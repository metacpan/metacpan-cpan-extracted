#!perl -T
use 5.008003;
use strict;
use warnings;
use Test::More tests => 6;

use Math::Fortran qw(log10);

sub fltcmp
{
	my($x, $y) = @_;

	return -1 if ($x + 5e-7 < $y);
	return 1 if ($x - 5e-7 > $y);
	return 0;
}


my @logs = ("no",
	0, 0.301029995, 0.4771212547, 0.602059991, 0.698970004, 0.7781512503,
	);

for my $x (1 .. 6)
{
	my $y = log10($x);
	ok(fltcmp($y, $logs[$x]) == 0, "log10($x) returned $y");
}

