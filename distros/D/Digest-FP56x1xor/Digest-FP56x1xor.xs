/*
 * Digest::FP56x1xor.xs - C implementation of a 56bit pseudo additive fingerprint hash.
 *
 * (C) 2007-2008 jw@suse.de, Novell Inc.
 * This module is free software. IT may be used
 * and/or modified under the same terms as perl itself.
 *
 * See also 
 *	perldoc perlxs
 * 	perldoc perlguts
 * 	perldoc perlxstut
 * 	perldoc perlapi
 *
 * Currently gen_l() croaks, if no 64bit integers are available
 * and gen() is suggested, which returns a hex string.
 * If the compiler does not respond to 'long long' with 64bit, 
 * we die().
 *
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define VERSION "0.15"	// keep in sync with Changes, lib/Digest/FP56x1xor.pm

#if !defined(_STDINT_H) && !defined(__WORDSIZE)
// stdint.h and bits/types.h also have these:
typedef unsigned long long uint64_t;
typedef unsigned int       uint32_t;
#endif

static uint64_t rand56[256] = {
#include "random56x256.h"
};

// rotate56 rotates the lower 56 bits in h by m bits.
// The high 8 bit of h are cleared and remain zero.
static uint64_t rotate56(uint64_t h, int m)
{
  uint64_t x = (h << m) & 0x00ffffffffffffffLL;
  h &= 0x00ffffffffffffffLL;
  x |= (h >> (56-m));
  return x;
}

#if 0
// hmm, is this useful? how ould perl work with that
// string? I need to push it into 
// postgresql and sqlite databases and have it compared there.
// the sql statements for this are always 7bit ascii, right?
//
static unsigned char *uint64tostr8(uint64_t h, unsigned char *buf)
{
  unsigned char buf8[9];
  int i;
  if (!buf) buf = buf8;
  for (i = 0; i < 8; i++)
    {
      buf[i] = (unsigned char)((h>>(8*(7-i))) & 0xff);
    }
  return buf; 
}
#endif

// fp is a 64bit integer.
// highest 2 bit are always zero, next 6 bit are the modulo count.
// remaining lower 56 bit are fingerprint hash value.
static uint64_t gen_fp(const char *text, unsigned int len)
{
  uint64_t h = 0;
  unsigned int m = 0;	// byte counter modulo 56
  unsigned int c;

  if (sizeof(uint64_t) != 8)
    croak("sizeof(uint64_t) is %d, need 8\n", (int)sizeof(uint64_t));

  while (len-- > 0)
    {
      c = (unsigned char)*text++;
      uint64_t x = rotate56(rand56[c], m);
      h ^= x;
      if (++m >= 56) m = 0;
    }
  h |= ((uint64_t)m) << 56;
  return h;
}

static uint64_t cat_fp(uint64_t h1, uint64_t h2)
{
  unsigned int m1 = (h1 >> 56);
  unsigned int m2 = (h2 >> 56);
  uint64_t r = rotate56(h2, m1) ^ (h1 & 0x00ffffffffffffffLL);
  m2 += m1;
  if (m2 >= 56) m2 -= 56;
  r |= ((uint64_t)m2)<<56;
  return r; 
}

static int xc2i(unsigned char c)
{
  // ascii has numbers before upper before lower case.
  if (c <= '9') return c - '0';
  if (c <= 'F') return c - 'A' + 10;
  return c - 'a' + 10;
}

static uint64_t x2i64(unsigned char *t, int n)
{
  uint64_t h = 0;
  while (n-- > 0)
    h = (h<<4) + xc2i(*t++);
  return h;
}

static char *ll2x16(uint64_t fp)
{
  static char buf[18];
  sprintf(buf, "%08x%08x", (unsigned int)(fp>>32), (unsigned int)(fp & 0xffffffff));
  return buf;
}

#if 0
// same as ll2x16, but with 0x prefix
// may be used for human consumption. Databases don't like that.
static char *ll2x18(uint64_t fp)
{
  static char buf[20];
  sprintf(buf, "0x%08x%08x", (unsigned int)(fp>>32), (unsigned int)(fp & 0xffffffff));
  return buf;
}
#endif

static uint64_t cat_fp_x(const char *x1, const char *x2)
{
  uint64_t h1 = x2i64((unsigned char *)x1, strlen(x1));
  uint64_t h2 = x2i64((unsigned char *)x2, strlen(x2));
  return cat_fp(h1, h2);
}

// private version of \w, just like perl in ascii C locale.
// but also with quote chars, so that <div id="foo" name=bar>
// is preserverd during cooked()

static int is_word_ch_q(int c)
{
  if ((c <= 'z' && c >= 'a') ||
      (c <= 'Z' && c >= 'A') ||
      (c <= '9' && c >= '0') ||
       c == '_' || c == '"' || c == '\'')
    return 1;
  return 0;
}

// called with len including the trailing \n or \f.
// returns the number of char written to outp
// it never writes more than len chars to out.
static int cook_text(char *outp, const char *text, int len)
{
  char *p = outp;
  char *s = p;
  unsigned char lc = ' ';	// last char we sent to output
  int line_start = 1;		// we are at start of a line.
  int whitespace = 0;		// we saw whitespace chars since lc.

  while (len-- > 0)
    {
      unsigned char c = *text++;
      if (!c) continue;		// completly ignore \0 chars

      if (line_start && (c == '+' || c == '-' || c == '<' || c == '>')) 
        { 
	  line_start = 0; 
	  continue; 		// ignore typ. diff chars at line start.
	}
      line_start = 0;

      if (c <= ' ') 	// (Whitespace: all character codes <= 32)
        {
	  if (c == '\n' || c == '\r' || c == '\f' || c == '\v')
	    line_start = 1;
	  whitespace = 1;
	  continue;
	}

      // output a space *only* to prevent run together words.
      if (whitespace && is_word_ch_q(lc) && is_word_ch_q(c)) *p++ = ' ';
      whitespace = 0;

      // this ~-magic does not really fold utf8 to latin1.
      // maybe it helps to map other encodings.
      if (c >= 128)
        {
	  if (lc < 128) *p++ = '~';
	  lc = c;
	}
      else
        {
	  *p++ = lc = c;
	}
    }

  return p - s;
}


MODULE = Digest::FP56x1xor		PACKAGE = Digest::FP56x1xor		
PROTOTYPES: ENABLE

long gen_l(text)
    const char *text
  CODE:
    if (sizeof(uint64_t) != 8)
      croak("sizeof(uint64_t) is %d, need 8. Please try the gen() method\n", (int)sizeof(uint64_t));
    RETVAL = gen_fp(text, strlen(text));
  OUTPUT:
    RETVAL

long cat_l(h1, h2)
    long h1
    long h2
  CODE:
    RETVAL = cat_fp((uint64_t)h1, (uint64_t)h2);
  OUTPUT:
    RETVAL

SV *gen(sv_text, ...)
    SV *sv_text
  INIT:
    STRLEN text_len;
    IV start_off;
    IV len;
    const char *text;

    text = (const char *)SvPV(sv_text, text_len);
    if ( items > 1)
      {
        start_off = SvIV(ST(1));
        if (start_off > text_len)
	  croak("specified offset=%d is beyond text_len=%d", 
	    (int)start_off, (int)text_len);
	text_len -= start_off;
      }
    else
      start_off = 0;

    if ( items > 2)
      {
        len = SvIV(ST(2));
	if (len > text_len)
	  croak("specified length=%d exceeds text_len=%d", (int)len, (int)text_len);
        text_len = len;
      }

  CODE:
    uint64_t fp = gen_fp(text+start_off, text_len);
    RETVAL = newSVpvn(ll2x16(fp), 16);
  OUTPUT:
    RETVAL

SV *cat(x1, x2)
    const char *x1
    const char *x2
  CODE:
    uint64_t fp = cat_fp_x(x1, x2);
    RETVAL = newSVpvn(ll2x16(fp), 16);
  OUTPUT:
    RETVAL

SV *ll2x(fp)
    long fp;
  CODE:
    RETVAL = newSVpvn(ll2x16(fp), 16);
  OUTPUT:
    RETVAL

long x2l(x)
    const char *x
  CODE:
    RETVAL = x2i64((unsigned char *)x, strlen(x));
  OUTPUT:
    RETVAL

SV*
cooked(sv_text, ...)
    SV *sv_text
  INIT:
    STRLEN text_len;		// like strlen(text), but including '\0' bytes. STRLEN is unsigned!
    IV start_off;
    IV len;
    const char *text;
    char *cooked_text;
    int cooked_len;

    SV *text_out;	

    text = (const char *)SvPV(sv_text, text_len);
    if ( items > 1)
      {
        start_off = SvIV(ST(1));
        if (start_off > text_len)
	  croak("specified offset=%d is beyond text_len=%d", 
	    (int)start_off, (int)text_len);
	text_len -= start_off;
      }
    else
      start_off = 0;

    if ( items > 2)
      {
        len = SvIV(ST(2));
	if (len > text_len)
	  croak("specified length=%d exceeds text_len=%d", (int)len, (int)text_len);
        text_len = len;
      }

  CODE:
    cooked_text = (char *)malloc(text_len);	// never longer than raw text;
    cooked_len = cook_text(cooked_text, text+start_off, text_len);

    // transfer output from C to perl
    text_out = newSVpvn(cooked_text, cooked_len);

    // forget C
    free((char *)cooked_text);
    // do not free text, it points into perl proper. 
    // (Would cause an abort in PerlIOBuf_close)

    RETVAL = text_out;
  OUTPUT:
    RETVAL

