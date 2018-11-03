#!/bin/perl
#
use Carp;
use Math::Polynomial::Solve qw(:utility);
use Math::Utils qw(:polynomial);
use Math::Complex;
use strict;
use warnings;

coefficients order => 'ascending';

while (my $line = prompt("Polynomial: "))
{
	my @coef = split(/,? /, $line);

	$line = prompt("X values: ");
	my @xvals = split(/,? /, $line);

	print "\nPolynomial: [", join(", ", @coef), "]\n";

	my @roots = laguerre(\@coef, \@xvals);
	my @zeros = pl_evaluate(\@coef, \@roots);

	for my $j (0 .. $#xvals)
	{
		print "x: " . $xvals[$j] . "; root: " . $roots[$j] .
			"; p(root): " . $zeros[$j] . ";\n";
	}
	print "\n";
}

exit(0);

sub prompt
{
	my $pr = shift;
	print $pr;
	my $inp = <>;
	chomp $inp;
	return $inp;
}

