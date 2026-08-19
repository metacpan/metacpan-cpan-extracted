=head1 NAME

71_xboolean_plain_value_json_protection.t - HAC-092: kvp2json_each's
BOOL branch applied UTF-8-validate-or-die and lossless-numify protection
(HAC-055/HAC-070/HAC-084) only to the LIVE scalar-ref case
(xBOOLEAN(\$var)) - a PLAIN (non-ref) value, e.g. xBOOLEAN($value) called
with a bare scalar, fell straight through to returning the raw value
unprotected. Verified live before this fix: a plain xBOOLEAN() value
holding invalid UTF-8 bytes silently produced mojibake instead of
dying, and a plain numeric-looking xBOOLEAN() value was never numified.
Both are fully public, documented input shapes per xBOOLEAN's own POD
("a plain scalar or a scalar ref"). The native-JSON-boolean behavior for
a live ref holding exactly '0'/'1' (xTRUE/xFALSE's shape) is unaffected.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

{
    my $status = "caf\xE9";    # raw Latin-1 bytes, invalid UTF-8, plain (not a ref)

    eval { $api->kvp2json( data => { s => xBOOLEAN($status) }, events => {} ) };
    my $error = $@;

    ok $error,
        "a plain (non-live) xBOOLEAN value holding invalid UTF-8 dies instead of silently corrupting it";
    like $error, qr/not valid UTF-8/,
        "the error matches the same message the plain-scalar and live-ref paths already give";
}

{
    my $json = $api->kvp2json( data => { n => xBOOLEAN("5") }, events => {} );

    is $json, '{"n":5}',
        "a plain (non-live) xBOOLEAN value that's a lossless numeric string still numifies, matching the main scalar branch";
}

{
    # Existing native-JSON-boolean behavior (xTRUE/xFALSE's \1/\0 shape) is unaffected.
    is $api->kvp2json( data => { t => xTRUE() }, events => {} ), '{"t":true}',
        "xTRUE() still encodes as a native JSON boolean, unaffected by this fix";
    is $api->kvp2json( data => { f => xFALSE() }, events => {} ), '{"f":false}',
        "xFALSE() still encodes as a native JSON boolean, unaffected by this fix";
}

{
    # xTrue/xFalse/xtrue/xfalse/xt__e/xf___e all pass a plain string literal to
    # xBOOLEAN internally - confirm they're unaffected (still valid UTF-8, no numify).
    is $api->kvp2json( data => { s => xTrue() }, events => {} ), '{"s":"True"}',
        "xTrue() is unaffected - still encodes as the plain string \"True\"";
}

done_testing;
