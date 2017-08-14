#!perl -T
use 5.008003;
use strict;
use warnings FATAL => 'all';
use Math::Derivative qw(:all);
use Math::Utils qw(:compare :polynomial);
use Test::More tests => 1;

#
# This type of derivative calculating is terribly noisy.
#
my($fltcmp) = generate_fltcmp(0.05);

#
# The polynomial, its derivative, and its second derivative.
#
my @coef = (1, -1, -2, -7, 2);
my @dx_coef = @{ pl_derivative(\@coef) };
my @d2x_coef = @{ pl_derivative(\@dx_coef) };

# diag(@dx_coef);
# diag(@d2x_coef);

#
# The X values in steps of 0.10.
#
my @xvals = map{$_ / 10} (5 .. 29);

#
# The Y values from the polynomial, the first derivatives
# at the end points, and the expected second derivatives.
#
my @yvals = pl_evaluate(\@coef, \@xvals);
my($yp0, $ypn) = pl_evaluate(\@dx_coef, $xvals[0], $xvals[$#xvals]);
my @expected = pl_evaluate(\@d2x_coef, \@xvals);

# diag($yp0);
# diag($ypn);

#
# Get the second derivative approximations,
# and compare them.
#
my @d2ydx2 = Derivative2(\@xvals, \@yvals, $yp0, $ypn);

my $msg = "";

for my $j (0 .. $#expected)
{
	if (&$fltcmp($d2ydx2[$j], $expected[$j]) != 0)
	{
		$msg .= sprintf("%g returned at index %d; expected %g\n",
				$d2ydx2[$j],
				$j,
				$expected[$j]);
	}
}

if ($#expected < $#d2ydx2)
{
	$msg .= "More values returned than expected: (" .
		join(", ", @d2ydx2[$#expected+1 .. $#d2ydx2]) . ")\n";
}

ok($msg eq "", $msg);

