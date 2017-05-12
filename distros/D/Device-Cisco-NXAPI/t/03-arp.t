#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 7;
use File::Slurp;
use JSON;


BEGIN {
    use_ok( 'Device::Cisco::NXAPI' ) || print "Can't use Device::Cisco::NXAPI!\n";
};

my %ipv4_json_test_files = (
    vrf_default => "./t/json/arp/show_ip_arp.json",
);

my $api = Device::Cisco::NXAPI->new(uri => "http://1.1.1.1", username => 'foo', password => 'foo', debug => 0);

###################################
# Testing vrf default
################################### 

my $json_reply = read_file($ipv4_json_test_files{vrf_default});

$api->meta->remove_method('_send_cmd');
$api->meta->add_method('_send_cmd', sub { return decode_json($json_reply)->{result}->{body} } );

my $test = $api->tester();

ok( $test->arp_entries(ips => ['10.47.64.4']), "ARP Entry Exists" );
ok( $test->arp_entries(ips => ['10.47.64.4', '10.47.64.61']), "Multiple ARP Entries Exist" );
ok( $test->arp_entries(ips => ['10.47.64.4', '10.47.64.4']), "Duplicate ARP Entries Exist" );

ok( !$test->arp_entries(ips => ['1.1.1.1']), "ARP Entry Doesn't Exist" );
ok( !$test->arp_entries(ips => ['1.1.1.1', '1.1.1.1']), "Duplicate ARP Entries Don't Exist" );
ok( !$test->arp_entries(ips => ['10.47.64.4', '1.1.1.1']), "One ARP Entry Exists, One Doesn't" );



