/* Creation date: 2008-04-05T22:10:32Z
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

/* $Header: /repository/projects/libjsonevt/utf16.c,v 1.3 2009-02-23 17:46:55 don Exp $ */

#include "utf16.h"

#define SAFE_SET_POINTER_VAL(ptr, val) if (ptr) { *(ptr) = val; }

uint32_t
utf16_bytes_to_unicode(const uint8_t *orig_buf, uint32_t buf_len, uint32_t *ret_len,
    uint32_t is_little_endian) {

    const uint8_t *s = orig_buf;

    if (buf_len < 2) {
        /* utf-16 requires at least two bytes for a code point */
        
        SAFE_SET_POINTER_VAL(ret_len, 0);
        return 0;
    }

    if (is_little_endian) {
        if ( (s[1] & 0xfc) == 0xd8 ) {
            /* surrogate pair -- requires 4 bytes */
            if (buf_len < 4) {
                SAFE_SET_POINTER_VAL(ret_len, 0);
                return 0;
            }
            
            SAFE_SET_POINTER_VAL(ret_len, 4);
            
            return 0x010000
                + ( s[2] | ((s[3] & 0x03) << 8) | ((*s & 0xff) << 10) | ((s[1] & 0x03) << 18) );
        }
        else {
            SAFE_SET_POINTER_VAL(ret_len, 2);

            return ( *s | (s[1] << 8) );
        }
    }
    else { /* big endian */
        if ( (*s & 0xfc) == 0xd8 ) {
            /* surrogate pair -- requires 4 bytes */
            if (buf_len < 4) {
                SAFE_SET_POINTER_VAL(ret_len, 0);
                return 0;
            }
            
            SAFE_SET_POINTER_VAL(ret_len, 4);
            return 0x010000
                + ( s[3] | ((s[2] & 0x03) << 8) | (s[1] << 10) | ((*s & 0x03) << 18) );
        }
        else {
            SAFE_SET_POINTER_VAL(ret_len, 2);
            
            return ( (*s << 8) | s[1] );
        }
    }

    return 0;
}

uint32_t
utf16_unicode_to_bytes(uint32_t cp, uint8_t *out_buf, uint32_t output_little_endian) {
    uint8_t *d = out_buf;

    if (cp < 0xffff) {
        /* single unsigned 16-bit code unit, so 2 bytes, with same value as the code point */

        /* but 0xd800 .. 0xdfff are ill-formed */
        if (cp >= 0xd800 && cp <= 0xdfff) {
            *d = 0;
            return 0;
        }

        /* big endian is the default */

        if (output_little_endian) {
            /* little endian */
            *d++ = cp & 0xff;
            *d++ = (cp & 0xff00) >> 8;
        }
        else {
            /* big endian */
            *d++ = (cp & 0xff00) >> 8;
            *d++ = cp & 0xff;
        }
        return 2;
    }
    else {
        /* use surrogate pairs */
        cp -= 0x010000;

        if (output_little_endian) {
            /* little endian */
            *d++ = (cp  & 0x000ff300) >> 10;
            *d++ = ((cp & 0x00300000) >> 18) | 0xd8;
            *d++ = cp   & 0x00ff;
            *d++ = ((cp & 0x0300)     >> 8)  | 0xdc;
        }
        else {
            /* big endian */
            *d++ = ((cp & 0x00300000) >> 18) | 0xd8;
            *d++ = (cp  & 0x000ff300) >> 10;
            *d++ = ((cp & 0x0300)     >> 8)  | 0xdc;
            *d++ = cp   & 0x00ff;
        }
        return 4;
    }

    return 0;
}


