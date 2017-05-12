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

#include <stdio.h>
#include "bucket.h"
#include <glib.h>

/**
 * @file
 * @brief Methods to manage the Bucket data structure
 */

/**
 * @brief Creates a new bucket object.
 *
 * This function receives the size of the bucket to be created, and
 * the file handle to be used to dump the bucket contents as soon as
 * it is full or destructed.
 *
 * @param size the size of the bucket to be created
 * @param fh the already opened file handle used to dump the bucket contents
 * @return the newly created and empty bucket
 */
Bucket *bucket_new(nat_uint32_t size, FILE *fh)
{
    Bucket *self;

    self = g_new(Bucket, 1);
    self->size = size;
    self->ptr = 0;
    self->fh = fh;
    self->buffer = g_new(nat_uint32_t, size);
    return self;
}

/**
 * @brief Destroys the bucket object
 *
 * This function receives a bucket. If the bucket is not empty, its
 * contents are first dumped to the file. Then, all the memory used is
 * freed. Note that the file handle is not closed.
 *
 * @param self the bucket object to be destroyed.
 */
void bucket_free(Bucket *self)
{
    if (self->ptr)
	fwrite(self->buffer, sizeof(nat_uint32_t), self->ptr, self->fh);
    g_free(self->buffer);
    g_free(self);
}

/**
 * @brief Adds an integer to the bucket
 *
 * This function receives an unsigned integer to add to the bucket.
 * If the bucket is full it will be saved to the file handle and
 * emptied before being used.
 *
 * @param self the bucket object to use
 * @param val the unsigned integer to be added
 * @return the bucket object with the value added.
 */
Bucket *bucket_add(Bucket *self, nat_uint32_t val)
{
    if (self->ptr == self->size) {
	fwrite(self->buffer, sizeof(nat_uint32_t), self->ptr, self->fh);
	self->ptr = 0;
    }
    self->buffer[self->ptr++] = val;
    return self;
}
