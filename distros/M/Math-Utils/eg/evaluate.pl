#!/bin/perl
#
#
use Carp;
use Math::Utils qw(:polynomial);
use Math::Complex;
use strict;
use warnings;

while (my $line = prompt("Polynomial: "))
{
	my @polynomial = split(/[, ] */, $line);

	$line = prompt("X values: ");
	last unless ($line);
	my(@xvals) = split(/,? /, $line);

	my(@yvals) = pl_evaluate(\@polynomial, \@xvals);

	for my $j (0 .. $#yvals)
	{
		print $xvals[$j], ", ", $yvals[$j], "\n";
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
