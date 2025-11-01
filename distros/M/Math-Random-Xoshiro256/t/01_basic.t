use strict;
use warnings;
use Test::More;
use Math::Random::Xoshiro256;

my $rng = Math::Random::Xoshiro256->new();
ok($rng, 'Created PRNG instance');

# Test rand64
my $u64 = $rng->rand64();
ok(defined $u64 && $u64 >= 0, 'rand64 returns a 64-bit integer');

# Test next_double
my $d = $rng->__next_double();
ok($d >= 0 && $d < 1, 'next_double returns value in [0,1)');

# Test shuffle_array
my @orig     = qw(red green blue white black brown yellow purple pink);
my @shuffled = $rng->shuffle_array(@orig);

ok(scalar(@shuffled) == scalar(@orig), 'shuffle_array keeps length');
ok(join('', sort @shuffled) eq join('', sort @orig), 'shuffle_array preserves elements');

# Test random_elem
my $elem = $rng->random_elem(@orig);
my $ok   = grep { $_ eq $elem } @orig;
ok($ok, 'random_elem returns a value from the array');

# Test random_bytes
my $bytes = $rng->random_bytes(16);
ok(defined $bytes && length($bytes) == 16, 'random_bytes returns correct length');

# Test random_bytes edge case
my $one_byte = $rng->random_bytes(1);
ok(length($one_byte) == 1, 'random_bytes handles 1 byte request');

# Statistical test: average of 10,000 random_int(0,100) should be near 50
{
    my $N   = 10000;
    my $sum = 0;

    for (1 .. $N) {
        $sum += $rng->random_int(0,100);
    }

    my $avg = $sum / $N;

    ok(abs($avg - 50) < 2, "average of 10,000 random_int(0,100) near 50: $avg");
}

# Statistical test: average of 10,000 random_float() should be near 0.5
{
    my $N   = 10000;
    my $sum = 0;

    for (1 .. $N) {
        $sum += $rng->random_float();
    }

    my $avg = $sum / $N;

    ok(abs($avg - 0.5) < 0.03, "average of 10,000 random_float near 0.5: $avg");
}

# Inclusivity tests for random_int
{
    # Range [0,1] should produce both 0 and 1 across many trials
    my $seen0 = 0;
    my $seen1 = 0;
    for (1 .. 10000) {
        my $v = $rng->random_int(0, 1);

        $seen0 = 1 if $v == 0;
        $seen1 = 1 if $v == 1;

        last if $seen0 && $seen1;
    }

    ok($seen0 && $seen1, 'random_int(0,1) is inclusive of both 0 and 1');

    # Range [-10,20] should be inclusive: specifically see -10 and 20
    my $seen_min = 0;
    my $seen_max = 0;
    for (1 .. 20000) {
        my $v = $rng->random_int(-10, 20);
        $seen_min = 1 if $v == -10;
        $seen_max = 1 if $v == 20;

        last if $seen_min && $seen_max;
    }

    ok($seen_min && $seen_max, 'random_int(-10,20) includes both -10 and 20');
}

done_testing();
