#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;


use Device::PaloAlto::Firewall;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

unless ( $ENV{PA_TEST_URI} ) {
    plan ( skip_all => "No PA_TEST_URI environment variable provided" );
}

plan tests => 7;

my $uri = $ENV{PA_TEST_URI};

my $fw = Device::PaloAlto::Firewall->new(uri => $uri, username => 'test', password => 'test');

ok( $fw->system_info(), "System Info" );
ok( $fw->interfaces(), "Interfaces" );
ok( $fw->high_availability(), "High Availability" );
ok( $fw->ntp(), "NTP" );
ok( $fw->routing_table(), "Routing Table" );
ok( $fw->bgp_peers(), "BGP Peers" );
ok( $fw->panorama_status(), "Panorama Status" );







