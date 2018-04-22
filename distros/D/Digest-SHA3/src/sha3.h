/*
 * sha3.h: header file for SHA-3 routines
 *
 * Ref: http://keccak.noekeon.org/specs_summary.html
 *
 * Copyright (C) 2012-2018 Mark Shelor, All Rights Reserved
 *
 * Version: 1.04
 * Fri Apr 20 16:25:30 MST 2018
 *
 */

#ifndef _INCLUDE_SHA3_H_
#define _INCLUDE_SHA3_H_

#include <limits.h>

#define SHA64_SHR(x, n)	((x) >> (n))
#define SHA64_SHL(x, n)	((x) << (n))

#define SHA64_ALIGNED

#if defined(ULONG_LONG_MAX) || defined(ULLONG_MAX) || defined(HAS_LONG_LONG)
	#define SHA_ULL_EXISTS
#endif

#if (((ULONG_MAX >> 16) >> 16) >> 16) >> 15 == 1UL
	#define SHA64	unsigned long
	#define SHA64_CONST(c)	c ## UL
#elif defined(SHA_ULL_EXISTS) && defined(LONGLONGSIZE) && LONGLONGSIZE == 8
	#define SHA64	unsigned long long
	#define SHA64_CONST(c)	c ## ULL
#elif defined(SHA_ULL_EXISTS)
	#undef  SHA64_ALIGNED
	#undef  SHA64_SHR
	#define SHA64_MAX	18446744073709551615ULL
	#define SHA64_SHR(x, n)	(((x) & SHA64_MAX) >> (n))
	#define SHA64	unsigned long long
	#define SHA64_CONST(c)	c ## ULL

	/* The following cases detect compilers that
	 * support 64-bit types in a non-standard way */

#elif defined(_MSC_VER)					/* Microsoft C */
	#define SHA64	unsigned __int64
	#define SHA64_CONST(c)	(SHA64) c
#endif

#if defined(BYTEORDER) && ((BYTEORDER==0x1234) || (BYTEORDER==0x12345678))
	#if defined(SHA64_ALIGNED)
		#define MEM2WORD(W, m)	Copy(m, W, 8, char)
	#endif
#endif

#if !defined(MEM2WORD)
	#define MEM2WORD(W, m) *(W) = 				\
		(SHA64) m[0] << 0  | (SHA64) m[1] << 8  |	\
		(SHA64) m[2] << 16 | (SHA64) m[3] << 24 |	\
		(SHA64) m[4] << 32 | (SHA64) m[5] << 40 |	\
		(SHA64) m[6] << 48 | (SHA64) m[7] << 56
#endif

#define SHA3_224	224
#define SHA3_256	256
#define SHA3_384	384
#define SHA3_512	512
#define SHAKE128	128000
#define SHAKE256	256000

#define SHA3_224_BLOCK_BITS	1152
#define SHA3_256_BLOCK_BITS	1088
#define SHA3_384_BLOCK_BITS	832
#define SHA3_512_BLOCK_BITS	576
#define SHAKE128_BLOCK_BITS	1344
#define SHAKE256_BLOCK_BITS	1088

#define SHA3_224_DIGEST_BITS	224
#define SHA3_256_DIGEST_BITS	256
#define SHA3_384_DIGEST_BITS	384
#define SHA3_512_DIGEST_BITS	512
#define SHAKE128_DIGEST_BITS	SHAKE128_BLOCK_BITS
#define SHAKE256_DIGEST_BITS	SHAKE256_BLOCK_BITS

#define SHA3_MAX_BLOCK_BITS	SHAKE128_BLOCK_BITS
#define SHA3_MAX_DIGEST_BITS	SHAKE128_DIGEST_BITS
#define SHA3_MAX_HEX_LEN	(SHA3_MAX_DIGEST_BITS / 4)
#define SHA3_MAX_BASE64_LEN	(1 + (SHA3_MAX_DIGEST_BITS / 6))

typedef struct SHA3 {
	int alg;
	SHA64 S[5][5];
	unsigned char block[SHA3_MAX_BLOCK_BITS/8];
	unsigned int blockcnt;
	unsigned int blocksize;
	unsigned char digest[SHA3_MAX_DIGEST_BITS/8];
	int digestlen;
	char hex[SHA3_MAX_HEX_LEN+1];
	char base64[SHA3_MAX_BASE64_LEN+1];
	int padded;
	int shake;
} SHA3;

#endif	/* _INCLUDE_SHA3_H_ */
