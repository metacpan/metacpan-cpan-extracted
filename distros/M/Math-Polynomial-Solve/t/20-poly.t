#
# Tests of the poly_roots() function, all of polynomials of degree
# four or less.
#
use 5.010001;
use Test::More tests => 22;

use Math::Complex;
use Math::Polynomial::Solve qw(:numeric ascending_order);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my($eq, $ne) = generate_relational(2.5e-7);

my @case = (
	[1, 2],
	[1, 2, 1],
	[1, 3, 3, 1],
	[9, 1, -1, 729],
	[1, 4, 6, 4, 1],
	[2, -4, -1, 6, 3],
	[-2, 4, 1, -6, -3],
	[289, 0, -30, 0, 1],
	[-289, 0, 30, 0, -1],
	[0, 0, 0, 289, 0, -30, 0, 1],
	[25, 60, 46, 12, 1],
);

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
	my @y = pl_evaluate([@coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ]," .
		" roots: [" . join(", ", @x) . "]"
	);
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
	my @y = pl_evaluate([@coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ]," .
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
