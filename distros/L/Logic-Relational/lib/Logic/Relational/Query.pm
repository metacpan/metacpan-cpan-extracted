package Logic::Relational::Query;

use v5.38;
use experimental 'signatures';

=head1 NAME

Logic::Relational::Query - Manages the execution and backtracking search of a query.

=head1 SYNOPSIS

    use Logic::Relational::Query;
    my $query = Logic::Relational::Query->new(
        program    => $program,
        goals      => [$goal],
        predicates => $predicates_snapshot,
    );
    while (my $solution = $query->next) {
        ...
    }

=head1 DESCRIPTION

C<Logic::Relational::Query> executes the logical goals using a depth-first search
and an explicit agenda of execution states. This design avoids deep recursion or
complex mutable call stacks, while supporting ancestor cycle pruning and subgoal
memoization.

=head1 METHODS

=head2 new

Constructor. Takes C<program> (Program), C<goals> (arrayref), and C<predicates>
(snapshot of the predicates hash).

=head2 trace

Sets or returns the trace event callback coderef.

=head2 next

Performs the search step. Returns the next C<Logic::Relational::Solution> object,
or C<undef> if all solutions have been exhausted.

=head2 reify_solution

Constructs a C<Logic::Relational::Solution> object from a successful execution state.

=head2 is_true

Returns 1 if the query succeeds at least once, 0 otherwise.

=head2 is_success

Alias for C<is_true>.

=head2 all

Returns all solutions (up to C<limit>, default 10,000).

=head2 all_values

Returns all bindings for the given variable across all solutions.

=head2 distinct_values

Returns unique bindings for the given variable in discovery order.

=head2 all_tuples

Extracts arrayref tuples for an arrayref of variables across all solutions,
deduplicating tuples by default (pass C<distinct =E<gt> 0> to keep duplicates).

=head2 first_value

Returns the variable's value from the first solution, or C<undef>.

=head2 value

Alias for C<first_value>.

=cut

use Carp qw(croak);

sub new ( $class, %args ) {
    my $program    = $args{program} // croak "program is required";
    my $goals      = $args{goals}   // croak "goals is required";
    my $predicates = $args{predicates}
      // croak "predicates snapshot is required";

    require Logic::Relational::Substitution;
    require Logic::Relational::State;
    my $initial_subst = $args{substitution}
      // Logic::Relational::Substitution->new;
    my $table_cache   = $args{table_cache} // {};
    my $initial_state = Logic::Relational::State->new(
        substitution => $initial_subst,
        goals        => $goals,
        ancestors    => $args{ancestors} // [],
        table_cache  => $table_cache,
    );

    my $self = {
        program         => $program,
        predicates      => $predicates,
        generators      => $args{generators} // {},
        table_cache     => $table_cache,
        agenda          => [$initial_state],
        trace_cb        => undef,
        is_backtracking => 0,
    };
    return bless $self, $class;
}

sub trace ( $self, $callback = undef ) {
    if ( defined $callback ) {
        $self->{trace_cb} = $callback;
    }
    return $self->{trace_cb};
}

sub next ($self) {
    my $trace_cb = $self->{trace_cb};

    while ( my $state = pop @{ $self->{agenda} } ) {
        if ( $state->has_goals
            && ref( $state->goals->[0] ) eq 'Logic::Relational::Goal::EndCall' )
        {
            my ( $end_goal, @rem ) = $state->split_first_goal;
            my @succ = $end_goal->expand(
                state        => $state,
                substitution => $state->substitution,
                remaining    => \@rem,
            );
            push @{ $self->{agenda} }, reverse @succ;
            next;
        }

        if ( $self->{is_backtracking} && $trace_cb ) {
            require Logic::Relational::TraceEvent;
            $trace_cb->(
                Logic::Relational::TraceEvent->new(
                    type         => 'backtrack',
                    goal         => $state->goals->[0],
                    substitution => $state->substitution
                )
            );
            $self->{is_backtracking} = 0;
        }

        if ( !$state->has_goals ) {
            if ($trace_cb) {
                require Logic::Relational::TraceEvent;
                $trace_cb->(
                    Logic::Relational::TraceEvent->new(
                        type         => 'solution',
                        goal         => undef,
                        substitution => $state->substitution
                    )
                );
            }
            $self->{is_backtracking} = 1;
            return $self->reify_solution($state);
        }

        my ( $goal, @remaining ) = $state->split_first_goal;

        if ($trace_cb) {
            require Logic::Relational::TraceEvent;
            $trace_cb->(
                Logic::Relational::TraceEvent->new(
                    type         => 'call',
                    goal         => $goal,
                    substitution => $state->substitution
                )
            );
        }

        my @successors = $goal->expand(
            state        => $state,
            program      => $self->{program},
            predicates   => $self->{predicates},
            generators   => $self->{generators},
            substitution => $state->substitution,
            remaining    => \@remaining,
        );

        if ( scalar @successors > 0 ) {
            $self->{is_backtracking} = 0;
            if ($trace_cb) {
                require Logic::Relational::TraceEvent;
                $trace_cb->(
                    Logic::Relational::TraceEvent->new(
                        type         => 'success',
                        goal         => $goal,
                        substitution => $state->substitution
                    )
                );
                if ( scalar @successors > 1 ) {
                    $trace_cb->(
                        Logic::Relational::TraceEvent->new(
                            type         => 'choice',
                            goal         => $goal,
                            substitution => $state->substitution
                        )
                    );
                }
            }
        }
        else {
            $self->{is_backtracking} = 1;
            if ($trace_cb) {
                require Logic::Relational::TraceEvent;
                $trace_cb->(
                    Logic::Relational::TraceEvent->new(
                        type         => 'fail',
                        goal         => $goal,
                        substitution => $state->substitution
                    )
                );
            }
        }

        push @{ $self->{agenda} }, reverse @successors;
    }
    return undef;
}

sub reify_solution ( $self, $state ) {
    require Logic::Relational::Solution;
    return Logic::Relational::Solution->new(
        substitution => $state->substitution, );
}

use overload
  bool     => sub ( $self, $, $ ) { $self->is_true },
  fallback => 1;

sub is_true ($self) {
    return $self->next ? 1 : 0;
}

sub is_success ($self) {
    return $self->is_true;
}

sub all ( $self, %options ) {
    my $limit = exists $options{limit} ? $options{limit} : 10_000;
    my @solutions;

    while ( my $sol = $self->next ) {
        push @solutions, $sol;
        if ( defined $limit && scalar(@solutions) >= $limit ) {
            last;
        }
    }

    return wantarray ? @solutions : \@solutions;
}

sub all_values ( $self, $var, %options ) {
    my @sols   = $self->all(%options);
    my @values = map { $_->value($var) } @sols;
    return wantarray ? @values : \@values;
}

sub distinct_values ( $self, $var, %options ) {
    my @vals = $self->all_values( $var, %options );
    require Logic::Relational::State;
    require Logic::Relational::Substitution;
    my $dummy_state = Logic::Relational::State->new(
        substitution => Logic::Relational::Substitution->new,
        goals        => [],
    );
    my %seen;
    my @unique;
    for my $v (@vals) {
        my $sig = $dummy_state->canonical_term_signature($v);
        if ( !$seen{$sig}++ ) {
            push @unique, $v;
        }
    }
    return wantarray ? @unique : \@unique;
}

sub all_tuples ( $self, @args ) {
    my $vars;
    my %options;
    if ( @args && ref( $args[0] ) eq 'ARRAY' ) {
        $vars    = shift @args;
        %options = @args;
    }
    else {
        my @v_list;
        while ( @args && ref( $args[0] ) ) {
            push @v_list, shift @args;
        }
        $vars    = \@v_list;
        %options = @args;
    }
    croak "all_tuples requires an arrayref or list of variables"
      unless ref($vars) eq 'ARRAY' && @$vars;
    my $distinct = exists $options{distinct} ? $options{distinct} : 1;
    my @sols     = $self->all(%options);

    require Logic::Relational::State;
    require Logic::Relational::Substitution;
    my $dummy_state = Logic::Relational::State->new(
        substitution => Logic::Relational::Substitution->new,
        goals        => [],
    );

    my %seen;
    my @tuples;
    for my $sol (@sols) {
        my @tuple = map { $sol->value($_) } @$vars;
        if ($distinct) {
            my $sig = $dummy_state->canonical_term_signature( \@tuple );
            next if $seen{$sig}++;
        }
        push @tuples, \@tuple;
    }
    return wantarray ? @tuples : \@tuples;
}

sub first_value ( $self, $var ) {
    my $sol = $self->next // return undef;
    return $sol->value($var);
}

sub value ( $self, $var ) {
    return $self->first_value($var);
}

1;
