use 5.010001;
use Test::More tests => 18;	# Twice the number of scalar @case.

use Math::Polynomial::Solve qw(quadratic_roots ascending_order);
use Math::Complex;
use strict;
use warnings;

require "t/coef.pl";

my @case = (
	[1, 2, 1],
	[1, -1, -1],
	[1, 0, -1],
	[1, -3, 2],
	[1, 11, -6],
	[1, -7, 12],
	[1, -13, 12],
	[5, -6, 29],
	[17, 61, 296],
);

foreach (@case)
{
	my @coef = @$_;
	my @x = quadratic_roots(@coef);

	ok(allzeroes([reverse @coef ], @x),
		"   [ " . join(", ", @coef) . " ]");

	#diag(rootformat(@x), "\n\n");
}

ascending_order(1);

foreach (@case)
{
	my @coef = reverse @$_;
	my @x = quadratic_roots(@coef);

	ok(allzeroes(\@coef, @x),
		"   [ " . join(", ", @coef) . " ], ascending order");

	#diag(rootformat(@x), "\n\n");
}

1;
