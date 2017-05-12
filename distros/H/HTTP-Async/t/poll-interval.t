
use strict;
use warnings;

use Test::More tests => 24;
use HTTP::Request;
use Time::HiRes 'time';

BEGIN {
    require 't/test-utils.pl';
}

use FindBin;
use lib "$FindBin::Bin";
require TestServer;

my $s        = TestServer->new();
my $url_root = $s->started_ok("starting a test server");

use HTTP::Async;
my $q = HTTP::Async->new;

# Send off a long request - check that next_response returns at once
# but that wait_for_next_response returns only when the response has arrived.

# Check that the poll interval is at a sensible default.
is $q->poll_interval, 0.05, "\$q->poll_interval == 0.05";

# Check that the poll interval is changeable.
is $q->poll_interval(0.1), 0.1, "set poll_interval to 0.1";
is $q->poll_interval, 0.1, "\$q->poll_interval == 0.1";

{

    # Get the time since the request was made.
    reset_timer();

    my $url = "$url_root?delay=3";
    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added request to the queue - $url";

    # Does next_response return immediately
    ok !$q->next_response, "next_response returns at once";
    delay_lt_ok 0.4, "Returned quickly (less than 0.4 secs)";

    ok !$q->wait_for_next_response(0),
      "wait_for_next_response(0) returns at once";
    delay_lt_ok 0.4, "Returned quickly (less than 0.4 secs)";

    ok !$q->wait_for_next_response(1),
      "wait_for_next_response(1) returns after 1 sec without a response";

    delay_ge_ok 1,   "Returned after 1 sec delay";
    delay_lt_ok 1.4, "Returned before 1.4 sec delay";

    my $response = $q->wait_for_next_response();
    ok $response, "wait_for_next_response got the response";
    delay_gt_ok 3, "Returned after 3 sec delay";

    is $response->code, 200, "good response (200)";
    ok $response->is_success, "is a success";
}

{
    reset_timer();

    my $url = "$url_root?delay=1";
    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added request to the queue - $url";

    my $response = $q->wait_for_next_response;

    ok $response, "wait_for_next_response got the response";

    delay_gt_ok 1, "Returned after 1 sec delay";
    delay_lt_ok 2, "Returned before 2 sec delay";

    is $response->code, 200, "good response (200)";
    ok $response->is_success, "is a success";
}

{    # Check that wait_for_next_response does not hang if there is nothing
        # to wait for.
    reset_timer();
    ok !$q->wait_for_next_response, "Did not get a response";
    delay_lt_ok 1, "Returned in less than 1 sec";
}

