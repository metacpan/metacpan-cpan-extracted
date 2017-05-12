#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;
use File::Slurp;
use JSON;


BEGIN {
    use_ok( 'Device::Cisco::NXAPI' ) || print "Can't use Device::Cisco::NXAPI!\n";
}



my $api = Device::Cisco::NXAPI->new(uri => "http://1.1.1.1", username => 'foo', password => 'foo', debug => 0);

# Our input files to emulate the JSON returned from the HTTP API call
my $json_ip_unicast = read_file('./t/json/bgp/show_bgp_ip_unicast.json');
my $json_ipv6_unicast = read_file('./t/json/bgp/show_bgp_ipv6_unicast.json');

# Testing the IPv4 Unicast RIB
$api->meta->remove_method('_send_cmd');
$api->meta->add_method('_send_cmd', sub { return decode_json($json_ip_unicast)->{result}->{body} } );

my $test = $api->tester();

ok( $test->bgp_rib_prefixes(prefixes => ['1.2.3.0/24']), "Prefix exists" );
ok( $test->bgp_rib_prefixes(prefixes => ['1.2.3.0/24', '192.168.1.0/24']), "Multiple prefixes exist" );

ok( !$test->bgp_rib_prefixes(prefixes => ['1.1.1.0/24']), "Prefix doesn't exist" );
ok( !$test->bgp_rib_prefixes(prefixes => ['192.168.1.0/24', '1.1.1.0/24']), "Prefixes do and don't exist" );

# Testing the IPv6 Unicast RIB
$api->meta->remove_method('_send_cmd');
$api->meta->add_method('_send_cmd', sub { return decode_json($json_ipv6_unicast)->{result}->{body} } );
