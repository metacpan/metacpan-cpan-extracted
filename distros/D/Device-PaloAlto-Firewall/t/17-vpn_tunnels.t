#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;
use XML::Twig;

use Device::PaloAlto::Firewall;

plan tests => 10;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test', debug => 1);
my $test = $fw->tester();

# No configuration
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_tunnels_configured() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->vpn_tunnels(), 'ARRAY' );
is_deeply( $fw->vpn_tunnels(), [] , "No IPSEC configured returns an empty ARRAYREF" );

ok( !$test->vpn_tunnels_up(peer_ips => ['192.168.122.30']), "No IPSEC config returns 0" );

# No IKE or IPSEC up
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_ike_no_ipsec_up() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->vpn_tunnels(), 'ARRAY' );

ok( !$test->vpn_tunnels_up(peer_ips => ['192.168.122.30']), "No IKE or IPSEC up returns 0" );

# IKE up, IPSEC down
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( ike_up_ipsec_down() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->vpn_tunnels(), 'ARRAY' );

ok( !$test->vpn_tunnels_up(peer_ips => ['192.168.122.30']), "IKE up, IPSEC down returns 0" );

# All up
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( all_up() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->vpn_tunnels(), 'ARRAY' );

ok( $test->vpn_tunnels_up(peer_ips => ['192.168.122.30']), "IKE and IPSEC up returns 1" );
ok( !$test->vpn_tunnels_up(peer_ips => ['192.168.122.30', '192.168.1.29']), "One peer up, one peer down returns 0" );




sub no_tunnels_configured {
   return <<'END'
<response status="success"><result><total>0</total><num_ipsec>0</num_ipsec><IPSec/><dp>dp0</dp><num_sslvpn>0</num_sslvpn></result></response>
END
}

sub no_ike_no_ipsec_up {
   return <<'END'
<response status="success"><result>
  <total>1</total>
  <num_ipsec>1</num_ipsec>
  <IPSec>
    <entry>
      <pkt-decap>0</pkt-decap>
      <keytype>auto key</keytype>
      <anti-replay>False</anti-replay>
      <natt-lp>0</natt-lp>
      <dec-err>0</dec-err>
      <inner-warn>0</inner-warn>
      <owner>1</owner>
      <id>1</id>
      <enc>not established</enc>
      <monitor>
        <status>False</status>
        <on>False</on>
        <pkt-recv>0</pkt-recv>
        <pkt-seen>0</pkt-seen>
        <interval>0</interval>
        <pkt-reply>0</pkt-reply>
        <threshold>0</threshold>
        <pkt-sent>0</pkt-sent>
      </monitor>
      <start>6233</start>
      <copy-tos>False</copy-tos>
      <natt>False</natt>
      <remote-spi>D04C9BBD</remote-spi>
      <state>inactive</state>
      <pkt-lifesize>0</pkt-lifesize>
      <inner-if>tunnel.1</inner-if>
      <sid>0</sid>
      <type>IPSec</type>
      <byte-decap>0</byte-decap>
      <peerip>192.168.122.30</peerip>
      <owner-cpuid>0</owner-cpuid>
      <seq-recv>0</seq-recv>
      <timestamp>6233</timestamp>
      <acquire>0</acquire>
      <seq-send>0</seq-send>
      <auth>not established</auth>
      <pkt-encap>0</pkt-encap>
      <pkt-replay>0</pkt-replay>
      <natt-rp>0</natt-rp>
      <localip>192.168.122.19</localip>
      <local-spi>F78B4DAD</local-spi>
      <name>c1000v</name>
      <outer-if>ethernet1/1</outer-if>
      <auth-err>0</auth-err>
      <owner-state>0</owner-state>
      <proto>ESP</proto>
      <gwid>1</gwid>
      <mtu>1436</mtu>
      <subtype>None</subtype>
      <byte-encap>0</byte-encap>
      <context>10</context>
      <pkt-lifetime>0</pkt-lifetime>
    </entry>
  </IPSec>
  <dp>dp0</dp>
  <num_sslvpn>0</num_sslvpn>
</result></response>
END
}

sub ike_up_ipsec_down {
   return <<'END'
<response status="success"><result>
  <total>1</total>
  <num_ipsec>1</num_ipsec>
  <IPSec>
    <entry>
      <pkt-decap>0</pkt-decap>
      <keytype>auto key</keytype>
      <anti-replay>False</anti-replay>
      <natt-lp>0</natt-lp>
      <dec-err>0</dec-err>
      <inner-warn>0</inner-warn>
      <owner>1</owner>
      <id>1</id>
      <enc>not established</enc>
      <monitor>
        <status>False</status>
        <on>False</on>
        <pkt-recv>0</pkt-recv>
        <pkt-seen>0</pkt-seen>
        <interval>0</interval>
        <pkt-reply>0</pkt-reply>
        <threshold>0</threshold>
        <pkt-sent>0</pkt-sent>
      </monitor>
      <start>4780</start>
      <copy-tos>False</copy-tos>
      <natt>False</natt>
      <remote-spi>00000000</remote-spi>
      <state>init</state>
      <pkt-lifesize>0</pkt-lifesize>
      <inner-if>tunnel.1</inner-if>
      <sid>306</sid>
      <type>IPSec</type>
      <byte-decap>0</byte-decap>
      <peerip>192.168.122.30</peerip>
      <owner-cpuid>0</owner-cpuid>
      <seq-recv>0</seq-recv>
      <timestamp>4780</timestamp>
      <acquire>0</acquire>
      <seq-send>0</seq-send>
      <auth>not established</auth>
      <pkt-encap>0</pkt-encap>
      <pkt-replay>0</pkt-replay>
      <natt-rp>0</natt-rp>
      <localip>192.168.122.19</localip>
      <local-spi>00000000</local-spi>
      <name>c1000v</name>
      <outer-if>ethernet1/1</outer-if>
      <auth-err>0</auth-err>
      <owner-state>0</owner-state>
      <proto>ESP</proto>
      <gwid>1</gwid>
      <mtu>1448</mtu>
      <subtype>None</subtype>
      <byte-encap>0</byte-encap>
      <context>5</context>
      <pkt-lifetime>0</pkt-lifetime>
    </entry>
  </IPSec>
  <dp>dp0</dp>
  <num_sslvpn>0</num_sslvpn>
</result></response>
END
}


sub all_up {
   return <<'END'
<response status="success"><result>
  <total>1</total>
  <num_ipsec>1</num_ipsec>
  <IPSec>
    <entry>
      <pkt-decap>0</pkt-decap>
      <keytype>auto key</keytype>
      <anti-replay>False</anti-replay>
      <natt-lp>0</natt-lp>
      <dec-err>0</dec-err>
      <inner-warn>0</inner-warn>
      <owner>1</owner>
      <id>1</id>
      <enc>3des</enc>
      <monitor>
        <status>False</status>
        <on>False</on>
        <pkt-recv>0</pkt-recv>
        <pkt-seen>0</pkt-seen>
        <interval>0</interval>
        <pkt-reply>0</pkt-reply>
        <threshold>0</threshold>
        <pkt-sent>0</pkt-sent>
      </monitor>
      <start>5304</start>
      <copy-tos>False</copy-tos>
      <last-rekey>166</last-rekey>
      <natt>False</natt>
      <remote-spi>83901465</remote-spi>
      <state>active</state>
      <pkt-lifesize>0</pkt-lifesize>
      <inner-if>tunnel.1</inner-if>
      <sid>331</sid>
      <type>IPSec</type>
      <byte-decap>0</byte-decap>
      <peerip>192.168.122.30</peerip>
      <owner-cpuid>0</owner-cpuid>
      <seq-recv>0</seq-recv>
      <timestamp>5304</timestamp>
      <acquire>0</acquire>
      <seq-send>0</seq-send>
      <auth>md5</auth>
      <pkt-encap>0</pkt-encap>
      <pkt-replay>0</pkt-replay>
      <natt-rp>0</natt-rp>
      <localip>192.168.122.19</localip>
      <local-spi>B5102BDB</local-spi>
      <name>c1000v</name>
      <outer-if>ethernet1/1</outer-if>
      <auth-err>0</auth-err>
      <owner-state>0</owner-state>
      <proto>ESP</proto>
      <gwid>1</gwid>
      <mtu>1436</mtu>
      <subtype>None</subtype>
      <remain>3434</remain>
      <byte-encap>0</byte-encap>
      <context>6</context>
      <pkt-lifetime>0</pkt-lifetime>
    </entry>
  </IPSec>
  <dp>dp0</dp>
  <num_sslvpn>0</num_sslvpn>
</result></response>
END
}
