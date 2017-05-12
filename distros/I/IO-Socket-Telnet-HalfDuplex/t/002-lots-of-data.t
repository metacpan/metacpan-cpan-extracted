#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 10;

use IO::Socket::Telnet::HalfDuplex;

# send more than a single send buffer is capable of - make sure that it gets
# the whole thing

my $IAC = chr(255);
my $DO = chr(253);
my $WONT = chr(252);
my $PONG = chr(99);
my $localport = 23359;

my $pid;
unless ($pid = fork) {
    my $server = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => $localport,
        Listen    => 1,
    );
    die "can't create server: $!" if !$server;
    my $connection = $server->accept;
    my $buf;
    while (defined $connection->recv($buf, 4096)) {
        # read of 0 bytes means that the socket is closed
        last unless defined $buf && length $buf;
        my $gotpong = ($buf =~ s/$IAC$DO$PONG//);
        # sometimes the IAC DO PONG and the request come in different packets,
        # don't send things if it's just a ping
        $connection->send('test' x 10000) if length $buf;
        if ($gotpong) {
            $connection->send("$IAC$WONT$PONG");
        }
    }
    exit;
}
# give the server time to set up
sleep 1;
my $client = IO::Socket::Telnet::HalfDuplex->new(
    PeerAddr => '127.0.0.1',
    PeerPort => $localport,
);
for (1..10) {
    $client->send('blah');
    my $str = $client->read;
    is($str, 'test' x 10000, "client got the right string");
}
$client->close;
