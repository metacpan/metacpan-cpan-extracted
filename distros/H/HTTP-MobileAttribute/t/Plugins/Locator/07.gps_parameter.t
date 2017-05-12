use strict;
use warnings;
use Test::More;
plan skip_all => "this module requires Geo::Coordinates::Converter && Geo::Coordinates::Converter::iArea" unless eval "use Geo::Coordinates::Converter; use Geo::Coordinates::Converter::iArea; 1;";
plan tests => 7;


use HTTP::MobileAttribute plugins => ['Locator'];


{ # DoCoMo
    local $ENV{HTTP_USER_AGENT} = 'DoCoMo/2.0 SH904i(c100;TB;W24H16)';
    my $agent = HTTP::MobileAttribute->new;

    # GPS
    is HTTP::MobileAttribute::Plugin::Locator::_is_gps_parameter( $agent, {
        lat => '35.21.03.342', lon => '138.34.45.725', geo => 'wgs84'
    } ) => 1;

    # Basic
    is HTTP::MobileAttribute::Plugin::Locator::_is_gps_parameter( $agent, {
        AREACODE => '05902', LAT => '+35.39.43.538', LON => '+139.44.06.232', GEO => 'wgs84', XACC => 1
    }) => '';

    is HTTP::MobileAttribute::Plugin::Locator::_is_gps_parameter( $agent, {
        AREACODE => '05902'
    }) => '';
}


{ # au
    local $ENV{HTTP_USER_AGENT} = 'KDDI-CA31 UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0';
    local $ENV{HTTP_X_UP_DEVCAP_MULTIMEDIA} = '0200000000000000';
    my $agent = HTTP::MobileAttribute->new;

    # GPS
    is HTTP::MobileAttribute::Plugin::Locator::_is_gps_parameter( $agent, {
        lat => '+35.21.03.342', lon => '+138.34.45.725', datum => '0'
    }) => 1;

    # Basic
    is HTTP::MobileAttribute::Plugin::Locator::_is_gps_parameter( $agent, {
        lat => '35.21.03.342', lon => '138.34.45.725', datum => 'wgs84'
    }) => '';
}


{ # SoftBank
    local $ENV{HTTP_USER_AGENT} =
        'SoftBank/1.0/911T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1';
    my $agent = HTTP::MobileAttribute->new;

    # GPS
    is HTTP::MobileAttribute::Plugin::Locator::_is_gps_parameter( $agent, {
        pos => 'N35.21.03.342E138.34.45.725'
    }) => 1;

    # Basic
    local $ENV{ HTTP_X_JPHONE_GEOCODE } = '352051%1a1383456%1afoo';
    is HTTP::MobileAttribute::Plugin::Locator::_is_gps_parameter( $agent, {
    }) => '';
}


