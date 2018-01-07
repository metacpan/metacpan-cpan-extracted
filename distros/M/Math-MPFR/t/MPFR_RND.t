use warnings;
use strict;
use Math::MPFR qw(:mpfr);

print "1..20\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

if(GMP_RNDN == MPFR_RNDN) {print "ok 1\n"}
else {
  warn "GMP_RNDN: ", GMP_RNDN, " MPFR_RNDN: ", MPFR_RNDN, "\n";
  print "not ok 1\n";
}

if(GMP_RNDZ == MPFR_RNDZ) {print "ok 2\n"}
else {
  warn "GMP_RNDZ: ", GMP_RNDZ, " MPFR_RNDZ: ", MPFR_RNDZ, "\n";
  print "not ok 2\n";
}

if(GMP_RNDU == MPFR_RNDU) {print "ok 3\n"}
else {
  warn "GMP_RNDU: ", GMP_RNDU, " MPFR_RNDU: ", MPFR_RNDU, "\n";
  print "not ok 3\n";
}

if(GMP_RNDD == MPFR_RNDD) {print "ok 4\n"}
else {
  warn "GMP_RNDD: ", GMP_RNDD, " MPFR_RNDD: ", MPFR_RNDD, "\n";
  print "not ok 4\n";
}

if(MPFR_RNDA == 4) {print "ok 5\n"}
else {
  warn "MPFR_RNDA: ", MPFR_RNDA, "\n";
  print "not ok 5\n";
}

if(MPFR_VERSION_MAJOR >= 3) {
  my ($mpfr, $dis) = Rmpfr_init_set_ui(12345, MPFR_RNDA);
  if($mpfr == 12345) {print "ok 6\n"}
  else {
    warn "\$mpfr: $mpfr\n";
    print "not ok 6\n";
  }
}
else {
  eval {my ($mpfr, $dis) = Rmpfr_init_set_ui(12345, MPFR_RNDA);};
  if($@ =~ /Illegal rounding value supplied/) {print "ok 6\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 6\n";
  }
}

if(Rmpfr_print_rnd_mode(MPFR_RNDD) eq 'MPFR_RNDD' ||
   Rmpfr_print_rnd_mode(MPFR_RNDD) eq 'GMP_RNDD') {print "ok 7\n"}
else {
  warn "\nExpected 'MPFR_RNDD' or 'GMP_RNDD'\nGot '", Rmpfr_print_rnd_mode(MPFR_RNDD), "'\n";
  print "not ok 7\n";
}

if(Rmpfr_print_rnd_mode(MPFR_RNDU) eq 'MPFR_RNDU' ||
   Rmpfr_print_rnd_mode(MPFR_RNDU) eq 'GMP_RNDU') {print "ok 8\n"}
else {
  warn "\nExpected 'MPFR_RNDU' or 'GMP_RNDU'\nGot '", Rmpfr_print_rnd_mode(MPFR_RNDU), "'\n";
  print "not ok 8\n";
}

if(Rmpfr_print_rnd_mode(MPFR_RNDN) eq 'MPFR_RNDN' ||
   Rmpfr_print_rnd_mode(MPFR_RNDN) eq 'GMP_RNDN') {print "ok 9\n"}
else {
  warn "\nExpected 'MPFR_RNDN' or 'GMP_RNDN'\nGot '", Rmpfr_print_rnd_mode(MPFR_RNDN), "'\n";
  print "not ok 9\n";
}

if(Rmpfr_print_rnd_mode(MPFR_RNDZ) eq 'MPFR_RNDZ' ||
   Rmpfr_print_rnd_mode(MPFR_RNDZ) eq 'GMP_RNDZ') {print "ok 10\n"}
else {
  warn "\nExpected 'MPFR_RNDZ' or 'GMP_RNDZ'\nGot '", Rmpfr_print_rnd_mode(MPFR_RNDZ), "'\n";
  print "not ok 10\n";
}

if(!defined(Rmpfr_print_rnd_mode(100))) {print "ok 11\n"}
else {
  warn "\nExpected 'undef'\nGot '", Rmpfr_print_rnd_mode(100), "'\n";
  print "not ok 11\n";
}

if(Rmpfr_print_rnd_mode(GMP_RNDD) eq 'MPFR_RNDD' ||
   Rmpfr_print_rnd_mode(GMP_RNDD) eq 'GMP_RNDD') {print "ok 12\n"}
else {
  warn "\nExpected 'MPFR_RNDD' or 'GMP_RNDD'\nGot '", Rmpfr_print_rnd_mode(GMP_RNDD), "'\n";
  print "not ok 12\n";
}

if(Rmpfr_print_rnd_mode(GMP_RNDU) eq 'MPFR_RNDU' ||
   Rmpfr_print_rnd_mode(GMP_RNDU) eq 'GMP_RNDU') {print "ok 13\n"}
else {
  warn "\nExpected 'MPFR_RNDU' or 'GMP_RNDU'\nGot '", Rmpfr_print_rnd_mode(GMP_RNDU), "'\n";
  print "not ok 13\n";
}

if(Rmpfr_print_rnd_mode(GMP_RNDN) eq 'MPFR_RNDN' ||
   Rmpfr_print_rnd_mode(GMP_RNDN) eq 'GMP_RNDN') {print "ok 14\n"}
else {
  warn "\nExpected 'MPFR_RNDN' or 'GMP_RNDN'\nGot '", Rmpfr_print_rnd_mode(GMP_RNDN), "'\n";
  print "not ok 14\n";
}

if(Rmpfr_print_rnd_mode(GMP_RNDZ) eq 'MPFR_RNDZ' ||
   Rmpfr_print_rnd_mode(GMP_RNDZ) eq 'GMP_RNDZ') {print "ok 15\n"}
else {
  warn "\nExpected 'MPFR_RNDZ' or 'GMP_RNDZ'\nGot '", Rmpfr_print_rnd_mode(GMP_RNDZ), "'\n";
  print "not ok 15\n";
}

if(3 <= MPFR_VERSION_MAJOR) {
  if(Rmpfr_print_rnd_mode(MPFR_RNDA) eq 'MPFR_RNDA') {print "ok 16\n"}
  else {
    warn "\nExpected 'MPFR_RNDA'\nGot '", Rmpfr_print_rnd_mode(MPFR_RNDA), "'\n";
    print "not ok 16\n";
  }
}
else {
  if(!defined(Rmpfr_print_rnd_mode(MPFR_RNDA))) {print "ok 16\n"}
  else {
    warn "\nExpected 'undef'\nGot '", Rmpfr_print_rnd_mode(MPFR_RNDA), "'\n";
    print "not ok 16\n";
  }
}

if(MPFR_RNDF == 5) {print "ok 17\n"}
else {
  warn "\n Expected 5, got ", MPFR_RNDF, "\n";
  print "not ok 17\n";
}

if(MPFR_VERSION_MAJOR >= 4) {
  my $op1 = Math::MPFR->new('17.7');
  my $op2 = Math::MPFR->new('9.9');

  my $ropu = Math::MPFR->new();
  my $ropf = Math::MPFR->new();
  my $ropd = Math::MPFR->new();

  my $inex1 = Rmpfr_mul($ropu, $op1, $op2, MPFR_RNDU);
  my $inex2 = Rmpfr_mul($ropd, $op1, $op2, MPFR_RNDD);

  if($inex1 && $inex2) {print "ok 18\n"}
  else {
    warn "\n \$inex1: $inex1, \$inex2: $inex2\n";
    print "not ok 18\n";
  }

  Rmpfr_mul($ropf, $op1, $op2, MPFR_RNDF);

  if($ropf == $ropu || $ropf == $ropd) {print "ok 19\n"}
  else {
    warn "\n \$ropu: $ropu\n \$ropf: $ropf\n \$ropd: $ropd\n";
    print "not ok 19\n";
  }

  Rmpfr_set_default_rounding_mode(MPFR_RNDF);

  my $check = $op1 * $op2;

  if($check == $ropu || $check == $ropd) {print "ok 20\n"}
  else {
    warn "\n \$ropu: $ropu\n \$check: $check\n \$ropd: $ropd\n";
    print "not ok 20\n";
  }

  # Restore original default rounding mode
  Rmpfr_set_default_rounding_mode(MPFR_RNDN);
}
else {

  my $ropf = Math::MPFR->new();

  eval {Rmpfr_mul($ropf, Math::MPFR->new('17.7'), Math::MPFR->new('9.9'), MPFR_RNDF)};

  if($@ =~ /^Illegal rounding value supplied for this version/) {print "ok 18\n"}
  else {
    warn "\n\$\@: $@";
    print "not ok 18\n";
  }

  warn "\n Skipping tests 19 and 20 - requires mpfr-4.0.0 or later\n";
  for(19..20) {print "ok $_\n"}
}
