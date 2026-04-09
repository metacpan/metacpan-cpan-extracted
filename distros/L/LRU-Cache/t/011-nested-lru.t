use strict;
use warnings;
use Test::More tests => 44;
use LRU::Cache 'import';

# ============================================
# Test storing LRU::Cache objects inside LRU::Cache
# ============================================

# --- Basic nesting: inner cache as value ---
{
    my $outer = LRU::Cache::new(10);
    my $inner = LRU::Cache::new(5);

    $inner->set("x", 100);
    $inner->set("y", 200);

    $outer->set("sub_cache", $inner);

    my $got = $outer->get("sub_cache");
    is(ref $got, 'LRU::Cache', 'nested: inner is LRU::Cache');
    is($got->get("x"), 100, 'nested: inner get x');
    is($got->get("y"), 200, 'nested: inner get y');
    is($got->size, 2, 'nested: inner size');
    is($got->capacity, 5, 'nested: inner capacity');
}

# --- Multiple inner caches ---
{
    my $outer = LRU::Cache::new(10);

    for my $i (1..5) {
        my $inner = LRU::Cache::new(3);
        $inner->set("id", $i);
        $inner->set("name", "cache_$i");
        $outer->set("c$i", $inner);
    }

    is($outer->size, 5, 'multi nested: outer has 5 entries');

    for my $i (1..5) {
        my $inner = $outer->get("c$i");
        is(ref $inner, 'LRU::Cache', "multi nested: c$i is LRU::Cache");
        is($inner->get("id"), $i, "multi nested: c$i id");
        is($inner->get("name"), "cache_$i", "multi nested: c$i name");
    }
}

# --- Function-style with nested caches ---
{
    my $outer = LRU::Cache::new(10);
    my $inner = LRU::Cache::new(5);

    lru_set($inner, "a", "alpha");
    lru_set($inner, "b", "beta");

    lru_set($outer, "nested", $inner);

    my $got = lru_get($outer, "nested");
    is(ref $got, 'LRU::Cache', 'func nested: ref type');
    is(lru_get($got, "a"), "alpha", 'func nested: inner get a');
    is(lru_get($got, "b"), "beta", 'func nested: inner get b');
}

# --- Overwrite inner cache with new one ---
{
    my $outer = LRU::Cache::new(5);
    my $inner1 = LRU::Cache::new(3);
    $inner1->set("v", "old");
    $outer->set("slot", $inner1);

    is($outer->get("slot")->get("v"), "old", 'overwrite: initial value');

    my $inner2 = LRU::Cache::new(3);
    $inner2->set("v", "new");
    $outer->set("slot", $inner2);

    is($outer->get("slot")->get("v"), "new", 'overwrite: replaced value');
    is($outer->size, 1, 'overwrite: outer size unchanged');
}

# --- Eviction of inner caches ---
{
    my $outer = LRU::Cache::new(3);

    for my $i (1..5) {
        my $inner = LRU::Cache::new(10);
        $inner->set("val", $i * 10);
        $outer->set("c$i", $inner);
    }

    is($outer->size, 3, 'eviction: outer capped at 3');
    ok(!$outer->exists("c1"), 'eviction: c1 evicted');
    ok(!$outer->exists("c2"), 'eviction: c2 evicted');
    is($outer->get("c3")->get("val"), 30, 'eviction: c3 survived');
    is($outer->get("c4")->get("val"), 40, 'eviction: c4 survived');
    is($outer->get("c5")->get("val"), 50, 'eviction: c5 survived');
}

# --- Delete returns inner cache ---
{
    my $outer = LRU::Cache::new(5);
    my $inner = LRU::Cache::new(5);
    $inner->set("k", "v");
    $outer->set("del_me", $inner);

    my $deleted = $outer->delete("del_me");
    is(ref $deleted, 'LRU::Cache', 'delete nested: returns LRU::Cache');
    is($deleted->get("k"), "v", 'delete nested: inner still works');
    ok(!$outer->exists("del_me"), 'delete nested: removed from outer');
}

# --- Oldest/newest with nested caches ---
{
    my $outer = LRU::Cache::new(5);
    for my $i (1..3) {
        my $inner = LRU::Cache::new(2);
        $inner->set("n", $i);
        $outer->set("oc$i", $inner);
    }

    my ($ok, $ov) = $outer->oldest;
    is($ok, "oc1", 'oldest nested: key');
    is(ref $ov, 'LRU::Cache', 'oldest nested: value is LRU::Cache');
    is($ov->get("n"), 1, 'oldest nested: inner value');

    my ($nk, $nv) = $outer->newest;
    is($nk, "oc3", 'newest nested: key');
    is($nv->get("n"), 3, 'newest nested: inner value');
}

# --- Clear outer with nested caches ---
{
    my $outer = LRU::Cache::new(5);
    my @inners;
    for my $i (1..3) {
        my $inner = LRU::Cache::new(5);
        $inner->set("data", "val_$i");
        push @inners, $inner;
        $outer->set("k$i", $inner);
    }

    $outer->clear;
    is($outer->size, 0, 'clear nested: outer empty');

    # Inner caches should still be accessible through our refs
    is($inners[0]->get("data"), "val_1", 'clear nested: inner 0 alive');
    is($inners[2]->get("data"), "val_3", 'clear nested: inner 2 alive');
}
