# -*- Perl -*-
# a SDL game where cards are used to move around a board
package Game::Kezboard;
our $VERSION = '0.04';

# mostly instead see the "kezboard" script

1;
__END__

=head1 Name

Game::Kezboard - a SDL game where cards are used to move around a board

=head1 SYNOPSIS

                       K E Z B O A R D   A L P H A

    You are the only child of a Trianglezoid Ranger.  Your mission is
    to pilot to Squaresville, as best you can.  Various obstacles may
    appear.  But let us not dwell for long on such cliches.  Click on
    a map item to see its position and inertia.  Click a card to play
    it, or use the number keys.  The undo button will remove cards in
    play. Once three cards are played, press the okay button and then
    see what happens.  The cards include various turns, nothing, move
    forward, and move backwards.  Moving alters inertia, which sticks
    around over time.  An important point worth mentioning is that an

=head1 DESCRIPTION

This is a SDL game. Probably you will want to run B<kezboard> which
hopefully got put into some PATH directory when this module was
installed.

=head1 SEE ALSO

L<kezboard(1)>

L<Game::Deckar> - a module to manage decks of cards

L<Imager> - used to "draw" some of the "artwork".

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

The font included uses the "Creative Commons Attribution-ShareAlike 4.0
International Public License".

L<https://int10h.org/oldschool-pc-fonts/fontlist/>

=cut
