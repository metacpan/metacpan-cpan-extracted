use warnings;
use strict;

print "1..1\n";

eval {use Math::GMPz::V;};

if($@) {
  warn "\$\@: $@";
  print "not ok 1\n";
}
else {
  warn "\nGMP Header version (major): ", Math::GMPz::V::___GNU_MP_VERSION(), "\n";
  warn "GMP Header version (minor): ", Math::GMPz::V::___GNU_MP_VERSION_MINOR(), "\n";
  warn "GMP Header version (patchlevel): ", Math::GMPz::V::___GNU_MP_VERSION_PATCHLEVEL(), "\n";
  #warn "GMP Library version: ", Math::GMPz::V::gmp_v(), "\n";
  warn "GMP CC: ", Math::GMPz::V::___GMP_CC(), "\n";
  warn "GMP CFLAGS: ", Math::GMPz::V::___GMP_CFLAGS(), "\n";
  print "ok 1\n";
}

my($h_major, $h_minor) = (Math::GMPz::V::___GNU_MP_VERSION(), Math::GMPz::V::___GNU_MP_VERSION_MINOR());

if(($h_major < 4) ||
   ($h_major == 4 && $h_minor < 2)) {
   warn "\n\n      Your GMP Header version is outdated and unsupported.\n",
        "      REMAINING TEST SUITE WILL POSSIBLY FAIL !!!!\n";
}


