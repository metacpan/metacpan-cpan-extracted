#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2008-2024 -- leonerd@leonerd.org.uk

package # hide from CPAN
   IO::Async::Internals::Connector 0.802;

use v5.14;
use warnings;

use Scalar::Util qw( weaken blessed );

use POSIX qw( EINPROGRESS );
use Socket qw( SOL_SOCKET SO_ERROR );

use Future 0.44; # ->result
use Future::Utils 0.18 qw( try_repeat_until_success );

use IO::Async::OS;

use Carp;

use constant {
   CONNECT_EWOULDLBOCK => IO::Async::OS->HAVE_CONNECT_EWOULDBLOCK,
   HAVE_SOCKADDR_IN6   => IO::Async::OS->HAVE_SOCKADDR_IN6,
};

# Internal constructor
sub new
{
   my $class = shift;
   my ( %params ) = @_;

   my $loop = delete $params{loop} or croak "Expected a 'loop'";

   my $self = bless {}, $class;
   weaken( $self->{loop} = $loop );

   return $self;
}

## Utility function
sub _get_sock_err
{
   my ( $sock ) = @_;

   my $err = $sock->getsockopt( SOL_SOCKET, SO_ERROR );

   if( defined $err ) {
      # 0 means no error, but is still defined
      return undef if !$err;

      $! = $err;
      return $!;
   }

   # It seems we can't call getsockopt to query SO_ERROR. We'll try getpeername
   if( defined getpeername( $sock ) ) {
      return undef;
   }

   my $peername_errno = $!+0;
   my $peername_errstr = "$!";

   # Not connected so we know this ought to fail
   if( read( $sock, my $buff, 1 ) ) {
      # That was most unexpected. getpeername fails because we're not
      # connected, yet read succeeds.
      warn "getpeername fails with $peername_errno ($peername_errstr) but read is successful\n";
      warn "Please see http://rt.cpan.org/Ticket/Display.html?id=38382\n";

      $! = $peername_errno;
      return $!;
   }

   return $!;
}

sub _connect_addresses
{
   my $self = shift;
   my ( $addrlist, $on_fail ) = @_;

   my $loop = $self->{loop};

   my ( $connecterr, $binderr, $socketerr );

   my $future = try_repeat_until_success {
      my $addr = shift;
      my ( $family, $socktype, $protocol, $localaddr, $peeraddr ) =
         @{$addr}{qw( family socktype protocol localaddr peeraddr )};

      my $sock = IO::Async::OS->socket( $family, $socktype, $protocol );

      if( !$sock ) {
         $socketerr = $!;
         $on_fail->( "socket", $family, $socktype, $protocol, $! ) if $on_fail;
         return Future->fail( 1 );
      }

      if( $localaddr and not $sock->bind( $localaddr ) ) {
         $binderr = $!;
         $on_fail->( "bind", $sock, $localaddr, $! ) if $on_fail;
         return Future->fail( 1 );
      }

      $sock->blocking( 0 );

      # TODO: $sock->connect returns success masking EINPROGRESS
      my $ret = connect( $sock, $peeraddr );
      if( $ret ) {
         # Succeeded already? Dubious, but OK. Can happen e.g. with connections to
         # localhost, or UNIX sockets, or something like that.
         return Future->done( $sock );
      }
      elsif( $! != EINPROGRESS and !CONNECT_EWOULDLBOCK || $! != POSIX::EWOULDBLOCK ) {
         $connecterr = $!;
         $on_fail->( "connect", $sock, $peeraddr, $! ) if $on_fail;
         return Future->fail( 1 );
      }

      # Else
      my $f = $loop->new_future;
      $loop->watch_io(
         handle => $sock,
         on_write_ready => sub {
            $loop->unwatch_io( handle => $sock, on_write_ready => 1 );

            my $err = _get_sock_err( $sock );

            return $f->done( $sock ) if !$err;

            $connecterr = $!;
            $on_fail->( "connect", $sock, $peeraddr, $err ) if $on_fail;
            return $f->fail( 1 );
         },
      );
      $f->on_cancel(
         sub { $loop->unwatch_io( handle => $sock, on_write_ready => 1 ); }
      );
      return $f;
   } foreach => $addrlist;

   return $future->else_with_f( sub {
      my $f = shift;

      return $future->new->fail( "connect: $connecterr", connect => connect => $connecterr )
         if $connecterr;
      return $future->new->fail( "bind: $binderr",       connect => bind    => $binderr    )
         if $binderr;
      return $future->new->fail( "socket: $socketerr",   connect => socket  => $socketerr  )
         if $socketerr;

      # If it gets this far then something went wrong
      return $f;
   } );
}

sub connect
{
   my $self = shift;
   my ( %params ) = @_;

   my $loop = $self->{loop};

   my $on_fail = $params{on_fail};

   my %gai_hints;
   exists $params{$_} and $gai_hints{$_} = $params{$_} for qw( family socktype protocol flags );

   if( exists $params{host} or exists $params{local_host} or exists $params{local_port} ) {
      # We'll be making a ->getaddrinfo call
      defined $gai_hints{socktype} or defined $gai_hints{protocol} or
         carp "Attempting to ->connect without either 'socktype' or 'protocol' hint is not portable";
   }

   my $peeraddrfuture;
   if( exists $params{host} and exists $params{service} ) {
      my $host    = $params{host}    or croak "Expected 'host'";
      my $service = $params{service} or croak "Expected 'service'";

      $peeraddrfuture = $loop->resolver->getaddrinfo(
         host    => $host,
         service => $service,
         %gai_hints,
      );
   }
   elsif( exists $params{addrs} or exists $params{addr} ) {
      my @addrs = exists $params{addrs} ? @{ $params{addrs} } : ( $params{addr} );

      # Warn about some common mistakes
      foreach my $peer ( @addrs ) {
         my ( $p_family, undef, undef, $p_addr ) = IO::Async::OS->extract_addrinfo( $peer );

         local our @CARP_NOT = qw( IO::Async::Loop IO::Async::Handle );

         if( $p_family == Socket::AF_INET ) {
            carp "Connecting to 0.0.0.0 is non-portable and ill-advised"
               if ( Socket::unpack_sockaddr_in  $p_addr )[1] eq Socket::INADDR_ANY;
         }
         elsif( HAVE_SOCKADDR_IN6 and $p_family == Socket::AF_INET6 ) {
            carp "Connecting to :: is non-portable and ill-advised"
               if ( Socket::unpack_sockaddr_in6 $p_addr )[1] eq Socket::IN6ADDR_ANY;
         }
      }

      $peeraddrfuture = $loop->new_future->done( @addrs );
   }
   elsif( exists $params{peer} ) {
      my $peer = delete $params{peer};
      croak "Expected 'peer' to be an IO::Socket or subclass"
         unless blessed $peer and $peer->isa( "IO::Socket" );

      my $p_family = $peer->sockdomain;

      $peeraddrfuture = $loop->new_future->done(
         [ $p_family, $peer->socktype, $peer->protocol, IO::Async::OS->make_addr_for_peer( $p_family, $peer->sockname ) ]
      );
   }
   else {
      croak "Expected 'host' and 'service' or 'addrs' or 'addr' arguments";
   }

   my $localaddrfuture;
   if( defined $params{local_host} or defined $params{local_service} ) {
      # Empty is fine on either of these
      my $host    = $params{local_host};
      my $service = $params{local_service};

      $localaddrfuture = $loop->resolver->getaddrinfo(
         host    => $host,
         service => $service,
         %gai_hints,
      );
   }
   elsif( exists $params{local_addrs} or exists $params{local_addr} ) {
      $localaddrfuture = $loop->new_future->done( exists $params{local_addrs} ? @{ $params{local_addrs} } : ( $params{local_addr} ) );
   }
   else {
      $localaddrfuture = $loop->new_future->done( {} );
   }

   return Future->needs_all( $peeraddrfuture, $localaddrfuture )
      ->then( sub {
         my @peeraddrs  = $peeraddrfuture->result;
         my @localaddrs = $localaddrfuture->result;

         my @addrs;

         foreach my $local ( @localaddrs ) {
            my ( $l_family, $l_socktype, $l_protocol, $l_addr ) = 
               IO::Async::OS->extract_addrinfo( $local, 'local_addr' );
            foreach my $peer ( @peeraddrs ) {
               my ( $p_family, $p_socktype, $p_protocol, $p_addr ) = 
                  IO::Async::OS->extract_addrinfo( $peer );

               next if $l_family   and $p_family   and $l_family   != $p_family;
               next if $l_socktype and $p_socktype and $l_socktype != $p_socktype;
               next if $l_protocol and $p_protocol and $l_protocol != $p_protocol;

               push @addrs, {
                  family    => $l_family   || $p_family,
                  socktype  => $l_socktype || $p_socktype,
                  protocol  => $l_protocol || $p_protocol,
                  localaddr => $l_addr,
                  peeraddr  => $p_addr,
               };
            }
         }

         return $self->_connect_addresses( \@addrs, $on_fail );
      } );
}

0x55AA;
