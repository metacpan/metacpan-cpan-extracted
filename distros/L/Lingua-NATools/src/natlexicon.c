/* -*- Mode: C; c-file-style: "stroustrup" -*- */

/* NATools - Package with parallel corpora tools
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
#include <EXTERN.h>
#include <perl.h>
#include <zlib.h>
#include <string.h>
#include <stdlib.h>
#include <wchar.h>
#include "natlexicon.h"
#include "unicode.h"

/**
 * @file
 * @brief NATLexicon object API
 *
 * This modules defines the functions needed to access the NATLexicon
 * structure.
 */


/**
 * Turn on this variable to get more debugging messages being printed
 * to stderr;
 */
#define DEBUG 0



/**
 * Translates a word to its identifier;
 *
 * @param lexicon a reference to a NATLexicon object;
 * @param word a reference to a string containing a word;
 * @return the word identifier;
 */
nat_uint32_t natlexicon_id_from_word(NATLexicon *lexicon, const wchar_t *word)
{
    NATCell *cell;
    cell = natlexicon_search_word(lexicon, word);
    if (cell) {
	return cell->id;
    } else {
	return 0;
    }
}

/**
 * Translates a word identifier to the corresponding word;
 *
 * @param lexicon a reference to a NATLexicon object;
 * @param id a word identifier;
 * @return a reference to the word identified by id.
 */
wchar_t *natlexicon_word_from_id(NATLexicon *lexicon, nat_uint32_t id)
{
    nat_uint32_t offset;
    if (id == lexicon->count-1) {
	return wcs_dup(L"(null)");
    }
    offset = lexicon->cells[id].offset;
    if (lexicon->cells[id].id != id) {
	fprintf(stderr,"** WARNING: ids differ\n");
	fprintf(stderr, "** ID: %u,%u COUNT: %d\n", id,lexicon->cells[id].id, lexicon->count);
    }
    return (wchar_t*)(lexicon->words + offset);
}

/**
 * Returns the number of occurrences of the word identified by id in
 * the NATLexicon object.
 *
 * @param lexicon a reference to a NATLexicon object;
 * @param id a word identifier;
 * @return the number of occurrences of the word;
 */
nat_uint32_t natlexicon_count_from_id(NATLexicon *lexicon, nat_uint32_t id)
{
    if (id == lexicon->count-1) return 0;
    return lexicon->cells[id].count;
}

static void natlexicon_merge(NATLexicon *self,
			     NATLexicon *lex1, nat_uint32_t idx1, nat_uint32_t *itable1,
			     NATLexicon *lex2, nat_uint32_t idx2, nat_uint32_t *itable2)
{   
    int cmp;
    wchar_t *tmp;

    if ((idx1 == lex1->count-1) && (idx2 == lex2->count-1)) {
	/* TRATAR DO NULL */
	self->cells[self->count].id = self->count;
	self->cells[self->count].count = 0;
	self->cells[self->count].offset = self->words_limit-1;
	itable1[idx1]=self->count;
	itable2[idx2]=self->count++;
	return;
    }
    else if (idx1 == lex1->count-1) cmp = 1;
    else if (idx2 == lex2->count-1) cmp = -1;
    else cmp = wcscmp((wchar_t*)(lex1->words+lex1->cells[idx1].offset),
		      (wchar_t*)(lex2->words+lex2->cells[idx2].offset));
    
    if (cmp == 0) {
	self->cells[self->count].id = self->count;
	self->cells[self->count].count = lex1->cells[idx1].count + lex2->cells[idx2].count;
	self->cells[self->count].offset = self->words_limit;
	tmp = lex1->words+lex1->cells[idx1].offset;
	while(*tmp) {
	    *(self->words+self->words_limit) = *tmp;
	    self->words_limit++;
	    tmp++;
	}
	*(self->words+self->words_limit) = '\0';
	self->words_limit++;
	itable1[idx1++]=self->count;
	itable2[idx2++]=self->count++;

    } else if (cmp > 0) {

	/* tratar do idx2 only */
	self->cells[self->count].id = self->count;
	self->cells[self->count].count = lex2->cells[idx2].count;
	self->cells[self->count].offset = self->words_limit;
	tmp = lex2->words+lex2->cells[idx2].offset;
	while(*tmp) {
	    *(self->words+self->words_limit) = *tmp;
	    self->words_limit++;
	    tmp++;
	}
	*(self->words+self->words_limit) = '\0';
	self->words_limit++;
	itable2[idx2++]=self->count++;

    } else {

	/* tratar do idx1 only */
	self->cells[self->count].id = self->count;
	self->cells[self->count].count = lex1->cells[idx1].count;
	self->cells[self->count].offset = self->words_limit;
	tmp = lex1->words+lex1->cells[idx1].offset;
	while(*tmp) {
	    *(self->words+self->words_limit) = *tmp;
	    self->words_limit++;
	    tmp++;
	}
	*(self->words+self->words_limit) = '\0';
	self->words_limit++;
	itable1[idx1++]=self->count++;

    }

    natlexicon_merge(self, lex1, idx1, itable1, lex2, idx2, itable2);
}

/**
 * Conciliates two NATLexicon objects, given two indirection tables
 *
 * @param lex1 first NATLexicon object to conciliate
 * @param it1  first indirection table
 * @param lex2 second NATLexicon object to conciliate
 * @param it2  second indirection table
 * @return a new NATLexicon object with the lexicon conciliated
 */
NATLexicon *natlexicon_conciliate(NATLexicon *lex1, nat_uint32_t** it1,
				  NATLexicon *lex2, nat_uint32_t** it2)
{
    NATLexicon *self;
    
    wchar_t      *merged_str = NULL;
    nat_uint32_t  merged_str_offset = 0;
    nat_uint32_t  merged_str_size = 0;

    NATCell      *merged_cells = NULL;
    nat_uint32_t  merged_cells_size = 0;
    nat_uint32_t  merged_cells_offset = 0;

    nat_uint32_t *itable1, *itable2;
    
    itable1 = g_new0(nat_uint32_t, lex1->words_limit);
    *it1 = itable1;
    itable2 = g_new0(nat_uint32_t, lex2->words_limit);
    *it2 = itable2;

    merged_cells_size = lex1->count + lex2->count;
    merged_cells = g_new0(NATCell, merged_cells_size);

    merged_str_size = lex1->words_limit + lex2->words_limit;
    merged_str = g_new0(wchar_t, merged_str_size);

    self = g_new(NATLexicon, 1);
    self->words_limit = merged_str_offset;
    self->words = merged_str;
    self->cells = merged_cells;
    self->count = merged_cells_offset;

    natlexicon_merge(self, lex1, 0, itable1, lex2, 0, itable2);

    /* aqui convinha apagar as celulas e espaço por usar. */
    /* TODO */

    return self;
}


static NATCell *natlexicon_bsearch_word(NATLexicon *lex, nat_uint32_t low,
                                        nat_uint32_t high, const wchar_t *word)
{
    nat_uint32_t middle;
    int cmp;

    if (high < low) return NULL;

    middle = (high+low)/2;
    cmp = wcscmp(word, lex->words + lex->cells[middle].offset);

    if (cmp == 0)
	return &lex->cells[middle];
    else if (cmp > 0)
	return natlexicon_bsearch_word(lex, middle+1, high, word);
    else
	return natlexicon_bsearch_word(lex, low, middle-1, word);
}

/**
 * Searches the NATLexicon object for a word. Returns the respective
 * NATCell cell or NULL if not found.
 *
 * @param lexicon The NATLexicon object to use
 * @param word Word to be searched
 * @return The NATCell object of that word, or NULL if not found
 */
NATCell *natlexicon_search_word(NATLexicon *lexicon, const wchar_t *word)
{
    return natlexicon_bsearch_word(lexicon, 0, lexicon->count - 1, word);
}

/**
 * Frees the memory of the NATLexicon object.
 *
 * @param self a reference to the NATLexicon object to be freed.
 */
void natlexicon_free(NATLexicon *self)
{
    g_free(self->words);
    g_free(self->cells);
    g_free(self);
}
