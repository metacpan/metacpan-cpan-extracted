use 5.010001;
use Test::More tests => 10;

use Math::Polynomial::Solve qw(:sturm :utility poly_roots ascending_order);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my($eq, $ne) = generate_relational(2.5e-7);

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
	my @badvals = grep {&$ne($_, 0)} @zeroes;

	ok(scalar @badvals == 0,
		"Polynomial: [" . join(", ", @polynomial) . "],\n" .
	   " 'zeroes' are (" . join(", ", @zeroes) . ")\n" .
	   " sturm_bisection_roots() returns (" . join(", ", @roots) . ")\n" .
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
	my @badvals = grep {&$ne($_, 0)} @zeroes;

	ok(scalar @badvals == 0,
		"Polynomial (ascending): [" . join(", ", @polynomial) . "],\n" .
	   " 'zeroes' are (" . join(", ", @zeroes) . ")\n" .
	   " sturm_bisection_roots() returns (" . join(", ", @roots) . ")\n" .
	   "      poly_roots() returns (" . join(", ", @plroots) . ")"
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
