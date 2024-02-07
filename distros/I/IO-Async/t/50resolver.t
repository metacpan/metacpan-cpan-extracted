#!/usr/bin/perl

use v5.14;
use warnings;

use IO::Async::Test;

use Test2::V0;
use Test::Metrics::Any;

use Socket 1.93 qw( 
   AF_INET SOCK_STREAM SOCK_DGRAM SOCK_RAW INADDR_LOOPBACK INADDR_ANY
   AI_NUMERICHOST AI_PASSIVE NI_NUMERICHOST NI_NUMERICSERV
   pack_sockaddr_in unpack_sockaddr_in sockaddr_family inet_aton inet_ntoa
);

use IO::Async::Loop;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

my $resolver = $loop->resolver;
isa_ok( $resolver, [ "IO::Async::Resolver" ], '$loop->resolver isa IO::Async::Resolver' );

SKIP: {
   my @pwuid;
   defined eval { @pwuid = getpwuid( $< ) } or
      skip "No getpwuid()", 5;

   {
      my $future = $resolver->resolve(
         type => 'getpwuid',
         data => [ $< ], 
      );

      isa_ok( $future, [ "Future" ], '$future isa Future' );

      wait_for { $future->is_ready };

      my @result = $future->get;

      is( \@result, \@pwuid, 'getpwuid from future' );
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

      is( $result, \@pwuid, 'getpwuid' );
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

      is( $result, \@pwuid, 'getpwuid via $loop->resolve' );
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

      is( $result, \@pwnam, 'getpwnam' );
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

   is( $result, \@proto, 'getprotobyname' );
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

   is( $result, \@proto, 'getprotobynumber' );
}

BEGIN {
   # Rather than suffer various test failures because system resolver behaves
   # in a weird way when testing, lets just mock it out and replace it with a
   # virtual one so we can control the results
   no warnings 'redefine';

   *Socket::getaddrinfo = sub {
      my ( $host, $service, $hints ) = @_;

      my $hint_flags    = $hints->{flags} // 0;
      my $hint_family   = $hints->{family};
      my $hint_socktype = $hints->{socktype};

      die "TODO: fake getaddrinfo on unrecognised family" if $hint_family and $hint_family != AF_INET;

      my $flag_numerichost = $hint_flags & AI_NUMERICHOST;

      return ( Socket::EAI_FAIL ) if $host =~ m/\.FAIL$/;

      my $inaddr;
      $inaddr = inet_aton( "1.2.3.4" ) if !$flag_numerichost and $host eq "one.FAKE";
      $inaddr = INADDR_LOOPBACK        if                        $host eq "127.0.0.1";
      $inaddr = INADDR_ANY             if $hint_flags & AI_PASSIVE and !$host;

      defined $inaddr or
         die "TODO: Unsure how to fake getaddrinfo on host=$host";

      my $port = 0;
      $port = $service+0 if $service =~ m/^\d+$/;
      $port = 80 if $service eq "www";

      my $addr = pack_sockaddr_in( $port, $inaddr );

      my @res = map {
         { family => AF_INET, socktype => $_, protocol => 0, addr => $addr }
      } grep { !$hint_socktype or $_ == $hint_socktype } ( SOCK_STREAM, SOCK_DGRAM, SOCK_RAW );

      return ( "", @res );
   };

   *Socket::getnameinfo = sub {
      my ( $addr, $flags ) = @_;

      my $family = sockaddr_family $addr;
      $family == AF_INET or
         die "TODO: Unsure how to fake getnameinfo on family=$family";

      my ( $port, $inaddr ) = unpack_sockaddr_in $addr;
      $inaddr eq INADDR_LOOPBACK or
         die "TODO: Unsure how to fake getnameinfo on inaddr!=INADDR_LOOPBACK";

      my $host;
      if( $flags & NI_NUMERICHOST ) {
         $host = inet_ntoa( $inaddr );
      }
      else {
         $host = "localhost";
      }

      my $service;
      if( $flags & NI_NUMERICSERV ) {
         $service = $port;
      }
      elsif( $port == 80 ) {
         $service = "www";
      }
      else {
         die "TODO: convert port=$port to service name";
      }

      return ( "", $host, $service );
   };
}

my @expect_one_www = (
   { family => AF_INET, socktype => SOCK_STREAM, protocol => 0, addr => pack_sockaddr_in(80, inet_aton("1.2.3.4")) },
);
my @expect_lo_80 = (
   { family => AF_INET, socktype => SOCK_STREAM, protocol => 0, addr => pack_sockaddr_in(80, INADDR_LOOPBACK) },
);
my @expect_passive_3000 = (
   { family => AF_INET, socktype => SOCK_STREAM, protocol => 0, addr => pack_sockaddr_in(3000, INADDR_ANY) },
);

{
   my $result;

   $resolver->resolve(
      type => 'getaddrinfo_array',
      data => [ "one.FAKE", "www", "inet", "stream" ],
      on_resolved => sub { $result = [ 'resolved', @_ ] },
      on_error    => sub { $result = [ 'error',    @_ ] },
   );

   wait_for { $result };

   is( $result->[0], "resolved", 'getaddrinfo_array - resolved' );

   my @got = @{$result}[1..$#$result];
   my @expect = map { [ @{$_}{qw( family socktype protocol addr canonname )} ] } @expect_one_www;

   is( \@got, \@expect, 'getaddrinfo_array - resolved addresses' );
}

{
   my $result;

   $resolver->resolve(
      type => 'getaddrinfo_hash',
      data => [ host => "one.FAKE", service => "www", family => "inet", socktype => "stream" ],
      on_resolved => sub { $result = [ 'resolved', @_ ] },
      on_error    => sub { $result = [ 'error',    @_ ] },
   );

   wait_for { $result };

   is( $result->[0], "resolved", 'getaddrinfo_hash - resolved' );

   my @got = @{$result}[1..$#$result];

   is( \@got, \@expect_one_www, 'getaddrinfo_hash - resolved addresses' );
}

{
   my $result;

   $resolver->getaddrinfo(
      host     => "one.FAKE",
      service  => "www",
      family   => "inet",
      socktype => "stream",
      on_resolved => sub { $result = [ 'resolved', @_ ] },
      on_error    => sub { $result = [ 'error',    @_ ] },
   );

   wait_for { $result };

   is( $result->[0], "resolved", '$resolver->getaddrinfo - resolved' );

   my @got = @{$result}[1..$#$result];

   is( \@got, \@expect_one_www, '$resolver->getaddrinfo - resolved addresses' );
}

{
   my $future = $resolver->getaddrinfo(
      host     => "one.FAKE",
      service  => "www",
      family   => "inet",
      socktype => "stream",
   );

   isa_ok( $future, [ "Future" ], '$future for $resolver->getaddrinfo isa Future' );

   wait_for { $future->is_ready };

   my @got = $future->get;

   is( \@got, \@expect_one_www, '$resolver->getaddrinfo - resolved addresses' );
}

{
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

   is( \@got, \@expect_lo_80, '$resolver->getaddrinfo resolved addresses synchronously' );

   undef $result;
   $resolver->getaddrinfo(
      host        => "127.0.0.1",
      socktype    => SOCK_RAW,
      on_resolved => sub { $result = [ 'resolved', @_ ] },
      on_error    => sub { $result = [ 'error',    @_ ] },
   );

   is( $result->[0], 'resolved', '$resolver->getaddrinfo on numeric host/no service is synchronous' );

   my @got_sinaddrs = map { $_->{addr} } @{$result}[1..$#$result];

   is( \@got_sinaddrs, [ map { pack_sockaddr_in( 0, inet_aton "127.0.0.1" ) } @got_sinaddrs ],
      '$resolver->getaddrinfo resolved addresses synchronously with no service' );
}

{
   my $result;

   $resolver->getaddrinfo(
      family   => "inet",
      service  => "3000",
      socktype => "stream",
      passive  => 1,
      on_resolved => sub { $result = [ 'resolved', @_ ] },
      on_error    => sub { $result = [ 'error',    @_ ] },
   );

   is( $result->[0], "resolved", '$resolver->getaddrinfo passive - resolved synchronously' );

   my @got = @{$result}[1..$#$result];

   is( \@got, \@expect_passive_3000, '$resolver->getaddrinfo passive - resolved addresses' );
}

{
   my $future = $resolver->getaddrinfo(
      host     => "127.0.0.1",
      service  => "80",
      socktype => SOCK_STREAM,
   );

   isa_ok( $future, [ "Future" ], '$future for $resolver->getaddrinfo numerical isa Future' );

   wait_for { $future->is_ready };

   my @got = $future->get;

   is( \@got, \@expect_lo_80, '$resolver->getaddrinfo resolved addresses synchronously' );
}

{
    my $future = wait_for_future $resolver->getaddrinfo(
       host     => "a-name-to.FAIL",
       service  => "80",
       socktype => SOCK_STREAM,
    );

    ok( $future->failure, '$future failed for missing host' );
    is( ( $future->failure )[1], "resolve", '->failure [1] gives resolve' );
    is( ( $future->failure )[2], "getaddrinfo", '->failure [2] gives getaddrinfo' );

    my $errno = ( $future->failure )[3];
    is( $errno, Socket::EAI_FAIL, '->failure [3] gives EAI_FAIL' );
}

my $sinaddr_lo_www = pack_sockaddr_in( 80, INADDR_LOOPBACK );

{
   my $result;

   $resolver->getnameinfo(
      addr => $sinaddr_lo_www,
      on_resolved => sub { $result = [ 'resolved', @_ ] },
      on_error    => sub { $result = [ 'error',    @_ ] },
   );

   wait_for { $result };

   is( $result->[0], "resolved", '$resolver->getnameinfo - resolved' );
   is( [ @{$result}[1..2] ], [ "localhost", "www" ], '$resolver->getnameinfo - resolved names' );
}

{
   my $future = wait_for_future $resolver->getnameinfo(
      addr => $sinaddr_lo_www,
   );

   my @got = $future->get;

   is( \@got, [ "localhost", "www" ], '$resolver->getnameinfo - resolved names from future' );
}

{
   my $result;

   $resolver->getnameinfo(
      addr    => $sinaddr_lo_www,
      numeric => 1,
      on_resolved => sub { $result = [ 'resolved', @_ ] },
      on_error    => sub { $result = [ 'error',    @_ ] },
   );

   is( $result, [ resolved => "127.0.0.1", 80 ], '$resolver->getnameinfo with numeric is synchronous' );
}

{
   my $future = $resolver->getnameinfo(
      addr    => $sinaddr_lo_www,
      numeric => 1,
   );

   is( [ $future->get ], [ "127.0.0.1", 80 ], '$resolver->getnameinfo with numeric is synchronous for future' );
}

# Metrics
SKIP: {
   skip "Metrics are unavailable" unless $IO::Async::Metrics::METRICS;

   is_metrics_from(
      sub {
         $resolver->getnameinfo( addr => $sinaddr_lo_www )->get;
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
