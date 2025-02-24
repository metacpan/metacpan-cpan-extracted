use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Test::More;

my $check = Math::MPFR->new();
my $rop = Math::MPFR->new();

for my $num('1234.7', '-1234.7', ~0, ~0 * -1) {
  for my $div('18.8', '-18.8') {
    $check = Math::MPFR->new($num) % Math::MPFR->new($div);
    Rmpfr_fmod($rop, Math::MPFR->new($num), Math::MPFR->new($div), MPFR_RNDN);
    cmp_ok($check, '==', $rop, "$num % $div ok");
  }
}

my $nan = Math::MPFR->new();
my $ninf = Math::MPFR->new();
Rmpfr_set_inf($ninf, -1);
my $pinf = -$ninf;

$check = $nan % $nan;
Rmpfr_fmod($rop, $nan, $nan, MPFR_RNDN);
my $ok = 0;
$ok = 1 if Rmpfr_nan_p($check) && Rmpfr_nan_p($rop);
cmp_ok($ok, '==', 1, "NaN % NaN is NaN");

$check = $nan % 0;
Rmpfr_fmod($rop, $nan, Math::MPFR->new(0), MPFR_RNDN);
$ok = 0;
$ok = 1 if Rmpfr_nan_p($check) && Rmpfr_nan_p($rop);
cmp_ok($ok, '==', 1, "NaN % 0 is NaN");

$check = 1234 % $nan;
Rmpfr_fmod($rop, Math::MPFR->new(1234), $nan, MPFR_RNDN);
$ok = 0;
$ok = 1 if Rmpfr_nan_p($check) && Rmpfr_nan_p($rop);
cmp_ok($ok, '==', 1, "1234 % NaN is NaN");

$check = Math::MPFR->new(1234) % 0;
Rmpfr_fmod($rop, Math::MPFR->new(1234), $nan, MPFR_RNDN);
$ok = 0;
$ok = 1 if Rmpfr_nan_p($check) && Rmpfr_nan_p($rop);
cmp_ok($ok, '==', 1, "1234 % 0 is NaN");

$check = $pinf % $pinf;
Rmpfr_fmod($rop, $pinf, $pinf, MPFR_RNDN);
$ok = 0;
$ok = 1 if Rmpfr_nan_p($check) && Rmpfr_nan_p($rop);
cmp_ok($ok, '==', 1, "Inf % Inf is NaN");

$check = $pinf % 0;
Rmpfr_fmod($rop, $pinf, Math::MPFR->new(0), MPFR_RNDN);
$ok = 0;
$ok = 1 if Rmpfr_nan_p($check) && Rmpfr_nan_p($rop);
cmp_ok($ok, '==', 1, "Inf % 0 is NaN");

$check = 1234.5 % $pinf;
Rmpfr_fmod($rop, Math::MPFR->new(1234.5), $pinf, MPFR_RNDN);
cmp_ok($check, '==', $rop, "1234.5 % Inf is $rop");

$check = $ninf % $ninf;
Rmpfr_fmod($rop, $ninf, $ninf, MPFR_RNDN);
$ok = 0;
$ok = 1 if Rmpfr_nan_p($check) && Rmpfr_nan_p($rop);
cmp_ok($ok, '==', 1, "-Inf % -Inf is NaN");

$check = $ninf % 0;
Rmpfr_fmod($rop, $ninf, Math::MPFR->new(0), MPFR_RNDN);
$ok = 0;
$ok = 1 if Rmpfr_nan_p($check) && Rmpfr_nan_p($rop);
cmp_ok($ok, '==', 1, "-Inf % 0 is NaN");

$check = 1234.5 % $ninf;
Rmpfr_fmod($rop, Math::MPFR->new(1234.5), $ninf, MPFR_RNDN);
cmp_ok($check, '==', $rop, "1234.5 % -Inf is $rop");

eval { require Math::GMPz; };
if(!$@) {
  if($Math::GMPz::VERSION >= 0.63) {
    for(1 .. 100) {
      my($x, $y) = ( int(rand(3000)) + 1000, int(rand(2000)));
      my $f1 = Math::MPFR->new($x);
      my $f2 = Math::MPFR->new($y);
      my $z1 = Math::GMPz->new($y);
      my $z2 = Math::GMPz->new($x);

      if(Rmpfr_nan_p($f1 % $z1) && Rmpfr_nan_p($z2 % $f2)) {
        cmp_ok(1, '==', 1, "X % Y is not dependent on type")
      }
      else {
        cmp_ok( $f1 % $z1, '==', $z2 % $f2, "X % Y is not dependent on type");
      }
      cmp_ok(ref($f1 % $z1), 'eq', 'Math::MPFR', "'%' returns Math::MPFR object");
      cmp_ok(ref($f1 % $z1), 'eq', ref($z2 % $f2), "X % Y always returns Math::MPFR object");

      $z1 %= $f1;
      $f2 %= $z2;

      cmp_ok( $z1, '==', $f2, "X %= Y is not dependent on type");
      cmp_ok(ref($z1), 'eq', 'Math::MPFR', "'%=' returns Math::MPFR object");
      cmp_ok(ref($z1), 'eq', ref($f2), "X %= Y always returns Math::MPFR object");

    }
  }
  else { warn "Skipping Math::GMPz tests - Math-GMPz-0.63 or later is require; have only $Math::GMPz::VERSION" }
}
else { warn "Skipping Math::GMPz tests - couldn't load Math::GMPz" }

eval { require Math::GMPq; };
if(!$@) {
  if($Math::GMPq::VERSION >= 0.58) {
    my $q = Math::GMPq->new('23/2');
    my $f = Math::MPFR->new('201.5');
    my $alt = Math::MPFR->new('201.5');

    cmp_ok(ref($f % $q), 'eq', 'Math::MPFR', "'%' returned a Math::MPFR object, as expected");
    cmp_ok($f % $q, '==', 6, "201.5 % (23/2) returns 6");

    $alt %= $q;

    cmp_ok(ref($alt), 'eq', 'Math::MPFR', "'%=' returned a Math::MPFR object, as expected");
    cmp_ok($alt, '==', 6, "201.5 %= (23/2) returns 6");


    $q *= 100.5; # 4623/4 == 1155.75
    cmp_ok($q, '==', 1155.75, "value of Math::GMPq object is 1155.75 (4623/4)");
    my $f_mod =  $q % $f;
    cmp_ok(ref($f_mod), 'eq', 'Math::MPFR', "'%' (switched) : returns Math::MPFR object");
    cmp_ok($f_mod, '==', 148.25, "'%' (switched) : returns correct value (148.25)");

    $q %= $f;

    cmp_ok(ref($q), 'eq', 'Math::MPFR', "'%=' (switched) : returns Math::MPFR object");
    cmp_ok($q, '==', 148.25, "'%=' (switched) : returns correct value (148.25)");

  }
  else { warn "Skipping Math::GMPzqtests - Math-GMPq-0.58 or later is require; have only $Math::GMPq::VERSION" }
}
else { warn "Skipping Math::GMPq tests - couldn't load Math::GMPq" }


done_testing();
