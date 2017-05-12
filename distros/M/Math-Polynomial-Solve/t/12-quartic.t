use 5.010001;
use Test::More tests => 14;	# Twice the number of scalar @case.

use Math::Polynomial::Solve qw(quartic_roots :utility ascending_order);
use Math::Complex;
use strict;
use warnings;

require "t/coef.pl";

my @case = (
	[1, 4, 6, 4, 1],
	[1, 0, 0, 0, -1],
	[1, 0, 0, 0, 1],
	[1, -10, 35, -50, 24],
	[1, 6, -5, -10, -3],
	[1, 6, 7, -7, -12],
	[1, 6, -1, 4,  2],
);

foreach (@case)
{
	my @coef = @$_;
	my @x = quartic_roots(@coef);

	ok(allzeroes([reverse @coef ], @x),
		"   [ " . join(", ", @coef) . " ]");

	#diag(rootformat(@x), "\n\n");
}

ascending_order(1);

foreach (@case)
{
	my @coef = reverse @$_;
	my @x = quartic_roots(@coef);

	ok(allzeroes(\@coef, @x),
		"   [ " . join(", ", @coef) . " ], ascending order");

	#diag(rootformat(@x), "\n\n");
}

1;
