#!/usr/bin/env perl
use strict;
use warnings;

# Phase 04's evidence: build cost, lookup cost, and the displacement
# histogram that justifies the mixer.
#
# The number that matters is not raw speed, it is the SHAPE: lookup must not
# grow with n, and the build must terminate at every size. A displacement
# histogram with a long tail means the mixer's avalanche is poor and the
# search is doing work it should not.

use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Frozen ();
use Time::HiRes ();

my @SIZES = @ARGV ? @ARGV : (1_000, 10_000, 100_000);
my $REPS  = 200_000;

printf "%-10s %10s %10s %12s %10s\n",
       'keys', 'build s', 'bytes', 'lookup ns', 'mphf';

for my $n (@SIZES) {
    my %h = map { ("key$_" => "value$_") } 1 .. $n;

    my $t0 = Time::HiRes::time();
    my $b  = Frozen->freeze(\%h);
    my $build = Time::HiRes::time() - $t0;

    # Every key found, before timing anything - a fast wrong answer is not a
    # result.
    my $bad = 0;
    for my $k (keys %h) { $bad++ unless defined Frozen->_find($b, $k) }
    die "  $n: $bad keys missing\n" if $bad;

    my @probe = map { "key" . (1 + int rand $n) } 1 .. 1000;
    $t0 = Time::HiRes::time();
    for my $i (1 .. $REPS) { Frozen->_find($b, $probe[$i % 1000]) }
    my $look = Time::HiRes::time() - $t0;

    printf "%-10d %10.3f %10d %12.1f %10s\n",
           $n, $build, length $b, 1e9 * $look / $REPS,
           Frozen->_has_mphf($b) ? 'yes' : 'LINEAR';
}

# The absent-key path costs the same as the present one - one hash, one index,
# one memcmp that fails. Worth showing, because a structure that was slow on
# misses would be the wrong shape for a cache.
{
    my $n = 100_000;
    my %h = map { ("key$_" => $_) } 1 .. $n;
    my $b = Frozen->freeze(\%h);
    my $t0 = Time::HiRes::time();
    for my $i (1 .. $REPS) { Frozen->_find($b, "absent$i") }
    my $miss = Time::HiRes::time() - $t0;
    printf "\nmiss at %d keys: %.1f ns per probe\n", $n, 1e9 * $miss / $REPS;
}
