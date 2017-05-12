#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;

use IO::Socket::Telnet::HalfDuplex;

# can use whatever ping value you want

pipe my $read, my $write;

my $IAC = chr(255);
my $DO = chr(253);
my $WONT = chr(252);
my $PONG = chr(105);
my $localport = 23460;

my $pid;
unless ($pid = fork) {
    my $ping = 0;
    my $server = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => $localport,
        Listen    => 1,
    );
    die "can't create server: $!" if !$server;
    my $connection = $server->accept;
    my $buf;
    my $tested = 0;
    while (defined $connection->recv($buf, 4096)) {
        # read of 0 bytes means that the socket is closed
        last unless defined $buf && length $buf;
        my $gotpong = ($buf =~ s/$IAC$DO$PONG//);
        if (!$tested) {
            print { $write } "$buf\n";
            $tested = 1;
            $connection->send('test');
        }
        if ($gotpong) {
            $ping++;
            $connection->send("$IAC$WONT$PONG");
        }
    }
    print { $write } "$ping\n";
    close $write;
    exit;
}
# give the server time to set up
sleep 1;
my $pong = 0;
my $client = IO::Socket::Telnet::HalfDuplex->new(
    PeerAddr => '127.0.0.1',
    PeerPort => $localport,
    PingOption => ord($PONG),
);
$client->telnet_simple_callback(sub {
    my $self = shift;
    my ($msg) = @_;
    my $ping = ord($PONG);
    $pong++ if $msg =~ /$ping$/;
    return '';
});
$client->send('blah');
my $str = $client->read;
$client->close;
is($pong, 1, "client got a pong from the server");
is($str, 'test', "client got the right string");
my $buf;
read $read, $buf, 7;
my @results = split /\n/, $buf;
is($results[0], 'blah', 'server got the right string');
is($results[1], 1, 'server got a ping from the client');
