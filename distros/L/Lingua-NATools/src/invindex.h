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

#ifndef __INVINDEX_H__
#define __INVINDEX_H__

/**
 * @file
 * @brief Data structure for invertion indexes creation
 */

/** @brief 2<sup>24</sup>, the maximum value - 1 able to be stored in three bytes (24 bits) */
#define TWO_POWER_TWENTYFOUR 16777216

/** @brief list of characters used to ignore words in case of their existence */
#define IGNORE_WORDS L",.:;!?\"+-*/\\%^()[]@#=&%_"

/** @brief the size of the cell to be used on the linked list of occurrences */
#define CELLSIZE 50

#include "standard.h"
#include "bucket.h"

/**
 * @brief Structure for each word occurrence
 *
 * This structure stores a set of packed occurrences for a word.
 */
typedef struct cInvIndexEntry {
    /** buffer where the packed occurrences are stored */
    nat_uint32_t* data;
    /** the size of the buffer (we normally use CELLSIZE) */
    nat_uint32_t size;
    /** the offset for the first free position  */
    nat_uint32_t ptr;
    /** linked list pointer for the next buffer cell  */
    struct cInvIndexEntry *next;
} InvIndexEntry;

/**
 * @brief Structure for the invertion index
 *
 * Main data structure for the invertion index creation. It is not
 * used to load invertion indexes from disk. For that use
 * CompactInvIndex.
 */
typedef struct cInvIndex {
    /** array size (number of words) */
    nat_uint32_t size;
    /** array usage */
    nat_uint32_t lastid;
    /** number of entries */
    nat_uint32_t nrentries;
    /** array list */
    struct cInvIndexEntry **buffer;
} InvIndex;

/**
 * @brief Compact structure for the invertion index
 */
typedef struct cCompactInvIndex {
    /** buffer for offsets for each word */
    nat_uint32_t *buffer;
    /** number of words (also, size of buffer) */
    nat_uint32_t nrwords;
    /** buffer for occurrences (size is nrwords + nrentries) */
    nat_uint32_t *entry;
    /** number of occurrences  */
    nat_uint32_t nrentries;
} CompactInvIndex;

InvIndex*        inv_index_new(
                         nat_uint32_t original_size);

InvIndex*        inv_index_add_occurrence(
                         InvIndex *index,
			 nat_uint32_t wid,
			 nat_uchar_t  chunk,
			 nat_uint32_t sentence);

int inv_index_save_hash(InvIndex *index, const char *filename, nat_boolean_t quiet);

void             inv_index_free(
                         InvIndex *index);

CompactInvIndex *inv_index_compact_new(
                         nat_uint32_t nrwords,
			 nat_uint32_t nrentries);

CompactInvIndex *inv_index_compact_load(const char* filename);
InvIndex*       inv_index_add_chunk(InvIndex *index, nat_uchar_t chunk, CompactInvIndex *cii);
void            inv_index_compact_free(CompactInvIndex *cii);
nat_uint32_t*   inv_index_compact_get_occurrences(CompactInvIndex *index, nat_uint32_t wid);
nat_uint32_t    unpack( nat_uint32_t packed, nat_uchar_t *character);
nat_uint32_t    pack(nat_uint32_t integer, nat_uchar_t character);
nat_uint32_t*   intersect(nat_uint32_t *self, nat_uint32_t *other);

/* size_t inv_index_buffer_size(nat_uint32_t *buffer); */

#endif /* __INVINDEX_H__ */
