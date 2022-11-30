use strict;
use warnings;

package Games::Board::Grid 1.014;
use parent qw(Games::Board);
# ABSTRACT: a grid-shaped gameboard

use Carp;

#pod =head1 SYNOPSIS
#pod
#pod   use Games::Board::Grid;
#pod
#pod   my $chess = Games::Board->new(size => 8);
#pod
#pod   my $rook = Games::Board::Piece->new(id => 'KR')->move(to => '7 7');
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module provides a base class for representing a board made up of spaces on
#pod a right-angled grid.
#pod
#pod =cut

#pod =method new
#pod
#pod   my $board = Games::Board::Grid->new(size => $size);
#pod
#pod This method constructs a new game board and returns it.  As constructed it has
#pod no spaces or pieces on it.  The C<size> argument may be an integer, to produce
#pod a square board, or an arrayref containing two integers, to produce a
#pod rectangular board.
#pod
#pod =cut

sub new {
  my ($class, %args) = @_;

  croak "no size given to construct grid" unless $args{size};

  $args{size} = [ ($args{size}) x 2 ] unless ref $args{size};

  my $board = { size => $args{size} };
  bless $board => $class;
  $board->init;
}

#pod =method init
#pod
#pod This method sets up the spaces on the board.
#pod
#pod =cut

sub init {
  my $board = shift;

  $board->{spaces} = {};

  for my $x (0 .. ($board->{size}[0] - 1)) {
  for my $y (0 .. ($board->{size}[1] - 1)) {
    my $id = $board->index2id([$x,$y]);
    $board->{spaces}{$id} = Games::Board::Grid::Space->new(id => $id, board => $board);
  }
  }

  $board;
}

#pod =method size
#pod
#pod =cut

sub size { (shift)->{size} }

#pod =method id2index
#pod
#pod   my $index = $board->id2index($id);
#pod
#pod This method returns the grid location of an identified space, in the format
#pod C<[$x, $y]>.  In Games::Board::Grid, the index C<[x,y]> becomes the id C<'x
#pod y'>.  Yeah, it's ugly, but it works.
#pod
#pod Reimplementing this method on a subclass can allow the use of idiomatic space
#pod identifiers on a grid.  (See, for example, the chess-custom.t test in this
#pod distribution.)
#pod
#pod =cut

sub id2index { [ split(/ /,$_[1]) ] }

#pod =method index2id
#pod
#pod   my $id = $board->index2id($index);
#pod
#pod This method performs the same translation as C<id2index>, but in reverse.
#pod
#pod =cut

sub index2id { join(q{ }, @{$_[1]}) }

#pod =method space
#pod
#pod   my $space = $board->space($id);
#pod
#pod This method returns the space with the given C<$id>.  If no space with that id
#pod exists, undef is returned.
#pod
#pod =cut

sub space {
  my $board = shift;
  my $id    = shift;

  return $board->{spaces}{$id};
}

#pod =method add_space
#pod
#pod This method, provided by Games::Board, will croak immediately if called.
#pod
#pod =cut

sub add_space { croak "spaces can't be added to grid board" }

#pod =head2 Games::Board::Grid::Space
#pod
#pod The spaces on a grid board are blessed into this class.  It acts like a
#pod L<Games::Board::Space> object, but directions are given as arrayrefs with x-
#pod and y-offsets.  For example, a knight's move might be represented as:
#pod
#pod   $board->space('1 0')->dir([2,1]);
#pod
#pod =cut

package Games::Board::Grid::Space 1.014;
use parent qw(Games::Board::Space);

sub dir_id {
  my ($self, $dir) = @_;
  return unless ref $dir eq 'ARRAY';

  my $pos = $self->board->id2index($self->id);

  my $newpos = [
    $pos->[0] + $dir->[0],
    $pos->[1] + $dir->[1]
  ];

  return if $newpos->[0] < 0 or $newpos->[1] < 0;
  return
    if $newpos->[0] >= $self->board->size->[0]
    or $newpos->[1] >= $self->board->size->[1];
  return $self->board->index2id($newpos);
}

"Family fun night!";

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Board::Grid - a grid-shaped gameboard

=head1 VERSION

version 1.014

=head1 SYNOPSIS

  use Games::Board::Grid;

  my $chess = Games::Board->new(size => 8);

  my $rook = Games::Board::Piece->new(id => 'KR')->move(to => '7 7');

=head1 DESCRIPTION

This module provides a base class for representing a board made up of spaces on
a right-angled grid.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 new

  my $board = Games::Board::Grid->new(size => $size);

This method constructs a new game board and returns it.  As constructed it has
no spaces or pieces on it.  The C<size> argument may be an integer, to produce
a square board, or an arrayref containing two integers, to produce a
rectangular board.

=head2 init

This method sets up the spaces on the board.

=head2 size

=head2 id2index

  my $index = $board->id2index($id);

This method returns the grid location of an identified space, in the format
C<[$x, $y]>.  In Games::Board::Grid, the index C<[x,y]> becomes the id C<'x
y'>.  Yeah, it's ugly, but it works.

Reimplementing this method on a subclass can allow the use of idiomatic space
identifiers on a grid.  (See, for example, the chess-custom.t test in this
distribution.)

=head2 index2id

  my $id = $board->index2id($index);

This method performs the same translation as C<id2index>, but in reverse.

=head2 space

  my $space = $board->space($id);

This method returns the space with the given C<$id>.  If no space with that id
exists, undef is returned.

=head2 add_space

This method, provided by Games::Board, will croak immediately if called.

=head2 Games::Board::Grid::Space

The spaces on a grid board are blessed into this class.  It acts like a
L<Games::Board::Space> object, but directions are given as arrayrefs with x-
and y-offsets.  For example, a knight's move might be represented as:

  $board->space('1 0')->dir([2,1]);

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
