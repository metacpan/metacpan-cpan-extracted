#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2019 -- leonerd@leonerd.org.uk

package IO::Async::OS;

use strict;
use warnings;

our $VERSION = '0.77';

our @ISA = qw( IO::Async::OS::_Base );

if( eval { require "IO/Async/OS/$^O.pm" } ) {
   @ISA = "IO::Async::OS::$^O";
}

package # hide from CPAN
   IO::Async::OS::_Base;

use Carp;

use Socket 1.95 qw(
   AF_INET AF_INET6 AF_UNIX INADDR_LOOPBACK SOCK_DGRAM SOCK_RAW SOCK_STREAM
   pack_sockaddr_in inet_aton
   pack_sockaddr_in6 inet_pton
   pack_sockaddr_un
);

use POSIX qw( sysconf _SC_OPEN_MAX );

# Win32 [and maybe other places] don't have an _SC_OPEN_MAX. About the best we
# can do really is just make up some largeish number and hope for the best.
use constant OPEN_MAX_FD => eval { sysconf(_SC_OPEN_MAX) } || 1024;

# Some constants that define features of the OS

use constant HAVE_SOCKADDR_IN6 => defined eval { pack_sockaddr_in6 0, inet_pton( AF_INET6, "2001::1" ) };
use constant HAVE_SOCKADDR_UN  => defined eval { pack_sockaddr_un "/foo" };

# Do we have to fake S_ISREG() files read/write-ready in select()?
use constant HAVE_FAKE_ISREG_READY => 0;

# Do we have to select() for for evec to get connect() failures
use constant HAVE_SELECT_CONNECT_EVEC => 0;
# Ditto; do we have to poll() for POLLPRI to get connect() failures
use constant HAVE_POLL_CONNECT_POLLPRI => 0;

# Does connect() yield EWOULDBLOCK for nonblocking in progress?
use constant HAVE_CONNECT_EWOULDBLOCK => 0;

# Can we rename() files that are open?
use constant HAVE_RENAME_OPEN_FILES => 1;

# Can we reliably watch for POSIX signals, including SIGCHLD to reliably
# inform us that a fork()ed child has exit()ed?
use constant HAVE_SIGNALS => 1;

# Do we support POSIX-style true fork()ed processes at all?
use constant HAVE_POSIX_FORK => !$ENV{IO_ASYNC_NO_FORK};
# Can we potentially support threads? (would still need to 'require threads')
use constant HAVE_THREADS => !$ENV{IO_ASYNC_NO_THREADS} &&
   eval { require Config && $Config::Config{useithreads} };

# Preferred trial order for built-in Loop classes
use constant LOOP_BUILTIN_CLASSES => qw( Poll Select );

# Should there be any other Loop classes we try before the builtin ones?
use constant LOOP_PREFER_CLASSES => ();

=head1 NAME

C<IO::Async::OS> - operating system abstractions for C<IO::Async>

=head1 DESCRIPTION

This module acts as a class to provide a number of utility methods whose exact
behaviour may depend on the type of OS it is running on. It is provided as a
class so that specific kinds of operating system can override methods in it.

As well as these support functions it also provides a number of constants, all
with names beginning C<HAVE_> which describe various features that may or may
not be available on the OS or perl build. Most of these are either hard-coded
per OS, or detected at runtime.

The following constants may be overridden by environment variables.

=over 4

=item * HAVE_POSIX_FORK

True if the C<fork()> call has full POSIX semantics (full process separation).
This is true on most OSes but false on MSWin32.

This may be overridden to be false by setting the environment variable
C<IO_ASYNC_NO_FORK>.

=item * HAVE_THREADS

True if C<ithreads> are available, meaning that the C<threads> module can be
used. This depends on whether perl was built with threading support.

This may be overridable to be false by setting the environment variable
C<IO_ASYNC_NO_THREADS>.

=back

=cut

=head2 getfamilybyname

   $family = IO::Async::OS->getfamilybyname( $name )

Return a protocol family value based on the given name. If C<$name> looks like
a number it will be returned as-is. The string values C<inet>, C<inet6> and
C<unix> will be converted to the appropriate C<AF_*> constant.

=cut

sub getfamilybyname
{
   shift;
   my ( $name ) = @_;

   return undef unless defined $name;

   return $name if $name =~ m/^\d+$/;

   return AF_INET    if $name eq "inet";
   return AF_INET6() if $name eq "inet6" and defined &AF_INET6;
   return AF_UNIX    if $name eq "unix";

   croak "Unrecognised socket family name '$name'";
}

=head2 getsocktypebyname

   $socktype = IO::Async::OS->getsocktypebyname( $name )

Return a socket type value based on the given name. If C<$name> looks like a
number it will be returned as-is. The string values C<stream>, C<dgram> and
C<raw> will be converted to the appropriate C<SOCK_*> constant.

=cut

sub getsocktypebyname
{
   shift;
   my ( $name ) = @_;

   return undef unless defined $name;

   return $name if $name =~ m/^\d+$/;

   return SOCK_STREAM if $name eq "stream";
   return SOCK_DGRAM  if $name eq "dgram";
   return SOCK_RAW    if $name eq "raw";

   croak "Unrecognised socktype name '$name'";
}

# This one isn't documented because it's not really overridable. It's largely
# here just for completeness
my $HAVE_IO_SOCKET_IP;

sub socket
{
   my $self = shift;
   my ( $family, $socktype, $proto ) = @_;

   require IO::Socket;
   defined $HAVE_IO_SOCKET_IP or
      $HAVE_IO_SOCKET_IP = defined eval { require IO::Socket::IP };

   croak "Cannot create a new socket without a family" unless $family;
   # PF_UNSPEC and undef are both false
   $family = $self->getfamilybyname( $family ) || AF_UNIX;

   # SOCK_STREAM is the most likely
   $socktype = $self->getsocktypebyname( $socktype ) || SOCK_STREAM;

   defined $proto or $proto = 0;

   if( $HAVE_IO_SOCKET_IP and ( $family == AF_INET || $family == AF_INET6() ) ) {
      return IO::Socket::IP->new->socket( $family, $socktype, $proto );
   }

   my $sock = eval {
      IO::Socket->new(
         Domain => $family,
         Type   => $socktype,
         Proto  => $proto,
      );
   };
   return $sock if $sock;

   # That failed. Most likely because the Domain was unrecognised. This 
   # usually happens if getaddrinfo returns an AF_INET6 address but we don't
   # have a suitable class loaded. In this case we'll return a generic one.
   # It won't be in the specific subclass but that's the best we can do. And
   # it will still work as a generic socket.
   return IO::Socket->new->socket( $family, $socktype, $proto );
}

=head2 socketpair

   ( $S1, $S2 ) = IO::Async::OS->socketpair( $family, $socktype, $proto )

An abstraction of the C<socketpair(2)> syscall, where any argument may be
missing (or given as C<undef>).

If C<$family> is not provided, a suitable value will be provided by the OS
(likely C<AF_UNIX> on POSIX-based platforms). If C<$socktype> is not provided,
then C<SOCK_STREAM> will be used.

Additionally, this method supports building connected C<SOCK_STREAM> or
C<SOCK_DGRAM> pairs in the C<AF_INET> family even if the underlying platform's
C<socketpair(2)> does not, by connecting two normal sockets together.

C<$family> and C<$socktype> may also be given symbolically as defined by
C<getfamilybyname> and C<getsocktypebyname>.

=cut

sub socketpair
{
   my $self = shift;
   my ( $family, $socktype, $proto ) = @_;

   require IO::Socket;

   # PF_UNSPEC and undef are both false
   $family = $self->getfamilybyname( $family ) || AF_UNIX;

   # SOCK_STREAM is the most likely
   $socktype = $self->getsocktypebyname( $socktype ) || SOCK_STREAM;

   $proto ||= 0;

   my ( $S1, $S2 ) = IO::Socket->new->socketpair( $family, $socktype, $proto );
   return ( $S1, $S2 ) if defined $S1;

   return unless $family == AF_INET and ( $socktype == SOCK_STREAM or $socktype == SOCK_DGRAM );

   # Now lets emulate an AF_INET socketpair call

   my $Stmp = IO::Async::OS->socket( $family, $socktype ) or return;
   $Stmp->bind( pack_sockaddr_in( 0, INADDR_LOOPBACK ) ) or return;

   $S1 = IO::Async::OS->socket( $family, $socktype ) or return;

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
   else {
      $S2 = $Stmp;
      $S1->connect( getsockname $S2 ) or return;
      $S2->connect( getsockname $S1 ) or return;
   }

   return ( $S1, $S2 );
}

=head2 pipepair

   ( $rd, $wr ) = IO::Async::OS->pipepair

An abstraction of the C<pipe(2)> syscall, which returns the two new handles.

=cut

sub pipepair
{
   my $self = shift;

   pipe( my ( $rd, $wr ) ) or return;
   return ( $rd, $wr );
}

=head2 pipequad

   ( $rdA, $wrA, $rdB, $wrB ) = IO::Async::OS->pipequad

This method is intended for creating two pairs of filehandles that are linked
together, suitable for passing as the STDIN/STDOUT pair to a child process.
After this function returns, C<$rdA> and C<$wrA> will be a linked pair, as
will C<$rdB> and C<$wrB>.

On platforms that support C<socketpair(2)>, this implementation will be
preferred, in which case C<$rdA> and C<$wrB> will actually be the same
filehandle, as will C<$rdB> and C<$wrA>. This saves a file descriptor in the
parent process.

When creating a L<IO::Async::Stream> or subclass of it, the C<read_handle>
and C<write_handle> parameters should always be used.

 my ( $childRd, $myWr, $myRd, $childWr ) = IO::Async::OS->pipequad;

 $loop->open_process(
    stdin  => $childRd,
    stdout => $childWr,
    ...
 );

 my $str = IO::Async::Stream->new(
    read_handle  => $myRd,
    write_handle => $myWr,
    ...
 );
 $loop->add( $str );

=cut

sub pipequad
{
   my $self = shift;

   # Prefer socketpair
   if( my ( $S1, $S2 ) = $self->socketpair ) {
      return ( $S1, $S2, $S2, $S1 );
   }

   # Can't do that, fallback on pipes
   my ( $rdA, $wrA ) = $self->pipepair or return;
   my ( $rdB, $wrB ) = $self->pipepair or return;

   return ( $rdA, $wrA, $rdB, $wrB );
}

=head2 signame2num

   $signum = IO::Async::OS->signame2num( $signame )

This utility method converts a signal name (such as "TERM") into its system-
specific signal number. This may be useful to pass to C<POSIX::SigSet> or use
in other places which use numbers instead of symbolic names.

=cut

my %sig_num;
sub _init_signum
{
   my $self = shift;
   # Copypasta from Config.pm's documentation

   our %Config;
   require Config;
   Config->import;

   unless($Config{sig_name} && $Config{sig_num}) {
      die "No signals found";
   }
   else {
      my @names = split ' ', $Config{sig_name};
      @sig_num{@names} = split ' ', $Config{sig_num};
   }
}

sub signame2num
{
   my $self = shift;
   my ( $signame ) = @_;

   %sig_num or $self->_init_signum;

   return $sig_num{$signame};
}

=head2 extract_addrinfo

   ( $family, $socktype, $protocol, $addr ) = IO::Async::OS->extract_addrinfo( $ai )

Given an ARRAY or HASH reference value containing an addrinfo, returns a
family, socktype and protocol argument suitable for a C<socket> call and an
address suitable for C<connect> or C<bind>.

If given an ARRAY it should be in the following form:

 [ $family, $socktype, $protocol, $addr ]

If given a HASH it should contain the following keys:

 family socktype protocol addr

Each field in the result will be initialised to 0 (or empty string for the
address) if not defined in the C<$ai> value.

The family type may also be given as a symbolic string as defined by
C<getfamilybyname>.

The socktype may also be given as a symbolic string; C<stream>, C<dgram> or
C<raw>; this will be converted to the appropriate C<SOCK_*> constant.

Note that the C<addr> field, if provided, must be a packed socket address,
such as returned by C<pack_sockaddr_in> or C<pack_sockaddr_un>.

If the HASH form is used, rather than passing a packed socket address in the
C<addr> field, certain other hash keys may be used instead for convenience on
certain named families.

=over 4

=cut

use constant ADDRINFO_FAMILY   => 0;
use constant ADDRINFO_SOCKTYPE => 1;
use constant ADDRINFO_PROTOCOL => 2;
use constant ADDRINFO_ADDR     => 3;

sub extract_addrinfo
{
   my $self = shift;
   my ( $ai, $argname ) = @_;

   $argname ||= "addr";

   my @ai;

   if( ref $ai eq "ARRAY" ) {
      @ai = @$ai;
   }
   elsif( ref $ai eq "HASH" ) {
      $ai = { %$ai }; # copy so we can delete from it
      @ai = delete @{$ai}{qw( family socktype protocol addr )};

      if( defined $ai[ADDRINFO_FAMILY] and !defined $ai[ADDRINFO_ADDR] ) {
         my $family = $ai[ADDRINFO_FAMILY];
         my $method = "_extract_addrinfo_$family";
         my $code = $self->can( $method ) or croak "Cannot determine addr for extract_addrinfo on family='$family'";

         $ai[ADDRINFO_ADDR] = $code->( $self, $ai );

         keys %$ai and croak "Unrecognised '$family' addrinfo keys: " . join( ", ", keys %$ai );
      }
   }
   else {
      croak "Expected '$argname' to be an ARRAY or HASH reference";
   }

   $ai[ADDRINFO_FAMILY]   = $self->getfamilybyname( $ai[ADDRINFO_FAMILY] );
   $ai[ADDRINFO_SOCKTYPE] = $self->getsocktypebyname( $ai[ADDRINFO_SOCKTYPE] );

   # Make sure all fields are defined
   $ai[$_] ||= 0 for ADDRINFO_FAMILY, ADDRINFO_SOCKTYPE, ADDRINFO_PROTOCOL;
   $ai[ADDRINFO_ADDR]  = "" if !defined $ai[ADDRINFO_ADDR];

   return @ai;
}

=item family => 'inet'

Will pack an IP address and port number from keys called C<ip> and C<port>.
If C<ip> is missing it will be set to "0.0.0.0". If C<port> is missing it will
be set to 0.

=cut

sub _extract_addrinfo_inet
{
   my $self = shift;
   my ( $ai ) = @_;

   my $port = delete $ai->{port} || 0;
   my $ip   = delete $ai->{ip}   || "0.0.0.0";

   return pack_sockaddr_in( $port, inet_aton( $ip ) );
}

=item family => 'inet6'

Will pack an IP address and port number from keys called C<ip> and C<port>.
If C<ip> is missing it will be set to "::". If C<port> is missing it will be
set to 0. Optionally will also include values from C<scopeid> and C<flowinfo>
keys if provided.

This will only work if a C<pack_sockaddr_in6> function can be found in
C<Socket>

=cut

sub _extract_addrinfo_inet6
{
   my $self = shift;
   my ( $ai ) = @_;

   my $port     = delete $ai->{port}     || 0;
   my $ip       = delete $ai->{ip}       || "::";
   my $scopeid  = delete $ai->{scopeid}  || 0;
   my $flowinfo = delete $ai->{flowinfo} || 0;

   if( HAVE_SOCKADDR_IN6 ) {
      return pack_sockaddr_in6( $port, inet_pton( AF_INET6, $ip ), $scopeid, $flowinfo );
   }
   else {
      croak "Cannot pack_sockaddr_in6";
   }
}

=item family => 'unix'

Will pack a UNIX socket path from a key called C<path>.

=cut

sub _extract_addrinfo_unix
{
   my $self = shift;
   my ( $ai ) = @_;

   defined( my $path = delete $ai->{path} ) or croak "Expected 'path' for extract_addrinfo on family='unix'";

   return pack_sockaddr_un( $path );
}

=pod

=back

=cut

=head1 LOOP IMPLEMENTATION METHODS

The following methods are provided on C<IO::Async::OS> because they are likely
to require OS-specific implementations, but are used by L<IO::Async::Loop> to
implement its functionality. It can use the HASH reference C<< $loop->{os} >>
to store other data it requires.

=cut

=head2 loop_watch_signal

=head2 loop_unwatch_signal

   IO::Async::OS->loop_watch_signal( $loop, $signal, $code )

   IO::Async::OS->loop_unwatch_signal( $loop, $signal )

Used to implement the C<watch_signal> / C<unwatch_signal> Loop pair.

=cut

sub _setup_sigpipe
{
   my $self = shift;
   my ( $loop ) = @_;

   require IO::Async::Handle;

   my ( $reader, $sigpipe ) = $self->pipepair or croak "Cannot pipe() - $!";
   $_->blocking( 0 ) for $reader, $sigpipe;

   $loop->{os}{sigpipe} = $sigpipe;

   my $sigwatch = $loop->{os}{sigwatch};

   $loop->add( $loop->{os}{sigpipe_reader} = IO::Async::Handle->new(
      notifier_name => "sigpipe",
      read_handle => $reader,
      on_read_ready => sub {
         sysread $reader, my $buffer, 8192 or return;
         foreach my $signum ( unpack "I*", $buffer ) {
            $sigwatch->{$signum}->() if $sigwatch->{$signum};
         }
      },
   ) );

   return $sigpipe;
}

sub loop_watch_signal
{
   my $self = shift;
   my ( $loop, $signal, $code ) = @_;

   exists $SIG{$signal} or croak "Unrecognised signal name $signal";
   ref $code or croak 'Expected $code as a reference';

   my $signum = $self->signame2num( $signal );
   my $sigwatch = $loop->{os}{sigwatch} ||= {}; # {$num} = $code

   my $sigpipe = $loop->{os}{sigpipe} // $self->_setup_sigpipe( $loop );

   my $signum_str = pack "I", $signum;
   $SIG{$signal} = sub { syswrite $sigpipe, $signum_str };

   $sigwatch->{$signum} = $code;
}

sub loop_unwatch_signal
{
   my $self = shift;
   my ( $loop, $signal ) = @_;

   my $signum = $self->signame2num( $signal );
   my $sigwatch = $loop->{os}{sigwatch} or return;

   delete $sigwatch->{$signum};
   undef $SIG{$signal};
}

=head2 potentially_open_fds

   @fds = IO::Async::OS->potentially_open_fds

Returns a list of filedescriptors which might need closing. By default this
will return C<0 .. _SC_OPEN_MAX>. OS-specific subclasses may have a better
guess.

=cut

sub potentially_open_fds
{
   return 0 .. OPEN_MAX_FD;
}

sub post_fork
{
   my $self = shift;
   my ( $loop ) = @_;

   if( $loop->{os}{sigpipe} ) {
      $loop->remove( $loop->{os}{sigpipe_reader} );
      undef $loop->{os}{sigpipe};

      my $sigwatch = $loop->{os}{sigwatch};

      foreach my $signal ( keys %SIG ) {
         my $signum = $self->signame2num( $signal ) or next;
         my $code = $sigwatch->{$signum} or next;

         $self->loop_watch_signal( $loop, $signal, $code );
      }
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
