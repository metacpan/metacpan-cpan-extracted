package Games::Go::Cinderblock::MoveAttempt;
use Moose;

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

has node => (
   is => 'ro',
   required => 1,
);
has color => (
   is => 'ro',
   required => 1,
   isa => 'Str',
);

1;
__END__

=head1 NAME

Games::Go::Cinderblock::MoveAttempt

=head1 DESCRIPTION

Corollary to a
L<Games::Go::Cinderblock::MoveResult>.

L</node> & L</color> describe the move attempt.

L</basis_state> & L</rulemap> may determine its success.

The basis_state 

=head1 ATTRIBUTES

=head2 node

=head2 color

=head2 basis_state

=head2 rulemap

=cut

