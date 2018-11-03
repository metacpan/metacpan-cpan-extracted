#
# Tests of the poly_roots() function, all of polynomials of degree
# four or less. Cases are all 0.9216 times the values of the cases
# in 20-poly.t.
# for my $c (@case)
# {
#     my @f = map{ sprintf("%4.5f", $_ * 0.9216) } @$c;
#     print "\t[" . join(", ", @f) . "],\n";
# }
#
use 5.010001;
use Test::More tests => 22;

use Math::Complex;
use Math::Polynomial::Solve qw(:numeric);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my($eq, $ne) = generate_relational(2.5e-7);

my @case = (
	[0.9216, 1.8432],
	[0.9216, 1.8432, 0.9216],
	[0.9216, 2.7648, 2.7648, 0.9216],
	[8.2944, 0.9216, -0.9216, 671.8464],
	[0.9216, 3.6864, 5.5296, 3.6864, 0.9216],
	[1.8432, -3.6864, -0.9216, 5.5296, 2.7648],
	[-1.8432, 3.6864, 0.9216, -5.5296, -2.7648],
	[266.3424, 0, -27.6480, 0, 0.9216],
	[-266.34240, 0, 27.64800, 0, -0.9216],
	[0, 0, 0, 266.34240, 0, -27.64800, 0, 0.9216],
	[23.04, 55.296, 42.3936, 11.0592, 0.9216],
);

coefficients order => 'ascending';

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
# Repeat, except that the next line sets the
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
