use 5.010001;
use Test::More tests => 18;

use Math::Complex;
use Math::Polynomial::Solve qw(:numeric ascending_order);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my($eq, $ne) = generate_relational(2.5e-7);

#
# All cases are degree 5 or higher, so there should be no need to set
# the Hessenberg flag.
#
my @case = (
	[0.9216, 0, 0, 0, 0, -0.9216],
	[0.9216, 4.608, 9.2160, 9.2160, 4.608, 0.9216],
	[0.9216, 0, 0, 0, 0.9216, 0.9216],
	[0.9216, 0.9216, 0.9216, 0.9216, 0.9216, 0.9216, 0.9216, 0.9216],
	[3.6864, 7.3728, 13.824, 14.7456, 21.1968, 38.7072],
	[0.9216, 0, 0, 0, 18.432, 14.7456],
	[0.9216, 0, -2.7648, -3.6864, 2.7648, 5.5296, 1.8432],
	[-0.9216, 0, 2.7648, 3.6864, -2.7648, -5.5296, -1.8432],
	[1, -2.1, 1.64, -0.586, 0.0969, -0.00737, 0.00021],
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
		" roots: [" . join(", ", @x) . "]"
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
