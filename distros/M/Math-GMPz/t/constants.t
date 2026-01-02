# Check that the "constants" (actually subroutines) listed in 'use subs()'
# are functional. Those subroutines are:
# __GNU_MP_VERSION __GNU_MP_VERSION_MINOR __GNU_MP_VERSION_PATCHLEVEL
# __GNU_MP_RELEASE __GMP_CC __GMP_CFLAGS GMP_LIMB_BITS GMP_NAIL_BITS
# MATH_GMPz_IV_MAX  MATH_GMPz_IV_MIN  MATH_GMPz_UV_MAX

use strict;
use warnings;
use Math::GMPz qw(:mpz __GNU_MP_VERSION __GNU_MP_VERSION_MINOR
                   __GNU_MP_VERSION_PATCHLEVEL __GNU_MP_RELEASE __GMP_CC __GMP_CFLAGS);

print "1..10\n";


if((MATH_GMPz_UV_MAX <=> MATH_GMPz_IV_MAX) == 1) {print "ok 1\n"}
else {print "not ok 1\n"}

if(MATH_GMPz_IV_MAX < MATH_GMPz_UV_MAX ) {print "ok 2\n"}
else {print "not ok 2\n"}

if(MATH_GMPz_IV_MIN < MATH_GMPz_IV_MAX ) {print "ok 3\n"}
else {print "not ok 3\n"}

if(Math::GMPz::GMP_NAIL_BITS < Math::GMPz::GMP_NAIL_BITS + 1) {print "ok 4\n"}
else {print "not ok 4\n"}

if(Math::GMPz::GMP_LIMB_BITS < Math::GMPz::GMP_LIMB_BITS + 1) {print "ok 5\n"}
else {print "not ok 5\n"}

{
  no warnings 'numeric';
  if((__GMP_CC <= __GMP_CFLAGS) && (__GMP_CFLAGS <= __GMP_CC)) {print "ok 6\n"}
  else {print "not ok 6\n"}
}

if(__GNU_MP_VERSION < __GNU_MP_VERSION + 1) {print "ok 7\n"}
else {print "not ok 7\n"}

if(__GNU_MP_VERSION_MINOR < __GNU_MP_VERSION_MINOR + 1) {print "ok 8\n"}
else {print "not ok 8\n"}

if(__GNU_MP_VERSION_PATCHLEVEL < __GNU_MP_VERSION_PATCHLEVEL + 1) {print "ok 9\n"}
else {print "not ok 9\n"}

if(__GNU_MP_RELEASE < __GNU_MP_RELEASE + 1) {print "ok 10\n"}
else {print "not ok 10\n"}
