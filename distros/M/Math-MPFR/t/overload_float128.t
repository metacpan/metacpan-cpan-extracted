use strict;
use warnings;
use Config;
use Math::MPFR qw(:mpfr);

if(!Math::MPFR::_can_pass_float128()) {
  print "1..1\n";
  warn "\n Skipping all tests - can't pass __float128 type\n";
  print "ok 1\n";
  exit 0;
}

if($Config{nvtype} ne '__float128') {
  print "1..1\n";
  warn "\n What the ... ?? This shouldn't be possible\n";
  print "not ok 1\n";
  exit 0;
}

my $t = 1;

print "1..$t\n";

Rmpfr_set_default_prec(113);

my $ok = '';
my $rop = Math::MPFR->new(2.13);

if($rop == 2.13) {$ok .= 'a'}
else {warn "\n Expected:2.13 Got $rop\n"}

$rop = Math::MPFR->new(1.0);
$rop += 2.13;

if($rop == 3.13) {$ok .= 'b'}
else {warn "\n Expected:3.13 Got $rop\n"}

$rop -= 2.13;

if($rop == 1.0) {$ok .= 'c'}
else {warn "\n Expected:1.0 Got $rop\n"}

$rop *= 2.13;

if($rop == 2.13) {$ok .= 'd'}
else {warn "\n Expected:2.13 Got $rop\n"}

$rop /= 2.13;

if($rop == 1.0) {$ok .= 'e'}
else {warn "\n Expected:1.0 Got $rop\n"}

my $rop1 = $rop + 1.13;

if($rop1 == 2.13) {$ok .= 'f'}
else {warn "\n Expected:2.13 Got $rop1\n"}

$rop1 = $rop - 2.13;
if($rop1 == -1.13) {$ok .= 'g'}
else {warn "\n Expected:-0.13 Got $rop1\n"}

$rop1 = $rop * 2.13;

if($rop1 == 2.13) {$ok .= 'h'}
else {warn "\n Expected:2.13 Got $rop1\n"}

$rop += 1.13;
if($rop == 2.13) {$ok .= 'i'}
else {warn "\n Expected:2.13 Got $rop\n"}

$rop1 = $rop / 2.13;

if($rop1 == 1.0) {$ok .= 'j'}
else {warn "\n Expected:1.0 Got $rop1\n"}

$rop1 = 2.13 / $rop;

if($rop1 == 1.0) {$ok .= 'k'}
else {warn "\n Expected:1.0 Got $rop1\n"}

$rop1 = 3.13 - $rop;

if($rop1 == 1.0) {$ok .= 'l'}
else {warn "\n Expected:1.0 Got $rop1\n"}

if(!($rop <=> 2.13)) {$ok .= 'm'}
else {warn "\n Expected:2.13 Got $rop\n"}

if($rop != 2.14) {$ok .= 'n'}
else {warn "\n Expected:2.13 Got $rop\n"}

if($rop <= 2.14) {$ok .= 'o'}
else {warn "\n Expected:2.13 Got $rop\n"}

if($rop <= 2.13) {$ok .= 'p'}
else {warn "\n Expected:2.13 Got $rop\n"}

if($rop < 2.14) {$ok .= 'q'}
else {warn "\n Expected:2.13 Got $rop\n"}

if($rop > 2.12) {$ok .= 'r'}
else {warn "\n Expected:2.13 Got $rop\n"}

if($rop >= 2.12) {$ok .= 's'}
else {warn "\n Expected:2.13 Got $rop\n"}

if($rop >= 2.13) {$ok .= 't'}
else {warn "\n Expected:2.13 Got $rop\n"}

if($rop ** 2.13 == 2.13 ** $rop) {$ok .= 'u'}
else {warn $rop ** 2.13, " != ", 2.13 ** $rop, "\n"}

$rop1 = $rop;

$rop1 **= 2.13;

if($rop1 == 2.13 ** $rop) {$ok .= 'v'}
else {warn $rop ** 2.13, " != ", 2.13 ** $rop, "\n"}

if($ok eq 'abcdefghijklmnopqrstuv') {print "ok 1\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 1\n";
}




