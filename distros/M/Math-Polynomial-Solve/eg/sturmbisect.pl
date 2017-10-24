#!/bin/perl
#
use Carp;
use Math::Polynomial::Solve qw(:sturm ascending_order);
use Math::Utils qw(:compare :polynomial);
use Math::Complex;
use strict;
use warnings;

my $fltcmp = generate_fltcmp();

my $ascending = 1;
ascending_order($ascending);

while (my $line = prompt("Polynomial: "))
{
	my @coef = split(/,? /, $line);
	my @chain = poly_sturm_chain( @coef );

	$line = prompt("Two X values: ");
	my @xvals = split(/,? /, $line);

	croak "Only two x values please" if (scalar @xvals != 2);

	print "\nPolynomial: [", join(", ", @coef), "]\n";

	my @brackets = sturm_bisection(\@chain, $xvals[0], $xvals[1]);
	print "Bracketing ranges:\n";
	for my $b (@brackets)
	{
		print "     [" . join(", ", @$b), "]\n";
	}

	my @roots = sturm_bisection_roots(\@chain, $xvals[0], $xvals[1]);
	my @zeros = pl_evaluate(\@coef, \@roots);

	my $c = 0;
	$c += abs(&$fltcmp($_, 0.0)) foreach(@zeros);
	print "\nroots at: [", join(", ", @roots), "]\n\n";
	print "$c non-roots\n" if ($c);
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

