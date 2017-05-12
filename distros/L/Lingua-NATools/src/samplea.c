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


/* #define DEBUG */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "standard.h"
#include <NATools/corpus.h>
#include "matrix.h"


/**
 * @file
 * @brief Implementation of the SampleA EM-Algorithm variant
 */


/**
 * @brief Null word identifier
 */
#define NULLWORD 1


/**
 * @brief Minimum number of samples
 */
#define MINSAMPLES 100


/**
 * @brief ??
 *
 * @todo Understand this value
 */
#define SERR 0.01f


/**
 * @brief handy random macro
 */
#define RANDOM(num) (double)(((double)rand()*(num))/(double)(RAND_MAX+1.0))

/*     rand() uses a multiplicative congruential random-number gen-
       erator  with  period  2^32  that  returns successive pseudo-
       random numbers in the range from 0 to RAND_MAX.
       (see page 28, Hammersley and Handscomb)
*/


#ifdef DEBUG

#include <NATools/words.h>
struct cWords W1, W2;

static void printSentence(nat_uint32_t *st, struct cWords *Words)
{
    while (*st) printf("%s ",GiveString(Words,*st++));
    printf("\b.\n");
}

#endif

/* EM algorithm */

static void SortMatrix(CorpusCell *s, nat_uint32_t *st, nat_uint32_t length)
{
    nat_uint32_t i, j, lt;
    i = 0;
    lt = 0;
    while (s[i].word) {
	j = 0;
	while (j < lt && st[j] < s[i].word) j++;
	if (j == lt)
	    st[lt++] = s[i].word;
	else {
	    memmove(st+j+1, st+j, sizeof(*st) * (lt-j));
	    st[j] = s[i].word;
	    lt++;
	}
	i++;
    }
    while (lt < length) {  /* fill up longest sentence */
	memmove(st+1, st, sizeof(*st) * (lt++));
	st[0] = NULLWORD;
    }
    st[lt] = 0;
}

static double MarginalProbs(double *p, double *pi, double *pj, nat_uint32_t lr, nat_uint32_t lc)
{
    double total, f;
    nat_uint32_t r, c;
    total = 0.0f;
    for (c = 0; c < lc; c++) pj[c] = 0;
    for (r = 0; r < lr; r++) {
	pi[r] = 0;
	for (c = 0; c < lc; c++) {
	    f = p[r*MAXLEN + c];
	    pj[c] += f;
	    pi[r] += f;
	}
	total += pi[r];
    }
    return total;
}

#if 0
/* Not being used */
static void randomtest(void)
{
    int i;
    double f;
    for (i=0;i<100;i++) {
	f = RANDOM(6.43f);
	fprintf(stderr, "%f, ", f);
    }
}
#endif

static long MonteCarlo (nat_uint32_t *e, double *p, double *pi, double pN, nat_uint32_t l)
{
    nat_uint32_t r, c, i, j;
    double d, mtse, rnd, s[MAXLEN][MAXLEN], si[MAXLEN], sN;
    long Nsamples;

    Nsamples = 0;
    do {
	do {
	    memcpy(si, pi, MAXLEN * sizeof(double));
	    memcpy(&s[0][0], p, MAXLEN * MAXLEN * sizeof(double));
	    sN = pN;
	    i = 0;
	    while (i < l && sN > 0.0f) {
		rnd = RANDOM(sN);
		r = 0; c = 0;
		while (r < l && rnd > si[r])
		    rnd -= si[r++];
		while (c < l && rnd > s[r][c])
		    rnd -= s[r][c++];
		if (r < l && c < l) { 
		    e[r*MAXLEN + c] += 1;
		    sN = 0;
		    for (j = 0; j < l; j++) {
			si[j] -= s[j][c];
			sN += si[j];
			s[j][c] = s[r][j] = 0;
		    }
		    sN -= si[r];
		    si[r] = 0;
		}
		i++;
	    }
	} while (Nsamples < 65500 && ++Nsamples % MINSAMPLES != 0);

	mtse = 0;           /* compute mean theortical standard error */
	for (r = 0; r < l; r++)
	    for (c = 0; c < l; c++) {
		d = ((double) e[r*MAXLEN + c]) / (double) Nsamples;
		mtse += d * (1-d);
	    }
    } while (Nsamples < 65500 && sqrt(mtse / (Nsamples * l * l)) > SERR);
/*   fprintf(stderr, ", %f", mtse / (l * l) ); */
    return Nsamples;
}

/* ... */

static void EMalgorithm(struct cMatrix *M, struct cCorpus *C1, struct cCorpus *C2, 
#ifdef DEBUG
                        struct cWords *W1, struct cWords *W2,  
#endif
                        int step)
{
    double p[MAXLEN][MAXLEN], pi[MAXLEN], pj[MAXLEN], pN; /* probabilities */
#ifdef DEBUG
    double nij;
#endif
    long k, Nsamples;
    nat_uint32_t length;
    CorpusCell *s1, *s2;
    nat_uint32_t r, c, l;
    nat_uint32_t st1[MAXLEN + 1];
    nat_uint32_t st2[MAXLEN + 1];
    nat_uint32_t e[MAXLEN][MAXLEN];          /* solution */
    int M1, M2;

    if (step % 2) { 
        M1 = MATRIX_1;
        M2 = MATRIX_2;
    } else {
        M1 = MATRIX_2;
        M2 = MATRIX_1;
    }
    fprintf(stderr, "Step %d of the EM-algorithm:      ", step);
#ifdef DEBUG
    printf("\n\n");
#endif
    ClearMatrix(M, M2);
    k = 0;
    length = corpus_sentences_nr(C1);
    s1 = corpus_first_sentence(C1);
    s2 = corpus_first_sentence(C2);

    while (s1 != NULL && s2 != NULL) {
#ifdef DEBUG
	printf("--- TEST %d: ---\n", ++k);
	printSentence(s1, W1);
	printSentence(s2, W2);
	printf("---\n");
#else
	fprintf(stderr, "\b\b\b\b\b%4.1f%%", (double) (k++) * 99.9f / (double) length); 
#endif
	l = max(corpus_sentence_length(s1),
		corpus_sentence_length(s2));
	if (l <= MAXLEN) {
	    SortMatrix(s1, st1, l);
	    SortMatrix(s2, st2, l);
	    if (GetPartialMatrix(M, M1, st1, st2, &p[0][0], MAXLEN))
		report_error("EMalgorithm: GetPartialMatrix");
	    pN = MarginalProbs(&p[0][0], pi, pj, l, l);
	    memset(&e[0][0], 0, MAXLEN*MAXLEN * sizeof(e[0][0]));
	    Nsamples = MonteCarlo(&e[0][0], &p[0][0], pi, pN, l);
#ifdef DEBUG
	    {
		nat_uint32_t i,j;
		r = 0;
		while (r < l) {
		    c = 0;
		    while (c < l) {
			nij = 0.0f;
			i = r;
			while (st1[i] == st1[r]) {
			    j = c;
			    while (st2[j] == st2[c]) {
				nij += (double) e[i][j] / (double) Nsamples;
				j++;
			    }
			    i++;
			}
			while (nij >= 0.5) {
			    if (st1[r] == 1) printf("([null], ");
			    else printf("(%s,", GiveString(W1, st1[r]));
			    if (st2[c] == 1) printf("[null])");
			    else printf("%s)", GiveString(W2, st2[c]));
			    if (nij < 0.5) printf("?\n");
			    else printf("\n");
			    nij--;
			}
			c = j;       
		    }
		    r = i;
		}
		printf("\n");
	    }
#else
	    for (r = 0; r < l; r++)
		for (c = 0; c < l; c++) {
		    if (IncValue(M, M2, (double) e[r][c] / (double) Nsamples, st1[r], st2[c]))
			report_error("EMalgorithm: IncValue failed");
		}
#endif
	}
	s1 = corpus_next_sentence(C1);
	s2 = corpus_next_sentence(C2);
    }
    printf("\b\b\b\b\bdone \n");
}




/**
 * @brief The main function 
 *
 * @todo Document this
 */
int main(int argc, char **argv)
{
    Corpus *Corpus1, *Corpus2;
    Matrix* Matrices;
    double t;
    int Nsteps, step;
/* randomtest();*/
    if (argc != 6)
	report_error("Usage: sampleA nsteps corpusfile1 corpusfile2 dictfilein dictfileout");

#ifdef DEBUG
    LoadWords(&W1, "Lang1.lex");
    LoadWords(&W2, "Lang2.lex");
#endif

    Nsteps = atoi(argv[1]);
    if (Nsteps < 1 || Nsteps > 25)
	report_error("Number of steps out of range");

    Corpus1 = corpus_new();
    Corpus2 = corpus_new();

    if (corpus_load(Corpus1, argv[2])) report_error("LoadCorpus");
    if (corpus_load(Corpus2, argv[3])) report_error("LoadCorpus");
    if (!(Matrices = LoadMatrix(argv[4]))) report_error("LoadMatrix");

    printf("\nEM-algorithm model A, Monte Carlo sampling\n");

    printf("Initial matrix total:%9.2f\n", MatrixTotal(Matrices, MATRIX_1));
    printf("Initial memory used:%10.1f kb\n", (double) BytesInUse(Matrices) / 1024.0f);
    step = 1;
    while (step <= Nsteps) {
	EMalgorithm(Matrices, Corpus1, Corpus2, 
#ifdef DEBUG
		    &W1, &W2,   
#endif
		    step);
	step++;
	t = CompareMatrices(Matrices);
	printf("mean diff.: %15.6f\n", t);
	if (step % 2) t = MatrixTotal(Matrices, MATRIX_1);
	else t = MatrixTotal(Matrices, MATRIX_2);
	printf("Matrix total:%9.2f\n", t);
	printf("Memory used:%9.1f kb\n", (double) BytesInUse(Matrices) / 1024.0f);
    }

#ifndef DEBUG
    if (Nsteps % 2)
	CopyMatrix(Matrices, MATRIX_1);
    if (SaveMatrix(Matrices, argv[5])) report_error("SaveMatrix");
#endif 

    corpus_free(Corpus1);
    corpus_free(Corpus2);
    FreeMatrix(Matrices);

    return 0;
}
