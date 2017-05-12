use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..4\n";

my $mpfiui = Math::MPFI->new(17);
my $mpfisi = Math::MPFI->new(-23);
my $rop = Math::MPFI->new();
my $mt = 1;
my $fr = Math::MPFR->new();
my $ok;
my($have_gmp, $have_gmpz, $have_gmpq) = (0, 0, 0);

eval {require Math::GMP;};
if(!$@) {$have_gmp = 1}

eval {require Math::GMPz;};
if(!$@) {$have_gmpz = 1}

eval {require Math::GMPq;};
if(!$@) {$have_gmpq = 1}

Rmpfi_intersect($rop, $mpfiui, $mpfisi);

if(Rmpfi_is_empty($rop)) {print "ok 1\n"}
else {
  warn "\$rop is not empty\n";
  $mt = 0;
  print "not ok 1\n";
}

if($mt) {
  my $ret = Rmpfi_revert_if_needed($rop);
  if($ret) {$ok .= 'a'}
  else {warn "1a: Reversion failed\n"}

  Rmpfi_get_left($fr, $rop);
  if($fr == -23) {$ok .= 'b'}
  else {warn "2: Left value: $fr\n"}

  Rmpfi_get_right($fr, $rop);
  if($fr == 17) {$ok .= 'c'}
  else {warn "2: Right value: $fr\n"}

  if($ok eq 'abc') {print "ok 2\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 2\n";
  }
}
else {
  warn "Skipping Test 2 because Test 1 failed\n";
  print "ok 2\n";
}

# $rop is [-23, 17]

$ok = '';

my $op = Math::MPFI->new(0);

Rmpfi_put_ui($op, 50);
Rmpfi_put_si($op, -50);

Rmpfi_get_left($fr, $op);
if($fr == -50) {$ok .= 'a'}
else {warn "3a: \$fr: $fr\n"}

Rmpfi_get_right($fr, $op);
if($fr == 50) {$ok .= 'b'}
else {warn "3b: \$fr: $fr\n"}

Rmpfi_put($rop, $op);

Rmpfi_get_left($fr, $rop);
if($fr == -50) {$ok .= 'c'}
else {warn "3c: \$fr: $fr\n"}

Rmpfi_get_right($fr, $rop);
if($fr == 50) {$ok .= 'd'}
else {warn "3d: \$fr: $fr\n"}

Rmpfi_put_d($rop, -100.25);

Rmpfi_get_left($fr, $rop);
if($fr == -100.25) {$ok .= 'e'}
else {warn "3e: \$fr: $fr\n"}

Rmpfi_get_right($fr, $rop);
if($fr == 50) {$ok .= 'f'}
else {warn "3f: \$fr: $fr\n"}

Rmpfi_put_d($rop, 100.25);

Rmpfi_get_left($fr, $rop);
if($fr == -100.25) {$ok .= 'g'}
else {warn "3g: \$fr: $fr\n"}

Rmpfi_get_right($fr, $rop);
if($fr == 100.25) {$ok .= 'h'}
else {warn "3h: \$fr: $fr\n"}

Rmpfi_put_fr($rop, Math::MPFR->new(-200.75));

Rmpfi_get_left($fr, $rop);
if($fr == -200.75) {$ok .= 'i'}
else {warn "3i: \$fr: $fr\n"}

Rmpfi_get_right($fr, $rop);
if($fr == 100.25) {$ok .= 'j'}
else {warn "3j: \$fr: $fr\n"}

Rmpfi_put_fr($rop, Math::MPFR->new(200.75));

Rmpfi_get_left($fr, $rop);
if($fr == -200.75) {$ok .= 'k'}
else {warn "3k: \$fr: $fr\n"}

Rmpfi_get_right($fr, $rop);
if($fr == 200.75) {$ok .= 'l'}
else {warn "3l: \$fr: $fr\n"}

if($have_gmp) {
  Rmpfi_put_z($rop, Math::GMP->new(-500));

  Rmpfi_get_left($fr, $rop);
  if($fr == -500) {$ok .= 'm'}
  else {warn "3m: \$fr: $fr\n"}

  Rmpfi_get_right($fr, $rop);
  if($fr == 200.75) {$ok .= 'n'}
  else {warn "3n: \$fr: $fr\n"}

  Rmpfi_put_z($rop, Math::GMP->new(500));

  Rmpfi_get_left($fr, $rop);
  if($fr == -500) {$ok .= 'o'}
  else {warn "3o: \$fr: $fr\n"}

  Rmpfi_get_right($fr, $rop);
  if($fr == 500) {$ok .= 'p'}
  else {warn "3p: \$fr: $fr\n"}
}
else {
  warn "Skipping tests 3m, 3n, 3o & 3p - no Math::GMP\n";
  $ok .= 'mnop';
}

if($have_gmpz) {
  Rmpfi_put_z($rop, Math::GMPz->new(-700));

  Rmpfi_get_left($fr, $rop);
  if($fr == -700) {$ok .= 'q'}
  else {warn "3q: \$fr: $fr\n"}

  Rmpfi_put_z($rop, Math::GMPz->new(700));

  Rmpfi_get_right($fr, $rop);
  if($fr == 700) {$ok .= 'r'}
  else {warn "3r: \$fr: $fr\n"}
}
else {
  warn "Skipping tests 3q and 3r - no Math::GMPz\n";
  $ok .= 'qr';
}

if($have_gmpq) {
  Rmpfi_put_q($rop, Math::GMPq->new(-900.25));

  Rmpfi_get_left($fr, $rop);
  if($fr == -900.25) {$ok .= 's'}
  else {warn "3s: \$fr: $fr\n"}

  Rmpfi_put_q($rop, Math::GMPq->new(700.25));

  Rmpfi_get_right($fr, $rop);
  if($fr == 700.25) {$ok .= 't'}
  else {warn "3t: \$fr: $fr\n"}
}
else {
  warn "Skipping tests 3s and 3t - no Math::GMPq\n";
  $ok .= 'st';
}

if($ok eq 'abcdefghijklmnopqrst') {print "ok 3\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 3\n";
}

$ok = '';

Rmpfi_interv_d($rop, -3.25, 15.5);

Rmpfi_get_left($fr, $rop);
if($fr == -3.25) {$ok .= 'a'}
else {warn "4a: \$fr: $fr\n"}

Rmpfi_get_right($fr, $rop);
if($fr == 15.5) {$ok .= 'b'}
else {warn "4b: \$fr: $fr\n"}

Rmpfi_interv_ui($rop, 100, 200);

Rmpfi_get_left($fr, $rop);
if($fr == 100) {$ok .= 'c'}
else {warn "4c: \$fr: $fr\n"}

Rmpfi_get_right($fr, $rop);
if($fr == 200) {$ok .= 'd'}
else {warn "4d: \$fr: $fr\n"}

Rmpfi_interv_si($rop, -100, 300);

Rmpfi_get_left($fr, $rop);
if($fr == -100) {$ok .= 'e'}
else {warn "4e: \$fr: $fr\n"}

Rmpfi_get_right($fr, $rop);
if($fr == 300) {$ok .= 'f'}
else {warn "4f: \$fr: $fr\n"}

Rmpfi_interv_fr($rop, Math::MPFR->new(-500), Math::MPFR->new(500));

Rmpfi_get_left($fr, $rop);
if($fr == -500) {$ok .= 'g'}
else {warn "4g: \$fr: $fr\n"}

Rmpfi_get_right($fr, $rop);
if($fr == 500) {$ok .= 'h'}
else {warn "4h: \$fr: $fr\n"}

if($have_gmp) {
  Rmpfi_interv_z($rop, Math::GMP->new(-600), Math::GMP->new(600));

  Rmpfi_get_left($fr, $rop);
  if($fr == -600) {$ok .= 'i'}
  else {warn "4i: \$fr: $fr\n"}

  Rmpfi_get_right($fr, $rop);
  if($fr == 600) {$ok .= 'j'}
  else {warn "4j: \$fr: $fr\n"}
}
else {
  warn "Skipping tests 4i and 4j - no Math::GMP\n";
  $ok .= 'ij';
}

if($have_gmpz) {
  Rmpfi_interv_z($rop, Math::GMPz->new(-700), Math::GMPz->new(700));

  Rmpfi_get_left($fr, $rop);
  if($fr == -700) {$ok .= 'k'}
  else {warn "4k: \$fr: $fr\n"}

  Rmpfi_get_right($fr, $rop);
  if($fr == 700) {$ok .= 'l'}
  else {warn "4l: \$fr: $fr\n"}
}
else {
  warn "Skipping tests 4k and 4l - no Math::GMPz\n";
  $ok .= 'kl';
}

if($have_gmpq) {
  Rmpfi_interv_q($rop, Math::GMPq->new(-800), Math::GMPq->new(800));

  Rmpfi_get_left($fr, $rop);
  if($fr == -800) {$ok .= 'm'}
  else {warn "4m: \$fr: $fr\n"}

  Rmpfi_get_right($fr, $rop);
  if($fr == 800) {$ok .= 'n'}
  else {warn "4n: \$fr: $fr\n"}
}
else {
  warn "Skipping tests 4m and 4n - no Math::GMPq\n";
  $ok .= 'mn';
}


if($ok eq 'abcdefghijklmn') {print "ok 4\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 4\n";
}








