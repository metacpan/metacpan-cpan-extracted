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

#include <wchar.h>
#include <string.h> 
#include "srvshared.h"
#include "unicode.h"

int send_TU(int sd, TU* tu)
{
    char sbuf[1024];
    nat_boolean_t toexit = FALSE;

    if (tu -> quality >= 0.0) {
	snprintf(sbuf, 1024, "%% %f\n", tu->quality);
	if (write(sd, sbuf, strlen(sbuf)) < 0)
	    toexit = 1;
    }

    if (!toexit && (write(sd, tu->source, strlen(tu->source)) < 0))
	toexit = 1;

    if (!toexit && (write(sd, "\n", 1)<0)) toexit = 1;

    if (!toexit && (write(sd, tu->target, strlen(tu->target)) < 0))
	toexit = 1;

    if (!toexit && (write(sd, "\n", 1)<0)) toexit = 1;

    return toexit;
}


void destroy_TU(TU* tu) {
    if (tu) {
    	if (tu->source) g_free(tu->source);
    	if (tu->target) g_free(tu->target);
    	g_free(tu);
    }
}

char *convert_sentence(Words *W, CorpusCell *sentence) {
    char *ans;
    CorpusCell *ptr;
    GString *str = g_string_new("");
    ptr = sentence;
    while (ptr->word) {
    	wchar_t *word = words_get_by_id(W, ptr->word);
    	if (ptr->flags & 0x1) {
    	    word = uppercase_dup(word);
    	} else if (ptr->flags & 0x2) {
    	    word = capital_dup(word);
    	} else {
    	    word = wcs_dup(word);
    	}
        g_string_append_printf(str, "%ls ", word);
    	g_free(word);
    	ptr++;
    }

    ans = str->str; //strdup((wchar_t*)str->str);
    g_string_free(str, FALSE);

    return ans;
}

TU* create_TU(CorpusInfo *corpus, double q,
              CorpusCell *source, CorpusCell *target) {
    TU *tu = g_new(TU, 1);			
    
    tu->quality = (corpus->has_rank) ? q : -1.0;
    tu->source = convert_sentence(corpus->SourceLex, source);
    tu->target = convert_sentence(corpus->TargetLex, target);

    return tu;
}

struct callback {
    CorpusInfo *corpus;
    int fd;
    int direction;
    GSList *list;
};

static int list_grams_callback(void *dataS, int argc, char **argv, char **azColName) {
    struct callback *data = (struct callback*)dataS;
    GSList *l = NULL;
    int i;

    for (i = 0; i < argc; ++i) {
        l = g_slist_append(l, argv[i]);
    }
    data->list = g_slist_append(data->list, l);
    return 0;
}

static int dump_grams_callback(void *dataS, int argc, char **argv, char **azColName) {
    struct callback *data = (struct callback*)dataS;
    int i;

    for (i = 0; i < argc; ++i) {
        write(data->fd, argv[i], strlen(argv[i]));
        write(data->fd, " ", 1);
    }
    write(data->fd, "\n", 1);
    return 0;
}

GSList* dump_ngrams(int fd, CorpusInfo *corpus, int direction,
                    wchar_t words[50][150], int n) {
    char* tablename;
    char* word[4];
    char* sql;
    char* errmsg = NULL;
    int i, j, rc;
    int havewhere = 0;
    GSList *retval;

    struct callback* data;

    if (!corpus_info_has_ngrams(corpus)) {
        ERROR(fd);
        return NULL;
    } else {
        n -= 2;
        
        /* Calculate table name */
        switch (n) {
        case 2:
            tablename = g_strdup("bigrams");
            break;
        case 3:
            tablename = g_strdup("trigrams");
            break;
        case 4:
            tablename = g_strdup("tetragrams");
            break;
        default:
            if (fd) ERROR(fd);
            return NULL;
        }
        
        /* Construct SQL Query -- Hairy! */
        for (i = 0; i < 4; i++) {
            if (i < n) {
                if (wcscmp(words[2+i], L"*") == 0 || wcscmp(L"[]", words[2+i])==0) {
                    /* [] should mean end or beginning of string...
                       Not yet available */
                    word[i] = strdup("");
                } else {
                    if (havewhere) {
                        asprintf(&word[i]," AND w%d='%ls'",i+1, words[2+i]);
                    } else {
                        asprintf(&word[i]," WHERE w%d='%ls'",i+1, words[2+i]);
                        havewhere = 1;
                    }
                }
            } else {
                word[i] = strdup("");
            }
        }

        /* HARD CODED IS BAD IDEA!!!! */
        sql = g_strdup_printf("SELECT * FROM %s%s%s%s%s LIMIT 10",
                              tablename,
                              word[0], word[1], word[2], word[3]); 

        data = g_new0(struct callback, 1);
        data->fd = fd;
        data->direction = direction;
        data->corpus = corpus;
        data->list = NULL;

        /* Check if the ngrams files are already opened. If not, open them. */
        if (direction > 0 && !corpus->SourceGrams) {
            char* tmp = g_strdup_printf("%s/S.%%d.ngrams", corpus->filepath);
            corpus->SourceGrams = ngram_index_open_and_attach(tmp);
            g_free(tmp);
        }
        if (direction < 0 && !corpus->TargetGrams) {
            char* tmp = g_strdup_printf("%s/T.%%d.ngrams", corpus->filepath);
            corpus->TargetGrams = ngram_index_open_and_attach(tmp);            
            g_free(tmp);
        }

        if ((direction > 0 && !corpus->SourceGrams) ||
            (direction < 0 && !corpus->TargetGrams)) {
            g_free(sql);
            g_free(tablename);
            for (j = 0; j < i-1; j++) g_free(word[j]);
            ERROR(fd);
            return NULL;                    
        }

        if (fd) {
            rc = sqlite3_exec( (direction>0)?corpus->SourceGrams->dbh:corpus->TargetGrams->dbh,
                               sql,
                               dump_grams_callback, data, &errmsg);
        } else {
            rc = sqlite3_exec( (direction>0)?corpus->SourceGrams->dbh:corpus->TargetGrams->dbh,
                               sql,
                               list_grams_callback, data, &errmsg);
        }

        if (rc != SQLITE_OK) {
    	    sqlite3_free(errmsg);
    	    if (fd) ERROR(fd);
        } else {
    	    if (fd) DONE(fd);
        }

        retval = data->list;
        g_free(data);
        g_free(sql);
        g_free(tablename);
        for (i = 0; i < 4; i++) g_free(word[i]);

        return retval;
        
    }

}


GSList* dump_conc(int fd, CorpusInfo *corpus, int direction,
		  nat_boolean_t both, nat_boolean_t exact_match,
		  wchar_t words[50][150], int i) {

    GSList *results = NULL;
    
    int j = 2;
    nat_uint32_t wids[50];
    nat_uint32_t total = 20;
    nat_uint32_t *occs = NULL, *occs1 = NULL, *occs2 = NULL;
    nat_uint32_t wid;
    nat_boolean_t need_free = FALSE;
    nat_uint32_t *otherwids = NULL;
    nat_uint32_t counter;
    TU* tu;

    if (!corpus || !direction || corpus->standalone_dictionary) {
	    if (fd) ERROR(fd);
	    return NULL;
    } else {
	
    	if (wcscmp(words[j], L"<=>") == 0 || wcscmp(words[j], L"<->") == 0) {
    	    if (fd) ERROR(fd);
    	    return NULL;
    	}

    	if (wcscmp(words[j], L"*") == 0) {
    	    wids[j-2] = 1;
    	} else {
    	    wid = words_get_id( (direction>0)?corpus->SourceLex:corpus->TargetLex, words[j]);

    	    if (!wid) {
    		if (fd) ERROR(fd);
    		return NULL;
    	    }

    	    wids[j-2] = wid;

    	    occs = inv_index_compact_get_occurrences( (direction > 0)?corpus->SourceIdx:corpus->TargetIdx, wid);

    	}
    	wids[j-1] = 0;

	
    	if (i > 3) {
    	    for (j = 3; j < i; j++) {

    		if (words[j][0] == '#' && iswdigit(words[j][1])) {
    		    swscanf(words[j], L"#%d", &total);
    		    total = total>1000?1000:total;
    		    wids[j-2] = 0;
    		    break;
    		} else if (wcscmp(words[j], L"<=>") == 0 || wcscmp(words[j], L"<->") == 0) {
    		    if (direction < 0) {
    			if (fd) ERROR(fd);
    			return NULL;
    		    }
    		    direction = -direction;
    		    wids[j-2] = 0;
    		    otherwids = &(wids[j-1]);
    		} else {
    		    if (wcscmp(words[j], L"*") == 0) {
    			wids[j-2] = 1;
    		    } else {
    			wid = words_get_id( (direction > 0)?corpus->SourceLex:corpus->TargetLex, words[j]);
			
    			if (!wid) {
    			    if (need_free) g_free(occs);
    			    if (fd) DONE(fd);
    			    return NULL;
    			}

    			wids[j-2] = wid;
		    
    			occs1 = inv_index_compact_get_occurrences(
                                (direction > 0)?corpus->SourceIdx:corpus->TargetIdx,
                                wid);
    			occs2 = intersect(occs, occs1);
    			if (need_free) g_free(occs);
    			occs = occs2;
    			need_free = TRUE;
    		    }
    		}
	    }
	    wids[j-2] = 0;
	}
	
#if DEBUG      
	LOG("Retrieving and processing %d unities", length(occs));
#endif
	
	counter = 0;
	
	occs1 = occs;
	
	while(occs1 && *occs && counter < total) {
	    nat_uchar_t  chunk;
	    double q1 = -1, q2 = -1;
	    nat_boolean_t has_kwalitee = FALSE;
	    nat_uint32_t sentence = unpack(*occs, &chunk);
	    CorpusCell *src, *trg;

	    src = corpus_retrieve_sentence(corpus,  TRUE, chunk, sentence-1, &q1);
	    trg = corpus_retrieve_sentence(corpus, FALSE, chunk, sentence-1, &q2);

	    if (q1 >= 0 && q2 >= 0) has_kwalitee = TRUE;
		
	    if (exact_match && both) {
    		if (corpus_strstr(src, wids) && corpus_strstr(trg, otherwids)) {
    		    tu = create_TU(corpus, q1, src, trg);
    		    if (fd) {
                        if (send_TU(fd, tu)) break;
                        destroy_TU(tu);
    		    } else {
                        results = g_slist_append(results, tu);
    		    }
    		    counter ++;
    		}
	    } else if (both) {
    		tu = create_TU(corpus, q1, src, trg);
    		if (fd) {
    		    if (send_TU(fd,tu)) break;
    		    destroy_TU(tu);
    		} else {
    		    results = g_slist_append(results, tu);
    		}
    		counter++;
	    } else if (direction < 0) {
    		if (!exact_match || (exact_match && corpus_strstr(trg, wids))) {
    		    tu = create_TU(corpus, q1, src, trg);
    		    if (fd) {
    			    if (send_TU(fd,tu)) break;
    			    destroy_TU(tu);
    		    } else {
    			    results = g_slist_append(results, tu);
    		    }
    		    counter++;
    		}
	    } else {
    		if (!exact_match || (exact_match && corpus_strstr(src, wids))) {
    		    tu = create_TU(corpus, q1, src, trg);
    		    if (fd) {
        			if (send_TU(fd,tu)) break;
        			destroy_TU(tu);
    		    } else {
        			results = g_slist_append(results, tu);
    		    }
    		    counter++;
    		}
	    }

	    g_free(src);
	    g_free(trg);
	    
	    occs++;
	}

#if DEBUG
	LOG("Sent %d units", counter); 
#endif
	if (fd) DONE(fd);
	
	if (need_free) g_free(occs1);
    } 


    return results;
}

CorpusCell *corpus_retrieve_sentence(CorpusInfo* corpus,
				     nat_boolean_t source,
				     const nat_uchar_t chunk,
				     nat_uint32_t sentence,
				     double *kwalitee) 
{
    nat_uint32_t begin, end, delta;
    char *rank_filename;
    nat_uint32_t *offsets;
    double *ranks = NULL;
    nat_uint32_t size;
    FILE *fh;
    CorpusCell *buf;

    char *basedir = g_hash_table_lookup(corpus->config, "homedir");

    size = corpus->chunks[chunk-1].size;
    if (source) {
	    offsets = corpus->chunks[chunk-1].source_offset;
        fh = corpus->chunks[chunk-1].source_crp;
    } else {
	    offsets = corpus->chunks[chunk-1].target_offset;
        fh = corpus->chunks[chunk-1].target_crp;
    }

    rank_filename = g_strdup_printf("%s/rank.%03hhu.rnk", basedir, chunk);
    ranks = rank_load(corpus, rank_filename, size);

    begin = offsets[sentence];
    end = offsets[sentence+1];
    delta = end - begin;

    buf = g_new0(CorpusCell, delta);
    fseek(fh, begin*sizeof(CorpusCell) + CORPUS_HEADER_SIZE, 0);
    fread( buf, sizeof(CorpusCell),delta,fh);

    if (corpus->has_rank) {
	*kwalitee = ranks[sentence];
    }

    return buf;
}

double* rank_load(CorpusInfo *corpus, const char* file, const nat_uint32_t size) {
    FILE *rank;
    
    if (corpus->rank_cache1 && strcmp(corpus->rank_cache_filename1, file) == 0) {
	corpus->has_rank = 1;
	return corpus->rank_cache1;
    } else if (corpus->rank_cache2 && strcmp(corpus->rank_cache_filename2, file) == 0) {
	corpus->has_rank = 1;
	return corpus->rank_cache2;
    } else {
	rank = fopen(file, "rb");
	if (rank) {
	    double *ranks;
	    corpus->has_rank = 1;
	    
	    ranks = g_new(double, size);
	    fread(ranks, sizeof(double), size, rank);
	    fclose(rank);
	    
	    if (corpus->last_rank_cache == 1) {
		corpus->last_rank_cache = 2;
		if (corpus->rank_cache1) {
		    g_free(corpus->rank_cache1);
		    g_free(corpus->rank_cache_filename1);
		}
		corpus->rank_cache1 = ranks;
		corpus->rank_cache_filename1 = strdup(file);
		return corpus->rank_cache1;
	    } else {
		corpus->last_rank_cache = 1;
		if (corpus->rank_cache2) {
		    g_free(corpus->rank_cache2);
		    g_free(corpus->rank_cache_filename2);
		}
		corpus->rank_cache2 = ranks;
		corpus->rank_cache_filename2 = strdup(file);
		return corpus->rank_cache2;
	    }
	} else {
	    corpus->has_rank = 0;
	    return NULL;
	}
    }
}

