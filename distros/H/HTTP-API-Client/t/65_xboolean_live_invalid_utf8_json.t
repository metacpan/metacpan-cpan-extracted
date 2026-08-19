=head1 NAME

65_xboolean_live_invalid_utf8_json.t - HAC-084: kvp2json_each's BOOL
branch bypassed HAC-055's invalid-UTF-8 protection for a live
xBOOLEAN(\$var) reference holding raw non-UTF8-valid bytes - it went
straight to _numify_if_lossless without the UTF-8 validate-or-die step
the main scalar branch (!ref $v) does, silently producing mojibake
instead of dying with a clear error. Both paths now share the same
_json_validate_utf8() helper.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;
my $status = "caf\xE9";    # raw Latin-1 bytes, not valid UTF-8, not utf8-flagged

{
    eval { $api->kvp2json( data => { s => xBOOLEAN( \$status ) }, events => {} ) };
    my $error = $@;

    ok $error,
        "a live xBOOLEAN(\\\$var) holding invalid UTF-8 dies instead of silently corrupting it";
    like $error, qr/not valid UTF-8/,
        "the error matches the same message the plain-scalar path already gives";
}

{
    eval { $api->kvp2json( data => { s => $status }, events => {} ) };
    my $plain_scalar_error = $@;

    like $plain_scalar_error, qr/not valid UTF-8/,
        "the plain-scalar path (unchanged) still dies the same way, confirming both paths are symmetric";
}

done_testing;
