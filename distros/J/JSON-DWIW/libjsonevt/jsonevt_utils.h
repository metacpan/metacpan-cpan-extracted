/* Creation date: 2007-07-13 20:56:30
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

/* $Revision: 1472 $ */

#ifndef JSONEVT_UTILS_H
#define JSONEVT_UTILS_H

#include "jsonevt_config.h"

#include <sys/types.h>
#include <stdlib.h>

/* #define JSONEVT_PTR2UL(p) ( (unsigned long)(p) ) */
#define JSONEVT_PTR2UL(p) ( (uintptr_t)(p) )

/*
#if JSONEVT_ULONG_SIZE == 4
#define JSONEVT_PTRSPEC "10"
#else
#if JSONEVT_ULONG_SIZE == 8
#define JSONEVT_PTRSPEC "018"
#else
#define JSONEVT_PTRSPEC "034"
#endif
#endif
*/

/* #define JSONEVT_PTR_xf JSONEVT_PTRSPEC"lx" */
/* uintptr_t */
#define JSONEVT_PTR_xf PRIxPTR

#if defined(DO_DEBUG) && defined(__GNUC__)
#define JSONEVT_FREE_MEM(p)                                             \
    fprintf(stderr, "freeing memory \"%s\" in %s, %s (%d) - ", #p,      \
        __func__, __FILE__, __LINE__);                                  \
    fflush(stderr);                                                     \
    fprintf(stderr, "p = %#"JSONEVT_PTR_xf"\n", JSONEVT_PTR2UL(p));     \
    fflush(stderr);                                                     \
    free(p);

#define JSONEVT_NEW(var, nitems, type)                                    \
    fprintf(stderr, "alloc memory \"%s\" in %s, %s (%d) - ", #var,      \
        __func__, __FILE__, __LINE__);                                  \
    fflush(stderr);                                                     \
    var = (type *)malloc((nitems) * sizeof(type));                      \
    fprintf(stderr, "p = %#"JSONEVT_PTR_xf"\n", JSONEVT_PTR2UL(var));   \
    fflush(stderr);

#define JSONEVT_RENEW(var, nitems, type)                                  \
    fprintf(stderr, "realloc memory \"%s\" in %s, %s (%d) - %#"JSONEVT_PTR_xf" -> ", #var, \
        __func__,                                                       \
        __FILE__, __LINE__, JSONEVT_PTR2UL(var));                       \
    fflush(stderr);                                                     \
    if (var) { var = (type *)realloc(var, (nitems) * sizeof(type)); }   \
    else { var = (type *)malloc((nitems) * sizeof(type)); }             \
    fprintf(stderr, "p = %#"JSONEVT_PTR_xf"\n", JSONEVT_PTR2UL(var));   \
    fflush(stderr);

#define JSONEVT_RENEW_RV(var, nitems, type) ((type *)_jsonevt_renew_with_log((void *)(&(var)), (nitems) * sizeof(type), #var, __LINE__, __func__, __FILE__))

#else
#define JSONEVT_FREE_MEM(p) free(p)
#define JSONEVT_NEW(var, nitems, type) var = (type *)malloc((nitems) * sizeof(type));
#define JSONEVT_RENEW(var, nitems, type)                            \
    if (var) { var = (type *)realloc(var, (nitems) * sizeof(type)); }   \
    else { var = (type *)malloc((nitems) * sizeof(type)); }
#define JSONEVT_RENEW_RV(var, nitems, type)                             \
    ((type *)_jsonevt_renew((void *)(&(var)), (nitems) * sizeof(type)))
#endif

#endif

void * _jsonevt_renew_with_log(void **ptr, size_t size, const char *var_name, unsigned int line_num,
    const char *func_name, const char *file_name);
void * _jsonevt_renew(void **ptr, size_t size);
