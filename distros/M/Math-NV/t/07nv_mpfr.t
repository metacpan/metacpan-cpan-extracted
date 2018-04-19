
# NV.pm will always load Math::MPFR iff it's available.
# Math::NV::no_mpfr will be set to 0 iff Math::MPFR loaded successfully.
# Otherwise $Math::NV::no_mpfr will be set to the error message that the
# attempt to load Math::MPFR produced.

use strict;
use warnings;
use Math::NV qw(:all);


print "1..11\n";

my $arb = 1021;
Math::MPFR::Rmpfr_set_default_prec($arb);

my $val = nv_mpfr('1e+127', 106);

if(lc((@$val)[0]) eq "5a4d8ba7f519c84f") {print "ok 1\n"}
else {
  warn "expected \"5a4d8ba7f519c84f\", got ", lc((@$val)[0]), "\n";
  print "not ok 1\n";
}

if(lc((@$val)[1]) eq "56e7fd1f28f89c56") {print "ok 2\n"}
else {
  warn "expected \"56e7fd1f28f89c56\", got ", lc((@$val)[1]), "\n";
  print "not ok 2\n";
}

$val = nv_mpfr('1e+129', 106);

if(lc((@$val)[0]) eq "5ab7151b377c247e") {print "ok 3\n"}
else {
  warn "expected \"5ab7151b377c247e\", got ", lc((@$val)[0]), "\n";
  print "not ok 3\n";
}

if(lc((@$val)[1]) eq "5707b80b0047445d") {print "ok 4\n"}
else {
  warn "expected \"5707b80b0047445d\", got ", lc((@$val)[1]), "\n";
  print "not ok 4\n";
}

eval {$val = nv_mpfr('1.3', 1000);};

if($@ =~ /^Unrecognized value for bits/) {print "ok 5\n"}
else {
  warn "\n\$\@: $@";
  print "not ok 5\n";
}

eval {$val = nv_mpfr('1.3', 10);};
if($@ =~ /^Unrecognized value for bits/) {print "ok 6\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 6\n";
}

#####################################

$val =     nv_mpfr('2.3', mant_dig());
my $val2 = nv_mpfr('2.3');

if(mant_dig == 106) {
  if("@$val" eq "@$val2") {print "ok 7\n"}
  else {
    warn "\nexpected\n@$val eq\n@$val2\n";
    print "not ok 7\n";
  }
}
else {
  if($val eq $val2) {print "ok 7\n"}
  else {
    warn "\nexpected $val, got $val2\n";
    print "not ok 7\n";
  }
}

$val = nv_mpfr('1e+127', 53);

if(lc($val) eq "5a4d8ba7f519c84f") {print "ok 8\n"}
else {
  warn "expected \"5a4d8ba7f519c84f\", got ", lc($val), "\n";
  print "not ok 8\n";
}

if(106 == mant_dig()) {
  warn "\nSkipping tests 9 and 10 for double-double platform\n";
  print "ok 9\nok 10\n";
}

else {
  eval{$val = nv_mpfr('1e+127', 64);};

  if($@) {
    warn "\n Skipping test 9 as _ld_bytes() is unsupported\n";
    print "ok 9\n";
  }
  else {
    if($val =~ /^(0+)?41a4ec5d3fa8ce427b00$/i) {print "ok 9\n"}
    else {
      warn "expected \"41a4ec5d3fa8ce427b00\", got ", lc($val), "\n";
      print "not ok 9\n";
    }
  }

  eval {$val = nv_mpfr('1e+127', 113);};

  if(!$@) {
    if(lc($val) eq "41a4d8ba7f519c84f5ff47ca3e27156a") {print "ok 10\n"}
    else {
      warn "expected \"41a4d8ba7f519c84f5ff47ca3e27156a\", got ", lc($val), "\n";
      print "not ok 10\n";
    }
  }
  else {
    warn "\n Skipping test 10 as _f128_bytes() is unsupported\n";
    print "ok 10\n";
  }
}


# Check that default precison hasn't been altered
my $now = Math::MPFR::Rmpfr_get_default_prec();
if($now == $arb) {print "ok 11\n"}
else {
  warn "Default precision changed from $arb to $now\n";
  print "not ok 11\n";
}



