=head1 NAME

41_get_wrong_content_type.t - HAC-058: new_request() dies with a clear
message when a GET request is forced to a content_type other than
application/x-www-form-urlencoded (a GET request body can only be a
query string, so any other content_type is unbuildable). Previously
reachable but never exercised by the test suite.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new( content_type => "application/json" );

    eval { $api->get( "http://example.com", { q => "widgets" } ) };
    my $error = $@;

    ok $error, "GET with a non-form-urlencoded content_type dies";
    like $error, qr/application\/json/, "the error names the offending content_type";
}

done_testing;
