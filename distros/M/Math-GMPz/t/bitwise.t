use strict;
use warnings;

BEGIN{
 if($] < 5.022) {
   print "1..1\n";
   warn "\n skipping all tests - 'bitwise' feature not available\n";
   print "ok 1\n";
   exit;
   }
};

use feature 'bitwise';
use Math::GMPz qw(:mpz);
no warnings 'experimental::bitwise';

print "1..6\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $x = Math::GMPz->new(2);
my $y = Math::GMPz->new(3);

if(2 == ($x & $y)) {print "ok 1\n"}
else {print "not ok 1\n"}

if(3 == ($x | $y)) {print "ok 2\n"}
else {print "not ok 2\n"}

if(1 == ($x ^ $y)) {print "ok 3\n"}
else {print "not ok 3\n"}

$x &= 4;
if($x == 0) {print "ok 4\n"}
else {print "not ok 4\n"}

$x |= $y;
if($x == 3) {print "ok 5\n"}
else {print "not ok 5\n"}

$x ^= 2;
if($x == 1) {print "ok 6\n"}
else {print "not ok 6\n"}
