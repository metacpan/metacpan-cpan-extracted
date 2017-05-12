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


#ifndef UTF32_H
#define UTF32_H

#include <uni.h>

#include <int_defs.h>

UNI_DO_CPLUSPLUS_WRAP_BEGIN

uint32_t utf32_bytes_to_unicode(const uint8_t *orig_buf, uint32_t buf_len, uint32_t *ret_len,
    uint32_t is_little_endian);

uint32_t utf32_unicode_to_bytes(uint32_t code_point, uint8_t *out_buf,
    uint32_t output_little_endian);

UNI_DO_CPLUSPLUS_WRAP_END

#endif /* UTF32_H */

