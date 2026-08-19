=head1 NAME

78_non_utf8_charset_skips_tune_utf8.t - HAC-100: new_request()'s
'if ($self->charset eq "utf8") { $content = _tune_utf8($content); }' only
calls _tune_utf8 for the default 'utf8' charset. Every existing charset test
(t/38, t/50, t/59) calls kvp2json()/kvp2str() directly, never through
new_request(), so the branch where charset is something else (e.g.
'latin1') and _tune_utf8 is correctly skipped had a raw execution count of
0 in Devel::Cover. Verified live before this test existed: it already works
correctly - JSON::XS's own charset mode fully handles the encoding, so
_tune_utf8's wide-character probe-and-fix is only needed (and only called)
for the utf8 case.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new( charset => "latin1" );
    my $wide = "caf\x{e9}";
    utf8::upgrade($wide);    # a genuine Unicode string, not ambiguous raw bytes

    my $req = $api->post(
        "http://x/",
        { a => $wide },
        {},
        { test_request_object => 1 },
    );

    ok !utf8::is_utf8( $req->content ),
        "the request content is raw latin1-encoded bytes, not a UTF8-flagged string";
    is $req->content, qq({"a":"caf\xE9"}),
        "the wide character is correctly encoded as a single latin1 byte, matching direct kvp2json output";
}

done_testing;
