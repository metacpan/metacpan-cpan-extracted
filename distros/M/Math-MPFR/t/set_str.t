use strict;
use warnings;
use Math::MPFR qw(:mpfr);

print "1..15\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

my $hex = '0xabcde';
my $dec = 703710;
my $dec_str = '703710';
my $bin = '0b10101011110011011110';

my ($pest, $b_hex, $b_bin, $b_dec, $b_dec2, $b_hex2, $b_bin2, $two,
    $rev, $z);

($b_hex, $pest) = Rmpfr_init_set_str($hex, 0, GMP_RNDN);
if($b_hex == $hex && $b_hex == $dec && $b_hex == '703710') {print "ok 1\n"}
else {print "not ok 1\n"}

($b_bin, $pest) = Rmpfr_init_set_str($bin, 0, GMP_RNDN);
if($b_bin == $bin && $b_bin == $dec && $b_bin == '703710') {print "ok 2\n"}
else {print "not ok 2\n"}

$b_hex2 = Rmpfr_init();
$b_bin2 = Rmpfr_init();
$b_dec2 = Rmpfr_init();

Rmpfr_set_str($b_hex2, $hex, 0, GMP_RNDN);
if($b_hex2 == $hex && $b_hex2 == $dec && $b_hex2 == '703710') {print "ok 3\n"}
else {print "not ok 3\n"}

Rmpfr_set_str($b_bin2, $bin, 0, GMP_RNDN);
if($b_bin2 == $bin && $b_bin2 == $dec && $b_bin2 == '703710') {print "ok 4\n"}
else {print "not ok 4\n"}

($b_dec, $pest) = Rmpfr_init_set_str($dec_str, 0, GMP_RNDN);
if($b_dec == $hex && $b_dec == $dec && $b_dec == '703710') {print "ok 5\n"}
else {print "not ok 5\n"}

Rmpfr_set_str($b_dec2, $dec_str, 0, GMP_RNDN);
if($b_dec2 == $bin && $b_dec2 == $dec && $b_dec2 == '703710') {print "ok 6\n"}
else {print "not ok 6\n"}

($two, $pest) = Rmpfr_init_set_str('2', 0, GMP_RNDN);

my $ok = '';

$two = $two * $hex;
if($two == 1407420) {$ok = 'a'}

$two = $two / $hex;
if($two == 2) {$ok .= 'b'}

$two = $two + $bin;
if($two == $dec + 2) {$ok .= 'c'}

$two = $two - $bin;
if($two == 2) {$ok .= 'd'}

$rev = $hex * $two;
if($rev == 1407420) {$ok .= 'e'}

$rev = $hex / $two;
if($rev == 351855) {$ok .= 'f'}

$rev = $bin + $two;
if($rev == $dec + 2) {$ok .= 'g'}

$rev = $bin - $two;
if($rev == 703708) {$ok .= 'h'}

if($ok eq 'abcdefgh') {print "ok 7\n"}
else {print "not ok 7 $ok\n"}

$ok = '';

$two *= $hex;
if($two == 1407420) {$ok = 'a'}

$two /= $hex;
if($two == 2) {$ok .= 'b'}

$two += $bin;
if($two == $dec + 2) {$ok .= 'c'}

$two -= $bin;
if($two == 2) {$ok .= 'd'}

if($two < '0b11') {$ok .= 'e'}
if($two > '0x1') {$ok .= 'f'}
if($two <= '0b10') {$ok .= 'g'}
if($two >= '0x2') {$ok .= 'h'}
if($two != '0b11111') {$ok .= 'i'}
if(!($two <=> '0x2')) {$ok .= 'j'}


if($ok eq 'abcdefghij') {print "ok 8\n"}
else {print "not ok 8 $ok\n"}

$rev = $two ** '0b11';
if($rev == '0b1000') {print "ok 9\n"}
else {print "not ok 9 $rev\n"}

$two **= '0x3';
if($two == 8) {print "ok 10\n"}
else {print "not ok 10 $two\n"}

$two **= 2;
$two **= '0b1.0e-1'; # Take square root
if($two == 8) {print "ok 11\n"}
else {print "not ok 11\n"}

Rmpfr_set_str($b_hex, '.12345@-11', 10, GMP_RNDN);
Rmpfr_set_str($b_bin, ".12345\@-11", 0, GMP_RNDN);
if($b_hex == $b_bin) {print "ok 12\n"}
else {print "not ok 12\n"}

Rmpfr_set_str($two, '2', 0, GMP_RNDN);

$rev = '0b1e-1' ** $two;
if($rev == '0.25') {print "ok 13\n"}
else {print "not ok 13\n"}

Rmpfr_set_default_prec(300);

$z = Rmpfr_init();
my $bigstr = '0b'. ('1' x 250);

Rmpfr_set_str($z, $bigstr, 0, GMP_RNDN);

if($z == $bigstr) {print "ok 14\n"}
else {print "not ok 14\n"}

$ok = '';

my $ret = Rmpfr_strtofr($z, '11111111111.11111111111111', 0, GMP_RNDD);
if($ret == -1) {$ok = 'a'}

$ret = Rmpfr_strtofr($z, '11111111111.11111111111111', 0, GMP_RNDU);
if($ret == 1) {$ok .= 'b'}

$ret = Rmpfr_strtofr($z, '-11111111111.11111111111111', 0, GMP_RNDZ);
if($ret == 1) {$ok .= 'c'}

$ret = Rmpfr_strtofr($z, '11111111111.11111111111111', 0, GMP_RNDZ);
if($ret == -1) {$ok .= 'd'}

$ret = Rmpfr_strtofr($z, '-11111111111.5s11111111111111', 0, GMP_RNDD);
if(!$ret) {$ok .= 'e'}

$ret = Rmpfr_strtofr($z, '-11111111111.5s11111111111111', 0, GMP_RNDU);
if(!$ret) {$ok .= 'f'}

$ret = Rmpfr_strtofr($z, 'm11111111111.5s11111111111111', 0, GMP_RNDD);
if(!$z) {$ok .= 'g'}

$ret = Rmpfr_strtofr($z, 'm11111111111.5s11111111111111', 0, GMP_RNDU);
if(!$z) {$ok .= 'h'}

eval {$ret = Rmpfr_strtofr($z, '11111111111.11111111111111', 60, GMP_RNDD);};

if(MPFR_VERSION_MAJOR >= 3) {
   unless($@) {$ok .= 'i'}
   else {warn "15i: \$\@: $@\n"}
}
else {
  if($@ =~ /3rd argument supplied to Rmpfr_strtofr/) {$ok .= 'i'}
  else {warn "15i: \$\@: $@\n"}
}

if($ok eq 'abcdefghi') {print "ok 15\n"}
else {print "not ok 15 $ok\n"}

