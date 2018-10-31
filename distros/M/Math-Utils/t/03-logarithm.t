#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More tests => 12;

use Math::Utils qw(:compare log10 log2);

my($eq, $ne) = generate_relational(1.5e-7);

my @logs = ("no",
	0, 0.301029995, 0.4771212547, 0.602059991, 0.698970004, 0.7781512503,
	);

for my $x (1 .. 6)
{
	my $y = log10($x);
	ok(&$eq($y, $logs[$x]), "log10($x) returned $y");
}

my @lgs = ("no",
	0, 1.0, 1.584962501, 2.0, 2.321928095, 2.584962501,
	);

for my $x (1 .. 6)
{
	my $y = log2($x);
	ok(&$eq($y, $lgs[$x]), "log2($x) returned $y");
}

