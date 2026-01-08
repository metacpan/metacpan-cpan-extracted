use warnings;
use strict;
use Math::GMPq qw(:mpq);

print "1..2\n";

print "# Using gmp version ", Math::GMPq::gmp_v(), "\n";

my $mpq = Math::GMPq->new(~0 * -1);
if($mpq == ~0 * -1) {print "ok 1\n"}
else {print "not ok 1\n$mpq != ", ~0 * -1, "\n"}

if(Math::GMPq::_has_longdouble()) {
  my $ok = '';
  my $mpq1 = Math::GMPq->new((2 ** 59) + 11111);
  $ok .= 'a' if $mpq1 == 576460752303434599;
  $ok .= 'b' if $mpq1 < 576460752303434600;
  $ok .= 'c' if $mpq1 <= 576460752303434600;
  $ok .= 'd' if $mpq1 > 576460752303434598;
  $ok .= 'e' if $mpq1 >= 576460752303434598;
  $ok .= 'f' if ($mpq1 <=> 576460752303434600) == -1;
  $ok .= 'g' if ($mpq1 <=> 576460752303434598) == 1;
  $ok .= 'h' if !($mpq1 <=> 576460752303434599);

  if($ok eq 'abcdefgh') {print "ok 2\n"}
  else {print "not ok 2 $ok\n"}
}

else {
  warn "Skipping test 2 - no long double support\n";
  print "ok 2\n"}
