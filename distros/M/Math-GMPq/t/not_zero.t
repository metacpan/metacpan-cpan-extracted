# Just some additional tests to check that ~0, unsigned and signed longs are
# are being handled as expected.

use warnings;
use strict;
use Math::GMPq qw(:mpq);
use Config;

print"1..3\n";

print "# Using gmp version ", Math::GMPq::gmp_v(), "\n";

my $n = ~0;

my $gmpq1 = Math::GMPq::new($n);
my $gmpq2 = Math::GMPq->new($n);
my $gmpq3 = Rmpq_init();
Rmpq_set_ui($gmpq3, $n, 1);
my $gmpq4 = Rmpq_init();
Rmpq_set_si($gmpq4, $n, 1);

if($gmpq4 == -1) {print "ok 1\n"}
else {print "not ok 1\n"}

if($gmpq1 == $n &&
   $gmpq2 == $n ) {print "ok 2\n"}
else {print "not ok 2\n"}

if(Math::GMPq::_has_longlong() &&
   $Config::Config{longsize} == 4) {
   if($gmpq3 != $n) {print "ok 3\n"}
   else {print "not ok 3 A $gmpq3 == $n\n"}
}

else {
  if($n == $gmpq3) {print "ok 3 \n"}
  else {print "not ok 3 B $gmpq3 != $n\n"}
}


