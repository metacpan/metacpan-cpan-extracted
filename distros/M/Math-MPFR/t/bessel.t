use warnings;
use strict;
use Math::MPFR qw(:mpfr);

print "1..1\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

Rmpfr_set_default_prec(100);

my($val, $discard) = Rmpfr_init_set_ui(2934, GMP_RNDN);
my $ret = Rmpfr_init();
my $nan = Rmpfr_init();
my $neg = Math::MPFR->new(-1);
my $zero = Math::MPFR->new(0);
my $inf = Math::MPFR->new();
Rmpfr_set_inf($inf, 1);
my $ok = '';

Rmpfr_j0($ret, $val, GMP_RNDN);
if($ret > 0.007545752435 && $ret < 0.007545752437) {$ok .= 'a'}

Rmpfr_j1($ret, $val, GMP_RNDN);
if($ret > -0.012649475954 && $ret < -0.012649475952) {$ok .= 'b'}

Rmpfr_jn($ret, 200, $val, GMP_RNDN);
if($ret > 0.012963999661 && $ret < 0.012963999663) {$ok .= 'c'}

Rmpfr_y0($ret, $val, GMP_RNDN);
if($ret > -0.012650761686 && $ret < -0.012650761684) {$ok .= 'd'}

Rmpfr_y1($ret, $val, GMP_RNDN);
if($ret > -0.007547908437 && $ret < -0.007547908435) {$ok .= 'e'}

Rmpfr_yn($ret, 200, $val, GMP_RNDN);
if($ret > -0.007029988802 && $ret < -0.0070299888) {$ok .= 'f'}

Rmpfr_j0($ret, $nan, GMP_RNDN);
if(Rmpfr_nan_p($ret)) {$ok .= 'g'}

Rmpfr_j1($ret, $inf, GMP_RNDN);
if(!$ret) {$ok .= 'h'}

Rmpfr_j1($ret, $zero, GMP_RNDN);
if(!$ret) {$ok .= 'i'}

Rmpfr_y1($ret, $nan, GMP_RNDN);
if(Rmpfr_nan_p($ret)) {$ok .= 'j'}

Rmpfr_y0($ret, $neg, GMP_RNDN);
if(Rmpfr_nan_p($ret)) {$ok .= 'k'}

Rmpfr_y0($ret, $inf, GMP_RNDN);
if(!$ret) {$ok .= 'l'}

Rmpfr_y1($ret, $zero, GMP_RNDN);
if(Rmpfr_inf_p($ret)) {$ok .= 'm'}

if($ok eq 'abcdefghijklm') {print "ok 1\n"}
else {print "not ok 1 $ok\n"}
