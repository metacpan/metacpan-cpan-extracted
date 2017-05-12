use strict;
use warnings;

use Geo::IP;

use Test::More;

my $gi = Geo::IP->open( 't/data/GeoIPNetSpeedCell.dat', GEOIP_STANDARD );

is( $gi->name_by_addr('2.125.160.1'), 'Dialup', 'expected "speed"' );

done_testing();
