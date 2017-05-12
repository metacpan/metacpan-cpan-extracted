# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 16-evaluate.t'
use 5.010001;
use Test::Simple tests => 4;

use Math::Utils qw(:polynomial :compare);
use Math::Complex;
use strict;
use warnings;

my $fltcmp = generate_fltcmp();

my @case = (
	[[1, 4, 6, 4, 1], [-1, -1, -1, -1]],
	[[-1, 0, 0, 0, 1], [root(1, 4)]],
	[[1, 0, 0, 0, 1], [root(-1, 4)]],
	[[24, -50, 35, -10, 1], [1, 2, 3, 4]],
);

foreach (@case)
{
	my @case = @$_;
	my @coef = @{$case[0]};
	my @x = @{$case[1]};

	my @y = pl_evaluate(\@coef, \@x);

	ok( (&$fltcmp($y[0], 0.0) == 0 and
		&$fltcmp($y[1], 0.0) == 0 and
		&$fltcmp($y[2], 0.0) == 0 and
		&$fltcmp($y[3], 0.0) == 0),
		"   [ " . join(", ", @coef) . " ] returned" .
		"   [ " . join(", ", @y) . " ]"
	);
}

1;
