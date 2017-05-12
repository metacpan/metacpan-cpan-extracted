/* Creation date: 2008-04-06T02:35:32Z
 * Authors: Don
 */

/*

 Copyright (c) 2007-2010 Don Owens <don@regexguy.com>.  All rights reserved.

 This is free software; you can redistribute it and/or modify it under
 the Perl Artistic license.  You should have received a copy of the
 Artistic license with this distribution, in the file named
 "Artistic".  You may also obtain a copy from
 http://regexguy.com/license/Artistic

 This program is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

*/

/* $Header: /repository/projects/libjsonevt/utf32.c,v 1.3 2009-02-23 17:46:55 don Exp $ */

#include "utf32.h"

#define SAFE_SET_POINTER_VAL(ptr, val) if (ptr) { *(ptr) = val; }

uint32_t
utf32_bytes_to_unicode(const uint8_t *orig_buf, uint32_t buf_len, uint32_t *ret_len,
                       uint32_t is_little_endian) {
    
    const uint8_t *s = orig_buf;

    if (buf_len < 4) {
        /* must be at least 4 bytes in a valid utf-32 sequence*/
        SAFE_SET_POINTER_VAL(ret_len, 0);
        return 0;
    }

    SAFE_SET_POINTER_VAL(ret_len, 4);

    if (is_little_endian) {
        return ( *s | (s[1] << 8) | (s[2] << 16) | (s[3] << 24) );
    }
    else {
        return ( s[3] | (s[2] << 8) | (s[1] << 16) | (*s << 24) );
    }

    return 0;
}

uint32_t
utf32_unicode_to_bytes(uint32_t cp, uint8_t *out_buf, uint32_t output_little_endian) {
    uint8_t *d = out_buf;

    /* 0xd800 .. 0xdfff are ill-formed */
    if (cp >= 0xd800 && cp <= 0xdfff) {
        *d = 0;
        return 0;
    }

    if (output_little_endian) {
        *d++ = cp  & 0xff;
        *d++ = (cp & 0xff00)     >> 8;
        *d++ = (cp & 0xff0000)   >> 16;
        *d++ = (cp & 0xff000000) >> 24;

        return 4;
    }
    else {
        *d++ = (cp & 0xff000000) >> 24;
        *d++ = (cp & 0xff0000)   >> 16;
        *d++ = (cp & 0xff00)     >> 8;
        *d++ = cp  & 0xff;

        return 4;
    }

    return 0;
}


