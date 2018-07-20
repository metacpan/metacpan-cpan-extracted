# (c) ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2018.
# See the LICENSE file for more details.

use strict;
use warnings;

use lib 't/';
use MockSite;
use EPFL::Net::ipv6Test qw/p_createUserAgent p_getUrl/;

use Test::More tests => 5;

my $urlRoot = MockSite::mockLocalSite('t/resources/ipv6-test/');

my $ua = p_createUserAgent();

is( $ua->timeout,      1200,                   'timeout' );
is( $ua->agent,        'IDevelopBot - v1.0.0', 'user agent' );
is( $ua->max_redirect, 10,                     'max redirect' );

my $response = p_getUrl( $ua, $urlRoot . '/webaaaa-good.json' );
is( $response->code, 200, 'http status ok' );

$response = p_getUrl( $ua, $urlRoot . '/foobar.html' );
is( $response->code, 404, 'http status not found' );
