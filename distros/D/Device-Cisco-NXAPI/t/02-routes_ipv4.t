#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 13;
use File::Slurp;
use JSON;


BEGIN {
    use_ok( 'Device::Cisco::NXAPI' ) || print "Can't use Device::Cisco::NXAPI!\n";
}

my %ipv4_json_test_files = (
    vrf_default => "./t/json/route/show_ip_route_vrf_default.json",
    vrf_other => "./t/json/route/show_ip_route_vrf_other_vrf.json",
    vrf_all => "./t/json/route/show_ip_route_vrf_all.json",
);

my $api = Device::Cisco::NXAPI->new(uri => "http://1.1.1.1", username => 'foo', password => 'foo', debug => 0);

###################################
# Testing vrf default
################################### 

my $json_reply = read_file($ipv4_json_test_files{vrf_default});

$api->meta->remove_method('_send_cmd');
$api->meta->add_method('_send_cmd', sub { return decode_json($json_reply)->{result}->{body} } );

my $test = $api->tester();

ok( $test->routes( routes => [ '192.168.25.1/32' ] ), "Route Exists" );
ok( $test->routes( routes => [ '192.168.25.1/32', '1.2.3.4/32' ] ), "Multiple Routes Exists" );

ok( !$test->routes( routes => [ '1.2.3.5/32' ] ), "Route Doesn't Exist" );
ok( !$test->routes( routes => [ '1.2.3.5/32', '1.2.3.6/24' ] ), "Multiple Routes Don't Exist" );

ok ( $test->routes( routes => [ ] ), "Empty Set returns true");

ok( !$test->routes( routes => [ '1.2.3.4/32', '1.2.3.6/24' ] ), "Multiple Routes that do and don't exist" );

###################################
# Testing vrf other_vrf
################################### 
$json_reply = read_file($ipv4_json_test_files{vrf_other});

$api->meta->remove_method('_send_cmd');
$api->meta->add_method('_send_cmd', sub { return decode_json($json_reply)->{result}->{body} } );

ok( $test->routes( routes => [ '1.1.1.0/24' ] ), "Route Exists" );
ok( $test->routes( routes => [ '1.1.1.1/32', '8.8.8.0/24' ] ), "Multiple Routes Exists" );


###################################
# Testing vrf all
################################### 
$json_reply = read_file($ipv4_json_test_files{vrf_all});

$api->meta->remove_method('_send_cmd');
$api->meta->add_method('_send_cmd', sub { return decode_json($json_reply)->{result}->{body} } );

ok( $test->routes( routes => [ '1.1.1.0/24' ] ), "Route Exists" );
ok( $test->routes( routes => [ '1.2.3.0/24' ] ), "Route Exists" );
ok( $test->routes( routes => [ '0.0.0.0/0' ] ), "Route Exists" );
ok( $test->routes( routes => [ '1.2.3.0/24', '0.0.0.0/0', '1.1.1.0/24' ] ), "Multiple Routes Exist Across VRFs" );
