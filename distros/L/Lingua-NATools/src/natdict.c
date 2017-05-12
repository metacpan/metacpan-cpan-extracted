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
#include "natdict.h"


/**
 * @file
 * @brief NATDict object API
 *
 * This modules defines the functions needed to access to NATools
 * probabilistic translation dictionaries files.
 */


/**
 * Turn on this variable to get more debugging messages being printed
 * to stderr;
 */
#define DEBUG 0



static void print_quoted(wchar_t *str)
{
    printf("'");
    while(*str) {
	if (*str == '\'') printf("\\");
	if (*str == '\\') printf("\\");
	printf("%lc", *str);
	str++;
    }
    printf("'");
}

/**
 * @brief Gets a possible translation for a word.
 *
 * @param self a reference to a NATDict object.
 * @param language a bool identifying the language being used: 0 for 
 *   the source language and 1 for the target language.
 * @param wid the id identifier of the word being searched.
 * @param pos the position(offset) on the table we are accessing. Notice
 *   that this function is low-level. For a high-level function use the
 *   NAT::NATDict Perl module.
 * @return the word identifier for the possible translation in that position;
 */
nat_uint32_t natdict_dictionary_get_id(NATDict *self, nat_boolean_t language,
                                       nat_uint32_t wid, nat_uint32_t pos)
{
    /* if (language) then 'target' else 'source' fi */
    return dictionary_get_id(language?
			     self->target_dictionary:
			     self->source_dictionary, wid, pos);
}

/**
 * @brief Get the translation probability for a word
 *
 * @param self a reference to a NATDict object.
 * @param language a bool identifying the language being used: 0 for 
 *   the source language and 1 for the target language.
 * @param wid the id identifier of the word being searched.
 * @param pos the position(offset) on the table we are accessing. Notice
 *   that this function is low-level. For a high-level function use the
 *   NAT::NATDict Perl module.
 * @return the translation probability for the word in the specified position;
 */
float  natdict_dictionary_get_val(NATDict *self, nat_boolean_t language,
                                  nat_uint32_t wid, nat_uint32_t pos)
{
    /* if (language) then 'target' else 'source' fi */
    return dictionary_get_val(language?
			     self->target_dictionary:
			     self->source_dictionary, wid, pos);
}




/**
 * @brief Get the occurrnce count for a word (id).
 *
 * @param self a reference to a NATDict object.
 * @param language a bool identifying the language being used: 0 for 
 *   the source language and 1 for the target language.
 * @param id the id identifier of the word being searched.
 * @return the occurrence count of that word
 */
nat_uint32_t  natdict_word_count(NATDict *self, nat_boolean_t language, nat_uint32_t id)
{
    /* if (language) then 'target' else 'source' fi */
    return natlexicon_count_from_id(language?
				    self->target_lexicon:
				    self->source_lexicon, id);
}


/**
 * @brief Searches a NATDict by word id.
 *
 * @param self a reference to a NATDict object.
 * @param language a bool identifying the language being used: 0 for 
 *   the source language and 1 for the target language.
 * @param id the id identifier of the word being searched.
 * @return a reference to the word (wchar_t*).
 */
wchar_t *natdict_word_from_id(NATDict *self, nat_boolean_t language, nat_uint32_t id)
{
    /* if (language) then 'target' else 'source' fi */
    return natlexicon_word_from_id(language?
				   self->target_lexicon:
				   self->source_lexicon, id);
}


/**
 * @brief Searches a NATDict by word.
 *
 * @param self a reference to a NATDict object.
 * @param language a bool identifying the language being used: 0 for 
 *   the source language and 1 for the target language.
 * @param word a wchar_t* pointer to the word being searched
 * @return the identifier of the word in that lexicon.
 */
nat_uint32_t natdict_id_from_word(NATDict *self, nat_boolean_t language, const wchar_t *word)
{
    /* if (language) then 'target' else 'source' fi */
    return natlexicon_id_from_word(language?
				   self->target_lexicon:
				   self->source_lexicon, word);
}


/**
 * @brief Creates a new NATDict object.
 *
 * @param source_language a reference to a string containing the source
 *   language name.
 * @param target_language a reference to a string containing the target
 *   language name.
 * @return the newly created object.
 */
NATDict *natdict_new(const char *source_language, const char *target_language)
{
    NATDict *self;

    self = g_new(NATDict, 1);

    self->source_lexicon = NULL;
    self->target_lexicon = NULL;

    self->source_dictionary = NULL;
    self->target_dictionary = NULL;

    self->source_language = g_strdup(source_language);
    self->target_language = g_strdup(target_language);

    return self;
}

/**
 * @brief Saves a NATDict object.
 *
 * @param self a reference to a NATDict object.
 * @param filename a reference to a string containing the name where
 *   to to save the dictionary.
 * @return 0 if the process fails, 1 otherwise.
 */
nat_int_t natdict_save(NATDict *self, const char *filename)
{
    FILE    *fh;
    nat_uint32_t  s;

    fh = gzopen(filename, "wb");
    if (!fh) return 0;
    
    /* write NATools stamp */
    gzprintf(fh, "!NATDict");

    /* write source language name */
    s = strlen(self->source_language) + 1;
    gzwrite(fh, &s, sizeof(nat_uint32_t));
    gzwrite(fh, self->source_language, s);

    /* write target language name */
    s = strlen(self->target_language)+1;
    gzwrite(fh, &s, sizeof(nat_uint32_t));
    gzwrite(fh, self->target_language, s);
    
    /* source lexicon */
    gzwrite(fh, &self->source_lexicon->words_limit, sizeof(nat_uint32_t));
    gzwrite(fh, self->source_lexicon->words, self->source_lexicon->words_limit);
    gzwrite(fh, &self->source_lexicon->count, sizeof(nat_uint32_t));
    gzwrite(fh, self->source_lexicon->cells, sizeof(NATCell)*self->source_lexicon->count);

    /* target lexicon */
    gzwrite(fh, &self->target_lexicon->words_limit, sizeof(nat_uint32_t));
    gzwrite(fh, self->target_lexicon->words, self->target_lexicon->words_limit);
    gzwrite(fh, &self->target_lexicon->count, sizeof(nat_uint32_t));
    gzwrite(fh, self->target_lexicon->cells, sizeof(NATCell)*self->target_lexicon->count);

    /* source->target dictionary */
    dictionary_save_fh(fh, self->source_dictionary);

    /* target->source dictionary */
    dictionary_save_fh(fh, self->target_dictionary);

    gzclose(fh);

    return 1;
}

/**
 * @brief Loads a NATDict object from a file.
 *
 * @param filename a reference to a string containing the name where
 *   the dictionary is saved.
 * @return a reference to the loaded NATDict object, or NULL
 *   if the process failed.
 */
NATDict *natdict_open(const char *filename)
{
    FILE *fh;
    char tmp[20], tmp2[20];
    nat_int_t s;
    NATDict *self;

    fh = gzopen(filename, "rb");
    if (!fh) return NULL;

    /* Read stamp */
    gzread(fh, &tmp, 8 * sizeof(char));
    if (strncmp(tmp, "!NATDict", 8))
	return NULL;

    /* Read Language names */
    gzread(fh, &s, sizeof(nat_int_t));
    gzread(fh,  tmp, s);
    gzread(fh, &s, sizeof(nat_int_t));
    gzread(fh,  tmp2, s);

    self = natdict_new(tmp, tmp2);


#if DEBUG
    g_message("%s language", self->source_language);
#endif
    self->source_lexicon = natdict_load_lexicon(fh);


#if DEBUG
    g_message("\twords len: %u", self->source_lexicon->words_limit);
    g_message("\t cells nr: %u", self->source_lexicon->count);

    g_message("%s language", self->target_language);
#endif
    self->target_lexicon = natdict_load_lexicon(fh);


#if DEBUG
    g_message("\twords len: %u", self->target_lexicon->words_limit);
    g_message("\t cells nr: %u", self->target_lexicon->count);
#endif


    self->source_dictionary = dictionary_load(fh);
    self->target_dictionary = dictionary_load(fh);

    gzclose(fh);

    return self;
}

static void natdict_perldump_(NATLexicon *source,
			      NATLexicon *target,
			      Dictionary *dic)
{
    nat_uint32_t dicsize, id, j;
    dicsize = dictionary_get_size(dic);
    for (id=0; id<dicsize; ++id) {
	printf("\t");
	print_quoted(natlexicon_word_from_id(source, id));
	printf(" => {\n");
	printf("\t\tcount => %u,\n", natlexicon_count_from_id(source, id));
	printf("\t\ttrans => {\n");
	for (j=0; j<MAXENTRY; ++j) {
	    if (dictionary_get_val(dic, id, j) == 0.0000000) break;
	    printf("\t\t\t");
	    print_quoted(natlexicon_word_from_id(target, dictionary_get_id(dic, id, j)));
	    printf(" => %.8lf,\n", dictionary_get_val(dic, id, j));
	}
	printf("\t\t},\n");
	printf("\t},\n");
    }
}

/**
 * @brief Dumps a NATDict object in Perl format
 *
 * Prints to the stdout a perl formated data structure with the
 * contents of the NATDict object.
 *
 * @param self a reference to a NATDict object;
 */
void natdict_perldump(NATDict *self)
{
    printf("$%s_%s = {\n", self->source_language, self->target_language);
    natdict_perldump_(self->source_lexicon, self->target_lexicon, self->source_dictionary);
    printf("};\n");
    printf("$%s_%s = {\n", self->target_language, self->source_language);
    natdict_perldump_(self->target_lexicon, self->source_lexicon, self->target_dictionary);
    printf("};\n");
}


/**
 * @brief Loads a NATLexicon object from a FH
 *
 * Reads the NATLexicon object, and returns it. The filehandle is not
 * closed, and can be used to read more information from the file.
 *
 * @param fh a filehandle reference to a file containing a NATLexicon object;
 * @return the newly created NATLexicon object;
 */
NATLexicon *natdict_load_lexicon(FILE *fh)
{
    NATLexicon *self = g_new(NATLexicon, 1);

    gzread(fh, &self->words_limit, sizeof(nat_uint32_t));
    self->words = g_new(wchar_t, self->words_limit);
    gzread(fh, self->words, self->words_limit);

    gzread(fh, &self->count, sizeof(nat_uint32_t));
    self->cells = g_new(NATCell, self->count);
    gzread(fh, self->cells, sizeof(NATCell)*self->count);

#if DEBUG
    g_message("Lexicon size: %u", self->count);
#endif

    return self;
}

/**
 * @brief Sums two NATDict objects
 *
 * Sums the two NATDict objects and return the newly created one.
 *
 * @param dic1 a reference to one NATDict object;
 * @param dic2 a reference to another NATDict object;
 * @return a reference to the new NATDict object.
 */
NATDict *natdict_add(NATDict *dic1, NATDict *dic2)
{
    nat_uint32_t *it_S1, *it_S2, *it_T1, *it_T2;
    nat_uint32_t nsizeSource, nsizeTarget;
    NATLexicon *SLex, *TLex;
    NATDict *self;

    self = g_new(NATDict, 1);
    self->source_language = g_strdup(dic1->source_language);
    self->target_language = g_strdup(dic1->target_language);
    /* before start, should we see if the languages are the same? */

    g_message("Conciliating source dictionaries");

    /* First, conciliate source dictionaries */
    SLex = natlexicon_conciliate(dic1->source_lexicon, &it_S1,
				 dic2->source_lexicon, &it_S2);
    self->source_lexicon = SLex;
    nsizeSource = SLex->count;
    
    g_message("Conciliating target dictionaries");

    /* Second, conciliate target dictionaries */
    TLex = natlexicon_conciliate(dic1->target_lexicon, &it_T1, 
				 dic2->target_lexicon, &it_T2);
    self->target_lexicon = TLex;
    nsizeTarget = TLex->count;

    /* Now, remap dictionaries */
    g_message("Remapping first source dictionary");
    dictionary_realloc_map(it_S1, it_T1, dic1->source_dictionary, nsizeSource);
    g_message("Remapping first target dictionary");
    dictionary_realloc_map(it_T1, it_S1, dic1->target_dictionary, nsizeTarget);

    g_message("Remapping second source dictionary");
    dictionary_realloc_map(it_S2, it_T2, dic2->source_dictionary, nsizeSource);
    g_message("Remapping second target dictionary");
    dictionary_realloc_map(it_T2, it_S2, dic2->target_dictionary, nsizeTarget);

    /* Now, add them */
    self->source_dictionary = dictionary_add(dic1->source_dictionary,
					     dic2->source_dictionary);
    self->target_dictionary = dictionary_add(dic1->target_dictionary,
					     dic2->target_dictionary);

    return self;
}

/**
 * @brief Frees the memory used by a NATDict object;
 *
 * @param self a reference to one NATDict object to be freed;
 */
void natdict_free(NATDict *self)
{
    g_free(self->source_language);
    g_free(self->target_language);

    natlexicon_free(self->source_lexicon);
    natlexicon_free(self->target_lexicon);

    dictionary_free(self->source_dictionary);
    dictionary_free(self->target_dictionary);

    g_free(self);
}
