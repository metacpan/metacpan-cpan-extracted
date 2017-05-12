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
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <wchar.h>

#include <NATools/words.h>

#include <glib.h>

#include "unicode.h"

/**
 * @file
 * @brief Auxiliary data structure functions to collect words
 */

static int strcmpx(const wchar_t *s1,const wchar_t *s2)
{
    int result;
    do
        result = (*s1++) - (*s2++);
    while (!result && *s1 && *s2);
    if (*(s1-1) == L'*' || *(s2-1) == L'*') result = 0;
    if (!result && *s1) return 1;
    if (!result && *s2) return -1;
    else return result;
}

/**
 * @brief Creates a new Words object
 *
 * @return the newly word list or NULL in case of error
 */
Words* words_new()
{
    Words *ws = g_new( Words, 1 );
    ws->count = 1; 		/* FIRST IS THE NULL */
    ws->occurrences = 0;
    ws->tree = NULL;
    ws->idx = NULL;
    return ws;
}


static WordLstNode* words_add_word_(WordLstNode* list, wchar_t *string, nat_uint32_t* rn)
{
    int cmp;
    if (!list) {
        WordLstNode *cell = g_new(WordLstNode, 1);
        if (!cell) { *rn = 0; return list; }

        cell->string = string;
        cell->count = 1;        /* I would put 1... but original uses 2 */
        cell->left = NULL;
        cell->right = NULL;
        cell->id = *rn;
        return cell;
    } else {
        cmp = strcmpx(string, list->string);
        if (cmp < 0) {
            list->left = words_add_word_(list->left, string, rn);
        } else if (cmp > 0) {
            list->right = words_add_word_(list->right, string, rn);
        } else {
            *rn = list->id;
            list->count++;
        }
	return list;
    }
}



static WordLstNode* words_add_word_and_index_(Words *w, WordLstNode* list,
                                              wchar_t *string, nat_uint32_t* rn)
{
    int cmp;
    if (!list) {
        WordLstNode *cell = g_new(WordLstNode, 1);
        if (!cell) { *rn = 0; return list; }

        cell->string = string;
        cell->count = 1;        /* I would put 1... but original uses 2 */
        cell->left = NULL;
        cell->right = NULL;
        cell->id = *rn;
	w->idx[cell->id] = cell;
        return cell;
    } else {
        cmp = strcmpx(string, list->string);
        if (cmp < 0) {
            list->left = words_add_word_(list->left, string, rn);
        } else if (cmp > 0) {
            list->right = words_add_word_(list->right, string, rn);
        } else {
            *rn = list->id;
            list->count++;
        }
	return list;
    }
}

/**
 * @brief Adds a word to the word list object
 *
 * This function takes a word list object and a word. If the word does
 * not exist, a new cell is created and the new identifier
 * returned. If it already exists, the respective identifier is
 * returned.
 *
 * @param list the word list object
 * @param string the word being added
 * @return the identifier for that word
 */
nat_uint32_t words_add_word(Words* list, wchar_t *string)
{
    nat_uint32_t register_number = list->count + 1;
    
    list->tree = words_add_word_(list->tree, string, &register_number);
    if (register_number == list->count+1) list->count++;
    list->occurrences++;

    return register_number;
}

/**
 * @brief FIXME
 */
nat_uint32_t words_add_word_and_index(Words* list, wchar_t *string)
{
    nat_uint32_t register_number = list->count + 1;
    
    list->tree = words_add_word_and_index_(list, list->tree, string, &register_number);
    if (register_number == list->count+1) list->count++;
    list->occurrences++;

    return register_number;
}


/**
 * @brief Returns the total number of words in the corpus
 *
 * @param list the word list object
 * @return the number of tokens in the corpus
 */
nat_uint32_t words_tokens_number(Words* list)
{
    return list->occurrences;
}

/**
 * @brief Returns the number of words in a word list
 *
 * @param list the word list object
 * @return the number of the elements on the word list object
 */
nat_uint32_t words_size(Words* list)
{
    return list->count;
}

/**
 * @brief Returns the number of tokens in the corpus
 *
 * @param list the word list object
 * @return the number of tokens in the corpus
 */
nat_uint32_t words_occurrences(Words* list)
{
    return list->occurrences;
}

/**
 * @brief FIXME
 */
Words* words_enlarge(Words* list, nat_uint32_t extracells)
{
    list->idx = g_realloc(list->idx, (extracells + list->count) * sizeof(WordLstNode*));
    return list;
}

static void word_save_(WordLstNode* tree, FILE *fd)
{
    if (tree) {
        int len;
        fwrite(&tree->id, sizeof(tree->id), 1, fd);
        fwrite(&tree->count, sizeof(tree->count), 1, fd);
        len = wcslen(tree->string)+1;
        fwrite(&len, sizeof(int), 1, fd);
        fwrite(tree->string, sizeof(wchar_t) * len, 1, fd);
        word_save_(tree->left, fd);
        word_save_(tree->right, fd);
    }
}

/**
 * @brief Saves a wordlist on a file
 *
 * @param list the word list object to be saved
 * @param filename a string with the name of the file being created
 * @return true unless the save process failed. In this case, false is returned.
 */
nat_boolean_t words_save(Words* list, char* filename)
{
    FILE *fd;

    fd = fopen(filename, "w");
    if (fd == NULL)
        return FALSE;
    else {
        fwrite(&list->count,       sizeof(nat_uint32_t), 1, fd);
        fwrite(&list->occurrences, sizeof(nat_uint32_t), 1, fd);
        word_save_(list->tree, fd);
    }
    fclose(fd);
    return TRUE;
}


static WordLstNode* words_add_full_(Words *w, WordLstNode* tree, nat_uint32_t id,
                                    nat_uint32_t count, wchar_t* string) {
    int cmp;
    if (!tree) {
        WordLstNode *cell = g_new(WordLstNode, 1);
        if (!cell) return tree;

        if (w->idx) w->idx[id] = cell;

        cell->string = string;
        cell->count = count;
        cell->left = NULL;
        cell->right = NULL;
        cell->id = id;
        
        return cell;

    } else {
        cmp = strcmpx(string, tree->string);

        if (cmp < 0)
            tree->left = words_add_full_(w, tree->left, id, count, string);
        else if (cmp > 0)
            tree->right = words_add_full_(w, tree->right, id, count, string);

        return tree;
    }
}

/** 
 * @brief Adds a word in the tree maintaining a direct access array
 *
 * @param list the word list object
 * @param id the identifier for that word
 * @param count the occurrence count for that word
 * @param string the word
 * @param ptr a pointer to the direct access array
 * @return the word list object
 */
Words* words_add_full(Words* list, nat_uint32_t id,
                      nat_uint32_t count, const wchar_t* string)
{
    wchar_t *str = wcs_dup(string);
    list->tree = words_add_full_(list, list->tree, id, count, str);
    list->count++;              /* we hope this is not called for two equal strings */
    list->occurrences+=count;
    return list;
}



Words* words_real_load_(const char *filename, nat_boolean_t quick)
{
    FILE *fd;
    nat_uint32_t count;
    nat_uint32_t id, wc, tk;
    wchar_t buffer[MAXWORDLEN+1];
    Words *tree;    

    fd = fopen(filename, "r");
    
    if (fd == NULL) return NULL;

    if (!fread(&wc, sizeof(wc), 1, fd)) return NULL;
    if (!fread(&tk, sizeof(tk), 1, fd)) return NULL;

    tree = words_new();

    if (!quick) {
        if (tree->idx) g_free(tree->idx);
        tree->idx = g_new0(WordLstNode*, wc+1);
        if (!tree->idx) return NULL;
    }

    while(!feof(fd)) {
        fread(&id, sizeof(id), 1, fd);
        if (!feof(fd)) {
            int len;
            fread(&count, sizeof(count),         1, fd);
            fread(&len,   sizeof(int),           1, fd);
            fread(buffer, sizeof(wchar_t) * len, 1, fd);
            words_add_full(tree, id, count, buffer);
        }
    }
    fclose(fd);

    if (!quick) {
        WordLstNode *cell = g_new(WordLstNode, 1);
        cell->string = wcs_dup(L"(none)"); 
        tree->idx[1] = cell;       // FIXME: e o 0 ?
    }
    
    return tree;
}


Words* words_quick_load(const char *filename) {
    return words_real_load_(filename, 1);
}


/**
 * @brief Loads a word list object
 *
 * This function simply loads the file and returns the word
 * tree.
 *
 * @param filename filename of the word-list object
 * @return the loaded word-list object
 */
Words* words_load(const char *filename) {
    return words_real_load_(filename, 0);
}


static void print_words_(WordLstNode *Words)
{
    if (Words) {
        print_words_(Words->left);
        printf(" '%ls'\n", Words->string);
        print_words_(Words->right);
    }
}

/**
 * @brief prints the dictionary words to stdout
 *
 * This function is mainly used for debugging. Pass it a title and a
 * word list object and it will print them.
 *
 * @param title the title of the word list (for debug...)
 * @param lst the word list object
 */
void words_print(wchar_t* title, Words *lst)
{
    printf("== %ls ==\n", title);
    print_words_(lst->tree);
}

static void words_free_(WordLstNode *l) {
    if (l) {
        words_free_(l->left);
        words_free_(l->right);
        g_free(l);
    }
}

/**
 * @brief Frees the word list structure
 *
 * @param lst pointer to the tree to be freed.
 */
void words_free(Words *lst)
{
    if (lst->idx) g_free(lst->idx);
    words_free_(lst->tree);
    g_free(lst);
}

/**
 * @brief Returns the word in the tree given the word identifier
 *
 * @param words obj
 * @param index word identifier (and index in the array of cells)
 * @return the word which identifier was supplied
 */
wchar_t* words_get_by_id(Words *words, nat_uint32_t index)
{
    WordLstNode *cell;
    if (!words->idx) report_error("Words get by id called with NULL idx\n");

    cell = words->idx[index];
    if (cell)
        return cell->string;
    else
        return NULL;
}

/**
 * @brief Returns the full word cell in the tree given the word identifier
 *
 * @param ptr auxiliary array of cell indexes
 * @param index word identifier (and index in the array of cells)
 * @return the cell of that word in the tree.
 */
WordLstNode *words_get_full_by_id(Words *w, nat_uint32_t index)
{
    WordLstNode *cell;

    if (!w->idx) return NULL;

    cell = w->idx[index];
    if (cell)
        return cell;
    else
        return NULL;
}

/**
 * @brief Returns the number of occurrences from a word
 *
 * @param ptr auxiliary array of cell indexes
 * @param wid word identifier (and index in the array of cells)
 * @return the occurrence number for that word.
 */
nat_uint32_t words_get_count_by_id(Words *w, nat_uint32_t wid)
{
    WordLstNode *cell;
    /* FIXME: Check if wid is smaller to the size of the array */

    if (!w) return 0;

    cell = w->idx[wid];
    if (cell)
	return cell->count;
    else
	return 0;
}

/**
 * @brief Sets the number of occurrences for a word
 *
 * @param list the word list
 * @param ptr auxiliary array of cell indexes
 * @param wid word identifier (and index in the array of cells)
 * @return 0 on error.
 */
nat_int_t words_set_count_by_id(Words *list, nat_uint32_t wid, nat_uint32_t count)
{
    WordLstNode *cell;
    /* FIXME: Check if wid is smaller to the size of the array */

    if (!list->idx) return 0;

    cell = list->idx[wid];
    if (cell) {
	nat_uint32_t ocount = cell->count;
        cell->count = count;
	list->occurrences = list->occurrences - ocount + count;
    } else 
        return 0;
    return 1;
}

static nat_uint32_t get_id_(WordLstNode *tree, const wchar_t *string) {
    if (tree) {
        int cmp = strcmpx(string, tree->string);
        if (cmp<0) {
            return get_id_(tree->left, string);
        } else if (cmp>0) {
            return get_id_(tree->right, string);
        } else {
            return tree->id;
        }
    } else {
        return 0;
    }
}

/**
 * @brief Returns the id for a specific word
 *
 * @param list Words object to be searched
 * @param string word being searched
 * @return that word id
 */
nat_uint32_t words_get_id(Words* list, const wchar_t *string)
{
    return  get_id_(list->tree, string);
}


