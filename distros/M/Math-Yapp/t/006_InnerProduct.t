#!/bin/perl.exe -w
# 006_InnerProduct.t: Test the functions involved in inner product vector
# space properties of Legendre polynomials
#
use strict;
use warnings;

use Test::More;     # No test count in advance
BEGIN { use_ok('Math::Yapp') };

use Carp;
use Math::Complex;
use Math::Yapp;
use Data::Dumper;
#use blib;

# Diddle with the global settings
#
Yapp_testmode(1);   # Turn on extra messages for this test module
Yapp_decimals(2);
Yapp_print0(0);     # Don't Include zero coefficients in the output
Yapp_start_high(1); # Don't Start from low-order terms

my $ok_count;       # Sometimes, it takes a few steps to see if the answer
                    # is correct
my $margin = 1.0 / (10**10);    # When I consider results to be close enough
#
my $class_cplx = "Math::Complex";

printf("\nTest ordinary inner product of two Yapps\n");
$ok_count = 0;      # Use flag in this test
my @c_list1 = (cplx(2,3), 1, -2, cplx(3,.5), -4, 5);    # 5th & 6th degree
my @c_list2 = (2, cplx(1.5,-1), 3, -.5, 5.2, cplx(-1,-2.2), cplx(-2,-.9));
#my @c_list1 = (cplx(2,3), cplx(3,.5), -4, 5);               # Cubic
#my @c_list2 = (cplx(1.5,-1), cplx(-1,-2.2), cplx(-2,-.9));  # Quadratic

my $cpoly1 = Yapp(\@c_list1);       # Convert the first to Yapp object
my $cpoly2 = Yapp(\@c_list2);       # and the second one as well

my $coutp1 = $cpoly1->Ysprint();
my $coutp2 = $cpoly2->Ysprint();
printf("Get the inner product of these two polynomials:\n%s\n%s\n",
        $coutp1, $coutp2);
my $prod1 = $cpoly1 . $cpoly2 ;
my $prod1_string = Csprint($prod1); # Might have gotten a real but that's OK
printf("Inner product = <%s>\n", $prod1_string);    # Show what we got.

# Now test: is <poly1 . poly2> = conj(<poly2, <poly1>)?
#
printf ("Now see if this matches conj(P2 . P1)\n");
my $prod2 = $cpoly2 . $cpoly1;
printf("Commuted inner product = <%s>\n", Csprint($prod2));
my $conj_prod2 = ~$prod2;               # Take conjugate of commuted product
printf("Conjugate of commuted inner product = <%s>\n", Csprint($conj_prod2));
my $prod_diff = $prod1 - $conj_prod2;   # Difference between original product
                                        # and conjugate of cummuted product
my $abs_diff = abs($prod_diff);         # Magnitude of that difference
printf("Difference: original product - conj(cummuted product):\n%s (%9.8f)\n",
       Csprint($prod_diff), $abs_diff);
       
$ok_count++ if ($abs_diff <= $margin);  # Close enough?
is ($ok_count, 1, "Inner product function passes the conjugate test");

done_testing();
exit;
