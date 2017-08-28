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

# No BFD configured
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_bfd_configured() )->simplify()->{result} } );

ok( !$test->bfd_peers_up() , "No BFD configured no args returns 0" );
ok( !$test->bfd_peers_up(interfaces => ['ethernet1/1']) , "No BFD configured one arg returns 0" );

# Single BFD peer (up) configured 
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( single_bfd_response() )->simplify(forcearray => ['entry'] )->{result} } );

ok( $test->bfd_peers_up() , "Single up BFD peer returns 1" );
ok( $test->bfd_peers_up(interfaces => ['ethernet1/23']) , "Single up BFD one arg specified that's up peer returns 1" );
ok( !$test->bfd_peers_up(interfaces => ['ethernet1/24']) , "Single up BFD one arg specified that doesn't exist 0" );

# Multiple BFD peers configured 
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( multi_bfd_response() )->simplify(forcearray => ['entry'] )->{result} } );

ok( !$test->bfd_peers_up() , "Multiple BGP peers (up & down) no arguments returns 0" );
ok( $test->bfd_peers_up(interfaces => ['ethernet1/23']) , "Multiple BGP peers (up & down) one arg that's up returns 1" );
ok( $test->bfd_peers_up(interfaces => ['ethernet1/23', 'ethernet1/22.16']) , "Multiple BGP peers (up & down) two args that are both up returns 1" );
ok( !$test->bfd_peers_up(interfaces => ['ethernet1/23', 'ethernet1/28']) , "Multiple BGP peers (up & down) two args one that doesn't exist returns 0" );
ok( !$test->bfd_peers_up(interfaces => ['ethernet1/23', 'ethernet1/22.32']) , "Multiple BGP peers (up & down) two args one that's down returns 0" );

sub no_bfd_configured {
   return <<'END'
<response status="success"><result></result></response>
END
}


sub single_bfd_response {
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
</result>
</response>
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

