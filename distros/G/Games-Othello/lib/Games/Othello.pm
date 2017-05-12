package Games::Othello;

use warnings;
use strict;

=head1 NAME

Games::Othello - Perl extension for modelling a game of Othello.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Games::Othello;

    my $game = Games::Othello->new();

    while( !game->over ) {
        printf "It is presently %s's move",
            ($game->whos_move eq 'b') ? 'black', 'white';
        my @possible_moves = values $game->possible_moves();

        if ( ! @possible_moves ) {
            print "You have no moves available, you must pass.
            $game->pass_to_opponent;
        } else {
            foreach ( my $move ) @possible_moves ) {
                printf
                  "You will take %d of your opponents chips if you place your chip on %d,%d",
                  scalar @{ $move->{chips} }, $move->{x}, $move->{y};
            }
            my ($locx, $locy) = get_move();
            my $flipped = $game->place_chip( $locx, $locy );
        }
        
        my $layout = $game->chip_layout();
        foreach my $row ( @$layout ) {
            foreach my $pos ( @$row ) {
                printf '%3s',
                      ($pos eq 'b') ? 'B'  # Black occupied square.
                    : ($pos eq 'w') ? 'W'  # White occupied square.
                    :                 ' '  # Un-occupied square.
            }
            print "\n\n";
        }
    }
    my ($black_score, $white_score) = $game->score;

=head1 STATUS

This module is B<PRE-ALPHA>.  Do not expect it to do anything at this point.
Do not expect the API to remain as documented.  If this module interests you
and you have feedback on its design please DO forward that to me.  Contact
information is contained at the bottom of this documentation.

=head1 DESCRIPTION

This module is used to model the common board game, Othello.   Othello has been
around for a very long time, and has been re-produced in several different
formats.  The goal of the game is to eventually fill the board with all of your
chips.

The board itself is an 8x8 grid represented as a matrix of x,y coordinates.
The location of which way each axis is numbered is irrelevant.  But for the
examples in this documentation, the the 0,0 cordinate is located on the
top-left of the board, and 7,7 is located on the bottom-right of the board.
Initially there are two white chips and two black chips each organized
diagonally in the center of the board:  

      0   1   2   3   4   5   6   7

   0

   1

   2

   3              W   B

   4              B   W

   5

   6

   7

Black always has the first move.  Each player must place their color chip on
the board in a square that is horizontally, vertically, or diagonally adjacent
to at least one opponent's chip on the board.  Beyond the opponents chip must
be a straight row of contiguous chips terminated another one of the player's
own chips.

In each instance where a row of opponent chips is terminated by the player's
recently placed chip and another one of that player's chips, the opponents
chips are said to be "flipped".  When this happens, the opponents chips change
color and become owned by the player that just played a chip.

For example: At the beginning of the game, Black always moves first and always
has the following moves available:  (3,2), (2,3), (5,4), (4,5).   Suppose that
black were to place its first chip on (2,3), resulting in the following layout:

       2   3   4   

   3   B   W   B

   4       B   W

Since the new chip at (3,2) now causes the white chip at (3,3) to be in between
two black chips, that chip would be flipped:

       2   3   4   

   3   B   B   B

   4       B   W

White must now play a chip at (2,2) for a diagonal, (4,2) for a vertical, or
(2,4) for a horizontal row.

If a player is un-able to place a chip on the board in a way that causes at
least one flip, they must pass their turn. The game is over under the following
conditions:

=over

=item 1. All squares are occupied.

=item 2. Neither player has any moves available.

=item 3. One player has had all chips eliminated.

=back

At the end of the game, the winner is the player with the most chips on the
board.

=head1 METHODS

=head2 new

This object constructor returns a new Games::Othello object.  

=cut

sub new {
    die 'un-implemented.';
}

=head2 game_over

This method returns a boolean to indicate if the game is over.  See the above
game description for more information.

=cut

sub game_over {
    die 'un-implemented';
}

=head2 whos_move

This method will return the character 'b', or 'w' to indicate if it is
presently black or white's turn.

=cut

sub whos_move {
    die 'un-implemented';
}

=head2 possible_moves

This method returns a hash of hashrefs. 

The outer hash keys are strings representing the comma-separated x and y
coordinates of a particular chip placement that is available in the present
turn (i.e. "3,4").   The values are hashrefs containing information about that
chip placement for the present turn.   

An empty outer hash indicates there are no chip placements possible.

Each inner hashref contains the following key/values:

=over

=item * x

This is the x-axis value of the placement.

=item * y

This is the y-axis value of the placement.

=item * chips

This is a list of opponent's chips that will be flipped over if the move is
executed.  Each chip is represented as an array-ref containing the [x,y] pair
of coordinates for the chip to be flipped.   Because the rules of the game
state that you must always flip at least one opponent's chip or pass your turn,
it is assumed that this list will always contain at least one element.

=cut

sub possible_moves {
    die 'un-implemented';
}

=head2 pass_to_opponent

This method passes game play to the opponent.  This may only be when there are
no possible moves available for the current player.

If the turn is passed to the opponent while there are moves available, then a
Games::Othello::InvalidMove exception will be thrown.  (see EXCEPTIONS, below)

=cut

sub pass_to_opponent {
    die 'un-implemented';
}

=head2 place_chip

This method accepts two parameters: x and y coordinates where the player has
elected to place their chip.

When called, this method will update the state of the board to reflect that the
chipped has been place.  Any opponent chips that need flipped will be flipped
and the game will be updated so that it is the other player's turn.

A list of chips that were flipped will be returned by this method in the form
of [x,y] pairs in array-refs.

If place_chip is called with an invalid set of coordinates, then a
Games::Othello::InvalidMove exception will be thrown.

=cut

sub place_chip {
    die 'un-implemented';
}

=head2 chip_layout

This method returns information about the position of all chips on the board.
It returns an array of arrays.  Each outer array represents one row on the
board (starting from 0), and each inner array represents the horizontal grid
squares in that row (starting from 0).

Each square is represented with the single character 'b' for a black occupied
square, 'w' for a white occupied square, or ' ' (single space) for an
un-occupied square.

=cut

sub chip_layout {
    die 'un-implemented';
}

=head2 score

This method returns the black score and white score in a list.  The score for each player is simply a count of how many chips they have on the board.

=cut

sub score {
    die 'un-implemented';
}

=head1 EXECPTIONS

Games::Othello uses the L<Exception::Class> model for errors.

=head1 AUTHOR

Daniel J. Wright, C<< <DWRIGHT at CPAN.ORG> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-othello at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Othello>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Othello

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Othello>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Othello>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Othello>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Othello>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to L<Games::Backgammon> for giving me some thoughts on how to organize
this.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Daniel J. Wright, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Games::Othello
