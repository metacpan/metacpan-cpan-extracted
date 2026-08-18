=head1 NAME

29_json_bytes_vs_chars.t - HAC-032: JSON::XS's utf8 mode (used by
_build_json/kvp2json) unconditionally UTF-8-encodes its input. That's
correct for a genuine Unicode character string, but double-encodes a
value that is ALREADY raw UTF-8 bytes (utf8::is_utf8 false - the common
shape for data read from a file/DB/API without being explicitly
Encode::decode'd), producing mojibake in the JSON body. Same root-cause
class as HAC-031, in the JSON path instead of form-urlencoded.

=cut

use strict;
use warnings;
use utf8;
use Test::More;
use Encode;
use HTTP::API::Client;

my $wide_chars = "\x{65E5}\x{672C}";                    ## genuine Unicode string
my $utf8_bytes = Encode::encode( utf8 => $wide_chars );  ## already raw UTF-8 bytes, is_utf8 flag off

ok !utf8::is_utf8($utf8_bytes), "sanity: the byte-string input is not UTF8-flagged";

{
    my $api  = HTTP::API::Client->new;
    my $req1 = $api->post( "http://example.com", { name => $wide_chars }, {}, { test_request_object => 1 } );
    my $req2 = $api->post( "http://example.com", { name => $utf8_bytes }, {}, { test_request_object => 1 } );

    is $req2->content, $req1->content,
        "a value that is already raw UTF-8 bytes produces the same JSON body as the equivalent Unicode string";
}

{
    my $api = HTTP::API::Client->new;
    my $req = $api->post( "http://example.com", { name => "plain ascii" }, {}, { test_request_object => 1 } );
    is $req->content, '{"name":"plain ascii"}', "plain ASCII values unaffected";
}

done_testing;
