/* 
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 * 
 *  Copyright 1998-2000 Gisle Aas.
 *  Copyright 1995-1996 Neil Winton.
 *  Copyright 1991-1992 RSA Data Security, Inc.
 *
 * This code is derived from Neil Winton's MD6-1.7 Perl module, which in
 * turn is derived from the reference implementation in RFC 1321 which
 * comes with this message:
 *
 * Copyright (C) 1991-2, RSA Data Security, Inc. Created 1991. All
 * rights reserved.
 *
 * License to copy and use this software is granted provided that it
 * is identified as the "RSA Data Security, Inc. MD6 Message-Digest
 * Algorithm" in all material mentioning or referencing this software
 * or this function.
 *
 * License is also granted to make and use derivative works provided
 * that such works are identified as "derived from the RSA Data
 * Security, Inc. MD6 Message-Digest Algorithm" in all material
 * mentioning or referencing the derived work.
 *
 * RSA Data Security, Inc. makes no representations concerning either
 * the merchantability of this software or the suitability of this
 * software for any particular purpose. It is provided "as is"
 * without express or implied warranty of any kind.
 *
 * These notices must be retained in any copies of any part of this
 * documentation and/or software.
 */

#ifdef __cplusplus
extern "C" {
#endif
#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif
#include "src/md6.h"
#ifdef G_WARN_ON
#define DOWARN (PL_dowarn & G_WARN_ON)
#else
#define DOWARN PL_dowarn
#endif
#ifndef dTHX
#define pTHX_
#define aTHX_
#endif
#ifndef INT2PTR
#define INT2PTR(any,d)	(any)(d)
#endif
static const char *
md6_error( int error ) {
  switch ( error ) {
  case MD6_SUCCESS:
    return "no error";
  case MD6_FAIL:
    return "some other problem";
  case MD6_BADHASHLEN:
    return "hashbitlen<1 or >512 bits";
  case MD6_NULLSTATE:
    return "null state passed to MD6";
  case MD6_BADKEYLEN:
    return "key length is <0 or >512 bits";
  case MD6_STATENOTINIT:
    return "state was never initialized";
  case MD6_STACKUNDERFLOW:
    return "MD6 stack underflows (shouldn't happen)";
  case MD6_STACKOVERFLOW:
    return "MD6 stack overflow (message too long)";
  case MD6_NULLDATA:
    return "null data pointer";
  case MD6_NULL_N:
    return "compress: N is null";
  case MD6_NULL_B:
    return "standard compress: null B pointer";
  case MD6_BAD_ELL:
    return "standard compress: ell not in {0,255}";
  case MD6_BAD_p:
    return "standard compress: p<0 or p>b*w";
  case MD6_NULL_K:
    return "standard compress: K is null";
  case MD6_NULL_Q:
    return "standard compress: Q is null";
  case MD6_NULL_C:
    return "standard compress: C is null";
  case MD6_BAD_L:
    return "standard compress: L <0 or > 255";
  case MD6_BAD_r:
    return "compress: r<0 or r>255";
  case MD6_OUT_OF_MEMORY:
    return "compress: storage allocation failed";
  default:
    return "unknown error";
  }
}

static void
md6_croak( int error ) {
  if ( MD6_SUCCESS != error ) {
    croak( md6_error( error ) );
  }
}

static void
MD6Init( md6_state * ctx, int d ) {
  md6_croak( md6_init( ctx, d ) );
}

static void
MD6UpdateBits( md6_state * ctx, U8 * buf, STRLEN len ) {
  md6_croak( md6_update( ctx, buf, len ) );
}

static void
MD6Update( md6_state * ctx, U8 * buf, STRLEN len ) {
  MD6UpdateBits( ctx, buf, len * 8 );
}

static void
MD6Final( U8 * digest, md6_state * ctx ) {
  md6_croak( md6_final( ctx, digest ) );
}

static md6_state *
get_md6_ctx( pTHX_ SV * sv ) {
  if ( SvROK( sv ) ) {
    sv = SvRV( sv );
    if ( SvIOK( sv ) ) {
      md6_state *ctx = INT2PTR( md6_state *, SvIV( sv ) );
      if ( ctx && ctx->sig == MD6_SIG ) {
        return ctx;
      }
    }
  }
  croak( "Not a reference to a Digest::MD6 object" );
  return ( md6_state * ) 0;     /* some compilers insist on a return value */
}

static char *
enc_hex( char *buf, const unsigned char *in, int bits ) {
  static const char hx[] = "0123456789abcdef";
  char *op = buf;
  unsigned p = 0;
  while ( bits > 0 ) {
    unsigned b = ( p & 1 ) ? ( in[p >> 1] & 0x0F ) : ( in[p >> 1] >> 4 );
    if ( bits < 4 )
      b &= ( ( 1 << bits ) - 1 ) << ( 4 - bits );
    bits -= 4;
    p++;
    *op++ = hx[b];
  }
  *op = '\0';
  return buf;
}

static char *
enc_base64( char *buf, const unsigned char *in, int bits ) {
  static const char b64[] =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  unsigned phase = 0;
  unsigned p = 0;
  char *op = buf;
  while ( bits > 0 ) {
    unsigned b = 0;
    /* get next six bits */
    switch ( phase ) {
    case 0:
      b = in[p] >> 2;
      break;
    case 1:
      b = ( ( in[p] & 0x03 ) << 4 ) | ( ( in[p + 1] & 0xF0 ) >> 4 );
      break;
    case 2:
      b = ( ( in[p + 1] & 0x0F ) << 2 ) | ( ( in[p + 2] & 0xC0 ) >> 6 );
      break;
    case 3:
      b = in[p + 2] & 0x3f;
      break;
    }
    if ( bits < 6 )
      b &= ( ( 1 << bits ) - 1 ) << ( 6 - bits );
    bits -= 6;
    if ( ++phase == 4 ) {
      phase = 0;
      p += 3;
    }
    *op++ = b64[b];
  }
  *op = '\0';
  return buf;
}

/* Formats */
#define F_BIN 0
#define F_HEX 1
#define F_B64 2

#define HASH_MAX_BITS  512
#define HASH_MAX_BYTES ( HASH_MAX_BITS / 8 )

static SV *
make_mortal_sv( pTHX_ const unsigned char *src, int bits, int type ) {
  STRLEN len;
  char result[HASH_MAX_BYTES * 2 + 1];
  char *ret;

  switch ( type ) {
  case F_BIN:
    len = ( bits + 7 ) / 8;
    ret = ( char * ) src;
    break;
  case F_HEX:
    ret = enc_hex( result, src, bits );
    len = strlen( ret );
    break;
  case F_B64:
    ret = enc_base64( result, src, bits );
    len = strlen( ret );
    break;
  default:
    croak( "Bad conversion type (%d)", type );
    break;
  }
  return sv_2mortal( newSVpv( ret, len ) );
}

/********************************************************************/

/* *INDENT-OFF* */

typedef PerlIO* InputStream;

MODULE = Digest::MD6		PACKAGE = Digest::MD6

PROTOTYPES: DISABLE

void
new(xclass, ...)
	SV* xclass
  PREINIT:
    md6_state* context;
  PPCODE:
    int digest_len = (int) SvIV(get_sv("Digest::MD6::HASH_LENGTH", FALSE));
    if (!SvROK(xclass)) {
      STRLEN my_na;
      char *sclass = SvPV(xclass, my_na);
      New(55, context, 1, md6_state);
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), sclass, (void*)context);
      SvREADONLY_on(SvRV(ST(0)));
    } else {
      context = get_md6_ctx(aTHX_ xclass);
    }
    if ( items > 1 )
      digest_len = (int) SvIV(ST(1));
    MD6Init(context, digest_len);
    XSRETURN(1);

void
clone(self)
	SV* self
  PREINIT:
    md6_state* cont = get_md6_ctx(aTHX_ self);
    const char *myname = sv_reftype(SvRV(self),TRUE);
    md6_state* context;
  PPCODE:
    New(55, context, 1, md6_state);
    ST(0) = sv_newmortal();
    sv_setref_pv(ST(0), myname , (void*)context);
    SvREADONLY_on(SvRV(ST(0)));
    memcpy(context,cont,sizeof(md6_state));
    XSRETURN(1);

void
DESTROY(context)
	md6_state* context
  CODE:
    Safefree(context);

void
reset(self)
	SV* self
  PREINIT:
    md6_state* context = get_md6_ctx(aTHX_ self);
  PPCODE:
    MD6Init(context, context->d);
    XSRETURN(1);  /* self */

void
add(self, ...)
	SV* self
  PREINIT:
    md6_state* context = get_md6_ctx(aTHX_ self);
    int i;
    unsigned char *data;
    STRLEN len;
  PPCODE:
    for (i = 1; i < items; i++) {
      data = (unsigned char *)(SvPV(ST(i), len));
      MD6Update(context, data, len);
    }
    XSRETURN(1);  /* self */

void
_add_bits(self, ...)
	SV* self
  PREINIT:
    md6_state* context = get_md6_ctx(aTHX_ self);
    int i;
    unsigned char *data;
    STRLEN len;
    IV bits;
  PPCODE:
    if (!(items & 1)) {
      croak("add_bits expects a number of data, length pairs");
    }
    for (i = 1; i < items; i += 2) {
      data = (unsigned char *)(SvPV(ST(i), len));
      bits = SvIV(ST(i+1));
      if ( bits > len * 8 ) {
        croak("not enough bits in data");
      }
      MD6UpdateBits(context, data, bits);
    }
    XSRETURN(1);  /* self */

void
addfile(self, fh)
	SV* self
	InputStream fh
  PREINIT:
    md6_state* context = get_md6_ctx(aTHX_ self);
    /* TODO is the correct? */
    STRLEN fill = context->bits_processed / 8;
#ifdef USE_HEAP_INSTEAD_OF_STACK
    unsigned char* buffer;
#else
    unsigned char buffer[4096];
#endif
    int  n;
  CODE:
    if (fh) {
#ifdef USE_HEAP_INSTEAD_OF_STACK
      New(0, buffer, 4096, unsigned char);
      assert(buffer);
#endif
      if (fill) {
        /* The MD6Update() function is faster if it can work with
          * complete blocks.  This will fill up any buffered block
          * first.
          */
        STRLEN missing = 64 - fill;
        if ( (n = PerlIO_read(fh, buffer, missing)) > 0)
          MD6Update(context, buffer, n);
        else
          XSRETURN(1);  /* self */
      }

      /* Process blocks until EOF or error */
      while ( (n = PerlIO_read(fh, buffer, sizeof(buffer))) > 0) {
        MD6Update(context, buffer, n);
      }
#ifdef USE_HEAP_INSTEAD_OF_STACK
      Safefree(buffer);
#endif
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
	md6_state* context
  ALIAS:
    Digest::MD6::digest    = F_BIN
    Digest::MD6::hexdigest = F_HEX
    Digest::MD6::b64digest = F_B64
  PREINIT:
    unsigned char digeststr[HASH_MAX_BYTES];
  PPCODE:
    MD6Final(digeststr, context);
    MD6Init(context, context->d);  /* In case it is reused */
    ST(0) = make_mortal_sv(aTHX_ digeststr,  context->d, ix);
    XSRETURN(1);

void
md6(...)
  ALIAS:
    Digest::MD6::md6        = F_BIN
    Digest::MD6::md6_hex    = F_HEX
    Digest::MD6::md6_base64 = F_B64
  PREINIT:
    md6_state ctx;
    int i;
    unsigned char *data;
    STRLEN len;
    unsigned char digeststr[HASH_MAX_BYTES];
  PPCODE:
    int digest_len = (int) SvIV(get_sv("Digest::MD6::HASH_LENGTH", FALSE));
    MD6Init(&ctx, digest_len);

    if (DOWARN) {
      char *msg = 0;
      if (items == 1) {
        if (SvROK(ST(0))) {
          SV* sv = SvRV(ST(0));
          if (SvOBJECT(sv) && strEQ(HvNAME(SvSTASH(sv)), "Digest::MD6"))
            msg = "probably called as method";
          else
            msg = "called with reference argument";
        }
      }
      else if (items > 1) {
        data = (unsigned char *)SvPV(ST(0), len);
        if (len == 11 && memEQ("Digest::MD6", data, 11)) {
          msg = "probably called as class method";
        }
        else if (SvROK(ST(0))) {
          SV* sv = SvRV(ST(0));
          if (SvOBJECT(sv) && strEQ(HvNAME(SvSTASH(sv)), "Digest::MD6"))
            msg = "probably called as method";
        }
      }
      if (msg) {
        const char *f = 
            (ix == F_BIN) ? "md6" 
          : (ix == F_HEX) ? "md6_hex" 
          :                 "md6_base64";
        warn("&Digest::MD6::%s function %s", f, msg);
      }
    }

    for (i = 0; i < items; i++) {
      data = (unsigned char *)(SvPV(ST(i), len));
      MD6Update(&ctx, data, len);
    }
    MD6Final(digeststr, &ctx);
    ST(0) = make_mortal_sv(aTHX_ digeststr, ctx.d, ix);
    XSRETURN(1);

