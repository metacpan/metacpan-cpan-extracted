use warnings;
use strict;
use Math::MPFR qw(:mpfr);

print "1..6\n";

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

