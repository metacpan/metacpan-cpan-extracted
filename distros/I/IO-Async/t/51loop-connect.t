#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Identity;

use IO::Socket::INET;
use POSIX qw( ENOENT );
use Socket qw( AF_UNIX inet_ntoa );

use IO::Async::Loop;

use IO::Async::Stream;
use IO::Async::Socket;

# Some odd locations like BSD jails might not like INADDR_LOOPBACK. We'll
# establish a baseline first to test against
my $INADDR_LOOPBACK = do {
   my $localsock = IO::Socket::INET->new( LocalAddr => "localhost", Listen => 1 );
   $localsock->sockaddr;
};
my $INADDR_LOOPBACK_HOST = inet_ntoa( $INADDR_LOOPBACK );
if( $INADDR_LOOPBACK ne INADDR_LOOPBACK ) {
   diag( "Testing with INADDR_LOOPBACK=$INADDR_LOOPBACK_HOST; this may be because of odd networking" );
}

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

# Try connect(2)ing to a socket we've just created
my $listensock = IO::Socket::INET->new(
   Type      => SOCK_STREAM,
   LocalAddr => 'localhost',
   LocalPort => 0,
   Listen => 1
) or die "Cannot create listensock - $!";

my $addr = $listensock->sockname;

{
   my $future = $loop->connect(
      addr => { family => "inet", socktype => "stream", addr => $addr },
   );

   isa_ok( $future, "Future", '$future' );

   wait_for { $future->is_ready };

   my ( $sock ) = $future->get;

   can_ok( $sock, qw( peerhost peerport ) );
   is_deeply( [ unpack_sockaddr_in $sock->peername ],
              [ unpack_sockaddr_in $addr ], 'by addr: $sock->getpeername is $addr from future' );

   $listensock->accept; # Throw it away
}

# handle
{
   my $future = $loop->connect(
      handle => my $given_stream = IO::Async::Stream->new,
      addr   => { family => "inet", socktype => "stream", addr => $addr },
   );

   isa_ok( $future, "Future", '$future for ->connect( handle )' );

   wait_for { $future->is_ready };

   my $stream = $future->get;
   identical( $stream, $given_stream, '$future->get returns given Stream' );
   ok( my $sock = $stream->read_handle, '$stream has a read handle' );
   is_deeply( [ unpack_sockaddr_in $sock->peername ],
              [ unpack_sockaddr_in $addr ], 'Returned $stream->read_handle->getpeername is $addr' );

   $listensock->accept; # Throw it away
}

# legacy callbacks
{
   my $sock;

   $loop->connect(
      addr => { family => "inet", socktype => "stream", addr => $addr },
      on_connected => sub { $sock = shift; },
      on_connect_error => sub { die "Test died early - connect error $_[0]() - $_[-1]\n"; },
   );

   wait_for { $sock };

   # Not sure if it'll be an IO::Socket::INET or ::IP, but either way it should support these
   can_ok( $sock, qw( peerhost peerport ) );
   is_deeply( [ unpack_sockaddr_in $sock->peername ],
              [ unpack_sockaddr_in $addr ], 'by addr: $sock->getpeername is $addr' );

   $listensock->accept; # Throw it away
}

# Now try by name
{
   my $future = $loop->connect(
      host     => $listensock->sockhost,
      service  => $listensock->sockport,
      socktype => $listensock->socktype,
   );

   isa_ok( $future, "Future", '$future' );

   wait_for { $future->is_ready };

   my ( $sock ) = $future->get;

   can_ok( $sock, qw( peerhost peerport ) );
   is_deeply( [ unpack_sockaddr_in $sock->peername ],
              [ unpack_sockaddr_in $addr ], 'by host/service: $sock->getpeername is $addr from future' );

   is( $sock->sockhost, $INADDR_LOOPBACK_HOST, '$sock->sockhost is INADDR_LOOPBACK_HOST from future' );

   $listensock->accept; # Throw it away
}

# legacy callbacks
{
   my $sock;

   $loop->connect(
      host     => $listensock->sockhost,
      service  => $listensock->sockport,
      socktype => $listensock->socktype,
      on_connected => sub { $sock = shift; },
      on_resolve_error => sub { die "Test died early - resolve error - $_[-1]\n"; },
      on_connect_error => sub { die "Test died early - connect error $_[0]() - $_[-1]\n"; },
   );

   wait_for { $sock };

   can_ok( $sock, qw( peerhost peerport ) );
   is_deeply( [ unpack_sockaddr_in $sock->peername ],
              [ unpack_sockaddr_in $addr ], 'by host/service: $sock->getpeername is $addr' );

   is( $sock->sockhost, $INADDR_LOOPBACK_HOST, '$sock->sockhost is INADDR_LOOPBACK_HOST' );

   $listensock->accept; # Throw it away
}

SKIP: {
   # Some OSes can't bind(2) locally to other addresses on 127./8
   skip "Cannot bind to 127.0.0.2", 1 unless eval { IO::Socket::INET->new(
      LocalHost => "127.0.0.2", LocalPort => 0
   ) };

   # Some can bind(2) but then cannot connect() to 127.0.0.1 from it
   chomp($@), skip "Cannot connect to 127.0.0.1 from 127.0.0.2 - $@", 1 unless eval {
      my $s = IO::Socket::INET->new(
         LocalHost => "127.0.0.2", LocalPort => 0,
         PeerHost  => $listensock->sockhost, PeerPort => $listensock->sockport,
      ) or die $@;
      $listensock->accept; # Throw it away
      $s->sockhost eq "127.0.0.2" or die "sockhost is not 127.0.0.2\n"; };

   my $sock;

   $loop->connect(
      local_host => "127.0.0.2",
      host     => $listensock->sockhost,
      service  => $listensock->sockport,
      socktype => $listensock->socktype,
      on_connected => sub { $sock = shift; },
      on_resolve_error => sub { die "Test died early - resolve error - $_[-1]\n"; },
      on_connect_error => sub { die "Test died early - connect error $_[0]() - $_[-1]\n"; },
   );

   wait_for { $sock };

   is( $sock->sockhost, "127.0.0.2", '$sock->sockhost is 127.0.0.2' );

   $listensock->accept; # Throw it away
   undef $sock; # This too
}

# Now try on_stream event
{
   my $stream;

   $loop->connect(
      host     => $listensock->sockhost,
      service  => $listensock->sockport,
      socktype => $listensock->socktype,
      on_stream => sub { $stream = shift; },
      on_resolve_error => sub { die "Test died early - resolve error - $_[-1]\n"; },
      on_connect_error => sub { die "Test died early - connect error $_[0]() - $_[-1]\n"; },
   );

   wait_for { $stream };

   isa_ok( $stream, "IO::Async::Stream", 'on_stream $stream isa IO::Async::Stream' );
   my $sock = $stream->read_handle;
   is_deeply( [ unpack_sockaddr_in $sock->peername ],
              [ unpack_sockaddr_in $addr ], 'on_stream $sock->getpeername is $addr' );

   $listensock->accept; # Throw it away
}

my $udpsock = IO::Socket::INET->new( LocalAddr => 'localhost', Protocol => 'udp' ) or
   die "Cannot create udpsock - $!";

{
   my $future = $loop->connect(
      handle => my $given_socket = IO::Async::Socket->new,
      addr   => { family => "inet", socktype => "dgram", addr => $udpsock->sockname },
   );

   isa_ok( $future, "Future", '$future for ->connect( handle socket )' );

   wait_for { $future->is_ready };

   my $socket = $future->get;
   identical( $socket, $given_socket, '$future->get returns given Socket' );
   is_deeply( [ unpack_sockaddr_in $socket->read_handle->peername ],
              [ unpack_sockaddr_in $udpsock->sockname ], 'Returned $socket->read_handle->getpeername is $addr' );
}

# legacy callbacks
{
   my $sock;

   $loop->connect(
      addr => { family => "inet", socktype => "dgram", addr => $udpsock->sockname },
      on_socket => sub { $sock = shift; },
      on_connect_error => sub { die "Test died early - connect error $_[0]() - $_[-1]\n"; },
   );

   wait_for { $sock };

   isa_ok( $sock, "IO::Async::Socket", 'on_socket $sock isa IO::Async::Socket' );
   is_deeply( [ unpack_sockaddr_in $sock->read_handle->peername ],
              [ unpack_sockaddr_in $udpsock->sockname ], 'on_socket $sock->read_handle->getpeername is $addr' );
}

SKIP: {
   # Now try an address we know to be invalid - a UNIX socket that doesn't exist

   socket( my $dummy, AF_UNIX, SOCK_STREAM, 0 ) or
      skip "Cannot create AF_UNIX sockets - $!", 2;

   my $error;

   my $failop;
   my $failerr;

   $loop->connect(
      addr => { family => "unix", socktype => "stream", path => "/some/path/we/know/breaks" },
      on_connected => sub { die "Test died early - connect succeeded\n"; },
      on_fail => sub { $failop = shift @_; $failerr = pop @_; },
      on_connect_error => sub { $error = 1 },
   );

   wait_for { $error };

   is( $failop, "connect", '$failop is connect' );
   is( $failerr+0, ENOENT, '$failerr is ENOENT' );
}

SKIP: {
   socket( my $dummy, AF_UNIX, SOCK_STREAM, 0 ) or
      skip "Cannot create AF_UNIX sockets - $!", 2;

   my $failop;
   my $failerr;

   my $future = wait_for_future $loop->connect(
      addr => { family => "unix", socktype => "stream", path => "/some/path/we/know/breaks" },
      on_fail => sub { $failop = shift @_; $failerr = pop @_; },
   );

   is( $failop, "connect", '$failop is connect' );
   is( $failerr+0, ENOENT, '$failerr is ENOENT' );

   ok( $future->is_failed, '$future failed' );
   is( ( $future->failure )[2], "connect", '$future fail op is connect' );
   is( ( $future->failure )[3]+0, ENOENT, '$future fail err is ENOENT' );
}

# UNIX sockets always connect(2) synchronously, meaning if they fail, the error
# is available immediately. The above has therefore not properly tested
# asynchronous connect(2) failures. INET sockets should do this.

# First off we need a local socket that isn't listening - at lease one of the
# first 100 is likely not to be

my $port;
my $failure;

foreach ( 1 .. 100 ) {
   IO::Socket::INET->new( PeerHost => "127.0.0.1", PeerPort => $_ ) and next;

   $failure = "$!";
   $port = $_;

   last;
}

SKIP: {
   skip "Cannot find an un-connect(2)able socket on 127.0.0.1", 2 unless defined $port;

   my $failop;
   my $failerr;

   my @error;

   $loop->connect(
      addr => { family => "inet", socktype => "stream", port => $port, ip => "127.0.0.1" },
      on_connected => sub { die "Test died early - connect succeeded\n"; },
      on_fail => sub { $failop = shift @_; $failerr = pop @_; },
      on_connect_error => sub { @error = @_; },
   );

   wait_for { @error };

   is( $failop, "connect", '$failop is connect' );
   is( "$failerr", $failure, "\$failerr is '$failure'" );

   is( $error[0], "connect", '$error[0] is connect' );
   is( "$error[1]", $failure, "\$error[1] is '$failure'" );
}

done_testing;
