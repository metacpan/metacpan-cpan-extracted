#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;
use XML::Twig;

use Device::PaloAlto::Firewall;

plan tests => 13;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test', debug => 1);
my $test = $fw->tester();

# System Info 
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( system_info_vm() )->simplify(forcearray => ['entry'] )->{result} } );

isa_ok( $fw->system_info(), 'HASH' );

# When reading the tests below, when we talk about "higher" or "lower", we're referring to the 
# argument passed to the method. I.e. "Higher sub-version" means the argument passed should be greater than
# the version received from the firewall

ok( $test->version(version => '7.2.3'), "Matched version returns 1" );
ok( !$test->version(version => '7.2.4'), "Higher sub-sub-version argument returns 0" );
ok( !$test->version(version => '7.3.0'), "Higher sub-version argument returns 0" );
ok( !$test->version(version => '8.0.0'), "Higher major release argument returns 0" );
ok( $test->version(version => '7.2.3-h2'), "Hotfix above release argument returns 1" );
ok( $test->version(version => '7.2.2-h2'), "Hotfix below release argument returns 1" );

ok( $test->version(version => '7.2.2'), "Lower sub-sub-version returns 1" );
ok( $test->version(version => '7.1.0'), "Lower sub-version returns 1" );
ok( $test->version(version => '6.0.0'), "Lower major release returns 1" );

# System Info with Hotfix
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( system_info_hotfix_version() )->simplify(forcearray => ['entry'] )->{result} } );

ok( $test->version(version => '7.2.3-h2'), "Matched hotfix version returns 1" );
ok( $test->version(version => '7.2.3-h3'), "Hotfix version above returns 0" );
ok( $test->version(version => '7.2.3-h1'), "Hotfix version below returns 1" );


sub system_info_vm {
   return <<'END'
<response status="success"><result><system><hostname>PA-VM</hostname><ip-address>192.168.122.21</ip-address><netmask>255.255.255.0</netmask><default-gateway>192.168.122.1</default-gateway><ipv6-address>unknown</ipv6-address><ipv6-link-local-address>fe80::5054:ff:fe22:b2e4/64</ipv6-link-local-address><ipv6-default-gateway></ipv6-default-gateway><mac-address>52:54:00:22:b2:e4</mac-address><time>Mon Aug 28 21:07:11 2017
</time>
<uptime>0 days, 3:46:33</uptime>
<devicename>PA-VM</devicename>
<family>vm</family><model>PA-VM</model><serial>unknown</serial><vm-mac-base>BA:DB:EE:FB:AD:00</vm-mac-base><vm-mac-count>255</vm-mac-count><vm-uuid>unknown</vm-uuid><vm-cpuid>C1060200FDFB8B07</vm-cpuid><vm-license>none</vm-license><sw-version>7.2.3</sw-version>
<global-protect-client-package-version>0.0.0</global-protect-client-package-version>
<app-version>497-2688</app-version>
<app-release-date>unknown</app-release-date>
<av-version>0</av-version>
<av-release-date>unknown</av-release-date>
<threat-version>0</threat-version>
<threat-release-date>unknown</threat-release-date>
<wf-private-version>0</wf-private-version>
<wf-private-release-date>unknown</wf-private-release-date>
<url-db>paloaltonetworks</url-db>
<wildfire-version>0</wildfire-version>
<wildfire-release-date>unknown</wildfire-release-date>
<url-filtering-version>0000.00.00.000</url-filtering-version>
<global-protect-datafile-version>0</global-protect-datafile-version>
<global-protect-datafile-release-date>unknown</global-protect-datafile-release-date><logdb-version>7.0.9</logdb-version>
<platform-family>vm</platform-family>
<vpn-disable-mode>off</vpn-disable-mode>
<multi-vsys>off</multi-vsys>
<operational-mode>normal</operational-mode>
</system></result></response>
END
}

sub system_info_hotfix_version {
   return <<'END'
<response status="success"><result><system><hostname>PA-VM</hostname><ip-address>192.168.122.21</ip-address><netmask>255.255.255.0</netmask><default-gateway>192.168.122.1</default-gateway><ipv6-address>unknown</ipv6-address><ipv6-link-local-address>fe80::5054:ff:fe22:b2e4/64</ipv6-link-local-address><ipv6-default-gateway></ipv6-default-gateway><mac-address>52:54:00:22:b2:e4</mac-address><time>Mon Aug 28 21:07:11 2017
</time>
<uptime>0 days, 3:46:33</uptime>
<devicename>PA-VM</devicename>
<family>vm</family><model>PA-VM</model><serial>unknown</serial><vm-mac-base>BA:DB:EE:FB:AD:00</vm-mac-base><vm-mac-count>255</vm-mac-count><vm-uuid>unknown</vm-uuid><vm-cpuid>C1060200FDFB8B07</vm-cpuid><vm-license>none</vm-license><sw-version>7.2.3-h2</sw-version>
<global-protect-client-package-version>0.0.0</global-protect-client-package-version>
<app-version>497-2688</app-version>
<app-release-date>unknown</app-release-date>
<av-version>0</av-version>
<av-release-date>unknown</av-release-date>
<threat-version>0</threat-version>
<threat-release-date>unknown</threat-release-date>
<wf-private-version>0</wf-private-version>
<wf-private-release-date>unknown</wf-private-release-date>
<url-db>paloaltonetworks</url-db>
<wildfire-version>0</wildfire-version>
<wildfire-release-date>unknown</wildfire-release-date>
<url-filtering-version>0000.00.00.000</url-filtering-version>
<global-protect-datafile-version>0</global-protect-datafile-version>
<global-protect-datafile-release-date>unknown</global-protect-datafile-release-date><logdb-version>7.0.9</logdb-version>
<platform-family>vm</platform-family>
<vpn-disable-mode>off</vpn-disable-mode>
<multi-vsys>off</multi-vsys>
<operational-mode>normal</operational-mode>
</system></result></response>
END
}
