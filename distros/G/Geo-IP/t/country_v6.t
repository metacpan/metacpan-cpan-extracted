use strict;
use warnings;

use Geo::IP;

use Test::More;

if ( Geo::IP->api eq 'PurePerl' and $] < 5.014 ) {
    plan skip_all => 'perl provides ipv6 functions from version 5.14';
}

my $gi = Geo::IP->open( 't/data/GeoIPv6.dat', GEOIP_STANDARD );

is(
    $gi->country_code_by_addr_v6('2001:200::'), 'JP',
    'expected country code'
);

done_testing();
