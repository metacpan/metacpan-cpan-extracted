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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#include <stdio.h>
#include <ctype.h>
#include <locale.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdarg.h>

#include <NATools.h>
#include DB_HEADER

#include "standard.h"
#include "invindex.h"
#include "unicode.h"
#include "partials.h"

/**
 * @file
 * @brief Corpora grams to database
 */

#define HASBIGRAM(x)    (x[0] && x[1]         )
#define HASTRIGRAM(x)   (HASBIGRAM(x) && x[2] )
#define HASTETRAGRAM(x) (HASTRIGRAM(x) && x[3])
#define ADDWORD(x, w)   x[0]=x[1]; x[1]=x[2]; x[2]=x[3]; x[3]=w
#define BIGRAM(x)       x[0], x[1]
#define TRIGRAM(x)      BIGRAM(x), x[2]
#define TETRAGRAM(x)    TRIGRAM(x), x[3]


static nat_boolean_t quiet;

void show_help() {
    printf("Usage modues:\n"
           "      nat-ngrams -n <nr> <crp-file> <bdb>\n");
    printf("Valid options:\n"
           " -h   shows this help screen, and exits.\n"
           " -V   shows version information and exits.\n"
           " -o   defines minimum occurrence limit.\n"
           " -d   used to dump the database.\n"
           " -j   used to join databases.\n"
           " -n   the n of n-grams to dump (2 to 4).\n"
           " -v   turns on verbose mode.\n"
           " -q   turns on quiet mode.\n");
           
}

void add_occurrence(DB *idx, int n, ...) {
	int i;
	va_list wp;
	DBT key, value;
	
	memset(&key, 0, sizeof(DBT));	
	memset(&value, 0, sizeof(DBT));	

	key.data = malloc(n * sizeof(nat_uint32_t));	
	va_start(wp, n);
	for (i=0; i < n; i++) {
		*((nat_uint32_t*) key.data + i) = va_arg(wp, nat_uint32_t);
	}
	va_end(wp);
	key.size = n * sizeof(nat_uint32_t);
	
	if (!idx->get(idx, NULL, &key, &value, 0)) {
		*((nat_uint32_t*)value.data) = *((nat_uint32_t*)value.data) + 1;
	} else {
		value.data = malloc(sizeof(nat_uint32_t));
		*((nat_uint32_t*)value.data) = 1;
		value.size = sizeof(nat_uint32_t);
	}
	idx->put(idx, NULL, &key, &value, 0);
}

void dump(char* db_file, char* lex_file, nat_uint32_t min) {
    DB *db = NULL;
    Words *wl;
    DBC *dbcp;
    DBT key, data;

    if (db_create(&db, NULL, 0))
        report_error("Error creating DB file structure\n");

    if (db->open(db, NULL, db_file, NULL, DB_BTREE, 0, 0666))
        report_error("Error opening ngrams DB file '%s'\n", db_file);
	
    if (!(wl = words_load(lex_file)))
        report_error("Error opening Lexicon file '%s'\n", lex_file);

    if (db->cursor(db, NULL, &dbcp, 0))
        report_error("Error getting a cursor for file '%s'\n", db_file);
	
    memset(&key,   0, sizeof(key));
    memset(&data,  0, sizeof(data));

    while (dbcp->c_get(dbcp, &key, &data, DB_NEXT) == 0) {
        int i, n = key.size / sizeof(nat_uint32_t);
		
        if (*((nat_uint32_t*)data.data) >= min) {
            printf("%u ", *((nat_uint32_t*)data.data));
            for (i=0; i < n; i++) {
                printf("%ls", words_get_by_id(wl, *((nat_uint32_t*)key.data+i)));
                if (i == n-1) {
                    printf("\n");
                } else {
                    printf(" ");
                }			
            }
        }
    }
    
    dbcp->c_close(dbcp);
    db->close(db,0);
}

void join(int argc, char **argv, int offset) {
    DB *target = NULL;
    int i;
	
    printf(" - accumulating on '%s'\n", argv[optind+0]);
	
    if (db_create( &target, NULL, 0)) {
        printf("Error creating DB file structure\n");
        exit(1);
    }
    if (target->open(target, NULL, argv[optind + 0], NULL, DB_BTREE, DB_CREATE, 0666)) {
        printf("Error opening ngrams DB file '%s'\n",argv[optind+0]);
        exit(1);
    }
	
    for (i=1; i<argc-offset; ++i) {
        DB *source = NULL;
        DBC *dbcp;
        DBT key, data, sdata;

        printf(" - processing '%s'\n", argv[optind+i]);
		
        if (db_create( &source, NULL, 0)) {
            printf("Error creating DB file structure\n");
            exit(1);
        }
        if (source->open(source, NULL, argv[optind + i], NULL, DB_BTREE, DB_RDONLY, 0666)) {
            printf("Error opening ngrams DB file '%s'\n", argv[optind+i]);
            exit(1);
        }
		
        if (source->cursor(source, NULL, &dbcp, 0)) {
            printf("Error getting a cursor for file '%s'\n", argv[optind+i]);
            exit(1);
        }
		
        memset(&key,   0, sizeof(key));
        memset(&data,  0, sizeof(data));
        memset(&sdata, 0, sizeof(sdata));
		
        while (dbcp->c_get(dbcp, &key, &data, DB_NEXT) == 0) {

            if (!target->get(target, NULL, &key, &sdata, 0))
                *((nat_uint32_t*)sdata.data) = *((nat_uint32_t*)sdata.data) +
                    *((nat_uint32_t*)data.data);
            else
                sdata = data;
            target->put(target, NULL, &key, &sdata, 0);			
        }
		
        dbcp->c_close(dbcp);
        source->close(source,0);
    }
    target->close(target,0);
	
    printf(" - done\n");
}


/**
 * The main program.
 * 
 * @todo Document this
 */
int main(int argc, char **argv)
{
    Corpus *Corpus = NULL;
    DB *idx = NULL;
    nat_boolean_t verbose = FALSE;
    nat_boolean_t to_join = FALSE;
    nat_boolean_t to_dump = FALSE;
    nat_uint32_t dump_min_occ = 0;
    CorpusCell *cell;
    int size, i, n = 0;

    extern char *optarg;
    extern int optind;
    int c;

    nat_uint32_t sentences = 0, bigrams = 0, trigrams = 0, tetragrams = 0;
    nat_uint32_t words[4] = {0, 0, 0, 0};

    init_locale();

    quiet = FALSE;
    while ((c = getopt(argc, argv, "o:n:jvhiqVd")) != EOF) {
        switch (c) {
        case 'h':
            show_help();
            return 0;
        case 'o':
            dump_min_occ = atoi(optarg);
            break;
        case 'd':
            to_dump = TRUE;
            break;
        case 'j':
            to_join = TRUE;
            break;
        case 'n':
            n = atoi(optarg);
            break;
        case 'V':
            printf(PACKAGE " version " VERSION "\n");
            return 0;
        case 'v':
            verbose = TRUE;
            break;
        case 'q':
            quiet = TRUE;
            break;
        default:
            fprintf(stderr, "Unknown option.\n");
            exit(1);
        }
    }
    
    if (dump_min_occ && !to_dump) fprintf(stderr, "Ignoring -o option.\n");
    
    if ((to_join && n) || (to_dump && to_join) || (to_dump && n)) {
        fprintf(stderr, "We can't do join/dump/compute ngrams in the same run.\n");
        return 0;
    }

    if (quiet && verbose) {
        fprintf(stderr, "Quiet and verbose can't work together\n");
        return 1;
    }
    
    if (to_dump) {
        if ((argc != 2 + optind)) {
            printf("%s: wrong number of arguments\n", argv[0]);
            printf("\tUsage: nat-ngrams -d <dbd> <lexicon-file>\n");
            return 1;
        }
	
        dump(argv[optind+0], argv[optind+1], dump_min_occ);

    } else if (to_join) {
        join(argc, argv, optind);

    } else {
        if (n > 4 || n < 2) {
            fprintf(stderr, "Ngrams value must be 2, 3 or 4, not '%d'.\n", n);
            return 0;
        }
        
        if ((argc != 2 + optind)) {
            printf("%s: wrong number of arguments\n", argv[0]);
            printf("\tUsage: nat-ngrams -n <nr> <crp-file> <bdb>\n");
            return 1;
        }
	
	    
        /**
         * Load corpus
         */
        Corpus = corpus_new();
        corpus_load(Corpus, argv[optind + 0]);
        
        /* idx = ngram_index_new(argv[optind + 1], n);  */
        if (db_create( &idx, NULL, 0)) {
            printf("Error creating ngrams DB file structure\n");
            exit(1);
        }
        if (idx->open(idx, NULL, argv[optind + 1], NULL, DB_BTREE, DB_CREATE, 0666)) {
            printf("Error creating ngrams DB file '%s'\n",argv[optind+1]);
            exit(1);
        }
        
        /**
         * Dump the crp to DB
         */
        sentences = bigrams = trigrams = tetragrams = 0;
        cell = corpus_first_sentence(Corpus);       
        do {
            sentences++;
            size = corpus_sentence_length(cell);
            
            for(i=0; i<size; i++) {
                ADDWORD(words, cell[i].word);
                if(HASBIGRAM(words)) {
                    /* Note, this can't be 'ANDED' in the previous if */
                    if (n==2) {
                        bigrams++;
                        add_occurrence(idx, 2, BIGRAM(words));
                    }
                }
                else continue;
            
                if(HASTRIGRAM(words)) {
                    /* Note, this can't be 'ANDED' in the previous if */
                    if (n==3)   {
                        trigrams++;
                        add_occurrence(idx, 3, TRIGRAM(words));
                    }
                }
                else continue;
            
                if(HASTETRAGRAM(words)) {
                    /* Note, this can't be 'ANDED' in the previous if */
                    if (n==4) {
                        tetragrams++;
                        add_occurrence(idx, 4, TETRAGRAM(words));
                    }
                }
            }   
        
            while(HASBIGRAM(words) && n==2) {
                bigrams++;
                add_occurrence(idx, 2, BIGRAM(words));
            
                if(HASTRIGRAM(words) && n==3)   {
                    trigrams++;
                    add_occurrence(idx, 3, TRIGRAM(words));
                }
                if(HASTETRAGRAM(words) && n==4) {
                    tetragrams++;
                    add_occurrence(idx, 4, TETRAGRAM(words));
                }
                ADDWORD(words, 0);
            }
	
            if(!(sentences%100)) { 
                printf(" processed %u sentences\r", sentences); 
            }
        }
        while((cell = corpus_next_sentence(Corpus)));

        if(verbose) printf("\nClosing the database now\n");

        idx->close(idx, 0);

        if(verbose) printf("Database closed\n");
        corpus_free(Corpus);
        printf(" %u\t\t%u\r", sentences, bigrams + trigrams + tetragrams); 
        printf("\n");	
    }    
    return 0;
}

