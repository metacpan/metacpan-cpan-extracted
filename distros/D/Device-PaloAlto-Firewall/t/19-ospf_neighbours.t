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

# No configuration
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_ospf_configured() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->ospf_neighbours(), 'ARRAY', "No OSPF configured returns ARRAYREF" );
is_deeply( $fw->ospf_neighbours(), [] , "No OSPF configured returns an empty ARRAYREF" );

ok( !$test->ospf_neighbours_up(neighbours => ['192.168.122.30']), "OSPF not configured returns 0");

# OSPF configured no neighbours
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( ospf_configured_no_neighbours() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->ospf_neighbours(), 'ARRAY', "No OSPF neighbours returns ARRAYREF" );
is_deeply( $fw->ospf_neighbours(), [] , "No OSPF neighbours returns an empty ARRAYREF" );

ok( !$test->ospf_neighbours_up(neighbours => ['192.168.122.30']), "OSPF with no neighbours returns 0");

# OSPF configured with  neighbours
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( ospf_configured_with_neighbours() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->ospf_neighbours(), 'ARRAY', "No IPSEC configured returns ARRAYREF" );

ok( $test->ospf_neighbours_up(neighbours => ['192.168.122.30']), "OSPF with a neighbour returns 1");
ok( $test->ospf_neighbours_up(neighbours => ['192.168.122.30', '192.168.124.2']), "OSPF with a multiple neighbours returns 1");
ok( !$test->ospf_neighbours_up(neighbours => ['192.168.122.31']), "OSPF with a non-existent neighbour returns 0");

# OSPF with neighbour stuck in exstart
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( ospf_neighbour_in_exstart() )->simplify(forcearray => ['entry'] )->{result} } );

ok( !$test->ospf_neighbours_up(neighbours => ['192.168.124.2']), "OSPF with an exstart neighbour returns 0");
ok( !$test->ospf_neighbours_up(neighbours => ['192.168.124.2', '192.168.122.30']), "OSPF with an exstart neighbour and a full neighbour returns 0");



sub no_ospf_configured {
   return <<'END'
<response status="success"><result><options>  Options: 0x80:reserved, O:Opaq-LSA capability, DC:demand circuits, EA:Ext-Attr LSA capability, N/P:NSSA option, MC:multicase, E:AS external LSA capability, T:TOS capability</options></result></response>
END
}

sub ospf_configured_no_neighbours {
   return <<'END'
<response status="success"><result><options>  Options: 0x80:reserved, O:Opaq-LSA capability, DC:demand circuits, EA:Ext-Attr LSA capability, N/P:NSSA option, MC:multicase, E:AS external LSA capability, T:TOS capability</options></result></response>
END
}

sub ospf_configured_with_neighbours {
   return <<'END'
<response status="success"><result>
	<options>  Options: 0x80:reserved, O:Opaq-LSA capability, DC:demand circuits, EA:Ext-Attr LSA capability, N/P:NSSA option, MC:multicase, E:AS external LSA capability, T:TOS capability</options>
	<entry>
		<virtual-router>default</virtual-router>
		<neighbor-address>192.168.122.30</neighbor-address>
		<local-address-binding>0.0.0.0</local-address-binding>
		<type>dynamic</type>
		<status>full</status>
		<neighbor-router-id>1.1.1.20</neighbor-router-id>
		<area-id>0.0.0.0</area-id>
		<neighbor-priority>1</neighbor-priority>
		<lifetime-remain>31</lifetime-remain>
		<messages-pending>0</messages-pending>
		<lsa-request-pending>0</lsa-request-pending>
		<options>0x52: O EA E </options>
		<hello-suppressed>no</hello-suppressed>
		<restart-helper-status>not helping</restart-helper-status>
		<restart-helper-time-remaining>0</restart-helper-time-remaining>
		<restart-helper-exit-reason>none</restart-helper-exit-reason></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<neighbor-address>192.168.124.2</neighbor-address>
		<local-address-binding>0.0.0.0</local-address-binding>
		<type>dynamic</type>
		<status>full</status>
		<neighbor-router-id>1.1.1.20</neighbor-router-id>
		<area-id>0.0.0.0</area-id>
		<neighbor-priority>1</neighbor-priority>
		<lifetime-remain>38</lifetime-remain>
		<messages-pending>0</messages-pending>
		<lsa-request-pending>0</lsa-request-pending>
		<options>0x52: O EA E </options>
		<hello-suppressed>no</hello-suppressed>
		<restart-helper-status>not helping</restart-helper-status>
		<restart-helper-time-remaining>0</restart-helper-time-remaining>
		<restart-helper-exit-reason>none</restart-helper-exit-reason></entry></result></response>
END
}

sub ospf_neighbour_in_exstart {
	return <<'END'
<response status="success"><result>
	<options>  Options: 0x80:reserved, O:Opaq-LSA capability, DC:demand circuits, EA:Ext-Attr LSA capability, N/P:NSSA option, MC:multicase, E:AS external LSA capability, T:TOS capability</options>
	<entry>
		<virtual-router>default</virtual-router>
		<neighbor-address>192.168.122.30</neighbor-address>
		<local-address-binding>0.0.0.0</local-address-binding>
		<type>dynamic</type>
		<status>full</status>
		<neighbor-router-id>1.1.1.2</neighbor-router-id>
		<area-id>0.0.0.0</area-id>
		<neighbor-priority>1</neighbor-priority>
		<lifetime-remain>34</lifetime-remain>
		<messages-pending>1</messages-pending>
		<lsa-request-pending>0</lsa-request-pending>
		<options>0x52: O EA E </options>
		<hello-suppressed>no</hello-suppressed>
		<restart-helper-status>not helping</restart-helper-status>
		<restart-helper-time-remaining>0</restart-helper-time-remaining>
		<restart-helper-exit-reason>none</restart-helper-exit-reason></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<neighbor-address>192.168.124.2</neighbor-address>
		<local-address-binding>0.0.0.0</local-address-binding>
		<type>dynamic</type>
		<status>exchange</status>
		<neighbor-router-id>1.1.1.2</neighbor-router-id>
		<area-id>0.0.0.0</area-id>
		<neighbor-priority>1</neighbor-priority>
		<lifetime-remain>39</lifetime-remain>
		<messages-pending>2</messages-pending>
		<lsa-request-pending>0</lsa-request-pending>
		<options>0x52: O EA E </options>
		<hello-suppressed>no</hello-suppressed>
		<restart-helper-status>not helping</restart-helper-status>
		<restart-helper-time-remaining>0</restart-helper-time-remaining>
		<restart-helper-exit-reason>none</restart-helper-exit-reason></entry></result></response>
END
}
