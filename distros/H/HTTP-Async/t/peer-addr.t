use strict;
use warnings;

use Test::More;
use HTTP::Request;

plan tests => 4;

use FindBin;
use lib "$FindBin::Bin";
require TestServer;

my $s        = TestServer->new();
my $url_root = $s->started_ok("starting a test server");

$url_root =~ s/localhost/example.org/;

use HTTP::Async;

my $q = HTTP::Async->new;

my $req = HTTP::Request->new( 'GET', "$url_root?delay=0" );

my %opts = (
    peer_addr => 'localhost',
);
ok $q->add_with_opts($req, \%opts), "Added request to $url_root to the queue with peer_addr set to 'localhost'";

$q->poke while !$q->to_return_count;

my $res = $q->next_response;
is $res->code, 200, "Got a response";
like $res->content, qr/Delayed for/, "Got expected response";
