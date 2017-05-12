/* -*- Mode: C; c-file-style: "stroustrup" -*- */

/* NATools - Package with parallel corpora tools
 * Copyright (C) 1998-2001  Djoerd Hiemstra
 * Copyright (C) 2002-2014  Alberto Simões
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
#include <wctype.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <wchar.h>
#include <NATools.h>

#include "standard.h"
#include "invindex.h"
#include "unicode.h"
#include "partials.h"
#include "ngramidx.h"


/**
 * @file
 * @brief Corpora pre-processing unit
 */

/**
 * @brief maximum number of words in a translation unit
 */
#define MAXBUF 500

/**
 * @brief number of iterations between updating progress information
 */
#define STEP 100

/**
 * @brief value used as default size when alloccating the buffer for
 * the index
 */
#define DEFAULT_INDEX_SIZE 150000

static nat_boolean_t quiet;

static wchar_t *my_lowercase(wchar_t *sen, nat_boolean_t ignore_case) {
    if (ignore_case) {
        wchar_t *ptr = sen;
        while (*ptr) {
            *ptr = towlower(*ptr);
            ptr++;
        }
    }
    return sen;
}

void show_help(void) {
    printf("Usage: nat-pre [-iq] cp1 cp2 lex1 lex2 crp1 crp2\n");
    printf("Supported options:\n"
           "  -h shows this help message and exits\n"
           "  -V shows "PACKAGE" version and exits\n"
           "  -v activates verbose mode (incompatible with quiet mode)\n"
           "  -i activates ignore case\n"
           "  -q activates quiet mode\n"
           "Check nat-pre manpage for details.\n");
}

static int AddSentence(wchar_t **sen, unsigned long len,
		       Words* wl, Corpus *Corpus,
		       InvIndex *Index, nat_uint32_t sentence_number,
		       PartialCounts *partials, nat_boolean_t ignore_case)
{
    nat_uint32_t i, wid = 0;
    
    /* Add each sentence word */
    for (i = 0; i < len; i++) {
		int flag; 		/* 1: lowercase; 2: Capital; 3: UPPERCASE */

		if (isCapital(*sen)) flag = 2;
		else if (isUPPERCASE(*sen)) flag = 3;
		else flag = 1;
        
		if (wcslen(*sen) >= MAXWORDLEN) {
		    fprintf(stderr, "**WARNING** Truncating word '%ls'\n", *sen);
	            (*sen)[MAXWORDLEN - 1] = L'\0';
		}

        wid = words_add_word(wl, my_lowercase(*sen, ignore_case));

        if (wid) {
            partials = PartialCountsAdd(partials, wid);
		
            if (corpus_add_word(Corpus, wid, flag)) return 1;
		
            if (!wcsspn(*sen, IGNORE_WORDS)) {
                Index = inv_index_add_occurrence(Index, wid, 0, sentence_number);
            }
        } else {
            fprintf(stderr, "pre.c: received an empty word id.\n");
            return 2;
        }
		sen++;
    }

    /* If 'wid' is set, the sentence was not empty. */
    if (wid) {
		/* Add sentence delimiter (0) */
		if (corpus_add_word(Corpus, 0, 1)) return 3;
    } else {
        fprintf(stderr, "ERROR: empty string\n");
        return 4;
    }
    return 0;
}

/* This function signature is PORNOGRAPHIC! */
static int AnalyseCorpus(Corpus *C1, Words* wl1, InvIndex* Index1, wchar_t *text1, 
			 Corpus *C2, Words* wl2, InvIndex* Index2, wchar_t *text2,
			 nat_uint32_t *Nw1, nat_uint32_t *Nw2, nat_uint32_t *Nsen,
			 nat_uint32_t *TotNw1, nat_uint32_t *TotNw2, nat_uint32_t *TotNsen,
			 PartialCounts *partials1, PartialCounts *partials2,
                         nat_boolean_t ignore_case)
{
    unsigned long len1, len2;
    wchar_t *sen1[MAXBUF], *sen2[MAXBUF];
    
    if (!quiet) {
		fprintf(stderr, "\n Sentences\tWords cp1\tWords cp2\n");
		fprintf(stderr," ");
    }
    do {
		/* get a sentence for each corpus (array of words) */
		len1 = NextTextSentence(sen1, &text1, MAXBUF, SOFTDELIMITER, HARDDELIMITER);
		len2 = NextTextSentence(sen2, &text2, MAXBUF, SOFTDELIMITER, HARDDELIMITER);

		if (len1 && len2) {
		    (*TotNsen)++;
		    (*TotNw1) += len1;
		    (*TotNw2) += len2;
		    
		    if (!quiet && *TotNsen % STEP == 0 )
				fprintf(stderr, "\r  %7d\t %7d\t %7d", *TotNsen, *TotNw1, *TotNw2);
		    
		    if (max(len1, len2) <= MAXBUF) {
				(*Nsen)++;
				(*Nw1) += len1;
				(*Nw2) += len2;
				if (AddSentence(sen1, len1, wl1, C1, Index1,
		                                *Nsen, partials1, ignore_case))
	                    return 1;
				if (AddSentence(sen2, len2, wl2, C2, Index2,
		                                *Nsen, partials2, ignore_case))
	                    return 1;
		    } else {
				fprintf(stderr, "\n** WARNING: sentence too big: max(%ld,%ld)>%d\n",
	                        len1, len2,MAXBUF);
				/* 
				   fprintf(stderr, "**          s1: %ls\n", *sen1);
				   fprintf(stderr, "**          s2: %ls\n", *sen2);
				*/
		    }
		}
    } while (text1 != NULL && text2 != NULL);

    if (!quiet)
		fprintf(stderr, "\r  %7d\t %7d\t %7d\n\n", *TotNsen, *TotNw1, *TotNw2);

    if (text1 != NULL || text2 != NULL) return 2;
    else  return 0;
}

 
/**
 * The main program.
 * 
 * @todo Document this
 */
int main(int argc, char **argv)
{
    Words *wordLst1, *wordLst2;
    Corpus *Corpus1, *Corpus2;
    InvIndex *Index1, *Index2;
    char *indexfile;

    wchar_t *text1, *text2;

    nat_boolean_t verbose     = FALSE;
    nat_boolean_t ignore_case = FALSE;

    nat_uint32_t Nw1, Nw2, Nsen;
    nat_uint32_t TotNw1, TotNw2, TotNsen;
    nat_uint32_t UNw1, UNw2, UNsen;
    nat_uint32_t TotUNw1, TotUNw2;
    int result;

    PartialCounts partials1, partials2;

    // extern char *optarg;
    extern int optind;
    int c;

    init_locale();

    quiet = FALSE;

    while ((c = getopt(argc, argv, "hvqiV")) != EOF) {
	switch (c) {
        case 'h':
            show_help();
            return 0;
	case 'V':
	    printf(PACKAGE " version " VERSION "\n");
            return 0;
        case 'i':
            ignore_case = TRUE;
            break;
	case 'v':
	    verbose = TRUE;
	    break;
	case 'q':
	    quiet = TRUE;
	    break;
	default:
            show_help();
            return 1;
	}
    }

    if (quiet && verbose) {
	fprintf(stderr, "Quiet and verbose can't work together\n");
	return 1;
    }

    if (argc != 6 + optind) {
	printf("nat-pre: wrong number of arguments\n");
        show_help();
        return 1;
    }

    if (verbose) {
	printf("\nMaximum sentence length: %d words\n", MAXLEN); 
	printf("Sentence delimiter: '%c'\tParagraph delimiter: '%c'\n",
               SOFTDELIMITER, HARDDELIMITER);
    }


    /* 
     *  INITIALIZE/OPEN LEXICON
     */
    wordLst1 = words_quick_load(argv[optind + 2]);
    if (!wordLst1) {
	if (!quiet)
	    fprintf(stderr, " Source wordlist does not exist. Creating a new one\n");
	wordLst1 = words_new();
	if (!wordLst1) report_error("Not enough memory!");
    }

    wordLst2 = words_quick_load(argv[optind + 3]);
    if (!wordLst2) {
	if (!quiet)
	    fprintf(stderr, " Target wordlist does not exist. Creating a new one\n");
	wordLst2 = words_new();
	if (!wordLst2) report_error("Not enough memory!");
    }
    
    /*
     * INITIALIZE CORPUS FILES
     */
    Corpus1 = corpus_new();
    Corpus2 = corpus_new();

    /* 
     * INITIALIZE INVERTION INDEXES
     */
    Index1 = inv_index_new(DEFAULT_INDEX_SIZE);
    Index2 = inv_index_new(DEFAULT_INDEX_SIZE);

    /* 
     * INITIALIZE PARTIAL OCCURRENCES COUNT
     */
    partials1.size   = DEFAULT_INDEX_SIZE;
    partials1.buffer = g_new0(nat_uint32_t, partials1.size);
    partials1.last   = 0;

    partials2.size   = DEFAULT_INDEX_SIZE;
    partials2.buffer = g_new0(nat_uint32_t, partials2.size);
    partials2.last   = 0;

    /* 
     * OTHER VARIABLES...
     */
    TotNw1 = 0;
    TotUNw1 = 0;

    TotNw2 = 0;
    TotUNw2 = 0;

    TotNsen = 0; 

    if (verbose) printf("\nReading %s...\n", argv[optind]);
    text1 = ReadText(argv[optind]);

    if (verbose) printf("Reading %s...\n", argv[optind + 1]);
    text2 = ReadText(argv[optind + 1]);

    if (text1 == NULL || text2 == NULL)
	report_error("ReadText: %s %s", argv[optind], argv[optind+1]);

    Nw1 = 0; UNw1 = 0;
    Nw2 = 0; UNw2 = 0;

    Nsen = 0; UNsen = 0;
    
    result = AnalyseCorpus(Corpus1, wordLst1, Index1, text1,
			   Corpus2, wordLst2, Index2, text2,
			   &UNw1, &UNw2, &UNsen, &Nw1, &Nw2, &Nsen,
			   &partials1, &partials2, ignore_case);

    TotUNw1 += UNw1;
    TotUNw2 += UNw2;

    TotNw1 += Nw1;
    TotNw2 += Nw2;

    TotNsen += Nsen;

    if (result) {
	if (result == 2) report_error("AnalyseCorpus: lengths do not match");
	else report_error("AnalyseCorpus");
    }

    if (verbose) {
	printf("\nTotal corpus 1:\n");
	printf(" %d words\n", (int) TotNw1);
	printf(" %d words used\n", (int) TotUNw1);
	printf(" %d different words\n",words_size(wordLst1));

	printf("\nTotal corpus 2:\n");
	printf(" %d words\n", (int) TotNw2);
	printf(" %d words used\n", (int) TotUNw2);
	printf(" %d different words\n",words_size(wordLst2));
    }

    if (verbose) printf ("Checking corpus sizes\n");
    Nw1 = corpus_sentences_nr(Corpus1);
    Nw2 = corpus_sentences_nr(Corpus2);

    if (Nw1 != Nw2) report_error("Corpus lengths didn't pass final test");
    if (Nw1 == 0)   report_error("No sentences found\n");

    /* Save LEXICONS */
    if (verbose) printf ("Saving lexicon files\n");
    if (words_save(wordLst1, argv[optind + 2]) != TRUE) report_error("SaveWords 1");
    if (words_save(wordLst2, argv[optind + 3]) != TRUE) report_error("SaveWords 2");

    /* Save CORPORA */
    if (verbose) printf ("Saving corpora files\n");
    if (corpus_save(Corpus1, argv[optind + 4])) report_error("SaveCorpus 1");
    if (corpus_save(Corpus2, argv[optind + 5])) report_error("SaveCorpus 2");

    /* Save INVINDEXES */
    if (verbose) printf ("Saving invindex files\n");
    indexfile = g_strdup_printf("%s.invidx", argv[optind + 4]);
    if (inv_index_save_hash(Index1, indexfile, TRUE)) report_error("SaveInvIndex 1");

    g_free(indexfile);
    indexfile = g_strdup_printf("%s.invidx", argv[optind + 5]);
    if (inv_index_save_hash(Index2, indexfile, TRUE)) report_error("SaveInvIndex 2");
    g_free(indexfile);

    /* Save PartialCounts */
    indexfile = g_strdup_printf("%s.partials", argv[optind + 4]);
    PartialCountsSave(&partials1, indexfile);
    g_free(indexfile);

    indexfile = g_strdup_printf("%s.partials", argv[optind + 5]);
    PartialCountsSave(&partials2, indexfile);
    g_free(indexfile);

    /* Free Structures */
    words_free(wordLst1);
    words_free(wordLst2);

    free(text1);
    free(text2);

    corpus_free(Corpus1);
    corpus_free(Corpus2);

    inv_index_free(Index1);
    inv_index_free(Index2);
    
    return 0;
}

