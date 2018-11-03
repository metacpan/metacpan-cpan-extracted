#!/bin/perl
#
use Carp;
use Math::Polynomial::Solve qw(:sturm);
use strict;
use warnings;

coefficients order => 'ascending';

while (my $line = prompt("Polynomial: "))
{
	my @coef = split(/,? /, $line);

	my @chain = poly_sturm_chain( @coef );

	print "\nPolynomial: [", join(", ", @coef), "]\n";
	for my $j (0..$#chain)
	{
		my @c = @{$chain[$j]};
		print sprintf("    Fn%02d: [", $j) . join(", ", @c), "]\n";
	}
	print "Number of unique, real, roots: ", poly_real_root_count(@coef), "\n\n";
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

