/* Creation date: 2008-04-06T19:58:22Z
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

#ifndef OLD_COMMON_H
#define OLD_COMMON_H

#include "DWIW.h"
#include "libjsonevt/int_defs.h"
#include "libjsonevt/utf8.h"

#define kCommasAreWhitespace 1

/* a single set of flags for json_context and self_context */
#define kUseExceptions 1
#define kDumpVars (1 << 1)
#define kPrettyPrint (1 << 2)
#define kEscapeMultiByte (1 << 3)
#define kConvertBool (1 << 4)
#define kBareSolidus (1 << 5)
#define kMinimalEscaping (1 << 6)
#define kSortKeys (1 << 7)

#define kBadCharError 0
#define kBadCharConvert 1
#define kBadCharPassThrough 2

/* for converting to JSON */
typedef struct {
    SV * error;
    SV * error_data;
    int bare_keys;
    UV bad_char_policy;
    int use_exceptions;
    int flags;

    unsigned int string_count;
    unsigned int longest_string_bytes;
    unsigned int longest_string_chars;
    unsigned int number_count;
    unsigned int bool_count;
    unsigned int null_count;
    unsigned int hash_count;
    unsigned int array_count;
    unsigned int deepest_level;

    HV * ref_track;
} self_context;

#define kHaveModuleNotChecked 0
#define kHaveModule 1
#define kHaveModuleDontHave 2

UV get_bad_char_policy(HV * self_hash);
int have_bigint();
int have_bigfloat();

uint32_t common_utf8_bytes_to_unicode(const uint8_t *orig_buf, uint32_t buf_len, uint32_t *ret_len);
uint32_t common_utf8_unicode_to_bytes(uint32_t code_point, uint8_t *out_buf);

/*
#define convert_uv_to_utf8(buf, uv) common_utf8_unicode_to_bytes((uint32_t)(uv), (uint8_t *)(buf));
*/

#ifdef IS_PERL_5_6
#define convert_utf8_to_uv(utf8, len_ptr) utf8_to_uv_simple(utf8, len_ptr)
#else
#define convert_utf8_to_uv(utf8, len_ptr)  utf8_to_uvuni(utf8, len_ptr)
#endif

#ifdef IS_PERL_5_6
#define convert_uv_to_utf8(buf, uv) uv_to_utf8(buf, uv)
#else
#define convert_uv_to_utf8(buf, uv) uvuni_to_utf8(buf, uv)
#endif

#define UPDATE_CUR_LEVEL(ctx, cur_level) (cur_level > ctx->deepest_level ? (ctx->deepest_level = cur_level) : cur_level )

#define PSTRL(val) ( (UV)val )
#define STRLuf UVuf

#endif /* OLD_COMMON_H */
