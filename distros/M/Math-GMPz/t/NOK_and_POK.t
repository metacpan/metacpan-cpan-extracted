# For Math::GMPz we don't track POK/NOK dualvars.

use strict;
use warnings;
use Math::GMPz;
use Config;

use Test::More;



my $n = '98765' x 80;
my $r = '98765' x 80;
my $z;

if($n > 0) { # sets NV slot to inf, and turns on the NOK flag
  $z = Math::GMPz->new($n);
}

cmp_ok(Math::GMPz::_itsa($n), '==', 4,  "new() uses value in PV slot");
cmp_ok($z,                    '==', $n, "overload_equiv() uses value in PV slot");


my ($nv, $iv, $s);

if(66 > (6.6 / 10) * 100) {   # NV is double precision or IEEE 754 long double
                              # or __float128 or IBM doubledouble
  $nv = (6.6 / 10) * 100;
  $iv = 65;
  $s  = "$nv";
}
elsif(46 > (4.6 / 10) * 100) {  # NV is 10-byte extended precision long double
  $nv =   (4.6 /10) * 100;
  $iv =   45;
  $s  =   "$nv";
}
else {
  warn "\nweird perl encountered - skipping some tests\n";
}

if($iv) {
  cmp_ok(Math::GMPz::_itsa($nv),    '==', 3,       "new() uses value in NV slot");
  cmp_ok(Math::GMPz->new(1) * $nv,  '==', $iv,     "overload_mul() uses value in NV slot");
  cmp_ok(Math::GMPz->new(1) + $nv,  '==', $iv + 1, "overload_add() uses value in NV slot");
  cmp_ok(Math::GMPz->new(1) - $nv,  '==', 1 - $iv, "overload_sub() uses value in NV slot");
  cmp_ok($nv / Math::GMPz->new(1),  '==', $iv,     "overload_div() uses value in NV slot");
}

done_testing();
