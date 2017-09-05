#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;
use XML::Twig;

use Device::PaloAlto::Firewall;

plan tests => 12;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test', debug => 1);
my $test = $fw->tester();

# No BGP Configured
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_bgp_configured() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->bgp_rib(), 'ARRAY', "No BGP returns ARRAYREF" );
is_deeply( $fw->bgp_rib(), [] , "No BGP returns an empty ARRAYREF" );

ok( !$test->bgp_prefixes_in_rib(prefixes => ['1.1.1.0/24']), "BGP not configured returns 0" );

# BGP up and configured, but not prefixes in the loc RiB
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( empty_loc_rib() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->bgp_rib(), 'ARRAY', "Nothing in loc RIB returns ARRAYREF" );
is_deeply( $fw->bgp_rib(), [] , "Nothing in loc RIB returns an empty ARRAYREF" );

ok( !$test->bgp_prefixes_in_rib(prefixes => ['1.1.1.0/24']), "No prefices in RIB returns 0" );

# BGP up and prefix in the loc RIB
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( loc_rib() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->bgp_rib(), 'ARRAY', "Prefixes in loc RIB return an ARRAYREF" );

ok( !$test->bgp_prefixes_in_rib(prefixes => ['1.1.1.0/24']), "No prefices in RIB returns 0" );

ok( $test->bgp_prefixes_in_rib(prefixes => ['9.9.9.0/24']), "Single prefix present in RIB returns 1" );
ok( $test->bgp_prefixes_in_rib(prefixes => ['9.9.9.0/24', '10.175.0.0/16']), "Multiple prefixes present in RIB returns 1" );
ok( $test->bgp_prefixes_in_rib(prefixes => ['9.9.9.0/24', '10.175.0.0/16']), "Multiple prefixes present in RIB returns 1" );

ok( !$test->bgp_prefixes_in_rib(prefixes => ['9.9.9.0/24', '1.1.1.0/24']), "Multiple prefixes, one not present in RIB returns 0" );



sub no_bgp_configured {
   return <<'END'
<response status="success"><result>
	<entry vr="default">
		<flags>flags: *:best route, =:ECMP route</flags>
		<loc-rib></loc-rib></entry></result></response>
END
}

sub empty_loc_rib {
   return <<'END'
<response status="success"><result>
	<entry vr="default">
		<flags>flags: *:best route, =:ECMP route</flags>
		<loc-rib></loc-rib></entry></result></response>
END
}

sub loc_rib {
   return <<'END'
<response status="success"><result>
	<entry vr="default">
		<flags>flags: *:best route, =:ECMP route</flags>
		<loc-rib>
	<member>
		<prefix>9.9.9.0/24</prefix>
		<flag>*</flag>
		<nexthop>192.168.122.30</nexthop>
		<received-from>c1000v.local</received-from>
		<as-path>65001</as-path>
		<attr>
			<weight>0</weight>
			<originator-id>0.0.0.0</originator-id>
			<origin>IGP</origin>
			<med>0</med>
			<local-preference>100</local-preference></attr>
		<flap-stat>
			<flap-count>0</flap-count></flap-stat></member>
	<member>
		<prefix>10.175.0.0/16</prefix>
		<flag>*</flag>
		<nexthop>1.1.1.1</nexthop>
		<received-from>default_to_inside_vr</received-from>
		<as-path>65002</as-path>
		<attr>
			<weight>0</weight>
			<originator-id>0.0.0.0</originator-id>
			<origin>N/A</origin>
			<med>0</med>
			<local-preference>100</local-preference></attr>
		<flap-stat>
			<flap-count>0</flap-count></flap-stat></member>
	<member>
		<prefix>10.175.0.0/16</prefix>
		<flag> </flag>
		<nexthop>1.1.1.2</nexthop>
		<received-from>default_to_outside_vr</received-from>
		<as-path>65003</as-path>
		<attr>
			<weight>0</weight>
			<originator-id>0.0.0.0</originator-id>
			<origin>N/A</origin>
			<med>0</med>
			<local-preference>100</local-preference></attr>
		<flap-stat>
			<flap-count>0</flap-count></flap-stat></member></loc-rib></entry></result></response>
END
}

sub multi_bfd_response {
   return <<'END'
<response status="success"><result>
	<entry>
		<session-id>2</session-id>
		<interface>ethernet1/23 </interface>
		<protocol>BGP </protocol>
		<local-ip-address>192.168.198.29</local-ip-address>
		<neighbor-ip-address>192.168.198.30</neighbor-ip-address>
		<discriminator-local>0x48e0002</discriminator-local>
		<discriminator-remote>0x4bb50013</discriminator-remote>
		<state-local>up</state-local>
		<up-time>-1244382476d 16h 53m 38s 940ms </up-time>
		<errors>0</errors></entry>
	<entry>
		<session-id>7</session-id>
		<interface>ethernet1/22.16 </interface>
		<protocol>BGP </protocol>
		<local-ip-address>192.168.198.17</local-ip-address>
		<neighbor-ip-address>192.168.198.18</neighbor-ip-address>
		<discriminator-local>0x3ade0007</discriminator-local>
		<discriminator-remote>0x41000015</discriminator-remote>
		<state-local>up</state-local>
		<up-time>3d 4h 7m 42s 509ms </up-time>
		<errors>0</errors></entry>
	<entry>
		<session-id>30</session-id>
		<interface>ethernet1/22.32 </interface>
		<protocol>BGP </protocol>
		<local-ip-address>110.145.141.82</local-ip-address>
		<neighbor-ip-address>110.145.141.81</neighbor-ip-address>
		<discriminator-local>0x4a3a001e</discriminator-local>
		<discriminator-remote>0x0</discriminator-remote>
		<state-local>down</state-local>
		<up-time></up-time>
		<errors>0</errors></entry>
</result>
</response>
END
}

