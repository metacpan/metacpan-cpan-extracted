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

#include <glib.h>
#include <stdio.h>
#include <stdlib.h>
#include "invindex.h"

/**
 * @file
 * @brief Methods for invertion indexes creation and manipulation
 */



static size_t inv_index_buffer_size(nat_uint32_t *buffer)
{
    size_t s = 0;
    if (!buffer) return 0;
    while(*buffer) { buffer++; s++; }
    return s;
}


static int compare(const void* a, const void* b)
{
    nat_uint32_t ai,bi;
    ai = *(nat_uint32_t*)a;
    bi = *(nat_uint32_t*)b;
    return ai>bi?1:(ai<bi?-1:0);
}

/**
 * @brief Pack an integer and a character in four bytes
 *
 * This function takes an unsigned integer <i>a &lt;
 * 2<sup>24</sup></i> and an unsigned char and packs them in a
 * 32 bits unsigned integer.
 *
 * @todo Change function name
 *
 * @param integer the unsigned integer to be packed (<i>a &lt; 2<sup>24</sup></i>)
 * @param character the character to be packed
 * @return an unsigned packed integer
 */
nat_uint32_t pack(nat_uint32_t integer, nat_uchar_t character)
{
    if (integer >= TWO_POWER_TWENTYFOUR) return 0;
    return (character << 24) | integer;
}


/**
 * @brief Unpacks an integer and a character from four bytes
 *
 * This function takes an unsigned integer and unpacks from it
 * and integer <i>a &lt; 2<sup>24</sup></i> and an unsigned char.
 *
 * @todo Change function name
 *
 * @param packed the unsigned packed integer to be unpacked
 * @param character a pointer to an unsigned char, where the unsigned
 *                  character extracted will be stored
 * @return an unsigned integer (<i>a &lt; 2<sup>24</sup></i>) extracted
 *         from the packed integer
 */
nat_uint32_t unpack(nat_uint32_t packed, nat_uchar_t *character)
{
    *character = packed >> 24;
    return packed & 0x00FFFFFF;
}

/**
 * @brief Creates a new invertion index structure
 *
 * This function takes the size for the index to be created (the
 * number of words --- this original size can be enlarged later). It
 * returns the newly create invertion index in its edit data
 * structure.
 *
 * @param original_size the oringinal number of words
 * @return a new and empty invertion index.
 */
InvIndex* inv_index_new(nat_uint32_t original_size)
{
    InvIndex *index;

    index = g_new(InvIndex, 1);
	
    index->size = original_size;
    index->lastid = 0;
    index->nrentries = 0;
    index->buffer = g_new0(InvIndexEntry*, original_size);

    return index;
}

static InvIndexEntry* inv_index_add_occurrence_(InvIndex *index,
						InvIndexEntry *entry,
						nat_uint32_t packed) {
    InvIndexEntry *this;

    if (entry && entry->data[entry->ptr-1] == packed) return entry;

    if (entry && entry->ptr < entry->size) {
	/* we have some free space */
	entry->data[entry->ptr++] = packed;
	this = entry;
    } else {
	this = g_new(InvIndexEntry, 1);
	this->next = entry;
	this->size = CELLSIZE;
	this->ptr = 0;
	this->data = g_new(nat_uint32_t, this->size);
	this->data[this->ptr++] = packed;
    }

    index->nrentries++;

    return this;
}

/**
 * @brief Adds an word occurrence to the invertion index
 *
 * This function takes an invertion index, an word identifier, chunk
 * identifier and sentence number on that chunk, and adds this word
 * occurrence in the index.
 *
 * Note that <i>sentence &lt; 2<sup>24</sup></i>.
 *
 * @param index the Invertion Index object
 * @param wid the word identifier
 * @param chunk the chunk identifier
 * @param sentence the sentence number (for that chunk)
 * @return the changed Invertion Index
 */
InvIndex* inv_index_add_occurrence(InvIndex *index,
				   nat_uint32_t wid,
				   nat_uchar_t  chunk,
				   nat_uint32_t sentence) 
{
    if (wid >= index->size) {
	nat_uint32_t newsize = index->size;
	while(wid > newsize) newsize *=  1.3;
	index->buffer = g_realloc(index->buffer, 
				  newsize * sizeof(InvIndexEntry*));
	index->size = newsize;
    }


    if (wid >= index->lastid) index->lastid = wid + 1;

    /* Better to pack here. Less one argument in the function stack */
    index->buffer[wid] = inv_index_add_occurrence_(index,
						   index->buffer[wid], 
						   pack(sentence, chunk));
    return index;
}

static nat_uint32_t inv_index_save_hash_entry(InvIndexEntry *entry, Bucket *bucket) {
    if (entry) {
	nat_uint32_t i;
	for (i = 0; i<entry->ptr; i++) {
	    bucket = bucket_add(bucket, entry->data[i]);
	}
	return entry->ptr + inv_index_save_hash_entry(entry->next, bucket);
    } else {
	return 0;
    }
}


/**
 * @brief Save the invertion index in a compact format
 *
 * @param index the Invertion Index to be saved
 * @param filename the filename to be used to save the buffer
 * @param quiet if not true, the function will output to <i>stderr</i> the 
 *              progress for the process (which is very slow)
 * @return returns 0 in success, 1 in error
 */
int inv_index_save_hash(InvIndex *index, const char *filename, nat_boolean_t quiet)
{
    FILE *fh;
    nat_uint32_t i;
    nat_uint32_t *offsets;
    nat_uint32_t offset;
    Bucket *bucket;

    fh = fopen(filename, "w");
    if (!fh) return 1;

    offsets = g_new(nat_uint32_t, index->lastid);

    if (!quiet) fprintf(stderr, " Saving");

    fwrite(&index->lastid, sizeof(nat_uint32_t), 1, fh);
    fwrite(&index->nrentries, sizeof(nat_uint32_t), 1, fh);

    bucket = bucket_new(10000000, fh); /* 40 MBytes */
    for (i = 0, offset = 0; i < index->lastid; i++) {
	offsets[i] = offset;

	if (index->buffer[i])
	    offset += inv_index_save_hash_entry(index->buffer[i],
						bucket);
	bucket = bucket_add(bucket, 0);
	offset ++;

	if (!quiet && i % 2000 == 0) 
	    fprintf(stderr,".");
    }
    bucket_free(bucket);

    fwrite(offsets, sizeof(nat_uint32_t), index->lastid, fh);
    if (!quiet) fprintf(stderr,"\n");

    fclose(fh);
    return 0;
}

/**
 * @brief Loads a compact Invertion Index file
 *
 * This is the only way to load an Invertion Index.
 *
 * @param filename the name of the file to be loaded
 * @return the newly loaded Compact Invertion Index
 */
CompactInvIndex *inv_index_compact_load(const char* filename)
{
    nat_uint32_t nrwords, nrentries;
    CompactInvIndex *cii;
    FILE *fh;
    fh = fopen(filename, "r");
    if (!fh) return NULL;

    if (!fread(&nrwords,   sizeof(nat_uint32_t), 1, fh)) return NULL;
    if (!fread(&nrentries, sizeof(nat_uint32_t), 1, fh)) return NULL;

    cii = inv_index_compact_new(nrwords, nrentries);

    if (!fread(cii->entry,  sizeof(nat_uint32_t), nrentries + nrwords, fh)) return NULL;
    if (!fread(cii->buffer, sizeof(nat_uint32_t), nrwords, fh)) return NULL;

    return cii;
}

/**
 * @brief Allocates a new Compact Invertion Index object
 *
 * Note that the number of words and number of entires defined at
 * creation time cannot be changed.
 *
 * @param nrwords number of words to be stored.
 * @param nrentries number of total occurrences
 * @return the newly created empty Compact Invertion Index object
 */
CompactInvIndex *inv_index_compact_new(nat_uint32_t nrwords,
				       nat_uint32_t nrentries)
{
    CompactInvIndex *cii;
    cii = g_new(CompactInvIndex, 1);
    cii->nrwords = nrwords;
    cii->nrentries = nrentries;
    cii->buffer = g_new(nat_uint32_t, nrwords);
    cii->entry  = g_new(nat_uint32_t, nrwords + nrentries);
    return cii;
}

/**
 * @brief Frees the memory used by a Compact Invertion Index object
 *
 * @param cii the Compact Invertion Index object to be freed.
 */
void inv_index_compact_free(CompactInvIndex *cii) 
{
    g_free(cii->entry);
    g_free(cii->buffer);
    g_free(cii);
}


static void inv_index_free_entry(InvIndexEntry *entry) {
    if (entry) {
	inv_index_free_entry(entry->next);
	g_free(entry->data);
	g_free(entry);
    }
}

/**
 * @brief Frees the memory used by a Invertion Index object
 *
 * @param index the Invertion Index object to be freed.
 */
void inv_index_free(InvIndex *index)
{
    nat_uint32_t i;
    for (i = 0; i < index->size; i++)
	inv_index_free_entry(index->buffer[i]);

    g_free(index->buffer);
    g_free(index);
}

/**
 * @brief Adds a chunk Compact Invertion Index in a main Invertion Index
 *
 * Used to join chunks invertion indexes in a single invertion index.
 *
 * @param index the Invertion Index where the information will be added;
 * @param chunk the chunk identification number;
 * @param cii the Compact Invertion Index to be added;
 * @return the Invertion Index after the addition of the Compact Inv. Index
 */
InvIndex* inv_index_add_chunk(InvIndex *index,
			      nat_uchar_t chunk,
			      CompactInvIndex *cii)
{
    nat_uint32_t wid;

    for (wid = 0; wid < cii->nrwords; ++wid) {
	nat_uint32_t ptr = cii->buffer[wid];
	while(cii->entry[ptr]) {
	    index = inv_index_add_occurrence(index, wid, chunk, cii->entry[ptr]);
	    ptr++;
	}
    }
    return index;
}

/**
 * @brief gets the occurrences for a specific word identifier from a
 *     Compact Invertion Index
 *
 * @param index the Compact Invertion Index to be searched
 * @param wid the word identifier for the occurrences to be retrieved
 * @return a reference to a zero terminated buffer of packed occurrences.
 */
nat_uint32_t* inv_index_compact_get_occurrences(CompactInvIndex *index,
					   nat_uint32_t wid)
{
    if (wid >= index->nrwords) return NULL;

    return &(index->entry[index->buffer[wid]]);
}


/**
 * @brief intersects two arrays of occurrences
 *
 * @todo Change the function name
 *
 * @param self a reference to a zero terminated buffer of packed occurrences
 *             to be intersected with <i>other</i>. 
 * @param other a reference to a zero terminated buffer of packed occurrences
 *             to be intersected with <i>self</i>.
 * @return the intersectiong in a new zero-terminated buffer of packed occurrences
 */
nat_uint32_t* intersect(nat_uint32_t *self, nat_uint32_t *other)
{
    nat_uint32_t self_read, new_write, other_read;
    nat_uint32_t *new;
    size_t size_self;
    size_t size_other;

    new = NULL;

    size_self  = self  ? inv_index_buffer_size(self)  : 0;
    size_other = other ? inv_index_buffer_size(other) : 0;

    if (!size_self) {

	new = g_new(nat_uint32_t, size_other + 1);
	other_read = 0;
	while(other[other_read]) {
	    new[other_read] = other[other_read];
	    other_read++;
	}
	new[other_read] = other[other_read];

    } else if (!size_other) {

	new = g_new(nat_uint32_t, size_self + 1);
	self_read = 0;
	while(self[self_read]) {
	    new[self_read] = self[self_read];
	    self_read++;
	}
	new[self_read] = self[self_read];

    } else {

	new = g_new(nat_uint32_t, min(size_self, size_other) + 1);
		
	qsort(self,  size_self,  sizeof(nat_uint32_t), &compare);
	qsort(other, size_other, sizeof(nat_uint32_t), &compare);

	self_read = 0;
	new_write = 0;
	other_read = 0;
    
	while(self[self_read] && other[other_read]) {
	    if (self[self_read] == other[other_read]) {
		new[new_write] = self[self_read];
		new_write++;
		self_read++;
		other_read++;
	    } else if (self[self_read] > other[other_read]) {
		other_read++;
	    } else {
		self_read++;
	    }
	}
	new[new_write] = 0;
    }
    return new;
}
