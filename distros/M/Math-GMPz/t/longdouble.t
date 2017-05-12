use warnings;
use strict;
use Math::GMPz qw(:mpz);

print "1..2\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $mpz = Math::GMPz->new(~0 * -1);
if($mpz == ~0 * -1) {print "ok 1\n"}
else {print "not ok 1\n$mpz != ", ~0 * -1, "\n"}

if(Math::GMPz::_has_longdouble()) {
  my $ok = '';
  my $mpz1 = Math::GMPz->new((2 ** 59) + 11111);
  $ok .= 'a' if $mpz1 == 576460752303434599;
  $ok .= 'b' if $mpz1 < 576460752303434600;
  $ok .= 'c' if $mpz1 <= 576460752303434600;
  $ok .= 'd' if $mpz1 > 576460752303434598;
  $ok .= 'e' if $mpz1 >= 576460752303434598;
  $ok .= 'f' if ($mpz1 <=> 576460752303434600) < 0;
  $ok .= 'g' if ($mpz1 <=> 576460752303434598) > 0;
  $ok .= 'h' if !($mpz1 <=> 576460752303434599);

  if($ok eq 'abcdefgh') {print "ok 2\n"}
  else {print "not ok 2 $ok\n"}
}
else {
  warn "Skipping test 2 - no long double support\n";
  print "ok 2\n";
}
