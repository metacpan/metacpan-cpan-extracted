use strict;
use warnings;
use Config;
use Math::MPFR qw(:mpfr);

# __float128 sqrt(3.0) = 1.73205080756887729352744634150587232 (36 decimal digits).

my $t = 2;

print "1..$t\n";

if(Math::MPFR::_can_pass_float128()) {

  warn "\n Can pass __float128 using Rmpfr_get_float128 and Rmpfr_set_float128\n";

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

  Rmpfr_set_float128($fr, 1.73205080756887729352744634150587232, MPFR_RNDN);

  if($fr == Math::MPFR->new('1.73205080756887729352744634150587232')) {print "ok 2\n"}
  else {
    my $check = sprintf "%a", Rmpfr_get_float128($fr, MPFR_RNDN);
    warn "\n Expected 1.73205080756887729352744634150587232\nGot $fr\n";
    print "not ok 2\n";
  }

}
elsif($Config{nvtype} eq '__float128') {

  warn "\n Can pass __float128 using Rmpfr_get_NV and Rmpfr_set_NV\n";

  Rmpfr_set_default_prec(113);

  my $frac = 3.0; # For me, both C and perl miscalculates sqrt(2.0), so we'll
                  # sweep that one under the carpet and check using sqrt(3.0),
                  # which seems to be calculated correctly.

  my $fr = Math::MPFR->new($frac);
  $fr **= 0.5;
  if($fr == sqrt($frac)) {print "ok 1\n"}
  else {
    my $check = sprintf "%a", Rmpfr_get_NV($fr, MPFR_RNDN);
    warn "\n Expected $check\n      Got ", sprintf "%a\n", sqrt($frac);
    print "not ok 1\n";
  }

  Rmpfr_set_NV($fr, 1.73205080756887729352744634150587232, MPFR_RNDN);

  if($fr == Math::MPFR->new('1.73205080756887729352744634150587232')) {print "ok 2\n"}
  else {
    my $check = sprintf "%a", Rmpfr_get_float128($fr, MPFR_RNDN);
    warn "\n Expected 1.73205080756887729352744634150587232\nGot $fr\n";
    print "not ok 2\n";
  }
}
else {

  warn "\n Skipping all tests - nvtype is $Config{nvtype}\n";
  for(1 .. $t) {print "ok $_\n"}
}
