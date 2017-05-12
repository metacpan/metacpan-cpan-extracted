#!/usr/bin/perl

use warnings;
use strict;

use Getopt::Helpful;
use Data::Dumper;

my $option = "no";
my $var = "default";

my $hopt = Getopt::Helpful->new(
	[
		'o|option=s', \$option,
		'<option>',
		"setting for \$option (default: '$option')",
	],
	[
		'v|var=s', \$var,
		'<setting>',
		"setting for \$var (default: '$var')"
	],
	'+help',
	);

$hopt->Get();
print Dumper({option => $option, var => $var});
