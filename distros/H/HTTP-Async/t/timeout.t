
use strict;
use warnings;

use Test::More tests => 20;
use HTTP::Request;

use FindBin;
use lib "$FindBin::Bin";
require TestServer;

my $s        = TestServer->new();
my $url_root = $s->started_ok("starting a test server");

use HTTP::Async;
my $q = HTTP::Async->new;

# Check that the timeout is at a sensible default.
is $q->timeout, 180, "\$q->timeout == 180";

{    # Send a request that should return quickly
    my $url = "$url_root?delay=0";
    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added request to the queue - $url";
    my $res = $q->wait_for_next_response;
    is $res->code, 200, "Not timed out (200)";
}

is $q->timeout(2), 2, "Set the timeout really low";

{    # Send a request that should timeout
    my $url = "$url_root?delay=3";
    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added delayed request to the queue - $url";
    my $res = $q->wait_for_next_response;
    is $res->code, 504, "timed out (504)";
    ok $res->is_error, "is an error";
}

{    # Send a request that should not timeout as it is trickling back data.
    my $url = "$url_root?trickle=4";
    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added trickle request to the queue - $url";
    my $res = $q->wait_for_next_response;
    is $res->code, 200, "response ok (200)";
    ok !$res->is_error, "is not an error";
}

is $q->timeout(1),          1, "Set the timeout really low";
is $q->max_request_time(1), 1, "Set the max_request_time really low";

{    # Send a request that should timeout despite trickling back data.
    my $url = "$url_root?trickle=3";
    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added trickle request to the queue - $url";
    my $res = $q->wait_for_next_response;
    is $res->code, 504, "timed out (504)";
    ok $res->is_error, "is an error";
}

is $q->timeout(10),           10,  "Lengthen the timeout";
is $q->max_request_time(300), 300, "Lengthen the max_request_time";

{    # Send same request that should now be ok
    my $url = "$url_root?delay=3";
    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added delayed request to the queue - $url";
    my $res = $q->wait_for_next_response;
    is $res->code, 200, "Not timed out (200)";
}
