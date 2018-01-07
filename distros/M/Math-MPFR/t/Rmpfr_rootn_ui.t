
use strict;
use warnings;
use Math::MPFR qw(:mpfr);

if(4 > MPFR_VERSION_MAJOR) {
  print "1..1\n";
  my $rop = Math::MPFR->new();
  eval {Rmpfr_rootn_ui($rop, Math::MPFR->new(3), 7, MPFR_RNDN);};
  if($@ =~ /Rmpfr_rootn_ui not implemented/) {print "ok 1\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 1\n";
  }
}

else {

  print "1..3\n";

  my $rop1 = Math::MPFR->new();
  my $rop2 = Math::MPFR->new();
  my $op = Math::MPFR->new(10);

  Rmpfr_rootn_ui($rop1, $op, 0, MPFR_RNDN);

  if(Rmpfr_nan_p($rop1)) {print "ok 1\n"}
  else {
    warn "\nExpected NaN, got $rop1\n";
    print "not ok 1\n";
  }

  my $inex1 = Rmpfr_rootn_ui($rop1, $op, 3, MPFR_RNDN);
  my $inex2 = Rmpfr_cbrt($rop2, $op, MPFR_RNDN);

  if($inex1 * $inex2 > 0) {print "ok 2\n"}
  else {
    warn "\n\$inex1: $inex1\n\$inex2: $inex2\n";
    print "not ok 2\n";
  }

  if($rop1 == $rop2) {print "ok 3\n"}
  else {
    warn "\n\$rop1: $rop1\n\$rop2: $rop2\n";
    print "not ok 3\n";
  }
}

