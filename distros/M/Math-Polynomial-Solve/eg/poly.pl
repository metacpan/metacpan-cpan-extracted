#!/bin/perl
#
#
use Carp;
use Getopt::Long;
use Math::Polynomial::Solve qw(:numeric ascending_order);
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

	my @x = poly_roots(@coef);
	print rootprint(@x), "\n\n";
}
exit(0);

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

