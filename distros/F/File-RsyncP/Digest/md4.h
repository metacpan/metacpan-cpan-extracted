/* MD4.H - header file for MD4C.C
 */

/* Copyright (C) 1991-2, RSA Data Security, Inc. Created 1991. All
   rights reserved.

   License to copy and use this software is granted provided that it
   is identified as the "RSA Data Security, Inc. MD4 Message-Digest
   Algorithm" in all material mentioning or referencing this software
   or this function.

   License is also granted to make and use derivative works provided
   that such works are identified as "derived from the RSA Data
   Security, Inc. MD4 Message-Digest Algorithm" in all material
   mentioning or referencing the derived work.

   RSA Data Security, Inc. makes no representations concerning either
   the merchantability of this software or the suitability of this
   software for any particular purpose. It is provided "as is"
   without express or implied warranty of any kind.

   These notices must be retained in any copies of any part of this
   documentation and/or software.
 */

/* MD4 context. */
typedef struct {
  UINT4 state[4];                                   /* state (ABCD) */
  UINT4 count[2];        /* number of bits, modulo 2^64 (lsb first) */
  unsigned char buffer[64];                         /* input buffer */
  /*
   * MD4 finalization for Rsync compatability.  For protocol version <= 26
   * (rsync <= 2.5.6) rsync has a bug where it doesn't append the pad when
   * the last fragment is empty (digest size is a multiple of 64).  Rsync
   * also only has a 32 bit byte counter, so the number of bits overflows
   * for >= 512MB.  Both bugs are fixed for protocol version >= 27.
   */
  unsigned char rsyncMD4Bug;
} RsyncMD4_CTX;

void RsyncMD4Init PROTO_LIST ((RsyncMD4_CTX *));
void RsyncMD4Update PROTO_LIST
  ((RsyncMD4_CTX *, unsigned char *, unsigned int));
void RsyncMD4Final PROTO_LIST ((unsigned char [16], RsyncMD4_CTX *));
void RsyncMD4Encode PROTO_LIST
  ((unsigned char *, UINT4 *, unsigned int));
void RsyncMD4FinalRsync PROTO_LIST ((unsigned char [16], RsyncMD4_CTX *));
void RsyncMD4Decode PROTO_LIST
  ((UINT4 *, unsigned char *, unsigned int));
