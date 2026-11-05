#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use HAMT::Map;
use HAMT::Set;
use HAMT::Vector;

# The paths the other tests walk past: deleting what is not there at every
# kind of position, two keys that share a root position, equality against a
# stored undef, a diff stopped deep inside, set algebra over shared
# subtrees, the argument counts, the warning filter with no hook before it,
# and the empty forms of a merge, an intersection and a transient.

END { HAMT::_hash_bits(64) }

# The same layout every run, so what this file reaches is the same every run.
HAMT::_seed(20261104);

# ---- keys by their root position ---------------------------------------------
# The low five bits of a key's hash pick its position at the root, and
# _hash_of gives the hash as sixteen hex digits, lowest last.
sub root_pos { hex(substr(HAMT::_hash_of($_[0]), 14, 2)) & 31 }

my ($k1, $k2, $elsewhere);
{
    my %first;
    for my $i (1 .. 5000) {
        my $k   = "p$i";
        my $pos = root_pos($k);
        if (!defined $first{$pos}) { $first{$pos} = $k; next }
        next if HAMT::_hash_of($first{$pos}) eq HAMT::_hash_of($k);
        ($k1, $k2) = ($first{$pos}, $k);
        last;
    }
    for my $i (1 .. 5000) {
        my $k = "e$i";
        if (root_pos($k) != root_pos($k1)) { $elsewhere = $k; last }
    }
}
ok(defined $k2, "two keys share a root position and differ beyond it ($k1, $k2)");
ok(defined $elsewhere, "and a third sits elsewhere ($elsewhere)");

# ---- delete: absent keys at every kind of position ---------------------------
{
    my $one = HAMT::Map->new($k1 => 1);
    is($one->delete($k2)->count, 1, 'deleting an absent key that shares a position with the only key changes nothing');
    is($one->delete($elsewhere)->count, 1, 'deleting an absent key whose position is empty changes nothing');
    is($one->delete($k1)->count, 0, 'deleting the only key gives an empty map');
    ok(!$one->delete($k1)->exists($k1), 'which has it no more');
    is($one->delete($k1)->_check, 0, 'and is a valid trie');

    my $big  = HAMT::Map->new(map { ("b$_" => $_) } 1 .. 2000);
    my $same = $big;
    $same = $same->delete("absent$_") for 1 .. 200;
    is($same->count, 2000, 'deleting two hundred absent keys below a full root changes nothing');
    ok($same->equals($big), 'and leaves the map equal to what it was');

    # The core's persistent delete, which the methods leave to set
    # subtraction: 1 for a key that was there, 0 for one that was not.
    is(HAMT::_del_persistent($one, $k2), 0, 'the persistent delete finds no key sharing the position');
    is(HAMT::_del_persistent($one, $elsewhere), 0, 'nor one at an empty position');
    is(HAMT::_del_persistent($one, $k1), 1, 'and deletes the only key, leaving an empty trie');
    is(HAMT::_del_persistent($big, 'absent1'), 0, 'nor an absent key below a full root');
    is(HAMT::_del_persistent($big, 'b7'), 1, 'and deletes a key below the root');
    is(HAMT::_del_persistent(HAMT::Map->new, 'x'), 0, 'an empty trie has nothing to delete');

    # And its persistent put: 1 for a new key, 0 for one replaced.
    is(HAMT::_put_persistent(HAMT::Map->new, 'x', 1), 1, 'the persistent put into an empty trie adds');
    is(HAMT::_put_persistent($big, 'new', 1), 1, 'and a new key below a full root adds');
    is(HAMT::_put_persistent($big, 'b7', 'seven'), 0, 'and a present key is replaced');
    is(HAMT::_put_persistent($big, 'b7', $big->get('b7')), 0, 'or kept, when the value is the one there');

    my $two = HAMT::Map->new($k1 => 1, $k2 => 2);
    is(HAMT::_del_persistent($two, $k1), 1, 'deleting one of two keys sharing a position folds the other up');
    is($two->delete($k1)->count, 1, 'as the method does');
    is($two->delete($k1)->_check, 0, 'leaving a valid trie');
    is($two->delete($k1)->get($k2), 2, 'that still holds the other');

    my $set = HAMT::Set->new($k1);
    is($set->remove($k2)->count, 1, 'a set keeps its member when an absent one sharing the position is removed');
    is($set->remove($k1)->count, 0, 'and is empty once its only member goes');

    HAMT::_hash_bits(0);
    my $c = HAMT::Map->new(c1 => 1, c2 => 2, c3 => 3);
    is($c->delete('c9')->count, 3, 'deleting a key absent from a collision node changes nothing');
    is($c->delete('c1')->count, 2, 'and a present one goes');
    is(HAMT::_del_persistent($c, 'c9'), 0, 'the persistent delete finds no absent key in a collision node');
    is(HAMT::_del_persistent($c, 'c1'), 1, 'and deletes a present one');
    my $cs = HAMT::Set->new('c1', 'c2');
    ok($cs->remove('c9')->has('c1'), 'a set of colliding members likewise');
    undef $c;
    undef $cs;
    HAMT::_hash_bits(64);
}

# ---- equality --------------------------------------------------------------------
{
    my $u = HAMT::Map->new(a => undef);
    ok(!$u->equals(HAMT::Map->new(a => 1)), 'a stored undef is not equal to a value');
    ok(!HAMT::Map->new(a => 1)->equals($u), 'in either order');
    ok($u->equals(HAMT::Map->new(a => undef)), 'and is equal to a stored undef');
    ok(!HAMT::Map->new($k1 => 1)->equals(HAMT::Map->new($k2 => 1)), 'two keys at one root position are not one key');
    ok(!HAMT::Set->new($k1)->equals(HAMT::Set->new($k2)), 'in a set too');
    ok(!HAMT::Set->new->equals(HAMT::Set->new('x')), 'an empty set is not equal to one with a member');
    ok(!HAMT::Set->new('x')->equals(HAMT::Set->new), 'in either order');
    ok(HAMT::Set->new->equals(HAMT::Set->new), 'and two empty sets are equal');
    ok(!HAMT::Map->new->equals(HAMT::Map->new(x => 1)), 'an empty map is not equal to one with a key');
    ok(HAMT::Map->new->equals(HAMT::Map->new), 'and two empty maps are equal');
}

# ---- a diff stopped at any call -----------------------------------------------------
{
    no warnings 'exiting';
    my $a     = HAMT::Map->new(map { ("d$_" => $_) } 1 .. 300);
    my $empty = HAMT::Map->new;
    my $b     = $a->set(d7 => 'changed');
    my $three = HAMT::Map->new(d1 => 1, d2 => 2, d3 => 3);
    my $grown = $three->set(map { ("x$_" => $_) } 1 .. 300);
    my @pairs = ([$a, $empty], [$empty, $a], [$a, $b], [$three, $grown], [$grown, $three],
                 [HAMT::Map->new($k1 => 1), HAMT::Map->new($k2 => 1)]);
    my $bad = 0;
    for my $pair (@pairs) {
        my $total = $pair->[0]->diff($pair->[1], sub { });
        for my $stop (1 .. ($total < 400 ? $total : 40)) {
            my $want  = $stop < $total ? $stop : $total;
            my $calls = 0;
            my $n = $pair->[0]->diff($pair->[1], sub { $calls++; last if $calls == $stop });
            $bad++ unless $calls == $want && $n == $want;
        }
    }
    is($bad, 0, 'a diff stopped at any call, deep in a subtree or at the root, reports that many');

    HAMT::_hash_bits(0);
    my $ca = HAMT::Map->new(c1 => 1, c2 => 2, c3 => 3);
    my $cb = HAMT::Map->new(c1 => 1, c2 => 'changed', c4 => 4);
    $bad = 0;
    for my $pair ([$ca, $cb], [$cb, $ca]) {
        my $total = $pair->[0]->diff($pair->[1], sub { });
        for my $stop (1 .. $total) {
            my $calls = 0;
            my $n = $pair->[0]->diff($pair->[1], sub { $calls++; last if $calls == $stop });
            $bad++ unless $calls == $stop && $n == $stop;
        }
    }
    is($bad, 0, 'a diff of two collision nodes stopped at any call reports that many');
    undef $_ for $ca, $cb;
    HAMT::_hash_bits(64);
}

# ---- set algebra over shared subtrees ---------------------------------------------
{
    my $all = HAMT::Set->new(map { "s$_" } 1 .. 1000);
    my $t = $all->transient;
    $t->remove("s$_") for 1 .. 600;
    my $few = $t->persistent;
    is($few->count, 400, 'a set made from a larger one by removing shares what it did not touch');
    ok($all->intersect($few)->equals($few), 'intersecting with it keeps exactly it');
    is($all->intersect($few)->count, 400, 'with the count');
    is($all->difference($few)->count, 600, 'and subtracting it leaves the rest');
    ok(!$all->difference($few)->has('s700'), 'none of it');
    ok($all->difference($few)->has('s7'), 'all of the rest');
}

# ---- argument counts ------------------------------------------------------------------
{
    my $m = HAMT::Map->new(a => 1);
    my $v = HAMT::Vector->new(1, 2, 3);
    ok(!eval { $m->equals($m, sub { 1 }, 'extra'); 1 } && $@ =~ /equals: too many arguments/, 'Map equals with a fourth argument croaks');
    ok(!eval { $m->merge($m, sub { 1 }, 'extra'); 1 } && $@ =~ /merge: too many arguments/, 'as does merge');
    ok(!eval { $v->equals($v, sub { 1 }, 'extra'); 1 } && $@ =~ /equals: too many arguments/, 'and Vector equals');
    ok(!eval { $v->remove(0, 1, 'extra'); 1 } && $@ =~ /remove: too many arguments/, 'and Vector remove');
}

# ---- empty forms ----------------------------------------------------------------------
{
    my $e = HAMT::Map->new;
    is($e->merge(HAMT::Map->new)->count, 0, 'merging two empty maps gives an empty map');
    is(HAMT::Set->new->intersect(HAMT::Set->new('x'))->count, 0, 'an empty set intersected stays empty');
    is(HAMT::Set->new->difference(HAMT::Set->new('x'))->count, 0, 'and subtracted from stays empty');
    is($e->transient->persistent->count, 0, 'an empty map transient made persistent is an empty map');
    is(HAMT::Set->new->transient->persistent->count, 0, 'and an empty set transient an empty set');

    my $gone  = HAMT::Map->new(a => 1)->delete('a');
    my $sgone = HAMT::Set->new('a')->remove('a');
    is($gone->merge($gone)->count, 0, 'merging a map emptied by delete with itself gives an empty map');
    is($gone->merge($e)->count, 0, 'or with a map born empty');
    is($sgone->intersect(HAMT::Set->new('x'))->count, 0, 'a set emptied by remove intersected stays empty');
    is($sgone->difference(HAMT::Set->new('x'))->count, 0, 'and subtracted from stays empty');
    is($sgone->union($sgone)->count, 0, 'and united with itself stays empty');
    is($gone->transient->persistent->count, 0, 'a transient of a map emptied by delete made persistent is empty');
    is($sgone->transient->persistent->count, 0, 'as is one of a set emptied by remove');
}

# ---- keys and values --------------------------------------------------------------------
{
    my $k = 'plain';
    utf8::upgrade($k);
    my $m = HAMT::Map->new($k => 1);
    ok($m->exists('plain'), 'an ASCII key carrying the UTF-8 flag is the plain key');

    is(HAMT::_vec_height(HAMT::Vector->new), 0, 'an empty vector has no levels of nodes');
    is(HAMT::_vec_height(HAMT::Vector->new(1 .. 32)), 0, 'nor one that is all tail');
    is(HAMT::_vec_height(HAMT::Vector->new(1 .. 40)), 1, 'a vector with a tree has one level over its leaves');
    is(HAMT::_vec_height(HAMT::Vector->new(1 .. 1100)), 2, 'then two');
    is(HAMT::_vec_height(HAMT::Vector->new(1 .. 32900)), 3, 'then three');

    my $t = HAMT::Vector->new(1, 2, 3)->transient;
    $t->set(1, $t->get(1));
    is($t->get(1), 2, 'setting a slot to the scalar it holds changes nothing');
    ok(!eval { HAMT::Vector::Transient::push(42, 1); 1 } && $@ =~ /not a transient/, 'a vector transient method on a plain value croaks');
}

# ---- the warning filter ---------------------------------------------------------------
{
    my $m   = HAMT::Map->new(a => 1);
    my $obj = bless { what => 'warned' }, 'HAMT::Test::Warned';
    my @seen;
    {
        local $SIG{__WARN__} = sub { push @seen, $_[0] };
        $m->each(sub { warn $obj });
    }
    is(scalar @seen, 1, 'an object warned inside a walk reaches the hook that was there before');
    if ($] >= 5.014) {
        is($seen[0], $obj, 'as the object itself');
    }
    else {
        like($seen[0], qr/^\Q$obj\E at /, 'as the object stringified with its place, which is what warn did before 5.14');
    }

    my $captured = '';
    {
        local *STDERR;
        open STDERR, '>', \$captured or die "cannot capture STDERR: $!";
        $m->each(sub { warn "plain text\n"; warn $obj });
    }
    like($captured, qr/^plain text$/m, 'with no hook before it, a warning inside a walk goes to STDERR');
    like($captured, qr/HAMT::Test::Warned=HASH/, 'and an object warned is printed as perl prints it');
}

done_testing;
