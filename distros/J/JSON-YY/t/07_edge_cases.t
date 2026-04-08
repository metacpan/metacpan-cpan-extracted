use strict;
use warnings;
use Test::More;
use JSON::YY qw(encode_json decode_json decode_json_ro);

# --- needs_escape: control chars in long strings ---
{
    my $str = "abcdefg\x01hijklmno";  # 16 bytes, \x01 at position 7
    my $json = encode_json({s => $str});
    unlike $json, qr/\x01/, 'control char escaped in 16-byte string';
    like $json, qr/\\u0001/, 'control char becomes \\u0001';

    # all control chars
    for my $c (0x00..0x1f) {
        my $s = "prefix" . chr($c) . "suffix";  # >8 bytes
        my $j = encode_json({x => $s});
        unlike $j, qr/[\x00-\x1f]/, sprintf 'control char 0x%02x escaped', $c;
    }
}

# --- decode_json_ro scalar root ---
{
    my $s = decode_json_ro('"hello world"');
    is $s, 'hello world', 'decode_json_ro scalar string root';

    my $n = decode_json_ro('42');
    is $n, 42, 'decode_json_ro scalar number root';

    my $t = decode_json_ro('true');
    ok $t, 'decode_json_ro scalar true root';

    my $f = decode_json_ro('false');
    ok !$f, 'decode_json_ro scalar false root';

    my $u = decode_json_ro('null');
    ok !defined $u, 'decode_json_ro scalar null root';
}

# --- NaN/Inf encoding croaks ---
{
    eval { encode_json(9**9**9) };
    like $@, qr/NaN|Inf/i, 'encode Inf croaks';

    eval { encode_json(-9**9**9) };
    like $@, qr/NaN|Inf/i, 'encode -Inf croaks';

    eval { encode_json(9**9**9 - 9**9**9) };
    like $@, qr/NaN|Inf/i, 'encode NaN croaks';
}

# --- error paths ---
{
    eval { decode_json('not json') };
    like $@, qr/decode error/i, 'invalid JSON croaks';

    eval { decode_json('') };
    like $@, qr/decode error/i, 'empty JSON croaks';

    eval { decode_json_ro('not json') };
    like $@, qr/decode error/i, 'invalid JSON (ro) croaks';
}

# --- Doc API error paths ---
{
    use JSON::YY ':doc';

    eval { jdoc 'not json' };
    like $@, qr/parse error/i, 'jdoc invalid JSON croaks';

    my $doc = jdoc '{"a":1}';

    eval { jget $doc, "/nope" };
    like $@, qr/not found/i, 'jget missing path croaks';

    eval { jlen $doc, "/nope" };
    like $@, qr/not found/i, 'jlen missing path croaks';

    eval { jkeys $doc, "/a" };
    like $@, qr/object/i, 'jkeys on non-object croaks';

    eval { jiter $doc, "/a" };
    like $@, qr/array or object/i, 'jiter on scalar croaks';

    eval { jdel $doc, "" };
    like $@, qr/root/i, 'jdel root croaks';

    # jdel missing path returns undef
    my $r = jdel $doc, "/nope";
    ok !defined $r, 'jdel missing returns undef';

    # jdel returns independent copy (safe after mutations)
    $doc = jdoc '{"a":1,"b":2}';
    my $del = jdel $doc, "/a";
    jset $doc, "/c", 3;
    jset $doc, "/d", 4;
    is jencode $del, "", '1', 'jdel result survives parent mutations';
}

# --- jdecode keyword works ---
{
    use JSON::YY ':doc';
    my $doc = jdoc '{"x":[1,2,3]}';
    my $v = jdecode $doc, "/x";
    is_deeply $v, [1,2,3], 'jdecode works as jgetp alias';
}

# --- max_depth ---
{
    my $coder = JSON::YY->new->utf8->max_depth(3);
    eval { $coder->encode({a => {b => {c => {d => 1}}}}) };
    like $@, qr/depth/i, 'max_depth encode croaks';
}

done_testing;
