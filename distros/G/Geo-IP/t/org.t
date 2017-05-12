use strict;
use warnings;

use Geo::IP;

use Test::More;

my $gi = Geo::IP->open( 't/data/GeoIPOrg.dat', GEOIP_STANDARD );

is(
    $gi->org_by_addr('12.87.118.0'), 'AT&T Worldnet Services',
    'expected org'
);

done_testing();
