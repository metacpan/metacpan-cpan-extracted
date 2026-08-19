=head1 NAME

42_array_key_double_escape.t - HAC-059: kvp2str_each double-escaped the key
for an ARRAY-valued field whenever the key itself contained a character
uri_escape() touches (space, &, =, %, non-ASCII, ...). The top of
kvp2str_each unconditionally re-escapes whatever key it's given, and the
ARRAY branch recurses passing its own already-escaped $k back in as the
next call's key - so a space became %20 then %2520 instead of staying
%20. Reproducible with any array value under a key needing escaping;
existing tests never hit it because none of their array-valued keys
contain an escapable character.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );

    my $req = $api->post( "http://example.com", { "a b" => [ "x y", "z" ] },
        {}, { test_request_object => 1 } );

    is $req->content, "a%20b=x%20y&a%20b=z",
        "array value: key is escaped exactly once, not double-escaped";
}

{
    my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );

    my $req = $api->post( "http://example.com", { "a b" => xCSV( "x", "y" ) },
        {}, { test_request_object => 1 } );

    is $req->content, "a%20b=x,y",
        "CSV value: key is escaped exactly once (already correct, guarded here against regression)";
}

done_testing;
