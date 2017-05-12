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
is( $obj->get_city( $ip ),'Lugano','get_city' );
is( $obj->get_isp( $ip ),'Bluewin is an LIR and ISP in Switzerland.','get_isp' );
is( $obj->get_latitude( $ip ),'46.010078','get_latitude' );
is( $obj->get_zipcode( $ip ),'6908','get_zipcode' );
is( $obj->get_longitude( $ip ),'8.960040','get_longitude' );
is( $obj->get_domain( $ip ),'bluewin.ch','get_domain' );
is( $obj->get_timezone( $ip ),'+02:00','get_timezone' );
is( $obj->get_netspeed( $ip ),'DSL','get_netspeed' );
is( $obj->get_iddcode( $ip ),'41','get_iddcode' );
is( $obj->get_areacode( $ip ),'091','get_areacode' );
is( $obj->get_weatherstationcode( $ip ),'SZXX0020','get_weatherstationcode' );
is( $obj->get_weatherstationname( $ip ),'Lugano','get_weatherstationname' );
is( $obj->get_mcc( $ip ),'228','get_mcc' );
is( $obj->get_mnc( $ip ),'01','get_mnc' );
is( $obj->get_mobilebrand( $ip ),'Swisscom','get_mobilebrand' );
is( $obj->get_elevation( $ip ),'284','get_elevation' );
is( $obj->get_usagetype( $ip ),'ISP/MOB','get_usagetype' );

cmp_deeply(
	[ $obj->get_all( $ip ) ],
	[
		'CH',
		'Switzerland',
		'Ticino',
		'Lugano',
		'Bluewin is an LIR and ISP in Switzerland.',
		'46.010078',
		'8.960040',
		'bluewin.ch',
		'6908',
		'+02:00',
		'DSL',
		'41',
		'091',
		'SZXX0020',
		'Lugano',
		'228',
		'01',
		'Swisscom',
		'284',
		'ISP/MOB'
	],
);
