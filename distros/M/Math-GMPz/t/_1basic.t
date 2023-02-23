use warnings;
use strict;
use Math::GMPz qw(__GNU_MP_VERSION __GNU_MP_VERSION_MINOR __GNU_MP_VERSION_PATCHLEVEL MATH_GMPz_IV_MAX
                  MATH_GMPz_IV_MIN MATH_GMPz_UV_MAX);
use Math::GMPz::V;

print "1..9\n";

warn "\n# Using Math::GMPz version ", $Math::GMPz::VERSION, "\n";

eval {require Math::GMPq;};
if(!$@) {warn "# Using Math::GMPq version ", $Math::GMPq::VERSION, "\n"}
else {warn "# Math::GMPq unloadable\n"}

warn "# Using gmp library version ", Math::GMPz::gmp_v(), "\n";
warn "# CC is ", Math::GMPz::__GMP_CC, "\n" if defined Math::GMPz::__GMP_CC;
warn "# CFLAGS are ", Math::GMPz::__GMP_CFLAGS, "\n" if defined Math::GMPz::__GMP_CFLAGS;
warn "# GMP_LIMB_BITS is ", Math::GMPz::GMP_LIMB_BITS, "\n" if defined Math::GMPz::GMP_LIMB_BITS;
warn "# GMP_NAIL_BITS is ", Math::GMPz::GMP_NAIL_BITS, "\n" if defined Math::GMPz::GMP_NAIL_BITS;
warn "# MATH_GMPz_HAS_MAGICEXT is ", Math::GMPz::_magic_status(), "\n" if defined Math::GMPz::_magic_status();
warn "# MATH_GMPz_IV_MAX is ", MATH_GMPz_IV_MAX(), "\n";
warn "# MATH_GMPz_IV_MIN is ", MATH_GMPz_IV_MIN(), "\n";
warn "# MATH_GMPz_UV_MAX is ", MATH_GMPz_UV_MAX(), "\n";
warn "# LD_PRINTF_BROKEN is ", Math::GMPz::_ld_printf_broken(), "\n";

if($Math::GMPz::VERSION eq '0.56' && $Math::GMPz::Random::VERSION eq '0.56' &&
   $Math::GMPz::V::VERSION eq '0.56' &&
   Math::GMPz::_get_xs_version() eq $Math::GMPz::VERSION) {print "ok 1\n"}
else {
  print "not ok 1\n";
  warn "$Math::GMPz::VERSION $Math::GMPz::Random::VERSION ", Math::GMPz::_get_xs_version(), "\n"
}

my @version = split /\./, Math::GMPz::gmp_v();

if(scalar(@version) == 3) {print "ok 2\n"}
else {print "not ok 2\n"}

if (__GNU_MP_VERSION == $version[0]) {print "ok 3\n"}
else {print "not ok 3\n"}

if (__GNU_MP_VERSION_MINOR == $version[1]) {print "ok 4\n"}
else {print "not ok 4\n"}

if (__GNU_MP_VERSION_PATCHLEVEL == $version[2]) {print "ok 5\n"}
else {print "not ok 5\n"}

eval {Math::GMPz::__GMP_CC;};
unless($@) {print "ok 6\n"}
else {
  warn "$@\n";
  print "not ok 6\n"
}

eval {Math::GMPz::__GMP_CFLAGS;};
unless($@) {print "ok 7\n"}
else {
  warn "$@\n";
  print "not ok 7\n"
}

my $version_num = version_num(__GNU_MP_VERSION, __GNU_MP_VERSION_MINOR, __GNU_MP_VERSION_PATCHLEVEL);

print $version_num < 262659 ? !defined(Math::GMPz::__GMP_CC) ? "ok 8\n" : "not ok 8\n"
                            :  defined(Math::GMPz::__GMP_CC) ? "ok 8\n" : "not ok 8\n";

print $version_num < 262659 ? !defined(Math::GMPz::__GMP_CFLAGS) ? "ok 9\n" : "not ok 9\n"
                            :  defined(Math::GMPz::__GMP_CFLAGS) ? "ok 9\n" : "not ok 9\n";

sub version_num {
    return ($_[0] << 16) | ($_[1] << 8) | $_[2];
}
