
package Games::Boggle::Board;

=head1 NAME

Games::Boggle::Board - create a boggle board

=head1 SYNOPSIS

  use Games::Boggle::Board;

  my $board = Games::Boggle::Board->new();
  print $board->as_formatted_string;

=head1 DESCRIPTION

This module creates a random boggle board for play. 

=head1 METHODS

=head2 new

  my $board = Games::Boggle::Board->new();

=head2 as_string

Returns a single string, suitable to pass to Games::Boggle
  
  my $b = Games::Boggle->new( $board->as_string ); 

=head2 as_formatted_string

Returns a string formatted in a 4x4 block

  print $board->as_formatted_string;

=head2 as_array

Returns a one-dimensional array of letters

  foreach ($board->as_array) {
    # do something
  } 

=head1 AUTHOR

Anthony DeLorenzo E<lt>ajdelore@cpan.orgE<gt>.

=cut

$VERSION = '1.03';

use strict;

sub new {

  my $self = {};

  my @cubes = (
    # cubes taken from my boggle set, YMMV
    [ qw(S O A C P H) ],
    [ qw(T Y Y D S I) ],
    [ qw(M U O C T I) ],
    [ qw(Y R L T T E) ],
    [ qw(T T A O W O) ],
    [ qw(D R X I L E) ],
    [ qw(S E O T I S) ],
    [ qw(N S I E E U) ],
    [ qw(J O O B A B) ],
    [ qw(W R E T V H) ],
    [ qw(Y L E D R V) ],
    [ qw(E A N A G E) ],
    [ qw(H Z L R N N) ],
    [ qw(S F F K A P) ],
    [ qw(W H G E E N) ],
    [ qw(Q I M N U H) ],
  );

  my @board = map { $_->[int rand(6)] } @cubes;
  
  # uses fisher-yates shuffle
  # taken from perlfaq4, ++ to the perl community

  for (my $i = scalar(@board); --$i; ) {
    my $j = int rand ($i+1);
    @board[$i,$j] = @board[$j,$i];
  }

  $self->{BOARD} = \@board;

  bless ($self);
  return $self;
}

sub as_formatted_string {
  my $self = shift;
  my @board = @{$self->{BOARD}};
  s/Q/Qu/ foreach (@board); 
  return sprintf (
    ( "%-3s%-3s%-3s%-3s\n" .
      "%-3s%-3s%-3s%-3s\n" .
      "%-3s%-3s%-3s%-3s\n" .
      "%-3s%-3s%-3s%-3s\n" 
    )
    , @board);
}

sub as_array {
  my $self = shift;
  return @{$self->{BOARD}};
}

sub as_string {
  my $self = shift;
  return join ('',@{$self->{BOARD}});
}

1;

