# NAME

Math::Random::Xoshiro256 - XS wrapper for xoshiro256\*\* PRNG

# SYNOPSIS

```perl
use Math::Random::Xoshiro256;
my $rng = Math::Random::Xoshiro256->new();

my $rand   = $rng->rand64();
my $int    = $rng->random_int(10, 20);   # non-biased integer in [10, 20]
my $bytes  = $rng->random_bytes(16);     # 16 random bytes from PRNG
my $float  = $rng->random_float();       # float in [0, 1] inclusive

my @arr       = ('red', 'green', 'blue', 'yellow', 'purple');
my $rand_item = $rng->random_elem(@arr);
my @mixed     = $rng->shuffle_array(@arr);

$rng->seed($seed)   # Single 64bit seed
$rng->seed4(@seeds) # 4x 64bit seeds
```

# DESCRIPTION

Implement the Xoshiro256\*\* PRNG and expose so user friendly random methods.

This module is automatically seeded with entropy directly from your OS.
On Linux this is `/dev/urandom` and on Windows it uses `RtlGenRandom`.

Alternately you can manually seed this if you need repeatable random
numbers.

# METHODS

- **rand64()**

    Return an unsigned 64-bit random integer.

- **random\_int($min, $max)**

    Return a random integer (non-biased) in \[$min, $max\] inclusive.

- **random\_bytes($num)**

    Returns $num random bytes.

- **random\_float()**

    Returns a float in the interval \[0, 1\] inclusive.

- **random\_elem(@array)**

    Returns a single random element from the given array (returns undef if array is empty).

- **shuffle\_array(@array)**

    Returns a shuffled list using the Fisher-Yates algorithm with the PRNG instance. Input array is not modified.

# SEE ALSO

- [Random::Simple](https://metacpan.org/pod/Random%3A%3ASimple)
- [Math::Random::PCG32](https://metacpan.org/pod/Math%3A%3ARandom%3A%3APCG32)
- [Math::Random::ISAAC](https://metacpan.org/pod/Math%3A%3ARandom%3A%3AISAAC)
- [Math::Random::MT](https://metacpan.org/pod/Math%3A%3ARandom%3A%3AMT)
