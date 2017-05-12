#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Identity;

use IO::Socket::INET;

use Socket qw( inet_ntoa unpack_sockaddr_in );

use IO::Async::Loop;

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

{
   my $listensock = IO::Socket::INET->new(
      LocalAddr => "localhost",
      Type      => SOCK_STREAM,
      Listen    => 1,
   ) or die "Cannot socket() - $!";

   my $newclient;

   my $f = $loop->listen(
      handle => $listensock,
      on_accept => sub { $newclient = $_[0]; },
   );

   ok( $f->is_ready, '$loop->listen on handle ready synchronously' );

   my $notifier = $f->get;
   isa_ok( $notifier, "IO::Async::Notifier", 'synchronous on_notifier given a Notifier' );

   identical( $notifier->loop, $loop, 'synchronous $notifier->loop is $loop' );

   my $clientsock = IO::Socket::INET->new( Type => SOCK_STREAM )
      or die "Cannot socket() - $!";

   $clientsock->connect( $listensock->sockname ) or die "Cannot connect() - $!";

   ok( defined $clientsock->peername, '$clientsock is connected' );

   wait_for { defined $newclient };

   is_deeply( [ unpack_sockaddr_in $newclient->peername ],
              [ unpack_sockaddr_in $clientsock->sockname ], '$newclient peer is correct' );
}

{
   my $listensock;
   my $newclient;

   my $f = $loop->listen(
      family   => "inet",
      socktype => "stream",
      service  => "", # Ask the kernel to allocate a port for us
      host     => "localhost",

      on_listen => sub { $listensock = $_[0]; },

      on_accept => sub { $newclient = $_[0]; },
   );

   my $notifier = $f->get;

   ok( defined $listensock->fileno, '$listensock has a fileno' );
   # Not sure if it'll be an IO::Socket::INET or ::IP, but either way it should support these
   can_ok( $listensock, qw( peerhost peerport ) );

   isa_ok( $notifier, "IO::Async::Notifier", 'asynchronous on_notifier given a Notifier' );

   identical( $notifier->loop, $loop, 'asynchronous $notifier->loop is $loop' );

   my $listenaddr = $listensock->sockname;

   ok( defined $listenaddr, '$listensock has address' );

   my ( $listenport, $listen_inaddr ) = unpack_sockaddr_in( $listenaddr );

   is( inet_ntoa( $listen_inaddr ), $INADDR_LOOPBACK_HOST, '$listenaddr is INADDR_LOOPBACK' );

   my $clientsock = IO::Socket::INET->new( Type => SOCK_STREAM )
      or die "Cannot socket() - $!";

   $clientsock->connect( $listenaddr ) or die "Cannot connect() - $!";

   is( (unpack_sockaddr_in( $clientsock->peername ))[0], $listenport, '$clientsock on the correct port' );

   wait_for { defined $newclient };

   can_ok( $newclient, qw( peerhost peerport ) );

   is_deeply( [ unpack_sockaddr_in $newclient->peername ],
              [ unpack_sockaddr_in $clientsock->sockname ], '$newclient peer is correct' );
}

# Now we want to test failure. It's hard to know in a test script what will
# definitely fail, but it's likely we're either running as non-root, or the
# machine has at least one of an SSH or a webserver running. In this case,
# it's likely we'll fail to bind TCP port 22 or 80.

my $badport;
my $failure;
foreach my $port ( 22, 80 ) {
   IO::Socket::INET->new(
      Type      => SOCK_STREAM,
      LocalHost => "localhost",
      LocalPort => $port,
      ReuseAddr => 1,
      Listen    => 1,
   ) and next;
      
   $badport = $port;
   $failure = $!;
   last;
}

SKIP: {
   skip "No bind()-failing ports found", 6 unless defined $badport;

   my $failop;
   my $failerr;

   my @error;

   # We need to capture the Listener object before failure, so we can assert
   # it gets removed from the Loop again afterwards
   my $listener;
   no warnings 'redefine';
   my $add = IO::Async::Loop->can( "add" );
   local *IO::Async::Loop::add = sub {
      $listener = $_[1];
      $add->( @_ );
   };

   $loop->listen(
      family   => "inet",
      socktype => "stream",
      host     => "localhost",
      service  => $badport,

      on_resolve_error => sub { die "Test died early - resolve error $_[0]\n"; },

      on_listen => sub { die "Test died early - listen on port $badport actually succeeded\n"; },

      on_accept => sub { "DUMMY" }, # really hope this doesn't happen ;)

      on_fail => sub { $failop = shift; $failerr = pop; },
      on_listen_error => sub { @error = @_; },
   );

   ok( defined $listener, 'Managed to capture listener being added to Loop' );

   wait_for { @error };

   is( $failop, "bind", '$failop is bind' );
   is( "$failerr", $failure, "\$failerr is '$failure'" );

   is( $error[0], "bind", '$error[0] is bind' );
   is( "$error[1]", $failure, "\$error[1] is '$failure'" );

   ok( defined $listener, '$listener defined after bind failure' );
   ok( !$listener->loop, '$listener not in loop after bind failure' );
}

done_testing;
