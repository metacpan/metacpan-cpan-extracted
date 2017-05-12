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

#include <stdlib.h>
#include "corpusinfo.h"

static nat_uint32_t* load_offsets(CorpusInfo *corpus, char *file, nat_uint32_t* size) {
    nat_uint32_t x;
    nat_uint32_t *bf;
    FILE *fd;
    
    fd = fopen(file, "r");
    if (!fd) return NULL;

    fread(&x, sizeof(nat_uint32_t), 1, fd);
    if (size) *size = x;
    bf = g_new(nat_uint32_t, x);
    fread(bf, sizeof(nat_uint32_t), x, fd);
    fclose(fd);

    return bf;
}

CorpusInfo *corpus_info_new(char *filepath) {
    CorpusInfo *self;
    char *temp_file;
    int i;

    self = g_new0(CorpusInfo, 1);

    self->standalone_dictionary = FALSE;
    self->filepath = g_strdup(filepath);

    /* INI FILE */
    temp_file = g_strdup_printf("%s/nat.cnf", filepath);
    self->config = parse_ini(temp_file);
    if (!self->config) report_error("can't open file %s", temp_file);
    g_free(temp_file);

    temp_file = g_hash_table_lookup(self->config, "standalone-dictionary");
    if (temp_file && atoi(temp_file) != 0)
	self->standalone_dictionary = TRUE;

    /* Init the value of chunks */
    temp_file = g_hash_table_lookup(self->config, "nr-chunks");
    self->nrChunks = (nat_uchar_t)(temp_file?atoi(temp_file):1);

    /* SOURCE LEX */
    temp_file = g_strdup_printf("%s/source.lex", filepath);
    self->SourceLex = words_load(temp_file);
    if (!self->SourceLex) report_error("Can't open file %s", temp_file);
    g_free(temp_file);

    /* TARGET LEX */
    temp_file = g_strdup_printf("%s/target.lex", filepath);
    self->TargetLex = words_load(temp_file);
    if (!self->TargetLex) report_error("Can't open file %s", temp_file);
    g_free(temp_file);

    if (self->standalone_dictionary) {
    	self->SourceIdx = NULL;
    	self->TargetIdx = NULL;
    } else {
    	/* SOURCE INVIDX */
    	temp_file = g_strdup_printf("%s/source.invidx", filepath);
    	self->SourceIdx = inv_index_compact_load(temp_file);
    	if (!self->SourceIdx) report_error("Can't open file %s", temp_file);
    	g_free(temp_file);
	
    	/* TARGET INVIDX */
    	temp_file = g_strdup_printf("%s/target.invidx", filepath);
    	self->TargetIdx = inv_index_compact_load(temp_file);
    	if (!self->TargetIdx) report_error("Can't open file %s", temp_file);
    	g_free(temp_file);
    }

    /* SOURCE-TARGET DICTIONARY */
    temp_file = g_strdup_printf("%s/source-target.bin", filepath);
    self->SourceTarget = dictionary_open(temp_file);
    if (!self->SourceTarget) report_error("Can't open file %s", temp_file);
    g_free(temp_file);

    /* TARGET-SOURCE DICTIONARY */
    temp_file = g_strdup_printf("%s/target-source.bin", filepath);
    self->TargetSource = dictionary_open(temp_file);
    if (!self->TargetSource) report_error("Can't open file %s", temp_file);
    g_free(temp_file);

    /* Load offsets */
    if (self->standalone_dictionary) {
	    self->chunks = NULL;
    } else {
	    self->chunks = g_new(CorpusChunks, self->nrChunks);
    	for (i = 1; i <= self->nrChunks; ++i) {

    	    temp_file = g_strdup_printf("%s/source.%03d.crp", filepath, i);
    	    self->chunks[i-1].source_crp = fopen(temp_file, "r");
    	    if (!self->chunks[i-1].source_crp) report_error("Can't open file %s", temp_file);
    	    g_free(temp_file);

    	    temp_file = g_strdup_printf("%s/source.%03d.crp.index", filepath, i);
    	    self->chunks[i-1].source_offset = load_offsets(self, temp_file,
                                                           &(self->chunks[i-1].size));
    	    if (!self->chunks[i-1].source_offset) report_error("Can't open file %s", temp_file);
    	    g_free(temp_file);

    	    temp_file = g_strdup_printf("%s/target.%03d.crp", filepath, i);
    	    self->chunks[i-1].target_crp = fopen(temp_file, "r");
    	    if (!self->chunks[i-1].target_crp) report_error("Can't open file %s", temp_file);
    	    g_free(temp_file);

    	    temp_file = g_strdup_printf("%s/target.%03d.crp.index", filepath, i);
    	    self->chunks[i-1].target_offset = load_offsets(self, temp_file, NULL);
    	    if (!self->chunks[i-1].target_offset) report_error("Can't open file %s", temp_file);
    	    g_free(temp_file);
    	}
    }

    /* Rank caches */
    self->rank_cache1 = NULL;
    self->rank_cache2 = NULL;
    self->rank_cache_filename1 = NULL;
    self->rank_cache_filename2 = NULL;
    self->last_rank_cache = 2;

    /* NGrams */
    self->SourceGrams = NULL;
    self->TargetGrams = NULL;

    return self;
}

void corpus_info_free(CorpusInfo *corpus) {
    int i;

    if (corpus->config)
	    g_hash_table_destroy(corpus->config);

    if (corpus->SourceLex)
	    words_free(corpus->SourceLex);

    if (corpus->TargetLex)
	    words_free(corpus->TargetLex);

    if (corpus->SourceIdx) 
	    inv_index_compact_free(corpus->SourceIdx);

    if (corpus->TargetIdx) 
	    inv_index_compact_free(corpus->TargetIdx);
    
    if (corpus->SourceTarget)
	    dictionary_free(corpus->SourceTarget);

    if (corpus->TargetSource)
	    dictionary_free(corpus->TargetSource);

    if (corpus->SourceGrams)
        ngram_index_close(corpus->SourceGrams);

    if (corpus->TargetGrams)
        ngram_index_close(corpus->TargetGrams);

    for (i = 1; i <= corpus->nrChunks; ++i) {
        fclose(corpus->chunks[i-1].source_crp);
        fclose(corpus->chunks[i-1].target_crp);
        g_free(corpus->chunks[i-1].source_offset);
        g_free(corpus->chunks[i-1].target_offset);
    }
    g_free(corpus->chunks);

    if (corpus->rank_cache_filename1)
	    g_free(corpus->rank_cache_filename1);

    if (corpus->rank_cache_filename2)
	    g_free(corpus->rank_cache_filename2);

    if (corpus)
	    g_free(corpus);
}


nat_boolean_t corpus_info_has_ngrams(CorpusInfo *self) {
    char *temp_file;

    temp_file = g_hash_table_lookup(self->config, "n-grams");
    return (temp_file && atoi(temp_file) != 0);
}





