#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define INIT32 2166136261U
#define MULT32 16777619U
#define INIT64 14695981039346656037U
#define MULT64 1099511628211U

static UV
fnv1_32 (SV *data, U32 h)
{
  STRLEN l;
  U8 *p = (U8 *)SvPVbyte (data, l);

  while (l--)
    {
      h *= MULT32;
      h ^= *p++;
    }

  return h;
}

static UV
fnv1a_32 (SV *data, U32 h)
{
  STRLEN l;
  U8 *p = (U8 *)SvPVbyte (data, l);

  while (l--)
    {
      h ^= *p++;
      h *= MULT32;
    }

  return h;
}

#if UVSIZE >= 8

static UV
fnv1_64 (SV *data, UV h)
{
  STRLEN l;
  U8 *p = (U8 *)SvPVbyte (data, l);

  while (l--)
    {
      h *= MULT64;
      h ^= *p++;
    }

  return h;
}

static UV
fnv1a_64 (SV *data, UV h)
{
  STRLEN l;
  U8 *p = (U8 *)SvPVbyte (data, l);

  while (l--)
    {
      h ^= *p++;
      h *= MULT64;
    }

  return h;
}

#endif

#define fnv0_32 fnv1_32
#define fnv0_64 fnv1_64

static UV
xorfold (UV hash, int bits, int max)
{
  if (bits < max)
    hash = ((hash >> (max - bits)) ^ hash) & ((1 << bits) - 1);

  return hash;
}

#define xorfold_32(hash,bits) xorfold (hash, bits, 32)
#define xorfold_64(hash,bits) xorfold (hash, bits, 64)

static UV
reduce_32 (U32 hash, U32 range)
{
  U32 retry =         0xffffffffU / range * range;

  while (hash >= retry)
    hash = hash * MULT32 + INIT32;

  return hash % range;
}

static UV
reduce_64 (UV hash, UV range)
{
  U32 retry = 0xffffffffffffffffU / range * range;

  while (hash >= retry)
    hash = hash * MULT64 + INIT64;

  return hash % range;
}

MODULE = Digest::FNV::XS		PACKAGE = Digest::FNV::XS

PROTOTYPES: ENABLE

UV fnv0_32  (SV *data, SV *init = &PL_sv_undef)
	C_ARGS: data, SvUV (init)

UV fnv1_32  (SV *data, SV *init = &PL_sv_undef)
	C_ARGS: data, SvOK (init) ? SvUV (init) : INIT32

UV fnv1a_32 (SV *data, SV *init = &PL_sv_undef)
	C_ARGS: data, SvOK (init) ? SvUV (init) : INIT32

#if UVSIZE >= 8

UV fnv0_64  (SV *data, SV *init = &PL_sv_undef)
	C_ARGS: data, SvUV (init)

UV fnv1_64  (SV *data, SV *init = &PL_sv_undef)
	C_ARGS: data, SvOK (init) ? SvUV (init) : INIT64

UV fnv1a_64 (SV *data, SV *init = &PL_sv_undef)
	C_ARGS: data, SvOK (init) ? SvUV (init) : INIT64

#endif

UV xorfold_32 (UV hash, int bits)

UV xorfold_64 (UV hash, int bits)

UV reduce_32 (UV hash, UV range)

UV reduce_64 (UV hash, UV range)

