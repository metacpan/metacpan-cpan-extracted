#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "simdjson_wrapper.h"

#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <float.h>
#include <inttypes.h>

#if defined(__BORLANDC__) || defined(_MSC_VER)
# define snprintf _snprintf // C compilers have this in stdio.h
#endif

// some old perls do not have this, try to make it work, no
// guarantees, though. if it breaks, you get to keep the pieces.
#ifndef UTF8_MAXBYTES
# define UTF8_MAXBYTES 13
#endif

// compatibility with perl <5.18
#ifndef HvNAMELEN_get
# define HvNAMELEN_get(hv) strlen (HvNAME (hv))
#endif
#ifndef HvNAMELEN
# define HvNAMELEN(hv) HvNAMELEN_get (hv)
#endif
#ifndef HvNAMEUTF8
# define HvNAMEUTF8(hv) 0
#endif

// three extra for rounding, sign, and end of string
#define IVUV_MAXCHARS (sizeof (UV) * CHAR_BIT * 28 / 93 + 3)

#define F_ASCII             0x00000001UL
#define F_LATIN1            0x00000002UL
#define F_UTF8              0x00000004UL
#define F_INDENT            0x00000008UL
#define F_CANONICAL         0x00000010UL
#define F_SPACE_BEFORE      0x00000020UL
#define F_SPACE_AFTER       0x00000040UL
#define F_ALLOW_NONREF      0x00000100UL
#define F_SHRINK            0x00000200UL
#define F_ALLOW_BLESSED     0x00000400UL
#define F_CONV_BLESSED      0x00000800UL
#define F_RELAXED           0x00001000UL
#define F_ALLOW_UNKNOWN     0x00002000UL
#define F_ALLOW_TAGS        0x00004000UL
#define F_HOOK              0x00008000UL // some hooks exist, so slow-path processing
#define F_USE_SIMDJSON      0x00010000UL
#define F_CORE_BOOLS        0x00020000UL
#define F_ENCODE_CORE_BOOLS 0x00040000UL

#define F_PRETTY    F_INDENT | F_SPACE_BEFORE | F_SPACE_AFTER

#define INIT_SIZE   64 // initial scalar size to be allocated
#define INDENT_STEP 3  // spaces per indentation level

#define SHORT_STRING_LEN 16384 // special-case strings of up to this size

#define DECODE_WANTS_OCTETS(json) ((json)->flags & F_UTF8)

#define SB do {
#define SE } while (0)

#if __GNUC__ >= 3
# define my_expect(expr,value)      __builtin_expect ((expr), (value))
# define INLINE                     static inline
#else
# define my_expect(expr,value)      (expr)
# define INLINE                     static
#endif

#define expect_false(expr) my_expect ((expr) != 0, 0)
#define expect_true(expr)  my_expect ((expr) != 0, 1)

#define IN_RANGE_INC(type,val,beg,end) \
  ((unsigned type)((unsigned type)(val) - (unsigned type)(beg)) \
  <= (unsigned type)((unsigned type)(end) - (unsigned type)(beg)))

#define ERR_NESTING_EXCEEDED "json text or perl structure exceeds maximum nesting level (max_depth set too low?)"

#ifdef USE_ITHREADS
# define JSON_STASH (expect_true (json_stash) ? json_stash : gv_stashpv ("JSON::SIMD", 1))
# define BOOL_STASH (expect_true (bool_stash) ? bool_stash : gv_stashpv ("Types::Serialiser::Boolean", 1))
# define GET_BOOL(value) (expect_true (bool_ ## value) ? bool_ ## value : get_bool ("Types::Serialiser::" # value))
#else
# define JSON_STASH json_stash
# define BOOL_STASH bool_stash
# define GET_BOOL(value) bool_ ## value
#endif

// the amount of HEs to allocate on the stack, when sorting keys
#define STACK_HES 64

static HV *json_stash, *bool_stash; // JSON::SIMD::, Types::Serialiser::Boolean::
static SV *bool_false, *bool_true;
static SV *sv_json;

enum {
  INCR_M_WS = 0, // initial whitespace skipping, must be 0
  INCR_M_TFN,    // inside true/false/null
  INCR_M_NUM,    // inside number
  INCR_M_STR,    // inside string
  INCR_M_BS,     // inside backslash
  INCR_M_C0,     // inside comment in initial whitespace sequence
  INCR_M_C1,     // inside comment in other places
  INCR_M_JSON    // outside anything, count nesting
};

#define INCR_DONE(json) ((json)->incr_nest <= 0 && (json)->incr_mode == INCR_M_JSON)

// main JSON struct definition moved to simdjson_wrapper.h
// typedef struct { ... } JSON;

INLINE void
json_init (JSON *json)
{
  static const JSON init = { F_ALLOW_NONREF|F_USE_SIMDJSON, 512 };

  *json = init;
}

/////////////////////////////////////////////////////////////////////////////
// utility functions

INLINE SV *
get_bool (const char *name)
{
  SV *sv = get_sv (name, 1);

  SvREADONLY_on (sv);
  SvREADONLY_on (SvRV (sv));

  return sv;
}

INLINE void
shrink (SV *sv)
{
  sv_utf8_downgrade (sv, 1);

  if (SvLEN (sv) > SvCUR (sv) + 1)
    {
#ifdef SvPV_shrink_to_cur
      SvPV_shrink_to_cur (sv);
#elif defined (SvPV_renew)
      SvPV_renew (sv, SvCUR (sv) + 1);
#endif
    }
}

/* adds two STRLENs together, slow, and with paranoia */
static STRLEN
strlen_sum (STRLEN l1, STRLEN l2)
{
  size_t sum = l1 + l2;

  if (sum < (size_t)l2 || sum != (size_t)(STRLEN)sum)
    croak ("JSON::SIMD: string size overflow");

  return sum;
}

/* similar to SvGROW, but somewhat safer and guarantees exponential realloc strategy */
static char *
json_sv_grow (SV *sv, size_t len1, size_t len2)
{
  len1 = strlen_sum (len1, len2);
  len1 = strlen_sum (len1, len1 >> 1);

  if (len1 > 4096 - 24)
    len1 = (len1 | 4095) - 24;

  return SvGROW (sv, len1);
}

// decode a utf-8 character and return it, or (UV)-1 in
// case of an error.
// we special-case "safe" characters from U+80 .. U+7FF,
// but use the very good perl function to parse anything else.
// note that we never call this function for a ascii codepoints
INLINE UV
decode_utf8 (unsigned char *s, STRLEN len, STRLEN *clen)
{
  if (expect_true (len >= 2
                   && IN_RANGE_INC (char, s[0], 0xc2, 0xdf)
                   && IN_RANGE_INC (char, s[1], 0x80, 0xbf)))
    {
      *clen = 2;
      return ((s[0] & 0x1f) << 6) | (s[1] & 0x3f);
    }
  else
    return utf8n_to_uvuni (s, len, clen, UTF8_CHECK_ONLY);
}

// likewise for encoding, also never called for ascii codepoints
// this function takes advantage of this fact, although current gccs
// seem to optimise the check for >= 0x80 away anyways
INLINE unsigned char *
encode_utf8 (unsigned char *s, UV ch)
{
  if      (expect_false (ch < 0x000080))
    *s++ = ch;
  else if (expect_true  (ch < 0x000800))
    *s++ = 0xc0 | ( ch >>  6),
    *s++ = 0x80 | ( ch        & 0x3f);
  else if (              ch < 0x010000)
    *s++ = 0xe0 | ( ch >> 12),
    *s++ = 0x80 | ((ch >>  6) & 0x3f),
    *s++ = 0x80 | ( ch        & 0x3f);
  else if (              ch < 0x110000)
    *s++ = 0xf0 | ( ch >> 18),
    *s++ = 0x80 | ((ch >> 12) & 0x3f),
    *s++ = 0x80 | ((ch >>  6) & 0x3f),
    *s++ = 0x80 | ( ch        & 0x3f);

  return s;
}

// convert offset pointer to character index, sv must be string
static STRLEN
ptr_to_index (SV *sv, char *offset)
{
  return SvUTF8 (sv)
         ? utf8_distance (offset, SvPVX (sv))
         : offset - SvPVX (sv);
}

/////////////////////////////////////////////////////////////////////////////
// fp hell

// scan a group of digits, and a trailing exponent
static void
json_atof_scan1 (const char *s, NV *accum, int *expo, int postdp, int maxdepth)
{
  UV  uaccum = 0;
  int eaccum = 0;

  // if we recurse too deep, skip all remaining digits
  // to avoid a stack overflow attack
  if (expect_false (--maxdepth <= 0))
    while (*s >= '0' && *s <= '9')
      ++s;

  for (;;)
    {
      U8 dig = *s - '0';

      if (expect_false (dig >= 10))
        {
          if (dig == (U8)('.' - '0'))
            {
              if (postdp)
                break;
              ++s;
              json_atof_scan1 (s, accum, expo, 1, maxdepth);
            }
          else if ((dig | ' ') == 'e' - '0')
            {
              int exp2 = 0;
              int neg  = 0;

              ++s;

              if (*s == '-')
                {
                  ++s;
                  neg = 1;
                }
              else if (*s == '+')
                ++s;

              while (*s >= '0' && *s <= '9')
                exp2 = exp2 * 10 + (*s++ - '0');

              *expo += neg ? -exp2 : exp2;
            }

          break;
        }

      ++s;

      uaccum = uaccum * 10 + dig;
      ++eaccum;

      // if we have too many digits, then recurse for more
      // we actually do this for rather few digits
      if (uaccum >= (UV_MAX - 9) / 10)
        {
          if (postdp) *expo -= eaccum;
          json_atof_scan1 (s, accum, expo, postdp, maxdepth);
          if (postdp) *expo += eaccum;

          break;
        }
    }

  // this relies greatly on the quality of the pow ()
  // implementation of the platform, but a good
  // implementation is hard to beat.
  // (IEEE 754 conformant ones are required to be exact)
  if (postdp) *expo -= eaccum;
  *accum += uaccum * Perl_pow (10., *expo);
  *expo += eaccum;
}

// not static because we call it from simdjson too
NV
json_atof (const char *s)
{
  NV accum = 0.;
  int expo = 0;
  int neg  = 0;

  if (*s == '-')
    {
      ++s;
      neg = 1;
    }

  // a recursion depth of ten gives us >>500 bits
  json_atof_scan1 (s, &accum, &expo, 0, 10);

  return neg ? -accum : accum;
}

// target of scalar reference is bool?  -1 == nope, 0 == false, 1 == true
static int
ref_bool_type (SV *sv)
{
  svtype svt = SvTYPE (sv);

  if (svt < SVt_PVAV)
    {
      STRLEN len = 0;
      char *pv = svt ? SvPV (sv, len) : 0;

      if (len == 1)
        if (*pv == '1')
          return 1;
        else if (*pv == '0')
          return 0;
    }

  return -1;
}

// returns whether scalar is not a reference in the sense of allow_nonref
static int
json_nonref (SV *scalar)
{
  if (!SvROK (scalar))
    return 1;

  scalar = SvRV (scalar);

  if (SvTYPE (scalar) >= SVt_PVMG)
    {
      if (SvSTASH (scalar) == bool_stash)
        return 1;

      if (!SvOBJECT (scalar) && ref_bool_type (scalar) >= 0)
        return 1;
    }

  return 0;
}

/////////////////////////////////////////////////////////////////////////////
// encoder

// structure used for encoding JSON
typedef struct
{
  char *cur;  // SvPVX (sv) + current output position
  char *end;  // SvEND (sv)
  SV *sv;     // result scalar
  JSON json;
  U32 indent; // indentation level
  UV limit;   // escape character values >= this value when encoding
} enc_t;

INLINE void
need (enc_t *enc, STRLEN len)
{
  if (expect_false ((uintptr_t)(enc->end - enc->cur) < len))
    {
      STRLEN cur = enc->cur - (char *)SvPVX (enc->sv);
      char *buf = json_sv_grow (enc->sv, cur, len);
      enc->cur = buf + cur;
      enc->end = buf + SvLEN (enc->sv) - 1;
    }
}

INLINE void
encode_ch (enc_t *enc, char ch)
{
  need (enc, 1);
  *enc->cur++ = ch;
}

static void
encode_str (enc_t *enc, char *str, STRLEN len, int is_utf8)
{
  char *end = str + len;

  need (enc, len);

  while (str < end)
    {
      unsigned char ch = *(unsigned char *)str;

      if (expect_true (ch >= 0x20 && ch < 0x80)) // most common case
        {
          if (expect_false (ch == '"')) // but with slow exceptions
            {
              need (enc, len + 1);
              *enc->cur++ = '\\';
              *enc->cur++ = '"';
            }
          else if (expect_false (ch == '\\'))
            {
              need (enc, len + 1);
              *enc->cur++ = '\\';
              *enc->cur++ = '\\';
            }
          else
            *enc->cur++ = ch;

          ++str;
        }
      else
        {
          switch (ch)
            {
              case '\010': need (enc, len + 1); *enc->cur++ = '\\'; *enc->cur++ = 'b'; ++str; break;
              case '\011': need (enc, len + 1); *enc->cur++ = '\\'; *enc->cur++ = 't'; ++str; break;
              case '\012': need (enc, len + 1); *enc->cur++ = '\\'; *enc->cur++ = 'n'; ++str; break;
              case '\014': need (enc, len + 1); *enc->cur++ = '\\'; *enc->cur++ = 'f'; ++str; break;
              case '\015': need (enc, len + 1); *enc->cur++ = '\\'; *enc->cur++ = 'r'; ++str; break;

              default:
                {
                  STRLEN clen;
                  UV uch;

                  if (is_utf8)
                    {
                      uch = decode_utf8 (str, end - str, &clen);
                      if (clen == (STRLEN)-1)
                        croak ("malformed or illegal unicode character in string [%.11s], cannot convert to JSON", str);
                    }
                  else
                    {
                      uch = ch;
                      clen = 1;
                    }

                  if (uch < 0x80/*0x20*/ || uch >= enc->limit)
                    {
                      if (uch >= 0x10000UL)
                        {
                          if (uch >= 0x110000UL)
                            croak ("out of range codepoint (0x%lx) encountered, unrepresentable in JSON", (unsigned long)uch);

                          need (enc, len + 11);
                          sprintf (enc->cur, "\\u%04x\\u%04x",
                                   (int)((uch - 0x10000) / 0x400 + 0xD800),
                                   (int)((uch - 0x10000) % 0x400 + 0xDC00));
                          enc->cur += 12;
                        }
                      else
                        {
                          need (enc, len + 5);
                          *enc->cur++ = '\\';
                          *enc->cur++ = 'u';
                          *enc->cur++ = PL_hexdigit [ uch >> 12      ];
                          *enc->cur++ = PL_hexdigit [(uch >>  8) & 15];
                          *enc->cur++ = PL_hexdigit [(uch >>  4) & 15];
                          *enc->cur++ = PL_hexdigit [(uch >>  0) & 15];
                        }

                      str += clen;
                    }
                  else if (enc->json.flags & F_LATIN1)
                    {
                      *enc->cur++ = uch;
                      str += clen;
                    }
                  else if (is_utf8)
                    {
                      need (enc, len + clen);
                      do
                        {
                          *enc->cur++ = *str++;
                        }
                      while (--clen);
                    }
                  else
                    {
                      need (enc, len + UTF8_MAXBYTES - 1); // never more than 11 bytes needed
                      enc->cur = encode_utf8 (enc->cur, uch);
                      ++str;
                    }
                }
            }
        }

      --len;
    }
}

INLINE void
encode_indent (enc_t *enc)
{
  if (enc->json.flags & F_INDENT)
    {
      int spaces = enc->indent * INDENT_STEP;

      need (enc, spaces);
      memset (enc->cur, ' ', spaces);
      enc->cur += spaces;
    }
}

INLINE void
encode_space (enc_t *enc)
{
  need (enc, 1);
  encode_ch (enc, ' ');
}

INLINE void
encode_nl (enc_t *enc)
{
  if (enc->json.flags & F_INDENT)
    {
      need (enc, 1);
      encode_ch (enc, '\n');
    }
}

INLINE void
encode_comma (enc_t *enc)
{
  encode_ch (enc, ',');

  if (enc->json.flags & F_INDENT)
    encode_nl (enc);
  else if (enc->json.flags & F_SPACE_AFTER)
    encode_space (enc);
}

static void encode_sv (enc_t *enc, SV *sv);

static void
encode_av (enc_t *enc, AV *av)
{
  int i, len = av_len (av);

  if (enc->indent >= enc->json.max_depth)
    croak (ERR_NESTING_EXCEEDED);

  encode_ch (enc, '[');

  if (len >= 0)
    {
      encode_nl (enc); ++enc->indent;

      for (i = 0; i <= len; ++i)
        {
          SV **svp = av_fetch (av, i, 0);

          encode_indent (enc);

          if (svp)
            encode_sv (enc, *svp);
          else
            encode_str (enc, "null", 4, 0);

          if (i < len)
            encode_comma (enc);
        }

      encode_nl (enc); --enc->indent; encode_indent (enc);
    }

  encode_ch (enc, ']');
}

static void
encode_hk (enc_t *enc, HE *he)
{
  encode_ch (enc, '"');

  if (HeKLEN (he) == HEf_SVKEY)
    {
      SV *sv = HeSVKEY (he);
      STRLEN len;
      char *str;

      SvGETMAGIC (sv);
      str = SvPV (sv, len);

      encode_str (enc, str, len, SvUTF8 (sv));
    }
  else
    encode_str (enc, HeKEY (he), HeKLEN (he), HeKUTF8 (he));

  encode_ch (enc, '"');

  if (enc->json.flags & F_SPACE_BEFORE) encode_space (enc);
  encode_ch (enc, ':');
  if (enc->json.flags & F_SPACE_AFTER ) encode_space (enc);
}

// compare hash entries, used when all keys are bytestrings
static int
he_cmp_fast (const void *a_, const void *b_)
{
  int cmp;

  HE *a = *(HE **)a_;
  HE *b = *(HE **)b_;

  STRLEN la = HeKLEN (a);
  STRLEN lb = HeKLEN (b);

  if (!(cmp = memcmp (HeKEY (b), HeKEY (a), lb < la ? lb : la)))
    cmp = lb - la;

  return cmp;
}

// compare hash entries, used when some keys are sv's or utf-x
static int
he_cmp_slow (const void *a, const void *b)
{
  return sv_cmp (HeSVKEY_force (*(HE **)b), HeSVKEY_force (*(HE **)a));
}

static void
encode_hv (enc_t *enc, HV *hv)
{
  HE *he;

  if (enc->indent >= enc->json.max_depth)
    croak (ERR_NESTING_EXCEEDED);

  encode_ch (enc, '{');

  // for canonical output we have to sort by keys first
  // actually, this is mostly due to the stupid so-called
  // security workaround added somewhere in 5.8.x
  // that randomises hash orderings
  if (enc->json.flags & F_CANONICAL && !SvRMAGICAL (hv))
    {
      int count = hv_iterinit (hv);

      if (SvMAGICAL (hv))
        {
          // need to count by iterating. could improve by dynamically building the vector below
          // but I don't care for the speed of this special case.
          // note also that we will run into undefined behaviour when the two iterations
          // do not result in the same count, something I might care for in some later release.

          count = 0;
          while (hv_iternext (hv))
            ++count;

          hv_iterinit (hv);
        }

      if (count)
        {
          int i, fast = 1;
          HE *hes_stack [STACK_HES];
          HE **hes = hes_stack;

          // allocate larger arrays on the heap
          if (count > STACK_HES)
            {
              SV *sv = sv_2mortal (NEWSV (0, count * sizeof (*hes)));
              hes = (HE **)SvPVX (sv);
            }

          i = 0;
          while ((he = hv_iternext (hv)))
            {
              hes [i++] = he;
              if (HeKLEN (he) < 0 || HeKUTF8 (he))
                fast = 0;
            }

          assert (i == count);

          if (fast)
            qsort (hes, count, sizeof (HE *), he_cmp_fast);
          else
            {
              // hack to forcefully disable "use bytes"
              COP cop = *PL_curcop;
              cop.op_private = 0;

              ENTER;
              SAVETMPS;

              SAVEVPTR (PL_curcop);
              PL_curcop = &cop;

              qsort (hes, count, sizeof (HE *), he_cmp_slow);

              FREETMPS;
              LEAVE;
            }

          encode_nl (enc); ++enc->indent;

          while (count--)
            {
              encode_indent (enc);
              he = hes [count];
              encode_hk (enc, he);
              encode_sv (enc, expect_false (SvMAGICAL (hv)) ? hv_iterval (hv, he) : HeVAL (he));

              if (count)
                encode_comma (enc);
            }

          encode_nl (enc); --enc->indent; encode_indent (enc);
        }
    }
  else
    {
      if (hv_iterinit (hv) || SvMAGICAL (hv))
        if ((he = hv_iternext (hv)))
          {
            encode_nl (enc); ++enc->indent;

            for (;;)
              {
                encode_indent (enc);
                encode_hk (enc, he);
                encode_sv (enc, expect_false (SvMAGICAL (hv)) ? hv_iterval (hv, he) : HeVAL (he));

                if (!(he = hv_iternext (hv)))
                  break;

                encode_comma (enc);
              }

            encode_nl (enc); --enc->indent; encode_indent (enc);
          }
    }

  encode_ch (enc, '}');
}

// encode objects, arrays and special \0=false and \1=true values.
static void
encode_rv (enc_t *enc, SV *sv)
{
  svtype svt;
  GV *method;

  SvGETMAGIC (sv);
  svt = SvTYPE (sv);

  if (expect_false (SvOBJECT (sv)))
    {
      HV *stash = SvSTASH (sv);

      if (stash == bool_stash)
        {
          if (SvIV (sv)) encode_str (enc, "true" , 4, 0);
          else           encode_str (enc, "false", 5, 0);
        }
      else if ((enc->json.flags & F_ALLOW_TAGS) && (method = gv_fetchmethod_autoload (stash, "FREEZE", 0)))
        {
          int count;
          dSP;

          ENTER; SAVETMPS;
          PUSHMARK (SP);
          EXTEND (SP, 2);
          // we re-bless the reference to get overload and other niceties right
          PUSHs (sv_bless (sv_2mortal (newRV_inc (sv)), stash));
          PUSHs (sv_json);

          PUTBACK;
          count = call_sv ((SV *)GvCV (method), G_LIST);
          SPAGAIN;

          // catch this surprisingly common error
          if (SvROK (TOPs) && SvRV (TOPs) == sv)
            croak ("%s::FREEZE method returned same object as was passed instead of a new one", HvNAME (SvSTASH (sv)));

          encode_ch (enc, '(');
          encode_ch (enc, '"');
          encode_str (enc, HvNAME (stash), HvNAMELEN (stash), HvNAMEUTF8 (stash));
          encode_ch (enc, '"');
          encode_ch (enc, ')');
          encode_ch (enc, '[');

          if (count)
            {
              int i;

              for (i = 0; i < count - 1; ++i)
                {
                  encode_sv (enc, SP[i + 1 - count]);
                  encode_ch (enc, ',');
                }

              encode_sv (enc, TOPs);
              SP -= count;
            }

          PUTBACK;

          encode_ch (enc, ']');

          FREETMPS; LEAVE;
        }
      else if ((enc->json.flags & F_CONV_BLESSED) && (method = gv_fetchmethod_autoload (stash, "TO_JSON", 0)))
        {
          dSP;

          ENTER; SAVETMPS;
          PUSHMARK (SP);
          // we re-bless the reference to get overload and other niceties right
          XPUSHs (sv_bless (sv_2mortal (newRV_inc (sv)), stash));

          // calling with G_SCALAR ensures that we always get a 1 return value
          PUTBACK;
          call_sv ((SV *)GvCV (method), G_SCALAR);
          SPAGAIN;

          // catch this surprisingly common error
          if (SvROK (TOPs) && SvRV (TOPs) == sv)
            croak ("%s::TO_JSON method returned same object as was passed instead of a new one", HvNAME (SvSTASH (sv)));

          sv = POPs;
          PUTBACK;

          encode_sv (enc, sv);

          FREETMPS; LEAVE;
        }
      else if (enc->json.flags & F_ALLOW_BLESSED)
        encode_str (enc, "null", 4, 0);
      else
        croak ("encountered object '%s', but neither allow_blessed, convert_blessed nor allow_tags settings are enabled (or TO_JSON/FREEZE method missing)",
               SvPV_nolen (sv_2mortal (newRV_inc (sv))));
    }
  else if (svt == SVt_PVHV)
    encode_hv (enc, (HV *)sv);
  else if (svt == SVt_PVAV)
    encode_av (enc, (AV *)sv);
  else if (svt < SVt_PVAV)
    {
      int bool_type = ref_bool_type (sv);

      if (bool_type == 1)
        encode_str (enc, "true", 4, 0);
      else if (bool_type == 0)
        encode_str (enc, "false", 5, 0);
      else if (enc->json.flags & F_ALLOW_UNKNOWN)
        encode_str (enc, "null", 4, 0);
      else
        croak ("cannot encode reference to scalar '%s' unless the scalar is 0 or 1",
               SvPV_nolen (sv_2mortal (newRV_inc (sv))));
    }
  else if (enc->json.flags & F_ALLOW_UNKNOWN)
    encode_str (enc, "null", 4, 0);
  else
    croak ("encountered %s, but JSON can only represent references to arrays or hashes",
           SvPV_nolen (sv_2mortal (newRV_inc (sv))));
}

static void
encode_sv (enc_t *enc, SV *sv)
{
  SvGETMAGIC (sv);

#if PERL_VERSION_GE(5,36,0)
  if (enc->json.flags & F_ENCODE_CORE_BOOLS && SvIsBOOL (sv))
    {
      if (SvTRUE_nomg_NN (sv))
        encode_str (enc, "true", 4, 0);
      else
        encode_str (enc, "false", 5, 0);
    }
  else /* continues after the endif! */
#endif
  if (SvPOKp (sv))
    {
      STRLEN len;
      char *str = SvPV (sv, len);
      encode_ch (enc, '"');
      encode_str (enc, str, len, SvUTF8 (sv));
      encode_ch (enc, '"');
    }
  else if (SvNOKp (sv))
    {
      // trust that perl will do the right thing w.r.t. JSON syntax.
      need (enc, NV_DIG + 32);
#ifdef USE_QUADMATH
      quadmath_snprintf(enc->cur, enc->end - enc->cur, "%.*Qg", (int)NV_DIG, SvNVX(sv));
#else
      Gconvert (SvNVX (sv), NV_DIG, 0, enc->cur);
#endif
      enc->cur += strlen (enc->cur);
    }
  else if (SvIOKp (sv))
    {
      // we assume we can always read an IV as a UV and vice versa
      // we assume two's complement
      // we assume no aliasing issues in the union
      if (SvIsUV (sv) ? SvUVX (sv) <= 59000
                      : SvIVX (sv) <= 59000 && SvIVX (sv) >= -59000)
        {
          // optimise the "small number case"
          // code will likely be branchless and use only a single multiplication
          // works for numbers up to 59074
          I32 i = SvIVX (sv);
          U32 u;
          char digit, nz = 0;

          need (enc, 6);

          *enc->cur = '-'; enc->cur += i < 0 ? 1 : 0;
          u = i < 0 ? -i : i;

          // convert to 4.28 fixed-point representation
          u = u * ((0xfffffff + 10000) / 10000); // 10**5, 5 fractional digits

          // now output digit by digit, each time masking out the integer part
          // and multiplying by 5 while moving the decimal point one to the right,
          // resulting in a net multiplication by 10.
          // we always write the digit to memory but conditionally increment
          // the pointer, to enable the use of conditional move instructions.
          digit = u >> 28; *enc->cur = digit + '0'; enc->cur += (nz = nz || digit); u = (u & 0xfffffffUL) * 5;
          digit = u >> 27; *enc->cur = digit + '0'; enc->cur += (nz = nz || digit); u = (u & 0x7ffffffUL) * 5;
          digit = u >> 26; *enc->cur = digit + '0'; enc->cur += (nz = nz || digit); u = (u & 0x3ffffffUL) * 5;
          digit = u >> 25; *enc->cur = digit + '0'; enc->cur += (nz = nz || digit); u = (u & 0x1ffffffUL) * 5;
          digit = u >> 24; *enc->cur = digit + '0'; enc->cur += 1; // correctly generate '0'
        }
      else
        {
          // large integer, use the (rather slow) snprintf way.
          need (enc, IVUV_MAXCHARS);
          enc->cur +=
             SvIsUV(sv)
                ? snprintf (enc->cur, IVUV_MAXCHARS, "%"UVuf, (UV)SvUVX (sv))
                : snprintf (enc->cur, IVUV_MAXCHARS, "%"IVdf, (IV)SvIVX (sv));
        }
    }
  else if (SvROK (sv))
    encode_rv (enc, SvRV (sv));
  else if (!SvOK (sv) || enc->json.flags & F_ALLOW_UNKNOWN)
    encode_str (enc, "null", 4, 0);
  else
    croak ("encountered perl type (%s,0x%x) that JSON cannot handle, check your input data",
           SvPV_nolen (sv), (unsigned int)SvFLAGS (sv));
}

static SV *
encode_json (SV *scalar, JSON *json)
{
  enc_t enc;

  if (!(json->flags & F_ALLOW_NONREF) && json_nonref (scalar))
    croak ("hash- or arrayref expected (not a simple scalar, use allow_nonref to allow this)");

  enc.json      = *json;
  enc.sv        = sv_2mortal (NEWSV (0, INIT_SIZE));
  enc.cur       = SvPVX (enc.sv);
  enc.end       = SvEND (enc.sv);
  enc.indent    = 0;
  enc.limit     = enc.json.flags & F_ASCII  ? 0x000080UL
                : enc.json.flags & F_LATIN1 ? 0x000100UL
                                            : 0x110000UL;

  SvPOK_only (enc.sv);
  encode_sv (&enc, scalar);
  encode_nl (&enc);

  SvCUR_set (enc.sv, enc.cur - SvPVX (enc.sv));
  *SvEND (enc.sv) = 0; // many xs functions expect a trailing 0 for text strings

  if (!(enc.json.flags & (F_ASCII | F_LATIN1 | F_UTF8)))
    SvUTF8_on (enc.sv);

  if (enc.json.flags & F_SHRINK)
    shrink (enc.sv);

  return enc.sv;
}

/////////////////////////////////////////////////////////////////////////////
// decoder

// structure used for decoding JSON
// -- moved to simdjson_wrapper.h
// typedef struct { ... } dec_t;

static SV *
emulate_at_pointer (SV *sv, SV *path)
{
  if (!path ) {
    return sv;
  }

  SvUPGRADE (path, SVt_PV);
  sv_utf8_upgrade (path);

  char *orig = SvPVX(path);
  size_t len = SvCUR(path);
  SvGROW(path, SvCUR (path) + 1); // should basically be a NOP
  orig[len+1] = '\0';

  // empty path allowed (for scalars and , addresses the entire document
  if (len == 0) {
    return sv;
  }

  if (!SvROK(sv)) {
    croak("only the empty path is allowed for scalar documents");
  }

  if (orig[0] != '/') {
    croak("INVALID_JSON_POINTER: Invalid JSON pointer syntax");
  }
  orig++;

  char *key;
  Newx(key, len, char);

  char *err;
  char done = 0;
  while (!done) {
    svtype reftype = SvTYPE(SvRV(sv));
    char *p = key;
    char got_key = 0;

    memset(key, 0, len);

    while (!got_key) {
      switch (*orig) {
        case '~':
          orig++;
          if (*orig == '0') {
            *p++ = '~';
          } else if (*orig == '1') {
            *p++ = '/';
          } else {
            err = "INVALID_JSON_POINTER: Invalid JSON pointer syntax";
            goto emulate_fail;
          }
          orig++;
          break;
        case '/':
          got_key = 1;
          orig++;
          break;
        case '\0':
          done = 1;
          got_key = 1;
          break;
        default:
          *p++ = *orig++;
      }
    }
    
    if (reftype == SVt_PVAV) {
      if (p == key || (p - key > 1 && key[0] == '0')) {
        // empty string and numbers prefixed with 0 are not valid for arrays
        err = "INVALID_JSON_POINTER: Invalid JSON pointer syntax";
        goto emulate_fail;
      } else if (p - key == 1 && key[0] == '-') {
        // - means "the append position" or "the element after the end of the array"
        // We don't support this, because we're returning a real element, not a position.
        err = "INDEX_OUT_OF_BOUNDS: Attempted to access an element of a JSON array that is beyond its length";
        goto emulate_fail;
      }

      UV idx;
      int res = grok_number(key, p-key, &idx);

      if (!(res & IS_NUMBER_IN_UV) || res & (IS_NUMBER_GREATER_THAN_UV_MAX|IS_NUMBER_NOT_INT|IS_NUMBER_NEG|IS_NUMBER_INFINITY|IS_NUMBER_NAN)) {
        err = "INCORRECT_TYPE: The JSON element does not have the requested type";
        goto emulate_fail;
      }

      AV *av = (AV*) SvRV(sv);
      SSize_t last_idx = AvFILL(av);
      if (idx > last_idx) {
        err = "INDEX_OUT_OF_BOUNDS: Attempted to access an element of a JSON array that is beyond its length";
        goto emulate_fail;
      }

      SV **elem = av_fetch(av, idx, 0);
      if (elem && *elem) {
        sv = *elem;
      } else {
        // ?
        err = "INDEX_OUT_OF_BOUNDS: Attempted to access an element of a JSON array that is beyond its length";
        goto emulate_fail;
      }
    } else if (reftype == SVt_PVHV) {
      // TODO unicode keys?
      SV **elem = hv_fetch((HV*) SvRV(sv), key, -(p-key), 0);
      if (elem && *elem) {
        sv = *elem;
      } else {
        err = "NO_SUCH_FIELD: The JSON field referenced does not exist in this object";
        goto emulate_fail;
      }
    }
  } 

  Safefree(key);
  return sv;

emulate_fail:
  Safefree(key);
  croak("%s", err);
}

INLINE void
decode_comment (dec_t *dec)
{
  // only '#'-style comments allowed a.t.m.

  while (*dec->cur && *dec->cur != 0x0a && *dec->cur != 0x0d)
    ++dec->cur;
}

INLINE void
decode_ws (dec_t *dec)
{
  for (;;)
    {
      char ch = *dec->cur;

      if (ch > 0x20)
        {
          if (expect_false (ch == '#'))
            {
              if (dec->json.flags & F_RELAXED)
                decode_comment (dec);
              else
                break;
            }
          else
            break;
        }
      else if (ch != 0x20 && ch != 0x0a && ch != 0x0d && ch != 0x09)
        break; // parse error, but let higher level handle it, gives better error messages
      else
        ++dec->cur;
    }
}

#define ERR(reason) SB dec->err = reason; goto fail; SE

#define EXPECT_CH(ch) SB \
  if (*dec->cur != ch)		\
    ERR (# ch " expected");	\
  ++dec->cur;			\
  SE

#define DEC_INC_DEPTH if (++dec->depth > dec->json.max_depth) ERR (ERR_NESTING_EXCEEDED)
#define DEC_DEC_DEPTH --dec->depth

static SV *decode_sv (dec_t *dec);

static signed char decode_hexdigit[256];

static UV
decode_4hex (dec_t *dec)
{
  signed char d1, d2, d3, d4;
  unsigned char *cur = (unsigned char *)dec->cur;

  d1 = decode_hexdigit [cur [0]]; if (expect_false (d1 < 0)) ERR ("exactly four hexadecimal digits expected");
  d2 = decode_hexdigit [cur [1]]; if (expect_false (d2 < 0)) ERR ("exactly four hexadecimal digits expected");
  d3 = decode_hexdigit [cur [2]]; if (expect_false (d3 < 0)) ERR ("exactly four hexadecimal digits expected");
  d4 = decode_hexdigit [cur [3]]; if (expect_false (d4 < 0)) ERR ("exactly four hexadecimal digits expected");

  dec->cur += 4;

  return ((UV)d1) << 12
       | ((UV)d2) <<  8
       | ((UV)d3) <<  4
       | ((UV)d4);

fail:
  return (UV)-1;
}

static SV *
decode_str (dec_t *dec)
{
  SV *sv = 0;
  int utf8 = 0;
  char *dec_cur = dec->cur;

  do
    {
      char buf [SHORT_STRING_LEN + UTF8_MAXBYTES];
      char *cur = buf;

      do
        {
          unsigned char ch = *(unsigned char *)dec_cur++;

          if (expect_false (ch == '"'))
            {
              --dec_cur;
              break;
            }
          else if (expect_false (ch == '\\'))
            {
              switch (*dec_cur)
                {
                  case '\\':
                  case '/':
                  case '"': *cur++ = *dec_cur++; break;

                  case 'b': ++dec_cur; *cur++ = '\010'; break;
                  case 't': ++dec_cur; *cur++ = '\011'; break;
                  case 'n': ++dec_cur; *cur++ = '\012'; break;
                  case 'f': ++dec_cur; *cur++ = '\014'; break;
                  case 'r': ++dec_cur; *cur++ = '\015'; break;

                  case 'u':
                    {
                      UV lo, hi;
                      ++dec_cur;

                      dec->cur = dec_cur;
                      hi = decode_4hex (dec);
                      dec_cur = dec->cur;
                      if (hi == (UV)-1)
                        goto fail;

                      // possibly a surrogate pair
                      if (hi >= 0xd800)
                        if (hi < 0xdc00)
                          {
                            if (dec_cur [0] != '\\' || dec_cur [1] != 'u')
                              ERR ("missing low surrogate character in surrogate pair");

                            dec_cur += 2;

                            dec->cur = dec_cur;
                            lo = decode_4hex (dec);
                            dec_cur = dec->cur;
                            if (lo == (UV)-1)
                              goto fail;

                            if (lo < 0xdc00 || lo >= 0xe000)
                              ERR ("surrogate pair expected");

                            hi = (hi - 0xD800) * 0x400 + (lo - 0xDC00) + 0x10000;
                          }
                        else if (hi < 0xe000)
                          ERR ("missing high surrogate character in surrogate pair");

                      if (hi >= 0x80)
                        {
                          utf8 = 1;

                          cur = encode_utf8 (cur, hi);
                        }
                      else
                        *cur++ = hi;
                    }
                    break;

                  default:
                    --dec_cur;
                    ERR ("illegal backslash escape sequence in string");
                }
            }
          else if (expect_true (ch >= 0x20 && ch < 0x80))
            *cur++ = ch;
          else if (ch >= 0x80)
            {
              STRLEN clen;

              --dec_cur;

              decode_utf8 (dec_cur, dec->end - dec_cur, &clen);
              if (clen == (STRLEN)-1)
                ERR ("malformed UTF-8 character in JSON string");

              do
                *cur++ = *dec_cur++;
              while (--clen);

              utf8 = 1;
            }
          else if (ch == '\t' && dec->json.flags & F_RELAXED)
            *cur++ = ch;
          else
            {
              --dec_cur;

              if (!ch)
                ERR ("unexpected end of string while parsing JSON string");
              else
                ERR ("invalid character encountered while parsing JSON string");
            }
        }
      while (cur < buf + SHORT_STRING_LEN);

      {
        STRLEN len = cur - buf;

        if (sv)
          {
            STRLEN cur = SvCUR (sv);

            if (SvLEN (sv) - cur <= len)
              json_sv_grow (sv, cur, len);

            memcpy (SvPVX (sv) + SvCUR (sv), buf, len);
            SvCUR_set (sv, SvCUR (sv) + len);
          }
        else
          sv = newSVpvn (buf, len);
      }
    }
  while (*dec_cur != '"');

  ++dec_cur;

  if (sv)
    {
      SvPOK_only (sv);
      *SvEND (sv) = 0;

      if (utf8)
        SvUTF8_on (sv);
    }
  else
    sv = newSVpvn ("", 0);

  dec->cur = dec_cur;
  return sv;

fail:
  dec->cur = dec_cur;
  return 0;
}

static SV *
decode_num (dec_t *dec)
{
  int is_nv = 0;
  char *start = dec->cur;

  // [minus]
  if (*dec->cur == '-')
    ++dec->cur;

  if (*dec->cur == '0')
    {
      ++dec->cur;
      if (*dec->cur >= '0' && *dec->cur <= '9')
         ERR ("malformed number (leading zero must not be followed by another digit)");
    }
  else if (*dec->cur < '0' || *dec->cur > '9')
    ERR ("malformed number (no digits after initial minus)");
  else
    do
      {
        ++dec->cur;
      }
    while (*dec->cur >= '0' && *dec->cur <= '9');

  // [frac]
  if (*dec->cur == '.')
    {
      ++dec->cur;

      if (*dec->cur < '0' || *dec->cur > '9')
        ERR ("malformed number (no digits after decimal point)");

      do
        {
          ++dec->cur;
        }
      while (*dec->cur >= '0' && *dec->cur <= '9');

      is_nv = 1;
    }

  // [exp]
  if (*dec->cur == 'e' || *dec->cur == 'E')
    {
      ++dec->cur;

      if (*dec->cur == '-' || *dec->cur == '+')
        ++dec->cur;

      if (*dec->cur < '0' || *dec->cur > '9')
        ERR ("malformed number (no digits after exp sign)");

      do
        {
          ++dec->cur;
        }
      while (*dec->cur >= '0' && *dec->cur <= '9');

      is_nv = 1;
    }

  if (!is_nv)
    {
      int len = dec->cur - start;

      // special case the rather common 1..5-digit-int case
      if (*start == '-')
        switch (len)
          {
            case 2: return newSViv (-(IV)(                                                                          start [1] - '0' *     1));
            case 3: return newSViv (-(IV)(                                                         start [1] * 10 + start [2] - '0' *    11));
            case 4: return newSViv (-(IV)(                                       start [1] * 100 + start [2] * 10 + start [3] - '0' *   111));
            case 5: return newSViv (-(IV)(                    start [1] * 1000 + start [2] * 100 + start [3] * 10 + start [4] - '0' *  1111));
            case 6: return newSViv (-(IV)(start [1] * 10000 + start [2] * 1000 + start [3] * 100 + start [4] * 10 + start [5] - '0' * 11111));
          }
      else
        switch (len)
          {
            case 1: return newSViv (                                                                                start [0] - '0' *     1);
            case 2: return newSViv (                                                               start [0] * 10 + start [1] - '0' *    11);
            case 3: return newSViv (                                             start [0] * 100 + start [1] * 10 + start [2] - '0' *   111);
            case 4: return newSViv (                          start [0] * 1000 + start [1] * 100 + start [2] * 10 + start [3] - '0' *  1111);
            case 5: return newSViv (      start [0] * 10000 + start [1] * 1000 + start [2] * 100 + start [3] * 10 + start [4] - '0' * 11111);
          }

      {
        UV uv;
        int numtype = grok_number (start, len, &uv);
        if (numtype & IS_NUMBER_IN_UV)
          if (numtype & IS_NUMBER_NEG)
            {
              if (uv < (UV)IV_MIN)
                return newSViv (-(IV)uv);
            }
          else
            return newSVuv (uv);
      }

      len -= *start == '-' ? 1 : 0;

      // does not fit into IV or UV, try NV
      if (len <= NV_DIG)
        // fits into NV without loss of precision
        return newSVnv (json_atof (start));

      // everything else fails, convert it to a string
      return newSVpvn (start, dec->cur - start);
    }

  // loss of precision here
  return newSVnv (json_atof (start));

fail:
  return 0;
}

static SV *
decode_av (dec_t *dec)
{
  AV *av = newAV ();

  DEC_INC_DEPTH;
  decode_ws (dec);

  if (*dec->cur == ']')
    ++dec->cur;
  else
    for (;;)
      {
        SV *value;

        value = decode_sv (dec);
        if (!value)
          goto fail;

        av_push (av, value);

        decode_ws (dec);

        if (*dec->cur == ']')
          {
            ++dec->cur;
            break;
          }

        if (*dec->cur != ',')
          ERR (", or ] expected while parsing array");

        ++dec->cur;

        decode_ws (dec);

        if (*dec->cur == ']' && dec->json.flags & F_RELAXED)
          {
            ++dec->cur;
            break;
          }
      }

  DEC_DEC_DEPTH;
  return newRV_noinc ((SV *)av);

fail:
  SvREFCNT_dec (av);
  DEC_DEC_DEPTH;
  return 0;
}

// not static because we call it from simdjson too
SV *
filter_object (dec_t *dec, SV *sv, HV* hv)
{
  if (dec->json.cb_sk_object && HvKEYS (hv) == 1)
    {
      HE *cb, *he;

      hv_iterinit (hv);
      he = hv_iternext (hv);
      hv_iterinit (hv);

      // the next line creates a mortal sv each time it's called.
      // might want to optimise this for common cases.
      cb = hv_fetch_ent (dec->json.cb_sk_object, hv_iterkeysv (he), 0, 0);

      if (cb)
        {
          dSP;
          int count;

          ENTER; SAVETMPS;
          PUSHMARK (SP);
          XPUSHs (HeVAL (he));
          sv_2mortal (sv);

          PUTBACK; count = call_sv (HeVAL (cb), G_LIST); SPAGAIN;

          if (count == 1)
            {
              sv = newSVsv (POPs);
              PUTBACK;
              FREETMPS; LEAVE;
              return sv;
            }
          else if (count)
            croak ("filter_json_single_key_object callbacks must not return more than one scalar");

          PUTBACK;

          SvREFCNT_inc (sv);

          FREETMPS; LEAVE;
        }
    }

  if (dec->json.cb_object)
    {
      dSP;
      int count;

      ENTER; SAVETMPS;
      PUSHMARK (SP);
      XPUSHs (sv_2mortal (sv));

      PUTBACK; count = call_sv (dec->json.cb_object, G_LIST); SPAGAIN;

      if (count == 1)
        sv = newSVsv (POPs);
      else if (count == 0)
        SvREFCNT_inc (sv);
      else
        croak ("filter_json_object callbacks must not return more than one scalar");

      PUTBACK;

      FREETMPS; LEAVE;
    }
  return sv;
}

static SV *
decode_hv (dec_t *dec)
{
  SV *sv;
  HV *hv = newHV ();

  DEC_INC_DEPTH;
  decode_ws (dec);

  if (*dec->cur == '}')
    ++dec->cur;
  else
    for (;;)
      {
        EXPECT_CH ('"');

        // heuristic: assume that
        // a) decode_str + hv_store_ent are abysmally slow.
        // b) most hash keys are short, simple ascii text.
        // => try to "fast-match" such strings to avoid
        // the overhead of decode_str + hv_store_ent.
        {
          SV *value;
          char *p = dec->cur;
          char *e = p + 24; // only try up to 24 bytes

          for (;;)
            {
              // the >= 0x80 is false on most architectures
              if (p == e || *p < 0x20 || *p >= 0x80 || *p == '\\')
                {
                  // slow path, back up and use decode_str
                  SV *key = decode_str (dec);
                  if (!key)
                    goto fail;

                  decode_ws (dec); EXPECT_CH (':');

                  decode_ws (dec);
                  value = decode_sv (dec);
                  if (!value)
                    {
                      SvREFCNT_dec (key);
                      goto fail;
                    }

                  hv_store_ent (hv, key, value, 0);
                  SvREFCNT_dec (key);

                  break;
                }
              else if (*p == '"')
                {
                  // fast path, got a simple key
                  char *key = dec->cur;
                  int len = p - key;
                  dec->cur = p + 1;

                  decode_ws (dec); EXPECT_CH (':');

                  decode_ws (dec);
                  value = decode_sv (dec);
                  if (!value)
                    goto fail;

                  hv_store (hv, key, len, value, 0);

                  break;
                }

              ++p;
            }
        }

        decode_ws (dec);

        if (*dec->cur == '}')
          {
            ++dec->cur;
            break;
          }

        if (*dec->cur != ',')
          ERR (", or } expected while parsing object/hash");

        ++dec->cur;

        decode_ws (dec);

        if (*dec->cur == '}' && dec->json.flags & F_RELAXED)
          {
            ++dec->cur;
            break;
          }
      }

  DEC_DEC_DEPTH;
  sv = newRV_noinc ((SV *)hv);

  // check filter callbacks
  if (expect_false (dec->json.flags & F_HOOK))
    sv = filter_object(dec, sv, hv);

  return sv;

fail:
  SvREFCNT_dec (hv);
  DEC_DEC_DEPTH;
  return 0;
}

static SV *
decode_tag (dec_t *dec)
{
  SV *tag = 0;
  SV *val = 0;

  if (!(dec->json.flags & F_ALLOW_TAGS))
    ERR ("malformed JSON string, neither array, object, number, string or atom");

  ++dec->cur;

  decode_ws (dec);

  tag = decode_sv (dec);
  if (!tag)
    goto fail;

  if (!SvPOK (tag))
    ERR ("malformed JSON string, (tag) must be a string");

  decode_ws (dec);

  if (*dec->cur != ')')
    ERR (") expected after tag");

  ++dec->cur;

  decode_ws (dec);

  val = decode_sv (dec);
  if (!val)
    goto fail;

  if (!SvROK (val) || SvTYPE (SvRV (val)) != SVt_PVAV)
    ERR ("malformed JSON string, tag value must be an array");

  {
    AV *av = (AV *)SvRV (val);
    int i, len = av_len (av) + 1;
    HV *stash = gv_stashsv (tag, 0);
    SV *sv;

    if (!stash)
      ERR ("cannot decode perl-object (package does not exist)");

    GV *method = gv_fetchmethod_autoload (stash, "THAW", 0);
    
    if (!method)
      ERR ("cannot decode perl-object (package does not have a THAW method)");
    
    dSP;

    ENTER; SAVETMPS;
    PUSHMARK (SP);
    EXTEND (SP, len + 2);
    // we re-bless the reference to get overload and other niceties right
    PUSHs (tag);
    PUSHs (sv_json);

    for (i = 0; i < len; ++i)
      PUSHs (*av_fetch (av, i, 1));

    PUTBACK;
    call_sv ((SV *)GvCV (method), G_SCALAR);
    SPAGAIN;

    SvREFCNT_dec (tag);
    SvREFCNT_dec (val);
    sv = SvREFCNT_inc (POPs);

    PUTBACK;

    FREETMPS; LEAVE;

    return sv;
  }

fail:
  SvREFCNT_dec (tag);
  SvREFCNT_dec (val);
  return 0;
}

static SV *
decode_sv (dec_t *dec)
{
  // the beauty of JSON: you need exactly one character lookahead
  // to parse everything.
  switch (*dec->cur)
    {
      case '"': ++dec->cur; return decode_str (dec);
      case '[': ++dec->cur; return decode_av  (dec);
      case '{': ++dec->cur; return decode_hv  (dec);
      case '(':             return decode_tag (dec);

      case '-':
      case '0': case '1': case '2': case '3': case '4':
      case '5': case '6': case '7': case '8': case '9':
        return decode_num (dec);

      case 'f':
        if (dec->end - dec->cur >= 5 && !memcmp (dec->cur, "false", 5))
          {
            dec->cur += 5;

            if (expect_false (!dec->json.v_false))
              dec->json.v_false = GET_BOOL (false);

            return newSVsv (dec->json.v_false);
          }
        else
          ERR ("'false' expected");

        break;

      case 't':
        if (dec->end - dec->cur >= 4 && !memcmp (dec->cur, "true", 4))
          {
            dec->cur += 4;

            if (expect_false (!dec->json.v_true))
              dec->json.v_true = GET_BOOL (true);

            return newSVsv (dec->json.v_true);
          }
        else
          ERR ("'true' expected");

        break;

      case 'n':
        if (dec->end - dec->cur >= 4 && !memcmp (dec->cur, "null", 4))
          {
            dec->cur += 4;
            return newSVsv (&PL_sv_undef);
          }
        else
          ERR ("'null' expected");

        break;

      default:
        ERR ("malformed JSON string, neither tag, array, object, number, string or atom");
        break;
    }

fail:
  return 0;
}

static SV *
decode_json (SV *string, JSON *json, STRLEN *offset_return, SV* path)
{
  dec_t dec;
  SV *sv;

  /* work around bugs in 5.10 where manipulating magic values
   * makes perl ignore the magic in subsequent accesses.
   * also make a copy of non-PV values, to get them into a clean
   * state (SvPV should do that, but it's buggy, see below).
   *
   * SvIsCOW_shared_hash works around a bug in perl (possibly 5.16),
   * as reported by Reini Urban.
   */
  /*SvGETMAGIC (string);*/
  if (SvMAGICAL (string) || !SvPOK (string) || SvIsCOW_shared_hash (string))
    string = sv_2mortal (newSVsv (string));

  SvUPGRADE (string, SVt_PV);

  /* work around a bug in perl 5.10, which causes SvCUR to fail an
   * assertion with -DDEBUGGING, although SvCUR is documented to
   * return the xpv_cur field which certainly exists after upgrading.
   * according to nicholas clark, calling SvPOK fixes this.
   * But it doesn't fix it, so try another workaround, call SvPV_nolen
   * and hope for the best.
   * Damnit, SvPV_nolen still trips over yet another assertion. This
   * assertion business is seriously broken, try yet another workaround
   * for the broken -DDEBUGGING.
   */
  {
#ifdef DEBUGGING
    STRLEN offset = SvOK (string) ? sv_len (string) : 0;
#else
    STRLEN offset = SvCUR (string);
#endif

    if (offset > json->max_size && json->max_size)
      croak ("attempted decode of JSON text of %lu bytes size, but max_size is set to %lu",
             (unsigned long)SvCUR (string), (unsigned long)json->max_size);
  }

  if (DECODE_WANTS_OCTETS (json))
    sv_utf8_downgrade (string, 0);
  else
    sv_utf8_upgrade (string);

  SvGROW (string, SvCUR (string) + 1); // should basically be a NOP

  dec.json  = *json;
  dec.cur   = SvPVX (string);
  dec.end   = SvEND (string);
  dec.err   = 0;
  dec.depth = 0;

  if (dec.json.cb_object || dec.json.cb_sk_object)
    dec.json.flags |= F_HOOK;

  *dec.end = 0; // this should basically be a nop, too, but make sure it's there

  if (dec.json.flags & F_USE_SIMDJSON) {
    dec.error_code = 0;
    dec.input = string;
    dec.path = 0;

    // handle path
    if (path) {
      // repeat the voodoo above for the path argument too
      if (SvMAGICAL (path) || !SvPOK (path) || SvIsCOW_shared_hash (path))
        path = sv_2mortal (newSVsv (path));

      SvUPGRADE (path, SVt_PV);
      dec.path = SvPVX(path);
    }

    // we don't want to mess with this from the C++ code 
    if (expect_false (!dec.json.v_true))
      dec.json.v_true = GET_BOOL (true);
    if (expect_false (!dec.json.v_false))
      dec.json.v_false = GET_BOOL (false);

    sv = simdjson_decode(&dec);

    dec.end = SvEND(string);

  } else {
    decode_ws (&dec);
    sv = decode_sv (&dec);
  }

  if (offset_return)
    *offset_return = dec.cur - SvPVX (string);
  else if (sv && !path)
    {
      // check for trailing garbage
      if (!(dec.json.flags & F_USE_SIMDJSON)) // simdjson gobbles up trailing whitespace anyway
        decode_ws (&dec);
      if (dec.cur != dec.end)
        {
          dec.err = "garbage after JSON object";
          SvREFCNT_dec (sv);
          sv = 0;
        }
    }

  if (!sv)
    {
      SV *uni = sv_newmortal ();

      // horrible hack to silence warning inside pv_uni_display
      COP cop = *PL_curcop;
      cop.cop_warnings = pWARN_NONE;
      ENTER;
      SAVEVPTR (PL_curcop);
      PL_curcop = &cop;
      pv_uni_display (uni, dec.cur, dec.end - dec.cur, 20, UNI_DISPLAY_QQ);
      LEAVE;

      croak ("%s, at character offset %d (before \"%s\")",
             dec.err,
             (int)ptr_to_index (string, dec.cur),
             dec.cur != dec.end ? SvPV_nolen (uni) : "(end of string)");
    }

  sv = sv_2mortal (sv);

  if (!(dec.json.flags & F_ALLOW_NONREF) && json_nonref (sv))
    croak ("JSON text must be an object or array (but found number, string, true, false or null, use allow_nonref to allow this)");

  if (expect_false(path && !(dec.json.flags & F_USE_SIMDJSON))) {
    /* parse the path and derefer hash/array elements */
    sv = emulate_at_pointer(sv, path);
  }

  return sv;
}

/////////////////////////////////////////////////////////////////////////////
// incremental parser

static void
incr_parse (JSON *self)
{
  const char *p = SvPVX (self->incr_text) + self->incr_pos;

  // the state machine here is a bit convoluted and could be simplified a lot
  // but this would make it slower, so...

  for (;;)
    {
      switch (self->incr_mode)
        {
          // reached end of a scalar, see if we are inside a nested structure or not
          end_of_scalar:
            self->incr_mode = INCR_M_JSON;

            if (self->incr_nest) // end of a scalar inside array, object or tag
              goto incr_m_json;
            else // end of scalar outside structure, json text ends here
              goto interrupt;

          // only used for initial whitespace skipping
          case INCR_M_WS:
            for (;;)
              {
                if (*p > 0x20)
                  {
                    if (*p == '#')
                      {
                        self->incr_mode = INCR_M_C0;
                        goto incr_m_c;
                      }
                    else
                      {
                        self->incr_mode = INCR_M_JSON;
                        goto incr_m_json;
                      }
                  }
                else if (!*p)
                  goto interrupt;

                ++p;
              }

          // skip a single char inside a string (for \\-processing)
          case INCR_M_BS:
            if (!*p)
              goto interrupt;

            ++p;
            self->incr_mode = INCR_M_STR;
            goto incr_m_str;

          // inside #-style comments
          case INCR_M_C0:
          case INCR_M_C1:
          incr_m_c:
            for (;;)
              {
                if (*p == '\n')
                  {
                    self->incr_mode = self->incr_mode == INCR_M_C0 ? INCR_M_WS : INCR_M_JSON;
                    break;
                  }
                else if (!*p)
                  goto interrupt;

                ++p;
              }

            break;

          // inside true/false/null
          case INCR_M_TFN:
          incr_m_tfn:
            for (;;)
              switch (*p++)
                {
                  case 'r': case 'u': case 'e': // tRUE, falsE, nUll
                  case 'a': case 'l': case 's': // fALSe, nuLL
                    // allowed
                    break;
                   
                  default:
                    --p;
                    goto end_of_scalar;
                }

          // inside a number
          case INCR_M_NUM:
          incr_m_num:
            for (;;)
              switch (*p++)
                {
                  case 'e': case 'E': case '.': case '+':
                  case '-':
                  case '0': case '1': case '2': case '3': case '4':
                  case '5': case '6': case '7': case '8': case '9':
                    // allowed
                    break;

                  default:
                    --p;
                    goto end_of_scalar;
                }

          // inside a string
          case INCR_M_STR:
          incr_m_str:
            for (;;)
              {
                if (*p == '"')
                  {
                    ++p;
                    goto end_of_scalar;
                  }
                else if (*p == '\\')
                  {
                    ++p; // "virtually" consumes character after \

                    if (!*p) // if at end of string we have to switch modes
                      {
                        self->incr_mode = INCR_M_BS;
                        goto interrupt;
                      }
                  }
                else if (!*p)
                  goto interrupt;

                ++p;
              }

          // after initial ws, outside string
          case INCR_M_JSON:
          incr_m_json:
            for (;;)
              {
                switch (*p++)
                  {
                    case 0:
                      --p;
                      goto interrupt;

                    case 0x09:
                    case 0x0a:
                    case 0x0d:
                    case 0x20:
                      if (!self->incr_nest)
                        {
                          --p; // do not eat the whitespace, let the next round do it
                          goto interrupt;
                        }
                      break;

                    // the following three blocks handle scalars. this makes the parser
                    // more strict than required inside arrays or objects, and could
                    // be moved to a special case on the toplevel (except strings)
                    case 't':
                    case 'f':
                    case 'n':
                      self->incr_mode = INCR_M_TFN;
                      goto incr_m_tfn;

                    case '-':
                    case '0': case '1': case '2': case '3': case '4':
                    case '5': case '6': case '7': case '8': case '9':
                      self->incr_mode = INCR_M_NUM;
                      goto incr_m_num;

                    case '"':
                      self->incr_mode = INCR_M_STR;
                      goto incr_m_str;

                    case '[':
                    case '{':
                    case '(':
                      if (++self->incr_nest > self->max_depth)
                        croak (ERR_NESTING_EXCEEDED);
                      break;

                    case ']':
                    case '}':
                      if (--self->incr_nest <= 0)
                        goto interrupt;
                      break;

                    case ')':
                      --self->incr_nest;
                      break;

                    case '#':
                      self->incr_mode = INCR_M_C1;
                      goto incr_m_c;
                  }
              }
        }

      modechange:
        ;
    }

interrupt:
  self->incr_pos = p - SvPVX (self->incr_text);
  //printf ("interrupt<%.*s>\n", self->incr_pos, SvPVX(self->incr_text));//D
  //printf ("return pos %d mode %d nest %d\n", self->incr_pos, self->incr_mode, self->incr_nest);//D
}

/////////////////////////////////////////////////////////////////////////////
// XS interface functions

MODULE = JSON::SIMD		PACKAGE = JSON::SIMD

BOOT:
{
	int i;

        for (i = 0; i < 256; ++i)
          decode_hexdigit [i] =
            i >= '0' && i <= '9' ? i - '0'
            : i >= 'a' && i <= 'f' ? i - 'a' + 10
            : i >= 'A' && i <= 'F' ? i - 'A' + 10
            : -1;

        json_stash = gv_stashpv ("JSON::SIMD"                , 1);
        bool_stash = gv_stashpv ("Types::Serialiser::Boolean", 1);
        bool_false = get_bool ("Types::Serialiser::false");
        bool_true  = get_bool ("Types::Serialiser::true");

        sv_json = newSVpv ("JSON", 0);
        SvREADONLY_on (sv_json);

        simdjson_global_init();

        CvNODEBUG_on (get_cv ("JSON::SIMD::incr_text", 0)); /* the debugger completely breaks lvalue subs */
}

PROTOTYPES: DISABLE

void CLONE (...)
	CODE:
        // as long as these writes are atomic, the race should not matter
        // as existing threads either already use 0, or use the old value,
        // which is sitll correct for the initial thread.
        json_stash = 0;
        bool_stash = 0;
        bool_false = 0;
        bool_true  = 0;

void new (char *klass)
	PPCODE:
{
	SV *pv = NEWSV (0, sizeof (JSON));
        SvPOK_only (pv);
        json_init ((JSON *)SvPVX (pv));
        XPUSHs (sv_2mortal (sv_bless (
           newRV_noinc (pv),
           strEQ (klass, "JSON::SIMD") ? JSON_STASH : gv_stashpv (klass, 1)
        )));
}

void boolean_values (JSON *self, SV *v_false = 0, SV *v_true = 0)
	PPCODE:
        self->flags   &= ~F_CORE_BOOLS;
        self->v_false = newSVsv (v_false);
        self->v_true  = newSVsv (v_true);
        XPUSHs (ST (0));

void get_boolean_values (JSON *self)
	PPCODE:
        if (self->v_false && self->v_true)
          {
            EXTEND (SP, 2);
            PUSHs (self->v_false);
            PUSHs (self->v_true);
          }

void core_bools (JSON *self, int enable = 1)
	PPCODE:
        if (enable)
          {
            self->flags   |= F_CORE_BOOLS;
            self->v_false = newSVsv (&PL_sv_no);
            self->v_true  = newSVsv (&PL_sv_yes);
          }
        else
          {
            self->flags   &= ~F_CORE_BOOLS;
            self->v_false = 0;
            self->v_true  = 0;
          }
        XPUSHs (ST (0));

void get_core_bools (JSON *self)
	PPCODE:
{
        int result = self->flags & F_CORE_BOOLS;
#if PERL_VERSION_GE(5,36,0)
        if (self->v_false && self->v_true && SvIsBOOL(self->v_false) && SvIsBOOL(self->v_true))
          {
            result = F_CORE_BOOLS;
          }
#endif
        XPUSHs (boolSV (result));
}

void ascii (JSON *self, int enable = 1)
	ALIAS:
        ascii             = F_ASCII
        latin1            = F_LATIN1
        utf8              = F_UTF8
        indent            = F_INDENT
        canonical         = F_CANONICAL
        space_before      = F_SPACE_BEFORE
        space_after       = F_SPACE_AFTER
        pretty            = F_PRETTY
        allow_nonref      = F_ALLOW_NONREF
        shrink            = F_SHRINK
        allow_blessed     = F_ALLOW_BLESSED
        convert_blessed   = F_CONV_BLESSED
        relaxed           = F_RELAXED
        allow_unknown     = F_ALLOW_UNKNOWN
        allow_tags        = F_ALLOW_TAGS
        use_simdjson      = F_USE_SIMDJSON
        encode_core_bools = F_ENCODE_CORE_BOOLS
	PPCODE:
{
        if (enable)
          self->flags |=  ix;
        else
          self->flags &= ~ix;

        if (self->flags & F_USE_SIMDJSON && self->flags & F_ALLOW_TAGS)
          self->flags &= ~F_USE_SIMDJSON;
        if (self->flags & F_USE_SIMDJSON && self->flags & F_RELAXED)
          self->flags &= ~F_USE_SIMDJSON;

        XPUSHs (ST (0));
}

void get_ascii (JSON *self)
	ALIAS:
        get_ascii             = F_ASCII
        get_latin1            = F_LATIN1
        get_utf8              = F_UTF8
        get_indent            = F_INDENT
        get_canonical         = F_CANONICAL
        get_space_before      = F_SPACE_BEFORE
        get_space_after       = F_SPACE_AFTER
        get_allow_nonref      = F_ALLOW_NONREF
        get_shrink            = F_SHRINK
        get_allow_blessed     = F_ALLOW_BLESSED
        get_convert_blessed   = F_CONV_BLESSED
        get_relaxed           = F_RELAXED
        get_allow_unknown     = F_ALLOW_UNKNOWN
        get_allow_tags        = F_ALLOW_TAGS
        get_use_simdjson      = F_USE_SIMDJSON
        get_encode_core_bools = F_ENCODE_CORE_BOOLS
	PPCODE:
        XPUSHs (boolSV (self->flags & ix));

void max_depth (JSON *self, U32 max_depth = 0x80000000UL)
	PPCODE:
        self->max_depth = max_depth;
        XPUSHs (ST (0));

U32 get_max_depth (JSON *self)
	CODE:
        RETVAL = self->max_depth;
	OUTPUT:
        RETVAL

void max_size (JSON *self, U32 max_size = 0)
	PPCODE:
        self->max_size = max_size;
        XPUSHs (ST (0));

int get_max_size (JSON *self)
	CODE:
        RETVAL = self->max_size;
	OUTPUT:
        RETVAL

void filter_json_object (JSON *self, SV *cb = &PL_sv_undef)
	PPCODE:
{
        SvREFCNT_dec (self->cb_object);
        self->cb_object = SvOK (cb) ? newSVsv (cb) : 0;

        XPUSHs (ST (0));
}

void filter_json_single_key_object (JSON *self, SV *key, SV *cb = &PL_sv_undef)
	PPCODE:
{
	if (!self->cb_sk_object)
          self->cb_sk_object = newHV ();

        if (SvOK (cb))
          hv_store_ent (self->cb_sk_object, key, newSVsv (cb), 0);
        else
          {
            hv_delete_ent (self->cb_sk_object, key, G_DISCARD, 0);

            if (!HvKEYS (self->cb_sk_object))
              {
                SvREFCNT_dec (self->cb_sk_object);
                self->cb_sk_object = 0;
              }
          }

        XPUSHs (ST (0));
}

void encode (JSON *self, SV *scalar)
	PPCODE:
        PUTBACK; scalar = encode_json (scalar, self); SPAGAIN;
        XPUSHs (scalar);

void decode (JSON *self, SV *jsonstr)
	PPCODE:
        PUTBACK; jsonstr = decode_json (jsonstr, self, 0, 0); SPAGAIN;
        XPUSHs (jsonstr);

void decode_prefix (JSON *self, SV *jsonstr)
	PPCODE:
{
	SV *sv;
        STRLEN offset;
        PUTBACK; sv = decode_json (jsonstr, self, &offset, 0); SPAGAIN;
        EXTEND (SP, 2);
        PUSHs (sv);
        PUSHs (sv_2mortal (newSVuv (ptr_to_index (jsonstr, SvPV_nolen (jsonstr) + offset))));
}

void decode_at_pointer (JSON *self, SV *jsonstr, SV *path)
	PPCODE:
        PUTBACK; jsonstr = decode_json (jsonstr, self, 0, path); SPAGAIN;
        XPUSHs (jsonstr);

void incr_parse (JSON *self, SV *jsonstr = 0)
	PPCODE:
{
	if (!self->incr_text)
          self->incr_text = newSVpvn ("", 0);

        /* if utf8-ness doesn't match the decoder, need to upgrade/downgrade */
        if (!DECODE_WANTS_OCTETS (self) == !SvUTF8 (self->incr_text))
          if (DECODE_WANTS_OCTETS (self))
            {
              if (self->incr_pos)
                self->incr_pos = utf8_length ((U8 *)SvPVX (self->incr_text),
                                              (U8 *)SvPVX (self->incr_text) + self->incr_pos);

              sv_utf8_downgrade (self->incr_text, 0);
            }
          else
            {
              sv_utf8_upgrade (self->incr_text);

              if (self->incr_pos)
                self->incr_pos = utf8_hop ((U8 *)SvPVX (self->incr_text), self->incr_pos)
                                 - (U8 *)SvPVX (self->incr_text);
            }

        // append data, if any
        if (jsonstr)
          {
            /* make sure both strings have same encoding */
            if (SvUTF8 (jsonstr) != SvUTF8 (self->incr_text))
              if (SvUTF8 (jsonstr))
                sv_utf8_downgrade (jsonstr, 0);
              else
                sv_utf8_upgrade (jsonstr);

            /* and then just blindly append */
            {
              STRLEN len;
              const char *str = SvPV (jsonstr, len);
              STRLEN cur = SvCUR (self->incr_text);

              if (SvLEN (self->incr_text) - cur <= len)
                json_sv_grow (self->incr_text, cur, len);

              Move (str, SvEND (self->incr_text), len, char);
              SvCUR_set (self->incr_text, SvCUR (self->incr_text) + len);
              *SvEND (self->incr_text) = 0; // this should basically be a nop, too, but make sure it's there
            }
          }

        if (GIMME_V != G_VOID)
          do
            {
              SV *sv;
              STRLEN offset;

              if (!INCR_DONE (self))
                {
                  incr_parse (self);

                  if (self->incr_pos > self->max_size && self->max_size)
                    croak ("attempted decode of JSON text of %lu bytes size, but max_size is set to %lu",
                           (unsigned long)self->incr_pos, (unsigned long)self->max_size);

                  if (!INCR_DONE (self))
                    {
                      // as an optimisation, do not accumulate white space in the incr buffer
                      if (self->incr_mode == INCR_M_WS && self->incr_pos)
                        {
                          self->incr_pos = 0;
                          SvCUR_set (self->incr_text, 0);
                        }

                      break;
                    }
                }

              // manually consume trailing whitespace, to work around simdjson
              if (self->flags & F_USE_SIMDJSON)
                {
                  char *p = SvPVX (self->incr_text) + self->incr_pos;
                  while (p && (*p == 0x20 || *p == 0x0a ||*p == 0x0d || *p == 0x09))
                    {
                      p++;
                      self->incr_pos++;
                    }
                }

              PUTBACK; sv = decode_json (self->incr_text, self, &offset, 0); SPAGAIN;
              XPUSHs (sv);

              self->incr_pos -= offset;
              self->incr_nest = 0;
              self->incr_mode = 0;

              sv_chop (self->incr_text, SvPVX (self->incr_text) + offset);
            }
          while (GIMME_V == G_LIST);
}

SV *incr_text (JSON *self)
	ATTRS: lvalue
	CODE:
{
        if (self->incr_pos)
          croak ("incr_text can not be called when the incremental parser already started parsing");

        RETVAL = self->incr_text ? SvREFCNT_inc (self->incr_text) : &PL_sv_undef;
}
	OUTPUT:
        RETVAL

void incr_skip (JSON *self)
	CODE:
{
        if (self->incr_pos)
          {
            sv_chop (self->incr_text, SvPV_nolen (self->incr_text) + self->incr_pos);
            self->incr_pos  = 0;
            self->incr_nest = 0;
            self->incr_mode = 0;
          }
}

void incr_reset (JSON *self)
	CODE:
{
	SvREFCNT_dec (self->incr_text);
        self->incr_text = 0;
        self->incr_pos  = 0;
        self->incr_nest = 0;
        self->incr_mode = 0;
}

void DESTROY (JSON *self)
	CODE:
        SvREFCNT_dec (self->v_false);
        SvREFCNT_dec (self->v_true);
        SvREFCNT_dec (self->cb_sk_object);
        SvREFCNT_dec (self->cb_object);
        SvREFCNT_dec (self->incr_text);

PROTOTYPES: ENABLE

void encode_json (SV *scalar)
	PPCODE:
{
        JSON json;
        json_init (&json);
        json.flags |= F_UTF8;
        PUTBACK; scalar = encode_json (scalar, &json); SPAGAIN;
        XPUSHs (scalar);
}

void decode_json (SV *jsonstr)
	PPCODE:
{
        JSON json;
        json_init (&json);
        json.flags |= F_UTF8;
        PUTBACK; jsonstr = decode_json (jsonstr, &json, 0, 0); SPAGAIN;
        XPUSHs (jsonstr);
}

void simdjson_version ()
	PPCODE:
{
        SV *version_info;
        PUTBACK; version_info = simdjson_get_version(); SPAGAIN;
        XPUSHs (version_info);
}

void is_core_bool (SV *scalar)
	PPCODE:
{
#if PERL_VERSION_GE(5,36,0)
        XPUSHs( boolSV( SvIsBOOL( scalar )));
#else
        XPUSHs( boolSV( 0 ));
#endif
}
