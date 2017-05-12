use strict;
use warnings;
use Math::GMPq qw(:mpq);

print "1..21\n";

print "# Using gmp version ", Math::GMPq::gmp_v(), "\n";

my($have_mpz, $have_mpf) = (0, 0);
my($f, $z);

eval{require Math::GMPz};
if(!$@) {$have_mpz = 1}

eval{require Math::GMPf};
if(!$@) {$have_mpf = 1}

if($have_mpz) {$z = Math::GMPz::Rmpz_init_set_str('123456789', 10)}
if($have_mpf) {$f = Math::GMPf::Rmpf_init_set_str('1.2345@3', 10)}

my $p = Rmpq_init();
my $q = Rmpq_init();
my $r = Rmpq_init();
Rmpq_set_str($r, '111111111111111111111111111111234567/2', 10);
my $s = Rmpq_init();
my $double = 123.5;

Rmpq_set_ui($p, 9002, 6);
Rmpq_canonicalize($p);
if(Rmpq_get_str($p, 10) eq '4501/3') {print "ok 1\n"}
else {print "not ok 1\n"}

Rmpq_set_d($p, $double);
if(Rmpq_get_str($p, 10) eq '247/2') {print "ok 2\n"}
else {print "not ok 2\n"}

Rmpq_set($q, $p);
if(Rmpq_get_str($q, 10) eq '247/2') {print "ok 3\n"}
else {print "not ok 3\n"}

if($have_mpz) {
  Rmpq_set_z($p, $z);
  if(Rmpq_get_str($p, 10) eq '123456789') {print "ok 4\n"}
  else {print "not ok 4\n"}
  }
else {
  Rmpq_set_str($p, '123456789', 10);
  warn "Skipping test 4 - no Math::GMPz\n";
  print "ok 4\n";
  }

Rmpq_swap($p, $q);
if(Rmpq_get_str($q, 10) eq '123456789' && Rmpq_get_str($p, 10) eq '247/2') {print "ok 5\n"}
else {print "not ok 5\n"}

if($have_mpf) {
  Rmpq_set_f($p, $f);
  if(Rmpq_get_str($p, 10) eq '2469/2') {print "ok 6\n"}
  else {print "not ok 6\n"}
}
else {
  warn "Skipping test 6 - no Math::GMPf\n";
  print "ok 6\n";
}

Rmpq_set_str($s, '999999999999999999999ff1/2', 36);

if(Rmpq_get_str($s, 36) eq '999999999999999999999ff1/2') {print "ok 7\n"}
else {print "not ok 7\n"}

if(Rmpq_get_str($r, 10) eq '111111111111111111111111111111234567/2') {print "ok 8\n"}
else {print "not ok 8\n"}

Rmpq_neg($s, $r);
if(Rmpq_sgn($s) == -1 && Rmpq_sgn($r) == +1) {print "ok 9\n"}
else {print "not ok 9\n"}

Rmpq_abs($s, $s);
Rmpq_add($s, $s, $s);
Rmpq_mul_2exp($p, $r, 1);

if(Rmpq_equal($s, $p)) {print "ok 10\n"}
else {print "not ok 10\n"}

Rmpq_inv($s, $s);
Rmpq_set_ui($r, 1, 1);
Rmpq_canonicalize($r);
Rmpq_mul($q, $p, $s);

if(Rmpq_equal($q, $r)) {print "ok 11\n"}
else {print "not ok 11\n"}

Rmpq_div_2exp($p, $p, 1);

if(Rmpq_get_str($p, 10) eq '111111111111111111111111111111234567/2') {print "ok 12\n"}
else {print "not ok 12\n"}

Rmpq_neg($q, $p);
if(Rmpq_cmp($q, $p) < 0 && Rmpq_cmp($p, $q) > 0) {print "ok 13\n"}
else {print "not ok 13\n"}

Rmpq_div($q, $p, $q);
if(!Rmpq_cmp_si($q, -1, 1)) {print "ok 14\n"}
else {print "not ok 14\n"}

if(Rmpq_cmp_ui($q, 1, 1) < 0) {print "ok 15\n"}
else {print "not ok 15\n"}

my $ok = '';

if($have_mpz) {
  Rmpq_get_num($z, $p);
  if(Math::GMPz::Rmpz_get_str($z, 10) eq '111111111111111111111111111111234567') {$ok .= 'a'}
  Rmpq_get_den($z, $p);
  if(Math::GMPz::Rmpz_get_str($z, 10) eq '2') {$ok .= 'b'}
  Math::GMPz::Rmpz_set_ui($z, 12345671);
  Rmpq_set_num($p, $z);
  Math::GMPz::Rmpz_set_ui($z, 5);
  Rmpq_set_den($p, $z);
  if(Rmpq_get_str($p, 10) eq '12345671/5') {$ok .= 'c'}
  if($ok eq 'abc') {print "ok 16\n"}
  else {print "not ok 16 $ok\n"}
}
else {
  warn "Skipping test 16 - no Math::GMPz\n";
  print "ok 16\n";
}

Rmpq_set_str($q, '4295098369/4295360521', 10);

if($have_mpz) {
  $ok = '';
  Rmpq_numref($z, $q);
  if(Math::GMPz::Rmpz_get_str($z, 10) eq '4295098369') {$ok .= 'a'}
  Rmpq_denref($z, $q);
  if(Math::GMPz::Rmpz_get_str($z, 10) eq '4295360521') {$ok .= 'b'}
  if($ok eq 'ab') {print "ok 17\n"}
  else {print "not ok 17 $ok\n"}
}
else {
  warn "Skipping test 17 - no Math::GMPz\n";
  print "ok 17\n";
}

my $x = Rmpq_init();
my $y = Rmpq_init();

Rmpq_set_str($x, '0xFFFFFFFFFFFFFFF/11', 0);
Rmpq_set_str($y, '0xfffffffffffffff/11', 0);
Rmpq_set_str($p, '0XFFFFFFFFFFFFFFF/11', 0);
Rmpq_set_str($q, '0Xfffffffffffffff/11', 0);
Rmpq_set_str($r, '077777777777777777777/11', 0);
Rmpq_set_str($s, '1152921504606846975/11', 0);

if(!Rmpq_cmp($x, $y) && !Rmpq_cmp($x, $p)&& !Rmpq_cmp($x, $q) &&
   !Rmpq_cmp($x, $r) && !Rmpq_cmp($x, $s)) {print "ok 18\n"}
else {print "not ok 18\n"}

eval {$ok = Math::GMPq::gmp_v();};

if($@ || $ok =~ /[^0-9\.]/) {print "not ok 19\n"}
else {print "ok 19\n"}

#my $ofh = select(STDERR);
eval {Rmpq_printf("The version is %s. Values are %d %Qx %Qx\n", $ok, 11, $x, $y);};
#select($ofh);
if(!$@) {print "not ok 20\n"}
else {print "ok 20\n"}

my $si_test = Math::GMPq->new;

Rmpq_set_si($si_test, Math::GMPq::_long_min(), 1);

if($si_test == Math::GMPq::_long_min()) {print "ok 21\n"}
else {
  warn "\n  Expected ", Math::GMPq::_long_min(), "\n  Got $si_test\n";
  print "not ok 21\n";
}
