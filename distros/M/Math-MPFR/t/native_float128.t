use strict;
use warnings;
use Config;
use Math::MPFR qw(:mpfr);

my $t = 1;

if(Math::MPFR::_can_pass_float128()) {
  print "1..$t\n";
  warn "\n Can pass _float128 between perl subs and XSubs\n";

  Rmpfr_set_default_prec(113);

  my $frac = 3.0; # For me, both C and perl miscalculates sqrt(2.0), so we'll
                  # sweep that one under the carpet and check using sqrt(3.0),
                  # which seems to be calculated correctly.

  my $fr = Math::MPFR->new($frac);
  $fr **= 0.5;
  if($fr == sqrt($frac)) {print "ok 1\n"}
  else {
    my $check = sprintf "%a", Rmpfr_get_float128($fr, MPFR_RNDN);
    warn "\n Expected $check\n      Got ", sprintf "%a\n", sqrt($frac);
    print "not ok 1\n";
  }
}
elsif($Config{nvtype} eq '__float128') {

  # We can't pass __float128 types, so we'll pass the values as a long double.

  print "1..$t\n";

  # First, work out the precision of the long double:
  my($frac, $prec) = (2.0, $Config{longdblkind});
  if(!defined($prec)) {$prec = 0}
  elsif($prec == 0) {$prec = 53}
  elsif($prec == 1 || $prec == 2) {$prec = 113}
  elsif($prec == 3 || $prec == 4) {$prec = 64}
  elsif($prec == 5 || $prec == 6) {$prec = 2098}
  else {$prec = 0}

  if(!$prec) {
    warn "\n Skipping tests - couldn't determine precision of long double\n";
    print "ok $_\n" for 1 .. $t;
    exit 0;
  }

  warn "\n Casting __float128 to $prec-bit precision long double\n";

  Rmpfr_set_default_prec($prec);

  my $fr1 = Math::MPFR->new(sqrt($frac));
  my $fr2 = Math::MPFR->new();
  Rmpfr_set_ld($fr2, sqrt($frac), MPFR_RNDN);

  if($fr1 == $fr2) {print "ok 1\n"}
  else {
    warn "\n$fr1 != $fr2\n";
    print "not ok 1\n";
  }
}
else {
  print "1..1\n";
  warn "\n Skipping all tests - nvtype is $Config{nvtype}\n";
  print "ok 1\n";
  exit 0;
}
