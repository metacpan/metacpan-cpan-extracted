
use strict;
use warnings;
use URI::Escape;

use Test::More tests => 16;
use HTTP::Request;

use FindBin;
use lib "$FindBin::Bin";
require TestServer;

my $s1          = TestServer->new();
my $s1_url_root = $s1->started_ok("starting a test server");

my $s2          = TestServer->new();
$s2->{is_proxy} = 1;
my $s2_url_root = $s2->started_ok("starting a test server");

ok( $_, "got $_" ) for $s1_url_root, $s2_url_root;

my %tests = (
    "$s1_url_root/foo/bar?redirect=2" => 200,
    "$s1_url_root/foo/bar?delay=1"    => 200,
);

use HTTP::Async;
my $q = HTTP::Async->new;

foreach my $via_proxy ( 0, 1 ) {

    while ( my ( $url, $code ) = each %tests ) {

        my $req = HTTP::Request->new( 'GET', $url );

        my %opts = ( proxy_host => '127.0.0.1', proxy_port => $s2->port, );

        my $id =
            $via_proxy
          ? $q->add_with_opts( $req, \%opts )
          : $q->add($req);

        ok $id, "Added request to the queue - $url";

        my $res = $q->wait_for_next_response;
        is( $res->code, $code, "Got a '$code' response" )
          || diag $res->as_string;

        # check that the proxy header was found if this was a proxy request.
        my $proxy_header = $res->header('WasProxied') || '';
        my $expected = $via_proxy ? 'yes' : '';
        is($proxy_header, $expected, "check for proxy header '$expected'")
            || diag $res->as_string;
    }
}
