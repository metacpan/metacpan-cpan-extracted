use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..7\n";

my ($have_gmpq, $have_gmpz, $have_gmp) = (0, 0, 0);
my ($mpq, $mpz, $gmp);
my @str = ('1@-1', 10);
my $double = 0.3;;
my $ui = 117;
my $si = -117;
my $mpfr = Math::MPFR->new('0.1');
my $prec = 165;
my $ok = '';
Rmpfi_set_default_prec($prec);

eval{require Math::GMPq;};
unless($@) {
  $have_gmpq = 1;
  $mpq = Math::GMPq->new(-117);
}

eval{require Math::GMPz;};
unless($@) {
  $have_gmpz = 1;
  $mpz = Math::GMPz->new(-117);
}

eval{require Math::GMP;};
unless($@) {
  $have_gmp = 1;
  $gmp = Math::GMP->new(-117);
}

# is_strictly_inside
# is_inside (+ d, ui, si, z, q, fr) op1, op2.
# is_empty op
# intersect, union (rop, op1, op2)

my $mpfi1 = Math::MPFI->new($str[0]);
my $mpfi2 = Math::MPFI->new('0.3');

# Precision of $mpfi3 needs to be less than that of
# C double. Othewrwise the test involving $mpfi3 can
# fail (and rightly so).
my $mpfi3 = Rmpfi_init2(50);
Rmpfi_set_d($mpfi3, $double);

my $mpfiui = Math::MPFI->new(117);
$mpfiui = sqrt($mpfiui);
$mpfiui *= $mpfiui;
my $mpfisi = -($mpfiui);

unless(Rmpfi_is_strictly_inside($mpfi1, $mpfi1)) {$ok .= 'a'}
else {warn "1a: \$mpfi1 is strictly inside \$mpfi1\n"}

if(Rmpfi_is_inside($mpfi1, $mpfi1)) {$ok .= 'b'}
else {warn "1b: \$mpfi1 is not inside \$mpfi1\n"}

unless(Rmpfi_is_inside($mpfi2, $mpfi1)) {$ok .= 'c'}
else {warn "1c: \$mpfi2 is inside \$mpfi1\n"}

unless(Rmpfi_is_inside($mpfi1, $mpfi2)) {$ok .= 'd'}
else {warn "1d: \$mpfi1 is inside \$mpfi2\n"}

unless(Rmpfi_is_strictly_inside($mpfi2, $mpfi1)) {$ok .= 'e'}
else {warn "1e:\$mpfi2 is strictly inside \$mpfi1\n"}

unless(Rmpfi_is_strictly_inside($mpfi1, $mpfi2)) {$ok .= 'f'}
else {warn "1f: \$mpfi1 is strictly inside \$mpfi2\n"}

unless(Rmpfi_is_inside_d($double, $mpfi1)) {$ok .= 'g'}
else {warn "1g: \$double is inside \$mpfi1\n"}

if(Rmpfi_is_inside_d($double, $mpfi3)) {$ok .= 'h'}
else {warn "1h: \$double ($double) is not inside \$mpfi3 ($mpfi3)\n"}

if(Rmpfi_is_inside_ui($ui, $mpfiui)) {$ok .= 'i'}
else {warn "1i: \$ui ($ui) is not inside \$mpfiui ($mpfiui)\n"}

unless(Rmpfi_is_inside_ui($ui, $mpfisi)) {$ok .= 'I'}
else {warn "1I: \$ui ($ui) is inside \$mpfisi ($mpfisi)\n"}

if(Rmpfi_is_inside_si($si, $mpfisi)) {$ok .= 'j'}
else {warn "1j: \$si ($si) is not inside \$mpfisi ($mpfisi)\n"}

unless(Rmpfi_is_inside_si($si, $mpfiui)) {$ok .= 'J'}
else {warn "1J: \$si ($si) is inside \$mpfiui ($mpfiui)\n"}

my $fr = Math::MPFR->new(-117);
if(Rmpfi_is_inside_fr($fr, $mpfisi)) {$ok .= 'k'}
else {warn "1k: \$fr ($fr) is not inside \$mpfisi ($mpfisi)\n"}

unless(Rmpfi_is_inside_fr($fr, $mpfiui)) {$ok .= 'K'}
else {warn "1K: \$fr ($fr) is inside \$mpfiui ($mpfiui)\n"}

if($have_gmp) {
  if(Rmpfi_is_inside_z($gmp, $mpfisi)) {$ok .= 'l'}
  else {warn "1l: \$gmp ($gmp) is not inside \$mpfisi ($mpfisi)\n"}

  unless(Rmpfi_is_inside_z($gmp, $mpfiui)) {$ok .= 'L'}
  else {warn "1L: \$gmp ($gmp) is inside \$mpfiui ($mpfiui)\n"}
}
else {
  warn "Skipping tests 1l & 1L - no Math::GMP\n";
  $ok .= 'lL';
}

if($have_gmpz) {
  if(Rmpfi_is_inside_z($mpz, $mpfisi)) {$ok .= 'm'}
  else {warn "1m: \$mpz ($mpz) is not inside \$mpfisi ($mpfisi)\n"}

  unless(Rmpfi_is_inside_z($mpz, $mpfiui)) {$ok .= 'M'}
  else {warn "1M: \$mpz ($mpz) is  inside \$mpfiui ($mpfiui)\n"}
}
else {
  warn "Skipping tests 1m & 1M - no Math::GMPz\n";
  $ok .= 'mM';
}

if($have_gmpq) {
  if(Rmpfi_is_inside_q($mpq, $mpfisi)) {$ok .= 'n'}
  else {warn "1n: \$mpq ($mpq) is not inside \$mpfisi ($mpfisi)\n"}

  unless(Rmpfi_is_inside_q($mpq, $mpfiui)) {$ok .= 'N'}
  else {warn "1N: \$mpq ($mpq) is inside \$mpfiui ($mpfiui)\n"}
}
else {
  warn "Skipping tests 1n & 1N - no Math::GMPq\n";
  $ok .= 'nN';
}

if($ok eq 'abcdefghiIjJkKlLmMnN') {print "ok 1\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 1\n";
}

my $rop = Math::MPFI->new();
my $rop2 = Math::MPFI->new();

Rmpfi_intersect($rop,$mpfiui,$mpfisi);

if(Rmpfi_is_empty($rop)) {print "ok 2\n"}
else {
  warn "2: $\$rop: $rop\n ... expected \$rop to be empty\n";
  print "not ok 2\n";
}

Rmpfi_intersect($rop,$mpfisi,$mpfiui);

if(Rmpfi_is_empty($rop)) {print "ok 3\n"}
else {
  warn "3: $\$rop: $rop\n ... expected \$rop to be empty\n";
  print "not ok 3\n";
}

Rmpfi_union($rop, $mpfisi, $mpfiui);
Rmpfi_union($rop2, $mpfiui, $mpfisi);

if($rop == $rop2) {print "ok 4\n"}
else {
  warn "4: \$rop: $rop\n\$rop2: $rop2\n";
}

my($out1, $out2) = (Math::MPFI->new(), Math::MPFI->new());

Rmpfi_bisect($out1, $out2, $rop2);
Rmpfi_union($out1, $out1, $out2);
if($out1 == $rop2) {print "ok 5\n"}
else {
  warn "\$out1: $out1\n\$rop2: $rop2\n";
  print "not ok 5\n";
}

Rmpfi_blow($out1, $rop2, 0.0);
if($out1 == $rop2) {print "ok 6\n"}
else {
  warn "\$out1: $out1\n\$rop2: $rop2\n";
  print "not ok 6\n";
}

my $inc = Math::MPFI->new(1);
my $dec = Math::MPFI->new(-1);

$ok = '';

if(Rmpfr_get_default_prec() == Rmpfi_get_prec($rop2)) {$ok .= 'a'}
else {
  warn "Math::MPFR default precision: ", Rmpfr_get_default_prec(), "\n",
       "Precision of \$rop2: ", Rmpfi_get_prec($rop2), "\n";
}

my $fr2 = Math::MPFR->new();

Rmpfi_increase($rop2, $inc);
Rmpfi_get_left($fr, $rop2);
Rmpfi_get_left($fr2, $out1);
if($fr != $fr2) {$ok .= 'b'}
else {
  warn "7b: $fr == $fr2\n";
}

Rmpfi_get_right($fr, $rop2);
Rmpfi_get_right($fr2, $out1);
if($fr != $fr2) {$ok .= 'c'}
else {
  warn "7c: $fr == $fr2\n";
}

Rmpfi_increase($rop2, $dec);
Rmpfi_get_left($fr, $rop2);
Rmpfi_get_left($fr2, $out1);
if($fr == $fr2) {$ok .= 'd'}
else {
  warn "7d: $fr != $fr2\n";
}

Rmpfi_get_right($fr, $rop2);
Rmpfi_get_right($fr2, $out1);
if($fr == $fr2) {$ok .= 'e'}
else {
  warn "7e: $fr != $fr2\n";
}

if($ok eq 'abcde') {print "ok 7\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok\n";
}
