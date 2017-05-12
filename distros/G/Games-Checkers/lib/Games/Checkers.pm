# Games::Checkers, Copyright (C) 1996-2012 Mikhael Goikhman, migo@cpan.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

package Games::Checkers;

use vars qw($VERSION);
$VERSION = '0.2.0';

1;

__END__
# ----------------------------------------------------------------------------

=head1 NAME

Games::Checkers - Play the Checkers games

=head1 SYNOPSIS

    # automatic computer-vus-computer play script
    use Games::Checkers::Game;

    my $game = Games::Checkers::Game->new(level => 2);

    $game->show_board;

    while ($game->can_move) {
        $game->sleep(2);
        $game->show_move($game->choose_move);
        $game->show_board;
    }

    $game->show_result;
    
# Or the same on a lower level:

    # automatic computer-vus-computer play script
    use Games::Checkers::Constants;
    use Games::Checkers::Board;
    use Games::Checkers::BoardTree;

    my $board = new Games::Checkers::Board;
    my $color = White;
    my $num_moves = 0;
    print $board->dump;

    while ($board->can_color_move($color)) {
        sleep(2);
        # allow 100 moves for each player
        die "Draw by rules\n" if $num_moves++ == 200;
        my $board_tree = new Games::Checkers::BoardTree
            ($board, $color, 2);  # think 2 steps ahead
        my $move = $board_tree->choose_best_move;  # or: choose_random_move

        $board->transform($move);
        print $move->dump, "\n", $board->dump;
        $color = ($color == White) ? Black : White;
    }

    print "\n", ($color == White ? "Black" : "White"), " won.\n";

=head1 ABSTRACT

Games::Checkers is a set of Perl classes implementing the Checkers game
play. Several national rule variants are supported. A basic AI heuristics is
implemented using the Minimax algorithm. Replay of previously recorded games
is supported too.

=head1 DESCRIPTION

This package is intended to provide complete infrastructure for interactive
and automatic playing and manipulating of Checkers games. Some features are
not implemented yet.

Currently supported board sizes:

	* 8x8
	* 10x10 (not yet, but will be soon hopefully)

Currently supported variants:

	* Russian Checkers (AI and game replay)
	* British Checkers (game replay)
	* Italian Checkers (game replay, set $ENV{ITALIAN_BOARD_NOTATION})

Currently supported game file formats:

	* .pdn files (trying to detect a lot of broken notations too)
	* .pdn.gz|xz|bz2 files (automatically uncompressed on the fly)

Currently installed scripts:

	* pcheckers-auto-play
	* pcheckers-replay-games

In the future one script C<pcheckers> may be installed that will include:

	* automatic AI game play (current script pcheckers-auto-play)
	* recorded game replay (current script pcheckers-replay-games)
	* interactive game play of 1 or 2 human players

If SDL perl modules are installed, then the SDL support is automatically
detected and activated that replaces the default terminal IO.

=head1 The Rules of Checkers

=head2 Board

The regular checkerboard is comprised of 64 squares of contrasting colors,
like black and white. The checker pieces may be red and white in color (or
any combination of contrasting colors), usually grooved.

The black board squares are numbered either 1 to 32 or using the chess a1 to
h8 notation. The diagram below shows the pieces set up for play, with Black
occupying squares 1 to 12 (lines 6 to 8 in the chess notation) and White
occupying squares 21 to 32 (lines 1 to 3 in the chess notation).

Chess notation:

   +-------------------------------+
 8 |###| @ |###| @ |###| @ |###| @ |
   |---+---+---+---+---+---+---+---|
 7 | @ |###| @ |###| @ |###| @ |###|
   |---+---+---+---+---+---+---+---|
 6 |###| @ |###| @ |###| @ |###| @ |
   |---+---+---+---+---+---+---+---|
 5 |   |###|   |###|   |###|   |###|
   |---+---+---+---+---+---+---+---|
 4 |###|   |###|   |###|   |###|   |
   |---+---+---+---+---+---+---+---|
 3 | O |###| O |###| O |###| O |###|
   |---+---+---+---+---+---+---+---|
 2 |###| O |###| O |###| O |###| O |
   |---+---+---+---+---+---+---+---|
 1 | O |###| O |###| O |###| O |###|
   +-------------------------------+
     a   b   c   d   e   f   g   h  

Numerical notation:

         1       2       3       4
   +-------------------------------+
   |###| @ |###| @ |###| @ |###| @ | 4
   |---+---+---+---+---+---+---+---|
  5| @ |###| @ |###| @ |###| @ |###|
   |---+---+---+---+---+---+---+---|
   |###| @ |###| @ |###| @ |###| @ |12
   |---+---+---+---+---+---+---+---|
 13|   |###|   |###|   |###|   |###|
   |---+---+---+---+---+---+---+---|
   |###|   |###|   |###| O |###|   |20
   |---+---+---+---+---+---+---+---|
 21| O |###| O |###|   |###| O |###|
   |---+---+---+---+---+---+---+---|
   |###| O |###| O |###| O |###| O |28
   |---+---+---+---+---+---+---+---|
 29| O |###| O |###| O |###| O |###|
   +-------------------------------+
     29      30      31      32

Each player (White and Black) controls its own army of pieces. Pieces move
only on dark squares which are numbered. The white pieces always move first
in opening the game. For example, suppose White were to open the game by
moving the piece on 23 to the square marked 19, like shown above. This would
be recorded as 23-19. Or e3-f4 in the chess notation. Another possible
notation is ef4.

=head2 The goal

The goal in the checkers game is either to capture all of the opponent's
pieces or to blockade them. If neither player can accomplish the above, the
game is a draw.

=head2 Moves

Starting with White, the players take turns moving one of their own pieces.
A 'piece' means either a 'man' (other name is 'pawn') - an ordinary single
checker or a 'king' which is what a man becomes if it reaches the last rank
(see kings). A man may move one square diagonally only forward - that is,
toward the opponent - onto an empty square.

=head2 Captures

Checkers rules state that captures or 'jumps' are mandatory. If a square
diagonally in front of a man is occupied by an opponent's piece, and if the
square beyond that piece in the same direction is empty, the man may 'jump'
over the opponent's piece and land on the empty square. The opponent's piece
is captured and removed from the board.

In some variants, if in the course of single or multiple jumps the man
reaches the last rank, becoming a king, the turn shifts to the opponent;
no further 'continuation' jump is possible.
 
=head2 The kings

When a single piece reaches the last rank of the board by reason of a move,
or as the completion of a 'jump', it becomes a king; and that completes the
move, or 'jump'.

A king can move in any of the four diagonal directions and skip zero, one or
more empty cells, as the limits of the board permit. Similarly, the king can
optionally capture exactly one opponent piece at a time during such jump.

In some variants, a king has the same limits as a man (can't skip empty
cells), just moves and captures in 4 diagonal directions, as opposed to 2
forward directions.

=head1 CLASSES

    Games::Checkers
    Games::Checkers::Board
    Games::Checkers::BoardConstants
    Games::Checkers::BoardTree
    Games::Checkers::BoardTreeNode
    Games::Checkers::CompPlayer
    Games::Checkers::Constants
    Games::Checkers::CountMoveList
    Games::Checkers::CreateMoveList
    Games::Checkers::CreateUniqueMove
    Games::Checkers::CreateVergeMove
    Games::Checkers::DeclareConstant
    Games::Checkers::ExpandMoveList
    Games::Checkers::FigureIterator
    Games::Checkers::Game
    Games::Checkers::IteratorConstants
    Games::Checkers::Iterators
    Games::Checkers::KingBeatIterator
    Games::Checkers::KingStepIterator
    Games::Checkers::LocationConversions
    Games::Checkers::LocationIterator
    Games::Checkers::Move
    Games::Checkers::MoveConstants
    Games::Checkers::MoveListNode
    Games::Checkers::MoveLocationConstructor
    Games::Checkers::PDNParser
    Games::Checkers::PawnBeatIterator
    Games::Checkers::PawnStepIterator
    Games::Checkers::PieceRuleIterator
    Games::Checkers::Player
    Games::Checkers::PlayerConstants
    Games::Checkers::SDL
    Games::Checkers::UserPlayer
    Games::Checkers::ValidKingBeatIterator

=head1 SEE ALSO

http://migo.sixbit.org/software/pcheckers/

=head1 AUTHORS

Mikhael Goikhman <migo@freeshell.org>

