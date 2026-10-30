#!/usr/bin/env perl
# ABSTRACT: The fake HTTPS server reads a request body before it answers, so a large POST gets its response, not a reset
use strict;
use warnings;
use Test2::V0;
use IO::Socket::SSL;
use Time::HiRes qw( sleep );
use lib 't/lib';
use Test::Raider::FakeHTTPS;

# A chat request with raider's tool definitions is ~20 KB: more than one TLS
# record (16 KB). A server that answers after the headers and closes leaves
# the rest of the body unread in the kernel; the close then sends a TCP
# reset, which throws away the response the client has not read yet. Under
# load the engine read too late and saw "Connection closed" (t/70, t/73).
# Reading the response only after a pause makes the race deterministic.

local $SIG{PIPE} = 'IGNORE';
my $pki = Test::Raider::FakeHTTPS->pki( names => ['localhost'] );
my $srv = Test::Raider::FakeHTTPS->new( pki => $pki, routes => {
  '/v1/chat/completions' => sub { Test::Raider::FakeHTTPS->json( 200, { ok => 1 } ) },
} );

for my $size ( 20_000, 65_536 ) {
  my $c = IO::Socket::SSL->new(
    PeerAddr          => '127.0.0.1',
    PeerPort          => $srv->port,
    SSL_ca_file       => $pki->{ca},
    SSL_verifycn_name => 'localhost',
  ) or die 'connect: '.$SSL_ERROR;
  my $body = 'x' x $size;
  print $c "POST /v1/chat/completions HTTP/1.1\r\nHost: localhost\r\nContent-Length: ".length($body)."\r\n\r\n".$body;
  sleep 0.3;
  my $res = do { local $/; <$c> } // '';
  like( $res, qr{\AHTTP/1\.1 200 .*\r\n\r\n\{"ok":1\}\z}s, $size.' byte body: the whole response arrives' );
  close $c;
}

my @requests = $srv->requests;
is( [ map { $_->{method}.' '.$_->{path} } @requests ], [ ( 'POST /v1/chat/completions' ) x 2 ],
  'both requests logged, the body not taken for a request of its own' );

done_testing;
