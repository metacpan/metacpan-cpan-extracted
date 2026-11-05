#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use HAMT::Map;
use HAMT::Set;
use HAMT::Vector;

# No memory. The library's promise is that an allocation that fails leaves
# every container holding exactly what it held, with nothing leaked and the
# method dying with "out of memory". HAMT::_alloc_fail_in makes the n-th
# allocation from now fail. Each operation here runs with n from one upward
# until it succeeds, so every allocation it makes has failed once; after
# each failure the inputs are checked and the block count compared.

END { HAMT::_alloc_fail_in(0); HAMT::_hash_bits(64) }

# The same layout every run, so what this file reaches is the same every run.
HAMT::_seed(20261104);

my $limit = 50000;

sub starve {
    my ($name, $run, $intact) = @_;
    my $live = HAMT::_live_blocks();
    my $n = 0;
    while (++$n <= $limit) {
        HAMT::_alloc_fail_in($n);
        my $ok = eval { my @r = $run->(); 1 };
        my $err = $@;
        HAMT::_alloc_fail_in(0);
        if ($ok) {
            pass("$name: " . ($n - 1) . " allocations, each failing once and handled");
            return;
        }
        if ($err !~ /out of memory/) {
            fail("$name: allocation $n failing died with: $err");
            return;
        }
        my $now = HAMT::_live_blocks();
        if ($now != $live) {
            fail("$name: allocation $n failing leaked " . ($now - $live) . " blocks");
            return;
        }
        if ($intact && !$intact->()) {
            fail("$name: allocation $n failing changed an input");
            return;
        }
    }
    fail("$name: still failing after $limit allocations");
}

# ---- maps ---------------------------------------------------------------------
{
    my @pairs = map { ("k$_" => $_) } 1 .. 300;
    my %h = @pairs;
    my $m = HAMT::Map->new(@pairs);
    my $o = HAMT::Map->new((map { ("o$_" => $_) } 1 .. 300), k5 => 'five', k7 => 7);
    my $intact = sub { $m->count == 300 && $m->_check == 0 && $o->count == 302 && $o->_check == 0 };

    starve('Map->new from a list', sub { HAMT::Map->new(@pairs) });
    starve('Map->from_hash', sub { HAMT::Map->from_hash(\%h) });
    starve('Map set of a new key', sub { $m->set(zz => 1) }, $intact);
    starve('Map set of a present key', sub { $m->set(k1 => 'one') }, $intact);
    starve('Map set of many keys', sub { $m->set(map { ("n$_" => $_) } 1 .. 200) }, $intact);
    starve('Map delete', sub { $m->delete('k1') }, $intact);
    starve('Map delete of many', sub { $m->delete(map { "k$_" } 1 .. 200) }, $intact);
    starve('Map delete of an absent key', sub { $m->delete('zz') }, $intact);
    starve('the persistent put of a new key', sub { HAMT::_put_persistent($m, 'zz', 1) }, $intact);
    starve('the persistent put over a present key', sub { HAMT::_put_persistent($m, 'k1', 'one') }, $intact);
    starve('the persistent put into an empty trie', sub { HAMT::_put_persistent(HAMT::Map->new, 'zz', 1) }, $intact);
    my $del = sub { HAMT::_del_persistent(@_) == -1 and die "out of memory\n" };
    starve('the persistent delete below the root', sub { $del->($m, 'k1') }, $intact);
    starve('the persistent delete of a lone key', sub { $del->(HAMT::Map->new(k1 => 1), 'k1') }, $intact);
    starve('the persistent delete that folds a child up', sub { $del->(HAMT::Map->new(map { ("f$_" => $_) } 1 .. 40), 'f1') }, $intact);
    my $lone = HAMT::Map->new(k1 => 1);
    starve('Map merge of a lone key into a subtree holding it', sub { $lone->merge($o->set(k1 => 'one')) }, $intact);
    starve('Map merge of a lone key into a subtree holding it, with a resolver', sub { $lone->merge($o->set(k1 => 'one'), sub { "$_[1]$_[2]" }) }, $intact);
    starve('Map merge of a subtree into a lone key, with a resolver', sub { $o->set(k1 => 'one')->merge($lone, sub { "$_[1]$_[2]" }) }, $intact);
    starve('Map update', sub { $m->update(k1 => sub { 'new' }) }, $intact);
    starve('Map update of a new key', sub { $m->update(zz => sub { 'new' }) }, $intact);
    starve('Map merge', sub { $m->merge($o) }, $intact);
    starve('Map merge with a resolver', sub { $m->merge($o, sub { "$_[1]$_[2]" }) }, $intact);
    starve('Map diff', sub { $m->diff($o, sub { }) }, $intact);
    starve('Map each', sub { $m->each(sub { }) }, $intact);
    starve('Map equals', sub { $m->equals($o) }, $intact);
    starve('Map equals with a sub', sub { $m->equals($m->set(k1 => 1), sub { 1 }) }, $intact);
    starve('Map key_set', sub { $m->key_set }, $intact);
    starve('Map keys, values, pairs and to_hash', sub { my @k = $m->keys; my @v = $m->values; my @p = $m->pairs; $m->to_hash }, $intact);
    starve('Map transient', sub {
        my $t = $m->transient;
        $t->set(zz => 1);
        $t->set("k$_" => $_) for 1 .. 100;
        $t->set("n$_" => $_) for 1 .. 100;
        $t->delete("k$_") for 1 .. 50;
        $t->delete('absent');
        $t->persistent;
    }, $intact);
}

# ---- sets ---------------------------------------------------------------------
{
    my $s = HAMT::Set->new(map { "m$_" } 1 .. 300);
    my $o = HAMT::Set->new((map { "o$_" } 1 .. 300), 'm5', 'm7');
    my $sub = HAMT::Set->new(map { "m$_" } 1 .. 20);
    my $intact = sub { $s->count == 300 && $s->_check == 0 && $o->count == 302 && $o->_check == 0 };

    starve('Set->new', sub { HAMT::Set->new(map { "m$_" } 1 .. 300) });
    starve('Set add', sub { $s->add('zz') }, $intact);
    starve('Set add of many', sub { $s->add(map { "n$_" } 1 .. 200) }, $intact);
    starve('Set remove', sub { $s->remove('m1') }, $intact);
    starve('Set remove of many', sub { $s->remove(map { "m$_" } 1 .. 200) }, $intact);
    starve('Set union', sub { $s->union($o) }, $intact);
    starve('Set intersect', sub { $s->intersect($o) }, $intact);
    starve('Set intersect with a small set', sub { $s->intersect($sub) }, $intact);
    starve('Set difference', sub { $s->difference($o) }, $intact);
    starve('Set difference of a small set', sub { $s->difference($sub) }, $intact);
    starve('Set equals, is_subset and is_disjoint', sub { $s->equals($o); $sub->is_subset($s); $s->is_disjoint($o) }, $intact);
    starve('Set each and members', sub { $s->each(sub { }); my @m = $s->members }, $intact);
    starve('Set transient', sub {
        my $t = $s->transient;
        $t->add("n$_") for 1 .. 100;
        $t->remove("m$_") for 1 .. 50;
        $t->remove('absent');
        $t->persistent;
    }, $intact);
}

# ---- maps and sets whose keys all collide -------------------------------------
{
    HAMT::_hash_bits(0);
    my $m = HAMT::Map->new(map { ("c$_" => $_) } 1 .. 12);
    my $o = HAMT::Map->new(map { ("d$_" => $_) } 1 .. 12);
    my $s = HAMT::Set->new(map { "c$_" } 1 .. 12);
    my $t = HAMT::Set->new((map { "d$_" } 1 .. 12), 'c1', 'c2');
    my $intact = sub { $m->count == 12 && $m->_check == 0 && $s->count == 12 && $s->_check == 0 };

    starve('Map->new with every key colliding', sub { HAMT::Map->new(map { ("c$_" => $_) } 1 .. 12) });
    starve('Map set into a collision node', sub { $m->set(zz => 1) }, $intact);
    starve('Map delete from a collision node', sub { $m->delete('c1') }, $intact);
    starve('Map merge of collision nodes', sub { $m->merge($o) }, $intact);
    my $o2 = HAMT::Map->new((map { ("c$_" => "o$_") } 1 .. 6), (map { ("d$_" => $_) } 1 .. 6));
    starve('Map merge of collision nodes sharing keys', sub { $m->merge($o2) }, $intact);
    starve('Map merge of collision nodes with a resolver', sub { $m->merge($o2, sub { "$_[1]$_[2]" }) }, $intact);
    starve('Map update in a collision node', sub { $m->update(c1 => sub { 'x' }) }, $intact);
    starve('Set intersect of collision nodes', sub { $s->intersect($t) }, $intact);
    starve('Set difference of collision nodes', sub { $s->difference($t) }, $intact);
    starve('Set union of collision nodes', sub { $s->union($t) }, $intact);
    starve('Map transient on collision nodes', sub {
        my $x = $m->transient;
        $x->set("e$_" => $_) for 1 .. 5;
        $x->delete("c$_") for 1 .. 5;
        $x->persistent;
    }, $intact);
    undef $_ for $m, $o, $o2, $s, $t;
    HAMT::_hash_bits(64);
}

# ---- maps whose keys collide after two levels: chains of nodes ------------------
{
    HAMT::_hash_bits(10);
    my $p = HAMT::Map->new(map { ("p$_" => $_) } 1 .. 200);
    my $q = HAMT::Map->new((map { ("q$_" => $_) } 1 .. 200), p5 => 'five');
    my $intact = sub { $p->count == 200 && $p->_check == 0 && $q->count == 201 && $q->_check == 0 };
    starve('Map merge down chains of nodes', sub { $p->merge($q) }, $intact);
    starve('Map merge down chains with a resolver', sub { $p->merge($q, sub { "$_[1]$_[2]" }) }, $intact);
    starve('Map set down a chain', sub { $p->set(zz => 1) }, $intact);
    starve('Map delete down a chain', sub { $p->delete('p1') }, $intact);
    undef $_ for $p, $q;
    HAMT::_hash_bits(64);
}

# ---- vectors ------------------------------------------------------------------
{
    my $v = HAMT::Vector->new(1 .. 1100);
    my $w = HAMT::Vector->new(1 .. 700);
    my $r = $v->concat($w)->slice(3, 1500)->remove(400, 70)->insert(900, 1 .. 40);
    my $rcount = $r->count;
    my $intact = sub { $v->count == 1100 && $v->_check == 0 && $w->count == 700 && $r->count == $rcount && $r->_check == 0 };

    starve('Vector->new', sub { HAMT::Vector->new(1 .. 1100) });
    starve('Vector push', sub { $v->push(1) }, $intact);
    starve('Vector push of many', sub { $v->push(1 .. 100) }, $intact);
    starve('Vector pop', sub { $v->pop }, $intact);
    starve('Vector set near the start', sub { $v->set(0, 'x') }, $intact);
    starve('Vector set near the end', sub { $v->set(1099, 'x') }, $intact);
    starve('Vector concat', sub { $v->concat($w) }, $intact);
    starve('Vector slice', sub { $v->slice(100, 500) }, $intact);
    starve('Vector slice into the tail', sub { $v->slice(1090, 5) }, $intact);
    starve('Vector slice at a leaf boundary', sub { $v->slice(0, 1024) }, $intact);
    starve('Vector slice of the first leaf', sub { $v->slice(0, 32) }, $intact);
    starve('Vector insert', sub { $v->insert(500, 1 .. 40) }, $intact);
    starve('Vector remove', sub { $v->remove(500, 40) }, $intact);
    starve('Vector equals', sub { $v->equals($v->set(0, 1)) }, $intact);
    starve('Vector each, list and to_array', sub { $v->each(sub { }); my @l = $v->list; $v->to_array }, $intact);
    starve('relaxed vector push', sub { $r->push(1 .. 40) }, $intact);
    starve('relaxed vector pop', sub { $r->pop }, $intact);
    starve('relaxed vector set', sub { $r->set(700, 'x') }, $intact);
    starve('relaxed vector concat', sub { $r->concat($r) }, $intact);
    starve('relaxed vector slice', sub { $r->slice(10, 1000) }, $intact);
    starve('relaxed vector remove', sub { $r->remove(10, 1000) }, $intact);
    starve('relaxed vector insert', sub { $r->insert(10, 1 .. 100) }, $intact);

    my $tall = $r->concat($r)->concat($r)->remove(5, 3);
    my $tcount = $tall->count;
    my $tall_intact = sub { $tall->count == $tcount && $tall->_check == 0 && $r->count == $rcount };
    starve('tall relaxed vector concat', sub { $tall->concat($r) }, $tall_intact);
    starve('tall relaxed vector slice', sub { $tall->slice(7, 4000) }, $tall_intact);
    starve('tall relaxed vector insert', sub { $tall->insert(2000, 1 .. 40) }, $tall_intact);
    starve('tall relaxed vector remove', sub { $tall->remove(2000, 300) }, $tall_intact);
    starve('tall relaxed vector push', sub { $tall->push(1 .. 70) }, $tall_intact);

    my $choppy = HAMT::Vector->new(1 .. 17);
    $choppy = $choppy->concat(HAMT::Vector->new(1 .. 17)) for 1 .. 60;
    my $ccount = $choppy->count;
    my $choppy_intact = sub { $choppy->count == $ccount && $choppy->_check == 0 };
    starve('choppy vector slice', sub { $choppy->slice(20, 900) }, $choppy_intact);
    starve('choppy vector remove', sub { $choppy->remove(300, 400) }, $choppy_intact);
    starve('choppy vector insert', sub { $choppy->insert(500, 1 .. 20) }, $choppy_intact);
    starve('choppy vector concat', sub { $choppy->concat($choppy) }, $choppy_intact);
    starve('choppy vector push', sub { $choppy->push(1 .. 50) }, $choppy_intact);
    starve('choppy vector pop', sub { $choppy->pop }, $choppy_intact);
    starve('choppy vector set', sub { $choppy->set(600, 'x') }, $choppy_intact);

    my $loose = HAMT::Vector->new(1 .. 8);
    $loose = $loose->concat(HAMT::Vector->new(1 .. 40)) for 1 .. 3;
    starve('loose vector slice that repacks the cut', sub { $loose->slice(0, 90) }, sub { $loose->count == 128 && $loose->_check == 0 });
    starve('loose vector remove that repacks the cut', sub { $loose->remove(90, 30) }, sub { $loose->count == 128 && $loose->_check == 0 });

    my $deep = HAMT::Vector->new(1 .. 32800);
    starve('Vector push that needs a new root and a path', sub { $deep->push(1) }, sub { $deep->count == 32800 });
    my $thin = HAMT::Vector->new(1 .. 1057);
    starve('Vector pop that pulls a leaf out of the tree', sub { $thin->pop }, sub { $thin->count == 1057 && $thin->_check == 0 });
    starve('Vector transient', sub {
        my $t = $v->transient;
        $t->push($_) for 1 .. 100;
        $t->set(5, 'x');
        $t->pop for 1 .. 50;
        $t->persistent;
    }, $intact);
    starve('Vector transient emptied', sub {
        my $t = HAMT::Vector->new(1 .. 40)->transient;
        $t->pop for 1 .. 40;
        $t->push(1);
        $t->persistent;
    }, $intact);
}

# ---- every step of a random edit sequence ---------------------------------------
#
# The shapes a tree gets into after thousands of pushes, pops, sets and
# inserts are the ones the push and the join take their rarest paths on, so
# a sequence like the pool test's is replayed here with every step starved.
# The numbers come from a generator of this file's own, since perl's rand
# differs from one platform to the next and the shapes with it.
{
    my $state = 2;
    my $rnd = sub { $state = ($state * 1103515245 + 12345) % 2147483648; return ($state >> 8) % $_[0] };
    my $v = HAMT::Vector->new;
    my @a;
    my ($steps, $failures, $wrong) = (3000, 0, '');
    STEP: for my $step (1 .. $steps) {
        my $r = $rnd->(100);
        my ($op, $then);
        if ($r < 50 || !@a) { $op = sub { $v->push($step) }; $then = sub { push @a, $step } }
        elsif ($r < 70)     { $op = sub { $v->pop };         $then = sub { pop @a } }
        elsif ($r < 90)     { my $i = $rnd->(scalar @a); $op = sub { $v->set($i, -$step) };    $then = sub { $a[$i] = -$step } }
        else                { my $i = $rnd->(scalar @a); $op = sub { $v->insert($i, $step) }; $then = sub { splice @a, $i, 0, $step } }
        my $count = $v->count;
        my $live  = HAMT::_live_blocks();
        my $n = 0;
        while (++$n <= $limit) {
            HAMT::_alloc_fail_in($n);
            my $next = eval { $op->() };
            my $err  = $@;
            HAMT::_alloc_fail_in(0);
            if (defined $next) { $v = $next; $then->(); last }
            $failures++;
            if ($err !~ /out of memory/ || HAMT::_live_blocks() != $live || $v->count != $count) {
                $wrong = "step $step, allocation $n: $err";
                last STEP;
            }
        }
        next if $step % 250;
        if ($v->count != @a || $v->_check || join(',', $v->list) ne join(',', @a)) {
            $wrong = "step $step: the vector is not the array (rule " . $v->_check . ')';
            last STEP;
        }
    }
    is($wrong, '', "every one of $steps random edits survived each of its allocations failing ($failures failures)");
    is($v->_check, 0, 'and the vector is valid at the end');
}

# ---- the C ABI ------------------------------------------------------------------
#
# The selftest walks the whole table in C. Under a failing allocation it
# stops at the first entry that reports no memory, and its number is
# negative when something was left allocated.
{
    my $live = HAMT::_live_blocks();
    my ($n, $bad, $leaked) = (0, 0, 0);
    my $done;
    while (++$n <= $limit) {
        HAMT::_alloc_fail_in($n);
        my ($step) = HAMT::_abi_selftest();
        HAMT::_alloc_fail_in(0);
        if ($step == 0) { $done = $n - 1; last }
        $bad++ if $step < 0;
        $leaked++ if HAMT::_live_blocks() != $live;
    }
    ok(defined $done, "the ABI selftest succeeds once its allocations have each failed once")
        or diag("still failing after $limit allocations");
    is($bad, 0, "and never left something allocated behind a failure ($done allocations)");
    is($leaked, 0, 'and the library held what it held before each failure');
}

starve('_entry_probe', sub { HAMT::_entry_probe('key', 0, 'value') });

done_testing;
