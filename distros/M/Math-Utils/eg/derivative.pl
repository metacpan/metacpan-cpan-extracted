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
	my @polynomial = split(/,? /, $line);
	last unless ($line);

	my $x = prompt("x-value: ");

	d1(\@polynomial, $x);
	d2(\@polynomial, $x);
}
exit(0);

sub d1
{
	my($p_ref, $x) = @_;

	my($r, $d1, $d2) = pl_dxevaluate($p_ref, $x);

	print "Polynomial: $r, First derivative: $d1, Second derivative $d2\n\n";
}

sub d2
{
	my($p_ref, $x) = @_;

	my @d1p = pl_derivative(@$p_ref);
	my @d2p = pl_derivative(@d1p);

	my $r = pl_evaluate($p_ref, $x);
	my $d1 = pl_evaluate(\@d1p, $x);
	my $d2 = pl_evaluate(\@d2p, $x);

	print "Polynomial: $r, First derivative: $d1, Second derivative $d2\n\n";
}

sub prompt
{
	my $pr = shift;
	print $pr;
	my $inp = <>;
	chomp $inp;
	return $inp;
}
