#!/usr/bin/env perl
# ABSTRACT: a connect-time module that fails to load fails the request instead of wedging the host's connection slot
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

BEGIN {
  eval { require Net::Async::HTTP; require IO::Async::Loop; 1 }
    or plan skip_all => 'Requires Net::Async::HTTP and IO::Async';
}

use IO::Socket::INET;
use HTTP::Request;
use HTTP::Response;
use Test::LocalHTTPDaemon;
use Langertha::Content::Image;
use Langertha::Engine::OllamaOpenAI;
use Langertha::HTTP::ConnectCheck;

# Net::Async::HTTP loads some modules only when it opens a connection:
# IO::Async::Internals::Connector for every connection, IO::Async::SSL for
# https. When that load dies (a partial upgrade, no libssl), Net::Async::HTTP
# 0.50 keeps the connection slot for the host taken, so every later request to
# that host -- even once the module loads -- waits forever. With the default
# one connection per host that is every request of the engine to its provider.
# Core checks those modules before it hands a request to Net::Async::HTTP: a
# broken install is an error naming the module, and the slot is never taken.
# (karr k353, from langertha-raider k107; ADR 0027)

# Stands in for a broken install: a blocked file dies when required. That only
# works while the modules are still unloaded, so check right here, after every
# `use` above has run.
plan skip_all => 'IO::Async::Internals::Connector or IO::Async::SSL is already loaded'
  if $INC{'IO/Async/Internals/Connector.pm'} || $INC{'IO/Async/SSL.pm'};
my %blocked = map { $_ => 1 } qw( IO/Async/Internals/Connector.pm IO/Async/SSL.pm );
unshift @INC, sub {
  my ( undef, $file ) = @_;
  die "Can't locate $file (blocked by the test)\n" if $blocked{$file};
  return;
};

my $png = "\x89PNG-connect";
my $server = Test::LocalHTTPDaemon->start( sub {
  my ($req) = @_;
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'image/png' ], $png )
    if $req->uri->path eq '/a.png';
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/plain' ], 'pong' );
} );
my $base = $server->url;
( my $hostport = $base ) =~ s{\Ahttp://}{};

# A port nothing listens on, for the https engine: once IO::Async::SSL loads,
# its request must fail fast (connection refused), not wait on a taken slot.
my $closed_port = do {
  my $sock = IO::Socket::INET->new( Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0 )
    or die "cannot bind: $!";
  my $port = $sock->sockport;
  close $sock;
  $port;
};

my $http_engine  = Langertha::Engine::OllamaOpenAI->new( url => "$base/v1", model => 'm' );
my $https_engine = Langertha::Engine::OllamaOpenAI->new(
  url => "https://127.0.0.1:$closed_port/v1", model => 'm' );
isa_ok $http_engine->_async_http, ['Net::Async::HTTP'], 'the default backend';
my $loop = $http_engine->async_loop;

# Runs a request future to completion, or reports HANG after a few seconds.
sub settle {
  my ($future) = @_;
  my $guarded = Future->wait_any( $future,
    $loop->delay_future( after => 5 )->then_fail("HANG\n") );
  $loop->await($guarded);
  return $guarded->is_failed ? ( undef, scalar $guarded->failure ) : ( $guarded->get, undef );
}
sub get_f {
  my ( $engine, $url ) = @_;
  return $engine->async_request_f( HTTP::Request->new( GET => $url ) );
}

my $connector_error = qr/IO::Async::Internals::Connector failed to load \(Can't locate IO\/Async\/Internals\/Connector\.pm \(blocked by the test\)\); every HTTP connection needs it/;
my $ssl_error = qr/IO::Async::SSL failed to load \(Can't locate IO\/Async\/SSL\.pm \(blocked by the test\)\); an SSL \(https\) connection needs it/;

# --- Connector (and SSL) broken ---------------------------------------------

{
  my ( $res, $err ) = settle( get_f( $http_engine, "$base/ping" ) );
  ok !$res, 'Connector missing: the request does not succeed';
  like $err, qr/\ALangertha::Engine::OllamaOpenAI: cannot connect to http:\/\/\Q$hostport\E: $connector_error/,
    '... it fails naming the engine, the target and the module';

  ( $res, $err ) = settle( get_f( $https_engine, "https://127.0.0.1:$closed_port/ping" ) );
  like $err, qr/cannot connect to https:\/\/127\.0\.0\.1:$closed_port: $connector_error/,
    'https: the Connector is checked first';

  my $image = Langertha::Content::Image->from_url("$base/a.png");
  ( $res, $err ) = settle( $image->ensure_base64_f( $http_engine->_async_http ) );
  like $err, qr/\Aensure_base64: failed to fetch \Q$base\E\/a\.png: cannot connect to http:\/\/\Q$hostport\E: $connector_error/,
    'image fetch over Net::Async::HTTP: the same check, in the fetch error';
}

# --- Connector loads again, SSL still broken --------------------------------

delete $blocked{'IO/Async/Internals/Connector.pm'};

{
  my ( $res, $err ) = settle( get_f( $http_engine, "$base/ping" ) );
  ok !defined $err, 'Connector back: the next request to the same host is not stuck'
    or diag $err;
  is $res && $res->content, 'pong', '... and gets its answer';

  my $image = Langertha::Content::Image->from_url("$base/a.png");
  ( $res, $err ) = settle( $image->ensure_base64_f( $http_engine->_async_http ) );
  ok !defined $err, 'image fetch: the next fetch from the same host works' or diag $err;

  ( $res, $err ) = settle( get_f( $https_engine, "https://127.0.0.1:$closed_port/ping" ) );
  like $err, qr/\ALangertha::Engine::OllamaOpenAI: cannot connect to https:\/\/127\.0\.0\.1:$closed_port: $ssl_error/,
    'SSL missing: an https request fails naming IO::Async::SSL';

  # Net::Async::HTTP 0.50 derives SSL from the scheme but passes the caller's
  # own SSL option after it, so an explicit SSL option wins in both directions.
  # The check must make the same call: refuse exactly the connections that
  # would load IO::Async::SSL, and no others.
  ( $res, $err ) = settle( $http_engine->async_request_f(
    HTTP::Request->new( GET => "$base/ping" ), SSL => 1 ) );
  like $err, qr/\ALangertha::Engine::OllamaOpenAI: cannot connect to http:\/\/\Q$hostport\E: $ssl_error/,
    'SSL missing: http with SSL => 1 would connect with SSL, so it fails naming IO::Async::SSL';
  ( $res, $err ) = settle( get_f( $http_engine, "$base/ping" ) );
  ok !defined $err, '... and the host is not stuck: the next plain request works' or diag $err;
  is $res && $res->content, 'pong', '... and gets its answer';

  ( $res, $err ) = settle( $http_engine->async_request_f(
    HTTP::Request->new( GET => "https://$hostport/ping" ), SSL => 0 ) );
  ok !defined $err, 'SSL missing: https with SSL => 0 connects without SSL, so it is not refused'
    or diag $err;
  is $res && $res->content, 'pong', '... and the plain-http daemon answers it';

  like Langertha::HTTP::ConnectCheck::connect_error( 'http://h.example/x', 1 ),
    qr/\Acannot connect to http:\/\/h\.example:80: $ssl_error/,
    'connect_error: http with $ssl true asks for IO::Async::SSL';
  is Langertha::HTTP::ConnectCheck::connect_error( 'https://h.example/x', 0 ), undef,
    'connect_error: https with $ssl false does not';
  is Langertha::HTTP::ConnectCheck::connect_error('http://h.example/x'), undef,
    'connect_error: without $ssl, http does not';
}

# --- SSL loads again ----------------------------------------------------------

delete $blocked{'IO/Async/SSL.pm'};

SKIP: {
  skip 'IO::Async::SSL is not installed', 2 unless eval { require IO::Async::SSL; 1 };
  my ( $res, $err ) = settle( get_f( $https_engine, "https://127.0.0.1:$closed_port/ping" ) );
  like $err, qr/\A127\.0\.0\.1:$closed_port - connect: .*failed \[.*refused/i,
    'SSL back: the next https request to the host is not stuck, it reaches the closed port';
}

done_testing;
