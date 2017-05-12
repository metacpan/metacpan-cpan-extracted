/* Digest::Adler32::XS implementation.
 *
 * Copyright (C) 2003 Davide Libenzi (code derived from libxdiff)
 * Copyright 2004, Geoff Richards
 * Copyright 2009, Information Balance
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#undef assert
#include <assert.h>

#define QEF_BUFSZ 8192

#if 0
#define QEF_DEBUG_IO
#endif


/* largest prime smaller than 65536 */
#define QEF_BASE 65521L

/* NMAX is the largest n such that 255n(n+1)/2 + (n+1)(BASE-1) <= 2^32-1 */
#define QEF_NMAX 5552

#define QEF_DO1(buf, i)  { s1 += buf[i]; s2 += s1; }
#define QEF_DO2(buf, i)  QEF_DO1(buf, i); QEF_DO1(buf, i + 1);
#define QEF_DO4(buf, i)  QEF_DO2(buf, i); QEF_DO2(buf, i + 2);
#define QEF_DO8(buf, i)  QEF_DO4(buf, i); QEF_DO4(buf, i + 4);
#define QEF_DO16(buf)    QEF_DO8(buf, 0); QEF_DO8(buf, 8);

static U32
adler32(U32 adler, const unsigned char *buf, size_t len)
{
    int k;
    U32 s1 = adler & 0xffff;
    U32 s2 = (adler >> 16) & 0xffff;

    assert(buf);

    while (len > 0) {
        k = len < QEF_NMAX ? len : QEF_NMAX;
        len -= k;
        while (k >= 16) {
            QEF_DO16(buf);
            buf += 16;
            k -= 16;
        }
        if (k != 0)
            do {
                s1 += *buf++;
                s2 += s1;
            } while (--k);
        s1 %= QEF_BASE;
        s2 %= QEF_BASE;
    }

    return (s2 << 16) | s1;
}

MODULE = Digest::Adler32::XS   PACKAGE = Digest::Adler32::XS

PROTOTYPES: DISABLE

U32
adler32 (U32 init, SV *s)
    PREINIT:
        STRLEN len;
        const unsigned char *buf;
        svtype t;
    CODE:
    	t =	SvTYPE(s);
    	if (t == SVt_NULL) {
    		XSRETURN_UNDEF;
    	}
        buf = (unsigned char *) SvPV(s, len);
        RETVAL = adler32(init, buf, len);
    OUTPUT:
        RETVAL

