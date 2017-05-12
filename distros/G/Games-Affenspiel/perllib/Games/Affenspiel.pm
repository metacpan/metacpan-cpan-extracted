# Games::Affenspiel library, Copyright (C) 2006 Mikhael Goikhman
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

package Games::Affenspiel;

our $VERSION = '0.1.0';

1;

__END__
# ----------------------------------------------------------------------------

=head1 NAME

Games::Affenspiel - Play the Affenspiel game

=head1 SYNOPSIS

    # automatical random play script
    use Games::Affenspiel::Board;

    my $board = Games::Affenspiel::Board->new;
    $board->show;

    for (1 .. 5000) {
        sleep(1);
        my ($bar, $gap_position, $direction) = $board->choose_random_move;
        print "Move bar $bar in direction $direction to $gap_position\n";
        $board->show;
    }

=head1 ABSTRACT

Games::Affenspiel is a set of Perl classes implementing the Affenspiel
game play.

=head1 DESCRIPTION

This package is intended to provide a basis for interactive (not yet)
and automatic playing and manipulating of Affenspiel games.

Current built-in board configurations:

    0) 4x5; one 2x2, four 1x1, four 1x2, one 2x1 bars, two gaps
    1) 4x5; one 2x2 bar, 16 gaps (just a test board)
    2) 4x5; one 2x2, four 1x1, two 1x2, three 2x1 bars, two gaps

Currently installed scripts (run with --help):

    * affenspiel-random-moves
    * affenspiel-random-solve
    * affenspiel-solve

=head1 The Rules of Affenspiel

=head2 Board

The regular Affenspiel board is comprised of 20 cells, 4 rows (numbered
1 to 4) of 5 columns (numbered 1 to 5). The cell position is written
in I<(y, x)> notation.

The original board has two gaps and following bars: one 2x2, four 1x1,
four 1x2, one 2x1. The position of the left-top corner of the bar is
taken as the position of the bar.

=head2 Initial board

In the initial state, the 2x2 square bar is in position (1, 2),

    +----+
    |A/\A|
    |V[]V|
    | <> |
    |AOOA|
    |VOOV|
    +----+

=head2 The goal

In the final (solved) state, the 2x2 square bar is in position (4, 2)),
Here is an example final board (there are many solutions):

    +----+
    |AOAA|
    |VAVV|
    |OV<>|
    | /\O|
    | []O|
    +----+

=head2 Moves

Each piece may be moved to left/right/up/down inside the board if there
are enough gap(s) in that direction. No bar rotation is allowed.

=head1 CLASSES

    Games::Affenspiel
    Games::Affenspiel::Board

=head1 SEE ALSO

http://www.artsoft.org/affenspiel/

http://migo.sixbit.org/software/paffenspiel/

=head1 AUTHOR

Mikhael Goikhman <migo@homamail.com>

=end
