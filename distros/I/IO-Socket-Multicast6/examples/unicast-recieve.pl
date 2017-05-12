#!/usr/bin/perl

use strict;
use lib '../blib/lib','../blib/arch';
use IO::Socket::Multicast6;

use constant PORT  => '2000';

my $sock = new IO::Socket::Multicast6(
#					Domain=>AF_INET,
					LocalPort=>PORT,
					ReuseAddr=>1);

while (1) {
	my $data;
	next unless $sock->recv($data,1024);
	print "Got ".length($data)." bytes: $data\n";
}
