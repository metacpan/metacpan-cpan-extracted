=head1 NAME

74_numify_rejects_nan_infinity.t - HAC-095: _numify_if_lossless() numified
certain NaN/Infinity-looking string values ('NaN', 'Inf', '-Inf' - the exact
casings whose Perl NV-to-string roundtrip matches the original string
byte-for-byte, which is what the existing lossless-numeric check looks for)
into real Perl NVs. JSON::XS, in the utf8-mode encoder this module always
builds, then encoded those NVs as the bareword tokens C<nan>/C<-nan>/C<inf>
instead of a quoted string - tokens that are not valid JSON (RFC 8259
requires numbers to be finite), silently producing a body no JSON parser
(including JSON::XS itself) can decode. Verified live before this fix:
kvp2json(data=>{v=>'NaN'}) produced C<{"v":-nan}> and data=>{v=>'Inf'}
produced C<{"v":inf}>, with no error or warning. Lowercase 'nan'/'inf' and
'Infinity' were never affected - they don't round-trip through Perl's NV
stringification back to the identical original string, so they already fell
through the existing eq-based check unnumified.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

for my $v (qw( NaN Inf -Inf )) {
    my $json = $api->kvp2json( data => { v => $v } );

    is $json, qq({"v":"$v"}),
        "kvp2json('$v') stays a quoted JSON string, not the invalid bareword JSON::XS would emit for a real NaN/Inf NV";

    eval { JSON::XS->new->decode($json) };
    ok !$@, "the resulting JSON for '$v' round-trips through a plain JSON decoder without error"
        or diag "decode error: $@";
}

{
    # Ordinary finite numeric strings are unaffected by the guard.
    is $api->kvp2json( data => { n => "5" } ), '{"n":5}',
        "an ordinary lossless numeric string still numifies, unaffected by this fix";
    is $api->kvp2json( data => { n => "3.14" } ), '{"n":3.14}',
        "an ordinary lossless float string still numifies, unaffected by this fix";
}

{
    # Casings that don't round-trip through Perl's NV stringification were
    # already safe before this fix - confirm they still are.
    is $api->kvp2json( data => { v => "nan" } ), '{"v":"nan"}',
        "lowercase 'nan' was already unaffected (doesn't round-trip) - still a quoted string";
    is $api->kvp2json( data => { v => "Infinity" } ), '{"v":"Infinity"}',
        "'Infinity' was already unaffected (doesn't round-trip) - still a quoted string";
}

done_testing;
