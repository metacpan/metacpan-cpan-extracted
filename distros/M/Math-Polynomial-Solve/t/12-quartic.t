use 5.010001;
use Test::More tests => 14;	# Twice the number of scalar @case.

use Math::Complex;
use Math::Polynomial::Solve qw(quartic_roots ascending_order);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my($eq, $ne) = generate_relational(2.5e-7);

my @case = (
	[1, 4, 6, 4, 1],
	[1, 0, 0, 0, -1],
	[1, 0, 0, 0, 1],
	[1, -10, 35, -50, 24],
	[1, 6, -5, -10, -3],
	[1, 6, 7, -7, -12],
	[1, 6, -1, 4,  2],
);

ascending_order(0);

foreach (@case)
{
	my @coef = @$_;
	my @x = quartic_roots(@coef);
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
	my @x = quartic_roots(@coef);
	my @y = pl_evaluate([@coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ] ascending order," .
		" roots: [" . join(", ", @x) . "]"
	);
}

1;
