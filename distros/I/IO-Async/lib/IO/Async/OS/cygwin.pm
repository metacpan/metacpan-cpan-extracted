#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013 -- leonerd@leonerd.org.uk

package IO::Async::OS::cygwin;

use strict;
use warnings;

our $VERSION = '0.77';

our @ISA = qw( IO::Async::OS::_Base );

# Cygwin almost needs no hinting above the POSIX-like base, except that its
# emulation of poll() isn't quite perfect. It needs POLLPRI
use constant HAVE_POLL_CONNECT_POLLPRI => 1;

# Also select() only reports connect() failures by evec, not wvec
use constant HAVE_SELECT_CONNECT_EVEC => 1;

=head1 NAME

C<IO::Async::OS::cygwin> - operating system abstractions on C<cygwin> for C<IO::Async>

=head1 DESCRIPTION

This module contains OS support code for C<cygwin>.

See instead L<IO::Async::OS>.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
