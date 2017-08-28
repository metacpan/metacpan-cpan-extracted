#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;
use XML::Twig;

use Device::PaloAlto::Firewall;

plan tests => 8;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test', debug => 1);
my $test = $fw->tester();

# No servers configured
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( no_servers_configured() )->simplify( forcearray => ['entry'] )->{result} } );

ok( !$test->userid_server_monitor(), "No servers configured no args returns 0" );
ok( !$test->userid_server_monitor(servers => ['ad01.domain.int']), "No servers configured some args returns 0" );

# Servers configured some not connected
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( servers_configured_some_not_connected() )->simplify( forcearray => ['entry'] )->{result} } );

ok( $test->userid_server_monitor(servers => ['ad02.domain.int']), "One connected server matched returns 1" );
ok( !$test->userid_server_monitor(servers => ['ad01.domain.int']), "One not connected server matched returns 0" );

ok( $test->userid_server_monitor(servers => ['ad02.domain.int', 'ad04.domain.int']), "Multiple connected servers matched returns 1" );
ok( !$test->userid_server_monitor(servers => ['ad01.domain.int', 'ad02.domain.int']), "Multiple servers one not connected returns 0" );

ok( !$test->userid_server_monitor(), "No servers arg and servers not connected in response returns 0" );

# Servers configured all connected
$fw->meta->add_method('_send_request', sub { return XML::Twig->new()->safe_parse( servers_configured_all_connected() )->simplify( forcearray => ['entry'] )->{result} } );

ok( $test->userid_server_monitor(), "No servers arg and all servers connected in response returns 1" );

sub no_servers_configured {
    return <<'END'
<response status="success"><result/></response>
END
}

sub servers_configured_some_not_connected {
   return <<'END'
<response status="success">
<result>
<entry name="ad01.domain.int">
<vsys>vsys1</vsys>
<connected>Connection timeout</connected>
</entry>
<entry name="ad02.domain.int">
<vsys>vsys1</vsys>
<connected>Connected</connected>
</entry>
<entry name="ad03.domain.int">
<vsys>vsys1</vsys>
<connected>Connected</connected>
</entry>
<entry name="ad04.domain.int">
<vsys>vsys1</vsys>
<connected>Connected</connected>
</entry>
<entry name="ad05.domain.int">
<vsys>vsys1</vsys>
<connected>Connection timeout</connected>
</entry>
<entry name="ad06.domain.int">
<vsys>vsys1</vsys>
<connected>Connection timeout</connected>
</entry>
<entry name="ad07.domain.int">
<vsys>vsys1</vsys>
<connected>Connection timeout</connected>
</entry>
<entry name="ad08.domain.int">
<vsys>vsys1</vsys>
<connected>Connection timeout</connected>
</entry>
</result>
</response>
END
}

sub servers_configured_all_connected {
   return <<'END'
<response status="success">
<result>
<entry name="ad02.domain.int">
<vsys>vsys1</vsys>
<connected>Connected</connected>
</entry>
<entry name="ad03.domain.int">
<vsys>vsys1</vsys>
<connected>Connected</connected>
</entry>
<entry name="ad04.domain.int">
<vsys>vsys1</vsys>
<connected>Connected</connected>
</entry>
</result>
</response>
END
}
