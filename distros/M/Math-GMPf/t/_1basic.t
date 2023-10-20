use warnings;
use strict;
use Math::GMPf qw(__GNU_MP_VERSION __GNU_MP_VERSION_MINOR __GNU_MP_VERSION_PATCHLEVEL);
use Math::GMPf::V;

print "1..9\n";

warn "\n# Using Math::GMPf version ", $Math::GMPf::VERSION, "\n";
warn "# Using gmp library version ", Math::GMPf::gmp_v(), "\n";
warn "# CC is ", Math::GMPf::__GMP_CC, "\n" if defined Math::GMPf::__GMP_CC;
warn "# CFLAGS are ", Math::GMPf::__GMP_CFLAGS, "\n" if defined Math::GMPf::__GMP_CFLAGS;
warn "# GMP_LIMB_BITS is ", Math::GMPf::GMP_LIMB_BITS, "\n" if defined Math::GMPf::GMP_LIMB_BITS;
warn "# GMP_NAIL_BITS is ", Math::GMPf::GMP_NAIL_BITS, "\n" if defined Math::GMPf::GMP_NAIL_BITS;

if($Math::GMPf::VERSION eq '0.52' && $Math::GMPf::Random::VERSION eq '0.52' &&
   $Math::GMPf::V::VERSION eq '0.52' &&
   Math::GMPf::_get_xs_version() eq $Math::GMPf::VERSION) {print "ok 1\n"}
else {
  warn "$Math::GMPf::VERSION $Math::GMPf::Random::VERSION $Math::GMPf::V::VERSION ",
        Math::GMPf::_get_xs_version(), "\n";
  print "not ok 1\n";
}

my @version = split /\./, Math::GMPf::gmp_v();

if(scalar(@version) == 3) {print "ok 2\n"}
else {print "not ok 2\n"}

if (__GNU_MP_VERSION == $version[0]) {print "ok 3\n"}
else {print "not ok 3\n"}

if (__GNU_MP_VERSION_MINOR == $version[1]) {print "ok 4\n"}
else {print "not ok 4\n"}

if (__GNU_MP_VERSION_PATCHLEVEL == $version[2]) {print "ok 5\n"}
else {print "not ok 5\n"}

eval {Math::GMPf::__GMP_CC;};
unless($@) {print "ok 6\n"}
else {
  warn "$@\n";
  print "not ok 6\n"
}

eval {Math::GMPf::__GMP_CFLAGS;};
unless($@) {print "ok 7\n"}
else {
  warn "$@\n";
  print "not ok 7\n"
}

my $version_num = version_num(__GNU_MP_VERSION, __GNU_MP_VERSION_MINOR, __GNU_MP_VERSION_PATCHLEVEL);

print $version_num < 262659 ? !defined(Math::GMPf::__GMP_CC) ? "ok 8\n" : "not ok 8\n"
                            :  defined(Math::GMPf::__GMP_CC) ? "ok 8\n" : "not ok 8\n";

print $version_num < 262659 ? !defined(Math::GMPf::__GMP_CFLAGS) ? "ok 9\n" : "not ok 9\n"
                            :  defined(Math::GMPf::__GMP_CFLAGS) ? "ok 9\n" : "not ok 9\n";


sub version_num {
    return ($_[0] << 16) | ($_[1] << 8) | $_[2];
}
