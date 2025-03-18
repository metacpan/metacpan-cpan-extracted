use warnings;
use strict;
use Config;
use Math::GMPq qw(__GNU_MP_VERSION __GNU_MP_VERSION_MINOR __GNU_MP_VERSION_PATCHLEVEL);
use Math::GMPq::V;

my $tests = 9;
# Skip 2 tests for MSVC-built perls as vcpkg-builds of gmp
# may not define __GMP_CC and__GMP_CFLAGS.
my $skip = $^O =~ /MSWin/ && $Config{cc} eq 'cl' ? 2 : 0;
$tests -= $skip;

print "1..$tests\n";

warn "\n# Using Math::GMPq version ", $Math::GMPq::VERSION, "\n";
warn "# Using gmp library version ", Math::GMPq::gmp_v(), "\n";
warn "# CC is ", Math::GMPq::__GMP_CC, "\n" if defined Math::GMPq::__GMP_CC;
warn "# CFLAGS are ", Math::GMPq::__GMP_CFLAGS, "\n" if defined Math::GMPq::__GMP_CFLAGS;
warn "# GMP_LIMB_BITS is ", Math::GMPq::GMP_LIMB_BITS, "\n" if defined Math::GMPq::GMP_LIMB_BITS;
warn "# GMP_NAIL_BITS is ", Math::GMPq::GMP_NAIL_BITS, "\n" if defined Math::GMPq::GMP_NAIL_BITS;
warn "# INT_MIN  : ", Math::GMPq::_int_min(),   "\n";
warn "# INT_MAX  : ", Math::GMPq::_int_max(),   "\n";
warn "# UINT_MAX : ", Math::GMPq::_uint_max(),  "\n";
warn "# LONG_MIN : ", Math::GMPq::_long_min(),  "\n";
warn "# LONG_MAX : ", Math::GMPq::_long_max(),  "\n";
warn "# ULONG_MAX: ", Math::GMPq::_ulong_max(), "\n";
warn "# REQUIRED_LDBL_MANT_DIG: ", Math::GMPq::_required_ldbl_mant_dig(), "\n";
warn "# GMPQ_WIN32_FMT_BUG: ", Math::GMPq::V::_buggy(), "\n";

if($Math::GMPq::VERSION eq '0.64' && $Math::GMPq::Random::VERSION eq '0.64' &&
   $Math::GMPq::V::VERSION eq '0.64' &&
   Math::GMPq::_get_xs_version() eq $Math::GMPq::VERSION) {print "ok 1\n"}
else {print "not ok 1 $Math::GMPq::VERSION $Math::GMPq::Random::VERSION $Math:::GMPq::V::VERSION ", Math::GMPq::_get_xs_version(), "\n"}

my @version = split /\./, Math::GMPq::gmp_v();

if(scalar(@version) == 3) {print "ok 2\n"}
else {print "not ok 2\n"}

if (__GNU_MP_VERSION == $version[0]) {print "ok 3\n"}
else {print "not ok 3\n"}

if (__GNU_MP_VERSION_MINOR == $version[1]) {print "ok 4\n"}
else {print "not ok 4\n"}

if (__GNU_MP_VERSION_PATCHLEVEL == $version[2]) {print "ok 5\n"}
else {print "not ok 5\n"}

eval {Math::GMPq::__GMP_CC;};
unless($@) {print "ok 6\n"}
else {
  warn "$@\n";
  print "not ok 6\n"
}

eval {Math::GMPq::__GMP_CFLAGS;};
unless($@) {print "ok 7\n"}
else {
  warn "$@\n";
  print "not ok 7\n"
}

unless($skip) {
  my $version_num = version_num(__GNU_MP_VERSION, __GNU_MP_VERSION_MINOR, __GNU_MP_VERSION_PATCHLEVEL);

  print $version_num < 262659 ? !defined(Math::GMPq::__GMP_CC) ? "ok 8\n" : "not ok 8\n"
                              :  defined(Math::GMPq::__GMP_CC) ? "ok 8\n" : "not ok 8\n";

  print $version_num < 262659 ? !defined(Math::GMPq::__GMP_CFLAGS) ? "ok 9\n" : "not ok 9\n"
                              :  defined(Math::GMPq::__GMP_CFLAGS) ? "ok 9\n" : "not ok 9\n";
}

sub version_num {
    return ($_[0] << 16) | ($_[1] << 8) | $_[2];
}
