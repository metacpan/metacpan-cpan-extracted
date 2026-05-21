#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::JSON qw(file_json_decode file_json_encode);
use Tie::OrderedHash;

# Cross-product of:
#   - ordered=>1 / Tie::OrderedHash (keys preserve insertion order)
#   - nested data (objects inside arrays inside objects)
#
# Coverage check: t/15 covers ordered basics, t/26 covers dynamic
# builds, t/27 covers nested plain data.  This file stresses the
# combination: realistic shapes built or decoded with ordering
# preserved at every depth, plus mutation -> re-encode round-trips.

# ---- helpers ---------------------------------------------------------

# Recursively gather the key order of every object inside `$val`.
# Returns an arrayref of arrayrefs, in encounter order
# (depth-first walk).  Used to assert order preservation across
# decode -> re-encode -> decode cycles.
sub gather_key_orders {
    my ($val, $out) = @_;
    $out ||= [];
    if (ref $val eq 'HASH') {
        push @$out, [keys %$val];
        for my $k (keys %$val) {
            gather_key_orders($val->{$k}, $out);
        }
    } elsif (ref $val eq 'ARRAY') {
        gather_key_orders($_, $out) for @$val;
    }
    return $out;
}

# Build a dynamic Tie::OrderedHash from a flat (k,v,...) list.
sub oh_from {
    tie my %h, 'Tie::OrderedHash';
    while (my ($k, $v) = splice @_, 0, 2) { $h{$k} = $v; }
    return \%h;
}

# ---- subtests --------------------------------------------------------

subtest 'realistic API-response shape: order preserved at every depth' => sub {
    # Source bytes have a deliberate non-alphabetical key order at
    # every level.  Decode with ordered=>1, then walk every nested
    # object and confirm keys come back in source order.
    my $src = q|{
        "status":"ok",
        "version":"2.1.0",
        "request":{
            "id":"req-abc-123",
            "timestamp":1715200000,
            "params":{"limit":50,"offset":0,"sort":"asc"}
        },
        "data":{
            "total":2,
            "items":[
                {"id":"x1","title":"First","stats":{"views":10,"likes":1}},
                {"id":"x2","title":"Second","stats":{"views":20,"likes":2}}
            ]
        }
    }|;
    my $r = file_json_decode($src, ordered => 1);

    is_deeply([keys %$r],
              [qw(status version request data)],
              'top-level keys in source order');
    is_deeply([keys %{$r->{request}}],
              [qw(id timestamp params)],
              'request inner keys in source order');
    is_deeply([keys %{$r->{request}{params}}],
              [qw(limit offset sort)],
              'request.params keys in source order');
    is_deeply([keys %{$r->{data}}],
              [qw(total items)],
              'data keys in source order');
    is_deeply([keys %{$r->{data}{items}[0]}],
              [qw(id title stats)],
              'data.items[0] keys in source order');
    is_deeply([keys %{$r->{data}{items}[0]{stats}}],
              [qw(views likes)],
              'data.items[0].stats keys in source order');

    # Re-encode and confirm byte-faithful.
    my $back = file_json_encode($r);
    my $r2   = file_json_decode($back, ordered => 1);
    is_deeply(gather_key_orders($r2), gather_key_orders($r),
              'round-trip preserves the entire key-order tree');
};

subtest 'config-file shape: every nested section ordered' => sub {
    # Config files care about section ordering for diff stability.
    my $src = q|{
        "server":{"host":"0.0.0.0","port":8080,"tls":{"cert":"/c","key":"/k"}},
        "db":{"primary":{"host":"db1","port":5432},"replica":{"host":"db2","port":5432}},
        "logging":{"level":"info","outputs":[{"type":"stdout"},{"type":"file","path":"/log","rotate":"daily"}]}
    }|;
    my $cfg = file_json_decode($src, ordered => 1);

    is_deeply([keys %$cfg], [qw(server db logging)],
              'top-level config sections in source order');
    is_deeply([keys %{$cfg->{server}}], [qw(host port tls)],
              'server keys preserved');
    is_deeply([keys %{$cfg->{server}{tls}}], [qw(cert key)],
              'tls keys preserved');
    is_deeply([keys %{$cfg->{db}}], [qw(primary replica)],
              'db keys preserved');
    is_deeply([keys %{$cfg->{db}{primary}}], [qw(host port)],
              'db.primary keys preserved');
    is_deeply([keys %{$cfg->{logging}{outputs}[1]}],
              [qw(type path rotate)],
              'logging.outputs[1] keys preserved (last array elem)');
};

subtest 'AoH: each row independently ordered' => sub {
    # JSONL-style data where row schemas differ.  Each row is its
    # own object; the ordered=>1 flag must apply to every row.
    my $src = q|[
        {"id":1,"name":"alice","verified":true},
        {"id":2,"verified":false,"name":"bob"},
        {"name":"carol","id":3}
    ]|;
    my $rows = file_json_decode($src, ordered => 1);

    is(ref $rows, 'ARRAY', 'top-level array');
    is(scalar @$rows, 3, 'three rows');
    is_deeply([keys %{$rows->[0]}], [qw(id name verified)], 'row 0');
    is_deeply([keys %{$rows->[1]}], [qw(id verified name)], 'row 1 (different order)');
    is_deeply([keys %{$rows->[2]}], [qw(name id)],          'row 2 (different schema)');

    # Each row is a tied OrderedHash.
    is(ref(tied(%{$rows->[0]})), 'Tie::OrderedHash', 'row 0 is tied');
    is(ref(tied(%{$rows->[1]})), 'Tie::OrderedHash', 'row 1 is tied');
};

subtest 'mixed: outer plain HV, inner tied OrderedHash' => sub {
    # Build a structure where the outer shell is a plain hash but
    # the inner sections are Tie::OrderedHash.  Encode must walk
    # both correctly.
    my $val = {
        plain_outer => {
            wrapper => oh_from(z => 1, a => 2, m => 3),
            list    => [
                oh_from(third => 'C', first => 'A', second => 'B'),
                oh_from(only => 'X'),
            ],
        },
    };

    my $bytes = file_json_encode($val);
    # The inner ordered keys are deterministic.
    like($bytes, qr/"z":1,"a":2,"m":3/, 'wrapper keys in source order');
    like($bytes, qr/"third":"C","first":"A","second":"B"/,
         'first list-row keys in source order');
    like($bytes, qr/"only":"X"/, 'second list-row');
};

subtest 'mutate: insert key after decode -> re-encode appends at end' => sub {
    my $r = file_json_decode(q|{"alpha":1,"beta":2}|, ordered => 1);
    $r->{gamma} = 3;
    is_deeply([keys %$r], [qw(alpha beta gamma)],
              'inserted key appears at end');
    my $bytes = file_json_encode($r);
    is($bytes, '{"alpha":1,"beta":2,"gamma":3}',
       're-encode emits inserted key at end');
};

subtest 'mutate: update existing key preserves position' => sub {
    my $r = file_json_decode(q|{"alpha":1,"beta":2,"gamma":3}|, ordered => 1);
    $r->{beta} = 'updated';
    is_deeply([keys %$r], [qw(alpha beta gamma)],
              'updated key keeps its position');
    is($r->{beta}, 'updated', 'value updated');
    my $bytes = file_json_encode($r);
    is($bytes, '{"alpha":1,"beta":"updated","gamma":3}',
       're-encode reflects update without reordering');
};

subtest 'mutate: delete key removes it, others preserved' => sub {
    my $r = file_json_decode(q|{"a":1,"b":2,"c":3,"d":4}|, ordered => 1);
    delete $r->{b};
    is_deeply([keys %$r], [qw(a c d)],
              'remaining keys in original order');
    my $bytes = file_json_encode($r);
    is($bytes, '{"a":1,"c":3,"d":4}',
       're-encode reflects deletion');

    # Insert after delete: lands at the end.
    $r->{e} = 5;
    is(file_json_encode($r), '{"a":1,"c":3,"d":4,"e":5}',
       'insert after delete lands at end');
};

subtest 'mutate inside a nested ordered hash' => sub {
    my $src = q|{"top":{"x":1,"y":2,"z":3}}|;
    my $r = file_json_decode($src, ordered => 1);
    $r->{top}{w} = 4;       # add to inner
    delete $r->{top}{y};    # delete from inner
    is_deeply([keys %{$r->{top}}], [qw(x z w)],
              'nested mutations: insert at end, delete preserves rest');
    my $bytes = file_json_encode($r);
    is($bytes, '{"top":{"x":1,"z":3,"w":4}}',
       're-encoded structure reflects nested mutations');
};

subtest 'JSONL slurp: each row independently ordered' => sub {
    my $src = qq|{"z":1,"a":2}\n{"third":3,"first":1,"second":2}\n{"only":"x"}\n|;
    my $rows = file_json_decode($src, mode => 'lines', ordered => 1);
    is(scalar @$rows, 3, 'three rows');
    is_deeply([keys %{$rows->[0]}], [qw(z a)],                  'row 0');
    is_deeply([keys %{$rows->[1]}], [qw(third first second)],   'row 1');
    is_deeply([keys %{$rows->[2]}], [qw(only)],                 'row 2');
    is(ref(tied(%{$rows->[1]})), 'Tie::OrderedHash',
       'each JSONL row is its own tied OrderedHash');
};

subtest 'JSONL streaming: each_line callback receives ordered rows' => sub {
    use File::Raw;
    use File::Temp qw(tempfile);
    my ($fh, $path) = tempfile(UNLINK => 1);
    print $fh qq|{"third":3,"first":1,"second":2}\n|;
    print $fh qq|{"y":2,"x":1}\n|;
    print $fh qq|{"alpha":"A"}\n|;
    close $fh;

    my @collected;
    File::Raw::each_line(
        $path,
        sub { my $row = $_[0]; push @collected, [keys %$row] },
        plugin => 'jsonl', ordered => 1,
    );
    is_deeply($collected[0], [qw(third first second)], 'streamed row 0');
    is_deeply($collected[1], [qw(y x)],                 'streamed row 1');
    is_deeply($collected[2], [qw(alpha)],               'streamed row 2');
};

subtest 'sort_keys overrides ordered at every level' => sub {
    # ordered=>1 is decode; sort_keys=>1 is encode.  When you
    # decode with ordered (so internal keys are insertion-ordered)
    # and then re-encode with sort_keys, the *output* should be
    # alphabetically sorted at every level - sort_keys wins.
    my $src = q|{"z":{"y":2,"x":1},"a":[{"q":1,"p":2}]}|;
    my $r = file_json_decode($src, ordered => 1);

    my $sorted = file_json_encode($r, sort_keys => 1);
    is($sorted, '{"a":[{"p":2,"q":1}],"z":{"x":1,"y":2}}',
       'sort_keys flattens the order tree on encode');

    # Without sort_keys, the source order is preserved.
    my $natural = file_json_encode($r);
    is($natural, '{"z":{"y":2,"x":1},"a":[{"q":1,"p":2}]}',
       'no sort_keys: source order preserved on encode');
};

subtest 'deep ordered: 5-level nested objects, all keys preserved' => sub {
    # Each of the 5 nesting levels is its own ordered hash with
    # deliberately non-alphabetical keys.
    my $src = q|{
        "L0_z":1,
        "L0_a":{"L1_y":2,"L1_b":{"L2_x":3,"L2_c":{"L3_w":4,"L3_d":{"L4_v":5,"L4_e":6}}}}
    }|;
    my $r = file_json_decode($src, ordered => 1);

    is_deeply([keys %$r],                                    [qw(L0_z L0_a)], 'L0');
    is_deeply([keys %{$r->{L0_a}}],                          [qw(L1_y L1_b)], 'L1');
    is_deeply([keys %{$r->{L0_a}{L1_b}}],                    [qw(L2_x L2_c)], 'L2');
    is_deeply([keys %{$r->{L0_a}{L1_b}{L2_c}}],              [qw(L3_w L3_d)], 'L3');
    is_deeply([keys %{$r->{L0_a}{L1_b}{L2_c}{L3_d}}],        [qw(L4_v L4_e)], 'L4');
};

subtest 'ordered hash inside array inside ordered hash (alternation)' => sub {
    my $src = q|{"outer_z":1,"outer_a":[{"r":1,"q":2,"p":3},{"only":"x"}],"outer_m":2}|;
    my $r = file_json_decode($src, ordered => 1);

    is_deeply([keys %$r], [qw(outer_z outer_a outer_m)],
              'top-level ordered keys preserved');
    is_deeply([keys %{$r->{outer_a}[0]}], [qw(r q p)],
              'array-element-0 ordered keys preserved');
    is_deeply([keys %{$r->{outer_a}[1]}], [qw(only)],
              'array-element-1 ordered keys preserved');
};

subtest 'numeric-looking keys round-trip in source order (not lex)' => sub {
    # "1", "2", "10" sort lexically as "1","10","2" - confirms
    # we're preserving source order, not falling through to a sort.
    my $src = q|{"1":"one","2":"two","10":"ten","100":"hundred"}|;
    my $r = file_json_decode($src, ordered => 1);
    is_deeply([keys %$r], [qw(1 2 10 100)],
              'numeric-looking keys preserve source order');

    my $bytes = file_json_encode($r);
    is($bytes, '{"1":"one","2":"two","10":"ten","100":"hundred"}',
       're-encode preserves numeric-looking key order');

    # Alphabetic sort would put "1","10","100","2" - confirm
    # sort_keys would do exactly that, distinguishing the two paths.
    my $sorted = file_json_encode($r, sort_keys => 1);
    is($sorted, '{"1":"one","10":"ten","100":"hundred","2":"two"}',
       'sort_keys gives lexical, not numeric, ordering');
};

subtest 'special-char keys preserve order' => sub {
    my $src = q|{"a-b":1,"a.b":2,"a/b":3,"a b":4,"a\"b":5,"a\\\\b":6}|;
    my $r = file_json_decode($src, ordered => 1);
    is_deeply([keys %$r],
              ['a-b', 'a.b', 'a/b', 'a b', 'a"b', 'a\\b'],
              'keys with hyphens, dots, slashes, spaces, quotes, backslashes ordered');
};

subtest 'UTF-8 keys preserve order in nested ordered hash' => sub {
    # Mix of ASCII, BMP and non-BMP keys, deliberately not in lex order.
    my $src = q|{"z":1,"é":2,"中":3,"a":4}|;
    my $r = file_json_decode($src, ordered => 1);
    my @ks = keys %$r;
    is(scalar @ks, 4, 'four keys');
    is($ks[0], 'z',          'first key (ASCII)');
    is($ks[1], "\x{00e9}",   'second key (é)');
    is($ks[2], "\x{4e2d}",   'third key (中)');
    is($ks[3], 'a',          'fourth key (ASCII)');
};

subtest 'whole-tree mutation cycle: decode -> mutate everywhere -> re-encode' => sub {
    my $src = q|{"a":{"x":1,"y":2},"b":[{"p":10,"q":20},{"r":30}]}|;
    my $r = file_json_decode($src, ordered => 1);

    # Mutate at every level.
    $r->{c}            = 'new top-level';
    $r->{a}{z}         = 3;
    $r->{a}{x}         = 'updated';      # in-place
    $r->{b}[0]{s}      = 99;
    delete $r->{b}[1]{r};
    push @{$r->{b}}, oh_from(fresh => 'row');

    is_deeply([keys %$r], [qw(a b c)], 'top-level: c added at end');
    is_deeply([keys %{$r->{a}}], [qw(x y z)], 'a: z added at end, x updated in place');
    is_deeply([keys %{$r->{b}[0]}], [qw(p q s)], 'b[0]: s added at end');
    is_deeply([keys %{$r->{b}[1]}], [],          'b[1]: r deleted');
    is(scalar @{$r->{b}}, 3, 'b array grew by one');
    is_deeply([keys %{$r->{b}[2]}], [qw(fresh)], 'b[2]: dynamically built ordered row');

    # Re-encode and decode again - structure must come back identical.
    my $bytes = file_json_encode($r);
    my $r2    = file_json_decode($bytes, ordered => 1);

    is_deeply([keys %$r2],            [qw(a b c)],   'top-level survives round-trip');
    is_deeply([keys %{$r2->{a}}],     [qw(x y z)],   'a survives round-trip');
    is_deeply([keys %{$r2->{b}[0]}],  [qw(p q s)],   'b[0] survives round-trip');
    is_deeply([keys %{$r2->{b}[2]}],  [qw(fresh)],   'b[2] survives round-trip');
};

subtest 'ordered=>1 with pretty: byte-faithful round-trip' => sub {
    my $orig = q|{"z":1,"a":2,"m":{"y":3,"x":4}}|;
    my $r       = file_json_decode($orig, ordered => 1);
    my $pretty  = file_json_encode($r, pretty => 1);
    my $r2      = file_json_decode($pretty, ordered => 1);
    my $compact = file_json_encode($r2);
    is($compact, $orig, 'pretty round-trip lands back at byte-identical compact form');
};

done_testing;
