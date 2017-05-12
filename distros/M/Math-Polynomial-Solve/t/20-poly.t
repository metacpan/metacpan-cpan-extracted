#
# Tests of the poly_roots() function, all of polynomials of degree
# four or less.
#
use 5.010001;
use Test::More tests => 48;

use Math::Polynomial::Solve qw(:numeric ascending_order);
use Math::Complex;
use strict;
use warnings;

require "t/coef.pl";

my @case = (
	[2, 1],
	[1, 2, 1],
	[1, 3, 3, 1],
	[729, -1, 1, 9],
	[1, 4, 6, 4, 1],
	[3, 6, -1, -4, 2],
	[-3, -6, 1, 4, -2],
	[1, 0, -30, 0, 289],
	[-1, 0, 30, 0, -289],
	[1, 0, -30, 0, 289,  0,  0,  0],
	[289, 0, -30, 0, 1],
	[1, 12, 46, 60, 25],
);

ascending_order(0);

#
# All of these tests will be dispatched to the
# quadratic_roots, cubic_roots, and quartic_roots functions.
#
poly_option(hessenberg => 0);

for (@case)
{
	my @coef = @$_;
	my @x = poly_roots(@coef);

	ok(allzeroes([reverse @coef ], @x),
		"   [ " . join(", ", @coef) . " ]");

	#diag(rootformat(@x), "\n\n");
}

#
# Repeate, except that the next line sets the
# 'always use the iterative matrix' flag.
#
poly_option(hessenberg => 1);

for (@case)
{
	my @coef = @$_;
	my @x = poly_roots(@coef);

	ok(allzeroes([reverse @coef ], @x),
		"   [ " . join(", ", @coef) . " ]");

	#diag(rootformat(@x), "\n\n");
}

ascending_order(1);

#
# All of these tests will be dispatched to the
# quadratic_roots, cubic_roots, and quartic_roots functions.
#
poly_option(hessenberg => 0);

for (@case)
{
	my @coef = @$_;
	my @x = poly_roots(@coef);

	ok(allzeroes(\@coef, @x),
		"   [ " . join(", ", reverse @coef) . " ], ascending order");

	#diag(rootformat(@x), "\n\n");
}

#
# Repeate, except that the next line sets the
# 'always use the iterative matrix' flag.
#
poly_option(hessenberg => 1);

for (@case)
{
	my @coef = @$_;
	my @x = poly_roots(@coef);

	ok(allzeroes(\@coef, @x),
		"   [ " . join(", ", reverse @coef) . " ], ascending order");

	#diag(rootformat(@x), "\n\n");
}

1;
