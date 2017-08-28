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

plan tests => 10;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test', debug => 1);
my $test = $fw->tester();

# No NTP peers configured, using local synching
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_peers() )->simplify()->{result} } );

ok( !$test->ntp_synchronised(), "ntp_synchronised(): No NTP peer configured");
ok( !$test->ntp_reachable(), "ntp_reachable(): No NTP peer configured");

# Single NTP peer, synchronised
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( single_ntp_peer_synced() )->simplify( forcearray => ['entry'] )->{result} } );

ok( $test->ntp_synchronised(), "ntp_synchronised(): Single synchronised NTP peer");
ok( $test->ntp_reachable(), "ntp_reachable(): Single synchronised NTP peer");

# Single NTP peer, not synchronised
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( single_ntp_peer_not_synced() )->simplify( forcearray => ['entry'] )->{result} } );

ok( !$test->ntp_synchronised(), "ntp_synchronised(): Single unsynchronised NTP peer");
ok( !$test->ntp_reachable(), "ntp_reachable(): Single unsynchronised NTP peer");

# Multiple NTP peers, one synchronised, one not
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( multiple_peers_one_not_reachable() )->simplify( forcearray => ['entry'] )->{result} } );

ok( $test->ntp_synchronised(), "ntp_synchronised(): Two NTP peers, one synchronised, one not");
ok( !$test->ntp_reachable(), "ntp_reachable(): Two NTP peers, one synchronised, one not");

# Multiple NTP peers, both reachable, one synched.
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( multiple_peers_both_reachable() )->simplify( forcearray => ['entry'] )->{result} } );

ok( $test->ntp_synchronised(), "ntp_synchronised(): Two NTP peers, one synchronised, both reachable");
ok( $test->ntp_reachable(), "ntp_reachable(): Two NTP peers, one synchronised, both reachable");


sub single_ntp_peer_synced {
    return <<'END'
<response status="success"><result>
  <ntp-server-1>
    <status>synched</status>
    <authentication-type>none</authentication-type>
    <reachable>yes</reachable>
    <name>203.122.222.149</name>
  </ntp-server-1>
  <synched>203.122.222.149</synched>
</result></response>
END
}

sub single_ntp_peer_not_synced {
	return <<'END'
<response status="success"><result>
  <ntp-server-1>
    <status>rejected</status>
    <authentication-type>none</authentication-type>
    <reachable>no</reachable>
    <name>202.122.222.150</name>
  </ntp-server-1>
  <synched>LOCAL</synched>
</result></response>
END
}

sub multiple_peers_one_not_reachable {
	return <<'END'
<response status="success"><result>
  <synched>203.122.222.149</synched>
  <ntp-server-1>
    <status>rejected</status>
    <authentication-type>none</authentication-type>
    <reachable>no</reachable>
    <name>202.122.222.150</name>
  </ntp-server-1>
  <ntp-server-2>
    <status>synched</status>
    <authentication-type>none</authentication-type>
    <reachable>yes</reachable>
    <name>203.122.222.149</name>
  </ntp-server-2>
</result></response>
END
}

sub multiple_peers_both_reachable {
    return <<'END'
<response status="success"><result>
  <synched>192.168.174.199</synched>
  <ntp-server-1>
    <status>synched</status>
    <authentication-type>none</authentication-type>
    <reachable>yes</reachable>
    <name>192.168.174.199</name>
  </ntp-server-1>
  <ntp-server-2>
    <status>available</status>
    <authentication-type>none</authentication-type>
    <reachable>yes</reachable>
    <name>192.168.10.199</name>
  </ntp-server-2>
</result></response>
END
}

sub no_peers {
	return <<'END'
<response status="success">
<result>
<synched>LOCAL</synched>
</result>
</response>
END
}
