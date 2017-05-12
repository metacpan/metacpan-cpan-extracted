use strict;
use warnings;

package Games::Board::Grid;
{
  $Games::Board::Grid::VERSION = '1.013';
}
use parent qw(Games::Board);
# ABSTRACT: a grid-shaped gameboard

use Carp;



sub new {
  my ($class, %args) = @_;

  croak "no size given to construct grid" unless $args{size};

  $args{size} = [ ($args{size}) x 2 ] unless ref $args{size};

  my $board = { size => $args{size} };
  bless $board => $class;
  $board->init;
}


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


sub size { (shift)->{size} }


sub id2index { [ split(/ /,$_[1]) ] }


sub index2id { join(q{ }, @{$_[1]}) }


sub space {
  my $board = shift;
  my $id    = shift;

  return $board->{spaces}{$id};
}


sub add_space { croak "spaces can't be added to grid board" }


package Games::Board::Grid::Space;
{
  $Games::Board::Grid::Space::VERSION = '1.013';
}
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

=head1 NAME

Games::Board::Grid - a grid-shaped gameboard

=head1 VERSION

version 1.013

=head1 SYNOPSIS

  use Games::Board::Grid;

  my $chess = Games::Board->new(size => 8);

  my $rook = Games::Board::Piece->new(id => 'KR')->move(to => '7 7');

=head1 DESCRIPTION

This module provides a base class for representing a board made up of spaces on
a right-angled grid.

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

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
