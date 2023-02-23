use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use Math::BigInt; # for test 11
use warnings;
use strict;

print "1..12\n";

my ($have_gmpq, $have_gmpz, $have_gmp, $have_gmpf) = (0, 0, 0, 0);
my ($mpq, $mpz, $gmp);
my @str = ('1@-1', 10);
my $double = 0.1;
my $ui = ~0;
my $si = (($ui - 1) / 2) * -1;
my $mpfr = Math::MPFR->new('12347.1');
my $prec = 165;
my $ok = '';
my $dis;
Rmpfi_set_default_prec($prec);

eval{require Math::GMPq;};
unless($@) {$have_gmpq = 1}

eval{require Math::GMPz;};
unless($@) {$have_gmpz = 1}

eval{require Math::GMP;};
unless($@) {$have_gmp = 1}

eval{require Math::GMPf;};
unless($@) {$have_gmpf = 1}

################################### TEST 1

my $mpfi1 = Rmpfi_init();
my $mpfi2 = Math::MPFI->new();

unless($mpfi1 == $mpfi2) {$ok .= 'a'}
else {warn "Equivalence: ", $mpfi1 == $mpfi2, "\n"}

if($mpfi1 != $mpfi2) {$ok .= 'b'}
else {warn "Non-equivalence: ", $mpfi1 != $mpfi2, "\n"}

my $cmp = Rmpfi_cmp($mpfi1, $mpfi2);

if($cmp == 1) {$ok .= 'c'}
else {warn "\$cmp, expected to be \"1\"\nGot: $cmp\n"}

$cmp = Rmpfi_cmp($mpfi2, $mpfi1);

if($cmp == 1) {$ok .= 'd'}
else {warn "\$cmp, expected to be \"1\"\nGot: $cmp\n"}

my $p = Rmpfi_get_prec($mpfi1);
if($p == $prec) {$ok .= 'e'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

$p = Rmpfi_get_prec($mpfi2);
if($p == $prec) {$ok .= 'f'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

if($ok eq 'abcdef') {print "ok 1\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 1\n";
}

################################### TEST 2

undef($mpfi1);
undef($mpfi2);
$ok = '';

($mpfi1, $dis) = Rmpfi_init_set_str(@str);
$mpfi2 = Math::MPFI->new(@str);

unless($mpfi1 != $mpfi2) {$ok .= 'a'}
else {warn "Non-equivalence: ", $mpfi1 != $mpfi2, "\n"}

if($mpfi1 == $mpfi2) {$ok .= 'b'}
else {warn "Equivalence: ", $mpfi1 == $mpfi2, "\n"}

unless($mpfi1 != $str[0]) {$ok .= 'c'}
else {warn "Non-equivalence: ", $mpfi1 != $str[0], "\n"}

if($mpfi1 == $str[0]) {$ok .= 'd'}
else {warn "Equivalence: ", $mpfi1 == $str[0], "\n"}

$p = Rmpfi_get_prec($mpfi1);
if($p == $prec) {$ok .= 'e'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

$p = Rmpfi_get_prec($mpfi2);
if($p == $prec) {$ok .= 'f'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

if($ok eq 'abcdef') {print "ok 2\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 2\n";
}

################################### TEST 3

undef($mpfi1);
undef($mpfi2);
$ok = '';
if($have_gmpq) {
  $mpq = Math::GMPq->new('1/10');
  ($mpfi1, $dis) = Rmpfi_init_set_q($mpq);
  $mpfi2 = Math::MPFI->new($mpq);

  unless($mpfi1 != $mpfi2) {$ok .= 'a'}
  else {warn "Non-equivalence: ", $mpfi1 != $mpfi2, "\n"}

  if($mpfi1 == $mpfi2) {$ok .= 'b'}
  else {warn "Equivalence: ", $mpfi1 == $mpfi2, "\n"}

$p = Rmpfi_get_prec($mpfi1);
if($p == $prec) {$ok .= 'c'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

$p = Rmpfi_get_prec($mpfi2);
if($p == $prec) {$ok .= 'd'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

  if($ok eq 'abcd') {print "ok 3\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 3\n";
  }
}
else {
  warn "Skipping test 3 - no Math::GMPq\n";
  print "ok 3\n";
}

################################### TEST 4

undef($mpfi1);
undef($mpfi2);
$ok = '';
if($have_gmpz) {
  $mpz = Math::GMPz->new(12345);
  ($mpfi1, $dis) = Rmpfi_init_set_z($mpz);
  $mpfi2 = Math::MPFI->new($mpz);

  unless($mpfi1 != $mpfi2) {$ok .= 'a'}
  else {warn "Non-equivalence: ", $mpfi1 != $mpfi2, "\n"}

  if($mpfi1 == $mpfi2) {$ok .= 'b'}
  else {warn "Equivalence: ", $mpfi1 == $mpfi2, "\n"}

$p = Rmpfi_get_prec($mpfi1);
if($p == $prec) {$ok .= 'c'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

$p = Rmpfi_get_prec($mpfi2);
if($p == $prec) {$ok .= 'd'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

  if($ok eq 'abcd') {print "ok 4\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 4\n";
  }
}
else {
  warn "Skipping test 4 - no Math::GMPz\n";
  print "ok 4\n";
}

################################### TEST 5

undef($mpfi1);
undef($mpfi2);
$ok = '';
if($have_gmp) {
  $gmp = Math::GMP->new(12346);
  ($mpfi1, $dis) = Rmpfi_init_set_z($gmp);
  $mpfi2 = Math::MPFI->new($gmp);

  unless($mpfi1 != $mpfi2) {$ok .= 'a'}
  else {warn "Non-equivalence: ", $mpfi1 != $mpfi2, "\n"}

  if($mpfi1 == $mpfi2) {$ok .= 'b'}
  else {warn "Equivalence: ", $mpfi1 == $mpfi2, "\n"}

  $p = Rmpfi_get_prec($mpfi1);
  if($p == $prec) {$ok .= 'c'}
  else {warn "Precision expected to be $prec\nGot: $p\n"}

  $p = Rmpfi_get_prec($mpfi2);
  if($p == $prec) {$ok .= 'd'}
  else {warn "Precision expected to be $prec\nGot: $p\n"}

  if($ok eq 'abcd') {print "ok 5\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 5\n";
  }
}
else {
  warn "Skipping test 5 - no Math::GMP\n";
  print "ok 5\n";
}

################################### TEST 6

undef($mpfi1);
undef($mpfi2);
$ok = '';

($mpfi1, $dis) = Rmpfi_init_set_fr($mpfr);
$mpfi2 = Math::MPFI->new($mpfr);

unless($mpfi1 != $mpfi2) {$ok .= 'a'}
else {warn "Non-equivalence: ", $mpfi1 != $mpfi2, "\n"}

if($mpfi1 == $mpfi2) {$ok .= 'b'}
else {warn "Equivalence: ", $mpfi1 == $mpfi2, "\n"}

$p = Rmpfi_get_prec($mpfi1);
if($p == $prec) {$ok .= 'c'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

$p = Rmpfi_get_prec($mpfi2);
if($p == $prec) {$ok .= 'd'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

if($ok eq 'abcd') {print "ok 6\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 6\n";
}

################################### TEST 7

undef($mpfi1);
undef($mpfi2);
$ok = '';

($mpfi1, $dis) = Rmpfi_init_set_d($double);
$mpfi2 = Math::MPFI->new($double);

if(Math::MPFI::_has_longdouble()) {
  warn "Skipping tests 7a to 7d - Math::MPFI::_has_longdouble() returned true\n";
  $ok = 'abcd';
}
else {
  unless($mpfi1 != $mpfi2) {$ok .= 'a'}
  else {warn "7a: Non-equivalence:\n$mpfi1 !=\n$mpfi2\n"}

  if($mpfi1 == $mpfi2) {$ok .= 'b'}
  else {warn "7b: Equivalence:\n$mpfi1 ==\n$mpfi2\n"}

  unless($mpfi1 != $double) {$ok .= 'c'}
  else {warn "7c: Non-equivalence:\n$mpfi1 !=\n$double\n"}

  if($mpfi1 == $double) {$ok .= 'd'}
  else {warn "7d: Equivalence:\n$mpfi1 ==\n$double\n"}
}

$p = Rmpfi_get_prec($mpfi1);
if($p == $prec) {$ok .= 'e'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

$p = Rmpfi_get_prec($mpfi2);
if($p == $prec) {$ok .= 'f'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

if($ok eq 'abcdef') {print "ok 7\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 7\n";
}

################################### TEST 8

undef($mpfi1);
undef($mpfi2);
$ok = '';

unless(Math::MPFI::_has_longlong()) {
  ($mpfi1, $dis) = Rmpfi_init_set_si($si);
}
else {
  my $t = Math::MPFR->new();
  Math::MPFR::Rmpfr_set_sj($t, $si, Math::MPFR::Rmpfr_get_default_rounding_mode());
  ($mpfi1, $dis) = Rmpfi_init_set_fr($t);
}
$mpfi2 = Math::MPFI->new($si);

unless($mpfi1 != $mpfi2) {$ok .= 'a'}
else {warn "Non-equivalence: ", $mpfi1 != $mpfi2, "\n"}

if($mpfi1 == $mpfi2) {$ok .= 'b'}
else {warn "Equivalence: ", $mpfi1 == $mpfi2, "\n"}

unless($mpfi1 != $si) {$ok .= 'c'}
else {warn "Non-equivalence: ", $mpfi1 != $si, "\n"}

if($mpfi1 == $si) {$ok .= 'd'}
else {warn "Equivalence: ", $mpfi1 == $si, "\n"}

$p = Rmpfi_get_prec($mpfi1);
if($p == $prec) {$ok .= 'e'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

$p = Rmpfi_get_prec($mpfi2);
if($p == $prec) {$ok .= 'f'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

if($ok eq 'abcdef') {print "ok 8\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 8\n";
}

################################### TEST 9

undef($mpfi1);
undef($mpfi2);
$ok = '';

unless(Math::MPFI::_has_longlong()) {
  ($mpfi1, $dis) = Rmpfi_init_set_ui($ui);
}
else {
  my $t = Math::MPFR->new();
  Math::MPFR::Rmpfr_set_uj($t, $ui, Math::MPFR::Rmpfr_get_default_rounding_mode());
  ($mpfi1, $dis) = Rmpfi_init_set_fr($t);
}
$mpfi2 = Math::MPFI->new($ui);

unless($mpfi1 != $mpfi2) {$ok .= 'a'}
else {warn "Non-equivalence: ", $mpfi1 != $mpfi2, "\n"}

if($mpfi1 == $mpfi2) {$ok .= 'b'}
else {warn "Equivalence: ", $mpfi1 == $mpfi2, "\n"}

unless($mpfi1 != $ui) {$ok .= 'c'}
else {warn "Non-equivalence: ", $mpfi1 != $ui, "\n"}

if($mpfi1 == $ui) {$ok .= 'd'}
else {warn "Equivalence: ", $mpfi1 == $ui, "\n"}

$p = Rmpfi_get_prec($mpfi1);
if($p == $prec) {$ok .= 'e'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

$p = Rmpfi_get_prec($mpfi2);
if($p == $prec) {$ok .= 'f'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

if($ok eq 'abcdef') {print "ok 9\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 9\n";
}

################################### TEST 10

undef($mpfi2);
$ok = '';

$mpfi2 = Math::MPFI->new($mpfi1);

unless($mpfi1 != $mpfi2) {$ok .= 'a'}
else {warn "Non-equivalence: ", $mpfi1 != $mpfi2, "\n"}

if($mpfi1 == $mpfi2) {$ok .= 'b'}
else {warn "Equivalence: ", $mpfi1 == $mpfi2, "\n"}

$p = Rmpfi_get_prec($mpfi1);
if($p == $prec) {$ok .= 'c'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

$p = Rmpfi_get_prec($mpfi2);
if($p == $prec) {$ok .= 'd'}
else {warn "Precision expected to be $prec\nGot: $p\n"}

if($ok eq 'abcd') {print "ok 10\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 10\n";
}

###################################

my $mbi = Math::BigInt->new(12345);

eval {my $fail = Math::MPFI->new($mbi);};

if($@ =~ /Inappropriate argument supplied to new/) { print "ok 11\n" }
else {
  warn "\$\@: $@\n";
  print "not ok 11\n";
}

if($have_gmpf) {
  eval{my $fail2 = Math::MPFI->new(Math::GMPf->new(1.65));};
  if($@ =~ /Inappropriate argument supplied to new/) {print "ok 12\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 12\n";
  }
}
else {
  warn "Skipping test 12 - no Math::GMPf\n";
  print "ok 12\n";
}

