#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;

use Device::PaloAlto::Firewall;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

unless ( $ENV{PA_TEST_URI} ) {
    plan ( skip_all => "No PA_TEST_URI environment variable provided" );
}

plan tests => 4;

my $uri = $ENV{PA_TEST_URI};

my $fw = Device::PaloAlto::Firewall->new(uri => $uri, username => 'test', password => 'test');
$fw->verify_hostname(0);

# Test routing table with an invalid parameter carps and returns undef
warning_is { $fw->routing_table(vrouter => "") } "API Error (17) - Invalid command", "routing_table with invalid vrouter param";
{ 
    no warnings 'redefine';
    local *Device::PaloAlto::Firewall::carp = sub { };
    ok( !$fw->routing_table(vrouter => ""), "routing_table with invalud vrouter param returns undef" );
}


# Test that BGP peers with an invalid parameter carps and returns undef
warning_is { $fw->bgp_peers(vrouter => "") } "API Error (17) - Invalid command", "bgp_peers with invalid vrouter param";
{ 
    no warnings 'redefine';
    local *Device::PaloAlto::Firewall::carp = sub { };
    ok( !$fw->routing_table(vrouter => ""), "bgp_peers with invalid vrouter param returns undef" );
}





