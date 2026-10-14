#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr reftype blessed weaken readonly);
use HAMT::Map;
use HAMT::Set;
use HAMT::Vector;

# Nested data: array references and hash references as values, to any depth,
# and containers inside containers.
#
# The rule being tested is one sentence: a container holds the REFERENCE it
# was given, read-only, and never looks inside what it refers to. So the
# structure is the caller's own, shared by every version that holds it, and
# kept alive exactly as long as one of them does.

{
    package Local::Counted;
    our %alive; our $made = 0;
    sub new { my ($class, %f) = @_; my $o = bless { id => ++$made, %f }, $class; $alive{ $o->{id} } = 1; $o }
    sub DESTROY { delete $alive{ $_[0]{id} } }
}
sub alive { scalar keys %Local::Counted::alive }

my $blocks = HAMT::_live_blocks();

# ---- array and hash references as map values ----------------------------------
{
    my $list = [1, 2, 3];
    my $hash = { name => 'x', tags => ['a', 'b'] };
    my $m = HAMT::Map->new(list => $list, hash => $hash, empty_list => [], empty_hash => {});

    is(reftype($m->get('list')), 'ARRAY', 'an array reference comes back as an array reference');
    is(reftype($m->get('hash')), 'HASH', 'a hash reference as a hash reference');
    is(refaddr($m->get('list')), refaddr($list), 'it is the same array, not a copy of it');
    is(refaddr($m->get('hash')), refaddr($hash), 'and the same hash');
    is_deeply($m->get('list'), [1, 2, 3], 'holding what the array holds');
    is_deeply($m->get('hash'), { name => 'x', tags => ['a', 'b'] }, 'and what the hash holds, nested array and all');
    is_deeply($m->get('empty_list'), [], 'an empty array reference is a value');
    is_deeply($m->get('empty_hash'), {}, 'and an empty hash reference');
    is($m->get('hash')->{tags}[1], 'b', 'it can be read into as deep as it goes');
    is(scalar @{ $m->get('list') }, 3, 'and dereferenced in place');

    # The reference is fixed; what it refers to is not.
    ok(readonly($m->get('list')), 'the stored reference is read-only');
    ok(!eval { $_ = [] for $m->get('list'); 1 }, 'so it cannot be pointed at another array');
    like($@, qr/Modification of a read-only value/, "with perl's own message");
    push @{ $m->get('list') }, 4;
    is_deeply($list, [1, 2, 3, 4], 'but the array it refers to can be pushed to: the map is shallow');
    $m->get('hash')->{tags}[0] = 'A';
    $m->get('hash')->{added} = 1;
    is_deeply($hash, { name => 'x', tags => ['A', 'b'], added => 1 }, 'and so can a hash, at any depth');
    ok(!readonly($list->[0]) && !readonly($hash->{name}), 'nothing inside the structure was made read-only');
}

# ---- every version shares the one structure -------------------------------------
{
    my $inner = { count => 0, log => [] };
    my $v1 = HAMT::Map->new(state => $inner);
    my $v2 = $v1->set(other => 1);
    my $v3 = $v2->delete('other')->set(more => [1]);
    $inner->{count}++;
    push @{ $inner->{log} }, 'changed after storing';
    is($v1->get('state')->{count}, 1, 'a change to a stored hash is seen through the first version');
    is($v2->get('state')->{count}, 1, 'and the second');
    is($v3->get('state')->{log}[0], 'changed after storing', 'and the third, at depth');
    is(refaddr($v1->get('state')), refaddr($v3->get('state')), 'because all of them hold the one hash');

    # To change a nested value without changing the old version: a new structure.
    my $v4 = $v3->update(state => sub { +{ %{ $_[0] }, count => 99 } });
    is($v4->get('state')->{count}, 99, 'update with a copied hash gives the new version its own');
    is($v3->get('state')->{count}, 1, 'and leaves the old version with the old one');
    isnt(refaddr($v4->get('state')), refaddr($v3->get('state')), 'they are different hashes now');
    is(refaddr($v4->get('state')->{log}), refaddr($v3->get('state')->{log}),
       'whose own nested array is still shared: the copy was one level deep, as the caller made it');
}

# ---- deep structures ---------------------------------------------------------------
{
    my $deep = { a => [ { b => { c => [ 1, { d => 'bottom' } ] } } ] };
    my $m = HAMT::Map->new(deep => $deep);
    is($m->get('deep')->{a}[0]{b}{c}[1]{d}, 'bottom', 'a value five references down is reached');
    is_deeply($m->get('deep'), $deep, 'and the whole structure compares equal to what went in');

    my $tower = 'floor';
    $tower = [ $tower ] for 1 .. 200;
    my $t = HAMT::Map->new(tower => $tower);
    my $walk = $t->get('tower');
    $walk = $walk->[0] for 1 .. 200;
    is($walk, 'floor', 'a structure 200 references deep is stored and read back');

    my $cyclic = { name => 'loop' };
    $cyclic->{self} = $cyclic;
    my $c = HAMT::Map->new(loop => $cyclic);
    is(refaddr($c->get('loop')->{self}{self}), refaddr($cyclic), 'a structure that refers to itself is stored without being walked');
    delete $cyclic->{self};
}

# ---- array and hash references in a vector ---------------------------------------------
{
    my @rows = map { { id => $_, tags => [ "t$_", 'common' ] } } 1 .. 200;
    my $v = HAMT::Vector->new(@rows);
    is($v->count, 200, 'a vector of 200 hash references');
    is($v->get(41)->{id}, 42, 'read by index');
    is($v->get(-1)->{tags}[0], 't200', 'and into, from the end');
    is(refaddr($v->get(0)), refaddr($rows[0]), 'each is the hash that was pushed');
    is_deeply([ map { $_->{id} } $v->list ], [ 1 .. 200 ], 'list hands them out in order');

    my $v2 = $v->set(10, { id => 'replaced', tags => [] });
    is($v2->get(10)->{id}, 'replaced', 'a hash reference replaced by another');
    is($v->get(10)->{id}, 11, 'in the new vector only');
    is(refaddr($v2->get(11)), refaddr($v->get(11)), 'while their neighbours are the same hashes in both');

    my $grid = HAMT::Vector->new(map { [ ($_) x 3 ] } 1 .. 3);
    is_deeply([ map { [@$_] } $grid->list ], [ [1, 1, 1], [2, 2, 2], [3, 3, 3] ], 'a vector of arrays is a grid');
    $grid->get(1)->[1] = 'x';
    is_deeply($grid->get(1), [2, 'x', 2], 'whose rows are the caller\'s to write to');

    my $joined = $v->slice(0, 3)->concat(HAMT::Vector->new([ 'tail' ]))->insert(1, { id => 'in' });
    is_deeply([ map { ref eq 'HASH' ? $_->{id} : $_->[0] } $joined->list ], [ 1, 'in', 2, 3, 'tail' ],
              'sliced, joined and inserted into, the references travel untouched');
    is(refaddr($joined->get(0)), refaddr($rows[0]), 'still the first hash');
}

# ---- copies out: to_hash and to_array are shallow ----------------------------------------
{
    my $list = [1, 2];
    my $m = HAMT::Map->new(list => $list, n => 1);
    my $h = $m->to_hash;
    is(refaddr($h->{list}), refaddr($list), 'to_hash copies the reference, not the array');
    ok(!readonly($h->{list}), 'into a scalar that is writable');
    $h->{list} = 'replaced in the copy';
    is(refaddr($m->get('list')), refaddr($list), 'so replacing it in the hash does not reach the map');

    my $v = HAMT::Vector->new($list, { k => 1 });
    my $a = $v->to_array;
    is(refaddr($a->[0]), refaddr($list), 'to_array likewise');
    $a->[1] = undef;
    is_deeply($v->get(1), { k => 1 }, 'and the vector keeps what it had');

    my $nested = { outer => { inner => [1, 2, 3] }, list => [ { x => 1 } ] };
    my $from = HAMT::Map->from_hash($nested);
    is(refaddr($from->get('outer')), refaddr($nested->{outer}), 'from_hash takes the nested references as they are');
    is_deeply($from->to_hash, $nested, 'and a round trip through a map gives the same structure back');
    $nested->{outer} = 'the hash it came from, changed';
    is(reftype($from->get('outer')), 'HASH', 'changing the source hash\'s own slot does not reach the map');
}

# ---- equality: by address, unless told to look inside ---------------------------------------
{
    my $shared = [1, 2];
    my $a = HAMT::Map->new(k => $shared);
    ok($a->equals(HAMT::Map->new(k => $shared)), 'two maps holding the same array are equal');
    ok(!$a->equals(HAMT::Map->new(k => [1, 2])), 'two maps holding equal arrays are not: references compare by address');

    my $deep_eq;
    $deep_eq = sub {
        my ($x, $y) = @_;
        return 0 if ref $x ne ref $y;
        return $x eq $y unless ref $x;
        return @$x == @$y && !grep { !$deep_eq->($x->[$_], $y->[$_]) } 0 .. $#$x if ref $x eq 'ARRAY';
        return keys %$x == keys %$y && !grep { !exists $y->{$_} || !$deep_eq->($x->{$_}, $y->{$_}) } keys %$x
            if ref $x eq 'HASH';
        return refaddr($x) == refaddr($y);
    };
    ok($a->equals(HAMT::Map->new(k => [1, 2]), $deep_eq), 'with a sub that looks inside, they are');
    my $big1 = HAMT::Map->new(map { ("k$_" => { n => $_, list => [ 1 .. 3 ] }) } 1 .. 300);
    my $big2 = HAMT::Map->new(map { ("k$_" => { n => $_, list => [ 1 .. 3 ] }) } 1 .. 300);
    ok(!$big1->equals($big2), '300 pairs of equal nested values: not equal by address');
    ok($big1->equals($big2, $deep_eq), 'equal by a deep comparison');
    ok(!$big1->equals($big2->set(k150 => { n => 150, list => [1, 2, 4] }), $deep_eq), 'and unequal when one differs inside');

    ok(HAMT::Vector->new([1], { a => 1 })->equals(HAMT::Vector->new([1], { a => 1 }), $deep_eq),
       'a vector compares the same way');
    ok(!HAMT::Vector->new([1])->equals(HAMT::Vector->new([1])), 'and by address without the sub');
}

# ---- merge and diff over nested values -----------------------------------------------------------
{
    my $a = HAMT::Map->new(tags => ['a', 'b'], conf => { x => 1 }, only_a => [1]);
    my $b = HAMT::Map->new(tags => ['c'], conf => { y => 2 }, only_b => { k => 1 });
    my $plain = $a->merge($b);
    is_deeply($plain->get('tags'), ['c'], 'a plain merge takes the other map\'s reference whole');
    is(refaddr($plain->get('only_a')), refaddr($a->get('only_a')), 'and shares what only one side had');

    my $combined = $a->merge($b, sub {
        my ($key, $mine, $theirs) = @_;
        return ref $mine eq 'ARRAY' ? [ @$mine, @$theirs ] : { %$mine, %$theirs };
    });
    is_deeply($combined->get('tags'), ['a', 'b', 'c'], 'a resolver can join two arrays');
    is_deeply($combined->get('conf'), { x => 1, y => 2 }, 'or two hashes');
    is_deeply($a->get('tags'), ['a', 'b'], 'into new structures, leaving the receiver\'s as they were');
    is_deeply($b->get('conf'), { y => 2 }, 'and the other map\'s');

    my @seen;
    my $n = $a->diff($b, sub { my ($k, $was, $now, $kind) = @_; push @seen, "$kind:$k:" . (ref($was) || '-') . ':' . (ref($now) || '-') });
    is($n, 4, 'a diff reports nested values that are different references');
    is_deeply([ sort @seen ], [ 'add:only_b:-:HASH', 'change:conf:HASH:HASH', 'change:tags:ARRAY:ARRAY', 'remove:only_a:ARRAY:-' ],
              'by kind, handing over the references themselves');
    is($a->diff($a->set(tags => $a->get('tags')), sub { die 'never' }), 0, 'the same reference stored again is no difference');
}

# ---- a set of references is a set of their names ----------------------------------------------------
{
    my ($x, $y) = ([1], [1]);
    my $s = HAMT::Set->new($x, $y, $x);
    is($s->count, 2, 'two different arrays are two members, and one given twice is one');
    ok($s->has($x) && $s->has("$x"), 'found by the reference or by its string form: a member is a string');
    my ($back) = $s->members;
    ok(!ref $back, 'and a string is what comes back out, not the array');
}

# ---- containers inside containers ----------------------------------------------------------------------
{
    my $alice = HAMT::Map->new(name => 'alice', roles => HAMT::Set->new('admin'), log => HAMT::Vector->new('created'));
    my $users = HAMT::Map->new(alice => $alice, bob => HAMT::Map->new(name => 'bob'));

    isa_ok($users->get('alice'), 'HAMT::Map', 'a map stored in a map');
    isa_ok($users->get('alice')->get('roles'), 'HAMT::Set', 'a set stored in that');
    is($users->get('alice')->get('log')->get(0), 'created', 'and a vector, read all the way through');
    is(refaddr($users->get('alice')), refaddr($alice), 'the inner map is the object that was stored');

    # A persistent update three levels down: each level makes one new
    # container and shares the rest.
    my $users2 = $users->update(alice => sub {
        $_[0]->update(roles => sub { $_[0]->add('editor') })
             ->update(log   => sub { $_[0]->push('promoted') });
    });
    ok($users2->get('alice')->get('roles')->has('editor'), 'a nested update reaches the innermost set');
    is($users2->get('alice')->get('log')->count, 2, 'and the innermost vector');
    ok(!$users->get('alice')->get('roles')->has('editor'), 'the old outer map still sees the old inner set');
    is($users->get('alice')->get('log')->count, 1, 'and the old inner vector');
    is(refaddr($users2->get('bob')), refaddr($users->get('bob')), 'and what was not touched is the same object in both');
    is($alice->get('roles')->count, 1, 'the inner map first stored is itself unchanged');

    # Unlike a plain hash, an inner container cannot be changed under the outer one.
    {
        my @w;
        local $SIG{__WARN__} = sub { push @w, @_ };
        $users->get('alice')->get('roles')->add('sneaky');
        is(scalar @w, 1, 'an "in place" update of an inner container is the usual useless-use warning');
    }
    ok(!$users->get('alice')->get('roles')->has('sneaky'), 'and changes nothing, at any depth: nested containers are immutable all the way down');

    # Equality between nested containers: by address unless delegated.
    my $same_shape = HAMT::Map->new(alice => HAMT::Map->new(name => 'alice'));
    my $again      = HAMT::Map->new(alice => HAMT::Map->new(name => 'alice'));
    ok(!$same_shape->equals($again), 'two outer maps holding equal inner maps are not equal by address');
    ok($same_shape->equals($again, sub { blessed($_[0]) && $_[0]->can('equals') ? $_[0]->equals($_[1]) : $_[0] eq $_[1] }),
       'and are with a sub that asks the inner maps');

    my $matrix = HAMT::Vector->new(map { HAMT::Vector->new(($_) x 4) } 1 .. 4);
    my $matrix2 = $matrix->set(2, $matrix->get(2)->set(1, 'x'));
    is_deeply([ map { [ $_->list ] } $matrix2->list ], [ [1, 1, 1, 1], [2, 2, 2, 2], [3, 'x', 3, 3], [4, 4, 4, 4] ],
              'a vector of vectors, one cell changed');
    is($matrix->get(2)->get(1), 3, 'in the new matrix only');
    is(refaddr($matrix2->get(0)), refaddr($matrix->get(0)), 'sharing every row that did not change');

    my $index = HAMT::Map->new(evens => HAMT::Set->new(2, 4, 6), odds => HAMT::Set->new(1, 3, 5));
    my $t = $index->transient;
    $t->set(evens => $t->get('evens')->add(8));
    is($t->persistent->get('evens')->count, 4, 'a transient holds nested containers like any other value');
    is($index->get('evens')->count, 3, 'without changing the one it was opened from');
}

# ---- mixed: plain structures holding containers, and the reverse ------------------------------------------
{
    my $v = HAMT::Vector->new(1, 2, 3);
    my $m = HAMT::Map->new(plain => { vec => $v, list => [ $v, $v ] });
    is(refaddr($m->get('plain')->{vec}), refaddr($v), 'a vector inside a hash inside a map');
    is($m->get('plain')->{list}[1]->get(2), 3, 'read through all three');
    my $h = { map => $m };
    is($h->{map}->get('plain')->{vec}->count, 3, 'and a map inside a plain hash');
}

# ---- lifetime: a nested structure lives exactly as long as a version holds it ------------------------------
{
    my $before = alive();
    {
        my $m;
        {
            my $tree = { leaf => Local::Counted->new, list => [ Local::Counted->new, { deep => Local::Counted->new } ] };
            $m = HAMT::Map->new(tree => $tree);
        }
        is(alive() - $before, 3, 'a nested structure outlives the variable it was built in, held by the map');
        my $m2 = $m->set(other => 1);
        my $m3 = $m2->set(tree => 'replaced');
        undef $m;
        is(alive() - $before, 3, 'and is kept by any version that still holds it');
        undef $m2;
        is(alive() - $before, 0, 'and freed, to its deepest object, when the last of those goes');
        is($m3->get('tree'), 'replaced', 'leaving the version that replaced it untouched');
    }
    {
        my $v = HAMT::Vector->new(map { [ Local::Counted->new, { o => Local::Counted->new } ] } 1 .. 100);
        is(alive() - $before, 200, 'a vector of 100 nested structures holds 200 objects');
        my $half = $v->slice(0, 50);
        undef $v;
        is(alive() - $before, 100, 'a slice keeps only the structures it took');
        $half = $half->pop for 1 .. 10;
        is(alive() - $before, 80, 'and popping lets them go one at a time');
    }
    is(alive() - $before, 0, 'all gone with the last vector');
    {
        my $inner = HAMT::Vector->new(map { Local::Counted->new } 1 .. 10);
        my $outer = HAMT::Map->new(inner => $inner);
        my $outer2 = $outer->update(inner => sub { $_[0]->pop });
        undef $inner; undef $outer;
        is(alive() - $before, 9, 'a nested container shares its values with the version made from it');
        undef $outer2;
        is(alive() - $before, 0, 'until that goes too');
    }
    {
        # A map that holds a structure that holds the map: a cycle, as it
        # would be with a hash, and broken the same way.
        my $holder = { n => Local::Counted->new };
        my $m = HAMT::Map->new(holder => $holder);
        $holder->{map} = $m;
        undef $m;
        is(alive() - $before, 1, 'a structure that holds the map holding it keeps both alive');
        delete $holder->{map};
        undef $holder;
        is(alive() - $before, 0, 'until the loop is cut');

        my $weak = { n => Local::Counted->new };
        my $w = HAMT::Map->new(holder => $weak);
        $weak->{map} = $w;
        weaken($weak->{map});
        undef $w; undef $weak;
        is(alive() - $before, 0, 'or made with a weak reference in the first place');
    }
}

is(HAMT::_live_blocks(), $blocks, 'and after all of it the library holds what it held at the start');

done_testing;
