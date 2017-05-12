/* 
   This code was copied form Rsync by Craig Barratt

   Copyright (C) Andrew Tridgell 1996
   Copyright (C) Paul Mackerras 1996
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include "global.h"
#include "md4.h"
#include <string.h>

/*
 * CHAR_OFFSET is 0 for rsync, and 31 for librsync.
 */
#define CHAR_OFFSET 0

/*
 * a simple 32 bit checksum that can be updated from either end
 * (inspired by Mark Adler's Adler-32 checksum)
 */
UINT4 adler32_checksum(char *buf1, int len)
{
    int i;
    UINT4 s1, s2;
    signed char *buf = (signed char*)buf1;

    s1 = s2 = 0;
    for ( i = 0 ; i < len - 4; i += 4 ) {
        s2 += 4 * (s1 + buf[i]) + 3 * buf[i+1] + 2 * buf[i+2] + buf[i+3] +
	      10 * CHAR_OFFSET;
        s1 += (buf[i+0] + buf[i+1] + buf[i+2] + buf[i+3] + 4 * CHAR_OFFSET);
    }
    for ( ; i < len ; i++ ) {
        s1 += (buf[i] + CHAR_OFFSET);
	s2 += s1;
    }
    return (s1 & 0xffff) + (s2 << 16);
}

/*
 * Compute both the alder32 and MD4 checksums for blockSize sized
 * blocks from a buffer buf of length len.  Seed is the optional
 * Rsync seed that is appended to the data.  Each block produces
 * 4 + min(md4DigestLen,16) bytes of output (alder32+MD4) in digest.
 * The number of blocks is ceil(len/blockSize).
 *
 * There are two special cases:
 *   md4DigestLen == 0: skip MD4; output has adler32 only.
 *   md4DigestLen > 16: output MD4 is really MD4 state, prior to
 *                      MD4FinalRsync().
 */
void rsync_checksum(unsigned char *buf, UINT4 len, UINT4 blockSize, UINT4 seed,
    unsigned char *digest, int md4DigestLen)
{
    unsigned char seedBytes[4];

    if ( md4DigestLen > 0 && seed ) {
	RsyncMD4Encode(seedBytes, &seed, 1);
    }
    while ( len > 0 ) {
	int thisLen = len < blockSize ? len : blockSize;
	UINT4 adler32 = adler32_checksum((char*)buf, thisLen);

	RsyncMD4Encode(digest, &adler32, 1);
	digest += 4;
	if ( md4DigestLen ) {
	    RsyncMD4_CTX md4;
	    RsyncMD4Init(&md4);
	    RsyncMD4Update(&md4, buf, thisLen);
	    if ( seed ) {
		RsyncMD4Update(&md4, seedBytes, 4);
	    }
	    if ( md4DigestLen < 0 ) {
		/*
		 * Done: just save the state and the partial buffer (no finish)
		 */
	        RsyncMD4Encode(digest, md4.state, 16);
		digest += 16;
                memcpy(digest, md4.buffer, thisLen % 64);
                digest += thisLen % 64;
	    } else if ( md4DigestLen >= 16 ) {
		/*
		 * Normal finish: save all 16 bytes
		 */
		RsyncMD4FinalRsync(digest, &md4);
		digest += 16;
	    } else {
		unsigned char md4Digest[16];
		/*
		 * Finish and truncate to md4DigestLen bytes
		 */
		RsyncMD4FinalRsync(md4Digest, &md4);
		memcpy(digest, md4Digest, md4DigestLen);
		digest += md4DigestLen;
	    }
	}
	len -= thisLen;
	buf += thisLen;
    }
}

/*
 * Update the MD4 digest by adding the seed to the data.  Since
 * the rsync seed changes each time we need to add the seed.
 * We can do this by restoring the MD4 state (16 bytes plus
 * the length).  Each block has length blockSize, except the
 * last block, which is blockLastLen.
 *
 * The input data should be of length 20 * blockCnt.
 * The first block is blockStart (usually 0).  The length
 * of the last block is blockLastLen.  If seed == 0 then
 * it is skipped, and the MD4 digest is simply optionally
 * truncated.
 *
 * md4DigestLen is used to specify the MD4 digest length (eg: 2 or 16).
 * The output data size is blockCnt * (4 + md4DigestLen) bytes.
 */
void rsync_checksum_update(unsigned char *digestIn, UINT4 blockCnt,
    UINT4 blockSize, UINT4 blockLastLen, UINT4 seed,
    unsigned char *digestOut, int md4DigestLen)
{
    unsigned char seedBytes[4];

    if ( seed ) {
	RsyncMD4Encode(seedBytes, &seed, 1);
    }
    if ( md4DigestLen > 16 || md4DigestLen < 0 ) {
	md4DigestLen = 16;
    }
    while ( blockCnt-- ) {
        RsyncMD4_CTX md4;
	/*
	 * Copy adler32
	 */
	memcpy(digestOut, digestIn, 4);
	digestIn  += 4;
	digestOut += 4;
        RsyncMD4Init(&md4);
        RsyncMD4Decode(md4.state, digestIn, 16);
        digestIn  += 16;
        if ( blockCnt ) {
            md4.count[0] = blockSize << 3;
            md4.count[1] = blockSize >> 29;
            memcpy(md4.buffer, digestIn, blockSize % 64);
            digestIn += blockSize % 64;
        } else {
            md4.count[0] = blockLastLen << 3;
            md4.count[1] = blockLastLen >> 29;
            memcpy(md4.buffer, digestIn, blockLastLen % 64);
            digestIn += blockLastLen % 64;
        }
        if ( seed ) {
            RsyncMD4Update(&md4, seedBytes, 4);
        }
        if ( md4DigestLen == 16 ) {
            /*
             * Normal finish: save all 16 bytes
             */
            RsyncMD4FinalRsync(digestOut, &md4);
        } else {
            unsigned char md4Digest[16];
            /*
             * Finish and truncate to md4DigestLen bytes
             */
            RsyncMD4FinalRsync(md4Digest, &md4);
            memcpy(digestOut, md4Digest, md4DigestLen);
        }
        digestOut += md4DigestLen;
    }
}
