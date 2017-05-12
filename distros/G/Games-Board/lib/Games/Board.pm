use strict;
use warnings;
package Games::Board;
{
  $Games::Board::VERSION = '1.013';
}
# ABSTRACT: a parent class for board games

use Carp;
use Games::Board::Space;
use Games::Board::Piece;


sub new {
  my $class = shift;

  my $board = {
    spaces => { }
  };

  bless $board => $class;
}


sub space {
  my $board = shift;
  my $space = shift;

  return $board->{spaces}{$space};
}


sub add_space {
  my ($board, %args) = @_;
  my $space;

  $space = $board->spaceclass->new(board => $board, %args);

  return unless eval { $space->isa('Games::Board::Space') };

  if ($board->space($space->id)) {
    carp "space '" . $space->id . "' already exists on board";
  } else {
    $board->{spaces}{$space->id} = $space;
    return $space;
  }
}


sub piececlass { 'Games::Board::Piece' }


sub spaceclass { 'Games::Board::Space' }


sub add_piece {
  my $board = shift;
  my %args = @_;
  my $piece;

  $piece = $board->piececlass->new(board => $board, @_);
  $piece ||= shift;

  return unless eval { $piece->isa('Games::Board::Piece') };

  return $piece;
}

"Family fun night!";

__END__

=pod

=head1 NAME

Games::Board - a parent class for board games

=head1 VERSION

version 1.013

=head1 SYNOPSIS

  use Games::Board;

  my $board = Games::Board->new;

  $board->add_space(
    id  => 'go',
    dir => { next => 'mediterranean', prev => 'boardwalk' },
    cost => undef
  );

  my $tophat = Games::Board::Piece->new(id => 'tophat')->move(to => 'go');

=head1 DESCRIPTION

This module provides a base class for representing board games.  

=head1 METHODS

=head2 new

This method constructs a new game board and returns it.  As constructed it has
no spaces or pieces on it.

=head2 space

  my $space = $board->space($id);

This method returns the space with the given C<$id>.  If no space with that id
exists, undef is returned.

=head2 add_space

  my $space = $board->add_space(%args);

This method adds a space to the board.  It is passed a hash of attributes to
use in creating a Games::Board::Space object.  The object is created by calling
the constructor on the class whose name is returned by the C<spaceclass>
method.  This class must inherit from Games::Board::Space.

=head2 piececlass

This method returns the class used for pieces on this board.

=head2 spaceclass

This method returns the class used for spaces on this board.

=head2 add_piece

  my $piece = $board->add_piece(%args)

This method adds a piece to the board.  It is passed a hash of attributes to
use in creating a Games::Board::Piece object.  The object is created by calling
the constructor on the class whose name is returned by the C<piececlass>
method.  This class must inherit from Games::Board::Piece.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
