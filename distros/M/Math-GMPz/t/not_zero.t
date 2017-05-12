# Just some additional tests to check that ~0, unsigned and signed longs are
# are being handled as expected.

use warnings;
use strict;
use Math::GMPz qw(:mpz);
use Config;

print"1..3\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $n = ~0;

my $gmpz1 = Math::GMPz::new($n);
my $gmpz2 = Math::GMPz->new($n);
my $gmpz3 = Rmpz_init();
Rmpz_set_ui($gmpz3, $n);
my $gmpz4 = Rmpz_init();
Rmpz_set_si($gmpz4, $n);

if($gmpz4 == -1) {print "ok 1\n"}
else {print "not ok 1\n"}

if($gmpz1 == $n &&
   $gmpz2 == $n ) {print "ok 2\n"}
else {print "not ok 2\n"}

if(Math::GMPz::_has_longlong() &&
   $Config::Config{longsize} == 4) {
   if($gmpz3 != $n) {print "ok 3\n"}
   else {print "not ok 3 A $gmpz3 == $n\n"}
}

else {
  if($n == $gmpz3) {print "ok 3 \n"}
  else {print "not ok 3 B $gmpz3 != $n\n"}
}



