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

plan tests => 9;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test');

$fw->meta->remove_method('_send_request');
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( static_vm_response() )->simplify( forcearray => ['entry'] )->{result} } );

my $test = $fw->tester();

# Test for exceptions
dies_ok { $fw->routes() } 'routes(): Not specifying \'routes =>\' should die';
dies_ok { $test->routes_exist() } 'routes_exist(): Not specifying \'routes =>\' should die';
warning_is { $test->routes_exist(routes => []) } "Empty routes ARRAYREF specified - test will still return true", "Empty routes warns";
{ 
    # Supress the warning output
    no warnings 'redefine';
    local *Device::PaloAlto::Firewall::Test::carp = sub { };
	ok( $test->routes_exist(routes => []), 'Empty routes returns true' );
}

# Test general usage
ok( $test->routes_exist(routes => ['0.0.0.0/0']), 'Single route exists' );
ok( $test->routes_exist(routes => ['0.0.0.0/0', '192.168.122.0/24']), 'Multiple routes exist' );

ok( !$test->routes_exist(routes => ['1.2.3.4/32']), 'Single route does not exist' );
ok( !$test->routes_exist(routes => ['1.2.3.4/32', '2.3.4.5/32']), 'Multiple routes do not exist' );
ok( !$test->routes_exist(routes => ['1.2.3.4/32', '0.0.0.0/0']), 'One route is present, one route is not present' );


# Mocked responses
sub static_vm_response {
    return  <<'END';
<response status="success"><result>
	<flags>flags: A:active, ?:loose, C:connect, H:host, S:static, ~:internal, R:rip, O:ospf, B:bgp, Oi:ospf intra-area, Oo:ospf inter-area, O1:ospf ext-type-1, O2:ospf ext-type-2 E:ecmp</flags>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>0.0.0.0/0</destination>
		<nexthop>discard</nexthop>
		<metric></metric>
		<flags>  B  </flags>
		<age>1099</age>
		<interface></interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>0.0.0.0/0</destination>
		<nexthop>192.168.122.1</nexthop>
		<metric>10</metric>
		<flags>A S  </flags>
		<age></age>
		<interface>ethernet1/1</interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>1.1.1.100/30</destination>
		<nexthop>1.1.1.100</nexthop>
		<metric>0</metric>
		<flags>A C  </flags>
		<age></age>
		<interface>tunnel.1</interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>1.1.1.100/32</destination>
		<nexthop>0.0.0.0</nexthop>
		<metric>0</metric>
		<flags>A H  </flags>
		<age></age>
		<interface></interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>10.10.10.0/24</destination>
		<nexthop>10.10.10.10</nexthop>
		<metric>0</metric>
		<flags>A C  </flags>
		<age></age>
		<interface>ethernet1/2.10</interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>10.10.10.10/32</destination>
		<nexthop>0.0.0.0</nexthop>
		<metric>0</metric>
		<flags>A H  </flags>
		<age></age>
		<interface></interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>20.20.20.0/24</destination>
		<nexthop>20.20.20.20</nexthop>
		<metric>0</metric>
		<flags>A C  </flags>
		<age></age>
		<interface>ethernet1/2.20</interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>20.20.20.20/32</destination>
		<nexthop>0.0.0.0</nexthop>
		<metric>0</metric>
		<flags>A H  </flags>
		<age></age>
		<interface></interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>100.100.100.1/32</destination>
		<nexthop>0.0.0.0</nexthop>
		<metric>0</metric>
		<flags>A H  </flags>
		<age></age>
		<interface></interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>100.100.100.1/32</destination>
		<nexthop>0.0.0.0</nexthop>
		<metric>1</metric>
		<flags>  ~  </flags>
		<age></age>
		<interface></interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>101.101.101.1/32</destination>
		<nexthop>0.0.0.0</nexthop>
		<metric>0</metric>
		<flags>A H  </flags>
		<age></age>
		<interface></interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>101.101.101.1/32</destination>
		<nexthop>0.0.0.0</nexthop>
		<metric>1</metric>
		<flags>  ~  </flags>
		<age></age>
		<interface></interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>102.102.102.1/32</destination>
		<nexthop>0.0.0.0</nexthop>
		<metric>0</metric>
		<flags>A H  </flags>
		<age></age>
		<interface></interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>102.102.102.1/32</destination>
		<nexthop>0.0.0.0</nexthop>
		<metric>1</metric>
		<flags>  ~  </flags>
		<age></age>
		<interface></interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>192.168.122.0/24</destination>
		<nexthop>192.168.122.19</nexthop>
		<metric>0</metric>
		<flags>A C  </flags>
		<age></age>
		<interface>ethernet1/1</interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>192.168.122.19/32</destination>
		<nexthop>0.0.0.0</nexthop>
		<metric>0</metric>
		<flags>A H  </flags>
		<age></age>
		<interface></interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>192.168.124.0/24</destination>
		<nexthop>192.168.124.19</nexthop>
		<metric>0</metric>
		<flags>A C  </flags>
		<age></age>
		<interface>ethernet1/2</interface></entry>
	<entry>
		<virtual-router>default</virtual-router>
		<destination>192.168.124.19/32</destination>
		<nexthop>0.0.0.0</nexthop>
		<metric>0</metric>
		<flags>A H  </flags>
		<age></age>
		<interface></interface></entry></result></response>
END
}

