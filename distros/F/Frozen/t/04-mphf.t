#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Frozen ();
use Time::HiRes ();

# Construction: every size that exercises a different path, the small-n short
# circuit, and determinism across insertion order.

# ---- sizes ----------------------------------------------------------------
#
# 0, 1 and 2 are the degenerate cases; 7 and 8 straddle FZ_MPHF_MIN, which is
# the boundary the short circuit turns on.

for my $n (0, 1, 2, 7, 8, 9, 100, 1000) {
    my %h = map { ("key$_" => "value$_") } 1 .. $n;
    my $b = eval { Frozen->freeze(\%h) };
    ok(defined $b, "n=$n freezes") or do { diag $@; next };
    cmp_ok(Frozen->_walk_ok($b), '>', 0, "n=$n walks clean");

    # every key finds its own value
    my $bad = 0;
    for my $k (keys %h) {
        my $slot = Frozen->_find($b, $k);
        $bad++ unless defined $slot;
    }
    is($bad, 0, "n=$n: every key is found");
}

# ---- the short circuit fired, rather than being assumed to --------------

{
    my %small = map { ("k$_" => $_) } 1 .. 7;
    my %big   = map { ("k$_" => $_) } 1 .. 64;
    is(Frozen->_has_mphf(Frozen->freeze(\%small)), 0,
       'below FZ_MPHF_MIN there is no perfect hash at all');
    is(Frozen->_has_mphf(Frozen->freeze(\%big)), 1,
       'above it there is one');
}

# ---- insertion order does not reach the block --------------------------
#
# The MPHF is fed keys in the sorted order the previous phase emits, so two
# hashes with the same pairs built in different orders must be byte-identical.
# If construction ever depended on insertion order this is what would catch
# it, and it would catch it as a difference rather than as a wrong answer.

{
    my @pairs = map { ["key$_", "value$_"] } 1 .. 200;
    my %a; $a{$_->[0]} = $_->[1] for @pairs;
    my %b; $b{$_->[0]} = $_->[1] for reverse @pairs;
    is(Frozen->freeze(\%a), Frozen->freeze(\%b),
       'the same pairs in two insertion orders freeze to identical bytes');
}

# ---- duplicate keys ------------------------------------------------------
#
# Impossible from an HV, so this asserts the check exists rather than that it
# fires in normal use. A flat index built over dotted paths has no such
# guarantee, and a duplicate there would silently lose one of the two.

{
    my $b = eval { Frozen->freeze({ 'a.b' => 1, a => { b => 2 } }) };
    ok(defined $b, 'a literal dot and a nesting are distinct in the tree')
        or diag $@;
}

# ---- a big build, inside a budget ---------------------------------------
#
# The bound that matters is not speed, it is termination: the displacement
# search restarts the whole build on exhaustion, and an unbounded version
# hangs at boot in a production prefork parent. A wall-clock ceiling is a
# crude proxy for "it terminated", but a hang is what it is there to catch.

SKIP: {
    skip 'set FROZEN_BIG_TESTS=1 for the 100k build', 3
        unless $ENV{FROZEN_BIG_TESTS};
    my $n = 100_000;
    my %h = map { ("key$_" => $_) } 1 .. $n;
    my $t0 = Time::HiRes::time();
    my $b  = Frozen->freeze(\%h);
    my $dt = Time::HiRes::time() - $t0;
    ok(defined $b, "$n keys build");
    diag(sprintf "  %d keys in %.2fs, %d bytes", $n, $dt, length $b);
    cmp_ok($dt, '<', 120, 'and inside a two-minute ceiling');
    my $bad = 0;
    for my $k (keys %h) { $bad++ unless defined Frozen->_find($b, $k) }
    is($bad, 0, "all $n keys are found");
}

done_testing;
