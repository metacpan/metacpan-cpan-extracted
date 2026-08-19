=head1 NAME

53_leading_zero_numeric_string.t - HAC-070: kvp2json_each/kvp2str_each
both unconditionally coerce any numeric-looking string value via
looks_like_number($v) ? $v+0 : $v, silently mangling a value like a US
zip code "00501" into 501 in both JSON and form-urlencoded output - the
leading zeros carry meaning and were being discarded with no warning.
kvp2json_each now only numifies when the round-trip is lossless
(stringifying the numified value reproduces the original string exactly)
so a genuine number like "5" or "-3.5" still becomes a real JSON number,
but "00501"/"5.0"/"+5" stay strings. kvp2str_each's numification is
removed entirely - a query string has no separate number/string type, so
there was never a reason to risk losing the original representation.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

{
    my $json = $api->kvp2json( data => { zip => "00501" }, events => {} );
    is $json, '{"zip":"00501"}', "a leading-zero numeric string stays a JSON string, not mangled to 501";
}

{
    my $json = $api->kvp2json( data => { count => "5" }, events => {} );
    is $json, '{"count":5}', "a genuine round-trip-safe numeric string still becomes a real JSON number";
}

{
    my $str = $api->kvp2str( data => { zip => "00501" }, events => {} );
    is $str, 'zip=00501', "a leading-zero numeric string is preserved verbatim in the query string";
}

{
    my $str = $api->kvp2str( data => { count => "5" }, events => {} );
    is $str, 'count=5', "a genuine numeric string is unaffected in the query string either way";
}

done_testing;
