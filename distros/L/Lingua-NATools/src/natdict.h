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

#ifndef __NATDICT_H__
#define __NATDICT_H__

#include "NATools.h"
#include "dictionary.h"
#include "natlexicon.h"

/**
 * @file
 * @brief NATDict object API header file
 */

/**
 * @brief NATDict object structure
 */
typedef struct _NATDict {
    /** Dictionary source language */
    char      *source_language;
    /** Dictionary target language */
    char      *target_language;

    /** Dictionary source lexicon object */
    NATLexicon *source_lexicon;
    /** Dictionary target lexicon object */
    NATLexicon *target_lexicon;

    /** Dictionary from the source to the target language */
    Dictionary *source_dictionary;
    /** Dictionary from the target to the source language */
    Dictionary *target_dictionary;
} NATDict;


nat_int_t    natdict_save(NATDict *self, const char *filename);
NATDict*     natdict_open(const char *filename);
NATDict*     natdict_new(const char *source_language, const char *target_language);
void         natdict_perldump(NATDict *self);
NATDict*     natdict_add(NATDict *dic1, NATDict *dic2);
nat_uint32_t natdict_id_from_word(NATDict *self, nat_boolean_t language, const wchar_t *word);
wchar_t*     natdict_word_from_id(NATDict *self, nat_boolean_t language, nat_uint32_t id);
NATLexicon*  natdict_load_lexicon(FILE *fh);
nat_uint32_t natdict_word_count(NATDict *self, nat_boolean_t language, nat_uint32_t id);
float        natdict_dictionary_get_val(NATDict *self, nat_boolean_t language, nat_uint32_t wid, nat_uint32_t pos);
nat_uint32_t natdict_dictionary_get_id(NATDict *self, nat_boolean_t language, nat_uint32_t wid, nat_uint32_t pos);

#endif /* __NATDICT_H__ */
