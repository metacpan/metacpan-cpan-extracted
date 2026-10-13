package Logic::Relational::Goal::Not;

use v5.38;
use experimental 'signatures';
use parent 'Logic::Relational::Goal';
use Carp qw(croak);

=head1 NAME

Logic::Relational::Goal::Not - Negation as failure (not) goal.

=cut

sub new ( $class, $inner_goal ) {
    return bless { inner_goal => $inner_goal }, $class;
}

sub inner_goal ($self) { return $self->{inner_goal}; }

sub expand ( $self, %args ) {
    my $predicates = $args{predicates};
    my $subst      = $args{substitution};
    my $remaining  = $args{remaining};
    my $program    = $args{program};
    my $state      = $args{state};

    # Floundering check
    unless ( $self->{inner_goal}->is_ground($subst) ) {
        my $unbound =
          $self->_first_unbound_variable( $self->{inner_goal}, $subst );
        my $var_name = $unbound ? $unbound->name : 'unknown';
        croak "Negated goal contains unbound variable \$" . $var_name . "\n";
    }

    # Run inner query with current substitution snapshot
    require Logic::Relational::Query;
    my $inner_query = Logic::Relational::Query->new(
        program      => $program,
        goals        => [ $self->{inner_goal} ],
        predicates   => $predicates,
        generators   => $args{generators} // {},
        substitution => $subst,
        table_cache  => $state->table_cache,
    );

    if ( $inner_query->next ) {

        # Inner goal succeeded, so negation fails
        return ();
    }
    else {
        # Inner goal failed, so negation succeeds
        my $succ = $state->derive( goals => $remaining, );
        return $succ // ();
    }
}

sub freshen ( $self, $var_map ) {
    return ref($self)->new( $self->{inner_goal}->freshen($var_map) );
}

sub is_ground ( $self, $subst ) {
    return $self->{inner_goal}->is_ground($subst);
}

sub _first_unbound_variable ( $self, $goal, $subst ) {
    if ( ref($goal) eq 'Logic::Relational::Goal::Call' ) {    ## no critic (ProhibitCascadingIfElse)
        for my $arg ( @{ $goal->args } ) {
            my $v = $self->_first_unbound_var_in_term( $arg, $subst );
            return $v if $v;
        }
    }
    elsif ( ref($goal) eq 'Logic::Relational::Goal::Unify' ) {
        my $v = $self->_first_unbound_var_in_term( $goal->left, $subst );
        return $v if $v;
        return $self->_first_unbound_var_in_term( $goal->right, $subst );
    }
    elsif (ref($goal) eq 'Logic::Relational::Goal::All'
        || ref($goal) eq 'Logic::Relational::Goal::Any' )
    {
        for my $g ( @{ $goal->goals } ) {
            my $v = $self->_first_unbound_variable( $g, $subst );
            return $v if $v;
        }
    }
    elsif ( ref($goal) eq 'Logic::Relational::Goal::Not' ) {
        return $self->_first_unbound_variable( $goal->inner_goal, $subst );
    }
    elsif ( ref($goal) eq 'Logic::Relational::Goal::Guard' ) {
        for my $var ( @{ $goal->vars } ) {
            my $walked = $subst->walk($var);
            if ( ref($walked) eq 'Logic::Relational::Variable' ) {
                return $walked;
            }
        }
    }
    return undef;
}

sub _first_unbound_var_in_term ( $self, $term, $subst ) {
    $term = $subst->walk($term);
    if ( ref($term) eq 'Logic::Relational::Variable' ) {
        return $term;
    }
    elsif ( ref($term) eq 'Logic::Relational::Term' ) {
        for my $arg ( @{ $term->args } ) {
            my $v = $self->_first_unbound_var_in_term( $arg, $subst );
            return $v if $v;
        }
    }
    return undef;
}

1;
