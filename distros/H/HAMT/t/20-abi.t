#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use HAMT ();
use HAMT::Map;
use HAMT::Set;
use HAMT::Vector;

# The C ABI: the table has a stable address, the selftest walks every entry
# in C with every answer checked, and what C built through the table is what
# the Perl surface says it is.

my $p = HAMT::_abi_ptr();
ok($p, '_abi_ptr returns a non-zero address');
is($p, HAMT::_abi_ptr(), 'and the same one every call');
like($p, qr/^\d+$/, 'and an unsigned integer: where the loader maps the object decides the sign bit');
is(HAMT::_abi_version(), 1, 'the table is version 1');

# ---- the selftest -----------------------------------------------------------
#
# A table is a list of addresses, and nothing about compiling one proves an
# entry points where its declaration says. The selftest calls each through
# the table and checks what comes back, by number.
my $blocks = HAMT::_live_blocks();
my ($step, $map, $set, $vec) = HAMT::_abi_selftest();

is($step, 0, 'every entry in the table answered as its declaration says')
    or diag(($step < 0 ? 'and left something allocated: ' : '')
          . 'check number ' . abs($step) . ' in include/hamt/hamt_abi_selftest.h failed');

# ---- what C built, read from Perl ---------------------------------------------
#
# The selftest can agree with itself and be wrong. These are the same three
# containers asked through the other door.
SKIP: {
    skip 'the selftest did not finish', 21 if $step;

    isa_ok($map, 'HAMT::Map', 'the map C built');
    my $latin = chr(0xe9);
    my $wide  = chr(0x100);
    is_deeply({ $map->pairs }, { alpha => 1, beta => 2, gone => undef, $latin => 3, $wide => 4 },
              'holds the pairs C stored, under the keys Perl would use for them');
    is($map->count, 5, 'with the count C kept');
    is($map->_check, 0, 'in a valid trie');
    ok($map->equals(HAMT::Map->new(alpha => 1, beta => 2, gone => undef, $latin => 3, $wide => 4)),
       'and equals the same map built in Perl');
    ok($map->exists(do { my $u = $latin; utf8::upgrade($u); $u }), 'the key C stored as UTF-8 is found by either spelling');
    ok(Scalar::Util::readonly($map->get('alpha')), 'a value C stored is read-only, as one Perl stored would be');
    my $next = $map->set(more => 1);
    is($next->count, 6, 'it takes an update like any other map');
    is($map->count, 5, 'and is unchanged by it');

    isa_ok($set, 'HAMT::Set', 'the set C built');
    is($set->count, 100, 'has the hundred members C added');
    ok($set->equals(HAMT::Set->new(map { "m$_" } 0 .. 99)), 'which are the ones Perl would have added');
    is($set->_check, 0, 'in a valid trie');
    ok($set->union(HAMT::Set->new('x'))->has('x') && !$set->has('x'), 'and takes an update like any other set');

    isa_ok($vec, 'HAMT::Vector', 'the vector C built');
    is($vec->count, 1100, 'has the 1,100 values C pushed');
    is_deeply([ $vec->list ], [ 0 .. 1099 ], 'in the order C pushed them');
    is($vec->_check, 0, 'in a valid tree');
    ok($vec->equals(HAMT::Vector->new(0 .. 1099)), 'and equals the same vector built in Perl');
    is($vec->push('x')->count, 1101, 'and takes an update like any other vector');
    is($vec->count, 1100, 'unchanged by it');
}

# ---- nothing left behind ---------------------------------------------------------
undef $_ for $map, $set, $vec;
is(HAMT::_live_blocks(), $blocks, 'with those three gone, the selftest has left nothing allocated');

for my $round (1 .. 5) { my @r = HAMT::_abi_selftest(); }
is(HAMT::_live_blocks(), $blocks, 'nor has running it five more times');

# ---- a consumer can find the header -------------------------------------------------
ok(eval { require HAMT::Install::Files; 1 }, 'HAMT::Install::Files loads') or diag $@;
{
    no warnings 'once';
    my $core = $HAMT::Install::Files::CORE;
    ok(defined $core && -f "$core/hamt_abi.h", 'and names a directory that holds hamt_abi.h');
    my $text = do { local (@ARGV, $/) = ("$core/hamt_abi.h"); <> } // '';
    like($text, qr/^#define HAMT_ABI_VERSION 1$/m, 'which declares the version the table reports');
    unlike($text, qr/#\s*include\s+"hamt\//, 'and includes none of the private headers, which are not installed');
}

done_testing;
