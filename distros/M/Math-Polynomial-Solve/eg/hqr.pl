#!/bin/perl
#
#
use Carp;
use Getopt::Long;
use Math::Polynomial::Solve qw(:numeric ascending_order);
use Math::Complex;
use Math::Matrix;
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

	my @h = build_companion(@coef);
	my $m1 = Math::Matrix->new(@h);
	$m1->print();
	@h = balance_matrix(@h);
	$m1 = Math::Matrix->new(@h);
	$m1->print();
	my @x = hqr_eigen_hessenberg(@h);
	print rootprint(@x), "\n\n";
}
exit(0);

sub rowprint
{
	my $ref = shift;
	my @h = @$ref;
	my $n = $#h;
	my $fmt = "%8.4f";
	my $string= "";

	for my $i (0..$n)
	{
		my @formatted;
		for my $j (0..$n)
		{
			push @formatted, cartesian_format($fmt, $fmt, $h[$i][$j]);
		}
		$string .= "[" . join(", ", @formatted) . "]\n";
	}
	$string .= "\n";
	return $string;
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

