#!/usr/bin/perl

use strict;
use lib '../blib/lib','../blib/arch';
use IO::Socket::Multicast6;

#use constant GROUP => 'ff15::9023';
use constant GROUP => '239.255.30.29';
use constant PORT  => '2000';

my $sock = new IO::Socket::Multicast6(
					LocalAddr=>GROUP,
					LocalPort=>PORT,
					)
|| die "Failed to create multicast socket: $!";

$sock->mcast_ttl(5) || die "Failed to set TTL: $!";
$sock->mcast_loopback(1) || die "Failed to enable loopback: $!";
$sock->mcast_dest(GROUP, PORT);

while (1) {
	my $message = localtime();
	$sock->mcast_send($message) || die "Couldn't send: $!";
	print "Sent: $message\n";
} continue {
	sleep 4;
}
