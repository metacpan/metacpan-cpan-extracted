use strict;
use warnings;
package Games::Board 1.014;
# ABSTRACT: a parent class for board games

use Carp;
use Games::Board::Space;
use Games::Board::Piece;

#pod =head1 SYNOPSIS
#pod
#pod   use Games::Board;
#pod
#pod   my $board = Games::Board->new;
#pod
#pod   $board->add_space(
#pod     id  => 'go',
#pod     dir => { next => 'mediterranean', prev => 'boardwalk' },
#pod     cost => undef
#pod   );
#pod
#pod   my $tophat = Games::Board::Piece->new(id => 'tophat')->move(to => 'go');
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module provides a base class for representing board games.  
#pod
#pod =method new
#pod
#pod This method constructs a new game board and returns it.  As constructed it has
#pod no spaces or pieces on it.
#pod
#pod =cut

sub new {
  my $class = shift;

  my $board = {
    spaces => { }
  };

  bless $board => $class;
}

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
  my $space = shift;

  return $board->{spaces}{$space};
}

#pod =method add_space
#pod
#pod   my $space = $board->add_space(%args);
#pod
#pod This method adds a space to the board.  It is passed a hash of attributes to
#pod use in creating a Games::Board::Space object.  The object is created by calling
#pod the constructor on the class whose name is returned by the C<spaceclass>
#pod method.  This class must inherit from Games::Board::Space.
#pod
#pod =cut

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

#pod =method piececlass
#pod
#pod This method returns the class used for pieces on this board.
#pod
#pod =cut

sub piececlass { 'Games::Board::Piece' }

#pod =method spaceclass
#pod
#pod This method returns the class used for spaces on this board.
#pod
#pod =cut

sub spaceclass { 'Games::Board::Space' }

#pod =method add_piece
#pod
#pod   my $piece = $board->add_piece(%args)
#pod
#pod This method adds a piece to the board.  It is passed a hash of attributes to
#pod use in creating a Games::Board::Piece object.  The object is created by calling
#pod the constructor on the class whose name is returned by the C<piececlass>
#pod method.  This class must inherit from Games::Board::Piece.
#pod
#pod =cut

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

=encoding UTF-8

=head1 NAME

Games::Board - a parent class for board games

=head1 VERSION

version 1.014

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

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Kaycie Goodman Ricardo SIGNES Signes

=over 4

=item *

Kaycie Goodman <jgoodman1990@gmail.com>

=item *

Ricardo SIGNES <rjbs@codesimply.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
