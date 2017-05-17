use 5.010001;
use Test::More tests => 26;	# Twice the number of scalar @case.

use Math::Complex;
use Math::Polynomial::Solve qw(cubic_roots ascending_order);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my($eq, $ne) = generate_relational(2.5e-7);

my @case = (
	[1, 3, 3, 1],
	[1, 0, 0, -1],
	[1, 0, 0, 1],
	[1, -13, 59, -87],
	[1, -4, 4, -16],
	[1, -6, 11, -6],
	[1, 5, -62, -336],
	[8, 0, -6, -1],		# can't trisect 60 deg angle.
	[1, 0, 0, -2],		# can't duplicate the cube.
	[1, 1, -2, -1],		# can't construct a septagon.
	[8, -24, 0, 6.25],
	[729, -1, 1, 9],
	[1, -2.5, 7/8, -1/16],
);

ascending_order(0);

foreach (@case)
{
	my @coef = @$_;
	my @x = cubic_roots(@coef);
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
	my @x = cubic_roots(@coef);
	my @y = pl_evaluate([@coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ] ascending order," .
		" roots: [" . join(", ", @x) . "]"
	);
}

1;
