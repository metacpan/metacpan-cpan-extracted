use 5.010001;
use Test::More tests => 7;

use Math::Complex;
use Math::Polynomial::Solve qw(:classical);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my($eq, $ne) = generate_relational(2.5e-7);

my @case = (
	[1, 4, 6, 4, 1],
	[-1, 0, 0, 0, 1],
	[1, 0, 0, 0, 1],
	[24, -50, 35, -10, 1],
	[-3, -10, -5, 6, 1],
	[-12, -7, 7, 6, 1],
	[2, 4, -1, 6, 1],
);

coefficients order => 'ascending';

foreach (@case)
{
	my @coef = @$_;
	my @x = quartic_roots(@coef);
	my @y = pl_evaluate([@coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ] ascending order," .
		" roots: [" . join(", ", @x) . "]"
	);
}

1;
