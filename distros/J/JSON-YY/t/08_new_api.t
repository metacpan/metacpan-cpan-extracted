use strict;
use warnings;
use Test::More;
use JSON::YY ':doc';
use JSON::YY qw(encode_json decode_json);

# --- jfrom ---
{
    my $doc = jfrom {a => 1, b => [2, 3]};
    is ref $doc, 'JSON::YY::Doc', 'jfrom returns Doc';
    is jgetp $doc, "/a", 1, 'jfrom hash content';
    is_deeply jgetp $doc, "/b", [2, 3], 'jfrom array content';

    my $doc2 = jfrom [1, "two", \1, undef];
    is jtype $doc2, "", "array", 'jfrom arrayref';
    is jgetp $doc2, "/1", "two", 'jfrom array element';

    my $doc3 = jfrom "hello";
    is jgetp $doc3, "", "hello", 'jfrom scalar string';

    my $doc4 = jfrom 42;
    is jgetp $doc4, "", 42, 'jfrom scalar number';
}

# --- jpatch (RFC 6902) ---
{
    my $doc = jdoc '{"a":1,"b":{"c":2}}';

    my $patch = jdoc '[
        {"op":"add","path":"/d","value":4},
        {"op":"replace","path":"/a","value":10},
        {"op":"remove","path":"/b/c"}
    ]';
    jpatch $doc, $patch;
    is jgetp $doc, "/a", 10, 'jpatch replace';
    is jgetp $doc, "/d", 4, 'jpatch add';
    ok !jhas $doc, "/b/c", 'jpatch remove';

    # test operation
    my $doc2 = jdoc '{"a":1}';
    my $test_patch = jdoc '[{"op":"test","path":"/a","value":1}]';
    eval { jpatch $doc2, $test_patch };
    ok !$@, 'jpatch test succeeds';

    my $bad_test = jdoc '[{"op":"test","path":"/a","value":999}]';
    eval { jpatch $doc2, $bad_test };
    like $@, qr/patch/, 'jpatch test fails correctly';

    # move, copy
    my $doc3 = jdoc '{"a":1,"b":2}';
    my $move = jdoc '[{"op":"move","path":"/c","from":"/a"}]';
    jpatch $doc3, $move;
    ok !jhas $doc3, "/a", 'jpatch move removes source';
    is jgetp $doc3, "/c", 1, 'jpatch move creates target';

    my $doc4 = jdoc '{"a":1}';
    my $cp = jdoc '[{"op":"copy","path":"/b","from":"/a"}]';
    jpatch $doc4, $cp;
    is jgetp $doc4, "/a", 1, 'jpatch copy keeps source';
    is jgetp $doc4, "/b", 1, 'jpatch copy creates target';
}

# --- jmerge (RFC 7386) ---
{
    my $doc = jdoc '{"a":1,"b":2,"c":{"d":3}}';
    my $patch = jdoc '{"b":null,"c":{"d":4,"e":5},"f":6}';
    jmerge $doc, $patch;
    is jgetp $doc, "/a", 1, 'jmerge preserves unchanged';
    ok !jhas $doc, "/b", 'jmerge null removes';
    is jgetp $doc, "/c/d", 4, 'jmerge nested replace';
    is jgetp $doc, "/c/e", 5, 'jmerge nested add';
    is jgetp $doc, "/f", 6, 'jmerge top-level add';
}

# --- jvals ---
{
    my $doc = jdoc '{"x":1,"y":"two","z":true}';
    my @vals = jvals $doc, "";
    is scalar @vals, 3, 'jvals count';
    ok((grep { ref $_ eq 'JSON::YY::Doc' } @vals) == 3, 'jvals returns Docs');

    # encode each val
    my @encoded = sort map { jencode $_, "" } @vals;
    is_deeply \@encoded, ['"two"', '1', 'true'], 'jvals content';
}

# --- jeq ---
{
    my $a = jdoc '{"a":[1,2,3]}';
    my $b = jdoc '{"a":[1,2,3]}';
    my $c = jdoc '{"a":[1,2,4]}';
    ok jeq $a, $b, 'jeq equal';
    ok !(jeq $a, $c), 'jeq not equal';
}

# --- overloading ---
{
    my $doc = jdoc '{"x":1}';
    is "$doc", '{"x":1}', 'stringify overload';
    ok $doc, 'bool overload';

    my $a = jdoc '[1,2,3]';
    my $b = jdoc '[1,2,3]';
    my $c = jdoc '[1,2,4]';
    ok $a eq $b, 'eq overload';
    ok $a ne $c, 'ne overload';
}

# RFC 6902 4.1: add onto an existing object member replaces it. yyjson's
# pointer-put inserts unconditionally when its insert_new flag is set, which
# duplicated the key (and left the document disagreeing with its own JSON);
# yyjson.c carries a marked local patch for this.
{
    my @cases = (
        ['add onto existing',   '{"x":1}',       '[{"op":"add","path":"/x","value":2}]',    '{"x":2}'],
        ['copy onto existing',  '{"a":1,"b":2}', '[{"op":"copy","from":"/a","path":"/b"}]', '{"a":1,"b":1}'],
        ['move onto existing',  '{"a":1,"b":2}', '[{"op":"move","from":"/a","path":"/b"}]', '{"b":1}'],
        ['replace existing',    '{"x":1}',       '[{"op":"replace","path":"/x","value":2}]','{"x":2}'],
        ['add a new key',       '{"a":1}',       '[{"op":"add","path":"/b","value":2}]',    '{"a":1,"b":2}'],
        ['add nested existing', '{"a":{"b":1}}', '[{"op":"add","path":"/a/b","value":9}]',  '{"a":{"b":9}}'],
        ['array insert',        '{"a":[1,3]}',   '[{"op":"add","path":"/a/1","value":2}]',  '{"a":[1,2,3]}'],
        ['array append',        '{"a":[1]}',     '[{"op":"add","path":"/a/-","value":2}]',  '{"a":[1,2]}'],
    );
    for my $c (@cases) {
        my ($name, $doc, $patch, $want) = @$c;
        my $d = jdoc $doc;
        jpatch $d, jdoc $patch;
        is "$d", $want, "jpatch: $name";
    }

    # the document must agree with its own serialisation afterwards
    my $d = jdoc '{"x":1}';
    jpatch $d, jdoc '[{"op":"add","path":"/x","value":2}]';
    is +(jgetp $d, "/x"), decode_json(jencode $d, "")->{x},
        'jpatch: document agrees with its own JSON';

    # applying the same add twice is idempotent (the upsert pattern)
    my $u = jdoc '{}';
    jpatch $u, jdoc '[{"op":"add","path":"/k","value":1}]' for 1 .. 3;
    is "$u", '{"k":1}', 'jpatch: repeated add is idempotent';
}

done_testing;
