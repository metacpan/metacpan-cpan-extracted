#
# Tests of the poly_roots() function with varsubst on and off.
#
use 5.010001;
use Test::More tests => 30;

use Math::Complex;
use Math::Polynomial::Solve qw(:numeric poly_nonzero_term_count ascending_order);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my($eq, $ne) = generate_relational(2.5e-7);

my @case = (
	[1, 0, 1],
	[1, 0, 0, 1],
	[1, 0, 2, 0, 1],
	[1, 0, 0, 0, 0, 1],
	[1, 0, 0, 2, 0, 0, 1],
	[1, 0, 1, 0, 0, 0, 1, 0, 1],
	[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9],
	[2, 0, 1],
	[9, 0, 0, 27],
	[1, 0, 0, 0, 0, 5],
);

#
# Use poly_roots() as per normal...
#
poly_option(varsubst => 0);
ascending_order(0);

for (@case)
{
	my @coef = @$_;
	my @x = poly_roots(@coef);
	my @y = pl_evaluate([reverse @coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ] descending order, varsubst => 0" .
		" roots: [" . join(", ", @x) . "]"
	);
}

#
# Repeat, using variable substitution function whenever possible.
#
poly_option(varsubst => 1);

for (@case)
{
	my @coef = @$_;
	my $tc = poly_nonzero_term_count(@coef);
	my @x = poly_roots(@coef);
	my @y = pl_evaluate([reverse @coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ] descending order, varsubst => 1, nz terms = $tc" .
		" roots: [" . join(", ", @x) . "]"
	);
}

#
# Repeat again, now using the classical methods after substituting.
#
poly_option(hessenberg => 0);

for (@case)
{
	my @coef = @$_;
	my $tc = poly_nonzero_term_count(@coef);
	my @x = poly_roots(@coef);
	my @y = pl_evaluate([reverse @coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ] descending order, varsubst => 1, nz terms = $tc" .
		" roots: [" . join(", ", @x) . "]"
	);
}

1;

