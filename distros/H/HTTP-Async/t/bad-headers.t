
use strict;
use warnings;

use Test::More tests => 3;
use HTTP::Request;

use FindBin;
use lib "$FindBin::Bin";
require TestServer;

my $s        = TestServer->new();
my $url_root = $s->started_ok("starting a test server");

use HTTP::Async;
my $q = HTTP::Async->new;

# Check that a couple of redirects work.
my $url = "$url_root/foo/bar?bad_header=1";

my $req = HTTP::Request->new( 'GET', $url );
ok $q->add($req), "Added request to the queue";
$q->poke while !$q->to_return_count;

my $res = $q->next_response;
is $res->code, 200, "Got a response";
