package Logic::Relational::Query::Runner;

use v5.38;
use feature 'try';
no warnings 'experimental::try';
use builtin qw(blessed);
no warnings 'experimental::builtin';

use Carp        qw(croak);
use JSON::PP    ();
use Time::HiRes qw(time);

use Logic::Relational::DSL         qw(variable);
use Logic::Relational::Goal::Call  ();
use Logic::Relational::Goal::Not   ();
use Logic::Relational::Goal::All   ();
use Logic::Relational::Query::Plan ();

our $VERSION = '0.04';

=head1 NAME

Logic::Relational::Query::Runner - Compiles and executes planned JSON-Datalog queries.

=head1 SYNOPSIS

    use Logic::Relational::Query::Runner;

    my $res = Logic::Relational::Query::Runner->run($program, $spec);
    if ($res->{ok}) {
        for my $row (@{ $res->{results} }) {
            say "Found: " . $row->{child};
        }
    }

=head1 DESCRIPTION

C<Logic::Relational::Query::Runner> takes a target L<Logic::Relational::Program>
and a query specification (or L<Logic::Relational::Query::Plan>), compiles the
goals into executable logical goals, and materializes solutions into a bounded,
deduplicated result set.

=head1 METHODS

=head2 run

    my $res = Logic::Relational::Query::Runner->run($program, $spec_or_plan, %opts);

Compiles the planned goals into an executable query, drains solutions into a bounded,
deduplicated result set, and returns a structured response hashref.

=cut

sub run ($class, $program, $spec_or_plan, %opts)    ## no critic (Subroutines::ProhibitManyArgs)
{
    my $t0 = time;

    my $plan;
    if (blessed($spec_or_plan) && $spec_or_plan->isa('Logic::Relational::Query::Plan')) {
        $plan = $spec_or_plan;
    } else {
        $plan = Logic::Relational::Query::Plan->plan($program, $spec_or_plan);
    }

    if (!$plan->is_valid) {
        return {
            ok         => 0,
            error      => $plan->error,
            error_code => $plan->error_code,
            audit      => {
                steps      => 0,
                elapsed_ms => 0,
            },
        };
    }

    my $self = bless {
        program => $program,
        plan    => $plan,
        options => \%opts,
        t0      => $t0,
    }, $class;

    return $self->_execute;
}

sub _execute ($self) {
    my $plan         = $self->{plan};
    my $program      = $self->{program};
    my $select_names = $plan->select_vars;
    my $distinct     = $plan->distinct;
    my $limit        = $plan->limit;
    my $timeout_ms   = $plan->timeout_ms;
    my $t0           = $self->{t0};
    my $deadline     = defined $timeout_ms ? ($t0 + ($timeout_ms / 1000.0)) : undef;

    my ($root_goal, $vars_map) = $self->_compile_goals($plan->goals);

    my %query_args;
    if (defined $plan->max_steps) {
        $query_args{max_steps} = $plan->max_steps;
    }

    my $query;
    my @rows;
    my %seen;
    my $truncated = 0;

    try {
        $query = $program->query($root_goal, %query_args);

        while (my $sol = $query->next) {
            if (defined $deadline && time >= $deadline) {
                croak "Query execution timeout exceeded ($timeout_ms ms)";
            }

            if (!@$select_names) {
                @rows = ({});
                last;
            }

            my %row;
            for my $vname (@$select_names) {
                my $var_obj = $vars_map->{$vname};
                $row{$vname} = defined $var_obj ? $sol->value($var_obj) : undef;
            }

            if ($distinct) {
                my $sig = join("\x1f", map {$_ . '=' . ($row{$_} // "\x00")} @$select_names);
                next if $seen{$sig}++;
            }

            push @rows, \%row;

            if (scalar(@rows) >= $limit) {
                $truncated = 1;
                last;
            }
        }
    } catch ($e) {
        my $elapsed_ms = int((time - $t0) * 1000 + 0.5);
        my $err_str    = "$e";
        my $err_code   = 'EXECUTION_ERROR';

        if ($err_str =~ m{maximum\s+resolution\s+steps}ix) {
            my $steps_val = $plan->max_steps // 'limit';
            $err_code = 'MAX_STEPS_EXCEEDED';
            $err_str  = "Query exceeded step limit ($steps_val steps)";
        } elsif ($err_str =~ m{timeout\s+exceeded}ix) {
            $err_code = 'TIMEOUT_EXCEEDED';
            $err_str  = "Query exceeded time limit ($timeout_ms ms)";
        }

        return {
            ok         => 0,
            error      => $err_str,
            error_code => $err_code,
            audit      => {
                steps      => defined($query) ? $query->step_count : 0,
                elapsed_ms => $elapsed_ms,
            },
        };
    }

    my $elapsed_ms = int((time - $t0) * 1000 + 0.5);

    return {
        ok        => 1,
        matched   => @rows ? 1 : 0,
        count     => scalar(@rows),
        truncated => $truncated ? JSON::PP::true() : JSON::PP::false(),
        results   => \@rows,
        audit     => {
            steps         => defined($query) ? $query->step_count : 0,
            elapsed_ms    => $elapsed_ms,
            planned_goals => $plan->goal_strings,
        },
    };
}

sub _compile_goals ($self, $planned_goals) {
    my %vars;
    my $anon_seq = 0;
    my @call_goals;

    for my $g (@$planned_goals) {
        my @compiled_args;

        for my $raw_arg (@{ $g->{args} }) {
            if (!defined $raw_arg || ref($raw_arg)) {
                push @compiled_args, $raw_arg;
            } elsif ($raw_arg =~ m{\A\$([a-zA-Z_]\w*)\z}x) {
                my $vname = $1;
                if ($vname eq '_') {
                    my $anon_name = '_anon_' . ++$anon_seq;
                    push @compiled_args, variable($anon_name);
                } else {
                    $vars{$vname} //= variable($vname);
                    push @compiled_args, $vars{$vname};
                }
            } else {
                push @compiled_args, $raw_arg;
            }
        }

        my $call = Logic::Relational::Goal::Call->new($g->{pred}, \@compiled_args);
        if ($g->{negated}) {
            push @call_goals, Logic::Relational::Goal::Not->new($call);
        } else {
            push @call_goals, $call;
        }
    }

    my $root_goal =
        (@call_goals == 1)
        ? $call_goals[0]
        : Logic::Relational::Goal::All->new(\@call_goals);

    return ($root_goal, \%vars);
}

1;
