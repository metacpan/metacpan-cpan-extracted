use strict;
use warnings;

use Test::More;
use HTTP::Request;
use Net::EmptyPort;

my $rc = eval {
    require Sys::HostIP;
    1;
};
if (!$rc) {
    plan skip_all => "test requires Sys::HostIP to be installed";
    exit;
}

my $ips = Sys::HostIP->new->ips || [];

plan tests => 1 + 2*@$ips;

use FindBin;
use lib "$FindBin::Bin";
require TestServer;

my $s        = TestServer->new();
my $url_root = $s->started_ok("starting a test server");

use HTTP::Async;

for my $ip (@$ips) {
    my $q = HTTP::Async->new;

    my $req = HTTP::Request->new( 'GET', "$url_root?delay=0" );

    my %opts = (
        local_addr => $ip,
        local_port => Net::EmptyPort::empty_port(),
    );
    ok $q->add_with_opts($req, \%opts), "Added request to the queue with local_addr ($ip) set";
#   note `lsof -p $$`;
    $q->poke while !$q->to_return_count;

    my $res = $q->next_response;
    is $res->code, 200, "Got a response";
}
