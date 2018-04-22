/*
 * sha3.c: routines to compute SHA-3 digests
 *
 * Ref: http://keccak.noekeon.org/specs_summary.html
 *
 * Copyright (C) 2012-2018 Mark Shelor, All Rights Reserved
 *
 * Version: 1.04
 * Fri Apr 20 16:25:30 MST 2018
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include "sha3.h"

#define UCHR	unsigned char		/* useful abbreviations */
#define UINT	unsigned int
#define ULNG	unsigned long
#define W64	SHA64
#define C64	SHA64_CONST
#define SR64	SHA64_SHR
#define SL64	SHA64_SHL

/* word2mem: write 64-bit value in little-endian order */
static void word2mem(UCHR *mem, W64 w)
{
	int i;
	UCHR *p = mem;

	for (i = 0; i < 8; i++, w >>= 8)
		*p++ = (UCHR) (w & 0xff);
}

static const W64 RC[] = {	/* Keccak round constants */
	C64(0x0000000000000001), C64(0x0000000000008082),
	C64(0x800000000000808a), C64(0x8000000080008000),
	C64(0x000000000000808b), C64(0x0000000080000001),
	C64(0x8000000080008081), C64(0x8000000000008009),
	C64(0x000000000000008a), C64(0x0000000000000088),
	C64(0x0000000080008009), C64(0x000000008000000a),
	C64(0x000000008000808b), C64(0x800000000000008b),
	C64(0x8000000000008089), C64(0x8000000000008003),
	C64(0x8000000000008002), C64(0x8000000000000080),
	C64(0x000000000000800a), C64(0x800000008000000a),
	C64(0x8000000080008081), C64(0x8000000000008080),
	C64(0x0000000080000001), C64(0x8000000080008008)
};

/* ROTL: rotate 64-bit word left by n bit positions */
#define ROTL(w, n) (SR64((w), (64 - (n))) | SL64((w), (n)))

/* keccak_f: apply KECCAK-f[1600] permutation for 24 rounds */
static void keccak_f(W64 A[][5])
{
	int i;
	const W64 *rc = RC;
	for (i = 0; i < 24; i++, rc++) {
		W64 B[5][5], C[5], D[5];
		C[0] = A[0][0]^A[0][1]^A[0][2]^A[0][3]^A[0][4];
		C[1] = A[1][0]^A[1][1]^A[1][2]^A[1][3]^A[1][4];
		C[2] = A[2][0]^A[2][1]^A[2][2]^A[2][3]^A[2][4];
		C[3] = A[3][0]^A[3][1]^A[3][2]^A[3][3]^A[3][4];
		C[4] = A[4][0]^A[4][1]^A[4][2]^A[4][3]^A[4][4];
		D[0] = C[4] ^ ROTL(C[1], 1);
		D[1] = C[0] ^ ROTL(C[2], 1);
		D[2] = C[1] ^ ROTL(C[3], 1);
		D[3] = C[2] ^ ROTL(C[4], 1);
		D[4] = C[3] ^ ROTL(C[0], 1);
		A[0][0] ^= D[0];
		A[0][1] ^= D[0];
		A[0][2] ^= D[0];
		A[0][3] ^= D[0];
		A[0][4] ^= D[0];
		A[1][0] ^= D[1];
		A[1][1] ^= D[1];
		A[1][2] ^= D[1];
		A[1][3] ^= D[1];
		A[1][4] ^= D[1];
		A[2][0] ^= D[2];
		A[2][1] ^= D[2];
		A[2][2] ^= D[2];
		A[2][3] ^= D[2];
		A[2][4] ^= D[2];
		A[3][0] ^= D[3];
		A[3][1] ^= D[3];
		A[3][2] ^= D[3];
		A[3][3] ^= D[3];
		A[3][4] ^= D[3];
		A[4][0] ^= D[4];
		A[4][1] ^= D[4];
		A[4][2] ^= D[4];
		A[4][3] ^= D[4];
		A[4][4] ^= D[4];
		B[0][0] = A[0][0];
		B[1][3] = ROTL(A[0][1], 36);
		B[2][1] = ROTL(A[0][2], 3);
		B[3][4] = ROTL(A[0][3], 41);
		B[4][2] = ROTL(A[0][4], 18);
		B[0][2] = ROTL(A[1][0], 1);
		B[1][0] = ROTL(A[1][1], 44);
		B[2][3] = ROTL(A[1][2], 10);
		B[3][1] = ROTL(A[1][3], 45);
		B[4][4] = ROTL(A[1][4], 2);
		B[0][4] = ROTL(A[2][0], 62);
		B[1][2] = ROTL(A[2][1], 6);
		B[2][0] = ROTL(A[2][2], 43);
		B[3][3] = ROTL(A[2][3], 15);
		B[4][1] = ROTL(A[2][4], 61);
		B[0][1] = ROTL(A[3][0], 28);
		B[1][4] = ROTL(A[3][1], 55);
		B[2][2] = ROTL(A[3][2], 25);
		B[3][0] = ROTL(A[3][3], 21);
		B[4][3] = ROTL(A[3][4], 56);
		B[0][3] = ROTL(A[4][0], 27);
		B[1][1] = ROTL(A[4][1], 20);
		B[2][4] = ROTL(A[4][2], 39);
		B[3][2] = ROTL(A[4][3], 8);
		B[4][0] = ROTL(A[4][4], 14);
		A[0][0] = B[0][0] ^ (~B[1][0] & B[2][0]);
		A[0][1] = B[0][1] ^ (~B[1][1] & B[2][1]);
		A[0][2] = B[0][2] ^ (~B[1][2] & B[2][2]);
		A[0][3] = B[0][3] ^ (~B[1][3] & B[2][3]);
		A[0][4] = B[0][4] ^ (~B[1][4] & B[2][4]);
		A[1][0] = B[1][0] ^ (~B[2][0] & B[3][0]);
		A[1][1] = B[1][1] ^ (~B[2][1] & B[3][1]);
		A[1][2] = B[1][2] ^ (~B[2][2] & B[3][2]);
		A[1][3] = B[1][3] ^ (~B[2][3] & B[3][3]);
		A[1][4] = B[1][4] ^ (~B[2][4] & B[3][4]);
		A[2][0] = B[2][0] ^ (~B[3][0] & B[4][0]);
		A[2][1] = B[2][1] ^ (~B[3][1] & B[4][1]);
		A[2][2] = B[2][2] ^ (~B[3][2] & B[4][2]);
		A[2][3] = B[2][3] ^ (~B[3][3] & B[4][3]);
		A[2][4] = B[2][4] ^ (~B[3][4] & B[4][4]);
		A[3][0] = B[3][0] ^ (~B[4][0] & B[0][0]);
		A[3][1] = B[3][1] ^ (~B[4][1] & B[0][1]);
		A[3][2] = B[3][2] ^ (~B[4][2] & B[0][2]);
		A[3][3] = B[3][3] ^ (~B[4][3] & B[0][3]);
		A[3][4] = B[3][4] ^ (~B[4][4] & B[0][4]);
		A[4][0] = B[4][0] ^ (~B[0][0] & B[1][0]);
		A[4][1] = B[4][1] ^ (~B[0][1] & B[1][1]);
		A[4][2] = B[4][2] ^ (~B[0][2] & B[1][2]);
		A[4][3] = B[4][3] ^ (~B[0][3] & B[1][3]);
		A[4][4] = B[4][4] ^ (~B[0][4] & B[1][4]);
		A[0][0] ^= *rc;
	}
}

/* sha3: update SHA3 state with one block of data */
static void sha3(SHA3 *s, UCHR *block)
{
	unsigned int i, x, y;
	W64 P0[5][5];

	for (i = 0; i < s->blocksize/64; i++, block += 8)
		MEM2WORD(&P0[i%5][i/5], block);
	for (x = 0; x < 5; x++)
		for (y = 0; y < 5; y++) {
			if (x + y*5 >= s->blocksize/64)
				break;
			s->S[x][y] ^= P0[x][y];
		}
	keccak_f(s->S);
}

/* digcpy: write SHA3 state to digest buffer */
static UCHR *digcpy(SHA3 *s)
{
	unsigned int x, y;
	UCHR *Z = s->digest;
	int outbits = s->digestlen*8;

	while (outbits > 0) {
		for (y = 0; y < 5; y++)
			for (x = 0; x < 5; x++, Z += 8) {
				if (x + y*5 >= s->blocksize/64)
					break;
				word2mem(Z, s->S[x][y]);
			}
		if ((outbits -= (int) s->blocksize) > 0)
			keccak_f(s->S);
	}
	return(s->digest);
}

#define BITSET(s, pos)  s[(pos) >> 3] &  (UCHR)  (0x01 << ((pos) % 8))
#define SETBIT(s, pos)  s[(pos) >> 3] |= (UCHR)  (0x01 << ((pos) % 8))
#define CLRBIT(s, pos)  s[(pos) >> 3] &= (UCHR) ~(0x01 << ((pos) % 8))
#define NBYTES(nbits)   (((nbits) + 7) >> 3)
#define HEXLEN(nbytes)	((nbytes) << 1)
#define B64LEN(nbytes)	(((nbytes) % 3 == 0) ? ((nbytes) / 3) * 4 \
			: ((nbytes) / 3) * 4 + ((nbytes) % 3) + 1)

#define SHA3_INIT(s, algo, xof)					\
	do {							\
		Zero(s, 1, SHA3);				\
		s->alg = algo;					\
		s->shake = xof;					\
		s->blocksize = algo ## _BLOCK_BITS;		\
		s->digestlen = algo ## _DIGEST_BITS >> 3;	\
	} while (0)

/* sharewind: resets digest object */
static void sharewind(SHA3 *s)
{
	if      (s->alg == SHA3_224) SHA3_INIT(s, SHA3_224, 0);
	else if (s->alg == SHA3_256) SHA3_INIT(s, SHA3_256, 0);
	else if (s->alg == SHA3_384) SHA3_INIT(s, SHA3_384, 0);
	else if (s->alg == SHA3_512) SHA3_INIT(s, SHA3_512, 0);
	else if (s->alg == SHAKE128) SHA3_INIT(s, SHAKE128, 1);
	else if (s->alg == SHAKE256) SHA3_INIT(s, SHAKE256, 1);
}

/* shainit: initializes digest object */
static int shainit(SHA3 *s, int alg)
{
	if (alg != SHA3_224 && alg != SHA3_256 &&
		alg != SHA3_384 && alg != SHA3_512 &&
		alg != SHAKE128 && alg != SHAKE256)
		return 0;
	s->alg = alg;
	sharewind(s);
	return 1;
}

/* shadirect: updates state directly (w/o going through s->block) */
static ULNG shadirect(UCHR *bitstr, ULNG bitcnt, SHA3 *s)
{
	ULNG savecnt = bitcnt;

	while (bitcnt >= s->blocksize) {
		sha3(s, bitstr);
		bitstr += (s->blocksize >> 3);
		bitcnt -= s->blocksize;
	}
	if (bitcnt > 0) {
		Copy(bitstr, s->block, NBYTES(bitcnt), char);
		s->blockcnt = bitcnt;
	}
	return(savecnt);
}

/* shabytes: updates state for byte-aligned data in s->block */
static ULNG shabytes(UCHR *bitstr, ULNG bitcnt, SHA3 *s)
{
	UINT offset;
	UINT nbits;
	ULNG savecnt = bitcnt;

	offset = s->blockcnt >> 3;
	if (s->blockcnt + bitcnt >= s->blocksize) {
		nbits = s->blocksize - s->blockcnt;
		Copy(bitstr, s->block+offset, nbits>>3, char);
		bitcnt -= nbits;
		bitstr += (nbits >> 3);
		sha3(s, s->block), s->blockcnt = 0;
		shadirect(bitstr, bitcnt, s);
	}
	else {
		Copy(bitstr, s->block+offset, NBYTES(bitcnt), char);
		s->blockcnt += bitcnt;
	}
	return(savecnt);
}

/* shabits: updates state for bit-aligned data in s->block */
static ULNG shabits(UCHR *bitstr, ULNG bitcnt, SHA3 *s)
{
	ULNG i;

	for (i = 0UL; i < bitcnt; i++) {
		if (BITSET(bitstr, i))
			SETBIT(s->block, s->blockcnt);
		else
			CLRBIT(s->block, s->blockcnt);
		if (++s->blockcnt == s->blocksize)
			sha3(s, s->block), s->blockcnt = 0;
	}
	return(bitcnt);
}

/* shawrite: triggers a state update using data in bitstr/bitcnt */
static ULNG shawrite(UCHR *bitstr, ULNG bitcnt, SHA3 *s)
{
	if (!bitcnt)
		return(0);
	if (s->blockcnt == 0)
		return(shadirect(bitstr, bitcnt, s));
	else if (s->blockcnt % 8 == 0)
		return(shabytes(bitstr, bitcnt, s));
	else
		return(shabits(bitstr, bitcnt, s));
}

/* shapad: pads byte-aligned block with 0*1 and computes final digest */
static void shapad(SHA3 *s)
{
	while (s->blockcnt < s->blocksize)
		s->block[s->blockcnt>>3] = 0x00, s->blockcnt += 8;
	s->block[(s->blocksize>>3)-1] |= 0x80;
	sha3(s, s->block);
}

/* shafinish: pads remaining block(s) and computes final digest state */
static void shafinish(SHA3 *s)
{
	UCHR domain = s->shake ? 0x1f : 0x06;

	if (s->padded)
		return;
	s->padded = 1;
	if (s->blockcnt % 8 == 0) {
		s->block[s->blockcnt>>3] = domain;
		s->blockcnt += 8;
		shapad(s);
		return;
	}
	shawrite((UCHR *) &domain, s->shake ? 5 : 3, s);
	while (s->blockcnt % 8)
		CLRBIT(s->block, s->blockcnt), s->blockcnt++;
	shapad(s);
}

/* shasqueeze: returns pointer to squeezed digest (binary) */
static UCHR *shasqueeze(SHA3 *s)
{
	if (s->alg != SHAKE128 && s->alg != SHAKE256)
		return(NULL);
	digcpy(s);
	keccak_f(s->S);
	return(s->digest);
}

#define shadigest(state)	digcpy(state)

/* xmap: translation map for hexadecimal encoding */
static const char xmap[] =
	"0123456789abcdef";

/* shahex: returns pointer to current digest (hexadecimal) */
static char *shahex(SHA3 *s)
{
	int i;
	char *h;
	UCHR *d;

	d = digcpy(s);
	s->hex[0] = '\0';
	if (HEXLEN((size_t) s->digestlen) >= sizeof(s->hex))
		return(s->hex);
	for (i = 0, h = s->hex; i < s->digestlen; i++) {
		*h++ = xmap[(*d >> 4) & 0x0f];
		*h++ = xmap[(*d++   ) & 0x0f];
	}
	*h = '\0';
	return(s->hex);
}

/* bmap: translation map for Base 64 encoding */
static const char bmap[] =
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/* encbase64: encodes input (0 to 3 bytes) into Base 64 */
static void encbase64(UCHR *in, int n, char *out)
{
	UCHR byte[3] = {0, 0, 0};

	out[0] = '\0';
	if (n < 1 || n > 3)
		return;
	Copy(in, byte, (unsigned) n, UCHR);
	out[0] = bmap[byte[0] >> 2];
	out[1] = bmap[((byte[0] & 0x03) << 4) | (byte[1] >> 4)];
	out[2] = bmap[((byte[1] & 0x0f) << 2) | (byte[2] >> 6)];
	out[3] = bmap[byte[2] & 0x3f];
	out[n+1] = '\0';
}

/* shabase64: returns pointer to current digest (Base 64) */
static char *shabase64(SHA3 *s)
{
	int n;
	UCHR *q;
	char out[5];

	q = digcpy(s);
	s->base64[0] = '\0';
	if (B64LEN((size_t) s->digestlen) >= sizeof(s->base64))
		return(s->base64);
	for (n = s->digestlen; n > 3; n -= 3, q += 3) {
		encbase64(q, 3, out);
		strcat(s->base64, out);
	}
	encbase64(q, n, out);
	strcat(s->base64, out);
	return(s->base64);
}
