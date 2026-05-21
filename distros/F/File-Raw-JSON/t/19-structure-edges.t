#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::JSON qw(file_json_decode file_json_encode);

# Structure-level edge cases that the RFC 8259 happy-path tests
# don't cover.  Empty containers, deep nesting, mixed-type arrays,
# duplicate keys, sparse arrays, encode-side error handling for
# unencodable refs.

subtest 'empty containers' => sub {
    is_deeply(file_json_decode('{}'), {}, 'empty object decodes to {}');
    is_deeply(file_json_decode('[]'), [], 'empty array decodes to []');

    is(file_json_encode({}), '{}', 'empty hash encodes to {}');
    is(file_json_encode([]), '[]', 'empty array encodes to []');
};

subtest 'nested empty containers' => sub {
    my $r = file_json_decode('[[],{},[[],{}]]');
    is_deeply($r, [[], {}, [[], {}]], 'nested empty containers decoded');
    is(file_json_encode($r), '[[],{},[[],{}]]',
       'nested empty containers re-encoded byte-identically');
};

subtest 'mixed-type array' => sub {
    my $r = file_json_decode(
        '[1, "two", null, true, false, [3, 4], {"k":"v"}]'
    );
    is($r->[0], 1,             'int');
    is($r->[1], 'two',         'string');
    is($r->[2], undef,         'null');
    ok(!!$r->[3],              'true');
    ok(! $r->[4],              'false');
    is_deeply($r->[5], [3, 4], 'nested array');
    is_deeply($r->[6], {k=>'v'}, 'nested object');
};

subtest 'object with many keys (1000)' => sub {
    my $src = '{' . join(',', map qq|"k$_":$_|, 1..1000) . '}';
    my $r = file_json_decode($src);
    is(scalar keys %$r, 1000, '1000 keys decoded');
    is($r->{k1},     1,     'first key');
    is($r->{k500}, 500,     'middle key');
    is($r->{k1000}, 1000,   'last key');

    # Re-encode + parse round-trip preserves value count.
    my $back = file_json_decode(file_json_encode($r));
    is(scalar keys %$back, 1000, 'count preserved through round-trip');
};

subtest 'deeply nested arrays (within max_depth)' => sub {
    # Default max_depth is 512.  Build 100-deep nesting.
    my $depth = 100;
    my $src = ('[' x $depth) . '1' . (']' x $depth);
    my $r = file_json_decode($src);
    my $cur = $r;
    for (1..$depth - 1) {
        $cur = $cur->[0];
        last unless ref $cur eq 'ARRAY';
    }
    is(ref $cur, 'ARRAY', "nested $depth deep, all arrays");
    is($cur->[0], 1, 'innermost value preserved');
};

subtest 'max_depth caps decoder' => sub {
    # The decoder threads a depth counter through its recursive
    # walker (sv_from_yyjson_d) and croaks if depth exceeds the
    # configured max_depth (default 512).
    my $deep = '[' x 600;
    eval { file_json_decode($deep . '1' . (']' x 600)) };
    like($@, qr/max_depth.*exceeded/i,
         'depth 600 with default max_depth=512 croaks');

    # Raising max_depth lets the deeper input through.
    my $r = eval {
        file_json_decode($deep . '1' . (']' x 600), max_depth => 1024)
    };
    ok(!$@ && ref($r) eq 'ARRAY',
       'deep input parses ok with raised max_depth');
};

subtest 'duplicate keys: yyjson keeps last' => sub {
    # JSON allows duplicate keys; behaviour is implementation-defined.
    # yyjson keeps the last by default.
    my $r = file_json_decode('{"a":1,"a":2,"a":3}');
    is($r->{a}, 3, 'last duplicate wins');
    is(scalar keys %$r, 1, 'only one key in resulting hash');
};

subtest 'sparse Perl array encodes holes as null' => sub {
    my @a;
    $a[0] = 1;
    $a[3] = 4;          # leaves [1, undef, undef, 4]
    my $bytes = file_json_encode(\@a);
    is($bytes, '[1,null,null,4]', 'sparse array holes -> null');

    my $back = file_json_decode($bytes);
    is_deeply($back, [1, undef, undef, 4], 'round-trips through decode');
};

subtest 'encode rejects unencodable refs' => sub {
    # CODE / GLOB / Regexp refs aren't JSON-representable.  The
    # encoder explicitly checks SvTYPE(target) before falling through
    # to SvPV and croaks with a useful message.

    eval { file_json_encode(sub { 1 }) };
    like($@, qr/CODE reference/, 'encoding a CODE ref croaks');

    eval { file_json_encode(\*STDOUT) };
    like($@, qr/GLOB reference/, 'encoding a GLOB ref croaks');

    eval { file_json_encode(qr/x/) };
    like($@, qr/Regexp reference/, 'encoding a Regexp ref croaks');
};

subtest 'encode handles blessed non-boolean by stringifying' => sub {
    # Blessed scalar refs that aren't one of the recognised boolean
    # classes get stringified.  Assert we don't crash and produce
    # *some* JSON-shaped output.
    my $obj = bless { name => 'foo' }, 'My::Class';
    my $bytes;
    my $ok = eval { $bytes = file_json_encode($obj); 1 };
    ok($ok, 'blessed hash ref does not croak');
    ok(defined $bytes && length $bytes,
       'blessed hash produces non-empty JSON bytes')
        or diag "got: ", defined $bytes ? $bytes : '<undef>';
};

subtest 'circular refs are detected and rejected' => sub {
    # The encoder threads a per-call `visited` HV through the
    # recursive walker.  AV / HV targets get added on entry and
    # removed on exit, so diamonds (a value referenced from two
    # places without a cycle) still encode as two copies, but a
    # true cycle is caught and croaks.

    my $h = { name => 'root' };
    $h->{self} = $h;
    eval { file_json_encode($h) };
    like($@, qr/circular reference/i, 'self-referential hash croaks');

    my $a = [1];
    push @$a, $a;
    eval { file_json_encode($a) };
    like($@, qr/circular reference/i, 'self-referential array croaks');

    # Diamond DAG (no cycle) still works: shared structure encoded twice.
    my $shared = { x => 1 };
    my $diamond = [$shared, $shared];
    my $bytes = eval { file_json_encode($diamond, sort_keys => 1) };
    is($bytes, '[{"x":1},{"x":1}]',
       'diamond (no cycle) encodes as two independent copies');
};

subtest 'JSONL: empty buffer decodes to empty arrayref' => sub {
    my $r = file_json_decode('', mode => 'lines');
    is_deeply($r, [], 'empty bytes -> empty AoV');
};

subtest 'JSONL: trailing newline tolerated' => sub {
    my $r = file_json_decode(qq|{"a":1}\n{"b":2}\n|, mode => 'lines');
    is(scalar @$r, 2, 'two records');
    is_deeply($r->[0], {a=>1}, 'row 0');
    is_deeply($r->[1], {b=>2}, 'row 1');
};

subtest 'JSONL: missing trailing newline tolerated' => sub {
    my $r = file_json_decode(qq|{"a":1}\n{"b":2}|, mode => 'lines');
    is(scalar @$r, 2, 'two records without trailing newline');
};

subtest 'JSONL: multiple values on one line' => sub {
    my $r = file_json_decode('{"a":1}{"b":2}{"c":3}', mode => 'lines');
    is(scalar @$r, 3, 'three concatenated values');
    is($r->[0]{a}, 1, 'a=1');
    is($r->[2]{c}, 3, 'c=3');
};

subtest 'JSONL: pretty-printed values span multiple lines' => sub {
    my $src = qq|{\n  "a": 1\n}\n{\n  "b": 2\n}\n|;
    my $r = file_json_decode($src, mode => 'lines');
    is(scalar @$r, 2, 'two pretty-printed records');
    is_deeply($r->[0], {a=>1}, 'pretty row 0');
    is_deeply($r->[1], {b=>2}, 'pretty row 1');
};

subtest 'mode override on json plugin (mode => lines)' => sub {
    # The XSUB defaults to document but accepts mode => lines, same
    # as the plugin path's mode override.
    my $rows = file_json_decode(qq|[1,2]\n[3,4]|, mode => 'lines');
    is(scalar @$rows, 2,           'two AoV elements');
    is_deeply($rows->[0], [1, 2],  'first row');
    is_deeply($rows->[1], [3, 4],  'second row');
};

subtest 'sort_keys + canonical agree on key order' => sub {
    my $val = { c => 3, a => 1, b => 2 };
    my $sorted    = file_json_encode($val, sort_keys => 1);
    my $canonical = file_json_encode($val, canonical => 1);
    is($sorted,    '{"a":1,"b":2,"c":3}', 'sort_keys produces alpha order');
    is($canonical, '{"a":1,"b":2,"c":3}', 'canonical produces alpha order');
};

subtest 'pretty + sort_keys produces idempotent output' => sub {
    my $val = { c => 3, a => 1, b => 2, nested => [1, 2, { x => 9 }] };
    my $first  = file_json_encode($val, pretty => 1, sort_keys => 1);
    my $second = file_json_encode(file_json_decode($first),
                                  pretty => 1, sort_keys => 1);
    is($second, $first,
       'parse + re-encode with same opts produces identical bytes');
};

done_testing;
