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

my $uri = $ENV{PA_TEST_URI};
my $fw;

$fw = Device::PaloAlto::Firewall->new(uri => $uri, username => 'test', password => 'test');

lives_ok { $fw->system_info } "System Info";
lives_ok { $fw->environmentals } "Environmentals";
lives_ok { $fw->interfaces } "Interfaces";
lives_ok { $fw->high_availability } "High Availability";
lives_ok { $fw->ntp } "NTP";
lives_ok { $fw->routing_table } "Routing Table";
lives_ok { $fw->bgp_peers } "BGP Peers";
lives_ok { $fw->panorama_status } "Panorama Status";
lives_ok { $fw->ip_user_mapping } "IP User Mapping";
lives_ok { $fw->userid_server_monitor } "Server Monitor";
