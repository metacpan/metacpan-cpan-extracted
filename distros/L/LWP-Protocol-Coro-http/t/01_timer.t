#!perl -w
use strict;
use Test::More;

use AnyEvent;
use LWP::Protocol::Coro::http;
use LWP::Simple qw(get);

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

my $server = Test::HTTP::LocalServer->spawn(
    eval => 'sleep(4)',
    #debug => 1,
);
my $url = $server->url;
diag "Retrieving URL: " . $url;

my $data = get($url) || '';
isn't $data, '', "Retrieve " . $url;
cmp_ok $timer_events, '>', 3, "While retrieving the data we got three timer callbacks(because the server sleeps)";

undef $t; # stop the timer

diag "Shutting down server";
$server->stop;
undef $server;
diag "Done";
