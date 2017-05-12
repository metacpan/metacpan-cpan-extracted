
use strict;
use warnings;

use Test::More tests => 5;
use HTTP::Request;

use FindBin;
use lib "$FindBin::Bin";
require TestServer;

my $s        = TestServer->new();
my $url_root = $s->started_ok("starting a test server");

use HTTP::Async;
my $q = HTTP::Async->new;

my %tests = (
    "$url_root/foo/bar?break_connection=before_headers" => 504,
    "$url_root/foo/bar?break_connection=before_content" => 200,
);

while ( my ( $url, $code ) = each %tests ) {
    my $req = HTTP::Request->new( 'GET', $url );
    ok $q->add($req), "Added request to the queue - $url";
    my $res = $q->wait_for_next_response;
    is $res->code, $code, "Got a '$code' response";
}
