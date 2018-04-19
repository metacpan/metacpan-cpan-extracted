# (c) ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2017-2018.
# See the LICENSE file for more details.

use strict;
use warnings;

use lib 't/';
use MockSite;
use EPFL::Sciper::List qw/p_createUserAgent p_getUrl/;

use Test::More tests => 5;

my $urlRoot = MockSite::mockLocalSite('t/resources/epfl-search');

my $ua = p_createUserAgent();

is( $ua->timeout,      1200,        'timeout' );
is( $ua->agent,        'DevRunBot', 'user agent' );
is( $ua->max_redirect, 10,          'max redirect' );

my $response = p_getUrl( $ua, $urlRoot . '/a.json' );
is( $response->code, 200, 'http status ok' );

$response = p_getUrl( $ua, $urlRoot . '/foobar.html' );
is( $response->code, 404, 'http status not found' );
