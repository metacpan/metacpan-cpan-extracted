use strict;
use warnings;

use lib 't/';
use MockSite;
use HON::Http::UrlChecker::Service qw/p_createUserAgent p_getUrl/;

use Test::More tests => 5;

my $urlRoot = MockSite::mockLocalSite('t/resources/t-gone');

my $ua = p_createUserAgent();

is($ua->timeout, 1200, 'timeout');
is($ua->agent, 'HonBot', 'user agent');
is($ua->max_redirect, 10, 'max redirect');

my $response = p_getUrl($ua, $urlRoot . '/index.html');
is($response->code, 200, 'http status ok');

$response = p_getUrl($ua, $urlRoot . '/foobar.html');
is($response->code, 404, 'http status not found');
