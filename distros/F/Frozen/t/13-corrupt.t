#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Frozen ();
use File::Temp ();

# THE FUZZ GATE.
#
# A Frozen block is a build artifact, not a stranger's upload - but the
# realistic failure is a deploy that half-wrote a file, not an attacker. The
# bar is NEVER SEGFAULT: every mangled block must either load and read
# cleanly, or croak naming what is wrong with it.
#
# Every case runs in a CHILD, so a crash is an exit status the parent asserts
# on and the sweep continues, rather than a dead test run that says nothing
# about the cases after it.

plan skip_all => 'fork is POSIX-only here' if $^O eq 'MSWin32';

my $dir = File::Temp::tempdir(CLEANUP => 1);
my %data = (
    greeting => 'hello',
    items    => { one => '1 item', other => 'n items',
                  deep => { down => [1, 2, 3] } },
    list     => ['a', 'b', 'c'],
    n        => 42,
    f        => 1.5,
    u        => undef,
);
# Big enough to have an MPHF and a flat index, so the sweep covers both.
$data{"key$_"} = "value $_" for 1 .. 40;

my $good = Frozen->freeze(\%data, flat => '.');
my $len  = length $good;
diag("block is $len bytes");

# Exercise a block in a child. Returns 'ok', 'croak', or 'CRASH n'.
sub try_block {
    my ($bytes) = @_;
    pipe(my $r, my $w) or die $!;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        close $r;
        my $verdict = eval {
            my $fz = Frozen->attach($bytes);
            my $root = $fz->root;
            # Touch everything a reader would: keys, values, the walk, the
            # flat path, and a full inflate.
            my @k = $fz->keys($root);
            for my $k (@k) { my @v = $fz->fetch($root, $k) }
            $fz->each_leaf(sub { my $l = length($_[0]) });
            my @p = $fz->get('items.one');
            $fz->inflate;
            'ok';
        } || do { my $e = $@; $e =~ /^Frozen:/ ? 'croak' : 'croak-other' };
        print {$w} "$verdict\n";
        close $w;
        exit 0;
    }
    close $w;
    my $said = <$r>;
    close $r;
    waitpid $pid, 0;
    my $rc = $?;
    return "CRASH " . ($rc & 127) if $rc & 127;
    return 'EXIT ' . ($rc >> 8) if ($rc >> 8) != 0;
    chomp($said //= 'no-answer');
    return $said;
}

is(try_block($good), 'ok', 'the intact block reads');

# ---- truncation, at EVERY length -----------------------------------------
#
# Exhaustive, not sampled: total_size against the actual length is the check
# that should catch all of these, and a sample would not prove it.

{
    my (%verdict, @crashes);
    for my $n (0 .. $len - 1) {
        my $v = try_block(substr($good, 0, $n));
        $verdict{$v}++;
        push @crashes, $n if $v =~ /^CRASH/;
    }
    is(scalar @crashes, 0,
       "truncation at all $len lengths: no crashes")
        or diag "crashed at lengths: @crashes[0 .. ($#crashes > 9 ? 9 : $#crashes)]";
    is($verdict{ok} // 0, 0, 'and no truncated block was accepted as intact');
    diag("truncation verdicts: " . join(', ', map { "$_=$verdict{$_}" } sort keys %verdict));
}

# ---- byte flips, from a seeded corpus ------------------------------------
#
# The seed is fixed and printed, so a failing case is reproducible from the
# output rather than from luck.

{
    my $seed = $ENV{FROZEN_FUZZ_SEED} || 20260910;
    diag("byte-flip seed $seed (set FROZEN_FUZZ_SEED to reproduce)");
    srand($seed);
    my $cases = $ENV{FROZEN_BIG_TESTS} ? 3000 : 400;
    my (%verdict, @crashes);
    for my $i (1 .. $cases) {
        my $b   = $good;
        my $at  = int rand $len;
        my $bit = 1 << int rand 8;
        substr($b, $at, 1) = chr(ord(substr($b, $at, 1)) ^ $bit);
        my $v = try_block($b);
        $verdict{$v}++;
        push @crashes, "$at^$bit" if $v =~ /^CRASH/;
    }
    is(scalar @crashes, 0, "$cases byte flips: no crashes")
        or diag "crashed at: @crashes[0 .. ($#crashes > 9 ? 9 : $#crashes)]";
    diag("flip verdicts: " . join(', ', map { "$_=$verdict{$_}" } sort keys %verdict));
}

# ---- the named hazards, each deliberately constructed --------------------

{
    my %hazard = (
        'an offset into the header' => sub {
            my $b = $good;
            substr($b, 24, 4) = pack('V', (8 << 4) | 7);   # root -> offset 8
            $b;
        },
        'a count of 0xFFFFFFFF' => sub {
            my $b = $good;
            my $root = unpack('V', substr($b, 24, 4));
            my $off  = ($root >> 4) << 3;
            substr($b, $off, 4) = pack('V', 0xFFFFFFFF);
            $b;
        },
        'a root pointing at a string' => sub {
            my $b = $good;
            my $root = unpack('V', substr($b, 24, 4));
            substr($b, 24, 4) = pack('V', ($root & ~0xF) | 6);
            $b;
        },
        'a node that points at itself' => sub {
            my $b = $good;
            my $root = unpack('V', substr($b, 24, 4));
            my $off  = ($root >> 4) << 3;
            my $n    = unpack('V', substr($b, $off, 4));
            # first value slot -> the node itself
            substr($b, $off + 8 + $n * 4, 4) = pack('V', $root);
            $b;
        },
        'a string length past the block' => sub {
            my $b = $good;
            my $root = unpack('V', substr($b, 24, 4));
            my $off  = ($root >> 4) << 3;
            my $koff = unpack('V', substr($b, $off + 8, 4));
            substr($b, $koff, 4) = pack('V', 0x7FFFFFF);
            $b;
        },
        'total_size disagreeing with the length' => sub {
            my $b = $good;
            substr($b, 20, 4) = pack('V', $len + 4096);
            $b;
        },
    );

    for my $name (sort keys %hazard) {
        my $v = try_block($hazard{$name}->());
        unlike($v, qr/^CRASH/, "$name does not crash");
        diag("  $name => $v");
    }
}

done_testing;
