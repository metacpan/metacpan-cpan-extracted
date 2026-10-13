package Logic::Relational::Goal::Call;

use v5.38;
use experimental 'signatures';
use parent 'Logic::Relational::Goal';

=head1 NAME

Logic::Relational::Goal::Call - Goal representing a predicate call.

=head1 DESCRIPTION

Expands a predicate call against the program's clauses or generators, performing
automatic ancestor cycle pruning and optional subgoal answer tabling/memoization.

=head1 METHODS

=head2 new

Constructor. Takes C<$name> and C<\@args>.

=head2 name

Returns the predicate functor name.

=head2 args

Returns the arrayref of call arguments.

=head2 arity

Returns the number of arguments.

=head2 as_term

Returns the call represented as a L<Logic::Relational::Term>.

=head2 expand

Expands the call goal into successor states.

=head2 freshen

Returns a copy of the call goal with freshened logical variables.

=head2 is_ground

Returns true if all arguments of the call are ground under the given substitution.

=cut

use Carp qw(croak);

sub new ( $class, $name, $args ) {
    return bless { name => $name, args => $args }, $class;
}

sub name  ($self) { return $self->{name}; }
sub args  ($self) { return $self->{args}; }
sub arity ($self) { return scalar @{ $self->{args} }; }

sub as_term ($self) {
    require Logic::Relational::Term;
    return Logic::Relational::Term->new(
        functor => $self->{name},
        args    => $self->{args}
    );
}

sub _check_defined ( $self, $key, $predicates, $generators ) {
    return if exists $predicates->{$key} || exists $generators->{$key};

    my @alts = grep { $_ =~ /^\Q$self->{name}\E\//x }
      ( keys %$predicates, keys %$generators );
    if (@alts) {
        my ( $alt_name, $alt_arity ) = split( '/', $alts[0] );
        croak "Predicate "
          . $self->{name} . "/"
          . $self->arity
          . " is undefined; available predicate is $alt_name/$alt_arity\n";
    }
    croak "Predicate " . $self->{name} . "/" . $self->arity . " is undefined\n";
}

sub expand ( $self, %args ) {
    my $predicates = $args{predicates} // croak "predicates is required";
    my $generators = $args{generators} // {};
    my $program    = $args{program};
    my $state      = $args{state};
    my $subst      = $args{substitution};
    my $remaining  = $args{remaining};

    my $key = $self->{name} . '/' . $self->arity;
    $self->_check_defined( $key, $predicates, $generators );

    require Logic::Relational::Unifier;
    require Logic::Relational::State;

    if ( my $gen_code = $generators->{$key} ) {
        my @reified_args = map { $subst->reify($_) } @{ $self->{args} };
        my $iterator     = $gen_code->(@reified_args);
        croak "Generator $key did not return a coderef iterator"
          unless ref($iterator) eq 'CODE';

        require Logic::Relational::Goal::GeneratorStep;
        my $step_goal = Logic::Relational::Goal::GeneratorStep->new(
            iterator  => $iterator,
            call_args => $self->{args},
            key       => $key,
            arity     => $self->arity,
        );

        my $succ = $state->derive(
            substitution => $subst,
            goals        => [ $step_goal, @$remaining ],
        );
        return $succ // ();
    }

    if (   $program
        && $program->can('is_tabled')
        && $program->is_tabled( $self->{name}, $self->arity ) )
    {
        return $self->_expand_tabled(%args);
    }

    my $my_term = $self->as_term;
    my $my_sig  = $state->canonical_term_signature( $my_term, $subst );
    my @anc     = @{ $state->ancestors };

    for my $anc_term (@anc) {
        if ( $state->canonical_term_signature( $anc_term, $subst ) eq $my_sig )
        {
            return ();
        }
    }

    return $self->_expand_clauses( $predicates->{$key} // [],
        $my_term, \@anc, $state, $subst, $remaining );
}

sub _expand_clauses ( $self, $clauses, $my_term, $anc, $state, $subst,
    $remaining )
{
    my @successors;
    my $end_call;
    my $now = time;

    for my $clause (@$clauses) {
        my $meta = $clause->metadata;
        if (   exists $meta->{expires_at}
            && defined $meta->{expires_at}
            && $now >= $meta->{expires_at} )
        {
            next;
        }

        my $fresh_clause = $clause->freshen;
        my $new_subst    = Logic::Relational::Unifier::unify( $my_term,
            $fresh_clause->head, $subst );
        if ($new_subst) {
            my $body = $fresh_clause->body;
            if ( ref($body) eq 'Logic::Relational::Goal::True' ) {
                my $succ = $state->derive(
                    substitution => $new_subst,
                    goals        => [ $body, @$remaining ],
                );
                push @successors, $succ if $succ;
            }
            else {
                if ( !$end_call ) {
                    require Logic::Relational::Goal::EndCall;
                    $end_call = Logic::Relational::Goal::EndCall->new;
                }
                my $succ = $state->derive(
                    substitution => $new_subst,
                    goals        => [ $body, $end_call, @$remaining ],
                    ancestors    => [ @$anc, $my_term ],
                );
                push @successors, $succ if $succ;
            }
        }
    }
    return @successors;
}

sub _expand_tabled ( $self, %args ) {
    my $predicates = $args{predicates};
    my $generators = $args{generators} // {};
    my $program    = $args{program};
    my $state      = $args{state};
    my $subst      = $args{substitution};
    my $remaining  = $args{remaining};

    my $key      = $self->{name} . '/' . $self->arity;
    my $my_term  = $self->as_term;
    my $call_sig = $state->canonical_term_signature( $my_term, $subst );
    my $cache    = $state->table_cache;
    my $entry    = $cache->{$call_sig};

    if ( $entry && $entry->{complete} ) {
        return $self->_unify_cached_answers( $entry->{answers}, $state,
            $subst, $remaining );
    }

    if ( $entry && $entry->{in_progress} ) {
        $entry->{hit_self_recursion} = 1;
        $cache->{_active_dependency} = 1;
        return $self->_unify_cached_answers( $entry->{answers}, $state,
            $subst, $remaining );
    }

    my $outer_in_progress =
      scalar grep { ref($_) eq 'HASH' && $_->{in_progress} } values %$cache;

    $entry = $cache->{$call_sig} = {
        in_progress        => 1,
        complete           => 0,
        answers            => [],
        answer_sigs        => {},
        hit_self_recursion => 0,
    };

    my $clauses = $predicates->{$key} // [];
    my $now     = time;
    require Logic::Relational::Query;

    while (1) {
        my $new_count = 0;
        for my $clause (@$clauses) {
            my $meta = $clause->metadata;
            if (   exists $meta->{expires_at}
                && defined $meta->{expires_at}
                && $now >= $meta->{expires_at} )
            {
                next;
            }

            my $fresh_clause = $clause->freshen;
            my $new_subst    = Logic::Relational::Unifier::unify( $my_term,
                $fresh_clause->head, $subst );
            next unless $new_subst;

            my $sub_q = Logic::Relational::Query->new(
                program      => $program,
                goals        => [ $fresh_clause->body ],
                predicates   => $predicates,
                generators   => $generators,
                substitution => $new_subst,
                ancestors    => [ @{ $state->ancestors }, $my_term ],
                table_cache  => $cache,
            );

            while ( my $sol = $sub_q->next ) {
                my $sol_subst = $sol->substitution;
                my $ans_term  = $sol_subst->reify($my_term);
                my $ans_sig =
                  $state->canonical_term_signature( $ans_term, $sol_subst );
                if ( !$entry->{answer_sigs}{$ans_sig}++ ) {
                    push @{ $entry->{answers} }, $ans_term;
                    $new_count++;
                }
            }
        }
        if ( !( $entry->{hit_self_recursion} && $new_count > 0 ) ) {
            last;
        }
    }

    if ( $outer_in_progress && $cache->{_active_dependency} ) {
        delete $cache->{$call_sig};
    }
    else {
        $entry->{in_progress} = 0;
        $entry->{complete}    = 1;
        delete $cache->{_active_dependency} unless $outer_in_progress;
    }

    return $self->_unify_cached_answers( $entry->{answers}, $state, $subst,
        $remaining );
}

sub _unify_cached_answers ( $self, $answers, $state, $subst, $remaining ) {
    my $my_term = $self->as_term;
    my @successors;
    for my $ans_term (@$answers) {
        my $fresh_ans = $ans_term->freshen( {} );
        my $new_subst =
          Logic::Relational::Unifier::unify( $my_term, $fresh_ans, $subst );
        if ($new_subst) {
            my $succ = $state->derive(
                substitution => $new_subst,
                goals        => $remaining,
            );
            push @successors, $succ if $succ;
        }
    }
    return @successors;
}

sub freshen ( $self, $var_map ) {
    require Logic::Relational::DSL;
    my @fresh_args =
      map { Logic::Relational::DSL::freshen_val( $_, $var_map ) }
      @{ $self->{args} };
    return ref($self)->new( $self->{name}, \@fresh_args );
}

sub is_ground ( $self, $subst ) {
    for my $arg ( @{ $self->{args} } ) {
        return 0 unless $self->term_is_ground( $arg, $subst );
    }
    return 1;
}

1;
