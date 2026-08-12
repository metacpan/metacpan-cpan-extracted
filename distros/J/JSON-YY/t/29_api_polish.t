use strict;
use warnings;
use Test::More;
use Config;
use JSON::YY qw(encode_json decode_json);
use JSON::YY ':doc';

# --- jnum: a string argument used to fall through to SvNV, so jnum "42" made
#     a JSON real and jnum "abc" quietly made 0.0 ---
{
    is "" . (jnum 42),     '42',   'jnum: integer';
    is "" . (jnum -7),     '-7',   'jnum: negative integer';
    is "" . (jnum 3.14),   '3.14', 'jnum: float';
    is "" . (jnum "42"),   '42',   'jnum: integer string is an integer, not 42.0';
    is "" . (jnum "-7"),   '-7',   'jnum: negative integer string';
    is "" . (jnum "3.14"), '3.14', 'jnum: float string';
    is "" . (jnum " 42 "), '42',   'jnum: surrounding space is tolerated';

    ok +(jis_int jnum("42"), ""),  'jnum "42" is typed as an integer';
    ok +(jis_real jnum("1e3"), ""), 'jnum "1e3" keeps its exponent form as a real';

    for my $bad ('abc', '', 'nan', 'inf', '12abc') {
        ok !eval { jnum $bad; 1 }, qq{jnum "$bad" croaks};
        like $@, qr/jnum: (?:not a number|cannot use)/, qq{jnum "$bad": message};
    }
    # a string that groks but overflows to Inf must be refused here, not left
    # to fail later at serialisation
    for my $ovf ('1e999', '-1e999') {
        ok !eval { jnum $ovf; 1 }, qq{jnum "$ovf" croaks rather than building Inf};
    }
    # not an exact-text check: older perls convert extreme exponents less
    # accurately, so just require a finite number
    ok +(jnum "1e308"), 'a large but finite string is still accepted';
    ok +(jis_real jnum("1e308"), ""), 'and is a real';

    ok !eval { jnum undef; 1 }, 'jnum undef croaks';
    like $@, qr/not a number: undef/, 'jnum undef: message';

    # exact 64-bit integers need a 64-bit IV; elsewhere they degrade to an NV
    SKIP: {
        skip 'needs a 64-bit IV perl', 3 unless $Config{ivsize} >= 8;
        is "" . (jnum "9223372036854775807"),  '9223372036854775807',  'jnum: IV_MAX';
        is "" . (jnum "-9223372036854775808"), '-9223372036854775808', 'jnum: IV_MIN';
        is "" . (jnum "18446744073709551615"), '18446744073709551615', 'jnum: UV_MAX';
    }
}

# --- Doc overloading ---
{
    my $a = jdoc '{"a":1}';
    my $b = jdoc '{"a":1}';
    my $c = jdoc '{"a":2}';

    ok $a eq $b, 'eq: equal documents';
    ok !($a eq $c), 'eq: different documents';
    ok $a ne $c, 'ne: different documents';

    # comparing against plain text used to be false whichever way round
    ok $a eq '{"a":1}', 'eq: matching JSON text';
    ok '{"a":1}' eq $a, 'eq: matching JSON text, operands swapped';
    ok !($a ne '{"a":1}'), 'ne: matching JSON text';
    ok $a ne '{"z":9}', 'ne: different text';
    ok !($a eq undef), 'eq: undef is not equal';

    # numeric comparison used to say every pair of Docs was equal
    ok $a == $a, '==: a handle equals itself';
    ok !($a == $b), '==: distinct handles differ even when contents match';
    ok $a != $b, '!=: distinct handles';
}

# --- jdel keeps working, and reports honestly ---
{
    my $doc = jdoc '{"a":{"x":1},"b":2}';
    my $removed = jdel $doc, "/a";
    is "$removed", '{"x":1}', 'jdel returns the removed subtree';
    is_deeply decode_json("$doc"), { b => 2 }, 'and the parent no longer has it';
    is +(jdel $doc, "/nope"), undef, 'jdel on a missing path returns undef';
    is_deeply decode_json("$doc"), { b => 2 }, 'and leaves the document alone';
}

# --- error message for something that is not a Doc ---
{
    ok !eval { jgetp {}, "/a"; 1 }, 'a plain hashref is rejected';
    like $@, qr/not a JSON::YY::Doc object/, 'and says it is not a Doc';
    unlike $@, qr/corrupted/, 'rather than calling it corrupted';

    my $it = jiter jdoc('[1]'), "";
    ok !eval { jgetp $it, ""; 1 }, 'an iterator is rejected where a Doc is wanted';
    like $@, qr/not a JSON::YY::Doc object/, 'with the same message';
    ok !eval { jnext jdoc('[1]'); 1 }, 'a Doc is rejected where an iterator is wanted';
    like $@, qr/not a JSON::YY::Iter object/, 'with the iterator message';
}

# --- large doubles must not encode into something we cannot read back ---
{
    # JSON reals are doubles, so on a long-double or quadmath perl a value
    # comes back narrowed. Compare against the value put through a double,
    # which is the most a JSON round-trip can preserve on any build.
    sub as_double { unpack 'd', pack 'd', $_[0] }

    my $max = 1.7976931348623157e308;
    SKIP: {
        skip 'this perl overflows the DBL_MAX literal', 2
            unless $max < 9**9**9;
        my $j = encode_json([$max]);
        my $back = eval { decode_json($j)->[0] };
        is $@, '', 'the largest double decodes again';   # used to croak: infinity
        cmp_ok $back, '==', as_double($max), 'and keeps its value';
    }

    # ordinary values keep their short form
    is encode_json([0.1]),  '[0.1]',  '0.1 is unchanged';
    is encode_json([3.5]),  '[3.5]',  '3.5 is unchanged';
    is encode_json([1e307]), '[1e+307]', '1e307 is unchanged';
    for my $v (0.1, 1e-7, 3.5, -2.25) {
        cmp_ok decode_json(encode_json([$v]))->[0], '==', as_double($v),
            "round-trip $v";
    }

    # At the exponent extremes the literal is no ground truth: perl 5.26 reads
    # 1e307 several ulps off (its own atof, not ours), and on a long-double or
    # quadmath perl the literal is wider than the JSON real it becomes. Assert
    # what survives both -- once a value has been through JSON it is stable.
    for my $v (1e307, -1e307, 5e-324) {
        my $once  = encode_json([ decode_json(encode_json([$v]))->[0] ]);
        my $twice = encode_json([ decode_json($once)->[0] ]);
        is $twice, $once, "round-trip $v";
    }
}

# --- max_depth reaches XS as a U32, so -1 wrapped to 4294967295: not
#     "unlimited" but deep enough to segfault, undoing the depth protection ---
{
    for my $bad (-1, -512, 2**32, 2**32 + 10, 'abc', '', '1.5', '0x10', ' 5') {
        ok !eval { JSON::YY->new(max_depth => $bad); 1 },
            "new(max_depth => '$bad') is rejected";
        like $@, qr/max_depth must be a non-negative integer/,
            "new(max_depth => '$bad'): message";
    }
    ok !eval { JSON::YY->new->max_depth(-1); 1 }, 'chained max_depth(-1) rejected';

    for my $good (0, 1, 512, 2000, 4294967295) {
        ok eval { JSON::YY->new(max_depth => $good); 1 },
            "new(max_depth => $good) is accepted";
    }
    ok eval { JSON::YY->new->max_depth; 1 }, 'chained max_depth() defaults';

    # the protection must actually still be in force after a legal setting
    my $deep = ('[' x 2000) . (']' x 2000);
    ok !eval { JSON::YY->new(max_depth => 512)->decode($deep); 1 },
        'a legal max_depth still bounds decoding';
}

# --- a huge NV must never encode to a number our own decoder rejects: perls
#     that cache NV stringification would skip buf_cat_nv's fixup ---
{
    my $max = 1.7976931348623157e308;
    my $str = "$max";                       # populates the PV slot
    SKIP: {
    skip 'this perl overflows the DBL_MAX literal', 4 unless $max < 9**9**9;
    for my $c (['encode_json'  => sub { encode_json([$max]) }],
               ['OO encode'    => sub { JSON::YY->new(utf8 => 1)->encode([$max]) }],
               ['pretty'       => sub { JSON::YY->new(utf8 => 1, pretty => 1)->encode([$max]) }],
               ['jfrom'        => sub { "" . jfrom [$max] }]) {
        my ($name, $enc) = @$c;
        my $j = $enc->();
        ok eval { decode_json($j); 1 }, "$name: a stringified DBL_MAX decodes again";
    }
    }
}

# --- jfind must not numify a non-numeric match to 0, and must compare a
#     stringified integer as an integer ---
{
    my $d = jdoc '[{"id":0,"n":"zero"},{"id":1,"n":"one"},{"id":-5,"n":"neg"},{"id":2.5,"n":"real"}]';
    for my $bad ('abc', '', 'zzz', 'null') {
        my $r = jfind $d, "", "/id", $bad;
        is $r, undef, qq{jfind "$bad" does not match the id-0 record};
    }
    for my $c ([1,'one'], ['1','one'], [0,'zero'], ['0','zero'],
               [-5,'neg'], ['-5','neg'], [2.5,'real'], ['2.5','real']) {
        my $r = jfind $d, "", "/id", $c->[0];
        is +(jgetp $r, "/n"), $c->[1], "jfind $c->[0] finds $c->[1]";
    }

    # above 2^53 a double compare would pick the wrong record
    SKIP: {
        skip 'needs a 64-bit IV perl', 3 unless $Config{ivsize} >= 8;
        my $b = jdoc '[{"id":9007199254740992,"n":"a"},{"id":9007199254740993,"n":"b"}]';
        my $want = 9007199254740993;
        is +(jgetp +(jfind $b, "", "/id", $want), "/n"), 'b', 'big integer match';
        my $str = "$want";
        is +(jgetp +(jfind $b, "", "/id", $str), "/n"), 'b', 'big integer as a string matches too';
        my $u = jdoc '[{"id":18446744073709551615,"n":"max"}]';
        is +(jgetp +(jfind $u, "", "/id", "18446744073709551615"), "/n"), 'max', 'UV_MAX as a string';
    }

    # negative zero is zero
    my $z = jdoc '[{"v":0,"n":"zero"},{"v":-1,"n":"minus"}]';
    for my $m ('-0', '0', 0, '-0.0', '0.0') {
        is +(jgetp +(jfind $z, "", "/v", $m), "/n"), 'zero', qq{jfind "$m" matches 0};
    }
    is +(jgetp +(jfind $z, "", "/v", '-1'), "/n"), 'minus', 'negative integers still match';

    # INT64_MIN is representable and must be matchable
    SKIP: {
        skip 'needs a 64-bit IV perl', 2 unless $Config{ivsize} >= 8;
        my $mn = jdoc '[{"id":-9223372036854775808,"n":"min"},{"id":-1,"n":"neg"}]';
        is +(jgetp +(jfind $mn, "", "/id", -9223372036854775808), "/n"), 'min', 'jfind IV_MIN';
        is +(jgetp +(jfind $mn, "", "/id", "-9223372036854775808"), "/n"), 'min',
            'jfind IV_MIN as a string';
    }

    # empty containers have no leaves, so jpaths lists none (documented)
    is join("|", jpaths jdoc('{"a":{},"b":[],"c":1}'), ""), '/c',
        'jpaths skips empty containers';
}

# --- jpaths output must be usable as path input (the COOKBOOK pattern) ---
{
    my $doc = jdoc qq({"caf\x{e9}":{"x":1},"plain":2});
    my @p = jpaths $doc, "";
    ok utf8::is_utf8($p[0]), 'a path with a non-ASCII key comes back flagged';
    is_deeply [ map { jencode $doc, $_ } @p ], ['1','2'],
        'every returned path resolves (COOKBOOK: jencode $doc, $_ for @paths)';
    is +(jgetp $doc, $p[0]), 1, 'and jgetp finds it';

    my @a = jpaths jdoc('{"a":{"b":1}}'), "";
    ok !utf8::is_utf8($a[0]), 'an ASCII-only path is left unflagged';
    is $a[0], '/a/b', 'and is correct';
}

# --- comparing a Doc with a plain string must work under `use utf8` ---
{
    my $doc = jdoc qq({"k":"caf\x{e9}"});
    ok $doc eq qq({"k":"caf\x{e9}"}),   'eq a character string';
    ok $doc eq qq({"k":"caf\xc3\xa9"}), 'eq the same text as UTF-8 bytes';
    ok !($doc ne qq({"k":"caf\x{e9}"})), 'ne agrees';
    ok $doc ne qq({"k":"other"}),        'ne a different string';
    ok !($doc eq qq({"k":"other"})),     'eq a different string is false';
    ok +(jdoc qq({"k":"\x{1f600}"})) eq qq({"k":"\x{1f600}"}), 'eq with a wide character';
    ok +(jdoc '{"a":1}') eq '{"a":1}',   'plain ASCII still compares';
}

# --- documented: jset creates missing parents as objects, even numeric ones ---
{
    my $d = jfrom {};
    jset $d, "/users/0/name", "Bob";
    is "$d", '{"users":{"0":{"name":"Bob"}}}', 'numeric component creates an object';
    my $e = jfrom {};
    jset $e, "/users", [];
    jset $e, "/users/-", { name => "Bob" };
    is "$e", '{"users":[{"name":"Bob"}]}', 'the documented workaround gives an array';
}

done_testing;
