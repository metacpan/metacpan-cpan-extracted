use 5.010001;
use Test::More tests => 13;

use Math::Complex;
use Math::Polynomial::Solve qw(cubic_roots ascending_order);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my($eq, $ne) = generate_relational(2.5e-7);

my @case = (
	[1, 3, 3, 1],
	[-1, 0, 0, 1],
	[1, 0, 0, 1],
	[-87, 59, -13, 1],
	[-16, 4, -4, 1],
	[-6, 11, -6, 1],
	[-336, -62, 5, 1],
	[-1, -6, 0, 8],		# can't trisect 60 deg angle.
	[-2, 0, 0, 1],		# can't duplicate the cube.
	[-1, -2, 1, 1],		# can't construct a septagon.
	[6.25, 0, -24, 8],
	[9, 1, -1, 729],
	[-1/16, 7/8, -2.5, 1],
);

ascending_order(1);

foreach (@case)
{
	my @coef = @$_;
	my @x = cubic_roots(@coef);
	my @y = pl_evaluate([@coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ] ascending order," .
		" roots: [" . join(", ", @x) . "]"
	);
}

1;
