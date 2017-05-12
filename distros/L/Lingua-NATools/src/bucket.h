/* -*- Mode: C; c-file-style: "stroustrup" -*- */

/* NATools - Package with parallel corpora tools
 * Copyright (C) 1998-2001  Djoerd Hiemstra
 * Copyright (C) 2002-2012  Alberto Simões
 *
 * This package is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */


#ifndef __BUCKET_H__
#define __BUCKET_H__

#include "standard.h"

/**
 * @file
 * @brief Data structure for buffered output of integers
 */

/**
 * @brief Bucket of integers
 *
 * Bucket is a buffer of integers. Each time it is full, the contents
 * are saved in the filehandle, and the bucked emptied.
 */
typedef struct cBucket {
    /** filehandler of the buffered output file  */
    FILE *fh;
    /** size of the bucket */
    nat_uint32_t size;
    /** bucket or buffer for the integers */
    nat_uint32_t *buffer;
    /** pointer the the first free position on the buffer */
    nat_uint32_t ptr;
} Bucket;

Bucket *bucket_new (nat_uint32_t size, FILE* file);
Bucket *bucket_add (Bucket *self, nat_uint32_t val);
void    bucket_free(Bucket *self);

#endif
