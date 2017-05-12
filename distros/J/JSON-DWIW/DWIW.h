/* Creation date: 2008-04-06T20:25:24Z
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

/* $Header: /repository/owens_lib/cpan/JSON/DWIW/DWIW.h,v 1.3 2009-04-11 02:18:37 don Exp $ */

#ifndef DWIW_H
#define DWIW_H

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#if PERL_VERSION >= 8
#define IS_PERL_5_8
#else
#if PERL_VERSION <= 5
#error "This module requires at least Perl 5.6"
#else
#define IS_PERL_5_6
#endif
#endif

#define DEBUG_UTF8 0
#define JSON_DO_DEBUG 0
#define JSON_DO_TRACE 0
#define JSON_DUMP_OPTIONS 0
#define JSON_DO_EXTENDED_ERRORS 0

#include <stdarg.h>

#define MAYBE_USE_MMAP 0

#if MAYBE_USE_MMAP
#ifdef HAS_MMAP
#define USE_MMAP 1
#else
#define USE_MMAP 0
#endif
#else
#define USE_MMAP 0
#endif

#if USE_MMAP
#include <unistd.h>
#include <sys/types.h>
#include <sys/mman.h>
#endif

#ifdef HAVE_JSONEVT
#include "evt.h"
#endif

#define debug_level 9

#ifndef PERL_MAGIC_tied
#define PERL_MAGIC_tied            'P' /* Tied array or hash */
#endif

#define MOD_NAME "JSON::DWIW"
#define MOD_VERSION VERSION

/*

#ifdef JSONEVT_HAVE_FULL_VARIADIC_MACROS

#if JSON_DO_DEBUG
#define JSON_DEBUG(...) printf("%s (%d) - ", __FILE__, __LINE__); printf(__VA_ARGS__); printf("\n"); fflush(stdout)
#else
#define JSON_DEBUG(...)
#endif
#if JSON_DO_TRACE
#define JSON_TRACE(...) printf("%s (%d) - ", __FILE__, __LINE__); printf(__VA_ARGS__); printf("\n"); fflush(stdout)
#else
#define JSON_TRACE(...)
#endif

#else
void JSON_DEBUG(char *fmt, ...);
void JSON_TRACE(char *fmt, ...);
#endif
*/
 /* JSONEVT_HAVE_FULL_VARIADIC_MACROS */


#ifndef UTF8_IS_INVARIANT
#define UTF8_IS_INVARIANT(c) (((UV)c) < 0x80)
#endif

#define UNLESS(stuff) if (! (stuff))
#define MEM_EQ(buf1, buf2, len) ( memcmp((void *)buf1, (void *)buf2, len) == 0 )


#endif /* DWIW_H */

