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
    plan tests => 2;
};

# Launch a timer
my $timer_events = 0;
my $t = AnyEvent->timer(
    after => 1, interval => 1, cb => sub { diag "Waiting for reply\n"; $timer_events++ }
);

my $client = LWP::UserAgent->new();

my $server = Test::HTTP::LocalServer->spawn(
    #debug => 1,
);
my $url = $server->url;
diag "Retrieving URL: " . $url;

$client->proxy(http => $url);

my $fetch_url = "http://no.such.domain";
my $res = $client->get($fetch_url);
is $res->code, 404, "Got response";

is $res->content, $fetch_url, "Sent proxy requet";


undef $t; # stop the timer

diag "Shutting down server";
$server->stop;
undef $server;
diag "Done";
