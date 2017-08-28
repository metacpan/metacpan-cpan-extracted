#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;
use XML::Twig;

use Device::PaloAlto::Firewall;

plan tests => 14;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test', debug => 1);
my $test = $fw->tester();

# No HA Configured
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_ha_configured() )->simplify( forcearray => ['entry'] )->{result} } );

ok( !$test->ha_enabled(), "ha_enabled(): No HA configured" );
ok( !$test->ha_state(state => 'active'), "ha_state(): Test for 'active' on no HA configured firewall" );
ok( !$test->ha_state(state => 'passive'), "ha_state(): Test for 'passive' on no HA configured firewall" );

ok( !$test->ha_version(), "ha_version(): No HA Configured");

ok( !$test->ha_peer_up(), "ha_peer_up(): No HA Configured");

ok( !$test->ha_config_sync(), "ha_config_sync(): No HA Configured");


# HA Configured and Active
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( ha_active() )->simplify( forcearray => ['entry'] )->{result} } );

ok( $test->ha_enabled(), "ha_enabled(): HA Configured and Active" );
ok( $test->ha_state(state => 'active'), "ha_state(): Test for 'active' on acive firewall" );
ok( $test->ha_state(state => 'aCtIvE'), "ha_state(): Test for 'aCtIvE' case sensitivity on acive firewall" );

ok( !$test->ha_state(state => 'passive'), "ha_state(): Test for 'passive' on acive firewall" );
ok( !$test->ha_state(state => 'pAsSiVe'), "ha_state(): Test for 'pAsSiVe' case sensitivity on acive firewall" );

ok( $test->ha_version(), "ha_version(): HA Configured and Active with version matches");

ok( $test->ha_peer_up(), "ha_peer_up(): HA configured and active");

ok( $test->ha_config_sync(), "ha_config_sync(): HA configured and active, configuration synchronised");

sub no_ha_configured {
    return <<'END'
<response status="success"><result><enabled>no</enabled><group><local-info><ha1-encrypt-imported>no</ha1-encrypt-imported></local-info></group></result></response>
END
}

sub ha_active {
   return <<'END'
<?xml version="1.0" encoding="UTF-8"?>
<response status="success">
   <result>
      <enabled>yes</enabled>
      <group>
         <mode>Active-Passive</mode>
         <local-info>
            <url-compat>Match</url-compat>
            <app-version>675-3915</app-version>
            <gpclient-version>4.0.0</gpclient-version>
            <build-rel>7.1.9</build-rel>
            <ha2-port>dedicated-ha2</ha2-port>
            <av-version>2187-2674</av-version>
            <ha1-encrypt-enable>no</ha1-encrypt-enable>
            <url-version>0000.00.00.000</url-version>
            <mgmt-hb>configured</mgmt-hb>
            <platform-model>PA-5060</platform-model>
            <av-compat>Match</av-compat>
            <ha2-ipaddr>169.254.0.5/30</ha2-ipaddr>
            <vpnclient-compat>Match</vpnclient-compat>
            <ha1-ipaddr>169.254.0.1/30</ha1-ipaddr>
            <state-sync-type>ethernet</state-sync-type>
            <vpnclient-version>Not Installed</vpnclient-version>
            <ha2-macaddr>d4:f4:be:9a:76:06</ha2-macaddr>
            <monitor-fail-holdup>0</monitor-fail-holdup>
            <priority>64</priority>
            <preempt-hold>1</preempt-hold>
            <state>active</state>
            <version>1</version>
            <promotion-hold>2000</promotion-hold>
            <threat-compat>Match</threat-compat>
            <state-sync>Complete</state-sync>
            <addon-master-holdup>500</addon-master-holdup>
            <heartbeat-interval>1000</heartbeat-interval>
            <ha1-link-mon-intv>3000</ha1-link-mon-intv>
            <hello-interval>8000</hello-interval>
            <ha1-port>dedicated-ha1</ha1-port>
            <ha1-encrypt-imported>no</ha1-encrypt-imported>
            <mgmt-ip>192.168.192.50/24</mgmt-ip>
            <preempt-flap-cnt>0</preempt-flap-cnt>
            <nonfunc-flap-cnt>0</nonfunc-flap-cnt>
            <threat-version>675-3915</threat-version>
            <ha1-macaddr>00:90:0b:4b:3b:d3</ha1-macaddr>
            <state-duration>4235256</state-duration>
            <max-flaps>3</max-flaps>
            <active-passive>
               <passive-link-state>auto</passive-link-state>
               <monitor-fail-holddown>1</monitor-fail-holddown>
            </active-passive>
            <mgmt-ipv6 />
            <last-error-state>suspended</last-error-state>
            <preemptive>yes</preemptive>
            <gpclient-compat>Match</gpclient-compat>
            <mode>Active-Passive</mode>
            <build-compat>Match</build-compat>
            <last-error-reason>User requested</last-error-reason>
            <app-compat>Match</app-compat>
         </local-info>
         <peer-info>
            <app-version>675-3915</app-version>
            <gpclient-version>4.0.0</gpclient-version>
            <url-version>0000.00.00.000</url-version>
            <platform-model>PA-5060</platform-model>
            <ha2-ipaddr>169.254.0.6</ha2-ipaddr>
            <ha1-ipaddr>169.254.0.2</ha1-ipaddr>
            <vm-license />
            <ha2-macaddr>d4:f4:be:9a:8b:06</ha2-macaddr>
            <priority>128</priority>
            <state>passive</state>
            <version>1</version>
            <conn-mgmt>
               <conn-status>up</conn-status>
               <conn-desc>heartbeat status</conn-desc>
            </conn-mgmt>
            <last-error-reason>User requested</last-error-reason>
            <build-rel>7.1.9</build-rel>
            <conn-status>up</conn-status>
            <av-version>2187-2674</av-version>
            <vpnclient-version>Not Installed</vpnclient-version>
            <mgmt-ip>192.168.192.51/24</mgmt-ip>
            <conn-ha2>
               <conn-status>up</conn-status>
               <conn-ka-enbled>no</conn-ka-enbled>
               <conn-primary>yes</conn-primary>
               <conn-desc>link status</conn-desc>
            </conn-ha2>
            <threat-version>675-3915</threat-version>
            <ha1-macaddr>00:90:0b:4b:39:f9</ha1-macaddr>
            <conn-ha1>
               <conn-status>up</conn-status>
               <conn-primary>yes</conn-primary>
               <conn-desc>heartbeat status</conn-desc>
            </conn-ha1>
            <state-duration>4235256</state-duration>
            <mgmt-ipv6 />
            <last-error-state>suspended</last-error-state>
            <preemptive>yes</preemptive>
            <mode>Active-Passive</mode>
         </peer-info>
         <link-monitoring>
            <fail-cond>any</fail-cond>
            <enabled>no</enabled>
            <groups>
               <entry>
                  <interface>
                     <entry>
                        <status>up</status>
                        <name>ethernet1/21</name>
                     </entry>
                     <entry>
                        <status>up</status>
                        <name>ethernet1/22</name>
                     </entry>
                  </interface>
                  <fail-cond>all</fail-cond>
                  <enabled>yes</enabled>
                  <name>Border Links</name>
               </entry>
               <entry>
                  <interface>
                     <entry>
                        <status>up</status>
                        <name>ethernet1/23</name>
                     </entry>
                     <entry>
                        <status>up</status>
                        <name>ethernet1/24</name>
                     </entry>
                  </interface>
                  <fail-cond>all</fail-cond>
                  <enabled>yes</enabled>
                  <name>Corp to Ops Link</name>
               </entry>
            </groups>
         </link-monitoring>
         <path-monitoring>
            <vwire />
            <fail-cond>any</fail-cond>
            <vlan />
            <enabled>no</enabled>
            <vrouter />
         </path-monitoring>
         <running-sync>synchronized</running-sync>
         <running-sync-enabled>yes</running-sync-enabled>
      </group>
   </result>
</response>
END
}
