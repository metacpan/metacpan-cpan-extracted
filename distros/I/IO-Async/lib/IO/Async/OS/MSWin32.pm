#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2013 -- leonerd@leonerd.org.uk

package IO::Async::OS::MSWin32;

use strict;
use warnings;

our $VERSION = '0.77';

our @ISA = qw( IO::Async::OS::_Base );

use Carp;

use Socket qw( AF_INET SOCK_STREAM SOCK_DGRAM INADDR_LOOPBACK pack_sockaddr_in );

use IO::Socket (); # empty import

use constant HAVE_FAKE_ISREG_READY => 1;

# Also select() only reports connect() failures by evec, not wvec
use constant HAVE_SELECT_CONNECT_EVEC => 1;

use constant HAVE_POLL_CONNECT_POLLPRI => 1;

use constant HAVE_CONNECT_EWOULDBLOCK => 1;

use constant HAVE_RENAME_OPEN_FILES => 0;

# poll(2) on Windows is emulated by wrapping select(2) anyway, so we might as
# well try the Select loop first
use constant LOOP_BUILTIN_CLASSES => qw( Select Poll );

# CORE::fork() does not provide full POSIX semantics
use constant HAVE_POSIX_FORK => 0;

# Windows does not have signals, and SIGCHLD is not available
use constant HAVE_SIGNALS => 0;

=head1 NAME

C<IO::Async::OS::MSWin32> - operating system abstractions on C<MSWin32> for C<IO::Async>

=head1 DESCRIPTION

This module contains OS support code for C<MSWin32>.

See instead L<IO::Async::OS>.

=cut

# Win32's pipes don't actually work with select(). We'll have to create
# sockets instead
sub pipepair
{
   shift->socketpair( 'inet', 'stream' );
}

# Win32 doesn't have a socketpair(). We'll fake one up
sub socketpair
{
   my $self = shift;
   my ( $family, $socktype, $proto ) = @_;

   $family = $self->getfamilybyname( $family ) || AF_INET;

   # SOCK_STREAM is the most likely
   $socktype = $self->getsocktypebyname( $socktype ) || SOCK_STREAM;

   $proto ||= 0;

   $family == AF_INET or croak "Cannot emulate ->socketpair except on AF_INET";

   my $Stmp = $self->socket( $family, $socktype ) or return;
   $Stmp->bind( pack_sockaddr_in( 0, INADDR_LOOPBACK ) ) or return;

   my $S1 = $self->socket( $family, $socktype ) or return;

   my $S2;
   if( $socktype == SOCK_STREAM ) {
      $Stmp->listen( 1 ) or return;
      $S1->connect( getsockname $Stmp ) or return;
      $S2 = $Stmp->accept or return;

      # There's a bug in IO::Socket here, in that $S2 's ->socktype won't
      # yet be set. We can apply a horribly hacky fix here
      #   defined $S2->socktype and $S2->socktype == $socktype or
      #     ${*$S2}{io_socket_type} = $socktype;
      # But for now we'll skip the test for it instead
   }
   elsif( $socktype == SOCK_DGRAM ) {
      $S2 = $Stmp;
      $S1->connect( getsockname $S2 ) or return;
      $S2->connect( getsockname $S1 ) or return;
   }
   else {
      croak "Unrecognised socktype $socktype";
   }

   return ( $S1, $S2 );
};

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
