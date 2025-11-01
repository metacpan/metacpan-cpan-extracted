#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdint.h>

/* xoshiro256+ core */
static inline uint64_t rotl(const uint64_t x, int k) {
    return (x << k) | (x >> (64 - k));
}

/* OOP interface: define a struct to hold state for each object */
typedef struct {
    uint64_t s[4];
} xoshiro256_state;

#define SvXoshiro256State(sv) ((xoshiro256_state*)SvIV(SvRV(sv)))

/* Remove the static s[4] global */

/* Make core routines instance methods */
static uint64_t next_xoshiro256plus(xoshiro256_state *st) {
    const uint64_t result = st->s[0] + st->s[3];
    const uint64_t t = st->s[1] << 17;
    st->s[2] ^= st->s[0];
    st->s[3] ^= st->s[1];
    st->s[1] ^= st->s[2];
    st->s[0] ^= st->s[3];
    st->s[2] ^= t;
    st->s[3] = rotl(st->s[3], 45);
    return result;
}

// https://prng.di.unimi.it/xoshiro256starstar.c
static uint64_t next_xoshiro256starstar(xoshiro256_state *st) {
	const uint64_t result = rotl(st->s[1] * 5, 7) * 9;

	const uint64_t t = st->s[1] << 17;

	st->s[2] ^= st->s[0];
	st->s[3] ^= st->s[1];
	st->s[1] ^= st->s[2];
	st->s[0] ^= st->s[3];

	st->s[2] ^= t;

	st->s[3] = rotl(st->s[3], 45);

	return result;
}

/* splitmix64 for seeding */
static uint64_t splitmix64(uint64_t *state) {
    uint64_t z = (*state += 0x9E3779B97F4A7C15ULL);
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
    return z ^ (z >> 31);
}

/* ========================================================================== */
/* ========================================================================== */

MODULE = Math::Random::Xoshiro256  PACKAGE = Math::Random::Xoshiro256

SV* _xs_new(class)
    const char* class;
CODE:
{
    xoshiro256_state *st = malloc(sizeof(xoshiro256_state));
    if (!st) croak("Allocation failed");
    /* Default: zero-init; must seed before use */
    st->s[0]=st->s[1]=st->s[2]=st->s[3]=0ULL;
    SV* obj_ref = newSViv(0);
    SV* obj = newSVrv(obj_ref, class);
    sv_setiv(obj, (IV)st);
    SvREADONLY_on(obj);
    RETVAL = obj_ref;
}
OUTPUT: RETVAL

void DESTROY(self)
    SV* self;
CODE:
{
    xoshiro256_state *st = SvXoshiro256State(self);
    free(st);
}

void seed(self, seed)
    SV* self;
    UV seed;
CODE:
{
    xoshiro256_state *st = SvXoshiro256State(self);
    uint64_t s = (uint64_t)seed;
    st->s[0] = splitmix64(&s);
    st->s[1] = splitmix64(&s);
    st->s[2] = splitmix64(&s);
    st->s[3] = splitmix64(&s);
}

void seed4(self, seed1, seed2, seed3, seed4)
    SV* self;
    UV seed1;
    UV seed2;
    UV seed3;
    UV seed4;
CODE:
{
    xoshiro256_state *st = SvXoshiro256State(self);
    st->s[0] = seed1;
    st->s[1] = seed2;
    st->s[2] = seed3;
    st->s[3] = seed4;
}

UV rand64(self)
    SV* self;
CODE:
{
    xoshiro256_state *st = SvXoshiro256State(self);
    RETVAL = (UV) next_xoshiro256starstar(st);
}
OUTPUT: RETVAL

double __next_double(self)
    SV* self;
CODE:
{
    xoshiro256_state *st = SvXoshiro256State(self);
    uint64_t v = next_xoshiro256starstar(st);
    uint64_t top53 = v >> 11; /* keep top 53 bits */
    RETVAL = (double) top53 * (1.0 / 9007199254740992.0); /* 2^53 */
}
OUTPUT: RETVAL

IV random_int(self, min, max)
    SV* self;
    IV min;
    IV max;
CODE:
{
    xoshiro256_state *st = SvXoshiro256State(self);

    if (min > max) {
        croak("random_int: min must be <= max");
    }

    uint64_t range = (max - min) + 1;

    if (range == 0) {
        croak("random_int: Invalid arguments (range overflow or zero)");
    }

    uint64_t threshold = (-range) % range;
    uint64_t v;
    do {
        v = next_xoshiro256starstar(st);
    } while (v < threshold);

    RETVAL = (IV)((int64_t)min + (int64_t)(v % range));
}
OUTPUT: RETVAL
