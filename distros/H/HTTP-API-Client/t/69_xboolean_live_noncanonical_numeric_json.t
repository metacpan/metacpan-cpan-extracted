=head1 NAME

69_xboolean_live_noncanonical_numeric_json.t - HAC-090:
kvp2json_each's BOOL branch decided whether to pass a live
xBOOLEAN(\$var) scalar ref through unchanged to JSON::XS (for its
native-boolean convention) using NUMERIC equality ($$inner == 0 || ==
1), but JSON::XS itself only accepts the exact canonical string/number
0 or 1 - not any numerically-equal value. A live ref holding "01",
"1.0", " 1", or "1e0" crashed with a raw, unhelpful JSON::XS internal
error instead of going through the same numify/validate path every
other live value already uses. Fixed by comparing with string eq
against the canonical forms instead of numeric ==.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

for my $case ( "01", "1.0", " 1", "1e0" ) {
    my $flag = $case;
    my $json = $api->kvp2json( data => { s => xBOOLEAN( \$flag ) }, events => {} );

    is $json, qq({"s":"$case"}),
        "a live xBOOLEAN(\\\$var) holding '$case' (numerically 1, not canonically formatted) encodes as its own string value instead of crashing";
}

{
    my $flag = "0";
    is $api->kvp2json( data => { s => xBOOLEAN( \$flag ) }, events => {} ), '{"s":false}',
        "a live xBOOLEAN(\\\$var) holding the canonical string '0' still becomes a native JSON boolean";
}

{
    my $flag = 1;
    is $api->kvp2json( data => { s => xBOOLEAN( \$flag ) }, events => {} ), '{"s":true}',
        "a live xBOOLEAN(\\\$var) holding the canonical number 1 still becomes a native JSON boolean";
}

done_testing;
