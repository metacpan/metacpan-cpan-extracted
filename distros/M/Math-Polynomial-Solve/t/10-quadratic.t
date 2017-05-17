use 5.010001;
use Test::More tests => 18;	# Twice the number of scalar @case.

use Math::Complex;
use Math::Polynomial::Solve qw(quadratic_roots ascending_order);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my($eq, $ne) = generate_relational(2.5e-7);

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

ascending_order(0);

foreach (@case)
{
	my @coef = @$_;
	my @x = quadratic_roots(@coef);
	my @y = pl_evaluate([reverse @coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ] descending order," .
		" roots: [" . join(", ", @x) . "]"
	);
}

ascending_order(1);

foreach (@case)
{
	my @coef = reverse @$_;
	my @x = quadratic_roots(@coef);
	my @y = pl_evaluate([@coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ] ascending order," .
		" roots: [" . join(", ", @x) . "]"
	);
}

1;
