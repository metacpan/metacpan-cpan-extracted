#!/bin/perl
#
#
use Carp;
use Getopt::Long;
use Math::Polynomial::Solve qw(:utility ascending_order);
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
	my @polynomial = split(/,? /, $line);
	last unless ($line);

	my $x = prompt("x-value: ", -num);

	d1(\@polynomial, $x);
	d2(\@polynomial, $x);
}
exit(0);

sub d1
{
	my($p_ref, $x) = @_;

	my($r, $d1, $d2) = poly_derivaluate($p_ref, $x);

	print "Polynomial: $r, First derivative: $d1, Second derivative $d2\n\n";
}

sub d2
{
	my($p_ref, $x) = @_;

	my @d1p = poly_derivative(@$p_ref);
	my @d2p = poly_derivative(@d1p);

	my $r = poly_evaluate($p_ref, $x);
	my $d1 = poly_evaluate(\@d1p, $x);
	my $d2 = poly_evaluate(\@d2p, $x);

	print "Polynomial: $r, First derivative: $d1, Second derivative $d2\n\n";
}

sub cartesian_format($$@)
{
	my($fmt_re, $fmt_im, @numbers) = @_;
	my(@cfn, $n, $r, $i);

	$fmt_re ||= "%.15g";		# Provide a default real format
	$fmt_im ||= " + %.15gi";	# Provide a default im format

	foreach $n (@numbers)
	{
		$r = sprintf($fmt_re, Re($n));
		if (Im($n) != 0)
		{
			$i = sprintf($fmt_im, Im($n));
		}
		else
		{
			$r = sprintf($fmt_re, $n);
			$i = "";
		}

		push @cfn, $r . $i;
	}

	return wantarray? @cfn: $cfn[0];
}

sub rootprint
{
	my @fmtlist;
	foreach (@_)
	{
		push @fmtlist, cartesian_format(undef, undef, $_);
	}
	return "[ " . join(", ", @fmtlist) . " ]";
}

sub prompt
{
	my $pr = shift;
	print $pr;
	my $inp = <>;
	chomp $inp;
	return $inp;
}
