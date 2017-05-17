#
# Tests of the poly_roots() function, all of polynomials of degree
# four or less. Cases are all 0.9216 times the values of the cases
# in 20-poly.t.
#
use 5.010001;
use Test::More tests => 44;

use Math::Complex;
use Math::Polynomial::Solve qw(:numeric ascending_order);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my($eq, $ne) = generate_relational(2.5e-7);

my @case = (
	[1.8432, 0.9216],
	[0.9216, 1.8432, 0.9216],
	[0.9216, 2.7648, 2.7648, 0.9216],
	[0.9216, 3.6864, 5.5296, 3.6864, 0.9216],
	[2.7648, 5.5296, -0.9216, -3.6864, 1.8432],
	[-2.7648, -5.5296, 0.9216, 3.6864, -1.8432],
	[0.9216, 0, -27.648, 0, 266.3424],
	[-0.9216, 0, 27.648, 0, -266.3424],
	[0.9216, 0, -27.648, 0, 266.3424, 0, 0, 0],
	[266.3424, 0, -27.648, 0, 0.9216],
	[0.9216, 11.0592, 42.3936, 55.296, 23.04],
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
	my @y = pl_evaluate([reverse @coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ] descending order," .
		" roots: [" . join(", ", @x) . "]"
	);
}

#
# Repeat, except that the next line sets the
# 'always use the iterative matrix' flag.
#
poly_option(hessenberg => 1);

for (@case)
{
	my @coef = @$_;
	my @x = poly_roots(@coef);
	my @y = pl_evaluate([reverse @coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ] descending order," .
		" roots: [" . join(", ", @x) . "]"
	);
}

ascending_order(1);

#
# All of these tests will be dispatched to the
# quadratic_roots, cubic_roots, and quartic_roots functions.
#
poly_option(hessenberg => 0);

for (@case)
{
	my @coef = reverse @$_;
	my @x = poly_roots(@coef);
	my @y = pl_evaluate([@coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ] ascending order," .
		" roots: [" . join(", ", @x) . "]"
	);
}

#
# Repeat, except that the next line sets the
# 'always use the iterative matrix' flag.
#
poly_option(hessenberg => 1);

for (@case)
{
	my @coef = reverse @$_;
	my @x = poly_roots(@coef);
	my @y = pl_evaluate([@coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ] ascending order," .
		" roots: [" . join(", ", @x) . "]"
	);
}

exit(0);

sub rootprint
{
	my @fmtlist;
	for (@_)
	{
		push @fmtlist, cartesian_format(undef, undef, $_);
	}
	return "[ " . join(", ", @fmtlist) . " ]";
}

1;
