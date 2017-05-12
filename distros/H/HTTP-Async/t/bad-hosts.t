
use strict;
use warnings;

use Test::More;

use HTTP::Request;
use LWP::UserAgent;

use HTTP::Async;
my $q = HTTP::Async->new;

# Some weird ISPs or DNS providers take an address like http://i.dont.exist/
# and resolve it to something "useful" such as
# http://navigationshilfe1.t-online.de/dnserror?url=http://i.dont.exist/
#
# If that's happening then let's just give up on this test entirely.
{
    my $ua = LWP::UserAgent->new;
    if ($ua->get('http://i.dont.exist/foo/bar')->is_success) {
        plan skip_all => 'http://i.dont.exist/foo/bar resolved to something!';
        exit;
    }
}

# Try to add some requests for bad hosts. HTTP::Async should not fail
# but should return HTTP::Responses with the correct status code etc.

plan tests => 9;

my @bad_requests =
  map { HTTP::Request->new( GET => $_ ) }
  ( 'http://i.dont.exist/foo/bar', 'ftp://wrong.protocol.com/foo/bar' );

ok $q->add(@bad_requests), "Added bad requests";

while ( $q->not_empty ) {
    my $res = $q->next_response || next;

    my $request_uri = $res->request->uri;

    isa_ok($res, 'HTTP::Response', "$request_uri - Got a proper response")
        || diag sprintf("ref: %s", ref $res);

    ok(!$res->is_success, "$request_uri - Response was not a success")
        || diag sprintf("%s: %s", $res->code, $res->decoded_content);

    ok($res->is_error, "$request_uri - Response was an error")
        || diag sprintf("%s: %s", $res->code, $res->decoded_content);

    ok $res->request,  "$request_uri - Response has a request attached";
}
