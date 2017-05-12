#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use XML::Twig;

use Device::PaloAlto::Firewall;

plan tests => 21;

### Testing interfaces_up() ###

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test');

$fw->meta->remove_method('_send_request');
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( static_vm_response() )->simplify()->{result} } );

my $test = $fw->tester();


ok( $test->interfaces_up(interfaces => ['ethernet1/1']), 'Single interface up' );
ok( $test->interfaces_up(interfaces => ['ETHERNET1/1']), 'Single interface case insensitive' );
ok( $test->interfaces_up(interfaces => ['ethernet1/1', 'ethernet1/1', 'ethernet1/1', 'ethernet1/2', 'ethernet1/2']), 'Multiple interfaces' );

ok( $test->interfaces_up(interfaces => ['ethernet1/1', 'ethernet1/2']), 'Multiple interfaces up' );
ok( !$test->interfaces_up(interfaces => ['ethernet1/3']), 'Interface down' );
ok( !$test->interfaces_up(interfaces => ['ethernet1/1', 'ethernet1/3']), 'One interface up, one interface down' );

ok( $test->interfaces_up(interfaces => ['ethernet1/(1|2)']), 'Regex interface up' );
ok( !$test->interfaces_up(interfaces => ['ethernet1/(1|3)']), 'Regex One interface up, one interface down' );

ok( !$test->interfaces_up(interfaces => ['ethernet1/.']), 'All ethernet interfaces' );

warning_is { $test->interfaces_up(interfaces => ['ethrnet1/2']) } "Warning: 'ethrnet1/2' matched no interfaces. Test may still succeed", "interfaces_up() - no match warns";
warning_is { $test->interfaces_up(interfaces => [ ]) } "Warning: no interfaces specified - test returns true", "interfaces_up() with an empty ARRAYREF warns";
{ 
	# Supress the warning output
    no warnings 'redefine';
    local *Device::PaloAlto::Firewall::Test::carp = sub { };
	ok( $test->interfaces_up(interfaces => ['ethrnet1/2']), 'No matching misspelled interface' );
    ok( $test->interfaces_up(interfaces => [ ]), 'No interfaces specified' );
}


### Testing interfaces_duplex() ###

warning_is { $test->interfaces_duplex(interfaces => ['ethrnet1/2']) } "Warning: 'ethrnet1/2' matched no interfaces. Test may still succeed", "interfaces_duplex() - no match warns";

warning_is { $test->interfaces_duplex(interfaces => ['ethernet1/1']) } "Warning: detected 'auto' duplex, probable VM? Test may still succeed", "Probable VM Warning";
{ 
	# Supress the warning output
    no warnings 'redefine';
    local *Device::PaloAlto::Firewall::Test::carp = sub { };
	ok( $test->interfaces_duplex(interfaces => ['ethrnet1/1']), 'VM detection still succeeds' );
}

$fw->meta->remove_method('_send_request');
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( static_phy_response() )->simplify()->{result} } );

ok( $test->interfaces_duplex(interfaces => ['ethernet1/11']), 'Interface in full duplex mode' );
ok( !$test->interfaces_duplex(interfaces => ['ethernet1/12']), 'Interface in half duplex mode' );
ok( !$test->interfaces_duplex(interfaces => ['ethernet1/11', 'ethernet1/12']), 'One interface in half duplex mode, one in full duplex mode' );
ok( !$test->interfaces_duplex(interfaces => ['ethernet1/(1|2)']), 'One interface in half duplex mode, one in full duplex mode, regex' );
ok( !$test->interfaces_duplex(interfaces => ['.*']), 'Wildcard regex.' );


sub static_vm_response {
    return  <<'END';
<response status="success"><result>
  <ifnet>
    <entry>
      <name>ethernet1/1</name>
      <zone>outside</zone>
      <fwd>vr:default</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>192.168.122.19/24</ip>
      <id>16</id>
      <addr/>
    </entry>
    <entry>
      <name>ethernet1/2</name>
      <zone>inside</zone>
      <fwd>vr:default</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>192.168.124.19/24</ip>
      <id>17</id>
      <addr/>
    </entry>
    <entry>
      <name>ethernet1/2.10</name>
      <zone>inside</zone>
      <fwd>vr:default</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>19</tag>
      <ip>10.10.10.10/24</ip>
      <id>262</id>
      <addr/>
    </entry>
    <entry>
      <name>ethernet1/2.20</name>
      <zone>inside</zone>
      <fwd>vr:default</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>20</tag>
      <ip>20.20.20.20/24</ip>
      <id>263</id>
      <addr/>
    </entry>
    <entry>
      <name>ethernet1/3</name>
      <zone/>
      <fwd>N/A</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>N/A</ip>
      <id>18</id>
      <addr/>
    </entry>
    <entry>
      <name>ethernet1/3.10</name>
      <zone>inside</zone>
      <fwd>vr:default</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>19</tag>
      <ip>11.11.11.11/24</ip>
      <id>265</id>
      <addr/>
    </entry>
    <entry>
      <name>ethernet1/3.20</name>
      <zone>inside</zone>
      <fwd>vr:default</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>20</tag>
      <ip>21.21.21.21/24</ip>
      <id>266</id>
      <addr/>
    </entry>
    <entry>
      <name>loopback</name>
      <zone/>
      <fwd>N/A</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>N/A</ip>
      <id>3</id>
      <addr/>
    </entry>
    <entry>
      <name>loopback.10</name>
      <zone>inside</zone>
      <fwd>vr:default</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>100.100.100.1/32</ip>
      <id>267</id>
      <addr/>
    </entry>
    <entry>
      <name>loopback.11</name>
      <zone>inside</zone>
      <fwd>vr:default</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>101.101.101.1/32</ip>
      <id>268</id>
      <addr/>
    </entry>
    <entry>
      <name>loopback.12</name>
      <zone>inside</zone>
      <fwd>vr:default</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>102.102.102.1/32</ip>
      <id>269</id>
      <addr/>
    </entry>
    <entry>
      <name>tunnel</name>
      <zone/>
      <fwd>N/A</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>N/A</ip>
      <id>4</id>
      <addr/>
    </entry>
    <entry>
      <name>tunnel.1</name>
      <zone>inside</zone>
      <fwd>vr:default</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>1.1.1.100/30</ip>
      <id>261</id>
      <addr/>
    </entry>
  </ifnet>
  <hw>
    <entry>
      <name>ethernet1/1</name>
      <duplex>auto</duplex>
      <type>0</type>
      <state>up</state>
      <st>auto/auto/up</st>
      <mac>52:54:00:39:74:c1</mac>
      <mode>(autoneg)</mode>
      <speed>auto</speed>
      <id>16</id>
    </entry>
    <entry>
      <name>ethernet1/2</name>
      <duplex>auto</duplex>
      <type>0</type>
      <state>up</state>
      <st>auto/auto/up</st>
      <mac>52:54:00:dd:0c:f3</mac>
      <mode>(autoneg)</mode>
      <speed>auto</speed>
      <id>17</id>
    </entry>
    <entry>
      <name>ethernet1/3</name>
      <duplex>ukn</duplex>
      <type>0</type>
      <state>down</state>
      <st>ukn/ukn/down(autoneg)</st>
      <mac>ba:db:ad:ba:db:03</mac>
      <mode>(autoneg)</mode>
      <speed>ukn</speed>
      <id>18</id>
    </entry>
    <entry>
      <name>loopback</name>
      <duplex>[n/a]</duplex>
      <type>5</type>
      <state>up</state>
      <st>[n/a]/[n/a]/up</st>
      <mac>ba:db:ee:fb:ad:03</mac>
      <mode>(unknown)</mode>
      <speed>[n/a]</speed>
      <id>3</id>
    </entry>
    <entry>
      <name>tunnel</name>
      <duplex>[n/a]</duplex>
      <type>6</type>
      <state>up</state>
      <st>[n/a]/[n/a]/up</st>
      <mac>ba:db:ee:fb:ad:04</mac>
      <mode>(unknown)</mode>
      <speed>[n/a]</speed>
      <id>4</id>
    </entry>
  </hw>
</result></response>
END
}

sub static_phy_response {
    return  <<'END';
<response status="success"><result>
  <ifnet>
    <entry>
      <name>ethernet1/1</name>
      <zone/>
      <fwd>vwire:ethernet1/2</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>N/A</ip>
      <id>16</id>
      <addr/>
    </entry>
    <entry>
      <name>ethernet1/2</name>
      <zone/>
      <fwd>vwire:ethernet1/1</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>N/A</ip>
      <id>17</id>
      <addr/>
    </entry>
    <entry>
      <name>ethernet1/11</name>
      <zone>trust</zone>
      <fwd>vr:default</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>10.255.253.254/30</ip>
      <id>26</id>
      <addr/>
    </entry>
    <entry>
      <name>ethernet1/12</name>
      <zone>untrust</zone>
      <fwd>vr:default</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>10.255.254.254/30</ip>
      <id>27</id>
      <addr/>
    </entry>
    <entry>
      <name>ethernet1/13</name>
      <zone/>
      <fwd>ha</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>N/A</ip>
      <id>28</id>
      <addr/>
    </entry>
    <entry>
      <name>ha1</name>
      <zone/>
      <fwd>ha</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>N/A</ip>
      <id>5</id>
      <addr/>
    </entry>
    <entry>
      <name>ha2</name>
      <zone/>
      <fwd>ha</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>N/A</ip>
      <id>6</id>
      <addr/>
    </entry>
    <entry>
      <name>vlan</name>
      <zone/>
      <fwd>N/A</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>N/A</ip>
      <id>1</id>
      <addr/>
    </entry>
    <entry>
      <name>loopback</name>
      <zone/>
      <fwd>N/A</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>N/A</ip>
      <id>3</id>
      <addr/>
    </entry>
    <entry>
      <name>tunnel</name>
      <zone/>
      <fwd>N/A</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>N/A</ip>
      <id>4</id>
      <addr/>
    </entry>
    <entry>
      <name>tunnel.1</name>
      <zone>trust</zone>
      <fwd>vr:default</fwd>
      <vsys>1</vsys>
      <dyn-addr/>
      <addr6/>
      <tag>0</tag>
      <ip>N/A</ip>
      <id>256</id>
      <addr/>
    </entry>
  </ifnet>
  <hw>
    <entry>
      <name>ethernet1/1</name>
      <duplex>ukn</duplex>
      <type>0</type>
      <state>down</state>
      <st>ukn/ukn/down(power-down)</st>
      <mac>00:1b:17:c1:4e:10</mac>
      <mode>(power-down)</mode>
      <speed>ukn</speed>
      <id>16</id>
    </entry>
    <entry>
      <name>ethernet1/2</name>
      <duplex>ukn</duplex>
      <type>0</type>
      <state>down</state>
      <st>ukn/ukn/down(autoneg)</st>
      <mac>00:1b:17:c1:4e:11</mac>
      <mode>(autoneg)</mode>
      <speed>ukn</speed>
      <id>17</id>
    </entry>
    <entry>
      <name>ethernet1/11</name>
      <duplex>full</duplex>
      <type>0</type>
      <state>up</state>
      <st>1000/full/up</st>
      <mac>00:1b:17:c1:4e:1a</mac>
      <mode>(autoneg)</mode>
      <speed>1000</speed>
      <id>26</id>
    </entry>
    <entry>
      <name>ethernet1/12</name>
      <duplex>half</duplex>
      <type>0</type>
      <state>up</state>
      <st>10/half/up</st>
      <mac>00:1b:17:c1:4e:1b</mac>
      <mode>(forced)</mode>
      <speed>10</speed>
      <id>27</id>
    </entry>
    <entry>
      <name>ethernet1/13</name>
      <duplex>ukn</duplex>
      <type>0</type>
      <state>down</state>
      <st>ukn/ukn/down(autoneg)</st>
      <mac>00:1b:17:c1:4e:1c</mac>
      <mode>(autoneg)</mode>
      <speed>ukn</speed>
      <id>28</id>
    </entry>
    <entry>
      <name>ha1</name>
      <duplex>ukn</duplex>
      <type>2</type>
      <state>ukn</state>
      <st>ukn/ukn/ukn(autoneg)</st>
      <mac>00:1b:17:ff:ec:cb</mac>
      <mode>(autoneg)</mode>
      <speed>ukn</speed>
      <id>5</id>
    </entry>
    <entry>
      <name>ha2</name>
      <duplex>ukn</duplex>
      <type>2</type>
      <state>down</state>
      <st>ukn/ukn/down(autoneg)</st>
      <mac>00:1b:17:c1:4e:06</mac>
      <mode>(autoneg)</mode>
      <speed>ukn</speed>
      <id>6</id>
    </entry>
    <entry>
      <name>vlan</name>
      <duplex>[n/a]</duplex>
      <type>3</type>
      <state>up</state>
      <st>[n/a]/[n/a]/up</st>
      <mac>00:1b:17:c1:4e:01</mac>
      <mode>(unknown)</mode>
      <speed>[n/a]</speed>
      <id>1</id>
    </entry>
    <entry>
      <name>loopback</name>
      <duplex>[n/a]</duplex>
      <type>5</type>
      <state>up</state>
      <st>[n/a]/[n/a]/up</st>
      <mac>00:1b:17:c1:4e:03</mac>
      <mode>(unknown)</mode>
      <speed>[n/a]</speed>
      <id>3</id>
    </entry>
    <entry>
      <name>tunnel</name>
      <duplex>[n/a]</duplex>
      <type>6</type>
      <state>up</state>
      <st>[n/a]/[n/a]/up</st>
      <mac>00:1b:17:c1:4e:04</mac>
      <mode>(unknown)</mode>
      <speed>[n/a]</speed>
      <id>4</id>
    </entry>
  </hw>
</result></response>
END
}
