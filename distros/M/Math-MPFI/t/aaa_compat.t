use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..2\n";

if(Math::MPFI::_has_longdouble() == Math::MPFR::_has_longdouble()) {print "ok 1\n"}
else {
  warn "\n  Math::MPFI and Math::MPFR treat NV's (doubles) differently.\n",
       "  This breaks assumptions that have been made - and could result\n",
       "  in failing tests and/or strange failures. It is recommended that\n",
       "  both modules be built in the same way as regards support of long\n",
       "  doubles - see the Makefile.PL for information on how to control this\n";
  print "not ok 1\n";
}

if(Math::MPFI::_has_longlong() == Math::MPFR::_has_longlong()) {print "ok 2\n"}
else {
  warn "\n  Math::MPFI and Math::MPFR treat IV's (integers) differently.\n",
       "  This breaks assumptions that have been made - and could result\n",
       "  in failing tests and/or strange failures. It is recommended that\n",
       "  both modules be built in the same way as regards support of long\n",
       "  longs - see the Makefile.PL for information on how to control this\n";
  print "not ok 2\n";
}
