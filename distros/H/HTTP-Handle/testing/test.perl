#!/usr/bin/perl

use strict;
#use warnings;

while (<>) {
	m/"([^"]*)"|'([^']*)'|(\S+)/;

	my $string = $1 || $2 || $3;
	print "$string\n";

}
