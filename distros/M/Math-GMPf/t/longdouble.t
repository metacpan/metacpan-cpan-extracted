use warnings;
use strict;
use Math::GMPf qw(:mpf);

print "1..2\n";

print "# Using gmp version ", Math::GMPf::gmp_v(), "\n";

my $mpf = Math::GMPf->new(~0 * -1);
if($mpf == ~0 * -1) {print "ok 1\n"}
else {print "not ok 1\n$mpf != ", ~0 * -1, "\n"}

if(Math::GMPf::_has_longdouble()) {
  my $ok = '';
  my $mpf1 = Math::GMPf->new((2 ** 59) + 11111);
  $ok .= 'a' if $mpf1 == 576460752303434599;
  $ok .= 'b' if $mpf1 < 576460752303434600;
  $ok .= 'c' if $mpf1 <= 576460752303434600;
  $ok .= 'd' if $mpf1 > 576460752303434598;
  $ok .= 'e' if $mpf1 >= 576460752303434598;
  $ok .= 'f' if ($mpf1 <=> 576460752303434600) < 0;
  $ok .= 'g' if ($mpf1 <=> 576460752303434598) > 0;
  $ok .= 'h' if !($mpf1 <=> 576460752303434599);

  if($ok eq 'abcdefgh') {print "ok 2\n"}
  else {print "not ok 2 $ok\n"}
}
else {
  warn "Skipping test 2 - no long double support\n";
  print "ok 2\n";
}
