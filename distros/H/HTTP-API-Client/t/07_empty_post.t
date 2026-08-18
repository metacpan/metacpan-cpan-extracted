=head1 NAME

07_empty_post.t - regression test for HAC-004: a non-GET request with
form-urlencoded content-type and empty data must still build a real
HTTP::Request instead of leaving it undef

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );

my $request = $api->post("http://example.com/action", {}, {}, {
    test_request_object => 1,
});

ok defined($request), "POST with empty data and form-urlencoded content-type still builds a request";
isa_ok $request, "HTTP::Request";
is $request->method, "POST", "method is POST";
is $request->content, '', "content is empty";

done_testing;
