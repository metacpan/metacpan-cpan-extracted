#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Metrics::Any;

use Socket 1.93 qw( 
   AF_INET SOCK_STREAM SOCK_RAW INADDR_LOOPBACK AI_PASSIVE
   pack_sockaddr_in inet_aton getaddrinfo getnameinfo
);

use IO::Async::Loop;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

my $resolver = $loop->resolver;
isa_ok( $resolver, "IO::Async::Resolver", '$loop->resolver' );

SKIP: {
   my @pwuid;
   defined eval { @pwuid = getpwuid( $< ) } or
      skip "No getpwuid()", 5;

   {
      my $future = $resolver->resolve(
         type => 'getpwuid',
         data => [ $< ], 
      );

      isa_ok( $future, "Future", '$future' );

      wait_for { $future->is_ready };

      my @result = $future->get;

      is_deeply( \@result, \@pwuid, 'getpwuid from future' );
   }

   {
      my $result;

      $resolver->resolve(
         type => 'getpwuid',
         data => [ $< ], 
         on_resolved => sub { $result = [ @_ ] },
         on_error => sub { die "Test died early" },
      );

      wait_for { $result };

      is_deeply( $result, \@pwuid, 'getpwuid' );
   }

   {
      my $result;

      $loop->resolve(
         type => 'getpwuid',
         data => [ $< ],
         on_resolved => sub { $result = [ @_ ] },
         on_error => sub { die "Test died early" },
      );

      wait_for { $result };

      is_deeply( $result, \@pwuid, 'getpwuid via $loop->resolve' );
   }

   SKIP: {
      my $user_name = $pwuid[0];
      skip "getpwnam - No user name", 1 unless defined $user_name;

      my @pwnam = getpwnam( $user_name );

      my $result;

      $resolver->resolve(
         type => 'getpwnam',
         data => [ $user_name ],
         on_resolved => sub { $result = [ @_ ] },
         on_error => sub { die "Test died early" },
      );

      wait_for { $result };

      is_deeply( $result, \@pwnam, 'getpwnam' );
   }
}

my @proto = getprotobyname( "tcp" );

SKIP: {
   skip "getprotobyname - No protocol", 1 unless @proto;
   my $result;

   $resolver->resolve(
      type => 'getprotobyname',
      data => [ "tcp" ],
      on_resolved => sub { $result = [ @_ ] },
      on_error => sub { die "Test died early" },
   );

   wait_for { $result };

   is_deeply( $result, \@proto, 'getprotobyname' );
}

SKIP: {
   my $proto_number = $proto[2];
   skip "getprotobynumber - No protocol number", 1 unless defined $proto_number;

   my @proto = getprotobynumber( $proto_number );

   my $result;

   $resolver->resolve(
      type => 'getprotobynumber',
      data => [ $proto_number ],
      on_resolved => sub { $result = [ @_ ] },
      on_error => sub { die "Test died early" },
   );

   wait_for { $result };

   is_deeply( $result, \@proto, 'getprotobynumber' );
}

# Some systems seem to mangle the order of results between PF_INET and
# PF_INET6 depending on who asks. We'll hint AF_INET + SOCK_STREAM to minimise
# the risk of a spurious test failure because of ordering issues

my ( $localhost_err, @localhost_addrs ) = getaddrinfo( "localhost", "www", { family => AF_INET, socktype => SOCK_STREAM } );

{
   my $result;

   $resolver->resolve(
      type => 'getaddrinfo_array',
      data => [ "localhost", "www", "inet", "stream" ],
      on_resolved => sub { $result = [ 'resolved', @_ ] },
      on_error    => sub { $result = [ 'error',    @_ ] },
   );

   wait_for { $result };

   if( $localhost_err ) {
      is( $result->[0], "error", 'getaddrinfo_array - error' );
      is_deeply( $result->[1], "$localhost_err", 'getaddrinfo_array - error message' );
   }
   else {
      is( $result->[0], "resolved", 'getaddrinfo_array - resolved' );

      my @got = @{$result}[1..$#$result];
      my @expect = map { [ @{$_}{qw( family socktype protocol addr canonname )} ] } @localhost_addrs;

      is_deeply( \@got, \@expect, 'getaddrinfo_array - resolved addresses' );
   }
}

{
   my $result;

   $resolver->resolve(
      type => 'getaddrinfo_hash',
      data => [ host => "localhost", service => "www", family => "inet", socktype => "stream" ],
      on_resolved => sub { $result = [ 'resolved', @_ ] },
      on_error    => sub { $result = [ 'error',    @_ ] },
   );

   wait_for { $result };

   if( $localhost_err ) {
      is( $result->[0], "error", 'getaddrinfo_hash - error' );
      is_deeply( $result->[1], "$localhost_err", 'getaddrinfo_hash - error message' );
   }
   else {
      is( $result->[0], "resolved", 'getaddrinfo_hash - resolved' );

      my @got = @{$result}[1..$#$result];

      is_deeply( \@got, \@localhost_addrs, 'getaddrinfo_hash - resolved addresses' );
   }
}

{
   my $result;

   $resolver->getaddrinfo(
      host     => "localhost",
      service  => "www",
      family   => "inet",
      socktype => "stream",
      on_resolved => sub { $result = [ 'resolved', @_ ] },
      on_error    => sub { $result = [ 'error',    @_ ] },
   );

   wait_for { $result };

   if( $localhost_err ) {
      is( $result->[0], "error", '$resolver->getaddrinfo - error' );
      is_deeply( $result->[1], "$localhost_err", '$resolver->getaddrinfo - error message' );
   }
   else {
      is( $result->[0], "resolved", '$resolver->getaddrinfo - resolved' );

      my @got = @{$result}[1..$#$result];

      is_deeply( \@got, \@localhost_addrs, '$resolver->getaddrinfo - resolved addresses' );
   }
}

{
   my $future = $resolver->getaddrinfo(
      host     => "localhost",
      service  => "www",
      family   => "inet",
      socktype => "stream",
   );

   isa_ok( $future, "Future", '$future for $resolver->getaddrinfo' );

   wait_for { $future->is_ready };

   if( $localhost_err ) {
      is( scalar $future->failure, "$localhost_err", '$resolver->getaddrinfo - error message' );
      is( ( $future->failure )[1], "resolve", '->failure [1]' );
      is( ( $future->failure )[2], "getaddrinfo", '->failure [2]' );
   }
   else {
      my @got = $future->get;

      is_deeply( \@got, \@localhost_addrs, '$resolver->getaddrinfo - resolved addresses' );
   }
}

{
   my ( $lo_err, @lo_addrs ) = getaddrinfo( "127.0.0.1", "80", { socktype => SOCK_STREAM } );

   my $result;

   $resolver->getaddrinfo(
      host     => "127.0.0.1",
      service  => "80",
      socktype => SOCK_STREAM,
      on_resolved => sub { $result = [ 'resolved', @_ ] },
      on_error    => sub { $result = [ 'error',    @_ ] },
   );

   is( $result->[0], 'resolved', '$resolver->getaddrinfo on numeric host/service is synchronous' );

   my @got = @{$result}[1..$#$result];

   is_deeply( \@got, \@lo_addrs, '$resolver->getaddrinfo resolved addresses synchronously' );

   undef $result;
   $resolver->getaddrinfo(
      host        => "127.0.0.1",
      socktype    => SOCK_RAW,
      on_resolved => sub { $result = [ 'resolved', @_ ] },
      on_error    => sub { $result = [ 'error',    @_ ] },
   );

   is( $result->[0], 'resolved', '$resolver->getaddrinfo on numeric host/no service is synchronous' );

   my @got_sinaddrs = map { $_->{addr} } @{$result}[1..$#$result];

   is_deeply( \@got_sinaddrs, [ map { pack_sockaddr_in( 0, inet_aton "127.0.0.1" ) } @got_sinaddrs ],
      '$resolver->getaddrinfo resolved addresses synchronously with no service' );
}

{
   my ( $passive_err, @passive_addrs ) = getaddrinfo( "", "3000", { socktype => SOCK_STREAM, family => AF_INET, flags => AI_PASSIVE } );

   my $result;

   $resolver->getaddrinfo(
      family   => "inet",
      service  => "3000",
      socktype => "stream",
      passive  => 1,
      on_resolved => sub { $result = [ 'resolved', @_ ] },
      on_error    => sub { $result = [ 'error',    @_ ] },
   );

   if( $passive_err ) {
      is( $result->[0], "error", '$resolver->getaddrinfo passive - error synchronously' );
      is_deeply( $result->[1], "$passive_err", '$resolver->getaddrinfo passive - error message' );
   }
   else {
      is( $result->[0], "resolved", '$resolver->getaddrinfo passive - resolved synchronously' );

      my @got = @{$result}[1..$#$result];

      is_deeply( \@got, \@passive_addrs, '$resolver->getaddrinfo passive - resolved addresses' );
   }
}

{
   my ( $lo_err, @lo_addrs ) = getaddrinfo( "127.0.0.1", "80", { socktype => SOCK_STREAM } );

   my $future = $resolver->getaddrinfo(
      host     => "127.0.0.1",
      service  => "80",
      socktype => SOCK_STREAM,
   );

   isa_ok( $future, "Future", '$future for $resolver->getaddrinfo numerical' );

   wait_for { $future->is_ready };

   my @got = $future->get;

   is_deeply( \@got, \@lo_addrs, '$resolver->getaddrinfo resolved addresses synchronously' );
}

# Now something I hope doesn't exist - we put it in a known-missing TLD
my $missinghost = "TbK4jM2M0OS.lm57DWIyu4i";

# Some CPAN testing machines seem to have wildcard DNS servers that reply to
# any request. We'd better check for them

SKIP: {
    skip "Resolver has an answer for $missinghost", 1 if gethostbyname( $missinghost );

    my $future = wait_for_future $resolver->getaddrinfo(
       host     => $missinghost,
       service  => "80",
       socktype => SOCK_STREAM,
    );

    ok( $future->failure, '$future failed for missing host' );
    is( ( $future->failure )[1], "resolve", '->failure [1] gives resolve' );
    is( ( $future->failure )[2], "getaddrinfo", '->failure [2] gives getaddrinfo' );

    my $errno = ( $future->failure )[3];
    ok( $errno == Socket::EAI_FAIL || $errno == Socket::EAI_AGAIN || # no server available
        $errno == Socket::EAI_NONAME || $errno == Socket::EAI_NODATA, # server confirmed no DNS entry
        '->failure [3] gives EAI_FAIL or EAI_AGAIN or EAI_NONAME or EAI_NODATA' ) or
      diag( '$errno is ' . $errno );
}

my $testaddr = pack_sockaddr_in( 80, INADDR_LOOPBACK );
my ( $testerr, $testhost, $testserv ) = getnameinfo( $testaddr );

{
   my $result;

   $resolver->getnameinfo(
      addr => $testaddr,
      on_resolved => sub { $result = [ 'resolved', @_ ] },
      on_error    => sub { $result = [ 'error',    @_ ] },
   );

   wait_for { $result };

   if( $testerr ) {
      is( $result->[0], "error", '$resolver->getnameinfo - error' );
      is_deeply( $result->[1], "$testerr", '$resolver->getnameinfo - error message' );
   }
   else {
      is( $result->[0], "resolved", '$resolver->getnameinfo - resolved' );
      is_deeply( [ @{$result}[1..2] ], [ $testhost, $testserv ], '$resolver->getnameinfo - resolved names' );
   }
}

{
   my $future = wait_for_future $resolver->getnameinfo(
      addr => $testaddr,
   );

   if( $testerr ) {
      is( scalar $future->failure, "$testerr", '$resolver->getnameinfo - error message from future' );
      is( ( $future->failure )[1], "resolve", '->failure [1]' );
      is( ( $future->failure )[2], "getnameinfo", '->failure [2]' );
   }
   else {
      my @got = $future->get;

      is_deeply( \@got, [ $testhost, $testserv ], '$resolver->getnameinfo - resolved names from future' );
   }
}

{
   my $result;

   $resolver->getnameinfo(
      addr    => $testaddr,
      numeric => 1,
      on_resolved => sub { $result = [ 'resolved', @_ ] },
      on_error    => sub { $result = [ 'error',    @_ ] },
   );

   is_deeply( $result, [ resolved => "127.0.0.1", 80 ], '$resolver->getnameinfo with numeric is synchronous' );
}

{
   my $future = $resolver->getnameinfo(
      addr    => $testaddr,
      numeric => 1,
   );

   is_deeply( [ $future->get ], [ "127.0.0.1", 80 ], '$resolver->getnameinfo with numeric is synchronous for future' );
}

# Metrics
SKIP: {
   skip "Metrics are unavailable" unless $IO::Async::Metrics::METRICS;

   is_metrics_from(
      sub {
         $resolver->getnameinfo( addr => $testaddr )->get;
      },
      { "io_async_resolver_lookups type:getnameinfo" => 1 },
      'Resolver increments metrics'
   );

   # Can't easily unit-test the failure counter because we can't guarantee to
   # create a failure
}

# $loop->set_resolver
{
   my $callcount = 0;
   {
      package MockResolver;
      use base qw( IO::Async::Notifier );

      sub new { bless {}, shift }

      sub resolve {
         $callcount++; return Future->done();
      }
      sub getaddrinfo {}
      sub getnameinfo {}
   }

   $loop->set_resolver( MockResolver->new );

   $loop->resolve( type => "getpwuid", data => [ 0 ] )->get;

   is( $callcount, 1, '$callcount 1 after ->resolve' );
}

done_testing;
