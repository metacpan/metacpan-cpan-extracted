# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Math-SigDig.t'

#########################

use strict;
use warnings;

use Test::More tests => 14;
BEGIN { use_ok('Math::SigDig') };  #This is test 1

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;

#Print the number of tests in a format that Module::Build understands

#Initialize vars needed by Math::SigDig
my $x = 0;
my $y = 0;

#Keep track of how many tests failed
my $num_failed = 0;

#use the module I want to test
use Math::SigDig;

##
## Test 2
##

$x = sigdig(12.3456789);

ok(($x eq '12.3'),
   'sigdig() works using default of 3');
 
##
## Test 3
##

$x = sigdig(12.3456789,4);

ok(($x eq '12.35'),
   'sigdig() works when rounding and using a custom number of significant digits');

##
## Test 4
##

$x = sigdig("-12.345e-6789",2);

ok(($x eq '-12e-6789'),
   'sigdig() works with exponents and signs');

##
## Test 5
##

$x = sigdig(12.00456789,4);

ok(($x eq '12'),
   'sigdig() works trimming trailing zeros');

##
## Test 6
##

$x = sigdig(12.00456789,4,1);

ok(($x eq '12.00'),
   'sigdig() works when keeping trailing zeros');

##
## Test 7
##

$x = sigdig(12.00456789,0,4);
$y = sigdig(12,0,4);

ok(($x eq '12.00456789' && $y eq '12.00'),
   'sigdig() works in fill/no-chop mode');

##
## Test 8
##

$x = getsigdig(12.3456789);

ok(($x == 9),
   'getsigdig() works on decimal values');

##
## Test 9
##

$x = getsigdig("+12.3456789e+123");

ok(($x == 9),
   'getsigdig() works on exponents & signs');

##
## Test 10
##

$x = getsigdig("0001000.000");

ok(($x == 7),
   'getsigdig() works on leading zeros');

##
## Test 11
##

$x = getsigdig(1000,1);

ok(($x == 1),
   'getsigdig() works on excluded trailing whole-number zeros');

##
## Test 12
##

$x = getsigdig("1000.000",1);

ok(($x == 7),
   'getsigdig() works on included trailing decimal zeros');

##
## Test 13
##

$x = getsigdig("1000.000",0,1);

ok(($x == 1),
   'getsigdig() works on excluded trailing decimal zeros');

##
## Test 14
##

$x = 12.3456789;
$y = 12.34;
my $nx = getsigdig($x);
my $ny = getsigdig($y);
my $z = sigdig($x * $y,
               ($nx<$ny ? $nx : $ny));

ok(($z eq '152.3'),
   'sigdig and getsigdig() work in a math example');

