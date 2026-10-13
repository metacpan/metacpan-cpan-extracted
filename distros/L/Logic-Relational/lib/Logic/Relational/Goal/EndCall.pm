package Logic::Relational::Goal::EndCall;

use v5.38;
use experimental 'signatures';
use parent 'Logic::Relational::Goal';

=head1 NAME

Logic::Relational::Goal::EndCall - Internal marker goal popping an active ancestor call frame.

=head1 DESCRIPTION

C<Logic::Relational::Goal::EndCall> is an internal continuation marker inserted
after a rule body expansion by L<Logic::Relational::Goal::Call>. When reached, it
pops the completed call from the search state's active C<ancestors> stack so that
subsequent sibling goals are not treated as recursive descendants of the completed call.

=head1 METHODS

=head2 new

Constructs a new C<EndCall> marker goal.

=head2 expand

Pops the most recent ancestor from the state's ancestor stack and advances to the
remaining goals.

=head2 freshen

Returns the marker unchanged (no logical variables are stored in the marker).

=cut

sub new ($class) {
    return bless {}, $class;
}

sub expand ( $self, %args ) {
    my $state     = $args{state};
    my $remaining = $args{remaining};
    my @anc       = @{ $state->ancestors };
    pop @anc;

    my $succ = $state->derive(
        substitution => $args{substitution},
        goals        => $remaining,
        ancestors    => \@anc,
    );
    return $succ // ();
}

sub freshen ( $self, $var_map ) {
    return $self;
}

1;
