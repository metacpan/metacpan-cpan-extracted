use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Math::Random::Biski64' }

# Default RNG is auto-seeded at module load
my $default = Math::Random::Biski64->new();
isa_ok $default, 'Math::Random::Biski64', 'default RNG';
ok defined $default->next_u64, 'default produces a value';

# Deterministic seeding
my $rng = Math::Random::Biski64->new(12345);
isa_ok $rng, 'Math::Random::Biski64', 'new with seed';
my @expected = (
    602457908646571220,
    10831703241751616260,
    9045905474721525462,
    6056737633715403807,
    12343206235777992780,
);
is $rng->next_u64, $expected[0], 'output 1 matches reference';
is $rng->next_u64, $expected[1], 'output 2 matches reference';
is $rng->next_u64, $expected[2], 'output 3 matches reference';
is $rng->next_u64, $expected[3], 'output 4 matches reference';
is $rng->next_u64, $expected[4], 'output 5 matches reference';

# Determinism: same seed → same sequence
my $rng_a = Math::Random::Biski64->new(42);
my $rng_b = Math::Random::Biski64->new(42);
is $rng_a->next_u64, $rng_b->next_u64, 'deterministic across instances';
is $rng_a->next_u64, $rng_b->next_u64, 'deterministic continues';

# Re-seeding
$rng->seed(99);
my $c = Math::Random::Biski64->new(99);
is $rng->next_u64, $c->next_u64, 're-seed works';

# next_u32 returns upper 32 bits
my $r32 = Math::Random::Biski64->new(12345);
my $full = $r32->next_u64;
$r32->seed(12345);
is $r32->next_u32, $full >> 32, 'next_u32 is upper 32 bits';

# next_double is in [0, 1)
my $r_dbl = Math::Random::Biski64->new(777);
my $d = $r_dbl->next_double;
ok $d >= 0 && $d < 1, 'next_double in [0, 1)';
$d = $r_dbl->next_double;
ok $d >= 0 && $d < 1, 'next_double in range (2nd call)';

# Auto-seeded new() produces non-zero outputs
my $r_auto = Math::Random::Biski64->new;
ok $r_auto->next_u64 > 0, 'auto-seeded non-zero';
ok $r_auto->next_u64 > 0, 'auto-seeded non-zero (2nd)';

# for_stream produces deterministic per-stream
my $s0a = Math::Random::Biski64->for_stream(42, 0, 4);
my $s0b = Math::Random::Biski64->for_stream(42, 0, 4);
is $s0a->next_u64, $s0b->next_u64, 'stream deterministic';

# Different streams differ
my $s1 = Math::Random::Biski64->for_stream(42, 1, 4);
my $s2 = Math::Random::Biski64->for_stream(42, 2, 4);
cmp_ok $s0a->next_u64, '!=', $s1->next_u64, 'stream 0 ≠ stream 1';
cmp_ok $s0a->next_u64, '!=', $s2->next_u64, 'stream 0 ≠ stream 2';

# os_random_u64 returns non-zero
my $os = Math::Random::Biski64::os_random_u64();
ok $os > 0, 'os_random_u64 returns non-zero';

# rand_integer range
my $ri = Math::Random::Biski64->new(555);
my $n = $ri->rand_integer(1, 6);
ok $n >= 1 && $n <= 6, 'rand_integer(1,6) in range';

# rand_integer single value
is $ri->rand_integer(5, 5), 5, 'rand_integer(5,5) returns 5';

# rand_integer swapped range
is $ri->rand_integer(10, 3), 10, 'rand_integer(10,3) returns min';

# rand_integer deterministic
my $ria = Math::Random::Biski64->new(42);
my $rib = Math::Random::Biski64->new(42);
is $ria->rand_integer(0, 100), $rib->rand_integer(0, 100), 'rand_integer deterministic';

# rand_integer large range
$n = $ri->rand_integer(0, 1000000);
ok $n >= 0 && $n <= 1000000, 'rand_integer(0, 1000000) in range';

# shuffle_array returns all original elements
my @original = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
my $rs = Math::Random::Biski64->new(999);
my @shuffled = $rs->shuffle_array(@original);
is scalar(@shuffled), scalar(@original), 'shuffle_array preserves length';
my @sorted = sort { $a <=> $b } @shuffled;
is_deeply \@sorted, \@original, 'shuffle_array preserves elements';

# shuffle_array deterministic
my $rsa = Math::Random::Biski64->new(42);
my $rsb = Math::Random::Biski64->new(42);
my @a = $rsa->shuffle_array(1..20);
my @b = $rsb->shuffle_array(1..20);
is_deeply \@a, \@b, 'shuffle_array deterministic';

# shuffle_array single element
my @single = $rs->shuffle_array(42);
is_deeply \@single, [42], 'shuffle_array single element';

# shuffle_array empty list
my @empty = $rs->shuffle_array();
is_deeply \@empty, [], 'shuffle_array empty list';

# random_elem membership
my $re = Math::Random::Biski64->new(1234);
my @elems = (10 .. 50);
for (1 .. 10) {
	my $pick = $re->random_elem(@elems);
	ok $pick >= 10 && $pick <= 50, 'random_elem member of list';
}

# random_elem single element
is $re->random_elem('only'), 'only', 'random_elem single element';

# random_elem deterministic
my $rea = Math::Random::Biski64->new(42);
my $reb = Math::Random::Biski64->new(42);
is $rea->random_elem('a' .. 'z'), $reb->random_elem('a' .. 'z'), 'random_elem deterministic';

# random_elem distribution sanity (loose)
my $rex = Math::Random::Biski64->new(777);
my %seen;
$seen{ $rex->random_elem('x', 'y') }++ for 1 .. 200;
ok $seen{x} > 0,  'random_elem covers x';
ok $seen{y} > 0,  'random_elem covers y';

# random_elem empty list returns undef
is $re->random_elem(), undef, 'random_elem empty returns undef';

done_testing();
