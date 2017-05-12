/* Creation date: 2008-04-04T17:19:54Z
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

/* $Revision: 1568 $ */
#ifndef UTF8_H
#define UTF8_H

#include <uni.h>

#include <int_defs.h>

UNI_DO_CPLUSPLUS_WRAP_BEGIN

uint32_t utf8_bytes_to_unicode(const uint8_t *orig_buf, uint32_t buf_len, uint32_t *ret_len);
uint32_t utf8_unicode_to_bytes(uint32_t code_point, uint8_t *out_buf);

/* if the only set bits are in the lower 7, then the byte sequence in utf-8 is the same as ascii */
#define UTF8_BYTE_IS_INVARIANT(v) (((uint8_t)v) < 0x80)

/* a continuation byte occurs in each byte after the first in a multibyte utf-8 sequence */
#define UTF8_IS_CONTINUATION_BYTE(v) ( ((uint8_t)v) >= 0x80 && ((uint8_t)v) <= 0xbf )

/* to be the starting byte in a multi-byte utf-8 sequences, the high two bits must be set */
#define UTF8_IS_START_BYTE(v) ( ((uint8_t)v) >= 0xc2 && ((uint8_t)v) <= 0xf4 )

UNI_DO_CPLUSPLUS_WRAP_END

#endif /* UTF8_H */

