use warnings;
use strict;
use Math::MPFR qw(:mpfr);

print "1..21\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

my $version = RMPFR_VERSION_NUM(MPFR_VERSION_MAJOR, MPFR_VERSION_MINOR, MPFR_VERSION_PATCHLEVEL);

if($version == MPFR_VERSION) {print "ok 1\n"}
else {
  print "not ok 1 $version ", MPFR_VERSION, "\n";
}

if(MPFR_VERSION_MAJOR >= 2) {print "ok 2\n"}
else {print "not ok 2 MPFR_VERSION_MAJOR is ", MPFR_VERSION_MAJOR, "\n"}

if(MPFR_VERSION_MINOR >= 2 || MPFR_VERSION_MAJOR >= 3) {print "ok 3\n"}
else {print "not ok 3 MPFR_VERSION_MINOR is ", MPFR_VERSION_MINOR, " MPFR_VERSION_MAJOR is ", MPFR_VERSION_MAJOR, "\n"}

if(MPFR_VERSION_PATCHLEVEL >= 0) {print "ok 4\n"}
else {print "not ok 4 MPFR_VERSION_PATCHLEVEL is ", MPFR_VERSION_PATCHLEVEL, "\n"}

my $v = Rmpfr_get_version();

if($v eq MPFR_VERSION_STRING) {print "ok 5\n"}
else {print "not ok 5 $v is not the same as ", MPFR_VERSION_STRING, "\n"}

eval{my $patches = Rmpfr_get_patches();};
if(!$@) {print "ok 6\n"}
else {print "not ok 6 $@\n"}

# We now check that all of the "constants" (actually subroutines) listed
# in MPFR.pm in 'use subs' are parsed as intended.

my $arb = 3;

if(MPFR_VERSION < MPFR_VERSION + $arb) {print "ok 7\n"}
else {print "not ok 7\n"}

if(MPFR_VERSION_MAJOR < MPFR_VERSION_MAJOR + $arb) {print "ok 8\n"}
else {print "not ok 8\n"}

if(MPFR_VERSION_MINOR < MPFR_VERSION_MINOR + $arb) {print "ok 9\n"}
else {print "not ok 9\n"}

if(MPFR_VERSION_PATCHLEVEL < MPFR_VERSION_PATCHLEVEL + $arb) {print "ok 10\n"}
else {print "not ok 10\n"}

{
  no warnings 'numeric';
  if(MPFR_VERSION_STRING < MPFR_VERSION_STRING + $arb) {print "ok 11\n"}
  else {print "not ok 11\n"}
}

if(RMPFR_PREC_MIN < RMPFR_PREC_MIN + $arb) {print "ok 12\n"}
else {print "not ok 12\n"}

if(RMPFR_PREC_MAX < RMPFR_PREC_MAX + $arb) {print "ok 13\n"}
else {print "not ok 13\n"}

if(MPFR_DBL_DIG < MPFR_DBL_DIG + $arb) {print "ok 14\n"}
else {print "not ok 14\n"}

if(MPFR_LDBL_DIG < MPFR_LDBL_DIG + $arb) {print "ok 15\n"}
else {print "not ok 15\n"}

{
  no warnings 'uninitialized';
  if(MPFR_FLT128_DIG < MPFR_FLT128_DIG + $arb) {print "ok 16\n"}
  else {print "not ok 16\n"}
}

if(Math::MPFR::GMP_LIMB_BITS < Math::MPFR::GMP_LIMB_BITS + $arb) {print "ok 17\n"}
else {print "not ok 17\n"}

if(Math::MPFR::GMP_NAIL_BITS < Math::MPFR::GMP_NAIL_BITS + $arb) {print "ok 18\n"}
else {print "not ok 18\n"}

eval{my $p = MPFR_DBL_DIG;};

if(!$@) {
  if(defined(MPFR_DBL_DIG)) {
    warn "\nFYI:\n DBL_DIG = ", MPFR_DBL_DIG, "\n";
  }
  else {
    warn "\nFYI:\n DBL_DIG not defined\n";
  }
  print "ok 19\n";
}
else {
  warn "\$\@: $@";
  print "not ok 19\n";
}

eval{my $lp = MPFR_LDBL_DIG;};

if(!$@) {
  if(defined(MPFR_LDBL_DIG)) {
    warn  "\nFYI:\n LDBL_DIG = ", MPFR_LDBL_DIG, "\n";
  }
  else {
    warn "\nFYI:\n LDBL_DIG not defined\n";
  }
  print "ok 20\n";
}
else {
  warn "\$\@: $@";
  print "not ok 20\n";
}

eval{my $f128p = MPFR_FLT128_DIG;};

if(!$@) {
  if(defined(MPFR_FLT128_DIG)) {
    warn  "\nFYI:\n FLT128_DIG = ", MPFR_FLT128_DIG, "\n";
  }
  else {
    warn "\nFYI:\n FLT128_DIG not defined\n";
  }
  print "ok 21\n";
}
else {
  warn "\$\@: $@";
  print "not ok 21\n";
}
