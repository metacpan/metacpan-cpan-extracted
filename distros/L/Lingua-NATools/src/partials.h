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

#ifndef __PARTIALS_H__
#define __PARTIALS_H__

#include <EXTERN.h>
#include <perl.h>

/**
 * @file
 * @brief Auxiliary data structures to collect partial word counts.
 */


#define DEFAULT_PARTIAL_BUFFER_SIZE 150000

/**
 * @brief Partial count files data structure.
 *
 * For each partial file, this structure has its data, and related
 * information.
 */
typedef struct _partial_counts {
    /** buffer with partial counts (index corresponds to word id) */
    nat_uint32_t *buffer;
    /** current size of the partial counts buffer */
    nat_uint32_t  size;
    /** current state of how full is the counts buffer */
    nat_uint32_t  last;
} PartialCounts;

PartialCounts *PartialCountsAdd(PartialCounts *partials, nat_uint32_t wid);
void           PartialCountsSave(PartialCounts *partials, const char* filename);
PartialCounts *PartialCountsLoad(const char* filename);
void           PartialCountsFree(PartialCounts *partials);

#endif /* __PARTIALS_H__ */
