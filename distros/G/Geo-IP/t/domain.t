use strict;
use warnings;

use Geo::IP;

use Test::More;

my $gi = Geo::IP->open( 't/data/GeoIPDomain.dat', GEOIP_STANDARD );

is(
    $gi->name_by_addr('67.43.156.0'), 'shoesfin.NET',
    'expected domain name'
);

done_testing();
