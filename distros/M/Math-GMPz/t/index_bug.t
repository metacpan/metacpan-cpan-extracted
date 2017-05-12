# Maximum index that can be passed to mpz_setbit, mpz_tstbit, mpz_combit,
# mpz_clrbit, mpz_scan0 and mpz_scan1 is ULONG_MAX.
# If longsize < ivsize, then we need to croak if the UV arg is greater than
# ULONG_MAX. (We assume this gmp behaviour will be fixed in gmp-7.)
# This script checks that the error is being caught.

use strict;
use warnings;
use Config;
use Math::GMPz qw(:mpz);

if($Config{longsize} < $Config{ivsize} && 6 >= Math::GMPz::__GNU_MP_VERSION) {

  print "1..7\n";

  if(Math::GMPz::_gmp_index_overflow()) {print "ok 1\n"}
  else {
    warn "_gmp_index_overlow unexpectedly returned false\n";
    print "not ok 1\n";
  }

  my $z = Math::GMPz->new(1);

  eval{my $bit = Rmpz_tstbit($z, 4294967296);};

  if($@ =~ /is greater than maximum allowed value \(4294967295\)/) {print "ok 2\n"}
  else {
    warn "\n \$\@: $@\n";
    print "not ok 2\n";
  }

  eval{my $bit = Rmpz_scan0($z, 4294967296);};

  if($@ =~ /is greater than maximum allowed value \(4294967295\)/) {print "ok 3\n"}
  else {
    warn "\n \$\@: $@\n";
    print "not ok 3\n";
  }

  eval{my $bit = Rmpz_scan1($z, 4294967296);};

  if($@ =~ /is greater than maximum allowed value \(4294967295\)/) {print "ok 4\n"}
  else {
    warn "\n \$\@: $@\n";
    print "not ok 4\n";
  }

  eval{Rmpz_setbit($z, 4294967296);};

  if($@ =~ /is greater than maximum allowed value \(4294967295\)/) {print "ok 5\n"}
  else {
    warn "\n \$\@: $@\n";
    print "not ok 5\n";
  }

  eval{Rmpz_clrbit($z, 4294967296);};

  if($@ =~ /is greater than maximum allowed value \(4294967295\)/) {print "ok 6\n"}
  else {
    warn "\n \$\@: $@\n";
    print "not ok 6\n";
  }

  eval{Rmpz_combit($z, 4294967296);};

  if($@ =~ /is greater than maximum allowed value \(4294967295\)/) {print "ok 7\n"}
  else {
    warn "\n \$\@: $@\n";
    print "not ok 7\n";
  }

}

else {

  print "1..1\n";

  if(!Math::GMPz::_gmp_index_overflow()) {print "ok 1\n"}
  else {
    warn "_gmp_index_overlow unexpectedly returned true\n";
    print "not ok 1\n";
  }

}
