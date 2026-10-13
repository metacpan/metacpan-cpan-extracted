package Logic::Relational::State;

use v5.38;
use experimental 'signatures';
use Carp qw(croak);
use builtin 'blessed';
no warnings 'experimental::builtin';    ## no critic (TestingAndDebugging::ProhibitNoWarnings)

=head1 NAME

Logic::Relational::State - Represents a frozen search state in the logic engine.

=head1 METHODS

=head2 new

Constructor. Accepts C<substitution>, C<goals>, C<propagators>, C<ancestors>,
and C<table_cache>.

=head2 substitution

Returns the current L<Logic::Relational::Substitution>.

=head2 goals

Returns the arrayref of remaining goals.

=head2 propagators

Returns the arrayref of active constraint propagator callbacks.

=head2 ancestors

Returns the arrayref of active ancestor call terms along the current derivation path.

=head2 table_cache

Returns the shared subgoal memoization hashref for the active query.

=head2 has_goals

Returns true if there are remaining goals to prove.

=head2 split_first_goal

Returns the first goal and the list of remaining goals.

=head2 add_propagator

Returns a new state with the given constraint propagator added.

=head2 propagate

Runs all active constraint propagators until a fixpoint is reached.

=head2 derive

Derives a successor state with updated substitution, goals, propagators, or ancestors.

=head2 canonical_term_signature

Computes a canonical string signature for a term under a substitution, normalizing
unbound logical variables by order of first appearance (C<V0>, C<V1>, ...).

=cut

sub new ( $class, %args ) {
    my $subst       = $args{substitution} // croak "substitution is required";
    my $goals       = $args{goals}        // croak "goals list is required";
    my $props       = $args{propagators}  // [];
    my $ancestors   = $args{ancestors}    // [];
    my $table_cache = $args{table_cache}  // {};
    return bless {
        substitution => $subst,
        goals        => $goals,
        propagators  => $props,
        ancestors    => $ancestors,
        table_cache  => $table_cache,
    }, $class;
}

sub substitution ($self) {
    return $self->{substitution};
}

sub goals ($self) {
    return $self->{goals};
}

sub propagators ($self) {
    return $self->{propagators};
}

sub ancestors ($self) {
    return $self->{ancestors};
}

sub table_cache ($self) {
    return $self->{table_cache};
}

sub has_goals ($self) {
    return scalar @{ $self->{goals} } > 0;
}

sub split_first_goal ($self) {
    my ( $first, @rest ) = @{ $self->{goals} };
    return ( $first, @rest );
}

sub add_propagator ( $self, $callback ) {
    my $new_props = [ @{ $self->{propagators} }, $callback ];
    return ref($self)->new(
        substitution => $self->{substitution},
        goals        => $self->{goals},
        propagators  => $new_props,
        ancestors    => $self->{ancestors},
        table_cache  => $self->{table_cache},
    );
}

sub propagate ( $self, $subst ) {
    my $changed       = 1;
    my $current_subst = $subst;

    while ($changed) {
        $changed = 0;
        for my $prop ( @{ $self->{propagators} } ) {
            my $new_subst = $prop->($current_subst);
            return unless $new_subst;

            # Scalar reference address comparison in Perl to detect changes
            if ( $new_subst != $current_subst ) {
                $current_subst = $new_subst;
                $changed       = 1;
            }
        }
    }
    return $current_subst;
}

sub derive ( $self, %args ) {
    my $new_subst = $args{substitution} // $self->{substitution};
    my $new_goals = $args{goals}        // $self->{goals};
    my $new_props = $args{propagators}  // $self->{propagators};
    my $new_anc   = $args{ancestors}    // $self->{ancestors};
    my $new_cache = $args{table_cache}  // $self->{table_cache};

    my $temp_state = bless {
        substitution => $new_subst,
        goals        => $new_goals,
        propagators  => $new_props,
        ancestors    => $new_anc,
        table_cache  => $new_cache,
      },
      ref($self);

    my $propagated_subst = $temp_state->propagate($new_subst);
    return unless $propagated_subst;

    return ref($self)->new(
        substitution => $propagated_subst,
        goals        => $new_goals,
        propagators  => $new_props,
        ancestors    => $new_anc,
        table_cache  => $new_cache,
    );
}

sub canonical_term_signature ( $self, $term, $subst = $self->{substitution} ) {
    my %var_ids;
    my $next_id = 0;
    my $stringify;
    $stringify = sub ($val) {
        my $r = $subst->reify($val);
        return 'U' unless defined $r;
        if ( blessed($r) ) {
            if ( $r->isa('Logic::Relational::Variable') ) {
                my $vid = $r->id;
                $var_ids{$vid} //= $next_id++;
                return 'V' . $var_ids{$vid};
            }
            if ( $r->isa('Logic::Relational::Atom') ) {
                return 'A:' . $r->name;
            }
            if ( $r->isa('Logic::Relational::Term') ) {
                my @sub = map { $stringify->($_) } @{ $r->args };
                return 'T:' . $r->functor . '(' . join( ',', @sub ) . ')';
            }
            if ( $r->isa('Logic::Relational::ArrayRest') ) {
                return 'R:' . $stringify->( $r->term );
            }
        }
        if ( ref($r) eq 'ARRAY' ) {
            return '[' . join( ',', map { $stringify->($_) } @$r ) . ']';
        }
        if ( ref($r) eq 'HASH' ) {
            my @pairs =
              map { $_ . ':' . $stringify->( $r->{$_} ) } sort keys %$r;
            return '{' . join( ',', @pairs ) . '}';
        }
        return "S:$r";
    };
    return $stringify->($term);
}

1;
