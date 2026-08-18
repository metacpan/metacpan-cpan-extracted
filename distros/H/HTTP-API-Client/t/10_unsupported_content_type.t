=head1 NAME

10_unsupported_content_type.t - regression tests for HAC-008: convert_data()
must return an empty body for empty data, and die with a clear message for
non-empty data, instead of silently stringifying the data hashref, when
content_type is neither JSON nor form-urlencoded

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new( content_type => "text/plain" );
    my $req = $api->post( "http://example.com", {}, {}, { test_request_object => 1 } );

    is $req->content, '', "unsupported content_type with empty data produces an empty body, not a stringified hashref";
}

{
    my $api = HTTP::API::Client->new( content_type => "text/plain" );

    eval { $api->post( "http://example.com", { foo => "bar" }, {}, { test_request_object => 1 } ) };
    my $error = $@;

    ok $error, "unsupported content_type with non-empty data dies instead of silently producing garbage";
    like $error, qr/text\/plain/, "the error names the offending content_type";
}

done_testing;
