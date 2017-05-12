/* Mersenne Twister PRNG

   A C-Program for MT19937 (32- and 64-bit versions), with initialization
   improved 2002/1/26.  Coded by Takuji Nishimura and Makoto Matsumoto,
   and including Shawn Cokus's optimizations.

   Copyright (C) 1997 - 2004, Makoto Matsumoto and Takuji Nishimura,
   All rights reserved.
   Copyright (C) 2005, Mutsuo Saito, All rights reserved.
   Copyright 2005 - 2009 Jerry D. Hedden <jdhedden AT cpan DOT org>

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

     1. Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.

     2. Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.

     3. The names of its contributors may not be used to endorse or promote
        products derived from this software without specific prior written
        permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER
   OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

   Any feedback is very welcome.
   <m-mat AT math DOT sci DOT hiroshima-u DOT ac DOT jp>
   http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/emt.html
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newRV_noinc
#include "ppport.h"

#include <math.h>


#if UVSIZE == 8
    /* Constants related to the Mersenne Twister */
#   define N 312        /* Number of 64-bit ints in state vector */
#   define M 156

    /* Macros used inside Mersenne Twister algorithm */
#   define MIXBITS(u,v) ( ((u) & 0xFFFFFFFF80000000ULL) | ((v) & 0x7FFFFFFFULL) )
#   define TWIST(u,v) ((MIXBITS(u,v) >> 1) ^ ((v)&1UL ? 0xB5026F5AA96619E9ULL : 0ULL))

    /* Final randomization of integer extracted from state vector */
#   define TEMPER_ELEM(x)                       \
        x ^= (x >> 29) & 0x0000000555555555ULL; \
        x ^= (x << 17) & 0x71D67FFFEDA60000ULL; \
        x ^= (x << 37) & 0xFFF7EEE000000000ULL; \
        x ^= (x >> 43)

    /* Seed routine constants */
#   define BIT_SHIFT 62
#   define MAGIC1 6364136223846793005ULL
#   define MAGIC2 3935559000370003845ULL
#   define MAGIC3 2862933555777941757ULL
#   define HI_BIT 1ULL<<63

    /* Various powers of 2 */
#   define TWOeMINUS51 4.44089209850062616169452667236328125e-16
#   define TWOeMINUS52 2.220446049250313080847263336181640625e-16
#   define TWOeMINUS53 1.1102230246251565404236316680908203125e-16

    /* Make a double between 0 (inclusive) and 1 (exclusive) */
#   define RAND_0i_1x(x) (((NV)((x) >> 12)) * TWOeMINUS52)
    /* Make a double between 0 and 1 (exclusive) */
#   define RAND_0x_1x(x)   (RAND_0i_1x(x) + TWOeMINUS53)
    /* Make a double between 0 (exclusive) and 1 (inclusive) */
#   define RAND_0x_1i(x) (((NV)(((x) >> 12) + 1)) * TWOeMINUS52)
    /* Make a double between -1 and 1 (exclusive) */
#   define RAND_NEG1x_1x(x) ((((NV)(((IV)(x)) >> 11)) * TWOeMINUS52) + TWOeMINUS53)

#else
    /* Constants related to the Mersenne Twister */
#   define N 624        /* Number of 32-bit ints in state vector */
#   define M 397

    /* Macros used inside Mersenne Twister algorithm */
#   define MIXBITS(u,v) ( ((u) & 0x80000000) | ((v) & 0x7FFFFFFF) )
#   define TWIST(u,v) ((MIXBITS((u),(v)) >> 1) ^ (((v)&1UL) ? 0x9908B0DF : 0UL))

    /* Final randomization of integer extracted from state vector */
#   define TEMPER_ELEM(x)            \
        x ^= (x >> 11);              \
        x ^= (x << 7)  & 0x9D2C5680; \
        x ^= (x << 15) & 0xEFC60000; \
        x ^= (x >> 18)

    /* Seed routine constants */
#   define BIT_SHIFT 30
#   define MAGIC1 1812433253
#   define MAGIC2 1664525
#   define MAGIC3 1566083941
#   define HI_BIT 0x80000000

    /* Various powers of 2 */
#   define TWOeMINUS31 4.656612873077392578125e-10
#   define TWOeMINUS32 2.3283064365386962890625e-10
#   define TWOeMINUS33 1.16415321826934814453125e-10

    /* Make a double between 0 (inclusive) and 1 (exclusive) */
#   define RAND_0i_1x(x) ((NV)(x) * TWOeMINUS32)
    /* Make a double between 0 and 1 (exclusive) */
#   define RAND_0x_1x(x)   (RAND_0i_1x(x) + TWOeMINUS33)
    /* Make a double between 0 (exclusive) and 1 (inclusive) */
#   define RAND_0x_1i(x) ((((NV)(x)) + 1.0) * TWOeMINUS32)
    /* Make a double between -1 and 1 (exclusive) */
#   define RAND_NEG1x_1x(x) ((((NV)((IV)(x))) * TWOeMINUS31) + TWOeMINUS32)
#endif


/* Standalone PRNG */
#define SA_PRNG    "MRMA::PRNG"

/* Definitions for getting PRNG context */
#define PRNG_VARS   SV *addr

#define PRNG_PREP   addr = SvRV(ST(0))
#define GET_PRNG    INT2PTR(struct mt *, SvUV(addr))

/* Variable declarations for the dual (OO and functional) interface */
#define DUAL_VARS                       \
        PRNG_VARS;                      \
        struct mt *prng;                \
        int idx

/* Sets up PRNG for dual-interface */
/* A ref check for an object call is good enough,
 * and much faster than object or 'isa' checking. */
#define DUAL_PRNG                       \
    if (items && SvROK(ST(0))) {        \
        /* OO interface */              \
        PRNG_PREP;                      \
        items--;                        \
        idx = 1;                        \
    } else {                            \
        /* Standalone PRNG */           \
        addr = SvRV(get_sv(SA_PRNG, 0));\
        idx = 0;                        \
    }                                   \
    prng = GET_PRNG;

/* Get next random from a PRNG */
#define IRAND(x,y)                                      \
    x = ((--y->left == 0) ? _mt_algo(y) : *y->next++);  \
    TEMPER_ELEM(x)


/* The PRNG state structure (AKA the PRNG context) */
struct mt {
    UV state[N];
    UV *next;
    IV left;

    struct {
        IV have;
        NV value;
    } gaussian;

    struct {
        NV mean;
        NV log_mean;
        NV sqrt2mean;
        NV term;
    } poisson;

    struct {
        IV trials;
        NV term;
        NV prob;
        NV plog;
        NV pclog;
    } binomial;
};


/* The state mixing algorithm for the Mersenne Twister */
static UV
_mt_algo(struct mt *prng)
{
    UV *st = prng->state;
    UV *sn = &st[2];
    UV *sx = &st[M];
    UV n0 = st[0];
    UV n1 = st[1];
    int kk;

    for (kk = N-M+1;  --kk;  n0 = n1, n1 = *sn++) {
        *st++ = *sx++ ^ TWIST(n0, n1);
    }
    sx = prng->state;
    for (kk = M;      --kk;  n0 = n1, n1 = *sn++) {
        *st++ = *sx++ ^ TWIST(n0, n1);
    }
    n1 = *prng->state;
    *st = *sx ^ TWIST(n0, n1);

    prng->next = &prng->state[1];
    prng->left = N;

    return (n1);
}


/* Helper function to get next random double */
static NV
_rand(struct mt *prng)
{
    UV x;
    IRAND(x, prng);
    return (RAND_0x_1x(x));
}


/* Helper function to calculate a random tan(angle) */
static NV
_tan(struct mt *prng)
{
    UV x1, y1;
    NV x2, y2;

    do {
        IRAND(x1, prng);
        IRAND(y1, prng);
        x2 = RAND_NEG1x_1x(x1);
        y2 = RAND_NEG1x_1x(y1);
    } while (x2*x2 + y2*y2 > 1.0);
    return (y2/x2);

    /* The above is faster than the following:
    UV x;
    IRAND(x, prng);
    return (tan(3.1415926535897932 * RAND_0x_1x(x)));
    */
}


/* Helper function that returns the value ln(gamma(x)) for x > 0 */
/* Optimized from 'Numerical Recipes in C', Chapter 6.1          */
static NV
_ln_gamma(NV x)
{
    NV qq, ser;

    qq  = x + 4.5;
    qq -= (x - 0.5) * log(qq);

    ser = 1.000000000190015
        + (76.18009172947146    / x)
        - (86.50532032941677    / (x + 1.0))
        + (24.01409824083091    / (x + 2.0))
        - (1.231739572450155    / (x + 3.0))
        + (1.208650973866179e-3 / (x + 4.0))
        - (5.395239384953e-6    / (x + 5.0));

    return (log(2.5066282746310005 * ser) - qq);
}


MODULE = Math::Random::MT::Auto   PACKAGE = Math::Random::MT::Auto
PROTOTYPES: DISABLE


# The functions below are the random number deviates for the module.

# They work both as regular 'functions' for the functional interface to the
# standalone PRNG, as well as methods for the OO interface to PRNG objects.


# irand
#
# Returns a random integer.

UV
irand(...)
    PREINIT:
        DUAL_VARS;
    CODE:
        DUAL_PRNG
        IRAND(RETVAL, prng);
    OUTPUT:
        RETVAL


# rand
#
# Returns a random number on the range [0,1),
# or [0,X) if an argument is supplied.

double
rand(...)
    PREINIT:
        DUAL_VARS;
        UV rand;
    CODE:
        DUAL_PRNG

        /* Random number on [0,1) interval */
        IRAND(rand, prng);
        RETVAL = RAND_0i_1x(rand);
        if (items) {
            /* Random number on [0,X) interval */
            RETVAL *= SvNV(ST(idx));
        }
    OUTPUT:
        RETVAL


# shuffle
#
# Shuffles input data using the Fisher-Yates shuffle algorithm.

SV *
shuffle(...)
    PREINIT:
        DUAL_VARS;
        AV *ary;
        I32 ii, jj;
        UV rand;
        SV *elem;
    CODE:
        /* Same as DUAL_PRNG except needs more stringent object check */
        if (items && sv_isobject(ST(0))) {
            /* OO interface */
            PRNG_PREP;
            items--;
            idx = 1;
        } else {
            /* Standalone PRNG */
            addr = SvRV(get_sv(SA_PRNG, 0));
            idx = 0;
        }
        prng = GET_PRNG;

        /* Handle arguments */
        if (items == 1 && SvROK(ST(idx)) && SvTYPE(SvRV(ST(idx)))==SVt_PVAV) {
            /* User supplied an array reference */
            ary = (AV*)SvRV(ST(idx));
            RETVAL = newRV_inc((SV *)ary);

        } else if (GIMME_V == G_ARRAY) {
            /* If called in array context, shuffle directly on stack */
            for (ii = items-1 ; ii > 0 ; ii--) {
                /* Pick a random element from the beginning
                   of the array to the current element */
                IRAND(rand, prng);
                jj = rand % (ii + 1);
                /* Swap elements */
                SV *elem = ST(jj);
                ST(jj) = ST(ii);
                ST(ii) = elem;
            }
            XSRETURN(items);

        } else {
            /* Create an array from user supplied values */
            ary = newAV();
            av_extend(ary, items);
            while (items--) {
                av_push(ary, newSVsv(ST(idx++)));
            }
            RETVAL = newRV_noinc((SV *)ary);
        }

        /* Process elements from last to second */
        for (ii=av_len(ary); ii > 0; ii--) {
            /* Pick a random element from the beginning
               of the array to the current element */
            IRAND(rand, prng);
            jj = rand % (ii + 1);
            /* Swap elements */
            elem = AvARRAY(ary)[ii];
            AvARRAY(ary)[ii] = AvARRAY(ary)[jj];
            AvARRAY(ary)[jj] = elem;
        }
    OUTPUT:
        RETVAL


# gaussian
#
# Returns random numbers from a Gaussian distribution.
#
# On the first pass it calculates two numbers, returning one and saving the
# other.  On the next pass, it just returns the previously saved number.

double
gaussian(...)
    PREINIT:
        DUAL_VARS;
        UV u1, u2;
        NV v1, v2, r, factor;
    CODE:
        DUAL_PRNG

        if (prng->gaussian.have) {
            /* Use number generated during previous call */
            RETVAL = prng->gaussian.value;
            prng->gaussian.have = 0;

        } else {
            /* Marsaglia's polar method for the Box-Muller transformation */
            /* See 'Numerical Recipes in C', Chapter 7.2 */
            do {
                IRAND(u1, prng);
                IRAND(u2, prng);
                v1 = RAND_NEG1x_1x(u1);
                v2 = RAND_NEG1x_1x(u2);
                r = v1*v1 + v2*v2;
            } while (r >= 1.0);

            factor = sqrt((-2.0 * log(r)) / r);
            RETVAL = v1 * factor;

            /* Save 2nd value for later */
            prng->gaussian.value = v2 * factor;
            prng->gaussian.have = 1;
        }

        if (items) {
            /* Gaussian distribution with SD = X */
            RETVAL *= SvNV(ST(idx));
            if (items > 1) {
                /* Gaussian distribution with mean = Y */
                RETVAL += SvNV(ST(idx+1));
            }
        }
    OUTPUT:
        RETVAL


# exponential
#
# Returns random numbers from an exponential distribution.

double
exponential(...)
    PREINIT:
        DUAL_VARS;
    CODE:
        DUAL_PRNG

        /* Exponential distribution with mean = 1 */
        RETVAL = -log(_rand(prng));
        if (items) {
            /* Exponential distribution with mean = X */
            RETVAL *= SvNV(ST(idx));
        }
    OUTPUT:
        RETVAL


# erlang
#
# Returns random numbers from an Erlang distribution.

double
erlang(...)
    PREINIT:
        DUAL_VARS;
        IV order;
        IV ii;
        NV am, ss, tang, bound;
    CODE:
        DUAL_PRNG

        /* Check argument */
        if (! items) {
            Perl_croak(aTHX_ "Missing argument to 'erlang'");
        }
        if ((order = SvIV(ST(idx))) < 1) {
            Perl_croak(aTHX_ "Bad argument (< 1) to 'erlang'");
        }

        if (order < 6) {
            /* Direct method of 'adding exponential randoms' */
            RETVAL = 1.0;
            for (ii=0; ii < order; ii++) {
                RETVAL *= _rand(prng);
            }
            RETVAL = -log(RETVAL);

        } else {
            /* Use J. H. Ahren's rejection method */
            /* See 'Numerical Recipes in C', Chapter 7.3 */
            am = order - 1;
            ss = sqrt(2.0 * am + 1.0);
            do {
                do {
                    tang = _tan(prng);
                    RETVAL = (tang * ss) + am;
                } while (RETVAL <= 0.0);
                bound = (1.0 + tang*tang) * exp(am * log(RETVAL/am) - ss*tang);
            } while (_rand(prng) > bound);
        }

        if (items > 1) {
            /* Erlang distribution with mean = X */
            RETVAL *= SvNV(ST(idx+1));
        }
    OUTPUT:
        RETVAL


# poisson
#
# Returns random numbers from a Poisson distribution.

IV
poisson(...)
    PREINIT:
        DUAL_VARS;
        NV mean;
        NV em, tang, bound, limit;
    CODE:
        DUAL_PRNG

        /* Check argument(s) */
        if (! items) {
            Perl_croak(aTHX_ "Missing argument(s) to 'poisson'");
        }
        if (items == 1) {
            if ((mean = SvNV(ST(idx))) <= 0.0) {
                Perl_croak(aTHX_ "Bad argument (<= 0) to 'poisson'");
            }
        } else {
            if ((mean = SvNV(ST(idx)) * SvNV(ST(idx+1))) < 1.0) {
                Perl_croak(aTHX_ "Bad arguments (rate*time <= 0) to 'poisson'");
            }
        }

        if (mean < 12.0) {
            /* Direct method */
            bound = 1.0;
            limit = exp(-mean);
            for (RETVAL=0; ; RETVAL++) {
                bound *= _rand(prng);
                if (bound < limit) {
                    break;
                }
            }

        } else {
            /* Rejection method */
            /* See 'Numerical Recipes in C', Chapter 7.3 */
            if (prng->poisson.mean != mean) {
                prng->poisson.mean      = mean;
                prng->poisson.log_mean  = log(mean);
                prng->poisson.sqrt2mean = sqrt(2.0 * mean);
                prng->poisson.term      = (mean * prng->poisson.log_mean)
                                                - _ln_gamma(mean + 1.0);
            }
            do {
                do {
                    tang = _tan(prng);
                    em = (tang * prng->poisson.sqrt2mean) + mean;
                } while (em < 0.0);
                em = floor(em);
                bound = 0.9 * (1.0 + tang*tang)
                            * exp((em * prng->poisson.log_mean)
                                        - _ln_gamma(em+1.0)
                                        - prng->poisson.term);
            } while (_rand(prng) > bound);
            RETVAL = (int)em;
        }
    OUTPUT:
        RETVAL


# binomial
#
# Returns random numbers from a binomial distribution.

IV
binomial(...)
    PREINIT:
        DUAL_VARS;
        NV prob;
        IV trials;
        int ii;
        NV p, pc, mean;
        NV en, em, tang, bound, limit, sq;
    CODE:
        DUAL_PRNG

        /* Check argument(s) */
        if (items < 2) {
            Perl_croak(aTHX_ "Missing argument(s) to 'binomial'");
        }
        if (((prob = SvNV(ST(idx))) < 0.0 || prob > 1.0) ||
            ((trials = SvIV(ST(idx+1))) < 0))
        {
            Perl_croak(aTHX_ "Invalid argument(s) to 'binomial'");
        }

        /* If probability > .5, then calculate based on non-occurance */
        p = (prob <= 0.5) ? prob : 1.0-prob;

        if (trials < 25) {
            /* Direct method */
            RETVAL = 0;
            for (ii=1; ii <= trials; ii++) {
                if (_rand(prng) < p) {
                    RETVAL++;
                }
            }

        } else {
            if ((mean = p * trials) < 1.0) {
                /* Use direct Poisson method */
                bound = 1.0;
                limit = exp(-mean);
                for (RETVAL=0; RETVAL < trials; RETVAL++) {
                    bound *= _rand(prng);
                    if (bound < limit) {
                        break;
                    }
                }

            } else {
                /* Rejection method */
                /* See 'Numerical Recipes in C', Chapter 7.3 */
                en = (NV)trials;
                pc = 1.0 - p;
                sq = sqrt(2.0 * mean * pc);

                if (trials != prng->binomial.trials) {
                    prng->binomial.trials = trials;
                    prng->binomial.term = _ln_gamma(en + 1.0);
                }
                if (p != prng->binomial.prob) {
                    prng->binomial.prob  = p;
                    prng->binomial.plog  = log(p);
                    prng->binomial.pclog = log(pc);
                }

                do {
                    do {
                        tang = _tan(prng);
                        em = (sq * tang) + mean;
                    } while (em < 0.0 || em >= (en+1.0));
                    em = floor(em);
                    bound = 1.2 * sq * (1.0 + tang*tang) *
                                exp(prng->binomial.term -
                                    _ln_gamma(em + 1.0) -
                                    _ln_gamma(en - em + 1.0) +
                                    em * prng->binomial.plog +
                                    (en - em) * prng->binomial.pclog);
                } while (_rand(prng) > bound);
                RETVAL = (IV)em;
            }
        }

        /* Adjust results for occurance vs. non-occurance */
        if (p < prob) {
            RETVAL = trials - RETVAL;
        }

    OUTPUT:
        RETVAL



# The functions below are for internal use by the Math::Random::MT::Auto
# package.

MODULE = Math::Random::MT::Auto   PACKAGE = Math::Random::MT::Auto::_


# new_prng
#
# Creates a new PRNG context for the OO Interface, and returns a pointer to it.

SV *
new_prng(...)
    PREINIT:
        struct mt *prng;
    CODE:
        Newxz(prng, 1, struct mt);
        /* Initializes with minimal data to ensure it's 'safe' */
        prng->state[0]        = HI_BIT;
        prng->left            = 1;
        prng->poisson.mean    = -1;
        prng->binomial.trials = -1;
        prng->binomial.prob   = -1.0;
        RETVAL = newSVuv(PTR2UV(prng));
    OUTPUT:
        RETVAL


# free_prng
#
# Frees the PRNG context as part of object destruction.

void
free_prng(...)
    PREINIT:
        PRNG_VARS;
        struct mt *prng;
    CODE:
        PRNG_PREP;
        if ((prng = GET_PRNG)) {
            Safefree(prng);
        }


# seed_prng
#
# Applies a supplied seed to a specified PRNG.
#
# The specified PRNG may be either the standalone PRNG or an object's PRNG.

void
seed_prng(...)
    PREINIT:
        PRNG_VARS;
        struct mt *prng;
        AV *myseed;
        int len;
        UV *st;
        int ii, jj, kk;
    CODE:
        PRNG_PREP;
        prng = GET_PRNG;

        /* Extract argument */
        myseed = (AV*)SvRV(ST(1));

        len = av_len(myseed)+1;
        st = prng->state;

        /* Initialize */
        st[0]= 19650218;
        for (ii=1; ii<N; ii++) {
            st[ii] = (MAGIC1 * (st[ii-1] ^ (st[ii-1] >> BIT_SHIFT)) + ii);
        }

        /* Add supplied seed */
        ii=1; jj=0;
        for (kk = ((N>len) ? N : len); kk; kk--) {
            st[ii] = (st[ii] ^ ((st[ii-1] ^ (st[ii-1] >> BIT_SHIFT)) * MAGIC2))
                            + SvUV(*av_fetch(myseed, jj, 0)) + jj;
            if (++ii >= N) { st[0] = st[N-1]; ii=1; }
            if (++jj >= len) jj=0;
        }

        /* Final shuffle */
        for (kk=N-1; kk; kk--) {
            st[ii] = (st[ii] ^ ((st[ii-1] ^ (st[ii-1] >> BIT_SHIFT)) * MAGIC3)) - ii;
            if (++ii >= N) { st[0] = st[N-1]; ii=1; }
        }

        /* Guarantee non-zero initial state */
        st[0] = HI_BIT;

        /* Forces twist when first random is requested */
        prng->left = 1;


# get_state
#
# Returns an array ref containing the state vector and internal data for a
# specified PRNG.
#
# The specified PRNG may be either the standalone PRNG or an object's PRNG.

SV *
get_state(...)
    PREINIT:
        PRNG_VARS;
        struct mt *prng;
        AV *state;
        int ii;
    CODE:
        PRNG_PREP;
        prng = GET_PRNG;

        /* Create state array */
        state = newAV();
        av_extend(state, N+12);

        /* Add internal PRNG state to array */
        for (ii=0; ii<N; ii++) {
            av_push(state, newSVuv(prng->state[ii]));
        }
        av_push(state, newSViv(prng->left));

        /* Add non-uniform deviate function data to array */
        av_push(state, newSViv(prng->gaussian.have));
        av_push(state, newSVnv(prng->gaussian.value));
        av_push(state, newSVnv(prng->poisson.mean));
        av_push(state, newSVnv(prng->poisson.log_mean));
        av_push(state, newSVnv(prng->poisson.sqrt2mean));
        av_push(state, newSVnv(prng->poisson.term));
        av_push(state, newSViv(prng->binomial.trials));
        av_push(state, newSVnv(prng->binomial.term));
        av_push(state, newSVnv(prng->binomial.prob));
        av_push(state, newSVnv(prng->binomial.plog));
        av_push(state, newSVnv(prng->binomial.pclog));

        RETVAL = newRV_noinc((SV *)state);
    OUTPUT:
        RETVAL


# set_state
#
# Sets the specified PRNG's state vector and internal data from a supplied
# array ref.
#
# The specified PRNG may be either the standalone PRNG or an object's PRNG.

void
set_state(...)
    PREINIT:
        PRNG_VARS;
        struct mt *prng;
        AV *state;
        int ii;
    CODE:
        PRNG_PREP;
        prng = GET_PRNG;

        /* Extract argument */
        state = (AV*)SvRV(ST(1));

        /* Validate size of argument */
        if (av_len(state) != N+11) {
            Perl_croak(aTHX_ "Invalid state vector");
        }

        /* Extract internal PRNG state from array */
        for (ii=0; ii<N; ii++) {
            prng->state[ii] = SvUV(*av_fetch(state, ii, 0));
        }
        prng->left = SvIV(*av_fetch(state, ii, 0)); ii++;
        if (prng->left > 1) {
            prng->next = &prng->state[(N+1) - prng->left];
        }

        /* Extract non-uniform deviate function data from array */
        prng->gaussian.have     = SvIV(*av_fetch(state, ii, 0)); ii++;
        prng->gaussian.value    = SvNV(*av_fetch(state, ii, 0)); ii++;
        prng->poisson.mean      = SvNV(*av_fetch(state, ii, 0)); ii++;
        prng->poisson.log_mean  = SvNV(*av_fetch(state, ii, 0)); ii++;
        prng->poisson.sqrt2mean = SvNV(*av_fetch(state, ii, 0)); ii++;
        prng->poisson.term      = SvNV(*av_fetch(state, ii, 0)); ii++;
        prng->binomial.trials   = SvIV(*av_fetch(state, ii, 0)); ii++;
        prng->binomial.term     = SvNV(*av_fetch(state, ii, 0)); ii++;
        prng->binomial.prob     = SvNV(*av_fetch(state, ii, 0)); ii++;
        prng->binomial.plog     = SvNV(*av_fetch(state, ii, 0)); ii++;
        prng->binomial.pclog    = SvNV(*av_fetch(state, ii, 0));

 /* EOF */
