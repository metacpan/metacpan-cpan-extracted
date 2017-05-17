use 5.010001;
use Test::More tests => 20;

use Math::Complex;
use Math::Polynomial::Solve qw(poly_roots ascending_order);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my($eq, $ne) = generate_relational(3.0e-7);

#
# All cases are degree 5 or higher, so there should be no need to set
# the Hessenberg flag.
#
my @case = (
	[1, 0, 0, 0, 0, -1],
	[1, 5, 10, 10, 5, 1],
	[1, 0, 0, 0, 1, 1],		# Two of the roots are cube roots of 1
	[1, 1, 1, 1, 1, 1, 1, 1],
	[4, 8, 15, 16, 23, 42],
	[1, 0, 0, 0, 20, 16],
	[1, 0, -3, -4, 3, 6, 2],
	[-1, 0, 3, 4, -3, -6, -2],
	[4, -20, -7, 49, -70, 7, -53, 90],	# (4x**2 - 8x + 9)(x + 2)(x - 5)(x**3 - 1)
	[1950773,  7551423,  -1682934,  137445,  -4961,  67],
);

ascending_order(0);

for (@case)
{
	my @coef = @$_;
	my @x = poly_roots(@coef);
	my @y = pl_evaluate([reverse @coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ] descending order," .
		" roots: [" . join(", ", @x) . "]" .
		" evals: [" . join(", ", @y) . "]"
	);
}

ascending_order(1);

for (@case)
{
	my @coef = @$_;
	my @x = poly_roots(@coef);
	my @y = pl_evaluate([@coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ] ascending order," .
		" roots: [" . join(", ", @x) . "]" .
		" evals: [" . join(", ", @y) . "]"
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
