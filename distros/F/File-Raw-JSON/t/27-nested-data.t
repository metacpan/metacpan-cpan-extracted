#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::JSON qw(file_json_decode file_json_encode);

# Nested-structure exercise.  Existing tests cover decode-edge cases
# and ordered mode separately; this file focuses on realistic shapes
# (API responses, config files, AoH / HoA / mixed alternation) and
# verifies that round-trip + various encode flags all preserve them.

sub roundtrip_eq {
    my ($val, $opts, $label) = @_;
    $opts ||= {};
    my $bytes = file_json_encode($val, %$opts);
    my $back  = file_json_decode($bytes);
    is_deeply($back, $val, $label);
    return $bytes;
}

subtest 'AoH with consistent schema' => sub {
    my $rows = [
        { id => 1, name => 'alice', email => 'a@example.com', active => 1 },
        { id => 2, name => 'bob',   email => 'b@example.com', active => 0 },
        { id => 3, name => 'carol', email => 'c@example.com', active => 1 },
    ];
    roundtrip_eq($rows, undef, 'AoH round-trips');
    roundtrip_eq($rows, { sort_keys => 1 }, 'AoH round-trips with sort_keys');
    roundtrip_eq($rows, { pretty => 1, sort_keys => 1 },
                 'AoH round-trips with pretty + sort_keys');
};

subtest 'AoH with varying keys per row' => sub {
    # Real-world: optional fields appear / vanish per row.
    my $rows = [
        { id => 1, name => 'alice' },
        { id => 2, name => 'bob',   email => 'b@example.com' },
        { id => 3, name => 'carol', metadata => { source => 'import' } },
        { id => 4 },
    ];
    roundtrip_eq($rows, undef, 'sparse AoH round-trips');
    roundtrip_eq($rows, { sort_keys => 1 }, 'sparse AoH with sort_keys');
};

subtest 'HoA at multiple depths' => sub {
    my $h = {
        tags         => [qw(red green blue)],
        coordinates  => [10.5, 20.25, 30.5],
        identifiers  => [],
        nested_lists => [
            [1, 2, 3],
            [4, 5, 6],
            [],
        ],
    };
    roundtrip_eq($h, undef, 'HoA round-trips');
    roundtrip_eq($h, { sort_keys => 1 }, 'HoA with sort_keys');
};

subtest 'mixed AoHoAoH (4-level alternation)' => sub {
    my $val = [
        {
            owner => 'alpha',
            items => [
                { name => 'first',  values => [{ x => 1 }, { x => 2 }] },
                { name => 'second', values => [{ x => 3 }] },
            ],
        },
        {
            owner => 'beta',
            items => [
                { name => 'only',   values => [] },
            ],
        },
    ];
    roundtrip_eq($val, undef, '4-level alternation round-trips');
    roundtrip_eq($val, { sort_keys => 1 },
                 '4-level alternation with sort_keys');
};

subtest 'realistic API-response shape' => sub {
    my $resp = {
        status   => 'ok',
        version  => '2.1.0',
        request  => {
            id        => 'req-abc-123',
            timestamp => 1715200000,
            params    => { limit => 50, offset => 0, sort => 'asc' },
        },
        data => {
            total => 3,
            items => [
                {
                    id     => 'item-1',
                    title  => 'First item',
                    tags   => [qw(a b c)],
                    author => { name => 'Alice', verified => 1 },
                    stats  => { views => 100, likes => 5, dislikes => 0 },
                },
                {
                    id     => 'item-2',
                    title  => 'Second',
                    tags   => [],
                    author => { name => 'Bob', verified => 0 },
                    stats  => { views => 50, likes => 1, dislikes => 0 },
                },
                {
                    id     => 'item-3',
                    title  => 'Third with nested',
                    tags   => [qw(x)],
                    author => { name => 'Carol', verified => 1 },
                    stats  => { views => 200, likes => 12, dislikes => 1 },
                    nested => {
                        meta => {
                            created => '2026-05-08',
                            source  => { module => 'importer', version => 3 },
                        },
                    },
                },
            ],
        },
        errors  => [],
        warnings => undef,
    };
    roundtrip_eq($resp, undef, 'API response round-trips');
    roundtrip_eq($resp, { sort_keys => 1 },
                 'API response with sort_keys');
    roundtrip_eq($resp, { canonical => 1 },
                 'API response with canonical');
    roundtrip_eq($resp, { pretty => 1, sort_keys => 1 },
                 'API response with pretty + sort_keys');
};

subtest 'realistic config-file shape' => sub {
    my $cfg = {
        server => {
            host => '0.0.0.0',
            port => 8080,
            tls  => {
                cert => '/etc/ssl/server.crt',
                key  => '/etc/ssl/server.key',
                ciphers => [qw(ECDHE-ECDSA-AES256-GCM-SHA384
                               ECDHE-RSA-AES256-GCM-SHA384)],
            },
        },
        db => {
            primary => {
                host => 'db1.internal',
                port => 5432,
                pool => { min => 2, max => 20, timeout_ms => 5000 },
            },
            replica => {
                host => 'db2.internal',
                port => 5432,
                pool => { min => 1, max => 5, timeout_ms => 5000 },
            },
        },
        features => {
            enabled  => [qw(auth caching ratelimit)],
            disabled => [qw(tracing)],
            flags    => {
                experimental_routing => 1,
                strict_validation    => 0,
            },
        },
        logging => {
            level   => 'info',
            outputs => [
                { type => 'stdout' },
                { type => 'file', path => '/var/log/app.log', rotate => 'daily' },
            ],
        },
    };
    roundtrip_eq($cfg, undef, 'config round-trips');
    roundtrip_eq($cfg, { sort_keys => 1 }, 'config with sort_keys');
    roundtrip_eq($cfg, { pretty => 1 },    'config with pretty');
};

subtest 'mixed leaf types at varying depths' => sub {
    my $val = {
        L0_int    => 1,
        L0_float  => 1.5,
        L0_string => 'x',
        L0_null   => undef,
        L0_arr    => [],
        L0_obj    => {},
        L1 => {
            L1_int   => 2,
            L1_arr   => [
                3,
                3.5,
                'three',
                undef,
                [4, [5, [6]]],
                { L4_terminal => 'leaf' },
            ],
        },
    };
    my $bytes = roundtrip_eq($val, { sort_keys => 1 },
                             'mixed-leaf nesting round-trips');
    # Spot-check the deepest leaf survives.
    my $back = file_json_decode($bytes);
    is($back->{L1}{L1_arr}[4][1][1][0], 6,
       'deepest array leaf preserved (val[4][1][1][0] = 6)');
    is($back->{L1}{L1_arr}[5]{L4_terminal}, 'leaf',
       'deepest hash leaf preserved');
};

subtest 'nested booleans + nulls round-trip' => sub {
    my $val = {
        flags => [
            File::Raw::JSON::Boolean::TRUE(),
            File::Raw::JSON::Boolean::FALSE(),
            undef,
            File::Raw::JSON::Boolean::TRUE(),
        ],
        nested => {
            ok      => File::Raw::JSON::Boolean::TRUE(),
            failure => File::Raw::JSON::Boolean::FALSE(),
            note    => undef,
        },
    };
    my $bytes = file_json_encode($val);
    my $back  = file_json_decode($bytes);

    ok( $back->{flags}[0],          'top-level array bool true');
    ok(!$back->{flags}[1],          'top-level array bool false');
    is( $back->{flags}[2], undef,   'top-level array null');
    ok( $back->{flags}[3],          'top-level array bool true (after null)');
    ok( $back->{nested}{ok},        'nested bool true');
    ok(!$back->{nested}{failure},   'nested bool false');
    is( $back->{nested}{note}, undef, 'nested null');
};

subtest 'JSONL with nested rows' => sub {
    my $rows = [
        { id => 1, items => [ { x => 1 }, { x => 2 } ], meta => { ok => 1 } },
        { id => 2, items => [],                          meta => { ok => 0 } },
        { id => 3, items => [ { x => 99, y => [1,2,3] } ] },
    ];
    my $jsonl = file_json_encode($rows, mode => 'lines');
    # One newline-terminated record per row.
    is(scalar(() = $jsonl =~ /\n/g), 3, 'three line terminators');

    my $back = file_json_decode($jsonl, mode => 'lines');
    is_deeply($back, $rows, 'JSONL with nested rows round-trips');
};

subtest 'JSONL: pretty-printed + nested + decode' => sub {
    # Pretty values can span multiple lines; the brace-balancer must
    # cope with nesting inside individual records.
    my $rows = [
        { a => 1, nested => { x => [1,2,3] } },
        { a => 2, nested => { y => [4,5,6] } },
    ];
    # Encode with pretty (single-doc mode) + manually concat as JSONL.
    my $bytes = file_json_encode($rows->[0], pretty => 1, sort_keys => 1)
              . "\n"
              . file_json_encode($rows->[1], pretty => 1, sort_keys => 1)
              . "\n";

    my $back = file_json_decode($bytes, mode => 'lines');
    is(scalar @$back, 2, 'pretty multi-line JSONL: two records');
    is_deeply($back->[0]{nested}{x}, [1,2,3], 'first nested array');
    is_deeply($back->[1]{nested}{y}, [4,5,6], 'second nested array');
};

subtest 'wide-and-deep: 100 children x 100 grandchildren' => sub {
    # NB: capture the outer $_ before entering the inner map -
    # otherwise the inner $_ shadows it and we'd get "leaf_N_N"
    # pairs instead of "leaf_<child>_<item>".
    my @children = map {
        my $cid = $_;
        +{
            id    => $cid,
            items => [ map "leaf_${cid}_$_", 1..100 ],
        }
    } 1..100;
    my $val = { count => scalar @children, children => \@children };

    my $bytes = file_json_encode($val);
    my $back  = file_json_decode($bytes);

    is($back->{count}, 100,                 'top-level count preserved');
    is(scalar @{$back->{children}}, 100,    'children array preserved');
    is(scalar @{$back->{children}[0]{items}}, 100,
       'first child has 100 leaf items');
    is($back->{children}[42]{items}[7], 'leaf_43_8',
       'arbitrary leaf coordinates preserved');
};

subtest 'deep alternation: 5-level array/hash/array/hash/array' => sub {
    # arr[0] -> hash{a} -> arr[0] -> hash{x} -> arr[0] = "deep!"
    my $val = [ { a => [ { x => [ 'deep!' ] } ] } ];
    my $bytes = file_json_encode($val);
    is($bytes, '[{"a":[{"x":["deep!"]}]}]',
       '5-level alternation produces expected JSON');

    my $back = file_json_decode($bytes);
    is($back->[0]{a}[0]{x}[0], 'deep!',
       '5-level alternation walks back correctly');
};

subtest 'object whose values are all empty containers' => sub {
    my $val = {
        empty_arr   => [],
        empty_obj   => {},
        nested_arr  => [ [], [[]], [[[]]] ],
        nested_obj  => { a => {}, b => { c => {} } },
    };
    my $bytes = roundtrip_eq($val, { sort_keys => 1 },
                             'all-empty containers round-trip');
    # Sanity-check the byte form is what we expect.
    like($bytes, qr/"empty_arr":\[\]/, 'empty_arr emitted as []');
    like($bytes, qr/"empty_obj":\{\}/, 'empty_obj emitted as {}');
};

subtest 'sort_keys is applied at every nesting level' => sub {
    my $val = {
        z_outer => 1,
        a_outer => {
            z_inner => [
                { z_leaf => 1, a_leaf => 2 },
                { c => 3, b => 4 },
            ],
            a_inner => 'x',
        },
    };
    my $bytes = file_json_encode($val, sort_keys => 1);
    # Expected: every object's keys appear alphabetically.
    is($bytes,
       '{"a_outer":{"a_inner":"x","z_inner":[{"a_leaf":2,"z_leaf":1},{"b":4,"c":3}]},"z_outer":1}',
       'sort_keys flattens key order at every depth');
};

subtest 'pretty preserves nesting visually' => sub {
    my $val = { outer => { middle => { inner => [1, 2, 3] } } };
    my $bytes = file_json_encode($val, pretty => 1, sort_keys => 1);
    # 2-space indent default.  Inner array element should be indented 8 spaces.
    like($bytes, qr/^\{\n/,                        'starts with brace + newline');
    like($bytes, qr/\n        1,/,                 'array element at 8-space indent');
    like($bytes, qr/\n  "outer":/,                 'top-level key at 2-space indent');
};

done_testing;
