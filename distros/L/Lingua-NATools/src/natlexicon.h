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

#ifndef __NATLEXICON_H__
#define __NATLEXICON_H__

#include <EXTERN.h>
#include <perl.h>

#include "dictionary.h"

/**
 * @file
 * @brief NATLexicon object API header file
 */

/**
 * @brief NATCell object structure
 */
typedef struct _NATCell {
    /** the offset of the word in the words string*/
    nat_uint32_t offset;
    /** occurrence count of the word in the corpus */
    nat_uint32_t count;
    /** word identifier (equal to the cell index in the main array) */
    nat_uint32_t id;
} NATCell;

/**
 * @brief NATLexicon object structure
 */
typedef struct _NATLexicon {
    /** offset of the end of the string in the words string array */
    nat_uint32_t words_limit;
    /** word string array, a collection of words separated by the NULL character */
    wchar_t *words;

    /** array of word cells */
    NATCell *cells;
    /** index for the next free cell on the array (number of elements in the array)*/
    nat_uint32_t count;
} NATLexicon;

nat_uint32_t natlexicon_id_from_word(NATLexicon *lexicon, const wchar_t *word);
wchar_t*     natlexicon_word_from_id(NATLexicon *lexicon, nat_uint32_t id);
nat_uint32_t natlexicon_count_from_id(NATLexicon *lexicon, nat_uint32_t id);

NATLexicon*  natlexicon_conciliate(NATLexicon *lex1, nat_uint32_t **it1,
                                   NATLexicon *lex2, nat_uint32_t **it2);
NATCell*     natlexicon_search_word(NATLexicon *lex, const wchar_t *word);
void         natlexicon_free(NATLexicon *self);

#endif
