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
    plan tests => 4;
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
my $url = $server->error_after_headers;
diag "Retrieving URL: " . $url;

my $chunk_count;
my $res = $client->get($url, ':content_cb' => sub {
    diag "Got chunk";
    $chunk_count++
});
ok !$res->is_success, "The request was not successfull, as planned";
cmp_ok $res->code, '>=', 500, "We caught the remote error";
is $res->content, '', "We got an empty response";
is $chunk_count, 2, "We received 2 chunks";

undef $t; # stop the timer

diag "Shutting down server";
$server->stop;
undef $server;
diag "Done";
