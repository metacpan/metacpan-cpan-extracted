use strict;
use warnings;

use Geo::IP;

use Test::More;

my $gi = Geo::IP->open( 't/data/GeoIPRegion.dat', GEOIP_STANDARD );

is_deeply(
    [ $gi->region_by_addr('64.17.254.223') ], [ 'US', 'CA' ],
    'expected region and country'
);

done_testing();
