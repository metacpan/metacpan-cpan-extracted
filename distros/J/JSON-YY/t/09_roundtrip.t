use strict;
use warnings;
use Test::More;
use JSON::YY qw(encode_json decode_json);

eval { require JSON::XS };
plan skip_all => 'JSON::XS required for roundtrip tests' if $@;

# roundtrip: encode with YY, decode with XS, and vice versa
# note: avoid floats in cross-encoder comparisons — Gconvert output varies
# with NV_DIG (long double perls produce different representations)
my @test_data = (
    [1, 2, 3],
    {a => 1, b => "hello"},
    {nested => {deep => [1, {x => 2}]}},
    [undef, "str", 42],
    {empty_arr => [], empty_obj => {}},
    {"" => "empty key"},
    {long => "x" x 1000},
    [map { {id => $_, name => "n$_"} } 1..100],
    {utf8 => "\x{263a}", ascii => "plain"},
);

for my $i (0..$#test_data) {
    my $data = $test_data[$i];

    # YY encode -> XS decode
    my $yy_json = encode_json($data);
    my $xs_decoded = JSON::XS::decode_json($yy_json);

    # XS encode -> YY decode
    my $xs_json = JSON::XS::encode_json($data);
    my $yy_decoded = decode_json($xs_json);

    # compare
    is_deeply $xs_decoded, $yy_decoded,
        "roundtrip $i: YY encode/XS decode matches XS encode/YY decode";

    # YY roundtrip
    my $rt = decode_json(encode_json($data));
    is_deeply $rt, $yy_decoded, "roundtrip $i: YY self-roundtrip";
}

# types preservation — compare numerically for floats
{
    my $json = '{"i":42,"f":3.14,"s":"str","t":true,"f2":false,"n":null}';
    my $yy = decode_json($json);
    my $xs = JSON::XS::decode_json($json);

    is $yy->{i}, $xs->{i}, 'integer preserved';
    cmp_ok abs($yy->{f} - $xs->{f}), '<', 1e-10, 'float preserved';
    is $yy->{s}, $xs->{s}, 'string preserved';
    ok $yy->{t}, 'true preserved';
    ok !$yy->{f2}, 'false preserved';
    ok !defined $yy->{n}, 'null preserved';
}

# float roundtrip (YY self-roundtrip, numeric comparison)
{
    my $data = {pi => 3.14, e => 2.718281828};
    my $rt = decode_json(encode_json($data));
    cmp_ok abs($rt->{pi} - 3.14), '<', 1e-10, 'float self-roundtrip pi';
    cmp_ok abs($rt->{e} - 2.718281828), '<', 1e-10, 'float self-roundtrip e';
}

# large numbers
{
    my $json = '[9999999999999999,18446744073709551615,-9223372036854775808]';
    my $d = decode_json($json);
    is $d->[0], 9999999999999999, 'large int';
}

# keyword plugin must not hijack other modules' encode_json/decode_json
{
    my $data = [{a => 1, b => 2}];
    my $xs_json = JSON::XS::encode_json($data);
    like $xs_json, qr/\[/, 'JSON::XS encode_json not hijacked by keyword plugin';
    is_deeply JSON::XS::decode_json($xs_json), $data, 'JSON::XS decode_json not hijacked';

    # also test with concatenation (the original trigger)
    my $with_nl = JSON::XS::encode_json($data) . "\n";
    like $with_nl, qr/^\[.*\]\n$/, 'JSON::XS encode_json concat not hijacked';
}

done_testing;
