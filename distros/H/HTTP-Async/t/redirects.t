
use strict;
use warnings;

use Test::More;
use HTTP::Request;

my $tests = 21;
if ($ENV{'REAL_SERVERS'}) {
    $tests += 4;
}
plan tests => $tests;

use FindBin;
use lib "$FindBin::Bin";
require TestServer;

my $s        = TestServer->new();
my $url_root = $s->started_ok("starting a test server");

use HTTP::Async;
my $q = HTTP::Async->new;

# Check that the max_redirect is at a sensible level.
is $q->max_redirect, 7, "max_redirect == 7";

# Send a request to somewhere that will redirect a certain number of
# times:
#
# ?redirect=$num - if $num is > 0 then it redirects to $num - 1;

{    # Check that a couple of redirects work.
    my $url = "$url_root/foo/bar?redirect=3";

    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added request to the queue";
    $q->poke while !$q->to_return_count;

    my $res = $q->next_response;
    is $res->code, 200, "No longer a redirect";
    ok $res->previous, "Has a previous reponse";
    is $res->previous->code, 302, "previous request was a redirect";
}

{    # check that 20 redirects stop after the expected number.
    my $url = "$url_root?redirect=20";
    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added request to the queue";
    $q->poke while !$q->to_return_count;

    my $res = $q->next_response;
    is $res->code, 302, "Still a redirect";
    ok $res->previous, "Has a previous reponse";
    is $res->previous->code, 302, "previous request was a redirect";
    is $res->request->uri->as_string, "$url_root?redirect=13",
      "last request url correct";
}

{    # Set the max_redirect higher and try again.

    ok $q->max_redirect(30), "Set the max_redirect higher.";

    my $url = "$url_root?redirect=20";
    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added request to the queue";
    $q->poke while !$q->to_return_count;

    my $res = $q->next_response;
    is $res->code, 200, "No longer a redirect";
    ok $res->previous, "Has a previous reponse";
    is $res->previous->code, 302, "previous request was a redirect";
}

{    # Set the max_redirect to zero and check that none happen.

    is $q->max_redirect(0), 0, "Set the max_redirect to zero.";
    is $q->max_redirect, 0, "max_redirect is set to zero.";

    my $url = "$url_root?redirect=20";
    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added request to the queue";
    $q->poke while !$q->to_return_count;

    my $res = $q->next_response;
    is $res->code, 302, "No longer a redirect";
    ok !$res->previous, "Have no previous reponse";
}

if ($ENV{'REAL_SERVERS'}) {
    # Check that redirects have their headers repeated
    # Exmaple from kloevschall (https://github.com/evdb/HTTP-Async/issues/8)

    is $q->max_redirect(1), 1, "Set the max_redirect to one.";
    is $q->max_redirect, 1, "max_redirect is set to one.";

    my $headers = HTTP::Headers->new(Accept => 'application/x-research-info-systems');

    my $error = $q->add(HTTP::Request->new(GET => 'http://dx.doi.org/10.1126/science.169.3946.635', $headers));
    my $ok = $q->add(HTTP::Request->new(GET => 'http://data.crossref.org/10.1126%2Fscience.169.3946.635', $headers));

    while (my ($response, $req_id) = $q->wait_for_next_response) {
        ok $response->is_success, sprintf("Got good response (%s, %s) for %s",
            $response->code,
            $response->message,
            $response->base
        );
    }
}
