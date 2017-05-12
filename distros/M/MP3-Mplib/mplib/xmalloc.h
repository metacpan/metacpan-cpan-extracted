/*
 * mplib - a library that enables you to edit ID3 tags
 * Copyright (C) 2001,2002  Stefan Podkowinski
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; version 2.1.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef __XMALLOC_H
#define __XMALLOC_H

/* __BEGIN_DECLS should be used at the beginning of your declarations,
   so that C++ compilers don't mangle their names.  Use __END_DECLS at
   the end of C declarations. */
#undef __BEGIN_DECLS
#undef __END_DECLS
#ifdef __cplusplus
# define __BEGIN_DECLS extern "C" {
# define __END_DECLS }
#else
# define __BEGIN_DECLS /* empty */
# define __END_DECLS /* empty */
#endif


#define XMALLOC(type) ((type *) xmalloc(sizeof(type)))
#define XMALLOCD(type,descr) ((type *) xmallocd(sizeof(type),descr))
#define XMALLOC0(type) ((type *) xmalloc0(sizeof(type)))
#define XMALLOCD0(type,descr) ((type *) xmallocd0(sizeof(type),descr))

__BEGIN_DECLS

/* define XMALLOC_CHECK 1 */

void *xmalloc(size_t);
void *xmallocd(size_t, char*);
void *xmalloc0(size_t);
void *xmallocd0(size_t, char*);
void *xrealloc(void *, size_t);
void *xcalloc(size_t, size_t);
void xfree(void*);
#ifdef XMALLOC_CHECK
void xprint_malloc_stat(void);
#endif

__END_DECLS

#endif /* __XMALLOC_H */
