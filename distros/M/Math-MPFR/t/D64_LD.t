use warnings;
use strict;
use Math::MPFR qw (:mpfr);

my $t = 3;
print "1..$t\n";

my $why;
my $keep_printing = 1;

eval {require Math::Decimal64; Math::Decimal64->import (qw(:all));};
if($@) {$why = "Couldn't load Math::Decimal64\n"}
else {$why = "Math::MPFR not built for _Decimal64\n"
        unless Math::MPFR::_MPFR_WANT_DECIMAL_FLOATS()}

eval {require Math::LongDouble; Math::LongDouble->import (qw(:all));};
if($@) {$why .= "Couldn't load Math::LongDouble\n"}

unless($why) {

  my $d64_1 = Math::Decimal64->new(0);
  my $d64_2 = Math::Decimal64->new(0);
  my $ld    = ZeroLD(1);

  my $ok = 1;

  my $round = 0;# MPFR_RNDN

  my $mant_dig = Math::MPFR::_LDBL_MANT_DIG(); # expected to be either 64 or 106
  Rmpfr_set_default_prec($mant_dig);

  # If $mant_dig == 106, I assume the long double is "double-double" - which doesn't
  # accommodate the full exponent range of the Decimal64 type.
  my $rand_limit = $mant_dig == 106 ? 292 : 399;

  for my $it (1..100000) {
    my $digits = 1 + int(rand(16)); # Don't exceed max precision for this test.
    #Rmpfr_set_default_prec(53 + int(rand(100)));
    my $man_sign = $it % 2 ? '-' : '';
    my $exp_sign = $it % 3 ? 1 : -1;
    my $man = $man_sign . get_man($digits);
    my $exp = int(rand($rand_limit)) * $exp_sign;
    #next if $exp + $digits > 385;
    my $fr_arg = $man . '@' . $exp;

    my $d64_check = Math::Decimal64->new($man, $exp);

    my $fr = Math::MPFR->new($fr_arg, 10);

    Rmpfr_get_DECIMAL64($d64_1, $fr, $round);
    Rmpfr_get_LD($ld, $fr, $round);
    LDtoD64($d64_2, $ld);

    unless($d64_2 == $d64_1) {
      if($keep_printing < 6) {
        warn "$digits $exp\n$fr_arg\n $fr\n";
        warn "\$d64_check: $d64_check\n\$d64_1: $d64_1\n\$d64_2: $d64_2\n\$ld: $ld\n\n";
        $ok = 0;
      }
    $keep_printing++;
    }
  }


  if($ok) {print "ok 1\n"}
  else {print "not ok 1\n"}

  $ok = 1;

  for(3 .. 70) {
    my $eps = Math::Decimal64->new(1, -398);
    my $eps_ret = NVtoD64(2.5);
    my $eps_fr = Rmpfr_init2($_);
    Rmpfr_set_DECIMAL64($eps_fr, $eps, MPFR_RNDN);
    Rmpfr_get_DECIMAL64($eps_ret, $eps_fr, MPFR_RNDN);
    unless($eps_ret == $eps) {
      warn "\nMPFR precision: ", Rmpfr_get_prec($eps_fr), "\n";
      warn "\$eps: $eps\n\$eps_ret: $eps_ret\n";
      $ok = 0;
    }
  }

  if($ok) {print "ok 2\n"}
  else {print "not ok 2\n"}

  Rmpfr_set_default_prec($mant_dig);
  my $root = Math::MPFR->new(2.0);
  Rmpfr_sqrt($root, $root, MPFR_RNDN);
  my $ld_root = sqrt(Math::LongDouble->new(2.0));
  Rmpfr_get_LD($ld, $root, MPFR_RNDN);

  if($ld == $ld_root) {print "ok 3\n"}
  else {
    warn "\n\$ld: $ld\n\$ld_root: $ld_root\n";
    print "not ok 3\n";
  }

}
else {
 warn "\nSkipping all tests\n";
 warn $why;
 for (1 .. $t) {print "ok $_\n"}
}


sub get_man {
  my $ret = '';
  for(1 .. $_[0]) {$ret .= int(rand(10))}
  return $ret;
}

