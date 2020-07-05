#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;

my $file = 'samples/IP-COUNTRY-REGION-CITY-LATITUDE-LONGITUDE-ZIPCODE-TIMEZONE-ISP-DOMAIN-NETSPEED-AREACODE-WEATHER-MOBILE-ELEVATION-USAGETYPE-SAMPLE.BIN';

if ( ! -f $file ) {
	plan skip_all => "get DB24 sample file from ip2location.com to run this test";
} else {
	plan tests => 23;
}

use_ok( 'Geo::IP2Location::Lite' );

my $obj = Geo::IP2Location::Lite->open( $file );
my $ip  = '85.5.10.0';

my $country = $obj->get_country_short( $ip );

cmp_deeply( [ $obj->get_country( $ip ) ],[ 'CH','Switzerland' ],'get_country' );
is( $obj->get_country_short( $ip ),'CH','get_country_short' );
is( $obj->get_country_long( $ip ),'Switzerland','get_country_long' );
is( $obj->get_region( $ip ),'Ticino','get_region' );
ok( $obj->get_city( $ip ),'get_city' );
is( $obj->get_isp( $ip ),'Bluewin is an LIR and ISP in Switzerland.','get_isp' );
ok( $obj->get_latitude( $ip ),'get_latitude' );
ok( $obj->get_zipcode( $ip ),'get_zipcode' );
ok( $obj->get_longitude( $ip ),'get_longitude' );
is( $obj->get_domain( $ip ),'bluewin.ch','get_domain' );
ok( $obj->get_timezone( $ip ),'get_timezone' );
is( $obj->get_netspeed( $ip ),'DSL','get_netspeed' );
is( $obj->get_iddcode( $ip ),'41','get_iddcode' );
is( $obj->get_areacode( $ip ),'091','get_areacode' );
ok( $obj->get_weatherstationcode( $ip ),'get_weatherstationcode' );
ok( $obj->get_weatherstationname( $ip ),'get_weatherstationname' );
is( $obj->get_mcc( $ip ),'228','get_mcc' );
is( $obj->get_mnc( $ip ),'01','get_mnc' );
is( $obj->get_mobilebrand( $ip ),'Swisscom','get_mobilebrand' );
ok( $obj->get_elevation( $ip ),'get_elevation' );
is( $obj->get_usagetype( $ip ),'ISP/MOB','get_usagetype' );

cmp_deeply(
	[ $obj->get_all( $ip ) ],
	[
		'CH',
		'Switzerland',
		'Ticino',
		ignore(),
		'Bluewin is an LIR and ISP in Switzerland.',
		ignore(),
		ignore(),
		'bluewin.ch',
		ignore(),
		ignore(),
		'DSL',
		'41',
		'091',
		ignore(),
		ignore(),
		'228',
		'01',
		'Swisscom',
		ignore(),
		'ISP/MOB'
	],
);
