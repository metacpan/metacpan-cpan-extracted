package Games::Wumpus::Constants;

use 5.010;

use strict;
use warnings;
no  warnings 'syntax';

our $VERSION = '2009112401';

#
# Contants used in the Wumpus game.
#

use Exporter ();
our @ISA    = 'Exporter';
our @EXPORT = qw [
    $WUMPUS $BAT $PIT $PLAYER @HAZARDS
    $NR_OF_WUMPUS $NR_OF_BATS $NR_OF_PITS $NR_OF_ARROWS
    $WUMPUS_MOVES
    @CLASSICAL_LAYOUT
];

#
# Hazards
#
our $WUMPUS        = 1 << 0;
our $BAT           = 1 << 1;
our $PIT           = 1 << 2;
our $PLAYER        = 1 << 3;
our @HAZARDS       = ($WUMPUS, $BAT, $PIT);

our $NR_OF_WUMPUS  = 1;
our $NR_OF_BATS    = 2;
our $NR_OF_PITS    = 2;
our $NR_OF_ARROWS  = 5;

our $WUMPUS_MOVES  = .75;   # Change of Wumpus moving when woken up.

#
# Classical
#
our @CLASSICAL_LAYOUT = (
    [ 1,  4,  7], [ 0,  2,  9], [ 1,  3, 11], [ 2,  4, 13],
    [ 0,  3,  5], [ 4,  6, 14], [ 5,  7, 16], [ 0,  6,  8],
    [ 7,  9, 17], [ 1,  8, 10], [ 9, 11, 18], [ 2, 10, 12],
    [11, 13, 19], [ 3, 12, 14], [ 5, 13, 15], [14, 16, 19],
    [ 6, 15, 17], [ 8, 16, 18], [10, 17, 19], [12, 15, 18],
);


1;

__END__

=head1 NAME

Games::Wumpus::Constants - Constants for Games::Wumpus

=head1 SYNOPSIS

 use Games::Wumpus::Constants;

=head1 DESCRIPTION

Exports constants used for C<< Games::Wumpus >> and related modules.
The following constants are exported:

 $WUMPUS $BAT $PIT $PLAYER @HAZARDS $NR_OF_WUMPUS $NR_OF_BATS $NR_OF_PITS
 $NR_OF_ARROWS $WUMPUS_MOVES

=head1 BUGS

None known.

=head1 TODO

Configuration of the game should be possible.

=head1 SEE ALSO

L<< Games::Wumpus >>, L<< Games::Wumpus::Cave >>, L<< Games::Wumpus::Room >>

=head1 DEVELOPMENT

The current sources of this module are found on github,
L<< git://github.com/Abigail/Games--Wumpus.git >>.

=head1 AUTHOR

Abigail, L<< mailto:wumpus@abigail.be >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2009 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),   
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 INSTALLATION

To install this module, run, after unpacking the tar-ball, the 
following commands:

   perl Makefile.PL
   make
   make test
   make install

=cut
