use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..4\n";

Rmpfr_set_default_prec(150);

my $mpfi = Math::MPFI->new(9876);

Rmpfi_cbrt($mpfi, $mpfi);
$mpfi = $mpfi * $mpfi * $mpfi;

Rmpfi_cbrt($mpfi, $mpfi);
$mpfi = $mpfi * $mpfi * $mpfi;

Rmpfi_cbrt($mpfi, $mpfi);
$mpfi = $mpfi * $mpfi * $mpfi;

my $mpfr = Math::MPFR->new();


my($have_mpz, $have_mpq, $have_mpf) = (0, 0, 0);

eval{require Math::GMPz;};
if(!$@) {
  if($Math::GMPz::VERSION > 0.30) {$have_mpz = 1}
}
if($have_mpz) {
  my $state = Math::GMPz::zgmp_randinit_lc_2exp
               (Math::GMPz->new("98765" * 10), int(rand(123) + 100), int(rand(30) + 40));
  Rmpfi_urandom($mpfr, $mpfi, $state);

  if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {
    #warn "$mpfr\n";
    print "ok 1\n";
  }
  else {
    warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
    print "not ok 1\n";
  }
}
else {
  warn "Skipping test 1 - need at least version 0.31 of Math::GMPz\n";
  print "ok 1\n";
}



eval{require Math::GMPq;};
if(!$@) {
  if($Math::GMPq::VERSION > 0.30) {$have_mpq = 1}
}
if($have_mpq) {
  my $state = Math::GMPq::qgmp_randinit_mt();
  Rmpfi_urandom($mpfr, $mpfi, $state);

  if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {
    #warn "$mpfr\n";
    print "ok 2\n";
  }
  else {
    warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
    print "not ok 2\n";
  }
}
else {
  warn "Skipping test 2 - need at least version 0.31 of Math::GMPq\n";
  print "ok 2\n";
}

eval{require Math::GMPf;};
if(!$@) {
  if($Math::GMPf::VERSION > 0.31) {$have_mpf = 1}
}
if($have_mpf) {
  my $state = Math::GMPf::fgmp_randinit_lc_2exp_size(int(rand(108)) + 20);
  Rmpfi_urandom($mpfr, $mpfi, $state);

  if(Rmpfi_is_inside_fr($mpfr, $mpfi)) {
    #warn "$mpfr\n";
    print "ok 3\n";
  }
  else {
    warn "\$mpfr: $mpfr\n\$mpfi: $mpfi\n";
    print "not ok 3\n";
  }
}
else {
  warn "Skipping test 3 - need at least version 0.32 of Math::GMPf\n";
  print "ok 3\n";
}


my $alea = Math::MPFR->new();

Rmpfi_alea($alea, $mpfi);

if(!Rmpfi_cmp_fr($mpfi, $alea)) {print "ok 4\n"}
else {
  warn "\$alea: $alea\n\$mpfi: $mpfi\n";
  print "not ok 4\n";
}
