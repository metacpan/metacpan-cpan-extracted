use warnings;
use strict;
use Math::MPFR qw(:mpfr);

print "1..3\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

my $ok;

my($have_mpz, $have_mpq, $have_gmp) = (0, 0, 0);

eval{require Math::GMPz;};
unless($@) {$have_mpz = 1}

eval{require Math::GMPq;};
unless($@) {$have_mpq = 1}

eval{require Math::GMP;};
unless($@) {$have_gmp = 1}

my($q_zero, $z_zero);

# Rmpfr_div
# Rmpfr_div_d Rmpfr_div_q Rmpfr_div_si Rmpfr_div_ui Rmpfr_div_z
# Rmpfr_si_div Rmpfr_ui_div Rmpfr_d_div

my $unity   = Math::MPFR->new(1);
my $rop     = Math::MPFR->new();
my $fr_zero = Math::MPFR->new(0);
if($have_gmp) {$z_zero  = Math::GMP->new(0)}
if($have_mpz && !$have_gmp) {$z_zero  = Math::GMPz->new(0)}
if($have_mpq) {$q_zero  = Math::GMPq->new(0)}

if((MPFR_VERSION_MAJOR == 3 && MPFR_VERSION_MINOR >= 1) || MPFR_VERSION_MAJOR > 3) {
  unless(Rmpfr_divby0_p()) {$ok .= 'a'}
  Rmpfr_set_divby0();
  if(Rmpfr_divby0_p()) {$ok .= 'b'}
  Rmpfr_clear_divby0();
  unless(Rmpfr_divby0_p()) {$ok .= 'c'}

  Rmpfr_set_divby0();
  if(Rmpfr_divby0_p()) {$ok .= 'd'}
  Rmpfr_clear_flags();
  unless(Rmpfr_divby0_p()) {$ok .= 'e'}

  if($ok eq 'abcde') {print "ok 1\n"}
  else {
    warn "1: \$ok: $ok\n";
    print "not ok 1\n";
  }

  $ok = '';

  Rmpfr_div($rop, $unity, $fr_zero, GMP_RNDN);
  if(Rmpfr_divby0_p()) {$ok .= 'a'}
  Rmpfr_clear_divby0();
  unless(Rmpfr_divby0_p()) {$ok .= 'b'}

  if($have_gmp || $have_mpz) {
    Rmpfr_div_z($rop, $unity, $z_zero, GMP_RNDN);
    if(Rmpfr_divby0_p()) {$ok .= 'c'}
    Rmpfr_clear_divby0();
    unless(Rmpfr_divby0_p()) {$ok .= 'd'}
  }
  else {
    warn "Skipping tests 2c and 2d - no Math::GMP or Math::GMPz\n";
    $ok .= 'cd';
  }

  if($have_mpq) {
    Rmpfr_div_q($rop, $unity, $q_zero, GMP_RNDN);
    if(Rmpfr_divby0_p()) {$ok .= 'e'}
    Rmpfr_clear_divby0();
    unless(Rmpfr_divby0_p()) {$ok .= 'f'}
  }
  else {
    warn "Skipping tests 2e and 2f - no Math::GMPq\n";
    $ok .= 'ef';
  }

  Rmpfr_div_ui($rop, $unity, 0, GMP_RNDN);
  if(Rmpfr_divby0_p()) {$ok .= 'g'}
  Rmpfr_clear_divby0();
  unless(Rmpfr_divby0_p()) {$ok .= 'h'}

  Rmpfr_div_si($rop, $unity, 0, GMP_RNDN);
  if(Rmpfr_divby0_p()) {$ok .= 'i'}
  Rmpfr_clear_divby0();
  unless(Rmpfr_divby0_p()) {$ok .= 'j'}

  Rmpfr_div_d($rop, $unity, 0.0, GMP_RNDN);
  if(Rmpfr_divby0_p()) {$ok .= 'k'}
  Rmpfr_clear_divby0();
  unless(Rmpfr_divby0_p()) {$ok .= 'l'}

  Rmpfr_ui_div($rop, 15, $fr_zero, GMP_RNDN);
  if(Rmpfr_divby0_p()) {$ok .= 'm'}
  Rmpfr_clear_divby0();
  unless(Rmpfr_divby0_p()) {$ok .= 'n'}

  Rmpfr_si_div($rop, -23, $fr_zero, GMP_RNDN);
  if(Rmpfr_divby0_p()) {$ok .= 'o'}
  Rmpfr_clear_divby0();
  unless(Rmpfr_divby0_p()) {$ok .= 'p'}

  Rmpfr_d_div($rop, 12.34, $fr_zero, GMP_RNDN);
  if(Rmpfr_divby0_p()) {$ok .= 'q'}
  Rmpfr_clear_divby0();
  unless(Rmpfr_divby0_p()) {$ok .= 'r'}

  if($ok eq 'abcdefghijklmnopqr') {print "ok 2\n"}
  else {
    warn "2: \$ok: $ok\n";
    print "not ok 2\n";
  }

  $ok = '';

  $rop = $unity / $fr_zero;
  if(Rmpfr_divby0_p()) {$ok .= 'a'}
  Rmpfr_clear_divby0();
  unless(Rmpfr_divby0_p()) {$ok .= 'b'}

  $rop = $unity / 0;
  if(Rmpfr_divby0_p()) {$ok .= 'c'}
  Rmpfr_clear_divby0();
  unless(Rmpfr_divby0_p()) {$ok .= 'd'}

  $rop = $unity / 0.0;
  if(Rmpfr_divby0_p()) {$ok .= 'e'}
  Rmpfr_clear_divby0();
  unless(Rmpfr_divby0_p()) {$ok .= 'f'}

  $rop = $unity / '0.0';
  if(Rmpfr_divby0_p()) {$ok .= 'g'}
  Rmpfr_clear_divby0();
  unless(Rmpfr_divby0_p()) {$ok .= 'h'}

  $rop = 1 / $fr_zero;
  if(Rmpfr_divby0_p()) {$ok .= 'i'}
  Rmpfr_clear_divby0();
  unless(Rmpfr_divby0_p()) {$ok .= 'j'}

  $rop = -1 / $fr_zero;
  if(Rmpfr_divby0_p()) {$ok .= 'k'}
  Rmpfr_clear_divby0();
  unless(Rmpfr_divby0_p()) {$ok .= 'l'}

  $rop = 12.34 / $fr_zero;
  if(Rmpfr_divby0_p()) {$ok .= 'm'}
  Rmpfr_clear_divby0();
  unless(Rmpfr_divby0_p()) {$ok .= 'n'}

  $rop = '12.34' / $fr_zero;
  if(Rmpfr_divby0_p()) {$ok .= 'o'}
  Rmpfr_clear_divby0();
  unless(Rmpfr_divby0_p()) {$ok .= 'p'}

  if($ok eq 'abcdefghijklmnop') {print "ok 3\n"}
  else {
    warn "3: \$ok: $ok\n";
    print "not ok 3\n";
  }

}
else {
  eval{Rmpfr_set_divby0();};
  if($@ =~ /Rmpfr_set_divby0 not implemented/) {print "ok 1\n"}
  else {print "not ok 1\n"}

  eval{Rmpfr_clear_divby0();};
  if($@ =~ /Rmpfr_clear_divby0 not implemented/) {print "ok 2\n"}
  else {print "not ok 2\n"}

  eval{Rmpfr_divby0_p();};
  if($@ =~ /Rmpfr_divby0_p not implemented/) {print "ok 3\n"}
  else {print "not ok 3\n"}
}
