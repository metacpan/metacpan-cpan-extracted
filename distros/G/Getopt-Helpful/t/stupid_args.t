#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(
	no_plan
	);

use Getopt::Helpful;

{
	local $TODO = "don't let me do this";
	my $hats;
	eval {
		my $hopt = Getopt::Helpful->new(
		['h|hats', \$hats, '',''],
		'+help',
		);
	};
	ok((($@ ||'') =~ m/invalid/));

}
{
	local $TODO = "don't let me do this";
	my $hats;
	my $houses;
	eval {
		my $hopt = Getopt::Helpful->new(
		['h|hats', \$hats, '',''],
		['h|houses', \$houses, '',''],
		);
	};
	ok((($@ ||'') =~ m/invalid/));

}
{
	local $TODO = "don't let me do this";
	my $var;
	eval {
		my $hopt = Getopt::Helpful->new(
		['v|var', \$var, '',''],
		'+verbose',
		);
	};
	ok((($@ ||'') =~ m/invalid/));

}
