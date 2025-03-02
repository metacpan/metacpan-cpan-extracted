use strict;
use warnings;
use Math::MPFR qw(:mpfr);

my $t = 3;

print "1..$t\n";

my($have_atonv, $mpfr_has_float128);

eval{$mpfr_has_float128 = Rmpfr_buildopt_float128_p()};

$mpfr_has_float128 = 0 if $@; # else it's whatever Rmpfr_buildopt_float128_p() returned

$have_atonv = MPFR_VERSION <= 196869 ? 0 : 1;

if($have_atonv) {

  my($nv1, $nv2, $nv3, $double);

  if($Config::Config{nvtype} eq 'double' ||
      ($Config::Config{nvtype} eq 'long double' && ($Config::Config{nvsize} == 8 ||
                                                    Math::MPFR::_required_ldbl_mant_dig() == 2098))) {
    $double = atodouble('0b0.100001e-1074');
    $nv1 = atonv('0b0.100001e-1074');
    $nv2 = atonv('4.96e-324');
    $nv3 = atonv('0x0.84p-1074');
    if($nv1 == $nv2 && $double == $nv2 && $nv2 == $nv3 && $nv1 > 0) {print "ok 1\n"}
    else {
      warn "\n \$double: $double\n \$nv1: $nv1\n \$nv2: $nv2\n \$nv3: $nv3\n";
      print "not ok 1\n";
    }

    print "ok 2\n"; # Original test removed
  }

  elsif($Config::Config{nvtype} eq 'long double' && length(sqrt(2.1)) < 25) { # Exclude IEEE 754 long double
                                                                              # from this branch.
    $nv1 = atonv('0b0.100001e-16445');
    $nv2 = atonv('3.6452e-4951');
    $nv3 = atonv('0x0.84p-16445');
    if($nv1 == $nv2 && $nv2 == $nv3 && $nv1 > 0) {print "ok 1\n"}
    else {
      warn "\n \$nv1: $nv1\n \$nv2: $nv2\n \$nv3: $nv3\n";
      print "not ok 1\n";
    }


    # Let's now check to see whether failures reported at:
    # http://www.cpantesters.org/cpan/report/d6a27d3c-2a0d-11e9-bf31-80c71e9d5857 and
    # http://www.cpantesters.org/cpan/report/f8c159e0-2a0f-11e9-bf31-80c71e9d5857
    # might represent a bug in atonv().

    if(Math::MPFR::_required_ldbl_mant_dig() == 64) {

      my $ok = 1;

      my $nv = atonv('97646e-4945');
      unless(sprintf("%.19e", $nv) eq '9.7645999998519452098e-4941') {
        warn "97646e-4945: Expected 9.7645999998519452098e-4941 Got ", sprintf("%.19e", $nv), "\n";
        $ok = 0;
      }

      $nv = atonv('7286408931649326e-4956');
      unless(sprintf("%.19e", $nv) eq '7.2864089317595630535e-4941') {
        warn "7286408931649326e-4956: Expected 7.2864089317595630535e-4941 Got ", sprintf("%.19e", $nv), "\n";
        $ok = 0;
      }

      if($ok) { print "ok 2\n"; }
      else    { print "not ok 2\n"; }
    }
    else {
      print "ok 2\n"; # Original test removed
    }
  }

  elsif($Config::Config{nvtype} eq '__float128' || $Config::Config{nvtype} eq 'long double') {
    # If nvtype is "long double" it will be the IEEE 754 long double, as the other kinds of
    # long double have already been tested in one of the preceding branches.
    # For nvtype of "__float128" we also need to verify that $mpfr_has_float128 is TRUE.
    if($mpfr_has_float128 || $Config::Config{nvtype} eq 'long double') {
      $nv1 = atonv('0b0.100001e-16494');
      $nv2 = atonv('6.5e-4966');
      $nv3 = atonv('0x0.84p-16494');
      if($nv1 == $nv2 && $nv2 == $nv3 && $nv1 > 0) {print "ok 1\n"}
      else {
        warn "\n \$nv1: $nv1\n \$nv2: $nv2\n";
        print "not ok 1\n";
      }

      print "ok 2\n"; # Original test removed
    }

    else { # The nvtype can be only "__float128".
      eval { $nv1 = atonv('0b0.100001e-16494') };
      if($@ =~ /^The atonv function is unavailable for this __float128 build/) {
        print "ok 1\n";
      }
      else {
        warn "\$\@: $@\n";
        print "not ok 1\n";
      }

      if(Math::MPFR::_MPFR_WANT_FLOAT128()) {

        # MPFR_WANT_FLOAT128 should be not defined if mpfr
        # library does not support libquadmath types

        warn "Serious inconsistency regarding mpfr library's quadmath support\n";
        print "not ok 2\n";
      }
      else {
        print "ok2\n";
      }
    }
  }

  else {
    warn "\n Unrecognized nvtype in atonv.t\n";
    print "not ok 1\nnot ok 2\n";
  }

  $nv1 = atonv('0.625');
  if($nv1 == 5 / 8) { print "ok 3\n"}
  else {
    warn "\n $nv1 != ", 5 / 8, "\n";
    print "not ok 3\n";
  }

}
else {

  eval{atonv('1234.5');};

  if($@ =~ /^The atonv function requires mpfr\-3\.1\.6 or later/) {print "ok 1\n"}
  else {
    warn "\n \$\@: $@\n";
    print "not ok 1\n";
  }

  warn "\n Skipping tests 2 to $t - nothing else to check\n";
  print "ok $_\n" for 2 .. $t;
}


