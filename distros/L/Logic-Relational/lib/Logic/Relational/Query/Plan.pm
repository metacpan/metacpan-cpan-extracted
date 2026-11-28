package Logic::Relational::Query::Plan;

use v5.38;
use feature 'try';
no warnings 'experimental::try';
use builtin qw(blessed);
no warnings 'experimental::builtin';

use Carp qw(croak);

our $VERSION = '0.04';

=head1 NAME

Logic::Relational::Query::Plan - Query validator, safety checker, and goal planner.

=head1 SYNOPSIS

    use Logic::Relational::Query::Plan;

    my $plan = Logic::Relational::Query::Plan->plan($program, $spec);
    if (!$plan->is_valid) {
        die $plan->error;
    }

=head1 DESCRIPTION

C<Logic::Relational::Query::Plan> validates a JSON-Datalog query specification
against a target L<Logic::Relational::Program>, verifies predicate arities,
enforces groundness requirements, ensures negation safety (no unground free
variables in negated goals), and reorders goals dynamically for optimal
search tree exploration.

=head1 METHODS

=head2 plan

    my $plan = Logic::Relational::Query::Plan->plan($program, $spec);

Validates and plans a QuerySpec hashref against a Program. Returns a Plan instance.

=head2 is_valid

Returns true if the query specification was valid, or false if validation failed.

=head2 error

Returns the human-readable error message if validation failed, or undef.

=head2 error_code

Returns the standard uppercase error code (e.g. C<'INVALID_SPEC'>, C<'UNSAFE_NEGATION'>).

=head2 goals

Returns the arrayref of planned goal descriptor hashrefs.

=head2 select_vars

Returns the arrayref of projected variable names (e.g. C<['who', 'role']>).

=head2 goal_strings

Returns an arrayref of stringified representations of planned goals in execution order.

=head2 distinct

Returns boolean indicating whether set deduplication is enabled.

=head2 limit

Returns the integer row cap.

=head2 max_steps

Returns the resolution step budget, or undef.

=head2 timeout_ms

Returns the wall-clock deadline in milliseconds, or undef.

=cut

sub plan ($class, $program, $spec) {
    my $self = bless {
        program      => $program,
        spec         => $spec,
        is_valid     => 0,
        error        => undef,
        error_code   => undef,
        goals        => [],
        select_vars  => [],
        goal_strings => [],
        distinct     => 1,
        limit        => 50,
        max_steps    => undef,
        timeout_ms   => undef,
    }, $class;

    $self->_validate_and_plan;
    return $self;
}

sub is_valid     ($self) {return $self->{is_valid};}
sub error        ($self) {return $self->{error};}
sub error_code   ($self) {return $self->{error_code};}
sub goals        ($self) {return $self->{goals};}
sub select_vars  ($self) {return $self->{select_vars};}
sub goal_strings ($self) {return $self->{goal_strings};}
sub distinct     ($self) {return $self->{distinct};}
sub limit        ($self) {return $self->{limit};}
sub max_steps    ($self) {return $self->{max_steps};}
sub timeout_ms   ($self) {return $self->{timeout_ms};}

sub _set_error ($self, $msg, $code = 'INVALID_SPEC') {
    $self->{is_valid}   = 0;
    $self->{error}      = $msg;
    $self->{error_code} = $code;
    return;
}

sub _validate_and_plan ($self) {
    my $spec = $self->{spec};
    if (!defined $spec || ref($spec) ne 'HASH') {
        return $self->_set_error('Query specification must be a JSON object (hash)',
            'INVALID_SPEC');
    }

    my $raw_goals = $spec->{goals};
    if (!defined $raw_goals || ref($raw_goals) ne 'ARRAY' || !@$raw_goals) {
        return $self->_set_error('Query requires a non-empty "goals" array', 'INVALID_SPEC');
    }

    $self->{distinct}   = exists $spec->{distinct} ? ($spec->{distinct} ? 1 : 0)             : 1;
    $self->{limit}      = defined $spec->{limit} && $spec->{limit} > 0 ? int($spec->{limit}) : 50;
    $self->{max_steps}  = defined $spec->{max_steps}  ? int($spec->{max_steps})  : undef;
    $self->{timeout_ms} = defined $spec->{timeout_ms} ? int($spec->{timeout_ms}) : undef;

    # Extract schema map from program describe
    my $desc = $self->{program}->describe(include_stdlib => 1);
    my %cat_map;
    my %arities_by_name;
    for my $p (@{ $desc->{predicates} // [] }) {
        my $key = "$p->{name}/$p->{arity}";
        $cat_map{$key} = $p;
        push @{ $arities_by_name{ $p->{name} } }, $p->{arity};
    }

    my $schema_info = {
        cat_map => \%cat_map,
        arities => \%arities_by_name,
    };

    my $normalized_goals = $self->_normalize_and_validate_goals($raw_goals, $schema_info);
    return unless defined $normalized_goals;

    # Reorder goals and enforce groundness & negation safety
    my $planned = $self->_plan_goal_order($normalized_goals);
    return unless defined $planned;

    # Validate variable projection (select)
    my $select_spec   = $spec->{select};
    my $selected_vars = $self->_resolve_select_vars($select_spec, $planned);
    return unless defined $selected_vars;

    $self->{goals}        = $planned;
    $self->{select_vars}  = $selected_vars;
    $self->{goal_strings} = [map {$self->_format_goal_string($_)} @$planned];
    $self->{is_valid}     = 1;
    return;
}

sub _normalize_and_validate_goals ($self, $raw_goals, $schema_info) {
    my $cat_map         = $schema_info->{cat_map};
    my $arities_by_name = $schema_info->{arities};
    my @normalized;
    for my $idx (0 .. $#$raw_goals) {
        my $g = $raw_goals->[$idx];
        if (!defined $g || ref($g) ne 'HASH') {
            $self->_set_error("Goal #$idx must be a JSON object", 'INVALID_SPEC');
            return undef;
        }

        my ($pred, $args, $negated);
        if (exists $g->{not} && ref($g->{not}) eq 'HASH') {
            $pred    = $g->{not}{pred};
            $args    = $g->{not}{args};
            $negated = 1;
        } else {
            $pred    = $g->{pred};
            $args    = $g->{args};
            $negated = $g->{negated} ? 1 : 0;
        }

        if (!defined $pred || !length($pred)) {
            $self->_set_error("Goal #$idx missing 'pred' name", 'INVALID_SPEC');
            return undef;
        }
        if (!defined $args || ref($args) ne 'ARRAY') {
            $self->_set_error("Goal #$idx missing 'args' array", 'INVALID_SPEC');
            return undef;
        }

        # Normalize stripped arity suffix if user passed "parent/2"
        $pred =~ s{/\d+\z}{}x;
        my $arity = scalar(@$args);
        my $key   = "$pred/$arity";

        if (!exists $cat_map->{$key}) {
            if (exists $arities_by_name->{$pred}) {
                my $expected = join(', ', sort {$a <=> $b} @{ $arities_by_name->{$pred} });
                $self->_set_error(
                    "Predicate '$pred' expects arity $expected, got $arity in goal #$idx",
                    'ARITY_MISMATCH');
                return undef;
            }
            $self->_set_error("Unknown predicate '$pred' in goal #$idx", 'UNKNOWN_PREDICATE');
            return undef;
        }

        push @normalized,
            {
            pred     => $pred,
            arity    => $arity,
            args     => [@$args],
            negated  => $negated,
            spec     => $cat_map->{$key},
            orig_idx => $idx,
            };
    }
    return \@normalized;
}

sub _candidate_goal_score ($self, $g, $bound_vars) {
    if ($g->{negated}) {

        # Negated goals can only be scheduled when ALL their variables are already bound
        for my $arg (@{ $g->{args} }) {
            my $vn = $self->_var_name($arg);
            if (defined $vn && $vn ne '_' && !$bound_vars->{$vn}) {
                return undef;
            }
        }
        return 1;
    }

    # Positive goal: check ground requirements
    if ($self->_ground_reqs_met($g, $bound_vars)) {
        return $self->_goal_selectivity($g, $bound_vars);
    }
    return undef;
}

sub _plan_goal_order ($self, $goals) {
    my @remaining = @$goals;
    my @scheduled;
    my %bound_vars;

    while (@remaining) {
        my $best_idx;
        my $best_score = -1000;

        for my $i (0 .. $#remaining) {
            my $g     = $remaining[$i];
            my $score = $self->_candidate_goal_score($g, \%bound_vars);
            if (defined $score && $score > $best_score) {
                $best_score = $score;
                $best_idx   = $i;
            }
        }

        if (!defined $best_idx) {

            # Failed to schedule next goal. Inspect why:
            my $blocked = $remaining[0];
            if ($blocked->{negated}) {
                my @unground;
                for my $arg (@{ $blocked->{args} }) {
                    my $vn = $self->_var_name($arg);
                    push @unground, "\$$vn" if defined $vn && $vn ne '_' && !$bound_vars{$vn};
                }
                my $vlist = join(', ', @unground);
                $self->_set_error(
"Negated goal '$blocked->{pred}/$blocked->{arity}' contains unground free variable(s): $vlist",
                    'UNSAFE_NEGATION'
                );
                return undef;
            }

            my $reqs = join(', ', @{ $blocked->{spec}{ground_required} // [] });
            $self->_set_error(
"Predicate '$blocked->{pred}/$blocked->{arity}' requires ground (bound) argument(s): $reqs",
                'UNBOUND_REQUIRED_ARG'
            );
            return undef;
        }

        my $chosen = splice(@remaining, $best_idx, 1);
        push @scheduled, $chosen;

        # If positive, record newly bound variables
        if (!$chosen->{negated}) {
            for my $arg (@{ $chosen->{args} }) {
                my $vn = $self->_var_name($arg);
                $bound_vars{$vn} = 1 if defined $vn && $vn ne '_';
            }
        }
    }

    return \@scheduled;
}

sub _ground_reqs_met ($self, $goal, $bound_vars) {
    my $reqs = $goal->{spec}{ground_required} // [];
    return 1 unless @$reqs;

    my %name_to_idx;
    my $args_spec = $goal->{spec}{args} // [];
    for my $i (0 .. $#$args_spec) {
        $name_to_idx{ $args_spec->[$i]{name} } = $i;
    }

    for my $req (@$reqs) {
        my $idx = ($req =~ m{\A\d+\z}x) ? int($req) : $name_to_idx{$req};
        next unless defined $idx;
        my $val = $goal->{args}[$idx];
        return 0 if !defined $val || ref($val);
        my $vn = $self->_var_name($val);
        if (defined $vn) {
            return 0 if $vn eq '_' || !$bound_vars->{$vn};
        }
    }
    return 1;
}

sub _goal_selectivity ($self, $goal, $bound_vars) {
    my $score = 10;    # Base priority for positive goals
    for my $arg (@{ $goal->{args} }) {
        my $vn = $self->_var_name($arg);
        if (defined $vn) {
            $score += ($vn ne '_' && $bound_vars->{$vn}) ? 2 : 0;
        } else {
            $score += 5;    # Literal constants provide high selectivity
        }
    }
    return $score;
}

sub _resolve_select_vars ($self, $select_spec, $planned_goals) {
    my %all_vars;
    my @first_seen_vars;

    for my $g (@$planned_goals) {
        next if $g->{negated};
        for my $arg (@{ $g->{args} }) {
            my $vn = $self->_var_name($arg);
            if (defined $vn && $vn ne '_') {
                if (!$all_vars{$vn}++) {
                    push @first_seen_vars, $vn;
                }
            }
        }
    }

    if (defined $select_spec) {
        if (ref($select_spec) ne 'ARRAY') {
            $self->_set_error('"select" must be an array of variable names', 'INVALID_SPEC');
            return undef;
        }
        my @selected;
        for my $raw_name (@$select_spec) {
            my $vname = $raw_name;
            $vname =~ s{\A\$}{}x;
            if (!$all_vars{$vname}) {
                $self->_set_error("Selected variable '\$$vname' does not appear in positive goals",
                    'INVALID_SPEC');
                return undef;
            }
            push @selected, $vname;
        }
        return \@selected;
    }

    return \@first_seen_vars;
}

sub _var_name ($self, $term) {
    return undef if !defined $term || ref($term);
    if ($term =~ m{\A\$([a-zA-Z_]\w*)\z}x) {
        return $1;
    }
    return undef;
}

sub _format_goal_string ($self, $goal) {
    my @arg_strs;
    for my $arg (@{ $goal->{args} }) {
        if (!defined $arg) {
            push @arg_strs, 'undef';
        } elsif ($self->_var_name($arg)) {
            push @arg_strs, $arg;
        } elsif ($arg =~ m{\A-?\d+(?:\.\d+)?\z}x) {
            push @arg_strs, $arg;
        } else {
            my $escaped = $arg =~ s/'/\\'/grx;
            push @arg_strs, "'$escaped'";
        }
    }
    my $args_joined = join(', ', @arg_strs);
    my $prefix      = $goal->{negated} ? '\\+ ' : '';
    return "$prefix$goal->{pred}($args_joined)";
}

1;
