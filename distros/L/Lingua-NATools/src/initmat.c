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

#include "standard.h"
#include <NATools/corpus.h>
#include "matrix.h"


/**
 * @file
 * @brief Allocated the sparse matrix with words co-occurrences
 */


/* #define SAVE_DOTS 1 */

static nat_boolean_t load_exc_words(nat_uint32_t nr, char *buffer, char* file)
{
    FILE *fd;
    nat_uint32_t id;
    fd = fopen(file, "rb");
    if (!fd) return FALSE;

    do {
	if (fread(&id, sizeof(nat_uint32_t), 1, fd)) {
	    if (id >= nr) return FALSE;
	    buffer[id] = 1;
	}
    } while(!feof(fd));

    return TRUE;
}

static Matrix* InitialEstimate(nat_boolean_t quiet,
                               nat_uint32_t Nrow, nat_uint32_t Ncolumn, 
			       Corpus *corpus1, Corpus *corpus2,
			       char *excWrds1,	char *excWrds2)
{ 

#ifdef SAVE_DOTS
    FILE *dots_fd;
#endif

    Matrix *matrix;
    unsigned long cSentence, nSentences;
    unsigned long r, c, l;
    int jjdoneR, jjdoneC;
    CorpusCell *s1, *s2, *sen2;

    if (!quiet)
        fprintf(stderr, "\nAllocating the sparse matrix (%d x %d):      ",
                Nrow, Ncolumn);

    /* Alloc matrix */
    matrix = AllocMatrix(Nrow, Ncolumn);
    if (!matrix) report_error("InitialEstimate: AllocMatrix failed");

    /* prepare variables for percent counting */
    nSentences = corpus_sentences_nr(corpus1);
    cSentence = 0;

    s1 = corpus_first_sentence(corpus1);
    s2 = sen2 = corpus_first_sentence(corpus2);

#ifdef SAVE_DOTS
    dots_fd = fopen("__dots__", "w");
    if (!dots_fd) report_error("cannot open __dots__ file");
#endif

    while (s1 != NULL && s2 != NULL) {
	/* print percentage information */
        if (!quiet)
            fprintf(stderr, "\b\b\b\b\b%4.1f%%",
                    (float) (cSentence++) * 99.9f / (float) nSentences);

	l = max(corpus_sentence_length(s1),
		corpus_sentence_length(s2));
	if (l <= MAXLEN) {
            jjdoneR = 0;
	    for(r = 1; r <= l && !jjdoneR ; r++) {
		if (!(excWrds1 && s1->word && excWrds1[s1->word])) {
                    jjdoneC = 0;
		    for(c = 1; c <= l && !jjdoneC ; c++) {
			if (excWrds2 && s2->word && excWrds2[s2->word]) {
			    ++s2;
			} else {
			    if (s1->word && s2->word) {
				if (IncValue(matrix, MATRIX_1, 1.0f / (float)l, s1->word, s2->word))
				    report_error("InitialEstimate: IncValue failed");
#ifdef SAVE_DOTS
				fprintf(dots_fd, "%d %d\n", s1->word, s2->word);
#endif
				++s2;
			    }
			    else {
				if (s1->word == 0) {
				    if (IncValue(matrix, MATRIX_1, 1.0f / (float)l, NULLWORD, s2->word))
					report_error("InitialEstimate: IncValue failed");
#ifdef SAVE_DOTS
				fprintf(dots_fd, "0 %d\n", s2->word);
#endif
				    ++s2;
                                    jjdoneR=1;
				}
				else {
				    if (IncValue(matrix, MATRIX_1, 1.0f / (float)l, s1->word, NULLWORD))
					report_error("InitialEstimate: IncValue failed");
#ifdef SAVE_DOTS
				fprintf(dots_fd, "%d 0\n", s1->word);
#endif
                                    jjdoneC=1;
                                }
			    }
			}
		    }
		}
		if (s1->word) s1++;
		s2 = sen2;
	    }
	}
	s1 = corpus_next_sentence(corpus1);
	s2 = sen2 = corpus_next_sentence(corpus2);
    }
    
#ifdef SAVE_DOTS
    fclose(dots_fd);
#endif

    if (s1 != NULL || s2 != NULL)
	report_error("InitialEstimate: failed to evaluate all sentences");

    if (!quiet) fprintf(stderr, "\b\b\b\b\b\b done \n");

    return matrix;
}

void show_help () {
    printf("Usage:\n"
           "  nat-initmat [-q] corpusFile1 corpusFile2 matFile\n"
           "  nat-initmat [-q] corpusFile1 corpusFile2 excludeWrds1 excludeWrds2 matFile\n");
    printf("Supported options:\n"
           "  -h shows this help message and exits\n"
           "  -V shows "PACKAGE" version and exits\n"
           "  -q activates quiet mode\n"
           "Check nat-initmat manpage for details.\n");
}



/**
 * @brief The main function 
 *
 * @todo Document this
 */
int main(int argc, char **argv)
{
    char *excWrds1 = NULL;
    char *excWrds2 = NULL;
    char *matFile;
    Corpus *corpus1, *corpus2;
    Matrix *matrix;
    nat_uint32_t total1, total2;
    nat_boolean_t quiet = FALSE;

    // extern char *optarg;
    extern int optind;
    int c;
    
    while ((c = getopt(argc, argv, "hqV")) != EOF) {
        switch (c) {
        case 'h':
            show_help();
            return 0;
        case 'V':
            printf(PACKAGE " version " VERSION "\n");
            return 0;
        case 'q':
            quiet = TRUE;
            break;
        default:
            show_help();
            return 1;
        }
    }
    
    if (argc != optind + 3 && argc != optind + 5) {
	printf("nat-initmat: wrong number of arguments\n");
        show_help();
        return 1;
    }
    
    corpus1 = corpus_new();
    corpus2 = corpus_new();

    corpus_load(corpus1, argv[optind + 0]);
    corpus_load(corpus2, argv[optind + 1]);

    if (corpus_sentences_nr(corpus1) != corpus_sentences_nr(corpus2))
	report_error("initmat.c: lengths do not match");

    /* total1 and total2 are number of words (??) */
    total1 = corpus_diff_words_nr(corpus1);
    total2 = corpus_diff_words_nr(corpus2);

    if (argc == 6) {
	excWrds1 = g_new0(char, total1 + 1);
	if (!load_exc_words(total1, excWrds1, argv[optind + 2]))
	    report_error("initmat.c: error loading excludeWrds1");

	excWrds2 = g_new0(char, total2 + 1);
	if (!load_exc_words(total2, excWrds2, argv[optind + 3])) 
	    report_error("initmat.c: error loading excludeWrds2");

	matFile = argv[optind + 4];
    } else {
	matFile = argv[optind + 2];
    }

    matrix = InitialEstimate(quiet, total1, total2, corpus1, corpus2, excWrds1, excWrds2);
    
    if (argc == optind + 5) {
	g_free(excWrds1);
	g_free(excWrds2);
    }

    if (SaveMatrix(matrix, matFile)) report_error("SaveMatrix");

    /* fprintf(stderr, 
       "Matrix total after initial estimate:%9.2f\n", MatrixTotal(matrix, Matrix1)); */

    if (!quiet) {
        fprintf(stderr, "Memory used:%10.1f kb\n\n", (float) BytesInUse(matrix) / 1024.0f);
    }

    corpus_free(corpus1);
    corpus_free(corpus2);
    FreeMatrix(matrix);

    return 0;
}
