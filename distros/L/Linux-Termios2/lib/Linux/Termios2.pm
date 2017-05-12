#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Linux::Termios2;

use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

=head1 NAME

C<Linux::Termios2> - wrap the F<Linux>-specific C<struct termios2> structure
and related

=head1 SYNOPSIS

This module is primarily intended as a helper for L<IO::Termios>, but it could
also be used directly.

 use Linux::Termios2;
 use POSIX qw( TCSANOW );

 my $termios = Linux::Termios2->new;
 $termios->getattr( 0 );

 $termios->setospeed( 123456 );

 $termios->setattr( 0, TCSANOW ) or
    die "Cannot TCSETS2 - $!";

=head1 DESCRIPTION

This class provides an API equivalent to the L<POSIX::Termios> class, except
backed by the F<Linux>-specific C<struct termios2> structure instead.

It uses the C<TCGETS2> and C<TCSETS2> family of C<ioctl()> calls, meaning it
has access to the arbitrary baud rate ability of the C<c_ispeed> and
C<c_ospeed> fields with the C<BOTHER> baud setting. These are accessed
transparently, by simply calling C<setispeed> and C<setospeed> with baud rates
in bits per second.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
