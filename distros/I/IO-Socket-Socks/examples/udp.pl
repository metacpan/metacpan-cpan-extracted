#!/usr/bin/env perl

use lib '../lib';
use IO::Socket::Socks;
use Socket;
use strict;

# daytime UDP client

my $sock = IO::Socket::Socks->new(
    UdpAddr => 'localhost',
    UdpPort => 13,
    ProxyAddr => 'localhost',
    ProxyPort => 1080,
    SocksDebug => 1
) or die $SOCKS_ERROR;

my $peer = inet_aton('localhost');
$peer = sockaddr_in(13, $peer);

$sock->send('!', 0, $peer) or die $!;
$sock->recv(my $data, 50)  or die $!;
$sock->close();

print $data;
