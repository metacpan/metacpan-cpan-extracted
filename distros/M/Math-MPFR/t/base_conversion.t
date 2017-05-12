use strict;
use warnings;
use Math::MPFR qw(:mpfr);

print "1..11\n";

eval{my $p = MPFR_DBL_DIG;};

if(!$@) {
  if(defined(MPFR_DBL_DIG)) {
    warn "\nFYI:\n DBL_DIG = ", MPFR_DBL_DIG, "\n";
  }
  else {
    warn "\nFYI:\n DBL_DIG not defined\n";
  }
  print "ok 1\n";
}
else {
  warn "\$\@: $@";
  print "not ok 1\n";
}

eval{my $lp = MPFR_LDBL_DIG;};

if(!$@) {
  if(defined(MPFR_LDBL_DIG)) {
    warn  "\nFYI:\n LDBL_DIG = ", MPFR_LDBL_DIG, "\n";
  }
  else {
    warn "\nFYI:\n LDBL_DIG not defined\n";
  }
  print "ok 2\n";
}
else {
  warn "\$\@: $@";
  print "not ok 2\n";
}

eval{my $f128p = MPFR_FLT128_DIG;};

if(!$@) {
  if(defined(MPFR_FLT128_DIG)) {
    warn  "\nFYI:\n FLT128_DIG = ", MPFR_FLT128_DIG, "\n";
  }
  else {
    warn "\nFYI:\n FLT128_DIG not defined\n";
  }
  print "ok 3\n";
}
else {
  warn "\$\@: $@";
  print "not ok 3\n";
}

if(mpfr_max_orig_len(10, 2, 55) == 16){print "ok 4\n"}
else {
  warn "\n4: Got ", mpfr_max_orig_len(10, 2, 55), "\nExpected 16\n";
  print "not ok 4\n";
}

if(mpfr_max_orig_len(2, 10, 17) == 53){print "ok 5\n"}
else {
  warn "\n5: Got ", mpfr_max_orig_len(2, 10, 17), "\nExpected 53\n";
  print "not ok 5\n";
}

if(mpfr_min_inter_prec(2, 53, 10) == 17) {print "ok 6\n"}
else {
  warn "\n6: Got ", mpfr_min_inter_prec(2, 53, 10), "\nExpected 17\n";
  print "not ok 6\n";
}

if(mpfr_min_inter_prec(10, 16, 2) == 55) {print "ok 7\n"}
else {
  warn "\n7: Got ", mpfr_min_inter_prec(10, 16, 2), "\nExpected 55\n";
  print "not ok 7\n";
}

if(mpfr_max_orig_base(53, 10, 17) == 2) {print "ok 8\n"}
else {
  warn "\n8: Got ", mpfr_max_orig_base(53, 10, 17), "\nExpected 2\n";
  print "not ok 8\n";
}

if(mpfr_max_orig_base(16, 2, 55) == 10) {print "ok 9\n"}
else {
  warn "\n9: Got ", mpfr_max_orig_base(16, 2, 55), "\nExpected 10\n";
  print "not ok 9\n";
}

if(mpfr_min_inter_base(10, 16, 55) ==2) {print "ok 10\n"}
else {
  warn "\n10: Got ", mpfr_min_inter_base(10, 16, 55), "\nExpected 2\n";
  print "not ok 10\n";
}

if(mpfr_min_inter_base(2, 53, 17) ==10) {print "ok 11\n"}
else {
  warn "\n11: Got ", mpfr_min_inter_base(2, 53, 17), "\nExpected 10\n";
  print "not ok 11\n";
}
