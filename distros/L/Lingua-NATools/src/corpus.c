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
#include <stdlib.h>

#include <NATools/corpus.h>


/**
 * @file
 * @brief Auxiliary data structure functions to encode a corpus
 */

/** @brief size of the chunk increment at each corpus realloc */
#define MEMBLOCK 1024

/**
 * @brief gets the number of sentences in the corpus 
 *
 * @param filename name of the copus file
 * @return the number of sentences of that corpus
 */
nat_uint32_t  corpus_sentences_nr_from_index(char *filename)
{
    char *file = g_strdup_printf("%s.index", filename);    
    nat_uint32_t x;
    FILE *fd = fopen(file, "r");
    g_free(file);
    if (!fd) return 0;

    fread(&x, sizeof(nat_uint32_t), 1, fd);
    fclose(fd);
    return x;
}


/**
 * @brief creates a new corpus object
 *
 * @return the newly allocated corpus object, or NULL in error
 */
Corpus *corpus_new(void)
{
    Corpus* corpus;
    corpus = g_new(Corpus, 1);
    if (!corpus) return NULL;

    corpus->length = MEMBLOCK;
    corpus->readptr = 0;
    corpus->addptr = 0;

    corpus->words = g_new0(CorpusCell, corpus->length);
    if (!corpus->words) {
        g_free(corpus);
        return NULL;
    }

    corpus->index_size = MEMBLOCK;

    corpus->index = g_new(nat_uint32_t, MEMBLOCK);
    if (!corpus->index) {
	free(corpus->words);
	g_free(corpus);
	return NULL;
    }

    corpus->index_addptr = 0;
    corpus->index[0] = 0;

    return corpus;
}

/**
 * @brief Freed a corpus object
 *
 * @param corpus the corpus object to be freed.
 */
void corpus_free(Corpus *corpus)
{
    g_free(corpus->words);
    g_free(corpus->index);
    g_free(corpus);
}

static int index_enlarge(Corpus *corpus)
{
    corpus->index_size += MEMBLOCK;
    corpus->index = (nat_uint32_t*)realloc(corpus->index,
                                           corpus->index_size * sizeof(nat_uint32_t));
    return (corpus->index == NULL);
}

static int corpus_enlarge(Corpus *corpus)
{
    corpus->length += MEMBLOCK;
    corpus->words = (CorpusCell*)realloc(corpus->words,
                                         corpus->length * sizeof(CorpusCell));
    return (corpus->words == NULL);
}

/**
 * @brief adds a word to the end of the corpus
 * 
 * FIXME: explain flags
 *
 * @param corpus the corpus object
 * @param word the word identifier
 * @param flags a set of flags (see the description);
 */
int corpus_add_word(Corpus *corpus, nat_uint32_t word, nat_int_t flags)
{

    if (corpus->addptr >= corpus->length)
        if (corpus_enlarge(corpus))
            report_error("corpus.c: Error enlarging corpus file.\n");

    if (flags == 2)
	corpus->words[corpus->addptr].flags = 0x2;
    else if (flags == 3)
	corpus->words[corpus->addptr].flags = 0x1;
    else
	corpus->words[corpus->addptr].flags = 0x0;

    corpus->words[corpus->addptr++].word = word;

    if (!word) {
	corpus->index_addptr++;
	if (corpus->index_addptr >= corpus->index_size)
	    if (index_enlarge(corpus))
                report_error("corpus.c: Error enlarging corpus index file.\n");

	corpus->index[corpus->index_addptr] = corpus->addptr;
    }

    return 0;
}


/**
 * @brief gets the first sentence of the corpus
 *
 * @param corpus pointer to a Corpus object
 * @return a pointer to the first word of the first corpus sentence
 */
CorpusCell* corpus_first_sentence(Corpus *corpus)
{
    corpus->readptr = 0;
    return corpus->words;
}

/**
 * @brief gets the next sentence in the corpus
 *
 * @param corpus pointer to a Corpus object
 * @return a pointer to the first word of the next corpus sentence
 */
CorpusCell* corpus_next_sentence(Corpus *corpus)
{
    CorpusCell *w;
    nat_uint32_t p, l;
    p = corpus->readptr;
    l = corpus->addptr;
    w = corpus->words;
    while (p<=l && w[p].word) p++;
    if (p >= l-1) {
        corpus->readptr = 0;
        return NULL;
    }
    else
        return (w + (corpus->readptr = ++p));
}


/**
 * @brief calculates the size of the current sentence
 *
 * @param s pointer to the first cell of a sentence in the corpus
 * @return the size of the current sentence
 */
nat_uint32_t corpus_sentence_length(const CorpusCell *s)
{
    nat_uint32_t l = 0;
    while ((*s).word) { l++; s++; }
    return l;
}

/**
 * @brief loads a corpus from file
 *
 * @param corpus an empty corpus object reference
 * @param filename a reference to the filename string
 * @return not zero in case of error.
 */
int corpus_load(Corpus *corpus, const char *filename)
{
    FILE *fd;
    nat_uint32_t len;
    fd = fopen(filename, "rb");
    if (fd == NULL)
        return 1;
    if (fread( &len,sizeof(nat_uint32_t),1,fd) != 1)
	return 1;

    corpus->words = g_new(CorpusCell, len);
    if (corpus->words == NULL)
        return 3;
    if (fread(corpus->words, sizeof(CorpusCell),len,fd) != len)
        return 4;
    if (fclose(fd))
        return 5;
    corpus->length = len;
    corpus->addptr = len;
    corpus->readptr = 0;

    corpus->index = NULL;
    corpus->index_size = 0;
    corpus->index_addptr = 0;
    return 0;
}

/**
 * @brief saves the corpus object
 *
 * @param corpus a corpus object reference
 * @param filename the filename to be used
 * @return 1 in case of error. 0 otherwise.
 */
int corpus_save(Corpus *corpus, const char *filename)
{
    FILE *fd;
    char *file;
    nat_uint32_t len;
    fd = fopen(filename, "wb");
    if (fd == NULL)
	return 1;
    len = corpus->addptr;
    if (fwrite(&corpus->addptr, sizeof(nat_uint32_t), 1, fd ) != 1)
	return 1;
    if (fwrite(corpus->words, sizeof(CorpusCell), len, fd ) != len)
	return 1;
    if (fclose(fd))
	return 1;

    file = g_strdup_printf("%s.index", filename);

    /* - Add pointer to ficticial sentence at the end - */
    corpus->index_addptr++;
    if (corpus->index_addptr == corpus->index_size)
	if (index_enlarge(corpus))
	    return 1;
    corpus->index[corpus->index_addptr] = corpus->addptr;

    fd = fopen(file, "wb");
    if (fd == NULL) 
	return 1;
    if (!fwrite(&(corpus->index_size), sizeof(nat_uint32_t), 1, fd))
	return 0;
    if (!fwrite(corpus->index, sizeof(nat_uint32_t), corpus->index_size, fd))
	return 0;
    if (fclose(fd))
	return 1;

    g_free(file);

    return 0;
}

/**
 * @brief computes the number of different words in the corpus
 *
 * @param corpus the corpus object reference
 * @return the number of different words in the corpus
 */
nat_uint32_t corpus_diff_words_nr(Corpus *corpus)
{
    CorpusCell *w;
    nat_uint32_t max;
    nat_uint32_t p,l;
    max = 0;
    p = 0;
    l = corpus->addptr;
    w = corpus->words;
    while (p < l) {
        if ((*w).word > max) max = (*w).word;
        p++;
        w++;
    }
    return max;
}

/**
 * @brief computes the number of sentences in the corpus
 *
 * @param corpus the corpus object reference
 * @return the number of sentences of the corpus
 */
nat_uint32_t corpus_sentences_nr(Corpus *corpus)
{
    nat_uint32_t result;
    CorpusCell *s;
    result = 0;

    if (!corpus->addptr) return 0;

    s = corpus_first_sentence(corpus);
    while (s != NULL) {
        result++;
        s = corpus_next_sentence(corpus);
    }
    return result;
}

static nat_uint32_t uint32_sentence_length(const nat_uint32_t *needle) {
    nat_uint32_t ans = 0;
    while(needle[ans]) { ans++; }
    return ans;
}

/**
 * @brief searches for a sequence of words on a sentence/unit
 *
 * @todo explain the work of the placeholder.
 *
 * @param haystack A sentence (CorpusCell array) where to search for
 *                 a sequence of words
 * @param needle The sequence (nat_uint32_t array) to search for. 
 * @return true if the needle is found in the haystack.
 */
nat_boolean_t corpus_strstr(const CorpusCell *haystack, const nat_uint32_t *needle)
{
    nat_boolean_t found = FALSE;
    nat_uint32_t i,j;
    nat_uint32_t needle_size = uint32_sentence_length(needle);
    nat_uint32_t haystack_size = corpus_sentence_length(haystack);

    if (haystack_size > needle_size) {
	for (i = 0; i < haystack_size - needle_size; i++) {
	    for (j = 0; haystack[i+j].word == needle[j] || needle[j] == 1; j++);
	    if (j == needle_size) return TRUE;
	}
    }

    return found;
}
