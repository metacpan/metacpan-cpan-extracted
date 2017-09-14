#!perl -T

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Exception;

use Device::PaloAlto::Firewall;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

unless ( $ENV{PA_TEST_URI} ) {
    plan ( skip_all => "No PA_TEST_URI environment variable provided" );
}

plan tests => 23;

my $uri = $ENV{PA_TEST_URI};
my $fw;

$fw = Device::PaloAlto::Firewall->new(uri => $uri, username => 'test', password => 'test');

ok( $fw->authenticate(), "authenticate()" );
ok( $fw->system_info(), "system_info()" );
ok( $fw->environmentals(), "environmentals()" );
ok( $fw->high_availability(), "high_availability()" );
ok( $fw->software_check(), "software_check()" );
ok( $fw->content_check(), "content_check()" );
ok( $fw->antivirus_check(), "antivirus_check()" );
ok( $fw->gp_client_check(), "gp_client_check()" );

ok( $fw->licenses(), "licenses()" );
ok( $fw->interfaces(), "interfaces()" );
ok( $fw->interface_counters_logical(), "interface_counters_logical()" );
ok( $fw->routing_table(), "routing_table()" );
ok( $fw->bgp_peers(), "bgp_peers()" );
ok( $fw->bgp_rib(), "bgp_rib()" );
ok( $fw->ospf_neighbours(), "ospf_neighbours()" );
ok( $fw->pim_neighbours(), "pim_neighbours()" );
ok( $fw->bfd_peers(), "bfd_peers()" );
ok( $fw->ntp(), "ntp()" );
ok( $fw->panorama_status(), "panorama_status()" );
ok( $fw->ip_user_mapping(), "ip_user_mapping()" );
ok( $fw->userid_server_monitor(), "userid_server_monitor()" );
ok( $fw->ike_peers(), "ike_peers()" );
ok( $fw->ipsec_peers(), "ipsec_peers()" );
ok( $fw->vpn_tunnels(), "vpn_tunnels()" );
