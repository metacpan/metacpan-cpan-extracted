/* Creation date: 2008-04-15T03:00:18Z
 * Authors: Don
 */

/*
Copyright (c) 2007-2010 Don Owens <don@regexguy.com>.  All rights reserved.

 This is free software; you can redistribute it and/or modify it under
 the Perl Artistic license.  You should have received a copy of the
 Artistic license with this distribution, in the file named
 "Artistic".  You may also obtain a copy from
 http://regexguy.com/license/Artistic

 This program is distributed in the hope that it will be
 useful, but WITHOUT ANY WARRANTY; without even the implied
 warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
*/

#include "old_common.h"
#include "libjsonevt/utf8.h"

/* #define UNLESS(stuff) if (! stuff) */
#define SAFE_SET_POINTER_VAL(ptr, val) if (ptr) { *(ptr) = val; }

uint32_t
common_utf8_bytes_to_unicode(const uint8_t *orig_buf, uint32_t buf_len, uint32_t *ret_len) {
    uint32_t this_octet;
    uint32_t code_point = 0;
    uint32_t expected_len = 0;
    uint32_t len = 0;
    const uint8_t *buf = orig_buf;
    
    if (buf_len == 0) {
        SAFE_SET_POINTER_VAL(ret_len, 0);
        return 0;
    }
        
    this_octet = *buf;
        
    if (UTF8_BYTE_IS_INVARIANT(this_octet)) {
        SAFE_SET_POINTER_VAL(ret_len, 1);
        return this_octet;
    }

    /* the first byte should not be a continuation byte */
    if (UTF8_IS_CONTINUATION_BYTE(this_octet)) {
        SAFE_SET_POINTER_VAL(ret_len, 0);
        return 0;
    }

    UNLESS (UTF8_IS_START_BYTE(this_octet)) {
        SAFE_SET_POINTER_VAL(ret_len, 0);
        return 0;
    }

    /* compute the number of expected bytes and pull out the bits
       contributing to the code point
    */
    if ((this_octet & 0xf8) == 0xf0) {
        expected_len = 4;
        this_octet &= 0x07;
    }
    else if ((this_octet & 0xf0) == 0xe0) {
        expected_len = 3;
        this_octet &= 0x0f;
    }
    else if ((this_octet & 0xe0) == 0xc0) {
        expected_len = 2;
        this_octet &= 0x1f;
    }
    else {
        SAFE_SET_POINTER_VAL(ret_len, 0);
        return 0;
    }

    if (buf_len < expected_len) {
        SAFE_SET_POINTER_VAL(ret_len, 0);
        return 0;
    }

    /* now need to grab the rest of the bytes */
    /* grab the bits we want (mask with 0x3f) and OR it with the old value left shifted by 6 */
    
    len = expected_len - 1;
    buf++;
    code_point = this_octet;

    while (len--) {
        UNLESS (UTF8_IS_CONTINUATION_BYTE(*buf)) {
            SAFE_SET_POINTER_VAL(ret_len, 0);
            return 0;
        }

        this_octet = *buf;

        this_octet = (this_octet & 0x3f) | (code_point << 6);

        /* FIXME: should check here for illegal vals? */

        buf++;
        code_point = this_octet;
    }

    SAFE_SET_POINTER_VAL(ret_len, expected_len);

    return code_point;
}

uint32_t
common_utf8_unicode_to_bytes(uint32_t cp, uint8_t *out_buf) {
    uint8_t *d = out_buf;

    if (UNICODE_IS_INVARIANT(cp)) {
        *d = cp;
        return 1;
    }

    if (cp < 0x0800) {
        /* 2 bytes */
        *d++ = (cp >> 6)         | 0xc0;
        *d++ = (cp       & 0x3f) | 0x80;
        return 2;
    }
    
    if (cp < 0x010000) {
        /* 3 bytes */
        *d++ = (cp >> 12)         | 0xe0;
        *d++ = ((cp >> 6) & 0x3f) | 0x80;
        *d++ = (cp        & 0x3f) | 0x80;
        return 3;
    }

    if (cp < 0x200000) {
        /* 4 bytes */
        *d++ = (cp >> 18)           | 0xf0;
        *d++ = ((cp >> 12)  & 0x3f) | 0x80;
        *d++ = ((cp >> 6)   & 0x3f) | 0x80;
        *d++ = (cp          & 0x3f) | 0x80;
        return 4;
    }

    /* invalid */
    *d = 0;
    return 0;
}


UV
get_bad_char_policy(HV * self_hash) {
    SV ** ptr = NULL;
    U8 * data_str = NULL;
    STRLEN data_str_len = 0;

    ptr = hv_fetch((HV *)self_hash, "bad_char_policy", 15, 0);
    if (ptr && SvTRUE(*ptr)) {
        data_str = (U8 *)SvPV(*ptr, data_str_len);
        if (data_str && data_str_len) {
            if (strnEQ("error", (char *)data_str, data_str_len)) {
                return kBadCharError;
            }
            else if (strnEQ("convert", (char *)data_str, data_str_len)) {
                return kBadCharConvert;
            }
            else if (strnEQ("pass_through", (char *)data_str, data_str_len)) {
                return kBadCharPassThrough;
            }
        }
    }

    return kBadCharError;
}

static int g_have_big_int = kHaveModuleNotChecked;
static int g_have_big_float = kHaveModuleNotChecked;

int
have_bigint() {
    SV *rv;
    
    if (g_have_big_int != kHaveModuleNotChecked) {
        if (g_have_big_int == kHaveModule) {
            return 1;
        }
        else {
            return 0;
        }
    }

    rv = eval_pv("require Math::BigInt", 0);
    if (rv && SvTRUE(rv)) {
        /* module loaded successfully */
        g_have_big_int = kHaveModule;
        return 1;
    }
    else {
        /* we don't have it */
        g_have_big_int = kHaveModuleDontHave;
        return 0;
    }

    return 0;
    
}

int
have_bigfloat() {
    SV *rv;
    
    if (g_have_big_float != kHaveModuleNotChecked) {
        if (g_have_big_float == kHaveModule) {
            return 1;
        }
        else {
            return 0;
        }
    }

    rv = eval_pv("require Math::BigFloat", 0);
    if (rv && SvTRUE(rv)) {
        /* module loaded successfully */
        g_have_big_float = kHaveModule;
        return 1;
    }
    else {
        /* we don't have it */
        g_have_big_float = kHaveModuleDontHave;
        return 0;
    }

    return 0;
    
}

