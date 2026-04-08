use strict;
use warnings;
use Test::More;
use JSON::YY qw(decode_json decode_json_ro encode_json);

my $json = '{"name":"John","age":30,"tags":["a","b"],"nested":{"x":1}}';

# basic decode_json_ro
my $data = decode_json_ro $json;
is $data->{name}, 'John', 'ro: string value';
is $data->{age}, 30, 'ro: number value';
is_deeply $data->{tags}, ['a', 'b'], 'ro: array value';
is $data->{nested}{x}, 1, 'ro: nested value';

# verify readonly
ok Internals::SvREADONLY($data->{name}), 'string SV is readonly';
ok Internals::SvREADONLY($data->{age}), 'number SV is readonly';

eval { $data->{name} = "Jane" };
like $@, qr/read-only|Modification/, 'cannot modify hash value';

eval { $data->{new_key} = 1 };
like $@, qr/read-only|Modification|restrict/, 'cannot add hash key';

eval { push @{$data->{tags}}, "c" };
like $@, qr/read-only|Modification/, 'cannot modify array';

# zero-copy: string SV has SvLEN=0 (doesn't own buffer)
# extraction via assignment copies the string (sv_setsv copies SvLEN=0)
{
    my $extracted;
    {
        my $d2 = decode_json_ro '{"key":"value"}';
        $extracted = $d2->{key};  # copies the string
    }
    # $d2 freed, doc freed, but $extracted has its own copy
    is $extracted, 'value', 'extracted string survives parent (copy-on-extract)';
}

# large document
my $large_json = encode_json [map { {id => $_, val => "x" x 100} } 1..1000];
my $large_ro = decode_json_ro $large_json;
is scalar @$large_ro, 1000, 'ro: large array size';
is $large_ro->[0]{id}, 1, 'ro: large first element';
is $large_ro->[999]{val}, "x" x 100, 'ro: large last element string';

# keyword version
package RoKw {
    use JSON::YY qw(decode_json_ro);
    use Test::More;
    my $d = decode_json_ro '{"kw":true}';
    ok $d->{kw}, 'ro keyword decode works';
}

# roundtrip: decode_json_ro result can be re-encoded
my $rt_data = decode_json_ro '{"a":1,"b":[2,3]}';
my $rt_json = encode_json $rt_data;
my $rt_back = decode_json $rt_json;
is $rt_back->{a}, 1, 'ro data re-encodes correctly';

done_testing;
