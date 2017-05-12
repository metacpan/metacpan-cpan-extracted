#!perl -w
use strict;
use Test::More;

use AnyEvent;
use LWP::Protocol::Coro::http;
use LWP::UserAgent;

# Check whether we can launch the local webserver
if (! eval {
    use lib '../inc', 'inc';
    require Test::HTTP::LocalServer;
    1;
}) {
    plan skip_all => "Couldn't launch test server: $@";
} else {
    plan tests => 3;
};

# Launch a timer
my $timer_events = 0;
my $t = AnyEvent->timer(
    after => 1, interval => 1, cb => sub { diag "Waiting for reply\n"; $timer_events++ }
);

my $client = LWP::UserAgent->new(requests_redirectable => []);

my $server = Test::HTTP::LocalServer->spawn(
    #debug => 1,
);
my $url = $server->referer;
diag "Retrieving URL: " . $url;

my $res = $client->get($url);
is $res->code, 204, "No Referer was sent"
   or diag($res->headers->as_string);

my $referer = "http://example.com";
$res = $client->get($url, Referer => $referer);
is $res->code, 302, "Sent Referer header";
is $res->header('Location'), $referer, "Sent expected Referer";

undef $t; # stop the timer

diag "Shutting down server";
$server->stop;
undef $server;
diag "Done";
