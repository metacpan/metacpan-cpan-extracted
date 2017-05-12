#!perl

use strict;
use warnings;

use Test::More;

my $file = 'samples/IP-COUNTRY-SAMPLE.BIN';

if ( ! -f $file ) {
	BAIL_OUT( "no IP2Location binary data file found" );
}

plan tests => 214;

use_ok( 'Geo::IP2Location::Lite' );

isa_ok(
	my $obj = Geo::IP2Location::Lite->open( $file ),
	'Geo::IP2Location::Lite'
);

while (<DATA>) {
	chomp;
	my ( $ip,$exp_country ) = split( "\t" );
	my $country = $obj->get_country_short( $ip );
	is( uc( $country ),$exp_country,"get_country_short ($country)" );

	my $upgrade = qr/Please upgrade data file/;

	is( ( $obj->get_country( $ip ) )[0],$exp_country,'get_country' );
	ok( $obj->get_country_long( $ip ),'get_country_long' );
	like( $obj->get_region( $ip ),$upgrade,'get_region' );
	like( $obj->get_city( $ip ),$upgrade,'get_city' );
	like( $obj->get_isp( $ip ),$upgrade,'get_isp' );
	like( $obj->get_latitude( $ip ),$upgrade,'get_latitude' );
	like( $obj->get_zipcode( $ip ),$upgrade,'get_zipcode' );
	like( $obj->get_longitude( $ip ),$upgrade,'get_longitude' );
	like( $obj->get_domain( $ip ),$upgrade,'get_domain' );
	like( $obj->get_timezone( $ip ),$upgrade,'get_timezone' );
	like( $obj->get_netspeed( $ip ),$upgrade,'get_netspeed' );
	like( $obj->get_iddcode( $ip ),$upgrade,'get_iddcode' );
	like( $obj->get_areacode( $ip ),$upgrade,'get_areacode' );
	like( $obj->get_weatherstationcode( $ip ),$upgrade,'get_weatherstationcode' );
	like( $obj->get_weatherstationname( $ip ),$upgrade,'get_weatherstationname' );
	like( $obj->get_mcc( $ip ),$upgrade,'get_mcc' );
	like( $obj->get_mnc( $ip ),$upgrade,'get_mnc' );
	like( $obj->get_mobilebrand( $ip ),$upgrade,'get_mobilebrand' );
	like( $obj->get_elevation( $ip ),$upgrade,'get_elevation' );
	like( $obj->get_usagetype( $ip ),$upgrade,'get_usagetype' );
}

is( $obj->get_module_version,$Geo::IP2Location::Lite::VERSION,'get_module_version' );
is( $obj->get_database_version,'5.6.17','get_database_version' );

__DATA__
19.5.10.1	US
25.5.10.2	GB
43.5.10.3	JP
47.5.10.4	CA
51.5.10.5	GB
53.5.10.6	DE
80.5.10.7	GB
81.5.10.8	IL
83.5.10.9	PL
85.5.10.0	CH
