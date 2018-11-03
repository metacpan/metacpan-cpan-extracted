use 5.010001;
use Test::More tests => 9;

use Math::Complex;
use Math::Polynomial::Solve qw(:classical);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my($eq, $ne) = generate_relational(2.5e-7);

my @case = (
	[1, 2, 1],
	[-1, -1, 1],
	[-1, 0, 1],
	[2, -3, 1],
	[-6, 11, 1],
	[12, -7, 1],
	[12, -13, 1],
	[29, -6, 5],
	[296, 61, 17],
);

coefficients order => 'ascending';

foreach (@case)
{
	my @coef = @$_;
	my @x = quadratic_roots(@coef);
	my @y = pl_evaluate([@coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ] ascending order," .
		" roots: [" . join(", ", @x) . "]"
	);
}

1;
