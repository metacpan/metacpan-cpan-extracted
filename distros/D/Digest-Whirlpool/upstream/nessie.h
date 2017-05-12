
#ifndef PORTABLE_C__
#define PORTABLE_C__

#include <limits.h>

/* Definition of minimum-width integer types
 * 
 * u8   -> unsigned integer type, at least 8 bits, equivalent to unsigned char
 * u16  -> unsigned integer type, at least 16 bits
 * u32  -> unsigned integer type, at least 32 bits
 *
 * s8, s16, s32  -> signed counterparts of u8, u16, u32
 *
 * Always use macro's T8(), T16() or T32() to obtain exact-width results,
 * i.e., to specify the size of the result of each expression.
 */

typedef unsigned char u8;

#if UINT_MAX >= 4294967295UL

typedef unsigned int u32;

#else

typedef unsigned long u32;

#endif


#ifdef _MSC_VER
typedef unsigned __int64 u64;
#define LL(v)   (v##i64)
#else  /* !_MSC_VER */
typedef unsigned long long u64;
#define LL(v)   (v##ULL)
#endif /* ?_MSC_VER */

/*
 * Whirlpool-specific definitions.
 */

#define DIGESTBYTES 64
#define DIGESTBITS  (8*DIGESTBYTES) /* 512 */

#define WBLOCKBYTES 64
#define WBLOCKBITS  (8*WBLOCKBYTES) /* 512 */

#define LENGTHBYTES 32
#define LENGTHBITS  (8*LENGTHBYTES) /* 256 */

typedef struct NESSIEstruct {
	u8  bitLength[LENGTHBYTES]; /* global number of hashed bits (256-bit counter) */
	u8  buffer[WBLOCKBYTES];	/* buffer of data to hash */
	int bufferBits;		        /* current number of bits on the buffer */
	int bufferPos;		        /* current (possibly incomplete) byte slot on the buffer */
	u64 hash[DIGESTBYTES/8];    /* the hashing state */
} NESSIEstruct;

#endif   /* PORTABLE_C__ */

