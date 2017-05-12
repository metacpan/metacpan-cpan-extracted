package Game::Pexeso;

=head1 NAME

Game::Pexeso - Pexeso game in Clutter

=head1 DESCRIPTION

Play the pexeso game, a simple and educational mind game, with a Perl variant!
In this version the cards are downloaded directly from the internet and are
displaying your favourite CPAN contributor (a.k.a Perl hacker).

=head1 RULES

A deck of shuffled cards where each card appears twice is placed in front of you
with the cards facing down so you can't see which card is where. The idea is to
match the pairs of cards until there are no more cards available.

At each turn you are allowed to flip two cards. If the two cards are identical
then the pair is removed otherwise the card are flipped again so you can't see
them. You are allowed to remember the cards positions once you have seen them,
in fact that's the purpose of the game! You continue flipping pairs of cards
until you have successfully matched all cards.

=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Emmanuel Rodriguez.

This program is free software; you can redistribute it and/or modify
it under the same terms of:

=over 4

=item the GNU Lesser General Public License, version 2.1; or

=item the Artistic License, version 2.0.

=back

This module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You should have received a copy of the GNU Library General Public
License along with this module; if not, see L<http://www.gnu.org/licenses/>.

For the terms of The Artistic License, see L<perlartistic>.

=cut

use strict;
use warnings;

our $VERSION = '0.01';

# A true value
1;

