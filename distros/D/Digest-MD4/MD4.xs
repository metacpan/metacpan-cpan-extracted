/* $Id: MD4.xs,v 1.4 2013/03/14 05:51:35 mikem Exp mikem $ */

/* 
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 * 
 *  Copyright 1998-2000 Gisle Aas.
 *  Copyright 1995-1996 Neil Winton.
 *  Copyright 1991-1992 RSA Data Security, Inc.
 *
 * This code is derived from Neil Winton's MD4-1.7 Perl module, 
 * and Gisle Aas's Digest::MD5 module. The MD4 algorithm is
 * derived from the reference implementation in RFC 1320 which
 * comes with this message:
 *
 *  Copyright (C) 1990-2, RSA Data Security, Inc. All rights reserved.
 *
 *  License to copy and use this software is granted provided that it
 *  is identified as the "RSA Data Security, Inc. MD4 Message-Digest
 *  Algorithm" in all material mentioning or referencing this software
 *  or this function.
 *
 *  License is also granted to make and use derivative works provided
 *  that such works are identified as "derived from the RSA Data
 *  Security, Inc. MD4 Message-Digest Algorithm" in all material
 *  mentioning or referencing the derived work.
 *
 *  RSA Data Security, Inc. makes no representations concerning either
 *  the merchantability of this software or the suitability of this
 *  software for any particular purpose. It is provided "as is"
 *  without express or implied warranty of any kind.
 *
 *  These notices must be retained in any copies of any part of this
 *  documentation and/or software.
 */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#ifndef PERL_VERSION
#    include <patchlevel.h>
#    if !(defined(PERL_VERSION) || (SUBVERSION > 0 && defined(PATCHLEVEL)))
#        include <could_not_find_Perl_patchlevel.h>
#    endif
#    define PERL_REVISION       5
#    define PERL_VERSION        PATCHLEVEL
#    define PERL_SUBVERSION     SUBVERSION
#endif

#if PERL_VERSION <= 4 && !defined(PL_dowarn)
   #define PL_dowarn dowarn
#endif

#ifdef G_WARN_ON
   #define DOWARN (PL_dowarn & G_WARN_ON)
#else
   #define DOWARN PL_dowarn
#endif

#ifdef SvPVbyte
   #if PERL_REVISION == 5 && PERL_VERSION < 7
       /* SvPVbyte does not work in perl-5.6.1, borrowed version for 5.7.3 */
       #undef SvPVbyte
       #define SvPVbyte(sv, lp) \
	  ((SvFLAGS(sv) & (SVf_POK|SVf_UTF8)) == (SVf_POK) \
     	   ? ((lp = SvCUR(sv)), SvPVX(sv)) : my_sv_2pvbyte(aTHX_ sv, &lp))

       static char *
       my_sv_2pvbyte(pTHX_ register SV *sv, STRLEN *lp)
       {
	   sv_utf8_downgrade(sv,0);
           return SvPV(sv,*lp);
       }
   #endif
#else
   #define SvPVbyte SvPV
#endif

/* Perl does not guarantee that U32 is exactly 32 bits.  Some system
 * has no integral type with exactly 32 bits.  For instance, A Cray has
 * short, int and long all at 64 bits so we need to apply this macro
 * to reduce U32 values to 32 bits at appropriate places. If U32
 * really does have 32 bits then this is a no-op.
 */
#if BYTEORDER > 0x4321 || defined(TRUNCATE_U32)
  #define TRUNC32(x) ((x) &= 0xFFFFffff)
#else
  #define TRUNC32(x) /*nothing*/
#endif

#define MD4_CTX_SIGNATURE 200003166

/* This stucture keeps the current state of algorithm.
 */
typedef struct {
  U32 signature;       /* safer cast in get_md4_ctx() */
  U32 state[4];                                   /* state (ABCD) */
  U32 count[2];        /* number of bits, modulo 2^64 (lsb first) */
  unsigned char buffer[64];                         /* input buffer */
} MD4_CTX;

#define POINTER void*

/* Padding is added at the end of the message in order to fill a
 * complete 64 byte block (- 8 bytes for the message length).  The
 * padding is also the reason the buffer in MD4_CTX have to be
 * 128 bytes.
 */
static unsigned char PADDING[64] = {
  0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

/* Constants for MD4Transform routine.
 */
#define S11 3
#define S12 7
#define S13 11
#define S14 19
#define S21 3
#define S22 5
#define S23 9
#define S24 13
#define S31 3
#define S32 9
#define S33 11
#define S34 15

/* F, G, H and I are basic MD4 functions.
 */
#define F(x, y, z) (((x) & (y)) | ((~x) & (z)))
#define G(x, y, z) (((x) & (y)) | ((x) & (z)) | ((y) & (z)))
#define H(x, y, z) ((x) ^ (y) ^ (z))

/* ROTATE_LEFT rotates x left n bits.
 */
#define ROTATE_LEFT(x, n) (((x) << (n) | ((x) >> (32-(n)))))

/* FF, GG and HH are transformations for rounds 1, 2 and 3 */
/* Rotation is separate from addition to prevent recomputation */
#define FF(a, b, c, d, x, s) { \
    (a) += F ((b), (c), (d)) + (x); \
     TRUNC32((a));                  \
    (a) = ROTATE_LEFT ((a), (s)); \
     TRUNC32((a));                  \
  }
#define GG(a, b, c, d, x, s) { \
    (a) += G ((b), (c), (d)) + (x) + (U32)0x5a827999; \
     TRUNC32((a));                  \
    (a) = ROTATE_LEFT ((a), (s)); \
     TRUNC32((a));                  \
  }
#define HH(a, b, c, d, x, s) { \
    (a) += H ((b), (c), (d)) + (x) + (U32)0x6ed9eba1; \
     TRUNC32((a));                  \
    (a) = ROTATE_LEFT ((a), (s)); \
     TRUNC32((a));                  \
  }

/* Encodes input (UINT4) into output (unsigned char). Assumes len is
     a multiple of 4.
 */
static void Encode (output, input, len)
unsigned char *output;
U32 *input;
unsigned int len;
{
  unsigned int i, j;

  for (i = 0, j = 0; j < len; i++, j += 4) {
    output[j] = (unsigned char)(input[i] & 0xff);
    output[j+1] = (unsigned char)((input[i] >> 8) & 0xff);
    output[j+2] = (unsigned char)((input[i] >> 16) & 0xff);
    output[j+3] = (unsigned char)((input[i] >> 24) & 0xff);
  }
}

/* Decodes input (unsigned char) into output (UINT4). Assumes len is
     a multiple of 4.
 */
static void Decode (output, input, len)

U32 *output;
unsigned char *input;
unsigned int len;
{
  unsigned int i, j;

  for (i = 0, j = 0; j < len; i++, j += 4)
    output[i] = ((U32)input[j]) | (((U32)input[j+1]) << 8) |
      (((U32)input[j+2]) << 16) | (((U32)input[j+3]) << 24);
}

static void
MD4Init(MD4_CTX *context)
{
  context->count[0] = context->count[1] = 0;

  /* Load magic initialization constants.
   */
  context->state[0] = 0x67452301;
  context->state[1] = 0xefcdab89;
  context->state[2] = 0x98badcfe;
  context->state[3] = 0x10325476;
}


/* MD4 basic transformation. Transforms state based on block.
 */
static void MD4Transform (state, block)
U32 state[4];
unsigned char block[64];
{
  U32 a = state[0], b = state[1], c = state[2], d = state[3], x[16];

  Decode (x, block, 64);

  /* Round 1 */
  FF (a, b, c, d, x[ 0], S11); /* 1 */
  FF (d, a, b, c, x[ 1], S12); /* 2 */
  FF (c, d, a, b, x[ 2], S13); /* 3 */
  FF (b, c, d, a, x[ 3], S14); /* 4 */
  FF (a, b, c, d, x[ 4], S11); /* 5 */
  FF (d, a, b, c, x[ 5], S12); /* 6 */
  FF (c, d, a, b, x[ 6], S13); /* 7 */
  FF (b, c, d, a, x[ 7], S14); /* 8 */
  FF (a, b, c, d, x[ 8], S11); /* 9 */
  FF (d, a, b, c, x[ 9], S12); /* 10 */
  FF (c, d, a, b, x[10], S13); /* 11 */
  FF (b, c, d, a, x[11], S14); /* 12 */
  FF (a, b, c, d, x[12], S11); /* 13 */
  FF (d, a, b, c, x[13], S12); /* 14 */
  FF (c, d, a, b, x[14], S13); /* 15 */
  FF (b, c, d, a, x[15], S14); /* 16 */

  /* Round 2 */
  GG (a, b, c, d, x[ 0], S21); /* 17 */
  GG (d, a, b, c, x[ 4], S22); /* 18 */
  GG (c, d, a, b, x[ 8], S23); /* 19 */
  GG (b, c, d, a, x[12], S24); /* 20 */
  GG (a, b, c, d, x[ 1], S21); /* 21 */
  GG (d, a, b, c, x[ 5], S22); /* 22 */
  GG (c, d, a, b, x[ 9], S23); /* 23 */
  GG (b, c, d, a, x[13], S24); /* 24 */
  GG (a, b, c, d, x[ 2], S21); /* 25 */
  GG (d, a, b, c, x[ 6], S22); /* 26 */
  GG (c, d, a, b, x[10], S23); /* 27 */
  GG (b, c, d, a, x[14], S24); /* 28 */
  GG (a, b, c, d, x[ 3], S21); /* 29 */
  GG (d, a, b, c, x[ 7], S22); /* 30 */
  GG (c, d, a, b, x[11], S23); /* 31 */
  GG (b, c, d, a, x[15], S24); /* 32 */

  /* Round 3 */
  HH (a, b, c, d, x[ 0], S31); /* 33 */
  HH (d, a, b, c, x[ 8], S32); /* 34 */
  HH (c, d, a, b, x[ 4], S33); /* 35 */
  HH (b, c, d, a, x[12], S34); /* 36 */
  HH (a, b, c, d, x[ 2], S31); /* 37 */
  HH (d, a, b, c, x[10], S32); /* 38 */
  HH (c, d, a, b, x[ 6], S33); /* 39 */
  HH (b, c, d, a, x[14], S34); /* 40 */
  HH (a, b, c, d, x[ 1], S31); /* 41 */
  HH (d, a, b, c, x[ 9], S32); /* 42 */
  HH (c, d, a, b, x[ 5], S33); /* 43 */
  HH (b, c, d, a, x[13], S34); /* 44 */
  HH (a, b, c, d, x[ 3], S31); /* 45 */
  HH (d, a, b, c, x[11], S32); /* 46 */
  HH (c, d, a, b, x[ 7], S33); /* 47 */
  HH (b, c, d, a, x[15], S34); /* 48 */

  state[0] += a; TRUNC32(state[0]);
  state[1] += b; TRUNC32(state[1]);
  state[2] += c; TRUNC32(state[2]);
  state[3] += d; TRUNC32(state[3]);
}

#ifdef MD4_DEBUG
static char*
ctx_dump(MD4_CTX* ctx)
{
    static char buf[1024];
    sprintf(buf, "{A=%x,B=%x,C=%x,D=%x,%d,%d}",
	    ctx->state[0], ctx->state[1], ctx->state[2], ctx->state[3],
	    ctx->count[0], ctx->count[1]));
    return buf;
}
#endif


static void
MD4Update(MD4_CTX* context, const U8* input, STRLEN inputLen)
{
  unsigned int i, index, partLen;

  /* Compute number of bytes mod 64 */
  index = (unsigned int)((context->count[0] >> 3) & 0x3F);
  /* Update number of bits */
  if ((context->count[0] += ((U32)inputLen << 3))
      < ((U32)inputLen << 3))
    context->count[1]++;
  context->count[1] += ((U32)inputLen >> 29);

  partLen = 64 - index;

  /* Transform as many times as possible.
   */
  if (inputLen >= partLen) {
    Copy(input, &context->buffer[index], partLen, U8);
    MD4Transform (context->state, context->buffer);

    for (i = partLen; i + 63 < inputLen; i += 64)
     MD4Transform (context->state, &input[i]);

    index = 0;
  }
  else
    i = 0;

  /* Buffer remaining input */
Copy(&input[i], &context->buffer[index], inputLen-i, U8);
}


static void
MD4Final(U8* digest, MD4_CTX *context)
{
  unsigned char bits[8];
  unsigned int index, padLen;

  /* Save number of bits */
  Encode (bits, context->count, 8);

  /* Pad out to 56 mod 64.
   */
  index = (unsigned int)((context->count[0] >> 3) & 0x3f);
  padLen = (index < 56) ? (56 - index) : (120 - index);
  MD4Update (context, PADDING, padLen);

  /* Append length (before padding) */
  MD4Update (context, bits, 8);
  /* Store state in digest */
  Encode (digest, context->state, 16);

}

#ifndef INT2PTR
#define INT2PTR(any,d)	(any)(d)
#endif

static MD4_CTX* get_md4_ctx(SV* sv)
{
    if (SvROK(sv)) {
	sv = SvRV(sv);
	if (SvIOK(sv)) {
	    MD4_CTX* ctx = INT2PTR(MD4_CTX*, SvIV(sv));
	    if (ctx && ctx->signature == MD4_CTX_SIGNATURE) {
		return ctx;
            }
        }
    }
    croak("Not a reference to a Digest::MD4 object");
    return (MD4_CTX*)0; /* some compilers insist on a return value */
}


static char* hex_16(const unsigned char* from, char* to)
{
    static char *hexdigits = "0123456789abcdef";
    const unsigned char *end = from + 16;
    char *d = to;

    while (from < end) {
	*d++ = hexdigits[(*from >> 4)];
	*d++ = hexdigits[(*from & 0x0F)];
	from++;
    }
    *d = '\0';
    return to;
}

static char* base64_16(const unsigned char* from, char* to)
{
    static char* base64 =
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    const unsigned char *end = from + 16;
    unsigned char c1, c2, c3;
    char *d = to;

    while (1) {
	c1 = *from++;
	*d++ = base64[c1>>2];
	if (from == end) {
	    *d++ = base64[(c1 & 0x3) << 4];
	    break;
	}
	c2 = *from++;
	c3 = *from++;
	*d++ = base64[((c1 & 0x3) << 4) | ((c2 & 0xF0) >> 4)];
	*d++ = base64[((c2 & 0xF) << 2) | ((c3 & 0xC0) >>6)];
	*d++ = base64[c3 & 0x3F];
    }
    *d = '\0';
    return to;
}

/* Formats */
#define F_BIN 0
#define F_HEX 1
#define F_B64 2

static SV* make_mortal_sv(const unsigned char *src, int type)
{
    STRLEN len;
    char result[33];
    char *ret;
    
    switch (type) {
    case F_BIN:
	ret = (char*)src;
	len = 16;
	break;
    case F_HEX:
	ret = hex_16(src, result);
	len = 32;
	break;
    case F_B64:
	ret = base64_16(src, result);
	len = 22;
	break;
    default:
	croak("Bad convertion type (%d)", type);
	break;
    }
    return sv_2mortal(newSVpv(ret,len));
}


/********************************************************************/

typedef PerlIO* InputStream;

MODULE = Digest::MD4		PACKAGE = Digest::MD4

PROTOTYPES: DISABLE

void
new(xclass)
	SV* xclass
    PREINIT:
	MD4_CTX* context;
    PPCODE:
	if (!SvROK(xclass)) {
	    STRLEN my_na;
	    char *sclass = SvPV(xclass, my_na);
	    New(55, context, 1, MD4_CTX);
	    context->signature = MD4_CTX_SIGNATURE;
	    ST(0) = sv_newmortal();
	    sv_setref_pv(ST(0), sclass, (void*)context);
	    SvREADONLY_on(SvRV(ST(0)));
	} else {
	    context = get_md4_ctx(xclass);
	}
        MD4Init(context);
	XSRETURN(1);

void
clone(self)
	SV* self
    PREINIT:
	MD4_CTX* cont = get_md4_ctx(self);
	const char *myname = sv_reftype(SvRV(self),TRUE);
	MD4_CTX* context;
    PPCODE:
	New(55, context, 1, MD4_CTX);
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), myname , (void*)context);
	SvREADONLY_on(SvRV(ST(0)));
	memcpy(context,cont,sizeof(MD4_CTX));
	XSRETURN(1);

void
DESTROY(context)
	MD4_CTX* context
    CODE:
        Safefree(context);

void
add(self, ...)
	SV* self
    PREINIT:
	MD4_CTX* context = get_md4_ctx(self);
	int i;
	unsigned char *data;
	STRLEN len;
    PPCODE:
	for (i = 1; i < items; i++) {
	    data = (unsigned char *)(SvPVbyte(ST(i), len));
	    MD4Update(context, data, len);
	}
	XSRETURN(1);  /* self */

void
addfile(self, fh)
	SV* self
	InputStream fh
    PREINIT:
	MD4_CTX* context = get_md4_ctx(self);
	STRLEN fill = (context->count[0] >> 3) & 0x3F;
	unsigned char buffer[4096];
	int  n;
    CODE:
	if (fh) {
            if (fill) {
	        /* The MD4Update() function is faster if it can work with
	         * complete blocks.  This will fill up any buffered block
	         * first.
	         */
	        STRLEN missing = 64 - fill;
	        if ( (n = PerlIO_read(fh, buffer, missing)) > 0)
	 	    MD4Update(context, buffer, n);
	        else
		    XSRETURN(1);  /* self */
	    }

	    /* Process blocks until EOF or error */
            while ( (n = PerlIO_read(fh, buffer, sizeof(buffer))) > 0) {
	        MD4Update(context, buffer, n);
	    }

	    if (PerlIO_error(fh)) {
		croak("Reading from filehandle failed");
	    }
	}
	else {
	    croak("No filehandle passed");
	}
	XSRETURN(1);  /* self */

void
digest(context)
	MD4_CTX* context
    ALIAS:
	Digest::MD4::digest    = F_BIN
	Digest::MD4::hexdigest = F_HEX
	Digest::MD4::b64digest = F_B64
    PREINIT:
	unsigned char digeststr[16];
    PPCODE:
        MD4Final(digeststr, context);
	MD4Init(context);  /* In case it is reused */
        ST(0) = make_mortal_sv(digeststr, ix);
        XSRETURN(1);

void
md4(...)
    ALIAS:
	Digest::MD4::md4        = F_BIN
	Digest::MD4::md4_hex    = F_HEX
	Digest::MD4::md4_base64 = F_B64
    PREINIT:
	MD4_CTX ctx;
	int i;
	unsigned char *data;
        STRLEN len;
	unsigned char digeststr[16];
    PPCODE:
	MD4Init(&ctx);

	if (DOWARN) {
            char *msg = 0;
	    if (items == 1) {
		if (SvROK(ST(0))) {
                    SV* sv = SvRV(ST(0));
		    if (SvOBJECT(sv) && strEQ(HvNAME(SvSTASH(sv)), "Digest::MD4"))
		        msg = "probably called as method";
		    else
			msg = "called with reference argument";
		}
	    }
	    else if (items > 1) {
		data = (unsigned char *)SvPVbyte(ST(0), len);
		if (len == 11 && memEQ("Digest::MD4", data, 11)) {
		    msg = "probably called as class method";
		}
	    }
	    if (msg) {
		char *f = (ix == F_BIN) ? "md4" :
                          (ix == F_HEX) ? "md4_hex" : "md4_base64";
	        warn("&Digest::MD4::%s function %s", f, msg);
	    }
	}

	for (i = 0; i < items; i++) {
	    data = (unsigned char *)(SvPVbyte(ST(i), len));
	    MD4Update(&ctx, data, len);
	}
	MD4Final(digeststr, &ctx);
        ST(0) = make_mortal_sv(digeststr, ix);
        XSRETURN(1);
