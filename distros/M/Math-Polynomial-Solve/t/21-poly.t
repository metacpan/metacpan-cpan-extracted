use 5.010001;
use Test::More tests => 10;

use Math::Complex;
use Math::Polynomial::Solve qw(:numeric);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my($eq, $ne) = generate_relational(3.0e-7);

#
# All cases are degree 5 or higher, so there should be no need to set
# the Hessenberg flag.
#
my @case = (
	[-1, 0, 0, 0, 0, 1],
	[1, 5, 10, 10, 5, 1],
	[1, 1, 0, 0, 0, 1],		# Two of the roots are cube roots of 1
	[1, 1, 1, 1, 1, 1, 1, 1],
	[42, 23, 16, 15, 8, 4],
	[16, 20, 0, 0, 0, 1],
	[2, 6, 3, -4, -3, 0, 1],
	[-2, -6, -3, 4, 3, 0, -1],
	[90, -53, 7, -70, 49, -7, -20, 4],	# (4x**2 - 8x + 9)(x + 2)(x - 5)(x**3 - 1)
	[67, -4961, 137445, -1682934, 7551423, 1950773],
);

coefficients order => 'ascending';

for (@case)
{
	my @coef = @$_;
	my @x = poly_roots(@coef);
	my @y = pl_evaluate([@coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ]," .
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
