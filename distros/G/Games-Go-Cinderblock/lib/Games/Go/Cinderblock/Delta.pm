package Games::Go::Cinderblock::Delta;
use Moose;

#use overload
#   '!' => \&reverse,

has rulemap => (
   isa => 'Games::Go::Cinderblock::Rulemap',
   is => 'ro', #shouldn't change.
   required => 1,
);
#changes to board.
# format: {remove => {b => \@nodes}}
has _board => (
   isa => 'HashRef',
   is => 'ro',
   required => 0,
   predicate => 'diff_board',
);
#changes to turn.
# format: {before=>'w', after=>'b'}
has _turn => (
   isa => 'HashRef',
   is => 'ro',
   required => 0,
   predicate => 'diff_turn',
);
#changes to caps.
# format: {w => {before=>3, after=>5}}
has _captures => (
   isa => 'HashRef',
   is => 'ro',
   required => 0,
   predicate => 'diff_captures',
);

around BUILDARGS => sub {
   my $orig  = shift;
   my $class = shift;
   my %args = @_;
   if($args{captures}){
      $args{_captures} = delete $args{captures};
   }
   if($args{turn}){
      $args{_turn} = delete $args{turn};
   }
   if($args{board}){
      $args{_board} = delete $args{board};
   }
   return $class->$orig(%args);
};

sub board{
   my $self = shift;
   die 'no color' if shift;
   return $self->_board;
}
sub turn{
   my $self = shift;
   return {} unless $self->diff_turn;
   return $self->_turn
}
sub captures{
   my ($self,$color) = @_;
   return {} unless $self->diff_captures;
   if($color){ return $self->_captures->{$color} }
   return $self->_captures;
}

sub board_addition{
   my $self = shift;
   my $color = shift;
   return {} unless $self->diff_board;
   if($color){
      return $self->_board->{add}{$color}
   }
   return $self->_board->{add};
}
sub board_removal{
   my $self = shift;
   return {} unless $self->diff_board;
   my $color = shift;
   if($color){
      return $self->_board->{remove}{$color}
   }
   return $self->_board->{remove};
}

sub to_args{
   my $self = shift;
   my %struct;
   if($self->diff_board){
      $struct{board} = $self->_board;
   }
   if($self->diff_turn){
      $struct{turn} = $self->_turn;
   }
   if($self->diff_captures){
      $struct{captures} = $self->_captures;
   }
   return \%struct;
}

1;

__END__

=head1 NAME

Games::Go::Cinderblock::Delta - A changeset between 2 states

=head1 SYNOPSIS

 my $delta = $state1->delta_to($state2);
 my $current_turn = $delta->turn->{after};

=head1 DESCRIPTION

Games::Go::Cinderblock::Delta represents a set of changes
between 2 states with the same rulemap. Each change is not necessarily
defined; that would imply that that particular change does not occur.

This class has the following basic attributes:

=head3 board

Format for changes on the board: C<< {color => {add => [nodes], remove => [nodes]}, ...} >>

For example, a capture by black:
C<< {b => {add => [[0,1]]}, w => {remove => [[0,0]]}} >>

=head3 turn

This change generally tends to occur on every move.

 {before => 'b', after => 'w'}

=head3 captures

In the event of a capturing move, the captures value of the capturing side will change.

 {b => {before => 0, after => 1}}

=head1 METHODS

=head2 to_args

Decompose into arguments that could be used to initialize an identical delta.
B<Rulemap not included.>

Useful for JSON serialization.

=head1 TODO

=head2 time! 

If states are given a timestamp, it would be <prudent> to give deltas a representation
of the time change.

2 options:

Nested data structure for changes in remaining time for each player. time-system-dependent,
but time systems would be a part of rulemap, I imagine. I like this idea.

The number of milliseconds between the 2 states. This is a bad idea because it doesn't
account for the twin paradox.

=cut

