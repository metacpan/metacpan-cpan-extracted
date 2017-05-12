#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../lib);
use Math::RandomOrg qw(randnum);


my @names	= qw(Heads Tails);
for (1 .. 10) {
	my $value = randnum(0, 1);
	print $names[ $value ] . "\n";
}
