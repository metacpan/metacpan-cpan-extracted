use warnings;
use strict;
use Math::Random::BlumBlumShub qw(:all);

print "1..1\n";


if($Math::Random::BlumBlumShub::VERSION eq '0.06' && Math::Random::BlumBlumShub::_get_xs_version() eq $Math::Random::BlumBlumShub::VERSION) {print "ok 1\n"}
else {print "not ok 1 $Math::Random::BlumBlumShub::VERSION ", Math::Random::BlumBlumShub::_get_xs_version(), "\n"}

