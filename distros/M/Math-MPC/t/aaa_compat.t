use Math::MPC qw(:mpc);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..3\n";

if(Math::MPC::_has_longdouble() == Math::MPFR::_has_longdouble()) {print "ok 1\n"}
else {
  warn "\n  Math::MPC and Math::MPFR treat NVs (floating point values) differently.\n",
       "  This breaks assumptions that have been made - and could result\n",
       "  in failing tests and/or strange behaviour. It is recommended that\n",
       "  both modules be built in the same way as regards support of long\n",
       "  doubles - see the Makefile.PL for information on how to control this\n";
  print "not ok 1\n";
}

if(Math::MPC::_has_longlong() == Math::MPFR::_has_longlong()) {print "ok 2\n"}
else {
  warn "\n  Math::MPC and Math::MPFR treat IVs (integers) differently.\n",
       "  This breaks assumptions that have been made - and could result\n",
       "  in failing tests and/or strange behaviour. It is recommended that\n",
       "  both modules be built in the same way as regards support of long\n",
       "  longs - see the Makefile.PL for information on how to control this\n";
  print "not ok 2\n";
}

my $hv = MPC_HEADER_V_STR;
my $lv = Rmpc_get_version();

# If header and library versions don't match, warn about this.
# Should we also register a failed test here if they don't match ?
# (Currently we merely warn.)

if($hv ne $lv) {
  warn "\n MPC header version ($hv) differs from MPC library version ($lv).\n",
       " This should be avoided - even if there are no test failures and/or other\n",
       " subsequent problems\n";
}

print "ok 3\n";



