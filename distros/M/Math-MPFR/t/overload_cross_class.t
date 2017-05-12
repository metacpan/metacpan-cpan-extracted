use warnings;
use strict;
use Math::MPFR qw(:mpfr);

print "1..3\n";

my $message = '';
my ($have_mpz, $have_mpf, $have_mpq) = (1, 1, 1);
my ($rop, $op, $mpz, $mpf, $mpq, $mpz_power, $mpf_power, $mpq_power);

$op = Math::MPFR->new(307.5);

eval{require Math::GMPz;};
if($@) {
  $have_mpz = 0;
  $message .= "    Math::GMPz - currently not installed\n";
}
else {
  $mpz = Math::GMPz->new(10);
  $mpz_power = Math::GMPz->new(4);
  $message .= "    Math::GMPz - we only have $Math::GMPz::VERSION\n"
              if $Math::GMPz::VERSION < 0.35;
}

eval{require Math::GMPf;};
if($@) {
  $have_mpf = 0;
  $message .= "    Math::GMPf - currently not installed\n";
}
else {
  $mpf = Math::GMPf->new(10.0);
  $mpf_power = Math::GMPf->new(4.0);
  $message .= "    Math::GMPf - we only have $Math::GMPf::VERSION\n"
              if $Math::GMPf::VERSION < 0.35;
}

eval{require Math::GMPq;};
if($@) {
  $have_mpq = 0;
  $message .= "    Math::GMPq - currently not installed\n";
}
else {
  $mpq = Math::GMPq->new(10.0);
  $mpq_power = Math::GMPq->new(4);
  $message .= "    Math::GMPq - we only have $Math::GMPq::VERSION\n"
              if $Math::GMPq::VERSION < 0.35;
}

if($message) {
  $message = "\n  Version 0.35 (or later) of the following modules is needed for a more \n" .
             "  complete implementation of cross_class overloading:\n" .
             $message;
}

warn "$message\n" if $message;

my $ok = '';

if($have_mpz) {

  $rop = $op + $mpz;
  if(ref($rop) eq 'Math::MPFR'){$ok .= 'a'}
  else { warn "1a: ref: ", ref($rop), "\n"}
  if($rop == 317.5) {$ok .= 'b'}
  else {warn "1b: \$rop: $rop\n"}

  $rop = $op * $mpz;
  if(ref($rop) eq 'Math::MPFR'){$ok .= 'c'}
  else { warn "1c: ref: ", ref($rop), "\n"}
  if($rop == 3075) {$ok .= 'd'}
  else {warn "1d: \$rop: $rop\n"}

  $rop = $op - $mpz;
  if(ref($rop) eq 'Math::MPFR'){$ok .= 'e'}
  else { warn "1e: ref: ", ref($rop), "\n"}
  if($rop == 297.5) {$ok .= 'f'}
  else {warn "1f: \$rop: $rop\n"}

  $rop = $op / $mpz;
  if(ref($rop) eq 'Math::MPFR'){$ok .= 'g'}
  else { warn "1g: ref: ", ref($rop), "\n"}
  if($rop == 30.75) {$ok .= 'h'}
  else {warn "1h: \$rop: $rop\n"}

  ######################################
  $rop = $op ** $mpz_power;
  if(ref($rop) eq 'Math::MPFR'){$ok .= 'i'}
  else { warn "1i: ref: ", ref($rop), "\n"}
  if($rop == 8940884414.0625) {$ok .= 'j'}
  else {warn "1j: \$rop: $rop\n"}

  $op += $mpz;
  if($op == 317.5) {$ok .= 'k'}
  else {warn "1k: \$op: $op\n"}

  $op -= $mpz;
  if($op == 307.5) {$ok .= 'l'}
  else {warn "1l: \$op: $op\n"}

  $op *= $mpz;
  if($op == 3075) {$ok .= 'm'}
  else {warn "1m: \$op: $op\n"}

  $op /= $mpz;
  if($op == 307.5) {$ok .= 'n'}
  else {warn "1n: \$op: $op\n"}

  $op **= $mpz_power;
  if($op == 8940884414.0625) {$ok .= 'o'}
  else {warn "1o: \$op: $op\n"}

  Rmpfr_set_d($op, 307.5, GMP_RNDN); # Restore to original value
  ######################################

  if($ok eq 'abcdefghijklmno') {print "ok 1\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 1\n";
  }

} # close mpz
else {
  warn "\nSkipping test 1 - no Math::GMPz\n";
  print "ok 1\n";
}

$ok = '';

if($have_mpf) {

  $rop = $op + $mpf;
  if(ref($rop) eq 'Math::MPFR'){$ok .= 'a'}
  else { warn "2a: ref: ", ref($rop), "\n"}
  if($rop == 317.5) {$ok .= 'b'}
  else {warn "2b: \$rop: $rop\n"}

  $rop = $op * $mpf;
  if(ref($rop) eq 'Math::MPFR'){$ok .= 'c'}
  else { warn "2c: ref: ", ref($rop), "\n"}
  if($rop == 3075) {$ok .= 'd'}
  else {warn "2d: \$rop: $rop\n"}

  $rop = $op - $mpf;
  if(ref($rop) eq 'Math::MPFR'){$ok .= 'e'}
  else { warn "2e: ref: ", ref($rop), "\n"}
  if($rop == 297.5) {$ok .= 'f'}
  else {warn "2f: \$rop: $rop\n"}

  $rop = $op / $mpf;
  if(ref($rop) eq 'Math::MPFR'){$ok .= 'g'}
  else { warn "2g: ref: ", ref($rop), "\n"}
  if($rop == 30.75) {$ok .= 'h'}
  else {warn "2h: \$rop: $rop\n"}

  ######################################
  $rop = $op ** $mpf_power;
  if(ref($rop) eq 'Math::MPFR'){$ok .= 'i'}
  else { warn "2i: ref: ", ref($rop), "\n"}
  if($rop == 8940884414.0625) {$ok .= 'j'}
  else {warn "2j: \$rop: $rop\n"}

  $op += $mpf;
  if($op == 317.5) {$ok .= 'k'}
  else {warn "2k: \$op: $op\n"}

  $op -= $mpf;
  if($op == 307.5) {$ok .= 'l'}
  else {warn "2l: \$op: $op\n"}

  $op *= $mpf;
  if($op == 3075) {$ok .= 'm'}
  else {warn "2m: \$op: $op\n"}

  $op /= $mpf;
  if($op == 307.5) {$ok .= 'n'}
  else {warn "2n: \$op: $op\n"}

  $op **= $mpf_power;
  if($op == 8940884414.0625) {$ok .= 'o'}
  else {warn "2o: \$op: $op\n"}

  Rmpfr_set_d($op, 307.5, GMP_RNDN); # Restore to original value
  ######################################

  if($ok eq 'abcdefghijklmno') {print "ok 2\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 2\n";
  }

} # close mpf
else {
  warn "\nSkipping test 2 - no Math::GMPf\n";
  print "ok 2\n";
}

$ok = '';

if($have_mpq) {

  $rop = $op + $mpq;
  if(ref($rop) eq 'Math::MPFR'){$ok .= 'a'}
  else { warn "3a: ref: ", ref($rop), "\n"}
  if($rop == 317.5) {$ok .= 'b'}
  else {warn "3b: \$rop: $rop\n"}

  $rop = $op * $mpq;
  if(ref($rop) eq 'Math::MPFR'){$ok .= 'c'}
  else { warn "3c: ref: ", ref($rop), "\n"}
  if($rop == 3075) {$ok .= 'd'}
  else {warn "3d: \$rop: $rop\n"}

  $rop = $op - $mpq;
  if(ref($rop) eq 'Math::MPFR'){$ok .= 'e'}
  else { warn "3e: ref: ", ref($rop), "\n"}
  if($rop == 297.5) {$ok .= 'f'}
  else {warn "3f: \$rop: $rop\n"}

  $rop = $op / $mpq;
  if(ref($rop) eq 'Math::MPFR'){$ok .= 'g'}
  else { warn "3g: ref: ", ref($rop), "\n"}
  if($rop == 30.75) {$ok .= 'h'}
  else {warn "3h: \$rop: $rop\n"}

  ######################################
  $rop = $op ** $mpq_power;
  if(ref($rop) eq 'Math::MPFR'){$ok .= 'i'}
  else { warn "3i: ref: ", ref($rop), "\n"}
  if($rop == 8940884414.0625) {$ok .= 'j'}
  else {warn "3j: \$rop: $rop\n"}

  $op += $mpq;
  if($op == 317.5) {$ok .= 'k'}
  else {warn "3k: \$op: $op\n"}

  $op -= $mpq;
  if($op == 307.5) {$ok .= 'l'}
  else {warn "3l: \$op: $op\n"}

  $op *= $mpq;
  if($op == 3075) {$ok .= 'm'}
  else {warn "3m: \$op: $op\n"}

  $op /= $mpq;
  if($op == 307.5) {$ok .= 'n'}
  else {warn "3n: \$op: $op\n"}

  $op **= $mpq_power;
  if($op == 8940884414.0625) {$ok .= 'o'}
  else {warn "3o: \$op: $op\n"}

  Rmpfr_set_d($op, 307.5, GMP_RNDN); # Restore to original value
  ######################################

  if($ok eq 'abcdefghijklmno') {print "ok 3\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 3\n";
  }

} # close mpq
else {
  warn "\nSkipping test 3 - no Math::GMPq\n";
  print "ok 3\n";
}
