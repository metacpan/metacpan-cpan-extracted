#
# Tests of the poly_roots() function with both root_function on and off.
#
use 5.010001;
use Test::More tests => 34;

use Math::Complex;
use Math::Polynomial::Solve qw(:numeric poly_nonzero_term_count ascending_order);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my($eq, $ne) = generate_relational(2.5e-7);

my @case = (
	[1, 0, 1],
	[1, 0, 0, 1],
	[1, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 0, 0, 1],
	[1, 0, -1],
	[1, 0, 0, -1],
	[1, 0, 0, 0, -1],
	[1, 0, 0, 0, 0, -1],
	[1, 0, 0, 0, 0, 0, -1],
	[1, 0, 0, 0, 0, 0, 0, -1],
	[2, 0, 1],
	[9, 0, 0, 27],
	[1, 0, 0, 0, 0, 5],
	[1, 0, 1, 0, 1],	# shouldn't use root() ever.
	[3, 0, -1, -4, 2],	# shouldn't use root() ever.
);

#
# Use poly_roots() as per normal...
#
poly_option(root_function => 0);
ascending_order(0);

for (@case)
{
	my @coef = @$_;
	my $n = $#coef;
	my @x = poly_roots(@coef);
	my @y = pl_evaluate([reverse @coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		" root_function => 0,   [ " . join(", ", @coef) . " ]");
}

#
# Repeat, using the root() function whenever possible.
#
poly_option(root_function => 1);

for (@case)
{
	my @coef = @$_;
	my $n = $#coef;
	my @x = poly_roots(@coef);
	my @y = pl_evaluate([reverse @coef], @x);

	my @badvals = grep {&$ne($_, 0)} @y;

	ok(scalar @badvals == 0,
		" root_function => 1,   [ " . join(", ", @coef) . " ]");
}

1;

