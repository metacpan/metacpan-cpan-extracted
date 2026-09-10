#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Frozen ();
use Time::HiRes ();

# Lookup, and the one property an MPHF does not have on its own.

# ---- THE FALSE-POSITIVE GATE ---------------------------------------------
#
# A minimal perfect hash answers "if this key is present it is at slot N". For
# a key that was never in the set it answers some slot anyway, confidently.
# The memcmp against the key stored at that slot is what turns a confident
# guess into a correct answer, and it is the single thing most likely to be
# left out - because leaving it out passes every test that only looks up keys
# that exist.
#
# So: a large table, and a large number of probes for keys that are not in it.
# Every one must come back absent.

{
    my $n = 20_000;
    my %h = map { ("present$_" => $_) } 1 .. $n;
    my $b = Frozen->freeze(\%h);
    ok(Frozen->_has_mphf($b), 'the table has a perfect hash');

    my $found = 0;
    for my $k (keys %h) { $found++ if defined Frozen->_find($b, $k) }
    is($found, $n, 'every present key is found');

    my $probes = $ENV{FROZEN_BIG_TESTS} ? 2_000_000 : 200_000;
    my $false  = 0;
    for my $i (1 .. $probes) {
        $false++ if defined Frozen->_find($b, "absent$i");
    }
    is($false, 0,
       "$probes probes for absent keys produce not one false hit - the "
     . "memcmp confirm is doing its job");
}

# ---- the confirm has teeth even without an MPHF --------------------------
#
# Small nodes take the linear path, which also confirms. Both doors, one
# contract - and a test that only exercised the big path would miss a linear
# scan that returned the first key it looked at.

{
    my %h = map { ("k$_" => $_) } 1 .. 4;
    my $b = Frozen->freeze(\%h);
    is(Frozen->_has_mphf($b), 0, 'this one is on the linear path');
    ok(defined Frozen->_find($b, 'k1'), 'a present key is found');
    ok(!defined Frozen->_find($b, 'nope'), 'an absent key is absent');
    ok(!defined Frozen->_find($b, ''), 'the empty key is absent');
}

# ---- keys that break naive comparisons -----------------------------------

{
    my %h = (
        'a'            => 1,
        'ab'           => 2,
        'abc'          => 3,          # prefixes of one another
        "with\0nul"    => 4,          # a NUL inside the key
        ''             => 5,          # the empty key, as a real key
        'x' x 65536    => 6,          # a 64 KiB key
        'differ_a'     => 7,
        'differ_b'     => 8,          # differing only in the last byte
    );
    my $b = Frozen->freeze(\%h);
    cmp_ok(Frozen->_walk_ok($b), '>', 0, 'the awkward-key block walks clean');

    for my $k (sort keys %h) {
        my $label = length($k) > 20 ? sprintf('a %d-byte key', length $k)
                  : $k eq ''        ? 'the empty key'
                  : $k =~ /\0/      ? 'a key containing NUL'
                  :                   "'$k'";
        ok(defined Frozen->_find($b, $k), "$label is found");
    }

    # A prefix must not resolve to the key it is a prefix OF.
    ok(!defined Frozen->_find($b, 'abcd'), "'abcd' is absent, not 'abc'");
    ok(!defined Frozen->_find($b, 'with'), "'with' is absent, not the NUL key");
}

# ---- the O(1) claim ------------------------------------------------------
#
# If lookup cost grew with n the perfect hash would not have been worth
# writing. Measured as a ratio rather than an absolute, because an absolute
# would be a timing assertion on a shared machine and those do not hold.

SKIP: {
    skip 'set FROZEN_BIG_TESTS=1 for the O(1) measurement', 1
        unless $ENV{FROZEN_BIG_TESTS};

    my %small = map { ("key$_" => $_) } 1 .. 1_000;
    my %large = map { ("key$_" => $_) } 1 .. 100_000;
    my $bs = Frozen->freeze(\%small);
    my $bl = Frozen->freeze(\%large);

    my $reps = 200_000;
    my $t0 = Time::HiRes::time();
    Frozen->_find($bs, "key" . (($_ % 1000) + 1)) for 1 .. $reps;
    my $ts = Time::HiRes::time() - $t0;

    $t0 = Time::HiRes::time();
    Frozen->_find($bl, "key" . (($_ % 100000) + 1)) for 1 .. $reps;
    my $tl = Time::HiRes::time() - $t0;

    diag(sprintf "  1k: %.3fs  100k: %.3fs  ratio %.2f", $ts, $tl, $tl / $ts);
    cmp_ok($tl / $ts, '<', 3.0,
           'a hundredfold more keys costs under 3x per lookup, so it is not '
         . 'scanning');
}

done_testing;
