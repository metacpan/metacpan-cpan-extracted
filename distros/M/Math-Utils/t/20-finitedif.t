#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More tests => 10;

use Math::Utils qw(:polynomial :utility);

#
# Tests by creating polynomials from known sequences.
# The sequences after the sum-of-powers tests are taken
# from New Mathematical Diversions From Scientific American,
# by Martin Gardner, chapter 20.
#
my($fc, $start, @seq);
my($mult, $div, $p);

#
# Cubic 4 4 1 1
#
$start = 0;
@seq = (4, 10, 24, 52, 100);

$fc = seq_difference(\@seq);
($mult, $div, $p) = make_poly($fc, $start);

#diag("Cubic: $mult, $div, [", join(", ",@$p) . "]");
ok(($mult == 1 and $div == 1 and join("", @$p) eq "4411"), "Test Cubic 4 4 1 1");

#
# Sum of powers, p = 1 (triangle numbers).
#
$start = 0;
@seq = (0, 1, 3, 6, 10);

$fc = seq_difference(\@seq);
($mult, $div, $p) = make_poly($fc, $start);

#diag("Triangles: $mult, $div, [", join(", ",@$p) . "]");
ok(($mult == 1 and $div == 2 and join("", @$p) eq "011"), "Triangle numbers");

#
# Sum of powers, p = 2
#
$start = 0;
@seq = (0, 1, 5, 14, 30, 55);

$fc = seq_difference(\@seq);
($mult, $div, $p) = make_poly($fc, $start);

#diag("Squares: $mult, $div, [", join(", ",@$p) . "]");
ok(($mult == 1 and $div == 6 and join("", @$p) eq "0132"), "Sum of squares.");

#
# Sum of powers, p = 3
#
$start = 0;
@seq = (0, 1, 9, 36, 100, 225);
$fc = seq_difference(\@seq);
($mult, $div, $p) = make_poly($fc, $start);

#diag("Cubics: $mult, $div, [", join(", ",@$p) . "]");
ok(($mult == 1 and $div == 4 and join("", @$p) eq "00121"), "Sum of cubics");

#
# For each cut, what is the maximum number of pieces when slicing a circle.
#
$start = 0;
@seq = (1, 2, 4, 7, 11);
$fc = seq_difference(\@seq);
($mult, $div, $p) = make_poly($fc, $start);

#diag("Circle cutting problem: $mult, $div, [", join(", ",@$p) . "]");
ok(($mult == 1 and $div == 2 and join(",", @$p) eq "2,1,1"), "Circle cutting problem");

#
# Number of pieces produced by n plane cuts through a cylinder.
#
$start = 0;
@seq = (1, 2, 4, 8, 15);
$fc = seq_difference(\@seq);
($mult, $div, $p) = make_poly($fc, $start);

#diag("Cylinder cutting problem: $mult, $div, [", join(", ",@$p) . "]");
ok(($mult == 1 and $div == 6 and join(",", @$p) eq "6,5,0,1"), "Cylinder cutting problem");

#
# What is the maximum number of pieces produced by n simultaneous plane cuts
# through a doughnut.
#
# There's ambiguity about what counts as a "piece" when there are zero cuts,
# so start at one cut.
#
$start = 1;
@seq = (2, 6, 13, 24);
$fc = seq_difference(\@seq);
($mult, $div, $p) = make_poly($fc, $start);

#diag("Doughnut cutting problem: $mult, $div, [", join(", ",@$p) . "]");
ok(($mult == 1 and $div == 6 and join(",", @$p) eq "0,8,3,1"), "Doughnut cutting problem");

#
# What are the maximum number of triangles one can create when drawing n lines on paper.
#
$start = 1;
@seq = (0, 0, 1, 4, 10);
$fc = seq_difference(\@seq);
($mult, $div, $p) = make_poly($fc, $start);

#diag("Triangle drawing problem: $mult, $div, [", join(", ",@$p) . "]");
ok(($mult == 1 and $div == 6 and join(",", @$p) eq "0,2,-3,1"), "Triangle drawing problem");

#
# What are the maximum number of areas one can create by drawing n intersecting circles.
#
$start = 1;
@seq = (2, 4, 8, 14);
$fc = seq_difference(\@seq);
($mult, $div, $p) = make_poly($fc, $start);

#diag("Circle drawing problem: $mult, $div, [", join(", ",@$p) . "]");
ok(($mult == 1 and $div == 1 and join(",", @$p) eq "2,-1,1"), "Circle drawing problem");

#
# What are the maximum number of regions of space one can create by through n intersecting spheres.
#
$start = 1;
@seq = (2, 4, 8, 16);
$fc = seq_difference(\@seq);
($mult, $div, $p) = make_poly($fc, $start);

#diag("Intersecting spheres problem: $mult, $div, [", join(", ",@$p) . "]");
ok(($mult == 1 and $div == 3 and join(",", @$p) eq "0,8,-3,1"), "Intersecting spheres problem");

#print_diff_triangle(seq_difference(\@seq, triangle => 1));
#print "\nDifference column:\n", join(", ", @$fc), "\n";
#print "Polynomial is: [", join(", ", @{$p}), "]/$m\n";

#
# Healing wait in turns per level in the game Rogue (unfortunately, resulted in a messy polynomial).
#
#$start = 1;
#@seq = ( 20, 18, 17, 14, 13, 10, 9, 8, 7, 4, 3, 2);

exit (0);

#
# using the first column of the difference triangle, create the polynomial.
#
sub make_poly
{
	my($seq, $startfrom) = @_;
	my(@diffs) = @$seq;
	my $n = $#diffs;
	my $p = [1];
	my($mult, $div) = (1, 1);

	#
	# Set up the 1, x, x(x-1), x(x-1)(x-2), ... etc. polynomial sequence.
	#
	my @seq = ($p);

	for my $k (0 .. $n)
	{
		$seq[$k] = [ map($_ * $diffs[$k], @{$p}) ];
		$p = pl_mult($p, [-($startfrom + $k), 1]);
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

	#
	# Now find common factors.
	#
	my(@coefs) = grep($_ != 0, @{$p});

	if (scalar @coefs)
	{
		$mult = gcd(@coefs);
		my $d = gcd($mult, $m);
		$p = [map($_/$mult, @{$p})];
		$mult /= $d;
		$div = $m / $d;
	}

	return ($mult, $div, $p);
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

#sub print_poly_sequence
#{
#	my(@seq) = @_;
#
#	my $idx = 0;
#	print "\nThe polynomial sequences:\n";
#	for my $q (@seq)
#	{
#		printf("%2d: [%s] / %d!\n",
#			$idx,
#			join(", ", @{$q}),
#			$idx);
#		$idx++;
#	}
#	print "\n";
#}

#
# $first_col = seq_difference([0, 1, 2, 4, 7, 13, 24]);
# $diff_triangle = seq_difference([0, 1, 2, 4, 7, 13, 24], triangle => 1);
#
sub seq_difference
{
	my($seq, %opt) = @_;
	my(@numbers) = @$seq;

	my $triangle = (exists $opt{triangle} and $opt{triangle} != 0)? 1: 0;
	my $n = $#numbers;

	my(@diffs) = ($numbers[0]);

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

		push @diffs, ($triangle)? [@v]: $v[0];

		@numbers = @v;
	}
	return \@diffs;
}

