package NatsLive;
# Live-server tests run only against a server named in TEST_NATS_HOST or
# TEST_NATS_PORT, never against whatever happens to listen on 4222.
use strict;
use warnings;
use Exporter 'import';
use IO::Socket::INET;
use Test::More ();

our @EXPORT = qw(nats_or_skip);

sub nats_or_skip {
    Test::More::plan(skip_all => 'set TEST_NATS_HOST/TEST_NATS_PORT to test against a live nats-server')
        unless $ENV{TEST_NATS_HOST} || $ENV{TEST_NATS_PORT};
    my $host = $ENV{TEST_NATS_HOST} || '127.0.0.1';
    my $port = $ENV{TEST_NATS_PORT} || 4222;
    my $sock = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 1)
        or Test::More::plan(skip_all => "NATS server not available at $host:$port");
    close $sock;
    return ($host, $port);
}

1;
