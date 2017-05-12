#!/bin/perl
#
use Carp;
use Getopt::Long;
use Math::Polynomial::Solve qw(:sturm :utility ascending_order);
use Math::Complex;
use strict;
use warnings;
#use IO::Prompt;

my $line;
my $ascending = 0;

GetOptions('ascending' => \$ascending);

ascending_order($ascending);

while ($line = prompt("Polynomial: ", -num))
{
	my @coef = split(/,? /, $line);

	$line = prompt("X values: ");
	my @xvals = split(/,? /, $line);

	print "\nPolynomial: [", join(", ", @coef), "]\n";

	my @roots = laguerre(\@coef, \@xvals);
	my @zeros = poly_evaluate(\@coef, \@roots);

	for my $j (0 .. scalar @xvals)
	{
		print "x: " . $xvals[$j] . "; root: " . $roots[$j] .
			"; p(root): " . $zeros[$j] . ";\n";
	}
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

