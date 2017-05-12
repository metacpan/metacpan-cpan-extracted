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

#ifndef __CORPUS_H__
#define __CORPUS_H__

#include <glib.h>

#include "standard.h"

/**
 * @file
 * @brief Auxiliary data structure functions to encode a corpus header file
 */

/** The size of the header of the corpus file. */
#define CORPUS_HEADER_SIZE  sizeof(nat_uint32_t)

/**
 * @brief Corpus word structure
 */
typedef struct cCorpusCell {
    /** word identifier */
    nat_uint32_t word;
    /** word flags. 1 means it is in UPPERCASE, 10 means it is Capitalized */
    nat_uchar_t flags;
} __attribute__((packed)) CorpusCell;


/**
 * @brief Corpus structure
 */
typedef struct cCorpus {
    /** pointer to an array of words */
    CorpusCell *words;
    /** size of the corpus */
    nat_uint32_t  length;
    /** pointer to the position being read */
    nat_uint32_t  readptr;
    /** pointer to the write position */
    nat_uint32_t  addptr;

    /** pointer to the direct access index of offsets*/
    nat_uint32_t *index;
    /** size of the direct access index */
    nat_uint32_t  index_size;
    /** pointer to the write position in the direct access index  */
    nat_uint32_t  index_addptr;
} Corpus;

Corpus*       corpus_new(void);
void          corpus_free(Corpus *corpus);
int           corpus_add_word(Corpus *corpus, nat_uint32_t word, nat_int_t flags);
CorpusCell*   corpus_first_sentence(Corpus *corpus);
CorpusCell*   corpus_next_sentence(Corpus *corpus);
nat_uint32_t  corpus_sentence_length(const CorpusCell *s);
int           corpus_load(Corpus *corpus, const char *filename);
int           corpus_save(Corpus *corpus, const char *filename);
nat_uint32_t  corpus_diff_words_nr(Corpus *corpus);
nat_uint32_t  corpus_sentences_nr(Corpus *corpus);
nat_uint32_t  corpus_sentences_nr_from_index(char *filename);
nat_boolean_t corpus_strstr(const CorpusCell *haystack, const nat_uint32_t *needle);

#endif /* __CORPUS_H__ */
