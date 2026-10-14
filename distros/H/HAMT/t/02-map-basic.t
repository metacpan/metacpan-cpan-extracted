#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr blessed);
use HAMT::Map;

# The surface, one method at a time. After every update the receiver is read
# again: "unchanged" is asserted, not assumed.

sub as_hash { my ($m) = @_; return { $m->pairs } }

my $empty = HAMT::Map->new;
isa_ok($empty, 'HAMT::Map');
is($empty->count, 0, 'a new map is empty');
is_deeply([ $empty->keys ], [], 'with no keys');
is($empty->get('a'), undef, 'get on an empty map is undef');
ok(!$empty->exists('a'), 'and nothing exists');
is($empty->_check, 0, 'and it checks out');

my $m = HAMT::Map->new(a => 1, b => 2);
is($m->count, 2, 'new takes pairs');
is($m->get('a'), 1, 'get a');
is($m->get('b'), 2, 'get b');
ok($m->exists('a'), 'a exists');
ok(!$m->exists('c'), 'c does not');
is($m->get('c'), undef, 'and getting it is undef');

# ---- set -------------------------------------------------------------------
my $m2 = $m->set(c => 3);
isa_ok($m2, 'HAMT::Map');
isnt(refaddr($m2), refaddr($m), 'set returns another map');
is_deeply(as_hash($m2), { a => 1, b => 2, c => 3 }, 'holding the new pair');
is_deeply(as_hash($m), { a => 1, b => 2 }, 'and the receiver is what it was');
is($m->count, 2, 'with its count');

my $m3 = $m2->set(d => 4, e => 5, a => 'one');
is_deeply(as_hash($m3), { a => 'one', b => 2, c => 3, d => 4, e => 5 },
          'set takes several pairs and replaces as it goes');
is_deeply(as_hash($m2), { a => 1, b => 2, c => 3 }, 'the receiver is what it was');
is($m3->count, 5, 'a replaced key is not counted twice');

my $same_key_twice = $m->set(z => 1, z => 2);
is($same_key_twice->get('z'), 2, 'the later of two pairs for one key wins');
is($same_key_twice->count, 3, 'and is one key');

is(refaddr($m->set), refaddr($m), 'set with no pairs is the receiver');
is(refaddr($m->set(a => $m->get('a'))), refaddr($m),
   'setting a key to the scalar it already holds is the receiver');
{
    # Only a read-only scalar can be a stored one, so only those are looked
    # up first. A read-only scalar that is NOT the stored one must still be
    # stored, and one from another key's value must not be mistaken.
    my $ro = 'frozen';
    Internals::SvREADONLY($ro, 1);
    my $r = $m->set(a => $ro);
    is($r->get('a'), 'frozen', 'a read-only scalar from elsewhere is stored like any other');
    isnt(refaddr($r), refaddr($m), 'in a new map');
    is($m->set(a => $m->get('b'))->get('a'), 2, 'and another key\'s stored scalar is a new value for this one');
    is(refaddr($m->set(b => $m->get('b'), a => $m->get('a'))), refaddr($m), 'two keys each set to their own stored scalar is the receiver');
}
isnt(refaddr($m->set(a => 1)), refaddr($m),
     'setting it to an equal value from elsewhere is a new map: values are not compared');

# ---- delete ----------------------------------------------------------------
my $m4 = $m3->delete('a', 'b');
is_deeply(as_hash($m4), { c => 3, d => 4, e => 5 }, 'delete takes several keys');
is_deeply(as_hash($m3), { a => 'one', b => 2, c => 3, d => 4, e => 5 },
          'and the receiver is what it was');
is(refaddr($m->delete('nope')), refaddr($m), 'deleting an absent key is the receiver');
is(refaddr($m->delete), refaddr($m), 'and so is deleting nothing');
my $gone = $m->delete('a', 'b');
is($gone->count, 0, 'deleting every key leaves an empty map');
is_deeply([ $gone->keys ], [], 'with no keys');
is($gone->set(x => 1)->get('x'), 1, 'that can be added to again');
is($m->delete('a', 'a', 'a')->count, 1, 'deleting a key twice in one call is deleting it once');

# ---- values of every kind ---------------------------------------------------
{
    my $aref = [1, 2];
    my $code = sub { 42 };
    my $obj  = bless {}, 'Local::Thing';
    my $v = HAMT::Map->new(
        undef => undef, zero => 0, empty => '', int => -7, num => 1.5,
        str => 'text', aref => $aref, code => $code, obj => $obj,
        wide => chr(0x263a),
    );
    ok($v->exists('undef'), 'a key holding undef exists');
    is($v->get('undef'), undef, 'and holds undef');
    is($v->get('zero'), 0, 'zero');
    is($v->get('empty'), '', 'the empty string');
    is($v->get('int'), -7, 'a negative integer');
    is($v->get('num'), 1.5, 'a fraction');
    is($v->get('str'), 'text', 'a string');
    is($v->get('wide'), chr(0x263a), 'a wide character');
    is(refaddr($v->get('aref')), refaddr($aref), 'an array reference is the same array');
    is($v->get('code')->(), 42, 'a code reference still calls');
    is(blessed($v->get('obj')), 'Local::Thing', 'an object keeps its class');
}

# ---- lists ------------------------------------------------------------------
{
    my %src = map { ("key$_" => $_ * 2) } 1 .. 500;
    my $big = HAMT::Map->new(%src);
    is($big->count, 500, '500 pairs in');
    is($big->_check, 0, 'checks out');
    my @k = $big->keys;
    my @v = $big->values;
    my @p = $big->pairs;
    is(scalar @k, 500, 'keys in list context');
    is(scalar @v, 500, 'values in list context');
    is(scalar @p, 1000, 'pairs in list context');
    is_deeply([ sort @k ], [ sort keys %src ], 'the keys are the keys');
    my %zipped; @zipped{@k} = @v;
    is_deeply(\%zipped, \%src, 'keys and values are parallel');
    is_deeply({ @p }, \%src, 'pairs are key then value');
    is_deeply([ @p[ grep { !($_ & 1) } 0 .. $#p ] ], \@k, 'in the order keys gives');
    is_deeply([ $big->keys ], \@k, 'which is the same order every time');

    is(scalar($big->keys), 500, 'keys in scalar context is the count');
    is(scalar($big->values), 500, 'so is values');
    is(scalar($big->pairs), 500, 'and pairs: the count of pairs, not of elements');
}

# ---- to_hash and from_hash --------------------------------------------------
{
    my $src = { a => 1, b => [1, 2], c => undef, chr(0xe9) => 'latin', chr(0x100) => 'wide' };
    my $fm = HAMT::Map->from_hash($src);
    isa_ok($fm, 'HAMT::Map');
    is($fm->count, 5, 'from_hash takes every pair');
    my $back = $fm->to_hash;
    is(ref $back, 'HASH', 'to_hash returns a hash reference');
    is_deeply($back, $src, 'holding what went in');
    $back->{a} = 'changed';
    $back->{new} = 1;
    is($fm->get('a'), 1, 'writing to it does not reach the map');
    ok(!$fm->exists('new'), 'nor does adding to it');
    isnt(refaddr($fm->to_hash), refaddr($back), 'each call makes a new hash');
    $src->{a} = 'changed';
    is($fm->get('a'), 1, 'and writing to the source hash does not reach the map');

    # Keys are read straight from the hash, in whatever form it keeps them.
    {
        my $up = chr(0xe9); utf8::upgrade($up);
        my %odd = ($up => 'e-acute', chr(0x100) => 'wide', '' => 'empty', "a\0b" => 'nul', 12 => 'number');
        my $o = HAMT::Map->from_hash(\%odd);
        is_deeply({ $o->pairs }, \%odd, 'from_hash keeps keys of every kind: upgraded, wide, empty, with a NUL, numeric');
        is($o->get(chr(0xe9)), 'e-acute', 'a key the hash was given upgraded is found by its plain spelling');
        ok($o->equals(HAMT::Map->new(%odd)), 'and the map equals one built from the same pairs with new');
        is($o->_check, 0, 'in a valid trie');

        require Tie::Hash;
        tie my %tied, 'Tie::StdHash';
        %tied = (a => 1, $up => 2, chr(0x100) => 3);
        my $t = HAMT::Map->from_hash(\%tied);
        is_deeply({ $t->pairs }, { a => 1, chr(0xe9) => 2, chr(0x100) => 3 }, 'from_hash reads a tied hash');
        is($t->_check, 0, 'into a valid trie');

        my %big = map { ("key$_" => $_) } 1 .. 5000;
        ok(HAMT::Map->from_hash(\%big)->equals(HAMT::Map->new(%big)), 'and 5,000 pairs the same as new does');
    }
    ok(!eval { HAMT::Map->from_hash([]); 1 }, 'from_hash refuses an array reference');
    like($@, qr/^HAMT::Map::from_hash: not a hash reference/, 'by name');
    ok(!eval { HAMT::Map->from_hash('x'); 1 }, 'and a plain string');
    is(HAMT::Map->from_hash({})->count, 0, 'an empty hash is an empty map');
}

# ---- errors -----------------------------------------------------------------
ok(!eval { HAMT::Map->new('a'); 1 }, 'new with an odd list croaks');
like($@, qr/^HAMT::Map::new: odd number of arguments/, 'by name');
ok(!eval { my $x = $m->set('a'); 1 }, 'set with an odd list croaks');
like($@, qr/^HAMT::Map::set: odd number of arguments/, 'by name');
is_deeply(as_hash($m), { a => 1, b => 2 }, 'and the receiver is untouched after a croak');

# A croak in the middle of several pairs leaves nothing behind.
{
    package Local::Dies;
    sub TIESCALAR { bless [], shift }
    sub FETCH { die "fetch refused\n" }
}
{
    tie my $bomb, 'Local::Dies';
    my $r = eval { $m->set(x => 1, y => $bomb, z => 3) };
    is($@, "fetch refused\n", 'a value that dies on being read stops the set');
    is($r, undef, 'which returns nothing');
    is_deeply(as_hash($m), { a => 1, b => 2 }, 'and the receiver is untouched');
}

done_testing;
