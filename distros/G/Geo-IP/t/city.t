use strict;
use warnings;

use Geo::IP;

use Test::More;

my $gi = Geo::IP->open( 't/data/GeoIPCity.dat', GEOIP_STANDARD );

my $record = $gi->record_by_addr('64.17.254.216');

is( $record->area_code,     310,          'expexted area code' );
is( $record->city,          'El Segundo', 'expected city' );
is( $record->country_code,  'US',         'expected country code' );
is( $record->country_code3, 'USA',        'expected 3 letter country code' );
is( $record->country_name, 'United States',       'expected country name' );
is( $record->dma_code,     803,                   'expected DMA code' );
is( $record->latitude,     33.9164,               'expected latitude' );
is( $record->longitude,    '-118.4040',           'expected longitude' );
is( $record->metro_code,   803,                   'expected metro code' );
is( $record->postal_code,  '90245',               'expected postal code' );
is( $record->region,       'CA',                  'expeced region' );
is( $record->region_name,  'California',          'expected region name' );
is( $record->time_zone,    'America/Los_Angeles', 'expected time zone' );

done_testing();
