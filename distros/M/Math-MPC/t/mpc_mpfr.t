use warnings;
use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);

print "1..2\n";

if(Math::MPFR::_has_longlong() == Math::MPC::_has_longlong()) {print "ok 1\n"}
else {print "not ok 1 - Math::MPFR and Math::MPC have been built with different characteristics re the handling of 64 bit long longs. This is likely to cause problems\n"}

if(Math::MPFR::_has_longdouble() == Math::MPC::_has_longdouble()) {print "ok 2\n"}
else {print "not ok 2 - Math::MPFR and Math::MPC have been built with different characteristics re the handling of long doubles. This is likely to cause problems\n"}

