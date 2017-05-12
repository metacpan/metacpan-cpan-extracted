#!/bin/perl.exe  -w
# 003_Transforms.t: Test transofrms like derivative, antiderivative, and while
#                   we're at it, evaluation and integration over an interval.
#                   (Thinking of LaPlace transform but the result is not an
#                   algebraic polynomial. So that may be beyond my scope.)
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

# Test for just the evaluation at a value
#
my $x4 = Yapp("X^4 -1");
my $result = $x4->Yapp_eval(2.0);   # So lets test 2^4 -1 == 15?
my $expect_val = 15.0;
printf("  <%s> Evaluated at X=2\n= %5.2f\n", $x4->Ysprint(), $result);
is($result, $expect_val, "Test polynomial evaluation\n");

# Now test for evaluation as well as quotient
#
my ($result2, $yresult2) = $x4->Yapp_eval(3.0); # Result should be 80
$expect_val = 80.0;
printf("  <%s> Evaluated at X=3 = %5.2f\n", $x4->Ysprint(), $result2);
is($result2, $expect_val, "Another evaluation test, with quotient\n");
printf(" And quotient is: <%s>\n", $yresult2->Ysprint());

# To check the "division", multiply the quotient my (x - input) and add
# back the remainder
#
my $check_divide = Yapp("X -3") * $yresult2 + $result2;
is($check_divide->Ysprint(), $x4->Ysprint(),
    "Test if quotient multiplies back out after remainder\n");

# Using a different polynomial, 2X^4 -1, reduce the roots by 2
#
$x4 = Yapp("2X^4 - 1");     # With one root = 4th root of .5
my $x4r = $x4->Yapp_reduce(2.0);
my $expect_poly = "2.00X^4 +16.00X^3 +48.00X^2 +64.00X +31.00";
printf("  <%s>, with roots reduced by 2, is:\n  <%s>\n",
       $x4->Ysprint(), $x4r->Ysprint());
is ($x4r->Ysprint(), $expect_poly, "Test reduction of roots\n");
my $expect_root = (.5 ** .25) - 2.0;
$result = $x4r->Yapp_eval($expect_root);    # Is this really a root?

# If $expect_root is really a root, the above evaluation should be very
# close to 0. Like within the $margin I set above
#
my $close_enough = (abs($result) <= $margin) ? 1:0;
is($close_enough, 1, "Test if one known root has really been reduced\n");

# Now see about negating signs of the roots.
#
my @p_roots = (1,2,-3,cplx(4,1),cplx(4,-1));	# Roots before negation
my @n_roots = map {-$_} @p_roots;               # Roots after negation
my $p_yapp = Yapp_by_roots(\@p_roots);          # Create polynomial by roots
my $n_yapp = $p_yapp->Yapp_negate_roots();      # Negate roots of original Yapp
my $ok_nroots = 0;								# Count valid negated roots
foreach my $nroot (@n_roots)
{
  if (abs($n_yapp->Yapp_eval($nroot) ) < $margin) {$ok_nroots++;}
}
is($ok_nroots, 5, "Test if roots have been successfully negated\n");

# Now for derivative
#
my @d_list = (-3,4,5,-8,5,-13,-12,2);   # For a 7th degree Yapp
my $x7 = Yapp(\@d_list);            # And its polynomial
my $d1_x7 = $x7->Yapp_derivative(); # Get its first derivative
printf("D<%s>\n=<%s>\n", $x7->Ysprint(), $d1_x7->Ysprint());
my $expect_d1 = "14.00X^6 -72.00X^5 -65.00X^4 +20.00X^3 -24.00X^2"
              . " +10.00X +4.00";
is ($d1_x7->Ysprint(), $expect_d1, "Test first Derivative\n");

# Now starting from the same polynomial from scratch, get the 3rd
# derivative.

#
undef $x7;                  # Lose our polynomial
$x7 = Yapp(\@d_list);       # and recreate it from scratch
my $d3_x7 = $x7->Yapp_derivative(3);    # Get 3rd derivative
printf("D3 of <%s>\nis:   <%s>\n", $x7->Ysprint(), $d3_x7->Ysprint());

# Now, are all derivatives in order? (Pun unintended)
#
for (my $dlc = 1; $dlc <= 3; $dlc++)
{
  printf("D%d is <%s>\n", $dlc, ($x7->{derivative}[$dlc])->Ysprint());
}

# Only in the debugger can I check this: When I ask for the 4th derivative,
# will it start from scratch or from the already calculated 3rd derivative?
#
my $d4_x7 = $x7->Yapp_derivative(4);    # Get 4th derivative
printf("D4 is <%s>\n", $d4_x7->Ysprint());
my @expect_derivs
= ("(Degenerate)",          #(Will not be used in test)
   "14.00X^6 -72.00X^5 -65.00X^4 +20.00X^3 -24.00X^2 +10.00X +4.00",
   "84.00X^5 -360.00X^4 -260.00X^3 +60.00X^2 -48.00X +10.00",
   "420.00X^4 -1440.00X^3 -780.00X^2 +120.00X -48.00",
   "1680.00X^3 -4320.00X^2 -1560.00X +120.00"
  );
my $eq_count = 0;                       # How many equal strings have I found?
for (my $dlc = 1; $dlc <= 4; $dlc++)    # I know I ran 4 derivatives..
{
   $eq_count++
        if ($expect_derivs[$dlc] = ($x7->{derivative}[$dlc])->Ysprint());
}
is ($eq_count, 4, "Test up to 4 derivatives are correct\n");

# Test indefinite integral
#
my @i_list = (9, -4, 0, -2, 3, 2);
my $i_yapp = Yapp(\@i_list);
my $ii_yapp = $i_yapp->Yapp_integral();
printf ("D_-1<%s>\nis  <%s>\n", $i_yapp->Ysprint(), $ii_yapp->Ysprint());
my $check_yapp = $ii_yapp->Yapp_derivative();   # Now check if it was correct
                                                # by differentiating back
printf("Differentiates back to <%s>\n", $check_yapp->Ysprint());
is ($i_yapp->Yapp_equiv($check_yapp), 1,
    "Test that I can differentiate the integral back to the original\n");

# Now for a definite integral, using the above computed indefinte integral.
# Only a debugger trace will show wheher or not is uses the cached indefinite
# integral
#
my @limits = (-1, 1);
my $i_val = $i_yapp->Yapp_integral(@limits);
printf("Integral of <%s> from %4.2f to %4.2f = %8.5f\n",
       $i_yapp->Ysprint(), $limits[0], $limits[1], $i_val);

print("End of transform tests\n");
done_testing();
exit;
