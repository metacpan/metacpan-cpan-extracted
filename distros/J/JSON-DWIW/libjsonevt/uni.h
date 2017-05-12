/* Creation date: 2008-04-05T21:10:18Z
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

/* $Revision$ */

#ifndef UNI_H
#define UNI_H

#include <int_defs.h>

#ifdef __cplusplus
#define UNI_DO_CPLUSPLUS_WRAP_BEGIN extern "C" {
#define UNI_DO_CPLUSPLUS_WRAP_END }
#else
#define UNI_DO_CPLUSPLUS_WRAP_BEGIN
#define UNI_DO_CPLUSPLUS_WRAP_END
#endif

UNI_DO_CPLUSPLUS_WRAP_BEGIN

/* if the only set bits are in the lower 7, then the byte sequence in utf-8 is the same as ascii */
#define UNICODE_IS_INVARIANT(v) (((uint32_t)v) < 0x80)

/* the byte order mark is the code point 0xFEFF */
/* encoded as utf-8: "\xef\xbb\xbf" */
#define UNICODE_IS_BOM(v) ((v) == 0xFEFF);

UNI_DO_CPLUSPLUS_WRAP_END

#endif /* UNI_H */

