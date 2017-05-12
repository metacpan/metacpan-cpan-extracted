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
					ReuseAddr=>1)
|| die "Failed to create multicast socket: $!";

$sock->mcast_add(GROUP) || die "Couldn't join group: $!\n";

while (1) {
	my $data;
	next unless $sock->recv($data,1024);
	print "$data\n";
}
