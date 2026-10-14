#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use Scalar::Util qw(refaddr blessed);
use HAMT::Set;
use HAMT::Map;

# HAMT::Set, one method at a time, and its transient.

sub sorted { [ sort $_[0]->members ] }

my $empty = HAMT::Set->new;
isa_ok($empty, 'HAMT::Set');
is($empty->count, 0, 'a new set is empty');
is_deeply([ $empty->members ], [], 'with no members');
ok(!$empty->has('a'), 'and has nothing');
is($empty->_check, 0, 'and checks out');

my $s = HAMT::Set->new(qw(a b c));
is($s->count, 3, 'new takes a list');
ok($s->has('a') && $s->has('c'), 'has what was given');
ok(!$s->has('d'), 'and not what was not');
is(HAMT::Set->new(qw(a b a b a))->count, 2, 'a member given twice is one member');

# ---- add and remove ----------------------------------------------------------
my $s2 = $s->add('d', 'e');
isa_ok($s2, 'HAMT::Set');
is_deeply(sorted($s2), [qw(a b c d e)], 'add returns a set with the new members');
is_deeply(sorted($s), [qw(a b c)], 'and the receiver is unchanged');
is(refaddr($s->add('a')), refaddr($s), 'adding a member already there is the receiver');
is(refaddr($s->add), refaddr($s), 'and so is adding nothing');
is($s->add(qw(a z a z))->count, 4, 'adding one new member twice among old ones adds one');

my $s3 = $s2->remove('a', 'e');
is_deeply(sorted($s3), [qw(b c d)], 'remove returns a set without them');
is_deeply(sorted($s2), [qw(a b c d e)], 'and the receiver is unchanged');
is(refaddr($s->remove('zz')), refaddr($s), 'removing something absent is the receiver');
is($s->remove(qw(a b c))->count, 0, 'removing everything leaves an empty set');
is($s->remove(qw(a b c))->add('x')->count, 1, 'that can be added to again');

# ---- members ------------------------------------------------------------------
{
    my @src = map { "m$_" } 1 .. 400;
    my $big = HAMT::Set->new(@src);
    is($big->count, 400, '400 members in');
    is($big->_check, 0, 'checks out');
    is_deeply(sorted($big), [ sort @src ], 'members returns them all');
    is_deeply([ $big->members ], [ $big->members ], 'in the same order each time');
    is(scalar($big->members), 400, 'and their number in scalar context');

    my @seen;
    is(refaddr($big->each(sub { push @seen, $_[0] })), refaddr($big), 'each returns the set');
    is_deeply(\@seen, [ $big->members ], 'and calls the sub with each member, in that order');
    my @mrefs;
    $big->each(sub { push @mrefs, \$_[0] });
    is_deeply([ map { $$_ } @mrefs ], [ $big->members ], 'a sub that keeps a reference to every member keeps the right ones');
    my $n = 0;
    ok(!eval { $big->each(sub { die "stop\n" if ++$n == 7 }); 1 } && $@ eq "stop\n" && $n == 7,
       'a die in the sub stops the walk and passes through');
    my $doomed = HAMT::Set->new(1 .. 50);
    my $calls = 0;
    $doomed->each(sub { undef $doomed; $calls++ });
    is($calls, 50, 'a walk finishes over a set its own sub let go of');
    ok(!eval { $big->each('x'); 1 } && $@ =~ /^HAMT::Set::each: not a code reference/,
       'each refuses something that is not a sub');
}

# ---- members are strings, as a hash key is --------------------------------------
{
    my $ref = [];
    my $e_latin = chr(0xe9);                utf8::downgrade($e_latin);
    my $e_wide  = chr(0xe9);                utf8::upgrade($e_wide);
    my $t = HAMT::Set->new(5, '5', 5.0, '5.0', $ref, '', $e_latin, $e_wide, chr(0x100));
    is($t->count, 6, '5, "5" and 5.0 are one member; the two spellings of e-acute are one');
    ok($t->has(5) && $t->has('5.0') && $t->has(''), 'numbers and the empty string are members');
    ok($t->has("$ref"), 'a reference is a member by its string form');
    ok($t->has($e_latin) && $t->has($e_wide), 'found by either spelling');
    my ($wide) = grep { length == 1 && ord > 255 } $t->members;
    is($wide, chr(0x100), 'a wide character comes back as one character');
    {
        my @w;
        local $SIG{__WARN__} = sub { push @w, @_ };
        my $u = HAMT::Set->new(undef);
        ok($u->has(''), 'undef is the empty string');
        is(scalar @w, 1, 'with one warning');
    }
}

# ---- equals ---------------------------------------------------------------------
{
    my $a = HAMT::Set->new(1 .. 200);
    ok($a->equals(HAMT::Set->new(reverse 1 .. 200)), 'two sets with the same members are equal');
    ok(!$a->equals($a->add(201)), 'one member more is not');
    ok(!$a->equals($a->remove(7)->add(0)), 'nor one swapped for another');
    ok($a->equals($a->add(201)->remove(201)), 'there and back again is');
    ok(!$a->equals(undef) && !$a->equals([1 .. 200]) && !$a->equals('x'), 'something that is not a set is not equal');
    ok(!HAMT::Set->new('k')->equals(HAMT::Map->new(k => undef)), 'and a map is not a set');
    ok(HAMT::Set->new->equals(HAMT::Set->new), 'two empty sets are equal');
}

# ---- a set is not a map, and the reverse ------------------------------------------
{
    my $m = HAMT::Map->new(a => 1);
    ok(!eval { HAMT::Map::get($s, 'a'); 1 } && $@ =~ /^HAMT::Map::get: not a map/, 'a map method refuses a set');
    ok(!eval { HAMT::Set::has($m, 'a'); 1 } && $@ =~ /^HAMT::Set::has: not a set/, 'a set method refuses a map');
    ok(!eval { my $r = $s->union($m); 1 } && $@ =~ /^HAMT::Set::union: not a set/, 'union refuses a map');
    ok(!eval { my $r = $s->intersect([]); 1 } && $@ =~ /^HAMT::Set::intersect: not a set/, 'intersect refuses an array');
    ok(!eval { my $r = $s->difference(undef); 1 } && $@ =~ /^HAMT::Set::difference: not a set/, 'difference refuses undef');
    ok(!eval { $s->is_subset($m); 1 } && $@ =~ /^HAMT::Set::is_subset: not a set/, 'is_subset refuses a map');
    ok(!eval { $s->is_disjoint('x'); 1 } && $@ =~ /^HAMT::Set::is_disjoint: not a set/, 'is_disjoint refuses a string');
    for my $forged (bless({}, 'HAMT::Set'), bless(\(my $n = 12345), 'HAMT::Set'),
                    HAMT::_foreign_handle('HAMT::Set')) {
        ok(!eval { $forged->count; 1 } && $@ =~ /^HAMT::Set::count: not a set/, 'a forged set is refused');
    }
}

# ---- key_set -------------------------------------------------------------------------
{
    my $m = HAMT::Map->new(a => 1, b => undef, chr(0x100) => 3);
    my $k = $m->key_set;
    isa_ok($k, 'HAMT::Set');
    is_deeply(sorted($k), [ sort $m->keys ], 'key_set holds the map\'s keys');
    is($k->_check, 0, 'and checks out');
    ok($k->equals(HAMT::Set->new($m->keys)), 'equal to a set built from them');
    is(HAMT::Map->new->key_set->count, 0, 'an empty map has an empty key set');
    my $big = HAMT::Map->new(map { ("k$_" => $_) } 1 .. 1000);
    is($big->key_set->count, 1000, 'a thousand keys');
    ok($big->key_set->is_subset($big->set(more => 1)->key_set), 'and key sets compare as sets do');
}

# ---- void context -------------------------------------------------------------------
{
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    my $o = HAMT::Set->new('z');
    $s->add('x'); $s->remove('a'); $s->union($o); $s->intersect($o); $s->difference($o);
    is(scalar @w, 5, 'add, remove, union, intersect and difference warn in void context');
    like($w[$_->[0]], qr/^Useless use of HAMT::Set::$_->[1] in void context/, "$_->[1] by name")
        for [0, 'add'], [1, 'remove'], [2, 'union'], [3, 'intersect'], [4, 'difference'];
    is_deeply(sorted($s), [qw(a b c)], 'and did nothing');
    @w = ();
    { no warnings 'void'; $s->add('x'); $s->union($o); }
    $s->has('a'); $s->count; $s->members; $s->is_subset($o); $s->is_disjoint($o); $s->equals($o);
    is(scalar @w, 0, 'no warnings \'void\' silences them, and a question in void context never warned');
}

# ---- subclasses ------------------------------------------------------------------------
{
    package Local::Tags; our @ISA = ('HAMT::Set');
    sub describe { join '+', sort $_[0]->members }
}
{
    my $t = Local::Tags->new(qw(x y));
    isa_ok($t, 'Local::Tags');
    is($t->add('z')->describe, 'x+y+z', 'add returns the subclass');
    isa_ok($t->remove('x'), 'Local::Tags', 'so does remove');
    isa_ok($t->union(HAMT::Set->new('q')), 'Local::Tags', 'union returns the receiver\'s class');
    isa_ok($t->intersect(HAMT::Set->new('x')), 'Local::Tags', 'so does intersect');
    isa_ok($t->difference(HAMT::Set->new('x')), 'Local::Tags', 'and difference');
    isa_ok($t->transient->add('w')->persistent, 'Local::Tags', 'and a transient closes into it');
    is(blessed(HAMT::Set->new('q')->union($t)), 'HAMT::Set', 'the other way round, the receiver\'s again');
    # The empty set's union with a set is that set's own trie, so this is
    # the case where handing back the other object would be easiest.
    my $u = HAMT::Set->new->union($t);
    is(blessed($u), 'HAMT::Set', 'even when the result is exactly the other set, which is of another class');
    ok($u->equals($t), 'holding the same members');
    is(refaddr(Local::Tags->new->union($t)), refaddr($t), 'while between two of one class it is the other object itself');
}

# ---- the transient -----------------------------------------------------------------------
{
    my $base = HAMT::Set->new(1 .. 100);
    my $t = $base->transient;
    isa_ok($t, 'HAMT::Set::Transient');
    is($t->count, 100, 'a transient starts with what the set holds');
    is(refaddr($t->add(101, 102)), refaddr($t), 'add returns the transient');
    is(refaddr($t->remove(1, 2, 3)), refaddr($t), 'remove returns the transient');
    ok($t->has(101) && !$t->has(1), 'and both took effect in it');
    is($t->count, 99, 'with the count following');
    $t->add($_) for 200 .. 1200;
    $t->remove($_) for 200 .. 700;
    is($t->count, 599, 'a thousand adds and five hundred removes');
    is($t->_check, 0, 'and it checks out');
    is($base->count, 100, 'the set it was opened from has seen none of it');
    ok($base->has(1) && !$base->has(101), 'in any member');

    my $p = $t->persistent;
    isa_ok($p, 'HAMT::Set');
    is($p->count, 599, 'persistent returns a set of what it held');
    ok($p->equals(HAMT::Set->new(4 .. 102, 701 .. 1200)), 'the right members');
    is($p->_check, 0, 'that checks out');
    for my $call ([ add => 1 ], [ remove => 1 ], [ has => 1 ], [ 'count' ], [ 'persistent' ]) {
        my ($method, @args) = @$call;
        ok(!eval { my @r = $t->$method(@args); 1 }
           && $@ =~ /^HAMT::Set::Transient::\Q$method\E: this transient is closed/,
           "$method on a closed transient croaks by name");
    }
    my ($x, $y) = ($p->transient, $p->transient);
    $x->add('x'); $y->add('y');
    ok($x->has('x') && !$x->has('y') && $y->has('y') && !$y->has('x') && !$p->has('x') && !$p->has('y'),
       'two transients on one set see neither each other nor the set them');
    ok(!eval { HAMT::Map::Transient::count($x); 1 } && $@ =~ /not a transient/,
       'a set transient is not a map transient');

    my @w;
    local $SIG{__WARN__} = sub { push @w, @_ };
    $x->add('q'); $x->remove('q');
    is(scalar @w, 0, 'add and remove on a transient do not warn in void context');
}

# ---- nothing is leaked ---------------------------------------------------------------------
#
# A set holds no values, so no DESTROY can say a trie was freed. The library
# counts its own blocks instead.
{
    my $before = HAMT::_live_blocks();
    {
        my $a = HAMT::Set->new(1 .. 2000);
        my $b = HAMT::Set->new(1000 .. 3000);
        cmp_ok(HAMT::_live_blocks() - $before, '>', 4000, 'two sets of 2,000 hold some thousands of blocks');
        my @r = ($a->union($b), $a->intersect($b), $a->difference($b), $b->difference($a),
                 $a->add(9999), $a->remove(5), $a->union($a), $a->intersect($a), $a->difference($a));
        my $t = $a->transient;
        $t->add($_) for 5000 .. 6000;
        $t->remove($_) for 1 .. 500;
        push @r, $t->persistent, $a->transient, HAMT::Map->new(map { ($_ => 1) } 1 .. 500)->key_set;
        eval { $a->each(sub { die "stop\n" }) };
        my $n = 0;
        $n += $_->count for @r;
        cmp_ok($n, '>', 10_000, 'a dozen results built from them');
    }
    is(HAMT::_live_blocks(), $before, 'and once they are all gone the library holds what it held before');

    # The count CAN come up short: keep one result and it shows.
    my $kept;
    {
        my $a = HAMT::Set->new(1 .. 100);
        $kept = $a->intersect(HAMT::Set->new(50 .. 150));
    }
    cmp_ok(HAMT::_live_blocks(), '>', $before, 'a result that is kept is still counted');
    undef $kept;
    is(HAMT::_live_blocks(), $before, 'until it goes');
}

# ---- threads --------------------------------------------------------------------------------
SKIP: {
    skip 'this perl has no ithreads', 3 unless $Config{useithreads};
    skip 'threads.pm does not load', 3 unless eval { require threads; 1 };
    is(HAMT::Set->CLONE_SKIP, 1, 'the class asks not to be cloned');
    is(HAMT::Set::Transient->CLONE_SKIP, 1, 'and so does its transient');
    my $shared = HAMT::Set->new(1 .. 50);
    my ($state, $own) = threads->create({ context => 'list' }, sub {
        return ((eval { $shared->count; 1 } ? 'usable' : 'dead'), HAMT::Set->new(1, 2)->add(3)->count);
    })->join;
    is("$state $own", 'dead 3', 'a new thread does not get the parent\'s set, and can make its own');
}

done_testing;
