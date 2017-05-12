#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 2;
use File::Slurp;
use JSON;


BEGIN {
    use_ok( 'Device::Cisco::NXAPI' ) || print "Can't use Device::Cisco::NXAPI!\n";
}


my $json_reply = read_file('./t/json/bgp/show_bgp_ip_unicast_neighbors.json');

my $api = Device::Cisco::NXAPI->new(uri => "http://1.1.1.1", username => 'foo', password => 'foo', debug => 0);

#Modify the '_send_cmd' method so it always returns our JSON defined in the HEREDOC.
$api->meta->remove_method('_send_cmd');
$api->meta->add_method('_send_cmd', sub { return decode_json($json_reply)->{result}->{body} } );

my $test = $api->tester();

# Peer should be down
ok( !$test->bgp_peers_up(peers => ['1.1.1.1']) );

