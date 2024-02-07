#!/usr/bin/perl

use v5.14;
use warnings;

use IO::Async::Test;

use Test2::V0 0.000149;

use IO::Async::Loop;

use IO::Socket::INET;

use IO::Async::Listener;

# Some odd locations like BSD jails might not like INADDR_ANY. We'll establish
# a baseline first to test against
my $INADDR_ANY = do {
   my $anysock = IO::Socket::INET->new( LocalPort => 0, Listen => 1 );
   $anysock->sockaddr;
};
my $INADDR_ANY_HOST = inet_ntoa( $INADDR_ANY );
if( $INADDR_ANY ne INADDR_ANY ) {
   diag( "Testing with INADDR_ANY=$INADDR_ANY_HOST; this may be because of odd networking" );
}

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

my $listensock;

$listensock = IO::Socket::INET->new(
   LocalAddr => "localhost",
   Type      => SOCK_STREAM,
   Listen    => 1,
   Blocking  => 0,
) or die "Cannot socket() - $!";


{
   my $newclient;
   my $listener = IO::Async::Listener->new(
      handle => $listensock,
      on_accept => sub { ( undef, $newclient ) = @_ },
   );

   ok( defined $listener, 'defined $listener' );
   isa_ok( $listener, [ "IO::Async::Listener" ], '$listener isa IO::Async::Listener' );
   isa_ok( $listener, [ "IO::Async::Notifier" ], '$listener isa IO::Async::Notifier' );

   is_oneref( $listener, '$listener has refcount 1 initially' );

   ok( $listener->is_listening, '$listener is_listening' );
   is( [ unpack_sockaddr_in $listener->sockname ],
              [ unpack_sockaddr_in $listensock->sockname ], '$listener->sockname' );

   is( $listener->family,   AF_INET,     '$listener->family' );
   is( $listener->socktype, SOCK_STREAM, '$listener->sockname' );

   $loop->add( $listener );

   is_refcount( $listener, 2, '$listener has refcount 2 after adding to Loop' );

   my $clientsock = IO::Socket::INET->new( Type => SOCK_STREAM )
      or die "Cannot socket() - $!";

   $clientsock->connect( $listensock->sockname ) or die "Cannot connect() - $!";

   ok( defined $clientsock->peername, '$clientsock is connected' );

   wait_for { defined $newclient };

   is( [ unpack_sockaddr_in $newclient->peername ],
              [ unpack_sockaddr_in $clientsock->sockname ], '$newclient peer is correct' );

   is_refcount( $listener, 2, '$listener has refcount 2 before removing from Loop' );

   $loop->remove( $listener );

   is_oneref( $listener, '$listener has refcount 1 after removing from Loop' );
}

# on_accept handle constructors
{
   my $accepted;
   my $listener = IO::Async::Listener->new(
      handle => $listensock,
      on_accept => sub { ( undef, $accepted ) = @_ },
   );

   $loop->add( $listener );

   require IO::Async::Stream;

   # handle_constructor
   {
      $listener->configure( handle_constructor => sub {
         return IO::Async::Stream->new;
      } );

      my $clientsock = IO::Socket::INET->new( Type => SOCK_STREAM )
         or die "Cannot socket() - $!";

      $clientsock->connect( $listensock->sockname ) or die "Cannot connect() - $!";

      wait_for { defined $accepted };

      isa_ok( $accepted, [ "IO::Async::Stream" ], '$accepted with handle_constructor' );
      undef $accepted;
   }

   # handle_class
   {
      $listener->configure( handle_class => "IO::Async::Stream" );

      my $clientsock = IO::Socket::INET->new( Type => SOCK_STREAM )
         or die "Cannot socket() - $!";

      $clientsock->connect( $listensock->sockname ) or die "Cannot connect() - $!";

      wait_for { defined $accepted };

      isa_ok( $accepted, [ "IO::Async::Stream" ], '$accepted with handle_constructor' );
      undef $accepted;
   }

   $loop->remove( $listener );
}

# on_stream
{
   my $newstream;
   my $listener = IO::Async::Listener->new(
      handle => $listensock,
      on_stream => sub { ( undef, $newstream ) = @_ },
   );

   $loop->add( $listener );

   my $clientsock = IO::Socket::INET->new( Type => SOCK_STREAM )
      or die "Cannot socket() - $!";

   $clientsock->connect( $listensock->sockname ) or die "Cannot connect() - $!";

   wait_for { defined $newstream };

   isa_ok( $newstream, [ "IO::Async::Stream" ], 'on_stream $newstream isa IO::Async::Stream' );
   is( [ unpack_sockaddr_in $newstream->read_handle->peername ],
              [ unpack_sockaddr_in $clientsock->sockname ], '$newstream sock peer is correct' );

   $loop->remove( $listener );
}

# on_socket
{
   my $newsocket;
   my $listener = IO::Async::Listener->new(
      handle => $listensock,
      on_socket => sub { ( undef, $newsocket ) = @_ },
   );

   $loop->add( $listener );

   my $clientsock = IO::Socket::INET->new( Type => SOCK_STREAM )
      or die "Cannot socket() - $!";

   $clientsock->connect( $listensock->sockname ) or die "Cannot connect() - $!";

   wait_for { defined $newsocket };

   isa_ok( $newsocket, [ "IO::Async::Socket" ], 'on_socket $newsocket isa IO::Async::Socket' );
   is( [ unpack_sockaddr_in $newsocket->read_handle->peername ],
              [ unpack_sockaddr_in $clientsock->sockname ], '$newsocket sock peer is correct' );

   $loop->remove( $listener );
}

# stop listening
{
   my $listener = IO::Async::Listener->new(
      handle => $listensock,
      on_accept => sub {},
   );

   $loop->add( $listener );

   $listener->configure( handle => undef );

   is( $listener->read_handle, undef, '$listener has no read handle any more' );

   $loop->remove( $listener );
}

# Subclass
{
   my $sub_newclient;
   {
      package TestListener;
      use base qw( IO::Async::Listener );

      sub on_accept { ( undef, $sub_newclient ) = @_ }
   }

   my $listener = TestListener->new(
      handle => $listensock,
   );

   ok( defined $listener, 'subclass defined $listener' );
   isa_ok( $listener, [ "IO::Async::Listener" ], 'subclass $listener isa IO::Async::Listener' );

   is_oneref( $listener, 'subclass $listener has refcount 1 initially' );

   $loop->add( $listener );

   is_refcount( $listener, 2, 'subclass $listener has refcount 2 after adding to Loop' );

   my $clientsock = IO::Socket::INET->new( LocalAddr => "127.0.0.1", Type => SOCK_STREAM )
      or die "Cannot socket() - $!";

   $clientsock->connect( $listensock->sockname ) or die "Cannot connect() - $!";

   ok( defined $clientsock->peername, 'subclass $clientsock is connected' );

   wait_for { defined $sub_newclient };

   is( [ unpack_sockaddr_in $sub_newclient->peername ],
              [ unpack_sockaddr_in $clientsock->sockname ], '$sub_newclient peer is correct' );

   is_refcount( $listener, 2, 'subclass $listener has refcount 2 before removing from Loop' );

   $loop->remove( $listener );

   is_oneref( $listener, 'subclass $listener has refcount 1 after removing from Loop' );
}

# Subclass with handle_constructor
{
   {
      package TestListener::WithConstructor;
      use base qw( IO::Async::Listener );

      sub handle_constructor { return IO::Async::Stream->new }
   }

   my $accepted;

   my $listener = TestListener::WithConstructor->new(
      handle => $listensock,
      on_accept => sub { ( undef, $accepted ) = @_; },
   );

   $loop->add( $listener );

   my $clientsock = IO::Socket::INET->new( Type => SOCK_STREAM )
      or die "Cannot socket() - $!";

   $clientsock->connect( $listensock->sockname ) or die "Cannot connect() - $!";

   wait_for { defined $accepted };

   isa_ok( $accepted, [ "IO::Async::Stream" ], '$accepted with handle_constructor method' );

   $loop->remove( $listener );
}

{
   my $newclient;
   my $listener = IO::Async::Listener->new(
      on_accept => sub { ( undef, $newclient ) = @_ },
   );

   ok( !$listener->is_listening, '$listener is_listening not yet' );

   $loop->add( $listener );

   my $listen_self;

   $listener->listen(
      addr => { family => "inet", socktype => "stream", addr => pack_sockaddr_in( 0, $INADDR_ANY ) },
      on_listen => sub { $listen_self = shift },
      on_listen_error => sub { die "Test died early - $_[0] - $_[-1]\n"; },
   );

   ok( $listener->is_listening, '$listener is_listening' );

   my $sockname = $listener->sockname;
   ok( defined $sockname, 'defined $sockname' );

   my ( $port, $sinaddr ) = unpack_sockaddr_in( $sockname );

   ok( $port > 0, 'socket listens on some defined port number' );
   is( inet_ntoa( $sinaddr ), $INADDR_ANY_HOST, 'socket listens on INADDR_ANY' );

   is( $listener->family,   AF_INET,     '$listener->family' );
   is( $listener->socktype, SOCK_STREAM, '$listener->sockname' );

   ref_is( $listen_self, $listener, '$listen_self is $listener' );
   undef $listen_self; # for refcount

   my $clientsock = IO::Socket::INET->new( Type => SOCK_STREAM )
      or die "Cannot socket() - $!";

   $clientsock->connect( pack_sockaddr_in( $port, INADDR_LOOPBACK ) ) or die "Cannot connect() - $!";

   ok( defined $clientsock->peername, '$clientsock is connected' );

   wait_for { defined $newclient };

   is( [ unpack_sockaddr_in $newclient->peername ],
              [ unpack_sockaddr_in $clientsock->sockname ], '$newclient peer is correct' );

   $loop->remove( $listener );
}

done_testing;
