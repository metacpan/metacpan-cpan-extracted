#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;
use HTTP::Response;

use Device::PaloAlto::Firewall;


 my $http_error_responses = [
     HTTP::Response->new(
         400, 
         "400 Response", 
         undef,
         q{<response status = 'error' code = '400'><result><msg>Illegal parameter [request]</msg></result></response>}
     ),
     HTTP::Response->new(
         403, 
         "403 Response", 
         undef,
         q{<response status = 'error' code = '403'><result><msg>Invalid credentials.</msg></result></response>}
     ),
     HTTP::Response->new(
         500, 
         "500 Response", 
         undef,
         q{}
     ),
     HTTP::Response->new(
         503, 
         "503 Response", 
         undef,
         q{<html>
         <head><title>502 Bad Gateway</title></head>
         <body bgcolor="white">
         <center><h1>502 Bad Gateway</h1></center>
         <hr><center></center>
         </body>
         </html>}
     )
 ];

plan tests => 47 * @{ $http_error_responses } ; 

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test');
my $test = $fw->tester();

for my $response (@{ $http_error_responses }) { 

    $fw->meta->add_method('_send_http_request', sub { return $response } );

	# Supress the warning output
    no warnings 'redefine';
    local *Device::PaloAlto::Firewall::Test::carp = sub { };
    local *Device::PaloAlto::Firewall::carp = sub { };

    ok( !$fw->authenticate(), "authenticate() returns undef on ".$response->message );
    ok( !$fw->system_info(), "system_info() returns undef on ".$response->message );
    ok( !$fw->environmentals(), "environmentals() returns undef on ".$response->message );
    ok( !$fw->high_availability(), "high_availability() returns undef on ".$response->message );
    ok( !$fw->software_check(), "software_check() returns undef on ".$response->message );
    ok( !$fw->content_check(), "content_check() returns undef on ".$response->message );
    ok( !$fw->antivirus_check(), "antivirus_check() returns undef on ".$response->message );
    ok( !$fw->gp_client_check(), "gp_client_check() returns undef on ".$response->message );
    ok( !$fw->licenses(), "licenses() returns undef on ".$response->message );

    ok( !$fw->interfaces(), "interfaces() returns undef on ".$response->message );
    ok( !$fw->interface_counters_logical(), "interface_counters_logical() returns undef on ".$response->message );
    ok( !$fw->routing_table(), "routing_table() returns undef on ".$response->message );
    ok( !$fw->bgp_peers(), "bgp_peers() returns undef on ".$response->message );
    ok( !$fw->bgp_rib(), "bgp_rib() returns undef on ".$response->message );
    ok( !$fw->ospf_neighbours(), "ospf_neighbours() returns undef on ".$response->message );
    ok( !$fw->pim_neighbours(), "pim_neighbours() returns undef on ".$response->message );
    ok( !$fw->bfd_peers(), "bfd_peers() returns undef on ".$response->message );
    ok( !$fw->ntp(), "ntp() returns undef on ".$response->message );
    ok( !$fw->panorama_status(), "panorama_status() returns undef on ".$response->message );
    ok( !$fw->ip_user_mapping(), "ip_user_mapping() returns undef on ".$response->message );
    ok( !$fw->userid_server_monitor(), "userid_server_monitor() returns undef on ".$response->message );
    ok( !$fw->ike_peers(), "ike_peers() returns undef on ".$response->message );
    ok( !$fw->ipsec_peers(), "ipsec_peers() returns undef on ".$response->message );
    ok( !$fw->vpn_tunnels(), "vpn_tunnels() returns undef on ".$response->message );


    ok( !$test->version(version => '6.0.0'), "version() returns undef on ".$response->message );
    ok( !$test->environmentals(), "environmentals() returns undef on ".$response->message );
    ok( !$test->licenses_active(), "licenses_active() returns undef on ".$response->message );
    ok( !$test->interfaces_up(interfaces => ['ethernet1/1']), "interfaces_up() returns undef on ".$response->message );
    ok( !$test->interfaces_duplex(interfaces => ['ethernet1/1']), "interfaces_duplex() returns undef on ".$response->message );
    ok( !$test->interface_errors_logical(), "interface_errors_logical() returns undef on ".$response->message );
    ok( !$test->routes_exist(routes => ['192.168.0.0/24']), "routes_exist() returns undef on ".$response->message );
    ok( !$test->bgp_peers_up(peer_ips => ['192.168.1.1']), "bgp_peers_up() returns undef on ".$response->message );
    ok( !$test->bgp_prefixes_in_rib(prefixes => ['192.168.0.0/24']), "bgp_prefixes_in_rib() returns undef on ".$response->message );
    ok( !$test->ospf_neighbours_up(neighbours => ['192.168.1.1']), "ospf_neighbours_up() returns undef on ".$response->message );
    ok( !$test->pim_neighbours_up(neighbours => ['192.168.1.1']), "pim_neighbours_up() returns undef on ".$response->message );
    ok( !$test->bfd_peers_up(), "bfd_peers_up() returns undef on ".$response->message );
    ok( !$test->ntp_synchronised(), "ntp_synchronised() returns undef on ".$response->message );
    ok( !$test->ntp_reachable(), "ntp_reachable() returns undef on ".$response->message );
    ok( !$test->panorama_connected(), "panorama_connected() returns undef on ".$response->message );
    ok( !$test->ha_enabled(), "ha_enabled() returns undef on ".$response->message );
    ok( !$test->ha_state(state => 'active'), "ha_state() returns undef on ".$response->message );
    ok( !$test->ha_version(), "ha_version() returns undef on ".$response->message );
    ok( !$test->ha_peer_up(), "ha_peer_up() returns undef on ".$response->message );
    ok( !$test->ha_config_sync(), "ha_config_sync() returns undef on ".$response->message );
    ok( !$test->ip_user_mapping(), "ip_user_mapping() returns undef on ".$response->message );
    ok( !$test->userid_server_monitor(), "userid_server_monitor() returns undef on ".$response->message );
    ok( !$test->vpn_tunnels_up(peer_ips => ['192.168.1.1']), "vpn_tunnels_up() returns undef on ".$response->message );
}
