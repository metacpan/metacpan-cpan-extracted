=head1 NAME

46_xcsv_json_encoding.t - HAC-063: locks in kvp2json_each's actual
xCSV behavior (JSON-encodes as a plain array) against regression, since
DataTypeMarker.pm's DESCRIPTION and Client.pm's kvp2json POD previously
(and incorrectly) claimed kvp2json_each gives xCSV the same special
comma-joined treatment kvp2str_each does. It doesn't - a CSV-blessed
arrayref satisfies Perl's reftype-based ARRAY check and falls through
to the generic array branch. This is the JSON-appropriate behavior
(JSON already has native arrays), so the fix was to the docs, not the
code - this test protects that decision from silently regressing back
to whatever kvp2json_each happens to do next.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new( base_url => "http://example.com" );
    my $req = $api->post( "/test", { e => xCSV( 6, 7, 15 ) }, {},
        { test_request_object => 1 } );

    is $req->content, '{"e":[6,7,15]}',
        "xCSV JSON-encodes as a plain array, not a comma-joined string";
}

{
    my $api = HTTP::API::Client->new( base_url => "http://example.com" );
    my $req = $api->post( "/test", { e => xCSV() }, {},
        { test_request_object => 1 } );

    is $req->content, '{"e":[]}', "an empty xCSV JSON-encodes as an empty array";
}

done_testing;
