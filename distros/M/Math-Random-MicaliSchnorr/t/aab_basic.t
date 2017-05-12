use warnings;
use strict;
use Math::Random::MicaliSchnorr qw(:all);

print "1..1\n";


if($Math::Random::MicaliSchnorr::VERSION eq '0.06' && Math::Random::MicaliSchnorr::_get_xs_version() eq $Math::Random::MicaliSchnorr::VERSION) {print "ok 1\n"}
else {print "not ok 1 $Math::Random::MicaliSchnorr::VERSION ", Math::Random::MicaliSchnorr::_get_xs_version(), "\n"}

