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

#ifndef __CORPUSINFO_H__
#define __CORPUSINFO_H__

#include <unistd.h>
#include <string.h>
#include <ctype.h>

#include <NATools.h>
#include "parseini.h"
#include "invindex.h"
#include "dictionary.h"
#include "ngramidx.h"


typedef struct _CorpusChunks_ {
    nat_uint32_t *source_offset;
    nat_uint32_t *target_offset;
    nat_uint32_t size;
    FILE *source_crp;
    FILE *target_crp;
} CorpusChunks;

/* struct to encapsulate corpus information */
typedef struct _CorpusInfo_ {
    GHashTable *config;
    char       *filepath;

    nat_boolean_t standalone_dictionary;

    Words           *SourceLex, *TargetLex;
    CompactInvIndex *SourceIdx, *TargetIdx;
    Dictionary   *SourceTarget, *TargetSource;
    SQLite        *SourceGrams, *TargetGrams;
    
    nat_uchar_t nrChunks;

    /* Offsets, all in memory */
    CorpusChunks *chunks;

    /* Offset caches */
    /*     nat_uint32_t* offset_cache1; */
    /*     char* offset_cache_filename1; */
    /*     nat_uint32_t* offset_cache2; */
    /*     char* offset_cache_filename2; */
    /*     int last_offset_cache; */

    /* Rank caches */
    double *rank_cache1, *rank_cache2;
    char *rank_cache_filename1, *rank_cache_filename2;
    int last_rank_cache, has_rank;


} CorpusInfo;

CorpusInfo *corpus_info_new(char *filepath);

void          LOG(char* log, ...);
void          corpus_info_free(CorpusInfo *corpus);
nat_boolean_t corpus_info_has_ngrams(CorpusInfo *crp);

#endif
