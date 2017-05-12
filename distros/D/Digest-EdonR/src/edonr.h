/******************************************************************************
 * Tweaked Edon-R implementation for SUPERCOP, based on NIST API.
 *
 * (C) 2010 Jorn Amundsen <jorn.amundsen@ntnu.no>
 * ----------------------------------------------------------------------------
 *  $Id: EdonR.h 364 2010-12-13 07:01:24Z joern $
 *****************************************************************************/

#if defined(_WIN32) && defined(_MSC_VER) /* MS Visual C++ */
    typedef unsigned __int32 uint32_t;
    typedef unsigned __int64 uint64_t;
#else
/* tacitly assume ISO/IEC 9899:1999 <stdint.h> is present */
#include <stdint.h>
#endif

/* ANSI C header header for memory operations (move/copy) */
#include <string.h>

/* big endian support, provides no-op's if run on little endian hosts */
#include "byteorder.h"

/* General SHA-3 definitions */
typedef unsigned char BitSequence;
typedef uint64_t DataLength;
/*
 * EdonR allows to call Update() function consecutively only if the total length
 * of stored unprocessed data and the new supplied data is less than or equal to
 * the BLOCK_SIZE on which the compression functions operates.
 * Otherwise BAD_CONSECUTIVE_CALL_TO_UPDATE is returned.
 */
typedef enum {
	SUCCESS = 0,
	FAIL = 1,
	BAD_HASHLEN = 2,
	BAD_CONSECUTIVE_CALL_TO_UPDATE = 3
} HashReturn;


/* Specific algorithm definitions */
#define EdonR224_DIGEST_SIZE  28
#define EdonR224_BLOCK_SIZE   64
#define EdonR256_DIGEST_SIZE  32
#define EdonR256_BLOCK_SIZE   64
#define EdonR384_DIGEST_SIZE  48
#define EdonR384_BLOCK_SIZE  128
#define EdonR512_DIGEST_SIZE  64
#define EdonR512_BLOCK_SIZE  128

#define EdonR256_BLOCK_BITSIZE  512
#define EdonR512_BLOCK_BITSIZE 1024

typedef struct {
	uint32_t DoublePipe[16];
	BitSequence LastPart[EdonR256_BLOCK_SIZE * 2];
} Data256;
typedef struct {
	uint64_t DoublePipe[16];
	BitSequence LastPart[EdonR512_BLOCK_SIZE * 2];
} Data512;

typedef struct {
    int hashbitlen;

	/* + algorithm specific parameters */
	int unprocessed_bits;
	uint64_t bits_processed;
	union { 
		Data256  p256[1];
		Data512  p512[1];
    } pipe[1];
} hashState;

#define hashState224(x)  ((x)->pipe->p256)
#define hashState256(x)  ((x)->pipe->p256)
#define hashState384(x)  ((x)->pipe->p512)
#define hashState512(x)  ((x)->pipe->p512)

/* shift and rotate shortcuts */

#define shl(x,n)    ((x) << n)
#define shr(x,n)    ((x) >> n)

#define rotl32(x,n) (((x) << (n)) | ((x) >> (32 - (n))))
#define rotr32(x,n) (((x) >> (n)) | ((x) << (32 - (n))))

#define rotl64(x,n) (((x) << (n)) | ((x) >> (64 - (n))))
#define rotr64(x,n) (((x) >> (n)) | ((x) << (64 - (n))))

#if !defined(__C99_RESTRICT)
#define restrict /*restrict*/
#endif

HashReturn Init(hashState *state, int hashbitlen);
HashReturn Update(hashState *state, const BitSequence *data,
	DataLength databitlen);
HashReturn Final(hashState *state, BitSequence *hashval);
HashReturn Hash(int hashbitlen, const BitSequence *data, DataLength databitlen,
	BitSequence *hashval);
