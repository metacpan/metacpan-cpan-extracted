use Test::More tests => 11;

END { ok($loaded, "Should load and not die") }
use File::Scan::ClamAV;
$loaded++;

my $av = File::Scan::ClamAV->new();
ok($av, "Init Ok");
cmp_ok($av->host, 'eq', 'localhost', 'Default localhost');
cmp_ok($av->port, 'eq', '/tmp/clamd', 'Default port /tmp/clamd');

$av = File::Scan::ClamAV->new(
    port => '2030',
    host => 'awesome.host',
);

ok($av, "Init Ok");
cmp_ok($av->host, 'eq', 'awesome.host', 'Non default host');
cmp_ok($av->port, 'eq', '2030', 'Non default port');

my $result = $av->host('too.awesome.host');
cmp_ok($av->host, 'eq', 'too.awesome.host', 'Set host at runtime');
cmp_ok($result, 'eq', 'too.awesome.host', 'Host set result at runtime');

$result = $av->port('/tmp/socket');
cmp_ok($av->port, 'eq', '/tmp/socket', 'Set port at runtime');
cmp_ok($result, 'eq', '/tmp/socket', 'Port set result at runtime');
