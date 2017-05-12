# Just some additional tests to check that ~0, unsigned and signed longs are
# are being handled as expected.

use warnings;
use strict;
use Math::GMPf qw(:mpf);
use Config;

print"1..3\n";

print "# Using gmp version ", Math::GMPf::gmp_v(), "\n";

Rmpf_set_default_prec(65);

my $n = ~0;

my $gmpf1 = Math::GMPf::new($n);
my $gmpf2 = Math::GMPf->new($n);
my $gmpf3 = Rmpf_init_set_ui($n);
my $gmpf4 = Rmpf_init_set_si($n);

if($gmpf4 == -1) {print "ok 1\n"}
else {print "not ok 1\n"}

if($gmpf1 == $n &&
   $gmpf2 == $n ) {print "ok 2\n"}
else {print "not ok 2\n"}

if(Math::GMPf::_has_longlong() &&
   $Config::Config{longsize} == 4) {
   if($gmpf3 != $n) {print "ok 3\n"}
   else {print "not ok 3 A $gmpf3 == $n\n"}
}

else {
  if($n == $gmpf3) {print "ok 3 \n"}
  else {print "not ok 3 B $gmpf3 != $n\n"}
}


