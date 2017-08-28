#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newCONSTSUB
#define NEED_sv_2pv_flags
#include "ppport.h"

#if defined __GLIBC__ && defined __linux__
#  ifndef _GNU_SOURCE
#    define _GNU_SOURCE
#  endif
#include <unistd.h>
#include <sys/syscall.h>
#include <linux/random.h>
#endif

#include "mtwist/mtwist.c"
#include "mtwist/randistrs.c"

/* Some guesswork for older Perls */
#ifndef NVMANTBITS
  #if NVSIZE <= 4
    #define NVMANTBITS 23
  #elif NVSIZE <= 8
    #define NVMANTBITS 52
  #elif defined(USE_QUADMATH)
    #define NVMANTBITS 112
  #elif defined(__LDBL_MANT_DIG__)
    #define NVMANTBITS __LDBL_MANT_DIG__
  #else
    #define NVMANTBITS 64
  #endif
#endif

#ifdef UINT64_MAX
  #define HAS_UINT64_T 1
#else
  #define HAS_UINT64_T 0
#endif

#define MT_HAS_INT128 defined(UINT64_MAX) && defined(__SIZEOF_INT128__)
#define MT_USE_QUADMATH NVMANTBITS > 64 && defined(USE_QUADMATH)
#define MT_USE_LONG_DOUBLE NVMANTBITS > 53 && defined(HAS_LONG_DOUBLE) && defined(USE_LONG_DOUBLE)

typedef union {
  double dbl;
  char str[8];
  uint32_t i32[2];
#if HAS_UINT64_T
  uint64_t i64;
#endif
} int2dbl;

#define I2D_SIZE sizeof(int2dbl)

#if HAS_UINT64_T
/* based on libowfat */
static inline U8 fmt_uint64(char* dest, uint64_t u) {
  U8 len, len2;
  uint64_t tmp;

  /* count digits */
  for(len = 1, tmp = u; tmp > 9; tmp /= 10)
    len++;

  if (dest) {
    len2 = len;
    dest += len;
    do {
      *--dest = (char)((u%10) + '0');
      u /= 10;
    } while (--len2);
  }

  return len;
}

#if IVSIZE < 8
/* newSVpvf doesn't handle "%llu" correctly. */
static SV* svpv_uint64(uint64_t u) {
  SV* retval;
  char* buf;
  size_t length;
  const size_t bufsize = 24;

  dTHX;

  Newxc(buf, bufsize, char, char);
  if (!buf)
    return NULL;

  retval = newSV(0);
  if (!retval) {
    Safefree(buf);
    return NULL;
  }

  length = fmt_uint64(buf, u);

  sv_upgrade(retval, SVt_PV);
  SvCUR_set(retval, length);
  SvLEN_set(retval, bufsize);
  SvPV_set(retval, buf);
  SvPOK_only(retval);

  return retval;
}
#endif  /* IVSIZE < 8 */
#endif  /* UINT64_MAX */

#if MT_HAS_INT128
typedef unsigned __int128 mt_uint128_t;

static inline mt_uint128_t mts_u128rand(register mt_state*  state) {
  unsigned i;
  union u128 {
    uint32_t u32[4];
    mt_uint128_t u128;
  } rv;
  uint32_t* u32 = rv.u32 + 4;

  for (i = 4; i > 0; i--) {
    if (state->stateptr <= 0)
      mts_refresh(state);
    *--u32 = state->statevec[--state->stateptr];
    MT_TEMPER(*u32);
  }

  return rv.u128;
}

static inline mt_uint128_t mt_u128rand(void) {
  return mts_u128rand(&mt_default_state);
}

/* 128-bit division and modulo are very time-consuming because there is no
 * native 128-bit integer arithmetic. We speed it up a bit by dividing by 1e9
 * instead of 10.
 */
static inline void fmt_nsec(char* dest, uint64_t u) {
  if (dest && u < 1000000000) {
    do {
      *--dest = (char)((u%10) + '0');
      u /= 10;
    } while (u);
  }
}

static inline U8 fmt_uint128(char* dest, mt_uint128_t u) {
  U8 len, len2;
  mt_uint128_t tmp;
  uint64_t mod;

  /* count digits */
  for (len = 0, tmp = u; tmp > 999999999; tmp /= 1000000000)
    len += 9;
  len += fmt_uint64(NULL, (uint64_t)tmp);

  if (dest) {
    memset(dest, '0', len);
    len2 = len;
    dest += len;
    while (1) {
      mod = u % 1000000000;
      if (mod)
        fmt_nsec(dest, mod);

      len2 -= 9;
      if ((I8)len2 <= 0)
        break;

      dest -= 9;
      u /= 1000000000;
    }
  }

  return len;
}

static SV* svpv_uint128(mt_uint128_t u) {
  SV* retval;
  char* buf;
  size_t length;
  const size_t bufsize = 40;

  dTHX;

  Newxc(buf, bufsize, char, char);
  if (!buf)
    return NULL;

  retval = newSV(0);
  if (!retval) {
    Safefree(buf);
    return NULL;
  }

  length = fmt_uint128(buf, u);

  sv_upgrade(retval, SVt_PV);
  SvCUR_set(retval, length);
  SvLEN_set(retval, bufsize);
  SvPV_set(retval, buf);
  SvPOK_only(retval);

  return retval;
}
#endif

/*
 * We copy the seeds from an array reference to a buffer so that mtwist can
 * copy the buffer to another buffer. No wonder that computer power must double
 * every two years ...
 *
 *
 * We assume that mt_seeds[] has been initialized with zeros.
 */
static void get_seeds_from_av(AV* av_seeds, uint32_t* mt_seeds) {
  SSize_t i;
  SV** av_seed;
  uint32_t had_nz = 0;

  dTHX;

  /*
   * Two classic examples of badly chosen identifier names:
   * av_len() does not return the array length but the top array index.
   * MT_STATE_SIZE is not sizeof(mt_state) but the length of the state vector.
   */

  i = av_len(av_seeds);
  if (i >= MT_STATE_SIZE)
    i = MT_STATE_SIZE - 1;

  for (; i >= 0; i--)
    if ((av_seed = av_fetch(av_seeds, i, 0)))
      had_nz |= mt_seeds[i] = SvUV(*av_seed);

  if (! had_nz)
    croak("seedfull(): Need at least one non-zero seed value");
}

/*
 * We calculate clock_gettime() in nanoseconds or gettimeofday() in
 * microseconds XORed with a memory address and use the lower 32 bit as the
 * seed.
 */
static uint32_t timeseed(mt_state* state) {
  UV seed;
#ifdef CLOCK_MONOTONIC
  struct timespec ts;

  clock_gettime(CLOCK_MONOTONIC, &ts);
  seed = ts.tv_sec*1000000000 + ts.tv_nsec;
#else
  I32 return_count;

  /* Who invented those silly cryptic macro names? */
  dTHX;
  dSP;

  PUSHMARK(SP);
  return_count = call_pv("Time::HiRes::gettimeofday", G_ARRAY);

  if (return_count != 2)
    croak("Time::HiRes::gettimeofday() returned %d instead of 2 values",
          return_count);

  SPAGAIN;
  seed = POPu;
  seed += POPu * 1000000;
  PUTBACK;
#endif

  /* Hopefully Address Space Layout Randomization gives us some additional
     randomness. */
  seed ^= PTR2UV(&get_seeds_from_av);

  if (state)
    mts_seed32new(state, seed);
  else
    mt_seed32new(seed);

  return seed;
}

#ifdef SYS_getrandom
static inline int mrmt_getrandom(void *buf, size_t buflen, unsigned flags) {
#if defined(__GLIBC__) && ( __GLIBC__ > 2 || __GLIBC_MINOR__ > 24 )
  return getrandom(buf, buflen, flags);
#else
  return syscall(SYS_getrandom, buf, buflen, flags);
#endif
}
#endif

static inline uint32_t devseed(mt_state* state, bool want_goodseed) {
#ifdef SYS_getrandom
  uint32_t seed;
  unsigned flags = want_goodseed ? GRND_RANDOM : 0;
  while (mrmt_getrandom(&seed, sizeof(seed), flags) < 0) {}
  if (state)
    mts_seed32new(state, seed);
  else
    mt_seed32new(seed);
  return seed;
#else
  if (want_goodseed)
    return state ? mts_goodseed(state) : mt_goodseed();
  else
    return state ? mts_seed(state) : mt_seed();
#endif
}

static inline uint32_t fastseed(mt_state* state) {
#ifdef WIN32
  return timeseed(state);
#else
  return devseed(state, 0);
#endif
}

static inline uint32_t goodseed(mt_state* state) {
#ifdef WIN32
  return timeseed(state);
#else
  return devseed(state, 1);
#endif
}

static inline void bestseed(mt_state* state) {
#ifdef WIN32
  timeseed(state);
#else
  state ? mts_bestseed(state) : mt_bestseed();
#endif
}

static inline void seedfull(mt_state* state, AV* seeds) {
  uint32_t mt_seeds[MT_STATE_SIZE] = {0};

  get_seeds_from_av(seeds, mt_seeds);

  if (state)
    mts_seedfull(state, mt_seeds);
  else
    mt_seedfull(mt_seeds);
}

static inline uint32_t srand50c(mt_state* state, uint32_t* seed) {
  if (seed == NULL)
    return fastseed(state);

  if (state)
    mts_seed32new(state, (uint32_t)*seed);
  else
    mt_seed32new((uint32_t)*seed);

  return *seed;
}

static inline int2dbl rd_double(mt_state* state) {
  int2dbl i2d;

#if HAS_UINT64_T
  i2d.i64 = state ? mts_llrand(state) : mt_llrand();
#else
  if (state) {
    i2d.i32[0] = mts_lrand(state);
    i2d.i32[1] = mts_lrand(state);
  }
  else {
    i2d.i32[0] = mt_lrand();
    i2d.i32[1] = mt_lrand();
  }
#endif

  return i2d;
}

static SV* randstr(mt_state* state, size_t length) {
  size_t bufsize, i;
  int2dbl* buf;
  SV* retval;

  dTHX;

  if (length == 0)
    return newSVpvn("", 0);

  /* Make bufsize an integer multiple of I2D_SIZE */
  bufsize = length + ((-length) % I2D_SIZE);
  if (bufsize < length)
    return NULL;

  Newxc(buf, bufsize, char, int2dbl);
  if (!buf)
    return NULL;

  i = bufsize / I2D_SIZE;
  buf += i;
  do {
    *--buf = rd_double(state);
  } while (--i);

  retval = newSV(0);
  if (!retval) {
    Safefree(buf);
    return NULL;
  }

  sv_upgrade(retval, SVt_PV);
  SvCUR_set(retval, length);
  SvLEN_set(retval, bufsize);
  SvPV_set(retval, (char*)buf);
  SvPOK_only(retval);

  return retval;
}

static FILE* open_file_from_sv(SV* file_sv, char* mode, PerlIO** pio) {
  FILE* fh = NULL;

  dTHX;

  if (! SvOK(file_sv)) {
    /* file_sv is undef */
    warn("Filename or handle expected");
  }
  else if (SvROK(file_sv) && SvTYPE(SvRV(file_sv)) == SVt_PVGV) {
    /* file_sv is a Perl filehandle */
    *pio = IoIFP(sv_2io(file_sv));
    fh = PerlIO_exportFILE(*pio, NULL);
  }
  else {
    /* file_sv is a filename */
    fh = fopen(SvPV_nolen(file_sv), mode);
  }

  return fh;
}

static int savestate(mt_state* state, SV* file_sv) {
  PerlIO* pio = NULL;
  FILE* fh = NULL;
  int RETVAL = 0;

  dTHX;

  fh = open_file_from_sv(file_sv, "w", &pio);

  if (fh) {
    RETVAL = state ? mts_savestate(fh, state) : mt_savestate(fh);
    if (pio) {
      fflush(fh);
      PerlIO_releaseFILE(pio, fh);
    }
    else
      fclose(fh);
  }

  return RETVAL;
}

static int loadstate(mt_state* state, SV* file_sv) {
  PerlIO* pio = NULL;
  FILE* fh = NULL;
  int RETVAL = 0;

  dTHX;

  fh = open_file_from_sv(file_sv, "r", &pio);

  if (fh) {
    RETVAL = state ? mts_loadstate(fh, state) : mt_loadstate(fh);
    if (pio)
      PerlIO_releaseFILE(pio, fh);
    else
      fclose(fh);
  }

  return RETVAL;
}

static void set_state_from_sv(SV* sv_state, mt_state* state) {
  STRLEN len;

  dTHX;

  if (!SvPOK(sv_state))
    croak("State must be a string");

  len = SvCUR(sv_state);
  if (len != sizeof(mt_state))
    croak("Need exactly %d state bytes, not %d", sizeof(mt_state), len);

  *state = *(mt_state*)SvPV_nolen(sv_state);

  if (state->stateptr < 0 || state->stateptr > MT_STATE_SIZE) {
    warn("stateptr value %d outside valid range [0, %d], using 0 instead",
         state->stateptr, MT_STATE_SIZE);
    state->stateptr = 0;
  }
}


MODULE = Math::Random::MTwist		PACKAGE = Math::Random::MTwist

PROTOTYPES: ENABLE

mt_state*
new_state(char* CLASS)
  CODE:
    Newxz(RETVAL, 1, mt_state);
    if (RETVAL == NULL)
      croak("Could not allocate state memory");
  OUTPUT:
    RETVAL

void
DESTROY(mt_state* state)
  PPCODE:
    Safefree(state);

UV
seed32(mt_state* state, uint32_t seed)
  CODE:
    mts_seed32new(state, seed);
    RETVAL = seed;
  OUTPUT:
    RETVAL

UV
_seed32(uint32_t seed)
  CODE:
    mt_seed32new(seed);
    RETVAL = seed;
  OUTPUT:
    RETVAL

UV
srand(mt_state* state, uint32_t seed = 0)
  CODE:
    RETVAL = srand50c(state, items == 1 ? NULL : &seed);
  OUTPUT:
    RETVAL

UV
_srand(uint32_t seed = 0)
  CODE:
    RETVAL = srand50c(NULL, items == 0 ? NULL : &seed);
  OUTPUT:
    RETVAL

UV
timeseed(mt_state* state)

UV
_timeseed()
  CODE:
    RETVAL = timeseed(NULL);
  OUTPUT:
    RETVAL

UV
fastseed(mt_state* state)

UV
_fastseed()
  CODE:
    RETVAL = fastseed(NULL);
  OUTPUT:
    RETVAL

UV
goodseed(mt_state* state)

UV
_goodseed()
  CODE:
    RETVAL = goodseed(NULL);
  OUTPUT:
    RETVAL

void
bestseed(mt_state* state)

void
_bestseed()
  PPCODE:
    bestseed(NULL);

void
seedfull(mt_state* state, AV* seeds)
  PPCODE:
    seedfull(state, seeds);

void
_seedfull(AV* seeds)
  PPCODE:
    seedfull(NULL, seeds);

SV*
irand32(mt_state* state);
  ALIAS:
    irand64 = 1
    irand = 2
  CODE:
#if IVSIZE >= 8
    if (ix)
      RETVAL = newSVuv(mts_llrand(state));
#elif defined(UINT64_MAX)
    if (ix)
      RETVAL = svpv_uint64(mts_llrand(state));
#else
    if (ix == 1)
      XSRETURN_UNDEF;
#endif
    else
      RETVAL = newSVuv(state ? mts_lrand(state) : mt_lrand());
  OUTPUT:
    RETVAL

SV*
_irand32();
  ALIAS:
    _irand64 = 1
    _irand = 2
  CODE:
#if IVSIZE >= 8
    if (ix)
      RETVAL = newSVuv(mt_llrand());
#elif defined(UINT64_MAX)
    if (ix)
      RETVAL = svpv_uint64(mt_llrand());
#else
    if (ix == 1)
      XSRETURN_UNDEF;
#endif
    else
      RETVAL = newSVuv(mt_lrand());
  OUTPUT:
    RETVAL

SV*
irand128(mt_state* state);
  CODE:
#if IVSIZE >= 16
    RETVAL = newSVuv(mts_u128rand(state));
#elif MT_HAS_INT128
    RETVAL = svpv_uint128(mts_u128rand(state));
#else
    XSRETURN_UNDEF;
#endif
  OUTPUT:
    RETVAL

SV*
_irand128();
  CODE:
#if IVSIZE >= 16
    RETVAL = newSVuv(mt_u128rand());
#elif MT_HAS_INT128
    RETVAL = svpv_uint128(mt_u128rand());
#else
    XSRETURN_UNDEF;
#endif
  OUTPUT:
    RETVAL

NV
rand(mt_state* state, NV bound = 0)
  ALIAS:
    rand32 = 1
  CODE:
    if (NVMANTBITS <= 32 || ix)
      RETVAL = mts_drand(state);
    else
#if NVMANTBITS <= 64
      RETVAL = mts_ldrand(state);
#else
      RETVAL = mts_lldrand(state);
#endif
    if (bound)
      RETVAL *= bound;
  OUTPUT:
    RETVAL

NV
_rand(NV bound = 0)
  ALIAS:
    _rand32 = 1
  CODE:
    if (NVMANTBITS <= 32 || ix)
      RETVAL = mt_drand();
    else
#if NVMANTBITS <= 64
      RETVAL = mt_ldrand();
#else
      RETVAL = mt_lldrand();
#endif
    if (bound)
      RETVAL *= bound;
  OUTPUT:
    RETVAL

### Interestingly, randstr() is faster than rd_double(2).
SV*
randstr(mt_state* state, STRLEN length = I2D_SIZE)
  CODE:
    RETVAL = randstr(state, length);
  OUTPUT:
    RETVAL

SV*
_randstr(STRLEN length = I2D_SIZE)
  CODE:
    RETVAL = randstr(NULL, length);
  OUTPUT:
    RETVAL

#define RETURN_I2D(have_index) { \
  if (have_index) {              \
    switch(index) {              \
    case 0:                      \
      XSRETURN_NV(i2d.dbl);      \
    case 1:                      \
      if (IVSIZE >= 8)           \
        XSRETURN_UV(i2d.i64);    \
      else                       \
        XSRETURN_UNDEF;          \
    case 2:                      \
      XSRETURN_PVN(i2d.str, 8);  \
    default:                     \
      XSRETURN_UNDEF;            \
    }                            \
  }                              \
  else {                         \
    mPUSHn(i2d.dbl);             \
    if (GIMME_V == G_ARRAY) {    \
      EXTEND(SP, 2);             \
      if (IVSIZE >= 8)           \
        mPUSHu(i2d.i64);         \
      else                       \
        PUSHs(&PL_sv_undef);     \
      mPUSHp(i2d.str, 8);        \
    }                            \
  }                              \
}                                \

void
rd_double(mt_state* state, int index = 0)
  PREINIT:
    int2dbl i2d;
  PPCODE:
    i2d = rd_double(state);
    RETURN_I2D(items > 1);

void
_rd_double(int index = 0)
  PREINIT:
    int2dbl i2d;
  PPCODE:
    i2d = rd_double(NULL);
    RETURN_I2D(items != 0);

IV
rd_iuniform32(mt_state* state, IV lower, IV upper);
  ALIAS:
    rd_iuniform64 = 1
    rd_iuniform   = 2
  CODE:
#if IVSIZE >= 8
    if (ix)
      RETVAL = rds_liuniform(state, lower, upper);
#else
    if (ix == 1)
      XSRETURN_UNDEF;
#endif
    else
      RETVAL = rds_iuniform(state, (int32_t)lower, (int32_t)upper);
  OUTPUT:
    RETVAL

IV
_rd_iuniform32(IV lower, IV upper);
  ALIAS:
    _rd_iuniform64 = 1
    _rd_iuniform   = 2
  CODE:
#if IVSIZE >= 8
    if (ix)
      RETVAL = rd_liuniform(lower, upper);
#else
    if (ix == 1)
      XSRETURN_UNDEF;
#endif
    else
      RETVAL = rd_iuniform((int32_t)lower, (int32_t)upper);
  OUTPUT:
    RETVAL

NV
rd_uniform(mt_state* state, NV lower, NV upper);
  ALIAS:
    rd_luniform = 1
  CODE:
    RETVAL = (ix == 0) ? rds_uniform(state, lower, upper)
                       : rds_luniform(state, lower, upper);
  OUTPUT:
    RETVAL

NV
_rd_uniform(NV lower, NV upper);
  ALIAS:
    _rd_luniform = 1
  CODE:
    RETVAL = (ix == 0) ? rd_uniform(lower, upper)
                       : rd_luniform(lower, upper);
  OUTPUT:
    RETVAL

NV
rd_exponential(mt_state* state, NV mean)
  ALIAS:
    rd_lexponential = 1
  CODE:
    RETVAL = (ix == 0) ? rds_exponential(state, mean)
                       : rds_lexponential(state, mean);
  OUTPUT:
    RETVAL

NV
_rd_exponential(NV mean)
  ALIAS:
    _rd_lexponential = 1
  CODE:
    RETVAL = (ix == 0) ? rd_exponential(mean)
                       : rd_lexponential(mean);
  OUTPUT:
    RETVAL

NV
rd_erlang(mt_state* state, IV k, NV mean)
  ALIAS:
    rd_lerlang = 1
  CODE:
    RETVAL = (ix == 0) ? rds_erlang(state, k, mean)
                       : rds_lerlang(state, k, mean);
  OUTPUT:
    RETVAL

NV
_rd_erlang(int k, NV mean)
  ALIAS:
    _rd_lerlang = 1
  CODE:
    RETVAL = (ix == 0) ? rd_erlang(k, mean)
                       : rd_lerlang(k, mean);
  OUTPUT:
    RETVAL

NV
rd_weibull(mt_state* state, NV shape, NV scale)
  ALIAS:
    rd_lweibull = 1
    rd_lognormal = 2
    rd_llognormal = 3
  CODE:
    switch (ix) {
      case 0:  RETVAL = rds_weibull(state, shape, scale); break;
      case 1:  RETVAL = rds_lweibull(state, shape, scale); break;
      case 2:  RETVAL = rds_lognormal(state, shape, scale); break;
      default: RETVAL = rds_llognormal(state, shape, scale);
    }
  OUTPUT:
    RETVAL

NV
_rd_weibull(NV shape, NV scale)
  ALIAS:
    _rd_lweibull = 1
    _rd_lognormal = 2
    _rd_llognormal = 3
  CODE:
    switch (ix) {
      case 0:  RETVAL = rd_weibull(shape, scale); break;
      case 1:  RETVAL = rd_lweibull(shape, scale); break;
      case 2:  RETVAL = rd_lognormal(shape, scale); break;
      default: RETVAL = rd_llognormal(shape, scale);
    }
  OUTPUT:
    RETVAL

NV
rd_normal(mt_state* state, NV mean, NV sigma)
  ALIAS:
    rd_lnormal = 1
  CODE:
    RETVAL = (ix == 0) ? rds_normal(state, mean, sigma)
                       : rds_lnormal(state, mean, sigma);
  OUTPUT:
    RETVAL

NV
_rd_normal(NV mean, NV sigma)
  ALIAS:
    _rd_lnormal = 1
  CODE:
    RETVAL = (ix == 0) ? rd_normal(mean, sigma)
                       : rd_lnormal(mean, sigma);
  OUTPUT:
    RETVAL

NV
rd_triangular(mt_state* state, NV lower, NV upper, NV mode)
  ALIAS:
    rd_ltriangular = 1
  CODE:
    RETVAL = (ix == 0) ? rds_triangular(state, lower, upper, mode)
                       : rds_ltriangular(state, lower, upper, mode);
  OUTPUT:
    RETVAL

NV
_rd_triangular(NV lower, NV upper, NV mode)
  ALIAS:
    _rd_ltriangular = 1
  CODE:
    RETVAL = (ix == 0) ? rd_triangular(lower, upper, mode)
                       : rd_ltriangular(lower, upper, mode);
  OUTPUT:
    RETVAL

int
savestate(mt_state* state, SV* file_sv)

int
_savestate(SV* file_sv)
  CODE:
    RETVAL = savestate(NULL, file_sv);
  OUTPUT:
    RETVAL

int
loadstate(mt_state* state, SV* file_sv)

int
_loadstate(SV* file_sv)
  CODE:
    RETVAL = loadstate(NULL, file_sv);
  OUTPUT:
    RETVAL

SV*
getstate(mt_state* state)
  CODE:
    RETVAL = newSVpvn((char*)state, sizeof(mt_state));
  OUTPUT:
    RETVAL

SV*
_getstate()
  CODE:
    RETVAL = newSVpvn((char*)&mt_default_state, sizeof(mt_state));
  OUTPUT:
    RETVAL

void
setstate(mt_state* state, SV* sv_state)
  PPCODE:
    set_state_from_sv(sv_state, state);

void
_setstate(SV* sv_state)
  PPCODE:
    set_state_from_sv(sv_state, &mt_default_state);

BOOT:
{
  HV *stash;

  stash = gv_stashpv("Math::Random::MTwist", TRUE);
  newCONSTSUB(stash, "HAS_UINT64_T", newSViv(HAS_UINT64_T));
  newCONSTSUB(stash, "NVMANTBITS",   newSViv(NVMANTBITS));
}

# vim: set ts=2 sw=2 sts=2 expandtab:
