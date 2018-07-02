use 5.010001;
use Test::More tests => 5;

use Math::Polynomial::Solve qw(:sturm :utility poly_roots);
use Math::Utils qw(:polynomial :compare);
use strict;
use warnings;

my($eq, $ne) = generate_relational(2.5e-7);

my @case = (
	[-1, -4, 200, 20],
	[1, 3, 2],
	[4, 3, 2, 1],
	[-1, 0, 10, 15, 6],
	[-1, 0, 5, 6, 2],
);

coefficients order => 'ascending';

for my $cref (@case)
{
	my @polynomial = @$cref;
	my @plroots = poly_roots(@polynomial);
	my @chain = poly_sturm_chain(@polynomial);

	my @roots = sturm_bisection_roots(\@chain, -10000, 100);
	my @zeroes = pl_evaluate(\@polynomial, \@roots);
	my @badvals = grep {&$ne($_, 0)} @zeroes;

	ok(scalar @badvals == 0,
		"Polynomial: [" . join(", ", @polynomial) . "],\n" .
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
