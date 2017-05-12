#!/bin/perl.exe -w
# 005_Solutions.t: Test finding solutions (i.e. zeroes) of the polynomial
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

my $ok_count;       # Sometimes, it takes a few steps to see if the answer
                    # is correct
my $margin = 1.0 / (10**10);    # When I consider results to be close enough

# Quadratic equation with real roots:
#
printf("\nTest quadratic polynomial with real roots\n");
my $quadr = Yapp("2X +1") * Yapp("X -6");   # Solutions: (-.5, 6)
my @solutions = $quadr->Yapp_solve();
my $solv_string = join(", ", @solutions);
printf("Quadratic polynomial <%s> solved to real roots: <%s>\n",
       $quadr->Ysprint(), "$solv_string");
$ok_count = 0;              # start counting correct roots
$ok_count++ if (grep(-.5, @solutions));
$ok_count++ if (grep(6,   @solutions));
is($ok_count, 2, "Test quadratic Yapp with known real roots");

# Now for complex roots: I predetermined roots:
# -(1/3) + i*sqrt(5)
# -(1/3) - i*sqrt(5)
#
printf("\nTest quadratic polynomial with complex roots\n");
my @croots = (cplx((-1/3), sqrt(5)), cplx((-1/3), -sqrt(5)));
$quadr = Yapp("9X^2 + 6X +46");
@solutions = $quadr->Yapp_solve();
$solv_string = join(", ", @solutions);
printf("Quadratic polynomial <%s> solved to:\n  <%s>\n",
       $quadr->Ysprint(), $solv_string);
$ok_count = 0;
$ok_count++ if (grep($croots[0], @solutions));
$ok_count++ if (grep($croots[1], @solutions));
is($ok_count, 2, "Success: Quadratic Yapp with known complex roots");

# Cubic equation, with 1 real, 2 complex roots
#
printf("\nTest cubic equation, with 1 real, 2 complex roots\n");
my $cubic = Yapp("3X^3 -18X^2 + 30X -8");   # Real root ~ .3275
@solutions = $cubic->Yapp_solve();
$solv_string = join(", ", @solutions);
printf("Cubic polynomial <%s> solved to:\n  <%s>\n",
       $cubic->Ysprint(), $solv_string);

# To test, let's evaluate the original polynomial at each of these solutions.
#
Yapp_decimals(15);
$ok_count = test_solutions($cubic, \@solutions);   # Eval @ all alleged roots
is($ok_count, 3, "Success: Cubic Yapp with 1 real, 2 complex roots");

Yapp_decimals(5);   # Restore to readable setting

# OK, now I test a quartic solution. This one will have 4 complex roots.
# 
printf("\nTest quartic Yapp, with 2 pairs of complex roots\n");
my $quartic = Yapp("3X -(1+2i)") * Yapp("3X -(1-2i)")
            * Yapp("X -(-2+4i)") * Yapp("X -(-2-4i)");
printf("Test quartic = <%s>\n", $quartic->Ysprint());
@solutions = $quartic->Yapp_solve();

# To test, let's evaluate the original polynomial at each of these solutions.
#
Yapp_decimals(15);
$ok_count = test_solutions($quartic, \@solutions);
is($ok_count, 4, "Success: Quartic Yapp with 2 pairs of complex roots");

# Start playing with 5th degree;
#
printf("\nTest quintic Yapp, with 2 pairs of complex roots, 1 real root\n");
$margin = Yapp_margin(1/(10**12));
my $quintic = $quartic * Yapp("2X -5");   # Real solution: 2.5
Yapp_decimals(3);
printf("Test quintic = <%s>\n", $quintic->Ysprint);
Yapp_decimals(15);
@solutions = $quintic->Yapp_solve();
$ok_count = test_solutions($quintic, \@solutions);
is($ok_count, 5,
    "Success: Quintic that is previous quartic with 2.5 real solution");

# Now, a 6th degree (sixtic?) equation.  I will set up for all complex roots.
#
printf("\nTest 6th-degree Yapp, with 3 pairs of complex roots\n");
#$margin = Yapp_margin(1/(10**10));
$margin = (1/(10**9));
printf("Setting testing margin to %13.11f\n", $margin);
my $yapp6 = Yapp(1);
my @mroots = (cplx(2,sqrt(3)), cplx(-5,sqrt(7)), cplx(-11, 7));
my @x_coefs = (1, 3, 2);
for (my $rlc = 0; $rlc < 3; $rlc++)
{
  $yapp6 *= Yapp(-$mroots[$rlc], $x_coefs[$rlc])
          * Yapp(-(~$mroots[$rlc]), $x_coefs[$rlc]);
}
# Now get rid of tiny rounding coefficients that stem from all those radicals
# in above
#
#Yapp_decimals(3);
#printf("Test   6-deg = <%s>\n", $yapp6->Ysprint);
@{$yapp6->{coeff}} = map {int($_)} @{$yapp6->{coeff}} ;
Yapp_decimals(1);
printf("Test 6-deg = <%s>\n", $yapp6->Ysprint);
Yapp_decimals(15);
@solutions = $yapp6->Yapp_solve();
$ok_count = test_solutions($yapp6, \@solutions);
is($ok_count, 6,
    "Success: 6th degree Yapp with 3 pairs of complex roots\n");

#
#------------------------------------------------------------------------
# test_solutions() - Test if the solutions I got back solve the original
# polynomial.
# Parameters:
# - A Yapp polynomial object (reference, of course)
# - A reference to an array of alleged solutions
# Returns:
# - Number of solutions that worked OK.
#
sub test_solutions
{
  my ($poly, $solvers) = @_;
  my $goodies = 0;      # Have not counted any good solutions yet
  foreach my $zero (@{$solvers})
  {
    my $eval = $poly->Yapp_eval($zero);     # Evaluate polyn at that zero-point
    my $z_string = (ref($zero) eq "Math::Complex") ?
                     Csprint($zero) : sprintf("%.15f", $zero);
                                            # Generate appropriate string
    my $e_string = (ref($eval) eq "Math::Complex") ?
                     Csprint($eval) : sprintf("%.15f", $eval);
    printf("Value of original polynomial at %s is %s ", $z_string, $e_string);
    if (abs($eval) <= $margin)
    {
      printf ("Close enough\n");
      $goodies++;
    }
    else
    {
      printf ("No cigar\n");
    }
  }
  return $goodies
}

print("End of testing polynomial solutions\n");
done_testing();
exit;
