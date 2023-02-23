use warnings;
use strict;
use Config;
use Math::MPFR qw(:mpfr);


my $test_nv1 = 1.0;
my $test_nv2 = $test_nv1 + (2 ** -1000);

if($test_nv2 > $test_nv1 && Math::MPFR::_has_longdouble()) {

  print "1..3\n";

  my $fr = Rmpfr_init2(106);

  Rmpfr_set_ld($fr, $test_nv2, MPFR_RNDN);

  if($fr == $test_nv2) {print "not ok 1\n"}
  else {print "ok 1\n"}

  my $check = Rmpfr_get_ld($fr, MPFR_RNDN);

  if($check == $test_nv2) {print "not ok 2\n"}
  else {print "ok 2\n"}

  if(Math::MPFR::_required_ldbl_mant_dig() == 2098) {print "ok 3\n"}
  else {
    warn "\n expected 2098, got ", Math::MPFR::_required_ldbl_mant_dig(), "\n";
    print "not ok 3\n";
  }
}
else {
  print "1..1\n";
  warn "\nnot a Double-Double build.\nLDBL_MANT_DIG is ", Math::MPFR::_required_ldbl_mant_dig() == 2098 ? 106 : Math::MPFR::_required_ldbl_mant_dig() , "\n";

  if(Math::MPFR::_required_ldbl_mant_dig() == 64   ||
     Math::MPFR::_required_ldbl_mant_dig() == 2098 ||
     Math::MPFR::_required_ldbl_mant_dig() == 113  ||
     Math::MPFR::_required_ldbl_mant_dig() == 53     ) {print "ok 1\n"}
  else {
    warn "\n expected 2098, 64 or 53 - got ", Math::MPFR::_required_ldbl_mant_dig(), "\n";
    print "not ok 1\n";
  }
}
