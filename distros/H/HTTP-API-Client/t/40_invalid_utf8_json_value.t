=head1 NAME

40_invalid_utf8_json_value.t - HAC-055: kvp2json_each unconditionally
Encode::decode(utf8 => ...)s any non-UTF8-flagged scalar value, on the
(usually correct, per HAC-032/t/29) assumption that it is raw UTF-8 bytes.
When the value is NOT valid UTF-8 (e.g. Latin-1 bytes read from a legacy
file/DB without being explicitly decoded), Encode::decode with no CHECK
argument silently substitutes U+FFFD for the bad byte(s) instead of
erroring - the JSON body comes out with silently corrupted data and no
warning. This must die clearly instead, consistent with this module's
existing "surface the error, don't swallow it" behavior for an invalid
charset (HAC-046).

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $latin1_bytes = "caf\xE9";    ## 0xE9 alone is not valid UTF-8

ok !utf8::is_utf8($latin1_bytes), "sanity: not UTF8-flagged";

my $api = HTTP::API::Client->new;

my $req = eval {
    $api->post( "http://example.com", { name => $latin1_bytes }, {}, { test_request_object => 1 } );
};
my $error = $@;

ok !$req, "no request object is built from invalid-UTF-8 JSON data";
ok $error, "an error is raised instead of silently corrupting the value";
unlike $error, qr/\x{FFFD}/, "the error does not just embed the replacement character silently";

done_testing;
