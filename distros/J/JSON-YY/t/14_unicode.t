use strict;
use warnings;
use Test::More;
use JSON::YY qw(encode_json decode_json);
use JSON::YY ':doc';

# surrogate pairs (emoji via \uXXXX\uXXXX)
{
    my $json = '{"emoji":"\\uD83D\\uDE00"}';  # U+1F600 grinning face
    my $data = decode_json($json);
    my $emoji = $data->{emoji};
    is length($emoji), 1, 'surrogate pair decodes to single char';
    ok utf8::is_utf8($emoji), 'emoji has UTF-8 flag';

    # roundtrip
    my $rt = decode_json(encode_json($data));
    is $rt->{emoji}, $emoji, 'emoji roundtrips';
}

# direct UTF-8 emoji (4-byte)
{
    my $json = "{\"e\":\"\xF0\x9F\x98\x80\"}";  # raw UTF-8 bytes for U+1F600
    my $data = decode_json($json);
    ok defined $data->{e}, 'direct 4-byte UTF-8 decodes';
}

# BOM handling
{
    # yyjson should handle or reject BOM
    my $json_bom = "\xEF\xBB\xBF{\"a\":1}";
    my $data = eval { decode_json($json_bom) };
    # yyjson may or may not accept BOM — just verify no crash
    ok !$@ || $@ =~ /decode error/, 'BOM handling does not crash';
}

# null bytes in strings
{
    my $json = '{"s":"hello\\u0000world"}';
    my $data = decode_json($json);
    is length($data->{s}), 11, 'null byte in string preserves length';
}

# various unicode escapes
{
    my $json = '{"a":"\\u00e9","b":"\\u4e16\\u754c","c":"\\u0041"}';
    my $data = decode_json($json);
    is $data->{c}, 'A', '\\u0041 = A';
}

# Doc API with unicode
{
    my $doc = jdoc '{"name":"\\u00e9l\\u00e8ve"}';
    my $name = jgetp $doc, "/name";
    ok defined $name, 'Doc API unicode jgetp';
    ok utf8::is_utf8($name) || length($name) > 0, 'Doc API unicode string valid';
}

# unicode keys in Doc API
{
    my $doc = jfrom {"\x{263a}" => "smiley"};
    my @k = jkeys $doc, "";
    ok utf8::is_utf8($k[0]), 'jfrom unicode key has UTF-8 flag';
}

done_testing;
