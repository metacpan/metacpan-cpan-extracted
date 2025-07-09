use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Math::BigInt;
use Config;

print "1..17\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

my $ui = 123569;
my $si = -19907;
my $d = -1.625;
my $str = '-119.125';

my $ok = '';

my $f00 = new Math::MPFR();
if(Rmpfr_nan_p($f00)) {$ok = 'a'}
Rmpfr_set_ui($f00, $ui, Rmpfr_get_default_rounding_mode());
if($f00 == $ui) {$ok .= 'b'}

my $f01 = new Math::MPFR($ui);
if($f01 == $ui) {$ok .= 'c'}

my $f02 = new Math::MPFR($si);
if($f02 == $si) {$ok .= 'd'}

my $f03 = new Math::MPFR($d);
if($f03 == $d) {$ok .= 'e'}

my $f04 = new Math::MPFR($str);
if($f04 == $str) {$ok .= 'f'}

my $f05 = new Math::MPFR($str, 10);
if($f05 == $str) {$ok .= 'g'}

my $f06 = new Math::MPFR($d);
if($f06 == $d) {$ok .= 'h'}

if($ok eq 'abcdefgh') {print "ok 1\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 1\n";
}

#############################


$ok = '';

my $f10 = Math::MPFR::new();
if(Rmpfr_nan_p($f10)) {$ok = 'a'}
Rmpfr_set_ui($f10, $ui, Rmpfr_get_default_rounding_mode());
if($f10 == $ui) {$ok .= 'b'}

my $f11 = Math::MPFR::new($ui);
if($f11 == $ui) {$ok .= 'c'}

my $f12 = Math::MPFR::new($si);
if($f12 == $si) {$ok .= 'd'}

my $f13 = Math::MPFR::new($d);
if($f13 == $d) {$ok .= 'e'}

my $f14 = Math::MPFR::new($str);
if($f14 == $str) {$ok .= 'f'}

my $f15 = Math::MPFR::new($str, 10);
if($f15 == $str) {$ok .= 'g'}

my $f16 = Math::MPFR::new($d);
if($f16 == $d) {$ok .= 'h'}

if($ok eq 'abcdefgh') {print "ok 2\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 2\n";
}

################################

$ok = '';

my $f20 = Math::MPFR->new();
if(Rmpfr_nan_p($f20)) {$ok = 'a'}
else {warn "3a: $f20\n"}

Rmpfr_set_ui($f20, $ui, Rmpfr_get_default_rounding_mode());
if($f20 == $ui) {$ok .= 'b'}
else {warn "3b: $f20\n"}

my $f21 = Math::MPFR->new($ui);
if($f21 == $ui) {$ok .= 'c'}
else {warn "3c: $f21\n"}

my $f22 = Math::MPFR->new($si);
if($f22 == $si) {$ok .= 'd'}
else {warn "3d: $f22\n"}

my $f23 = Math::MPFR->new($d);
if($f23 == $d) {$ok .= 'e'}
else {warn "3e: $f23\n"}

my $f24 = Math::MPFR->new($str);
if($f24 == $str) {$ok .= 'f'}
else {warn "3f: $f24\n"}

my $f25 = Math::MPFR->new($str, 10);
if($f25 == $str) {$ok .= 'g'}
else {warn "3g: $f25\n"}

my $f26 = Math::MPFR->new($d);
if($f26 == $d) {$ok .= 'h'}
else {warn "3h: $f26\n"}

Rmpfr_set_default_prec(100);
my $f27 = Math::MPFR->new(36028797018964023);
my $f28 = Math::MPFR->new('36028797018964023');

if(Math::MPFR::_has_longlong() || $Config{ivsize} >= 8) {
  if($f27 == $f28) {$ok .= 'i'}
  else {warn "== : $f27 $f28\n"}
}
else {
  if(Math::MPFR::_has_longdouble()) {
    if($f27 == $f28) {$ok .= 'i'}
    else {warn "== : $f27 $f28\n"}
  }
  else {
    if($f27 != $f28) {$ok .= 'i'}
    else {warn "!= : $f27 $f28\n"}
  }
}

if($ok eq 'abcdefghi') {print "ok 3\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 3\n";
}

#############################

my $bi = Math::BigInt->new(123456789);

$ok = '';

eval{my $f30 = Math::MPFR->new(17, 12);};
if($@ =~ /Too many arguments supplied to new\(\) \- expected only one/) {$ok = 'a'}

eval{my $f31 = Math::MPFR::new(17, 12);};
if($@ =~ /Too many arguments supplied to new\(\) \- expected only one/) {$ok .= 'b'}

eval{my $f32 = Math::MPFR->new($str, 12, 7);};
if($@ =~ /Too many arguments supplied to new\(\)/) {$ok .= 'c'}

eval{my $f33 = Math::MPFR::new($str, 12, 7);};
if($@ =~ /Too many arguments supplied to new\(\) \- expected no more than two/) {$ok .= 'd'}

eval{my $f34 = Math::MPFR->new($bi);};
if($@ =~ /Inappropriate argument/) {$ok .= 'e'}

eval{my $f35 = Math::MPFR::new($bi);};
if($@ =~ /Inappropriate argument/) {$ok .= 'f'}

eval{my $f36 = Math::MPFR->new("17", 42);};
if($@) { warn "\$\@: $@\n" }
else {$ok .= 'g'}

eval{my $f37 = Math::MPFR->new("17", 1);};
if($@ =~ /2nd argument supplied to Rmpfr_init_set str/) {$ok .= 'h' }

eval{my $f38 = Math::MPFR->new("17", 0);};
if($@) { warn "\$\@: $@\n" }
else {$ok .= 'i' }

eval{my $f39 = Math::MPFR->new("17", -4);};
if($@ =~ /2nd argument supplied to Rmpfr_init_set str/) {$ok .= 'j' }

if($ok eq 'abcdefghij') {print "ok 4\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 4\n";
}

###############################

$ok = '';

my($gmpf, $gmpq, $gmpz, $gmp) = (0, 0, 0, 0);

eval{require Math::GMPf;};
if(!$@) {$gmpf = 1}

eval{require Math::GMPq;};
if(!$@) {$gmpq = 1}

eval{require Math::GMPz;};
if(!$@) {$gmpz = 1}

eval{require Math::GMP;};
if(!$@ && $Math::GMP::VERSION >= 2.25) {$gmp = 1}

if($gmpf) {
  my $x = Math::GMPf::new(125.5);
  my $y = Math::MPFR::new($x);
  my $z = Math::MPFR->new($x);

  if($y == $z && $z == 125.5) {print "ok 5\n"}
  else {
    warn "\$y: $y\n\$z: $z\n";
    print "not ok 5\n";
  }
}
else {
  warn "Skipping test 5 - no Math::GMPf\n";
  print "ok 5\n";
}

if($gmpq) {
  Rmpfr_set_default_prec(53);
  my $x = Math::GMPq::new('251/2');
  my $y = Math::MPFR::new($x);
  my $z = Math::MPFR->new($x);

  if($y == $z && $z == 125.5) {print "ok 6\n"}
  else {
    warn "\$y: $y\n\$z: $z\n";
    print "not ok 6\n";
  }
}
else {
  warn "Skipping test 6 - no Math::GMPq\n";
  print "ok 6\n";
}

if($gmpz) {
  Rmpfr_set_default_prec(53);
  my $x = Math::GMPz::new(125.5);
  my $y = Math::MPFR::new($x);
  my $z = Math::MPFR->new($x);

  if($y == $z && $z == 125) {print "ok 7\n"}
  else {
    warn "\$y: $y\n\$z: $z\n";
    print "not ok 7\n";
  }

  my $mpz = Math::GMPz->new('1' . ('0' x 64), 2);
  my $mpfr_64 = Rmpfr_init2(64);
  $mpfr_64 = Math::MPFR->new(2 ** 64);

  my $mpfr1 = Math::MPFR->new($mpz - 1);

  if(Rmpfr_get_prec($mpfr1) == 53) {
    print "ok 8\n";
  }
  else {
    warn "Expected precision of 53: ", Rmpfr_get_default_prec(), "\n";
    print "not ok 8\n";
  }

  if($mpfr1 == $mpfr_64) { print "ok 9\n" } # $mpfr1 should be rounded up to 0x1p+64
  else { print "not ok 9\n" }

  Rmpfr_set_default_rounding_mode(MPFR_RNDD);
  my $mpfr2 = Math::MPFR->new($mpz - 1); # $mpfr2 should be rounded down to 0x1.fffffffffffffp+63
  Rmpfr_set_default_rounding_mode(MPFR_RNDN);

  if(Rmpfr_get_prec($mpfr2) == 53) {
    print "ok 10\n";
  }
  else {print "not ok 10\n"}

  if($mpfr2 < $mpfr_64) { print "ok 11\n" }
  else {
    print "not ok 11\n";
  }
}
else {
  warn "Skipping tests 7 to 11 - no Math::GMPz\n";
  for(7..11) { print "ok $_\n" }
}

if($gmp) {
  Rmpfr_set_default_prec(53);
  my $x = Math::GMP->new(125);
  my $y = Math::MPFR::new($x);
  my $z = Math::MPFR->new($x);

  if($y == $z && $z == 125) {print "ok 12\n"}
  else {
    warn "\$y: $y\n\$z: $z\n";
    print "not ok 12\n";
  }

  my $mpz = Math::GMP->new(1) << 64;
  my $mpfr_64 = Rmpfr_init2(64);
  $mpfr_64 = Math::MPFR->new(2 ** 64);

  my $mpfr1 = Math::MPFR->new($mpz - 1);

  if(Rmpfr_get_prec($mpfr1) == 53) {
    print "ok 13\n";
  }
  else {
    print "not ok 13\n";
  }

  if($mpfr1 == $mpfr_64) { print "ok 14\n" } # $mpfr1 should be rounded up to 0x1p+64
  else { print "not ok 14\n" }

  Rmpfr_set_default_rounding_mode(MPFR_RNDD);
  my $mpfr2 = Math::MPFR->new($mpz - 1); # $mpfr2 should be rounded down to 0x1.fffffffffffffp+63
  Rmpfr_set_default_rounding_mode(MPFR_RNDN);

  if(Rmpfr_get_prec($mpfr2) == 53) {
    print "ok 15\n";
  }
  else {print "not ok 15\n";
  }

  if($mpfr2 < $mpfr_64) { print "ok 16\n" }
  else {
    print "not ok 16\n" }
}
else {
  warn "Skipping tests 12 to 16 - no Math::GMP or $Math::GMP::VERSION < 2.25\n";
  for(12..16) { print "ok $_\n" }
}

my $x = Math::MPFR::new(12345.5);
my $y = Math::MPFR::new($x);
my $z = Math::MPFR->new($x);

if($y == $z && $z == 12345.5) {print "ok 17\n"}
else {
  warn "\$y: $y\n\$z: $z\n";
  print "not ok 17\n";
}

