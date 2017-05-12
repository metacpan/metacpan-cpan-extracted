use strict;
use warnings;

use Test::More tests => 4;
use HTTP::Request;
use HTTP::Cookies;
use HTTP::Async;

use FindBin;
use lib "$FindBin::Bin";
require TestServer;

my $s        = TestServer->new();
my $url_root = $s->started_ok("starting a test server");

my $q = HTTP::Async->new;

my $cookie_jar = HTTP::Cookies->new({});
$q->cookie_jar($cookie_jar);

# Receive a cookie and store it in a cookie jar
{
    my $url = "$url_root/foo/bar?cookie=1";

    my $req = HTTP::Request->new('GET', $url);
    ok $q->add($req), "Added request to the queue";
    $q->poke while !$q->to_return_count;

    my $res = $q->next_response;
    my $response_cookie = $res->header('Set-Cookie');
    ok $response_cookie =~ m/x=test/, "Got cookie in response '$response_cookie'";

    my $jar_cookie = $cookie_jar->as_string();
    ok $jar_cookie =~ m/x=test/, "Got cookie from cookie jar '$jar_cookie'";
}
