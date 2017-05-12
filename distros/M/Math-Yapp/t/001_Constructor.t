#!/bin/perl.exe -w
# 001_Constructor.t:    Test the Math::Yapp constructor in various forms.
#                       Also serves as a test for the Ysprint() formatting
#                       function.
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

Yapp_testmode(0);
my $margin = 1.0 / (10**10);    # When I consider results to be close enough

my @y_list1 = (1, -2, 3, 0, 5, -6, 7, 0, 0);    # 6th degree poly
my $out_yapp1 = "7.00X^6 -6.00X^5 +5.00X^4 +3.00X^2 -2.00X +1.00";
                                                # Expected output

my @y_list2 = (-2, 3, -4, 5);                   # 3rd degree 
my @c_list1 = (cplx(2,3), 1, -2, cplx(3,0), -4, 5); # Complicate it a bit
my $s_list1 = "3X^4 -3 + 2X^4 + (1-2i)X^3 - X +3x^2";   # Mixed up

# First, diddle with the decimal point setting
#
#Math::Yapp->dec_places(2);              # Set to 2
#my $places = Math::Yapp->dec_places();  # Did it stay 2?
Yapp_decimals(2);               # Set to 2
my $places = Yapp_decimals();   # Did it stay 2?
is($places, 2, "Check setting of decimal places (==2)");

# Test constructor from an array
#
my $poly1 = Yapp(@y_list1);
my $outp1 = $poly1->Ysprint();
print "List: ( @y_list1 ) Produces:\n";
printf("<%s>\n", $outp1);
is($outp1, $out_yapp1, "Construct from array");
is($poly1->degree(), 6, "Correct degree setting (==6)");

# Test constructor from an array reference
#
my $poly1a = Yapp(\@y_list1);
my $outp1a = $poly1a->Ysprint();
is($outp1a, $outp1, "Construct from array reference");

# Test explicit copy constructor
#
my $poly1b = Yapp($poly1);
my $outp1b = $poly1b->Ysprint();
#ok($poly1b != $poly1, "Yapp really copied, not just a new reference");
is($outp1b, $outp1, "Explicit copy constructor");

# Test constructor with complex terms in the list
#
my $cpoly1 = Yapp(\@c_list1);
my $coutp1 = $cpoly1->Ysprint();
my $expected_coutp1
    = "5.00X^5 -4.00X^4 +3.00X^3 -2.00X^2 +1.00X +(2.00+3.00i)";
is($coutp1, $expected_coutp1,
   "Constructor from list with complex numbers");

print "End of constructor tests\n";
done_testing();
exit;
