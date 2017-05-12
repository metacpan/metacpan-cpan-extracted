package Games::Go::Cinderblock::MoveResult;
use Moose;

has move_attempt => (
   isa => 'Games::Go::Cinderblock::MoveAttempt', # Games::Go::Cinderblock::MoveAttempt?
   is => 'ro',
   required => 1,
);

has rulemap => (
   isa => 'Games::Go::Cinderblock::Rulemap',
   is => 'ro', #shouldn't change.
   required => 1,
);
has basis_state=> (
   is => 'ro',
   required => 1,
   isa => 'Games::Go::Cinderblock::State',
);

has resulting_state=> (
   is => 'ro',
   # required if success?
   isa => 'Games::Go::Cinderblock::State',
);
has delta => (
   lazy => 1,
   is => 'ro',
   builder => '_derive_delta',
   isa => 'Games::Go::Cinderblock::Delta',
);

has succeeded => (
   isa => 'Bool',
   is => 'ro',
#   lazy => 1,
#   builder => '_determine_success',
   required => 1,
);
has reason => (
   isa => 'Str',
   is => 'ro',
   required => 0,
);

sub _derive_delta{
   my $self = shift;
   return $self->basis_state->delta_to($self->resulting_state);
}

# meh
sub failed{
   my $self = shift;
   return ($self->succeeded ? 0 : 1);
}
1;

__END__

=head1 NAME

Games::Go::Cinderblock::MoveResult

=head1 DESCRIPTION

This results from evaluate_move.

It has a L</delta>, which describes changes to the board

=head1 ATTRIBUTES

=head2 rulemap 

=head2 succeeded

0 if move failed, 1 if move succeeded.

=head2 reason

If failed, this is why. e.g. 'suicide', 'collision'

=head2 basis_state

=head2 resulting_state

=head2 delta

L</resulting_state> minus L</basis_state>, essentially.

A delta is an object that describes changes between 2 states with
the same rulemap.

=cut

