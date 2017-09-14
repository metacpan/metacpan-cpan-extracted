#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;
use XML::Twig;

use Data::Dumper;

use Device::PaloAlto::Firewall;

plan tests => 12;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test', debug => 1);
my $test = $fw->tester();

$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_bgp_configured() )->simplify( forcearray => ['entry'] )->{result} } );



### Test exceptions and warnings ###
dies_ok { $fw->bgp_peers(rtr => 'default') } 'Incorrect parameter dies';
dies_ok { $test->bgp_peers_up() } 'Not specifying \'peer_ips =>\' dies';

### Tests when the firewall is not configured with BGP ###
isa_ok( $fw->bgp_peers(), 'ARRAY' );
is_deeply( $fw->bgp_peers(), [] , "No BGP peers configured returns an empty ARRAYREF" );

ok( !$test->bgp_peers_up(peer_ips => ['192.168.122.30']), 'No configured BGP');


### Tests when the firewall has a single peer ###
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( static_vm_response_single_peer() )->simplify( forcearray => ['entry'] )->{result} } );

ok( $test->bgp_peers_up(peer_ips => ['192.168.122.30']), 'Single peer up' );
ok( !$test->bgp_peers_up(peer_ips => ['1.1.1.1']), 'Peer not present' );
ok( !$test->bgp_peers_up(peer_ips => ['192.168.122.30', '1.1.1.1']), 'Single peer up, single peer not present' );

### Tests when the firewall has multiple peers ###
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( static_vm_response_multiple_peer() )->simplify( forcearray => ['entry'] )->{result} } );

ok( $test->bgp_peers_up(peer_ips => ['192.168.122.30']), 'Single peer up' );
ok( !$test->bgp_peers_up(peer_ips => ['192.168.122.35']), 'Single peer not up' );
ok( !$test->bgp_peers_up(peer_ips => ['192.168.122.30', '192.168.122.35']), 'Single peer up, single peer not up' );
ok( !$test->bgp_peers_up(peer_ips => ['192.168.122.30', '192.168.122.35', '1.1.1.1']), 'Single peer up, single peer not up, single peer not present' );

sub no_bgp_configured {
    return <<'END'
<response status="success"><result></result></response>
END
}

sub static_vm_response_single_peer {
    return  <<'END';
<response status="success"><result>
	<entry peer="c1000v.local" vr="default">
		<peer-group>Cisco</peer-group>
		<peer-router-id>1.1.1.20</peer-router-id>
		<remote-as>65001</remote-as>
		<status>Established</status>
		<status-duration>260</status-duration>
		<password-set>no</password-set>
		<passive>no</passive>
		<multi-hop-ttl>2</multi-hop-ttl>
		<peer-address>192.168.122.30:52236</peer-address>
		<local-address>192.168.122.19:179</local-address>
		<reflector-client>not-client</reflector-client>
		<same-confederation>no</same-confederation>
		<aggregate-confed-as>yes</aggregate-confed-as>
		<peering-type>Unspecified</peering-type>
		<connect-retry-interval>120</connect-retry-interval>
		<open-delay>0</open-delay>
		<idle-hold>15</idle-hold>
		<prefix-limit>5000</prefix-limit>
		<holdtime>90</holdtime>
		<holdtime-config>90</holdtime-config>
		<keepalive>30</keepalive>
		<keepalive-config>30</keepalive-config>
		<msg-update-in>4</msg-update-in>
		<msg-update-out>2</msg-update-out>
		<msg-total-in>15</msg-total-in>
		<msg-total-out>13</msg-total-out>
		<last-update-age>3</last-update-age>
		<last-error></last-error>
		<status-flap-counts>2</status-flap-counts>
		<established-counts>1</established-counts>
		<ORF-entry-received>0</ORF-entry-received>
		<nexthop-self>no</nexthop-self>
		<nexthop-thirdparty>yes</nexthop-thirdparty>
		<nexthop-peer>no</nexthop-peer>
		<config>
	<remove-private-as>yes</remove-private-as></config>
		<peer-capability>
	<list>
		<capability>Multiprotocol Extensions(1)</capability></list>
	<list>
		<capability>Route Refresh(2)</capability></list>
	<list>
		<capability>32-Bit AS Number(65)</capability></list>
	<list>
		<capability>unknown(70)</capability></list>
	<list>
		<capability>Route Refresh (Cisco)(128)</capability></list></peer-capability>
		<prefix-counter>
	<entry afi-safi="bgpAfiIpv4-unicast">
		<incoming-total>2</incoming-total>
		<incoming-accepted>2</incoming-accepted>
		<incoming-rejected>0</incoming-rejected>
		<outgoing-total>1</outgoing-total>
		<outgoing-advertised>1</outgoing-advertised>
	</entry>
</prefix-counter></entry></result></response>
END
}


sub static_vm_response_multiple_peer {
    return  <<'END';
<response status="success"><result>
	<entry peer="c1000v.local" vr="default">
		<peer-group>Cisco</peer-group>
		<peer-router-id>1.1.1.20</peer-router-id>
		<remote-as>65001</remote-as>
		<status>Established</status>
		<status-duration>1021</status-duration>
		<password-set>no</password-set>
		<passive>no</passive>
		<multi-hop-ttl>2</multi-hop-ttl>
		<peer-address>192.168.122.30:52236</peer-address>
		<local-address>192.168.122.19:179</local-address>
		<reflector-client>not-client</reflector-client>
		<same-confederation>no</same-confederation>
		<aggregate-confed-as>yes</aggregate-confed-as>
		<peering-type>Unspecified</peering-type>
		<connect-retry-interval>120</connect-retry-interval>
		<open-delay>0</open-delay>
		<idle-hold>15</idle-hold>
		<prefix-limit>5000</prefix-limit>
		<holdtime>90</holdtime>
		<holdtime-config>90</holdtime-config>
		<keepalive>30</keepalive>
		<keepalive-config>30</keepalive-config>
		<msg-update-in>7</msg-update-in>
		<msg-update-out>5</msg-update-out>
		<msg-total-in>45</msg-total-in>
		<msg-total-out>47</msg-total-out>
		<last-update-age>16</last-update-age>
		<last-error></last-error>
		<status-flap-counts>2</status-flap-counts>
		<established-counts>1</established-counts>
		<ORF-entry-received>0</ORF-entry-received>
		<nexthop-self>no</nexthop-self>
		<nexthop-thirdparty>yes</nexthop-thirdparty>
		<nexthop-peer>no</nexthop-peer>
		<config>
	<remove-private-as>yes</remove-private-as></config>
		<peer-capability>
	<list>
		<capability>Multiprotocol Extensions(1)</capability></list>
	<list>
		<capability>Route Refresh(2)</capability></list>
	<list>
		<capability>32-Bit AS Number(65)</capability></list>
	<list>
		<capability>unknown(70)</capability></list>
	<list>
		<capability>Route Refresh (Cisco)(128)</capability></list></peer-capability>
		<prefix-counter>
	<entry afi-safi="bgpAfiIpv4-unicast">
		<incoming-total>2</incoming-total>
		<incoming-accepted>2</incoming-accepted>
		<incoming-rejected>0</incoming-rejected>
		<outgoing-total>1</outgoing-total>
		<outgoing-advertised>1</outgoing-advertised></entry></prefix-counter></entry>
	<entry peer="Down_Peer" vr="default">
		<peer-group>Down</peer-group>
		<peer-router-id>0.0.0.0</peer-router-id>
		<remote-as>65005</remote-as>
		<status>Connect</status>
		<status-duration>0</status-duration>
		<password-set>no</password-set>
		<passive>no</passive>
		<multi-hop-ttl>2</multi-hop-ttl>
		<peer-address>192.168.122.35</peer-address>
		<local-address>192.168.122.19</local-address>
		<reflector-client>not-client</reflector-client>
		<same-confederation>no</same-confederation>
		<aggregate-confed-as>yes</aggregate-confed-as>
		<peering-type>Unspecified</peering-type>
		<connect-retry-interval>120</connect-retry-interval>
		<open-delay>0</open-delay>
		<idle-hold>15</idle-hold>
		<prefix-limit>5000</prefix-limit>
		<holdtime>0</holdtime>
		<holdtime-config>90</holdtime-config>
		<keepalive>0</keepalive>
		<keepalive-config>30</keepalive-config>
		<msg-update-in>0</msg-update-in>
		<msg-update-out>0</msg-update-out>
		<msg-total-in>0</msg-total-in>
		<msg-total-out>0</msg-total-out>
		<last-update-age>16</last-update-age>
		<last-error></last-error>
		<status-flap-counts>1</status-flap-counts>
		<established-counts>0</established-counts>
		<ORF-entry-received>0</ORF-entry-received>
		<nexthop-self>no</nexthop-self>
		<nexthop-thirdparty>yes</nexthop-thirdparty>
		<nexthop-peer>no</nexthop-peer>
		<config>
	<remove-private-as>yes</remove-private-as></config>
		<peer-capability></peer-capability>
		<prefix-counter></prefix-counter></entry></result></response>
END
}
