#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "mtwist/mtwist.c"
#include "mtwist/randistrs.c"

typedef union {
  double dbl;
  char str[8];
  uint32_t i32[2];
#ifdef UINT64_MAX
  uint64_t i64;
#endif
} int2dbl;

#define I2D_SIZE sizeof(int2dbl)

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
 * We calculate gettimeofday() in microseconds and use the lower 32 bit as the
 * seed.
 */
static uint32_t timeseed(mt_state* state) {
  I32 return_count;
  UV usecs;

  /* Who invented those silly cryptic macro names? */
  dTHX;
  dSP;

  PUSHMARK(SP);
  return_count = call_pv("Time::HiRes::gettimeofday", G_ARRAY);

  if (return_count != 2)
    croak("Time::HiRes::gettimeofday() returned %d instead of 2 values",
          return_count);

  SPAGAIN;
  usecs = POPu;
  usecs += POPu * 1000000;
  PUTBACK;

  if (state)
    mts_seed32new(state, usecs);
  else
    mt_seed32new(usecs);

  return usecs;
}

static inline uint32_t fastseed(mt_state* state) {
#ifdef WIN32
  return timeseed(state);
#else
  return state ? mts_seed(state) : mt_seed();
#endif
}

static inline uint32_t goodseed(mt_state* state) {
#ifdef WIN32
  return timeseed(state);
#else
  return state ? mts_goodseed(state) : mt_goodseed();
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
  uint32_t mt_seeds[MT_STATE_SIZE] = { 0 };

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
    mts_seed32new(state, *seed);
  else
    mt_seed32new(*seed);

  return *seed;
}

static inline int2dbl rd_double(mt_state* state) {
  int2dbl i2d;

#ifdef UINT64_MAX
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

static SV* randstr(mt_state* state, STRLEN length) {
  STRLEN bufsize;
  int2dbl *randbuf;
  SV* retval;

  dTHX;

  if (length == 0)
    return newSVpvn("", 0);

  /* Make bufsize an integer multiple of I2D_SIZE so that, if it's not, we
     don't need and extra memcpy() after the rd_double() loop. */
  bufsize = length;
  if (bufsize % I2D_SIZE) {
    /* The next line is the same as bufsize += I2D_SIZE - (bufsize % I2D_SIZE)
       (since bufsize is unsigned) but it's a bit faster, at least with gcc. */
    bufsize += (-bufsize) % I2D_SIZE;
    if (bufsize < length)
      return NULL;
  }

  retval = newSV(0);
  if (!retval)
    return NULL;

  SvUPGRADE(retval, SVt_PV);
  SvPOK_on(retval);
  SvCUR_set(retval, length);
  SvLEN_set(retval, bufsize);

  Newxc(randbuf, bufsize, char, int2dbl);
  if (!randbuf) {
    Safefree(retval);
    return NULL;
  }

  SvPV_set(retval, (char*)randbuf);

  /* Loads of preparatory code just for this tiny little loop! This sucks! */
  while (bufsize) {
    *(randbuf++) = rd_double(state);
    bufsize -= I2D_SIZE;
  }

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

uint32_t
seed32(mt_state* state, uint32_t seed)
  CODE:
    mts_seed32new(state, seed);
    RETVAL = seed;
  OUTPUT:
    RETVAL

uint32_t
_seed32(uint32_t seed)
  CODE:
    mt_seed32new(seed);
    RETVAL = seed;
  OUTPUT:
    RETVAL

uint32_t
srand(mt_state* state, uint32_t seed = 0)
  CODE:
    RETVAL = srand50c(state, items == 1 ? NULL : &seed);
  OUTPUT:
    RETVAL

uint32_t
_srand(uint32_t seed = 0)
  CODE:
    RETVAL = srand50c(NULL, items == 0 ? NULL : &seed);
  OUTPUT:
    RETVAL

uint32_t
timeseed(mt_state* state)

uint32_t
_timeseed()
  CODE:
    RETVAL = timeseed(NULL);
  OUTPUT:
    RETVAL

uint32_t
fastseed(mt_state* state)

uint32_t
_fastseed()
  CODE:
    RETVAL = fastseed(NULL);
  OUTPUT:
    RETVAL

uint32_t
goodseed(mt_state* state)

uint32_t
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

#if defined(UINT64_MAX)
uint64_t
irand(mt_state* state)
  ALIAS:
    irand64 = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = mts_llrand(state);
  OUTPUT:
    RETVAL

uint64_t
_irand()
  ALIAS:
    _irand64 = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = mt_llrand();
  OUTPUT:
    RETVAL

#else
uint32_t
irand(mt_state* state)
  ALIAS:
    irand64 = 1
  CODE:
    if (ix == 0)
      RETVAL = mts_lrand(state);
    else
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

uint32_t
_irand()
  ALIAS:
    _irand64 = 1
  CODE:
    if (ix == 0)
      RETVAL = mt_lrand(state);
    else
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

#endif

uint32_t
irand32(mt_state* state)
  CODE:
    RETVAL = mts_lrand(state);
  OUTPUT:
    RETVAL

uint32_t
_irand32()
  CODE:
    RETVAL = mt_lrand();
  OUTPUT:
    RETVAL

double
rand(mt_state* state, double bound = 0)
  ALIAS:
    rand32 = 1
  CODE:
    RETVAL = ix == 0 ? mts_ldrand(state) : mts_drand(state);
    if (bound)
      RETVAL *= bound;
  OUTPUT:
    RETVAL

double
_rand(double bound = 0)
  ALIAS:
    _rand32 = 1
  CODE:
    RETVAL = ix == 0 ? mt_ldrand() : mt_drand();
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
      if (sizeof(UV) >= 8)       \
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
      if (sizeof(UV) >= 8)       \
        mPUSHu(i2d.i64);         \
      else                       \
        PUSHs(&PL_sv_undef);     \
      mPUSHp(i2d.str, 8);        \
    }                            \
  }                              \
}                                \

void
rd_double(mt_state* state, int index = 0)
  INIT:
    int2dbl i2d;
  PPCODE:
    i2d = rd_double(state);
    RETURN_I2D(items > 1);

void
_rd_double(int index = 0)
  INIT:
    int2dbl i2d;
  PPCODE:
    i2d = rd_double(NULL);
    RETURN_I2D(items != 0);

double
rd_exponential(mt_state* state, double mean)
  ALIAS:
    rd_lexponential = 1
  CODE:
    RETVAL = (ix == 0) ? rds_exponential(state, mean)
                       : rds_lexponential(state, mean);
  OUTPUT:
    RETVAL

double
_rd_exponential(double mean)
  ALIAS:
    _rd_lexponential = 1
  CODE:
    RETVAL = (ix == 0) ? rd_exponential(mean)
                       : rd_lexponential(mean);
  OUTPUT:
    RETVAL

double
rd_erlang(mt_state* state, int k, double mean)
  ALIAS:
    rd_lerlang = 1
  CODE:
    RETVAL = (ix == 0) ? rds_erlang(state, k, mean)
                       : rds_lerlang(state, k, mean);
  OUTPUT:
    RETVAL

double
_rd_erlang(int k, double mean)
  ALIAS:
    _rd_lerlang = 1
  CODE:
    RETVAL = (ix == 0) ? rd_erlang(k, mean)
                       : rd_lerlang(k, mean);
  OUTPUT:
    RETVAL

double
rd_weibull(mt_state* state, double shape, double scale)
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

double
_rd_weibull(double shape, double scale)
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

double
rd_normal(mt_state* state, double mean, double sigma)
  ALIAS:
    rd_lnormal = 1
  CODE:
    RETVAL = (ix == 0) ? rds_normal(state, mean, sigma)
                       : rds_lnormal(state, mean, sigma);
  OUTPUT:
    RETVAL

double
_rd_normal(double mean, double sigma)
  ALIAS:
    _rd_lnormal = 1
  CODE:
    RETVAL = (ix == 0) ? rd_normal(mean, sigma)
                       : rd_lnormal(mean, sigma);
  OUTPUT:
    RETVAL

double
rd_triangular(mt_state* state, double lower, double upper, double mode)
  ALIAS:
    rd_ltriangular = 1
  CODE:
    RETVAL = (ix == 0) ? rds_triangular(state, lower, upper, mode)
                       : rds_ltriangular(state, lower, upper, mode);
  OUTPUT:
    RETVAL

double
_rd_triangular(double lower, double upper, double mode)
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
