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

#ifndef __WORDS_H__
#define __WORDS_H__

#include "standard.h"

/** @brief maximum size for words in the corpus */
#define MAXWORDLEN 99

/**
 * @file
 * @brief Auxiliary data structure to collect words header file
 */


/**
 * @brief Cell in the tree of collected words
 *
 * WordLstNode is each cell in the tree os collected words (Words)
 */
typedef struct cWordLstNode {
    /** word identifier */
    nat_uint32_t id;

    /** word occurrence counter */
    nat_uint32_t count;

    /** the word */
    wchar_t *string;

    /** binary tree left branch */
    struct cWordLstNode *left;

    /** binary right left branch */
    struct cWordLstNode *right;
} WordLstNode; 

/**
 * @brief binary search tree for words collecting.
 *
 * WordNode is a binary search tree base structure, used for words
 * collecting.
 */
typedef struct cWords {
    /** number of words in the tree and last identifier used */
    nat_uint32_t count;

    /** total number of occurrences (all cells count summed up) */
    nat_uint32_t occurrences;

    /** the binary search tree of words */
    WordLstNode *tree;

    /** direct_access to words using id */
    WordLstNode **idx;
} Words, Words_t;

Words_t*      words_new();
nat_uint32_t  words_add_word(Words *list, wchar_t *string);
Words*        words_add_full(Words *list, nat_uint32_t id, nat_uint32_t count,
                             const wchar_t *string);
Words*        words_load(const char *filename);
Words*        words_quick_load(const char *filename);
void          words_print(wchar_t *title, Words *lst);
void          words_free(Words *lst);
wchar_t*      words_get_by_id(Words *words, nat_uint32_t index);
WordLstNode*  words_get_full_by_id(Words *words, nat_uint32_t index);
nat_uint32_t  words_size(Words *list);
nat_uint32_t  words_occurrences(Words *list);
nat_boolean_t words_save(Words *list, char *filename);
nat_uint32_t  words_get_id(Words *lst, const wchar_t *string);
nat_uint32_t  words_get_count_by_id(Words *ptr, nat_uint32_t wid);
Words*        words_enlarge(Words* list, nat_uint32_t extracells);

#endif /* __WORDS_H__ */
