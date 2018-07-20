# (c) ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2018.
# See the LICENSE file for more details.

use strict;
use warnings;

use lib 't/';
use MockSite;
use EPFL::Net::ipv6Test qw/getWebAAAA getWebServer getWebDns p_buildUrl/;

use Test::Deep;
use Test::MockModule;
use Test::More tests => 20;

is(
  p_buildUrl('http://api.com/webaaaa.php', 'foobar.com', 0),
  'http://api.com/webaaaa.php?url=foobar.com',
  'correct url without scheme'
);

is(
  p_buildUrl('http://api.com/webaaaa.php', 'foobar.com', 1),
  'http://api.com/webaaaa.php?url=foobar.com&scheme=http',
  'correct url with scheme'
);

my $urlRoot = MockSite::mockLocalSite('t/resources/ipv6-test');

my $module = Test::MockModule->new('EPFL::Net::ipv6Test');
$module->mock(
  'p_buildUrl',
  sub {
    my ( $path, $domain, $withScheme ) = @_;
    return $urlRoot . q{/} . $domain . '.json';
  }
);

my $webaaaa = getWebAAAA(undef);
is( $webaaaa, undef, 'undef webaaaa' );
$webaaaa = getWebAAAA('foobar');
is( $webaaaa, undef, 'undef webaaaa' );
$webaaaa = getWebAAAA('webaaaa-good');
is( $webaaaa->{dns_aaaa}, '2400:cb00:2048:1::6814:e52a', 'good webaaaa');
$webaaaa = getWebAAAA('webaaaa-bad');
is( $webaaaa->{dns_aaaa}, 'null', 'bad webaaaa');
ok(defined $webaaaa->{error}, 'bad webaaaa error');

my $webserver = getWebServer(undef);
is( $webserver, undef, 'undef webserver' );
$webserver = getWebServer('foobar');
is( $webserver, undef, 'undef webserver' );
$webserver = getWebServer('webserver-good');
is( $webserver->{dns_aaaa}, '2400:cb00:2048:1::6814:e42a', 'good webserver');
is( $webserver->{server}, 'cloudflare', 'good webserver server');
is( $webserver->{title}, 'EPFL news', 'good webserver title');
$webserver = getWebServer('webserver-bad');
is( $webserver->{dns_aaaa}, 'null', 'bad webserver');
ok(defined $webserver->{error}, 'bad webserver error');

my $webdns = getWebDns(undef);
is( $webdns, undef, 'undef webdns' );
$webdns = getWebDns('foobar');
is( $webdns, undef, 'undef webdns' );
$webdns = getWebDns('webdns-good');
ok( $webdns->{dns_ok}, 'good webdns');
cmp_deeply(
  $webdns->{dns_servers},
  ['stisun1.epfl.ch','stisun2.epfl.ch'],
  'good webdns servers'
);
$webdns = getWebDns('webdns-bad');
ok( !$webdns->{dns_ok}, 'bad webdns');
cmp_deeply(
  $webdns->{dns_servers},
  [],
  'empty webdns servers'
);
