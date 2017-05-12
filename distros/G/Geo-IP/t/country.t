use strict;
use warnings;

use Geo::IP;

use Test::More;

my $gi = Geo::IP->open( 't/data/GeoIP.dat', GEOIP_STANDARD );

is(
    $gi->country_code_by_addr('64.17.254.216'), 'US',
    'expected country code'
);

is(
    $gi->country_name_by_addr('64.17.254.216'), 'United States',
    'expected country name'
);

done_testing();
