use 5.010001;
use Test::More tests => 10;

use Math::Polynomial::Solve qw(:sturm :utility poly_roots ascending_order);
use Math::Utils qw(:polynomial);
use strict;
use warnings;
require "t/coef.pl";

my @case = (
	[20, 200, -4, -1],
	[2, 3, 1],
	[1, 2, 3, 4],
	[6, 15, 10, 0, -1],
	[2, 6, 5, 0, -1],
);

ascending_order(0);


for my $cref (@case)
{
	my @polynomial = @$cref;
	my @rev = reverse @polynomial;
	my @plroots = poly_roots(@polynomial);
	my @chain = poly_sturm_chain(@polynomial);

	my @roots = sturm_bisection_roots(\@chain, -10000, 100);
	my @zeroes = pl_evaluate(\@rev, \@roots);

	ok(allzeroes(\@rev, @roots),
		"Polynomial: [" . join(", ", @polynomial) . "],\n" .
	   " 'zeroes' are (" . join(", ", @zeroes) . ")\n" .
	   " sturm_bisection() returns (" . join(", ", @roots) . ")\n" .
	   "      poly_roots() returns (" . join(", ", @plroots) . ")"
	);
}

ascending_order(1);
for my $cref (@case)
{
	my @polynomial = reverse @$cref;
	my @plroots = poly_roots(@polynomial);
	my @chain = poly_sturm_chain(@polynomial);

	my @roots = sturm_bisection_roots(\@chain, -10000, 100);
	my @zeroes = pl_evaluate(\@polynomial, \@roots);

	ok(allzeroes(\@polynomial, @roots),
		"Polynomial (ascending): [" . join(", ", @polynomial) . "],\n" .
	   " 'zeroes' are (" . join(", ", @zeroes) . ")\n" .
	   " sturm_bisection() returns (" . join(", ", @roots) . ")\n" .
	   "      poly_roots() returns (" . join(", ", @plroots) . ")"
	);
}

exit(0);
