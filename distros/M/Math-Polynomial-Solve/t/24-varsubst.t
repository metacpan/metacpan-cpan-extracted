#
# Tests of the poly_roots() function with varsubst on and off.
#
use 5.010001;
use Test::More tests => 33;

use Math::Complex;
use Math::Polynomial::Solve qw(:numeric poly_nonzero_term_count);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

coefficients order => 'ascending';

my($eq, $ne) = generate_relational(2.5e-7);

my @case = (
	[1, 0, 1],
	[1, 0, 0, 1],
	[1, 0, 2, 0, 1],
	[1, 0, 0, 0, 0, 1],
	[1, 0, 0, 2, 0, 0, 1],
	[1, 0, 1, 0, 0, 0, 1, 0, 1],
	[9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
	[1, 0, 2],
	[27, 0, 0, 9],
	[5, 0, 0, 0, 0, 1],
	[9, 0, 0, 0, 0, 9, 0, 0, 0, 0, 1],
);

#
# Use poly_roots() as per normal...
#
poly_option(varsubst => 0);

for (@case)
{
	my @coef = @$_;
	my @x = poly_roots(@coef);
	my @y = pl_evaluate([@coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ], varsubst => 0" .
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
	my @y = pl_evaluate([@coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ], varsubst => 1, nz terms = $tc" .
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
	my @y = pl_evaluate([@coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		"   [ " . join(", ", @coef) . " ], varsubst => 1, nz terms = $tc" .
		" roots: [" . join(", ", @x) . "]"
	);
}

1;

