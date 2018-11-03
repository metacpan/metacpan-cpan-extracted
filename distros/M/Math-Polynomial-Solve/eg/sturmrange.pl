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

	$line = prompt("X values: ");
	my @xvals = split(/,? /, $line);

	my @chain = poly_sturm_chain( @coef );
	my @signs = sturm_sign_chain(\@chain, \@xvals);

	print "\nPolynomial: [", join(", ", @coef), "]\n";
	print "Sturm chain:\n";

	for my $j (0..$#chain)
	{
		my @c = @{$chain[$j]};
		print sprintf("    Fn%02d: [", $j) . join(", ", @c), "]\n";
	}

	for my $j (0..$#signs)
	{
		my @s = @{$signs[$j]};
		print sprintf("x = %4f: [", $xvals[$j]) . join("   ", @s),
			"], sign count:  ",
			sturm_sign_count(@s), "\n\n";
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

