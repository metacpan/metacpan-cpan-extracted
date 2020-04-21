#!/usr/bin/env perl

use Math::Utils qw(:polynomial :utility);
use Getopt::Long;
#use Smart::Comments qw(###);
use strict;
use warnings;

my($triangle, $verbose, $helpme);
my($power, $startfrom) = (-1, 0);
my(@yvals);

GetOptions("power=i" => \$power,
	"start=i" => \$startfrom,
	"triangle" => \$triangle,
	"verbose" => \$verbose,
	"help" => \$helpme,
);

if ($power >= 0)
{
	@yvals = (0, 1);
	for my $j (2 .. $power + 1)
	{
		push @yvals, ($yvals[$j - 1] +  $j ** $power);
	}
}
else
{
	@yvals = @ARGV;
}

help() if ($helpme or ! scalar @yvals);

my @fc = diff_column(@yvals);

print_diff_triangle(diff_triangle(@yvals)) if ($triangle);
print "\nDifference column:\n", join(", ", @fc), "\n" if ($verbose);

my($m, $p) = make_poly(@fc);

print "Polynomial is: [", join(", ", @{$p}), "]/$m\n";

exit (0);

sub help
{
	print << 'EOH';

Simple finite difference calculation to find the polynomial that
generates the sequence that you provide. The numbers that you
provide are the Y values; the coresponding X values are 0, 1, 2, ... etc.

The polynomial is printed in ascending form. The output of
finitedif.pl 1 10 27 52, for example, will be [1, 5, 4]/1. Ths
translates to the polynomial 4*x**2 + 5*x + 1, all over the divisor 1.

useage:
        finitedif.pl 1 10 27 52

or
        finitedif.pl --startfrom=1 1 10 27 52

or
        finitedif.pl --power=2

The flag "startfrom" starts X from a value other than 0. The flag "power"
creates a power sequence (1, 4, 9, ... for power=2, 1, 8, 27, 64, ... for
power=3, and so on).

There are flags to display internal calculations:

        finitedif.pl --verbose 1 10 27 52

        finitedif.pl --triangle 1 10 27 52

The flag "verbose" prints out intermediate calculations in addition to
the polynomial. The flag "triangle" prints out the difference triangle.

EOH

exit(0);
}

#
# using the first column of the difference triangle, create the polynomial.
#
sub make_poly
{
	my(@diffs) = @_;
	my($n) = $#diffs;

	#
	# Set up the 1, x, x(x-1), x(x-1)(x-2), ... etc. polynomial sequence.
	#
	my $p = [1];
	my @seq = ($p);

	for my $k (0 .. $#diffs)
	{
		$seq[$k] = [ map($_ * $diffs[$k], @{$p}) ];
		$p = pl_mult($p, [-($startfrom + $k), 1]);
	}

	if ($verbose)
	{
		my $idx = 0;
		print "\nThe polynomial sequences:\n";
		for my $q (@seq)
		{
			printf("%2d: [%s] / %d!\n",
				$idx,
				join(", ", @{$q}),
				$idx);
			$idx++;
		}
		print "\n";
	}

	#
	# Add the sequences together to get one polynomial.
	#
	my $m  = 1;
	$p = [0];
	for my $k (reverse 1 .. $#diffs)
	{
		my $sk = [map($_ * $m, @{ $seq[$k] })];

		$p = pl_add($p, $sk);
		$m *= $k;
	}

	$p = pl_add($p, [$m * $diffs[0]]);

	if ($verbose)
	{
		print "Added together:\n";
		print "[", join(", ", @{$p}), "]/$m\n\n";
	}

	#
	# Now find common factor and divide by it.
	#
	my(@coefs) = grep($_ != 0, @{$p});
	if (scalar @coefs)
	{
		my $d = gcd(@coefs, $m);
		$p = [map($_/$d, @{$p})];
		$m /= $d;
	}

	if ($verbose)
	{
		print "After reducing the fraction:\n";
		print "[", join(", ", @{$p}), "]/$m\n\n";
	}

	return ($m, $p);
}

sub print_diff_triangle
{
	my(@diffs) = @_;

	for my $j (0 .. $#diffs)
	{
		my(@v) = @{$diffs[$j]};
		print join(" ", map(sprintf("%10d", $_), @v)), "\n";
	}
}

sub diff_triangle
{
	my(@numbers) = @_;
	my(@diffs) = ([@numbers]);
	my $n = $#numbers;

	#
	# Create a new row by subracting number j from number j+1.
	#
	for my $j (1 .. $n)
	{
		my @v;
		push @v, $numbers[$_] - $numbers[$_ - 1] for (1 .. $#numbers);

		#
		# If it's a row of zeros, we're done anyway.
		#
		last unless (scalar grep($_ != 0, @v));

		push @diffs, [@v];
		@numbers = @v;
	}
	return @diffs;
}

sub diff_column
{
	my(@numbers) = @_;
	my(@diffcol) = ($numbers[0]);
	my $n = $#numbers;

	#
	# Create a new row by subracting number j from number j+1.
	#
	for my $j (1 .. $n)
	{
		my @v;
		push @v, $numbers[$_] - $numbers[$_ - 1] for (1 .. $#numbers);

		#
		# If it's a row of zeros, we're done anyway.
		#
		last unless (scalar grep($_ != 0, @v));

		push @diffcol, $v[0];
		@numbers = @v;
	}
	return @diffcol;
}

