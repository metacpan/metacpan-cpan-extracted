=head1 NAME

82_marker_as_header_value_dies.t - HAC-109: new_request()'s header
application loop has no awareness of HTTP::API::DataTypeMarker's blessed
BOOL/CSV markers - only kvp2json_each/kvp2str_each (the body-data
encoders) know how to unwrap them. An xBOOLEAN()/xCSV()-wrapped value used
as a header value silently stringified to Perl's default blessed-reference
form ("BOOL=ARRAY(0x...)") instead of dying - the same silent-corruption
failure class HAC-020/HAC-093/HAC-096 already established this project
must never do. Both now die with a clear message naming the header key,
instead of setting a garbage stringified header value.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

{
    eval { $api->get( "http://x/", {}, { "X-Flag" => xBOOLEAN(1) }, { test_request_object => 1 } ) };
    my $error = $@;

    ok $error, "xBOOLEAN() used as a header value dies instead of silently stringifying";
    like $error, qr/X-Flag/, "the error names the offending header key";
}

{
    eval { $api->get( "http://x/", {}, { "X-Tags" => xCSV( 1, 2, 3 ) }, { test_request_object => 1 } ) };
    my $error = $@;

    ok $error, "xCSV() used as a header value dies instead of silently stringifying";
    like $error, qr/X-Tags/, "the error names the offending header key";
}

{
    # Ordinary header values are unaffected by this fix.
    my $req = $api->get( "http://x/", {}, { "X-Plain" => "hello" }, { test_request_object => 1 } );
    is $req->header("X-Plain"), "hello", "an ordinary plain header value is unaffected";
}

done_testing;
