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
    plan tests => 5;
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
my $url = $server->chunked;
diag "Retrieving URL: " . $url;

my $chunk_count;
my $res = $client->get($url, ':content_cb' => sub {
    diag "Got chunk";
    $chunk_count++
});
ok $res->is_success, "We made a successfull request";
is $res->code, 200, "Yes, real success";
is $res->content, '', "We got an empty response";
is $chunk_count, 5, "We received 5 chunks";
cmp_ok $timer_events, '>', 3, "Retrieving the data took more than 3 seconds (because the server sleeps)";

undef $t; # stop the timer

diag "Shutting down server";
$server->stop;
undef $server;
diag "Done";
