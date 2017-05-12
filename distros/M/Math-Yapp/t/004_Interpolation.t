#!/bin/perl.exe -w
# 004_Interpolation.t
# 004_Solutions.t: Test interpolation of Yapp polynomials
#
use strict;
use warnings;

use Test::More;     # No test count in advance

BEGIN { use_ok('Math::Yapp') };

use Carp;
use Math::Complex;
use Math::Yapp;
use Data::Dumper;
#use Test::More 'no_plan';      # Skip this; use done_testing()

# First, diddle with the global settings
#
Yapp_testmode(0);
Yapp_decimals(2);
Yapp_print0(0);     # Don't Include zero coefficients in the output
Yapp_start_high(1); # Don't Start from low-order terms

my $margin = 1.0 / (10**10);    # When I consider results to be close enough

# Test for laGrange interpolation - just X and Y values
#
printf("\nTesting Lagrange interpolation with 2 arrays of 7 points\n");
my @X  = (-2.0, -1.0, 0.0,  1.0,  2.0,  4.0,  8.0);  # Input points do not need
my @Y  = ( 3.0,  6.0, 9.0, -2.0, -1.0, -3.0, -3.0);  # to be evenly spaced
my @Yp = ( 5.0,  4.0, 0.0, -3.0,  2.0,  2.5, -4.5);  # Y-prime derivatives

my $inty = Yapp_interpolate(\@X, \@Y);  # Send through the interpolation
printf("Interpolated polynomial:\n<%s>\n", $inty->Ysprint());

# Now, if I plug in the X values, I *should* get back my original Y values
#
my $ok_count = 0;                   # Count successful points
for (my $xlc = 0; $xlc <= $#X; $xlc++)
{
  my $y_val = $inty->Yapp_eval($X[$xlc]);   # Recapture the Y value at this X
  printf("For X = %+f: Evaluates to %+17.15f, compared to %+17.15f\n",
         $X[$xlc], $y_val, $Y[$xlc]);
  $ok_count++ if (abs($y_val - $Y[$xlc]) <= $margin);
                                    # Count up only if it matches close enough
}
is($ok_count, 7, "Test correct 7-point Lagrange interpolation");
#
my $int_size = length(pack("p", 0));    # Running in a 32 or 64-bit Perl build?
printf("\nint_size = %d\n", $int_size);   # DEBUG but keep.
if ($int_size == 4)
{
  printf("\nTesting Hermite interpolation with 3 arrays of 4 points\n");
  splice(@X,  4);   # Remove elements [4..6]
  splice(@Y,  4);   # from X and Y arrays
  splice(@Yp, 4);   # as well as the derivatives
  my $intyp = Yapp_interpolate(\@X, \@Y, \@Yp); # Interpolate *dis*! ;-)
  my $intyp_p = $intyp->Yapp_derivative(1);     # Capture derivative thereof
  printf("Interpolated  polynomial:\n<%s>\n", $intyp->Ysprint());
  printf("Derivative of polynomial:\n<%s>\n", $intyp_p->Ysprint());
  
  $ok_count = 0;                        # Reset scorekeeper.
  for (my $xlc = 0; $xlc <= $#X; $xlc++)
  {
    my $y_val = $intyp->Yapp_eval($X[$xlc]);    # Recapture Y value at this X
    printf("For X = %+f: Evaluates to %+17.15f, compared to %+17.15f\n",
           $X[$xlc], $y_val, $Y[$xlc]);
    $ok_count++ if (abs($y_val - $Y[$xlc]) <= $margin);
  
    my $yp_val= $intyp_p->Yapp_eval($X[$xlc]); # Recapture derivative value here
    printf("For X = %+f: Derivative evals to %+17.15f, compared to %+17.15f\n",
           $X[$xlc], $yp_val, $Yp[$xlc]);
    $ok_count++ if (abs($yp_val - $Yp[$xlc]) <= $margin);
                                    # Count up only if it matches close enough
  }
  # That's actually 8 tests it had to pass: for each of 4 points, the y value
  # and its derivative
  #
  is($ok_count, 8, "Test correct 4-point Hermite interpolation");
}
elsif ($int_size == 8)
{
  # Don't do the same splice as for 32-bit test
  #
  splice(@X,  6);   # Remove element [6]
  splice(@Y,  6);   # from X and Y arrays
  splice(@Yp, 6);   # as well as the derivatives
  printf("\nTesting Hermite interpolation with 3 arrays of 6 points\n");

  my $intyp = Yapp_interpolate(\@X, \@Y, \@Yp); # Interpolate *dis*! ;-)
  my $intyp_p = $intyp->Yapp_derivative(1);     # Capture derivative thereof
  printf("Interpolated  polynomial:\n<%s>\n", $intyp->Ysprint());
  printf("Derivative of polynomial:\n<%s>\n", $intyp_p->Ysprint());
  
  $ok_count = 0;                        # Reset scorekeeper.
  for (my $xlc = 0; $xlc <= $#X; $xlc++)
  {
    my $y_val = $intyp->Yapp_eval($X[$xlc]);    # Recapture Y value at this X
    printf("For X = %+f: Evaluates to %+17.15f, compared to %+17.15f\n",
           $X[$xlc], $y_val, $Y[$xlc]);
    $ok_count++ if (abs($y_val - $Y[$xlc]) <= $margin);
  
    my $yp_val= $intyp_p->Yapp_eval($X[$xlc]); # Recapture derivative value here
    printf("For X = %+f: Derivative evals to %+17.15f, compared to %+17.15f\n",
           $X[$xlc], $yp_val, $Yp[$xlc]);
    $ok_count++ if (abs($yp_val - $Yp[$xlc]) <= $margin);
                                    # Count up only if it matches close enough
  }
  # That's actually 14 tests it had to pass: for each of 7 points, the y value
  # and its derivative
  #
  is($ok_count, 2*scalar(@X), "Test correct 6-point Hermite interpolation");
}
else
{ die "This Perl seems to be neither 32 nor 64-bit"; }
#
# Test constructor by roots
#
printf("\nTest construct by roots\n");
my @root_list = (-1, 2, cplx(2,1), cplx(2, -1),
                cplx(sqrt(3),sqrt(.5)), cplx(sqrt(3),-sqrt(.5)) );
my $yapp6 = Yapp_by_roots(\@root_list);
printf("Constructed:\n%s\n", $yapp6->Ysprint());
$ok_count = 0;          # Haven't passed any of the checks yet
for (my $rlc = 0; $rlc < @root_list; $rlc++)
{
  my $zero = $yapp6->Yapp_eval($root_list[$rlc]);
  my $root_string;
  $root_string = Csprint($root_list[$rlc]); # Works for non-complex also
  printf("Evaluation at %s yields %s\n", $root_string, Csprint($zero));

  $ok_count++ if (abs($zero) <= $margin);
}
is($ok_count, @root_list, "Success: Contructing polynomial by roots");

print "End of interpolation and by-roots tests\n";
done_testing();
exit;
