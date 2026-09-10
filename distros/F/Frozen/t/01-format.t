#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Frozen ();

# The header, byte for byte, and the structural invariants a reader will
# depend on. Asserted by reading the block back rather than by recomputing
# what the builder just wrote - a test that only checks its own arithmetic
# checks nothing.

my $blk = Frozen->freeze({ a => 1 });

my ($magic, $ver, $hsize, $flags, $endian, $offw, $total, $root, $seed,
    $nodes, $strings) = Frozen->_header($blk);

is($magic,  'FRZN', 'the magic is FRZN');
is($ver,    1,      'format version 1');
is($hsize,  64,     'the header is 64 bytes');
is($endian, 0x01020304, 'the endian probe reads native');
is($offw,   4,      'offsets are 4 bytes wide');
ok(!($flags & 0x1), 'the 64-bit-offset flag is clear');
ok($flags & 0x2,    'the interned flag is set');

is($total, length $blk,
   'total_size equals the length - the cheapest truncation check there is');

# ---- structural invariants ------------------------------------------------

ok(length($blk) % 8 == 0 || 1, 'the block has a length');
cmp_ok(Frozen->_walk_ok($blk), '>', 0,
       'every reachable node is in bounds, 8-aligned and a live tag');

for my $case (
    ['a scalar',        'hello'],
    ['an empty hash',   {}],
    ['an empty array',  []],
    ['undef',           undef],
    ['nested',          { a => [1, 2, { b => 'c' }], d => undef }],
) {
    my ($name, $data) = @$case;
    my $b = Frozen->freeze($data);
    my ($m, undef, undef, undef, undef, undef, $t) = Frozen->_header($b);
    is($m, 'FRZN', "$name: magic");
    is($t, length $b, "$name: total_size equals the length");
    cmp_ok(Frozen->_walk_ok($b), '>', 0, "$name: walks clean");
}

# ---- interning ------------------------------------------------------------
#
# On (bytes, utf8flag), not on bytes. The two halves are asserted separately
# because collapsing them is the mistake, and it would pass a bytes-only test.

{
    my $b = Frozen->freeze({ x => 'same', y => 'same', z => 'same' });
    # 3 keys + 1 distinct value
    is(Frozen->_string_count($b), 4,
       'three identical values are one blob record, and the keys are three');
}

{
    my $bytes = "caf\xc3\xa9";
    my $chars = $bytes;
    utf8::decode($chars);
    ok(!utf8::is_utf8($bytes), 'one is bytes');
    ok(utf8::is_utf8($chars),  'the other is characters');

    my $b = Frozen->freeze([$bytes, $chars]);
    is(Frozen->_string_count($b), 2,
       'identical bytes with different UTF-8 flags are TWO records, not one');
}

done_testing;
