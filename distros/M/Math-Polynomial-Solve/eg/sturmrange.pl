#!/bin/perl
#
use Carp;
use Getopt::Long;
use Math::Polynomial::Solve qw(:sturm);
use strict;
use warnings;
#use IO::Prompt;

my $line;
my $ascending = 0;

GetOptions('ascending' => \$ascending);

ascending_order($ascending);

while ($line = prompt("Polynomial: "))
{
	my @coef = split(/,? /, $line);

	$line = prompt("X values: ");
	my @xvals = split(/,? /, $line);

	my @chain = poly_sturm_chain( @coef );
	my @signs = sturm_sign_chain(\@chain, \@xvals);

	print "\nPolynomial: [", join(", ", @coef), "]\n";

	foreach my $j (0..$#signs)
	{
		my @s = @{$signs[$j]};
		print sprintf("x = %4f: [", $xvals[$j]) . join("   ", @s), "] ",
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

