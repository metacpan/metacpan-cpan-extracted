use strict;
use warnings;

use lib 't/';
use MockSite;
use HON::Http::UrlChecker::Service qw/checkUrl/;

use Test::Exception;
use Test::More tests => 13;

my $urlRoot = MockSite::mockLocalSite('t/resources/t-gone');

my @list = checkUrl($urlRoot . '/index.html');
is(scalar @list, 1, 'a simple 200 response');
is($list[0]->{code}, 200, 'code should be 200');
is($list[0]->{message}, undef, 'not defined message');
is($list[0]->{title}, 'Tinnitus Treatment From T-Gone', '');

@list = checkUrl($urlRoot . '/foobar.html');
is(scalar @list, 1, 'a simple 404 response');
is($list[0]->{code}, 404, 'code should be 404');
like($list[0]->{message}, qr/Does Not Exist/, 'message should contain not');

my @wrongUrls = (
  '://', 'www.example.com', 'example.com/abc', '://example.com', '', 'http:',
);
foreach my $url (@wrongUrls){
  throws_ok { checkUrl($url) } qr/Wrong url: $url/;
}
