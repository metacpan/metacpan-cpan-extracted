=head1 NAME

72_xboolean_non_scalar_ref_dies.t - HAC-093: xBOOLEAN() wrapping a
reference other than a scalar ref (an ARRAY or HASH ref) silently
stringified to "ARRAY(0x...)"/"HASH(0x...)" in both kvp2json_each and
kvp2str_each instead of dying with a clear message - the same failure
class HAC-020 already established this project must never do silently.
Both encoders now die with a clear message naming the offending ref
type; a plain scalar and a genuine scalar ref (the two documented
xBOOLEAN input shapes) are unaffected.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

{
    eval { $api->kvp2json( data => { flag => xBOOLEAN( [ 1, 2, 3 ] ) }, events => {} ) };
    my $error = $@;

    ok $error, "kvp2json: xBOOLEAN(arrayref) dies instead of silently stringifying";
    like $error, qr/ARRAY ref/, "the error names the offending ref type";
}

{
    eval { $api->kvp2str( data => { flag => xBOOLEAN( { a => 1 } ) }, events => {} ) };
    my $error = $@;

    ok $error, "kvp2str: xBOOLEAN(hashref) dies instead of silently stringifying";
    like $error, qr/HASH ref/, "the error names the offending ref type";
}

{
    is $api->kvp2json( data => { flag => xTRUE() }, events => {} ), '{"flag":true}',
        "a genuine scalar ref (xTRUE's shape) is unaffected";
    is $api->kvp2json( data => { flag => xBOOLEAN("5") }, events => {} ), '{"flag":5}',
        "a plain scalar value is unaffected";
}

done_testing;
