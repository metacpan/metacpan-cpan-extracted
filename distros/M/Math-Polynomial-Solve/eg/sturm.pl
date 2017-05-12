#!/bin/perl
#
use Carp;
use Getopt::Long;
use Math::Polynomial::Solve qw(:sturm ascending_order);
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

	my @chain = poly_sturm_chain( @coef );

	print "\nPolynomial: [", join(", ", @coef), "]\n";
	foreach my $j (0..$#chain)
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

