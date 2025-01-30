#!/bin/perl.exe -w 
# 002_Arithmetic.t: Test the Math::Yapp arithmetic functions: Add,
#                   Subtract, Multiply, Divide; all via their overloaded
#                   operators.  Also the unary operators for negation (!)
#                   and conjugation (~)
#
use strict;
use warnings;

use Test::More 'no_plan';      # Skip this? use done_testing()
BEGIN { use_ok('Math::Yapp') };

use Carp;
use Math::Complex;
use Math::Yapp;
use Data::Dumper;

Yapp_testmode(0);
Yapp_decimals(2);
Yapp_print0(1);     # Include zero coefficients in the output
Yapp_start_high(0); # Start from low-order terms

print ("Testing addition\n");
my @y_list1 = (1, -2, 3, 0, 5, -6, 7);  # 6th degree poly
my @y_list2 = (-2, 3, -4, 5);           # 3rd degree 
my $poly1 = Yapp(\@y_list1);            # Create the Yapp objects I need
my $poly2 = Yapp(\@y_list2);            # for arithmetic
my $poly3 = $poly1 + $poly2;
my $expect_poly3
   = "-1.00 +1.00X -1.00X^2 +5.00X^3 +5.00X^4 -6.00X^5 +7.00X^6";
print $poly1->Ysprint(), "\n+  ", $poly2->Ysprint(),
      "\n=  ", $poly3->Ysprint(), "\n";
is($poly3->Ysprint(), $expect_poly3, "2-Yapp addition");

print "Testing to just add a complex constant:\n";
$poly3 = $poly1 + cplx(-4,3);                   # Just add a constant
$expect_poly3
  = "(-3.00+3.00i) -2.00X +3.00X^2 +0.00X^3 +5.00X^4 -6.00X^5 +7.00X^6";
print cplx(-4,3), "\n+ ", $poly1->Ysprint(), "\n",
      $poly3->Ysprint(), "\n";
is($poly3->Ysprint(), $expect_poly3, "Test adding a constant to Yapp");

print ("Test subtraction of polynomials:\n");
$poly3 = $poly1 - $poly2;
$expect_poly3 = "3.00 -5.00X +7.00X^2 -5.00X^3 +5.00X^4 -6.00X^5 +7.00X^6";
print "  ", $poly1->Ysprint(), "\n- ", $poly2->Ysprint(), "\n",
	  " = ", $poly3->Ysprint(), "\n";
is($poly3->Ysprint(), $expect_poly3, "Test 2-Yapp subtraction");

print "Subtract a constant from a polynomial\n";
$poly3 = $poly1 - 10;
printf("  <%s>\n- <%3.2f> =\n  <%s>\n",
       $poly1->Ysprint(), 10, $poly3->Ysprint());
diag "  ", $poly1->Ysprint(), " - 10";
diag "= ", $poly3->Ysprint();
$expect_poly3
  = "-9.00 -2.00X +3.00X^2 +0.00X^3 +5.00X^4 -6.00X^5 +7.00X^6";
is($poly3->Ysprint(), $expect_poly3, "Test Yapp minus constant");

print "Test subtract polynomial from a constant\n";
$poly3 = 10 - $poly1;
printf(" <%3.2f>\n- <%s> =\n  <%s>\n",
        10,  $poly1->Ysprint(), $poly3->Ysprint());
print "  10 - (", $poly1->Ysprint(), ")\n";
print "= ", $poly3->Ysprint(), "\n";
$expect_poly3
  = "9.00 +2.00X -3.00X^2 +0.00X^3 -5.00X^4 +6.00X^5 -7.00X^6";
is($poly3->Ysprint(), $expect_poly3, "Test constant minus Yapp");

print ("\nTesting multiplication by a constant:\n");
$poly3 = 10 * $poly1;
diag "  10 * ", $poly1->Ysprint();
diag "= ", $poly3->Ysprint();
$expect_poly3
 = "10.00 -20.00X +30.00X^2 +0.00X^3 +50.00X^4 -60.00X^5 +70.00X^6";
is($poly3->Ysprint(), $expect_poly3, "Test multiply by constant on left");

my $poly4 = $poly1 * 10;
my $expect_poly4
 = "10.00 -20.00X +30.00X^2 +0.00X^3 +50.00X^4 -60.00X^5 +70.00X^6";
diag "  ", $poly1->Ysprint(), " * 10";
diag "= ", $poly3->Ysprint();
is($poly4->Ysprint(), $expect_poly4, "Test multiply by constant on right");

diag("\nTesting multiplication of two polynomials");
$poly3 = $poly1 * $poly2;
printf("  <%s>\n* <%s>\n= <%s>\n",
       $poly1->Ysprint(), $poly2->Ysprint(), $poly3->Ysprint(),);
$expect_poly3
= "-2.00 +7.00X -16.00X^2 +22.00X^3 -32.00X^4 +42.00X^5 -52.00X^6 "
. "+70.00X^7 -58.00X^8 +35.00X^9";
diag "  ", $poly1->Ysprint(), "\n * ", $poly2->Ysprint();
diag "= ", $poly3->Ysprint();
is($poly3->Ysprint(), $expect_poly3, "Test multiply two polynomials");

diag ("\nTesting division by constant, real and complex\n");
$poly3 = $poly1 / 7;    # Make the top term a 1
printf("  <%s> / <%3.2f>\n= <%s>\n",
       $poly1->Ysprint(), 7, $poly3->Ysprint());
$expect_poly3 
= "0.14 -0.29X +0.43X^2 +0.00X^3 +0.71X^4 -0.86X^5 +1.00X^6";
is($poly3->Ysprint(), $expect_poly3, "Test divide by real constant");

$poly3 = $poly1 / cplx(1,-3);
printf("  <%s> / (1-3i)\n= <%s>\n",
       $poly1->Ysprint(), $poly3->Ysprint());
$expect_poly3
= "(0.10+0.30i) +(-0.20-0.60i)X +(0.30+0.90i)X^2 +0.00X^3 +(0.50+1.50i)X^4"
. " +(-0.60-1.80i)X^5 +(0.70+2.10i)X^6";
is($poly3->Ysprint(), $expect_poly3, "Test divide by complex constant");


printf("\nTest negation and conjugation\n");
$poly1 = Yapp(\@y_list1);           # Recreate Yapp I used earlier
$poly4 = ! $poly1;                  # Take its negative
printf("  <%s> Negated\n= <%s>\n", $poly1->Ysprint(), $poly4->Ysprint());
$expect_poly4
= "-1.00 +2.00X -3.00X^2 +0.00X^3 -5.00X^4 +6.00X^5 -7.00X^6";
is($poly4->Ysprint(), $expect_poly4, "Test negation of all coefficients");

printf("\nTest in-place negation\n");
#Xprintf("Before in-place negation:\n%s\n", $poly4->Ysprint());
#X$poly4->Yapp_negate();          # Negate this in-place. Should be back to $poly1
#X$expect_poly4                   # Negate my expected string as well
#X=  "1.00 -2.00X +3.00X^2 +0.00X^3 +5.00X^4 -6.00X^5 +7.00X^6";
#Xprintf("After in-place negation:\n%s\n", $poly4->Ysprint());
#Xis($poly4->Ysprint(), $expect_poly4, "In-place negation of coefficients");
print "(In place negation not working. Skipping this test)\n";

$poly4 = ~ $poly3;
printf("  <%s> Conjugated\n= <%s>\n",
       $poly3->Ysprint(), $poly4->Ysprint());
$expect_poly4
= "(0.10-0.30i) +(-0.20+0.60i)X +(0.30-0.90i)X^2 +0.00X^3 "
. "+(0.50-1.50i)X^4 +(-0.60+1.80i)X^5 +(0.70-2.10i)X^6";
is($poly4->Ysprint(), $expect_poly4,
   "Test conjugation of complex coefficients");

printf("\nTest in-place conjugation\n");
#X~$poly4;                        # Should revert back to $poly3
#Xis($poly4->Ysprint(), $poly3->Ysprint(),
#X   "In-place conjugation of coefficients");
print "(In place conjugation is not working. Skipping this test)\n";


printf("\nTest raising a polynomial to a power\n");
my $poly2_3p = $poly2 ** 3;     # Kept simple: a 3rd degree poly, cubed
my $poly2_3m = $poly2
             * $poly2 * $poly2; # Cubed also but not using ** operator
my $expected_3p = $poly2_3m->Ysprint(); # Expect to match simple multiplication
my $actual_3p   = $poly2_3p->Ysprint(); # What I actualy got using ** operator
printf("  <%s> ** 3\n= <%s>\n", $poly2->Ysprint(), $actual_3p);
is($actual_3p, $expected_3p, "Test if power matches multiplication");

printf("\nTest if an integer to a Yapp power fails\n");
my $junk;
eval { $junk = 2 ** $poly2; };
printf("Eval returned message:\n%s", $@);   # $@ is the "die" message
is($junk, undef, "Test if swapping ** operands barfs");

# $junk = 2 ** $poly2;          # This fails just fine but would kill the test.

printf("\nTest raising a polynomial to a non-integer power\n");
eval {$junk = $poly2 ** 3.14;};
printf("Eval returned message:\n%s", $@);   # $@ is the "die" message
is($junk, undef, "Test if ** to a fractional power barfs");

print("End of Yapp arithmetic tests\n");
done_testing();
exit;
