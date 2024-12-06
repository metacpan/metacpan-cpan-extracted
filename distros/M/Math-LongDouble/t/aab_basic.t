use warnings;
use strict;
use Math::LongDouble qw(:all);

print "1..1\n";


if($Math::LongDouble::VERSION eq '0.26' && Math::LongDouble::_get_xs_version() eq $Math::LongDouble::VERSION) {print "ok 1\n"}
else {print "not ok 1 $Math::LongDouble::VERSION ", Math::LongDouble::_get_xs_version(), "\n"}

# NAN_POW_BUG

if(Math::LongDouble::_nan_pow_bug()) {warn "\nNAN_POW_BUG is defined\n"}
else {warn "\nNAN_POW_BUG is NOT defined\n"}

# NANL_IS_UNAVAILABLE

if(Math::LongDouble::_have_nanl()) {warn "NANL_IS_UNAVAILABLE is NOT defined\n"}
else {warn "NANL_IS_UNAVAILABLE is defined\n"}

# ISNANL_IS_UNAVAILABLE

if(Math::LongDouble::_have_isnanl()) {warn "ISNANL_IS_UNAVAILABLE is NOT defined\n"}
else {warn "ISNANL_IS_UNAVAILABLE is defined\n"}

# SIGNBITL_IS_UNAVAILABLE

if(Math::LongDouble::_have_signbitl()) {warn "SIGNBITL_IS_UNAVAILABLE is NOT defined\n"}
else {warn "SIGNBITL_IS_UNAVAILABLE is defined\n"}

# SINCOSL_IS_UNAVAILABLE

if(Math::LongDouble::_sincosl_status() =~ /built with sincosl function/) {
  warn "SINCOSL_IS_UNAVAILABLE is NOT defined\n";
}
else {
  warn "SINCOSL_IS_UNAVAILABLE is defined\n";
}

warn "Actual nvsize == ", Math::LongDouble::_get_actual_nvsize(), "\n";
warn "Actual long double size = ", Math::LongDouble::_get_actual_ldblsize(), "\n"

