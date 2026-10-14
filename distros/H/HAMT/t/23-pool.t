#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use HAMT::Map;
use HAMT::Set;
use HAMT::Vector;

# Freed nodes and entries are kept for reuse, a bounded number of each size.
# What matters is that nothing can tell: a reused block must hold exactly
# what a new one would, the count of live blocks must come back to where it
# was, and what is kept must stay bounded however much is freed.

plan skip_all => 'this build has no pool' if HAMT::_pool_held() == -1;

# Twenty sizes, 128 of each at most.
my $most = 20 * 128;

my $base = HAMT::_live_blocks();
my $held0 = HAMT::_pool_held();
cmp_ok($held0, '>=', 0, 'the pool is open');
cmp_ok($held0, '<=', $most, 'and within its bound at the start');

{
    my $m = HAMT::Map->new(map { ("k$_" => $_) } 1 .. 5000);
    cmp_ok(HAMT::_live_blocks() - $base, '>', 5000, 'a map of 5,000 is live blocks, not held ones');
}
is(HAMT::_live_blocks(), $base, 'freed, none of it is live');
my $held = HAMT::_pool_held();
cmp_ok($held, '>', 0, 'and some of it is held');
cmp_ok($held, '<=', $most, 'but no more than the bound, though thousands were freed');

{
    my $m = HAMT::Map->new(map { ("k$_" => $_) } 1 .. 200);
    cmp_ok(HAMT::_pool_held(), '<', $held, 'building again takes blocks from what is held');
    is($m->count, 200, 'the map built from them has its keys');
    is(join(',', map { $m->get("k$_") } 1 .. 200), join(',', 1 .. 200), 'and every value');
    is($m->_check, 0, 'and is well formed');
}
is(HAMT::_live_blocks(), $base, 'and frees back to where it began');

# Churn: every update frees about what it allocates. The model is a hash.
{
    srand(11);
    my $m = HAMT::Map->new;
    my %h;
    my $bad = 0;
    my $peak = 0;
    for my $step (1 .. 20_000) {
        my $k = 'key' . int rand 400;
        if (rand() < 0.6) { my $val = "v$step"; $m = $m->set($k => $val); $h{$k} = $val }
        else              { $m = $m->delete($k); delete $h{$k} }
        my $now = HAMT::_pool_held();
        $peak = $now if $now > $peak;
        next if $step % 500;
        $bad++ if $m->count != keys %h || $m->_check;
        for my $key (keys %h) { $bad++ if ($m->get($key) // '') ne $h{$key} }
    }
    is($bad, 0, '20,000 updates through reused blocks agree with a hash throughout');
    cmp_ok($peak, '<=', $most, 'and what is held never passed the bound');
}
is(HAMT::_live_blocks(), $base, 'nothing is live after it');

# Every size a node or an entry comes in, each freed and reused.
{
    my $bad = 0;
    for my $round (1 .. 3) {
        for my $len (0, 1, 7, 8, 9, 15, 16, 17, 31, 47, 63, 100, 200, 260, 280, 300, 320, 1000, 5000) {
            my $key = 'x' x $len;
            my $m = HAMT::Map->new($key => $len, "$key!" => -$len);
            $bad++ unless $m->get($key) == $len && $m->get("$key!") == -$len && $m->count == 2;
            my $s = HAMT::Set->new($key);
            $bad++ unless $s->has($key) && !$s->has("$key?");
        }
        for my $n (1 .. 40) {
            my $m = HAMT::Map->new(map { ("n$_" => $_) } 1 .. $n);
            $bad++ unless $m->count == $n && $m->get("n$n") == $n && !$m->_check;
        }
    }
    is($bad, 0, 'keys from empty to 5,000 bytes and maps of 1 to 40, three times over');
    is(HAMT::_live_blocks(), $base, 'and nothing is live after them');
}

# A vector's nodes are the largest pooled size.
{
    srand(12);
    my $v = HAMT::Vector->new;
    my @a;
    my $bad = 0;
    for my $step (1 .. 6000) {
        my $r = rand();
        if    ($r < 0.5 || !@a) { $v = $v->push($step); push @a, $step }
        elsif ($r < 0.7)        { $v = $v->pop; pop @a }
        elsif ($r < 0.9)        { my $i = int rand @a; $v = $v->set($i, -$step); $a[$i] = -$step }
        else                    { my $i = int rand @a; $v = $v->insert($i, $step); splice @a, $i, 0, $step }
        next if $step % 300;
        $bad++ if $v->count != @a || $v->_check || join(',', $v->list) ne join(',', @a);
    }
    is($bad, 0, '6,000 vector edits through reused blocks agree with an array');
    undef $v;
    is(HAMT::_live_blocks(), $base, 'and nothing is live after them');
    cmp_ok(HAMT::_pool_held(), '<=', $most, 'with the pool inside its bound');
}

# A second interpreter does not use the first one's pool.
SKIP: {
    skip 'this perl has no ithreads', 5 unless $Config{useithreads};
    skip 'threads.pm does not load', 5 unless eval { require threads; 1 };
    my $keep = HAMT::Map->new(a => 1, b => 2);
    my $before = HAMT::_pool_held();
    my $live = HAMT::_live_blocks();
    my ($count, $sum) = threads->create({ context => 'list' }, sub {
        my $total = 0;
        for my $round (1 .. 20) {
            my $m = HAMT::Map->new(map { ("t$_" => $_) } 1 .. 300);
            $m = $m->set("t$_" => $_ * 2) for 1 .. 50;
            $total += $m->get('t7');
        }
        my $m = HAMT::Map->new(x => 1, y => 2, z => 3);
        return ($m->count, $total);
    })->join;
    is($count, 3, 'a thread builds maps of its own');
    is($sum, 280, 'and reads them');
    is(HAMT::_pool_held(), $before, 'without taking from or adding to the first interpreter\'s pool');
    is(HAMT::_live_blocks(), $live, 'and leaves nothing live behind it');
    is($keep->get('b'), 2, 'the first interpreter\'s map is as it was');
}

done_testing;
