#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <time.h>
#include <stdlib.h>
#include <stdint.h>

#include "perlmulticore.h"

/* NIST Secure Hash Algorithm */
/* heavily modified by Uwe Hollerbach <uh@alumni.caltech edu> */
/* from Peter C. Gutmann's implementation as found in */
/* Applied Cryptography by Bruce Schneier */
/* Further modifications to include the "UNRAVEL" stuff, below */

/* This code is in the public domain */

/* pcg: I was tempted to just rip this code off, after all, if you don't
 * demand anything I am inclined not to give anything. *Sigh* something
 * kept me from doing it, so here's the truth: I took this code from the
 * SHA1 perl module, since it looked reasonably well-crafted. I modified
 * it here and there, though.
 */

/*
 * we have lots of micro-optimizations here, this is just for toying
 * around...
 */

/* don't expect _too_ much from compilers for now. */
#if __GNUC__ > 2
#  define restrict __restrict__
#  define inline __inline__
#  ifdef __i386
#     define GCCX86ASM 1
#  endif
#elif __STDC_VERSION__ < 199900
#  define restrict
#  define inline
#endif

#if __GNUC__ < 2
#  define __attribute__(x)
#endif

#ifdef __i386
#  define a_regparm(n) __attribute__((__regparm__(n)))
#else
#  define a_regparm(n)
#endif

#define a_const __attribute__((__const__))

/* Useful defines & typedefs */

#if defined(U64TYPE) && (defined(USE_64_BIT_INT) || ((BYTEORDER != 0x1234) && (BYTEORDER != 0x4321)))
typedef U64TYPE XULONG;
#  if BYTEORDER == 0x1234
#    undef BYTEORDER
#    define BYTEORDER 0x12345678
#  elif BYTEORDER == 0x4321
#    undef BYTEORDER
#    define BYTEORDER 0x87654321
#  endif
#else
typedef uint_fast32_t XULONG;     /* 32-or-more-bit quantity */
#endif

#if GCCX86ASM
#  define zprefix(n) ({ int _r; __asm__ ("bsrl %1, %0" : "=r" (_r) : "r" (n)); 31 - _r ; })
#elif __GNUC__ > 2 && __GNUC_MINOR__ > 3
#  define zprefix(n) (__extension__ ({ uint32_t n__ = (n); n ? __builtin_clz (n) : 32; }))
#else
static int a_const zprefix (U32 n)
{
  static char zp[256] =
    {
      8, 7, 6, 6, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 4, 4,
      3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    };

  return
    n > 0xffffff ?      zp[n >> 24]
    : n > 0xffff ?  8 + zp[n >> 16]
    : n >   0xff ? 16 + zp[n >>  8]
    :              24 + zp[n];
}
#endif

#define SHA_BLOCKSIZE		64
#define SHA_DIGESTSIZE		20

typedef struct {
    U32 digest[5];		/* message digest */
    U32 count;		/* 32-bit bit count */
    int local;			/* unprocessed amount in data */
    U8 data[SHA_BLOCKSIZE];	/* SHA data buffer */
} SHA_INFO;


/* SHA f()-functions */
#define f1(x,y,z)	((x & y) | (~x & z))
#define f2(x,y,z)	(x ^ y ^ z)
#define f3(x,y,z)	((x & y) | (x & z) | (y & z))
#define f4(x,y,z)	(x ^ y ^ z)

/* SHA constants */
#define CONST1		0x5a827999L
#define CONST2		0x6ed9eba1L
#define CONST3		0x8f1bbcdcL
#define CONST4		0xca62c1d6L

/* truncate to 32 bits -- should be a null op on 32-bit machines */
#define T32(x)	((x) & 0xffffffffL)

/* 32-bit rotate */
#define R32(x,n)	T32(((x << n) | (x >> (32 - n))))

/* specific cases, for when the overall rotation is unraveled */
#define FA(n)	\
    T = T32(R32(A,5) + f##n(B,C,D) + E + *WP++ + CONST##n); B = R32(B,30)

#define FB(n)	\
    E = T32(R32(T,5) + f##n(A,B,C) + D + *WP++ + CONST##n); A = R32(A,30)

#define FC(n)	\
    D = T32(R32(E,5) + f##n(T,A,B) + C + *WP++ + CONST##n); T = R32(T,30)

#define FD(n)	\
    C = T32(R32(D,5) + f##n(E,T,A) + B + *WP++ + CONST##n); E = R32(E,30)

#define FE(n)	\
    B = T32(R32(C,5) + f##n(D,E,T) + A + *WP++ + CONST##n); D = R32(D,30)

#define FT(n)	\
    A = T32(R32(B,5) + f##n(C,D,E) + T + *WP++ + CONST##n); C = R32(C,30)

static void a_regparm(1) sha_transform(SHA_INFO *restrict sha_info)
{
    int i;
    U8 *restrict dp;
    U32 A, B, C, D, E, W[80], *restrict WP;
    XULONG T;

    dp = sha_info->data;

#if BYTEORDER == 0x1234
    assert(sizeof(XULONG) == 4);
#  ifdef HAS_NTOHL
    for (i = 0; i < 16; ++i) {
	T = *((XULONG *) dp);
	dp += 4;
        W[i] = ntohl (T);
    }
#  else
    for (i = 0; i < 16; ++i) {
	T = *((XULONG *) dp);
	dp += 4;
	W[i] =  ((T << 24) & 0xff000000) | ((T <<  8) & 0x00ff0000) |
		((T >>  8) & 0x0000ff00) | ((T >> 24) & 0x000000ff);
    }
#  endif
#elif BYTEORDER == 0x4321
    assert(sizeof(XULONG) == 4);
    for (i = 0; i < 16; ++i) {
	T = *((XULONG *) dp);
	dp += 4;
	W[i] = T32(T);
    }
#elif BYTEORDER == 0x12345678
    assert(sizeof(XULONG) == 8);
    for (i = 0; i < 16; i += 2) {
	T = *((XULONG *) dp);
	dp += 8;
	W[i] =  ((T << 24) & 0xff000000) | ((T <<  8) & 0x00ff0000) |
		((T >>  8) & 0x0000ff00) | ((T >> 24) & 0x000000ff);
	T >>= 32;
	W[i+1] = ((T << 24) & 0xff000000) | ((T <<  8) & 0x00ff0000) |
		 ((T >>  8) & 0x0000ff00) | ((T >> 24) & 0x000000ff);
    }
#elif BYTEORDER == 0x87654321
    assert(sizeof(XULONG) == 8);
    for (i = 0; i < 16; i += 2) {
	T = *((XULONG *) dp);
	dp += 8;
	W[i] = T32(T >> 32);
	W[i+1] = T32(T);
    }
#else
#error Unknown byte order -- you need to add code here
#endif

    for (i = 16; i < 80; ++i)
      {
        T = W[i-3] ^ W[i-8] ^ W[i-14] ^ W[i-16];
        W[i] = R32(T,1);
      }

    A = sha_info->digest[0];
    B = sha_info->digest[1];
    C = sha_info->digest[2];
    D = sha_info->digest[3];
    E = sha_info->digest[4];

    WP = W;
    FA(1); FB(1); FC(1); FD(1); FE(1); FT(1); FA(1); FB(1); FC(1); FD(1);
    FE(1); FT(1); FA(1); FB(1); FC(1); FD(1); FE(1); FT(1); FA(1); FB(1);
    FC(2); FD(2); FE(2); FT(2); FA(2); FB(2); FC(2); FD(2); FE(2); FT(2);
    FA(2); FB(2); FC(2); FD(2); FE(2); FT(2); FA(2); FB(2); FC(2); FD(2);
    FE(3); FT(3); FA(3); FB(3); FC(3); FD(3); FE(3); FT(3); FA(3); FB(3);
    FC(3); FD(3); FE(3); FT(3); FA(3); FB(3); FC(3); FD(3); FE(3); FT(3);
    FA(4); FB(4); FC(4); FD(4); FE(4); FT(4); FA(4); FB(4); FC(4); FD(4);
    FE(4); FT(4); FA(4); FB(4); FC(4); FD(4); FE(4); FT(4); FA(4); FB(4);

    sha_info->digest[0] = T32(sha_info->digest[0] + E);
    sha_info->digest[1] = T32(sha_info->digest[1] + T);
    sha_info->digest[2] = T32(sha_info->digest[2] + A);
    sha_info->digest[3] = T32(sha_info->digest[3] + B);
    sha_info->digest[4] = T32(sha_info->digest[4] + C);
}

/* initialize the SHA digest */

static void sha_init(SHA_INFO *restrict sha_info)
{
    sha_info->digest[0] = 0x67452301L;
    sha_info->digest[1] = 0xefcdab89L;
    sha_info->digest[2] = 0x98badcfeL;
    sha_info->digest[3] = 0x10325476L;
    sha_info->digest[4] = 0xc3d2e1f0L;
    sha_info->count = 0L;
    sha_info->local = 0;
}

/* update the SHA digest */

static void sha_update(SHA_INFO *restrict sha_info, U8 *restrict buffer, int count)
{
    int i;

    sha_info->count += count;
    if (sha_info->local) {
	i = SHA_BLOCKSIZE - sha_info->local;
	if (i > count) {
	    i = count;
	}
	memcpy(((U8 *) sha_info->data) + sha_info->local, buffer, i);
	count -= i;
	buffer += i;
	sha_info->local += i;
	if (sha_info->local == SHA_BLOCKSIZE) {
	    sha_transform(sha_info);
	} else {
	    return;
	}
    }
    while (count >= SHA_BLOCKSIZE) {
	memcpy(sha_info->data, buffer, SHA_BLOCKSIZE);
	buffer += SHA_BLOCKSIZE;
	count -= SHA_BLOCKSIZE;
	sha_transform(sha_info);
    }
    memcpy(sha_info->data, buffer, count);
    sha_info->local = count;
}

/* finish computing the SHA digest */
static int sha_final(SHA_INFO *sha_info)
{
  int count = sha_info->count;
  int local = sha_info->local;

  sha_info->data[local] = 0x80;

  if (sha_info->local >= SHA_BLOCKSIZE - 8) {
    memset(sha_info->data + local + 1, 0, SHA_BLOCKSIZE - 1 - local);
    sha_transform(sha_info);
    memset(sha_info->data, 0, SHA_BLOCKSIZE - 2);
  } else {
    memset(sha_info->data + local + 1, 0, SHA_BLOCKSIZE - 3 - local);
  }

  sha_info->data[62] = count >> 5;
  sha_info->data[63] = count << 3;

  sha_transform (sha_info);

  return sha_info->digest[0]
           ? zprefix (sha_info->digest[0])
           : zprefix (sha_info->digest[1]) + 32;
}

#define TRIALCHAR "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!#$%&()*+,-./;<=>?@[]{}^_|"

static char
nextenc[256];

static char
rand_char ()
{
  return TRIALCHAR[(int)(Drand01 () * sizeof (TRIALCHAR))];
}

typedef double (*NVTime)(void);

static double
simple_nvtime (void)
{
  return time (0);
}

static NVTime
get_nvtime (void)
{
  SV **svp = hv_fetch (PL_modglobal, "Time::NVtime", 12, 0);

  if (svp && SvIOK(*svp))
    return INT2PTR(NVTime, SvIV(*svp));
  else
    return simple_nvtime;

}

MODULE = Digest::Hashcash		PACKAGE = Digest::Hashcash

BOOT:
{
   int i;

   for (i = 0; i < sizeof (TRIALCHAR); i++)
     nextenc[TRIALCHAR[i]] = TRIALCHAR[(i + 1) % sizeof (TRIALCHAR)];
}

PROTOTYPES: ENABLE

# could be improved quite a bit in accuracy
NV
_estimate_rounds ()
	CODE:
{
        char data[40];
        NVTime nvtime = get_nvtime ();
        NV t1, t2, t;
        int count = 0;
        SHA_INFO ctx;

        t = nvtime ();
        do {
          t1 = nvtime ();
        } while (t == t1);

        t = t2 = nvtime ();
        do {
          volatile int i;
          sha_init (&ctx);
          sha_update (&ctx, data, sizeof (data));
          i = sha_final (&ctx);

          if (!(++count & 1023))
            t2 = nvtime ();

        } while (t == t2);

        RETVAL = (NV)count / (t2 - t1);
}
        OUTPUT:
        RETVAL

SV *
_gentoken (int size, IV timestamp, char *resource, char *trial = "", int extrarand = 0)
	CODE:
{
        SHA_INFO ctx1, ctx;
        char *token, *seq, *s;
        int toklen, i;
        time_t tstamp = timestamp ? timestamp : time (0);
        struct tm *tm = gmtime (&tstamp);

        New (0, token,
             1 + 1                    // version
             + 12 + 1                 // time field sans century
             + strlen (resource) + 1  // ressource
             + strlen (trial) + extrarand + 8 + 1 // trial
             + 1,
             char);

        if (!token)
          croak ("out of memory");

        if (size > 64)
          croak ("size must be <= 64 in this implementation\n");

        toklen = sprintf (token, "%d:%02d%02d%02d%02d%02d%02d:%s:%s",
                          0, tm->tm_year % 100, tm->tm_mon + 1, tm->tm_mday,
                          tm->tm_hour, tm->tm_min, tm->tm_sec,
                          resource, trial);

        if (toklen > 8000)
          croak ("token length must be <= 8000 in this implementation\n");

        perlinterp_release ();

        i = toklen + extrarand;
        while (toklen < i)
          token[toklen++] = rand_char ();

        sha_init (&ctx1);
        sha_update (&ctx1, token, toklen);

        seq = token + toklen;
        i +=  8;
        while (toklen < i)
          token[toklen++] = rand_char ();

        for (;;)
          {
            ctx = ctx1; // this "optimization" can help a lot for longer resource strings
            sha_update (&ctx, seq, 8);
            i = sha_final (&ctx);

            if (i >= size)
              break;

            s = seq;
            do {
              *s = nextenc [*s];
            } while (*s++ == 'a');
          }

        perlinterp_acquire ();

        RETVAL = newSVpvn (token, toklen);
}
	OUTPUT:
        RETVAL

int
_prefixlen (SV *tok)
	CODE:
{
        STRLEN toklen;
        char *token = SvPV (tok, toklen);
        SHA_INFO ctx;

        sha_init (&ctx);
        sha_update (&ctx, token, toklen);
        RETVAL = sha_final (&ctx);
}
	OUTPUT:
	RETVAL


