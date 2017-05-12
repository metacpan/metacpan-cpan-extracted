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
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "standard.h"
#include <NATools/corpus.h>
#include "matrix.h"

/**
 * @file
 * @brief Implementation of the IPFP EM-Algorithm variant
 */

/**
 * @brief Number of steps for IPFP algorithm
 */
#define NSTEPS 500

#if 0
/* not being used */
static void printEntropy(struct cMatrix *M, int M1, int empty)
{ 
    double h, hx, hy, hygx, hxgy, uygx, uxgy, uxy;
    if (empty) {
	h = log(GetNRow(M) * GetNColumn(M));
	hx = log(GetNRow(M));
	hy = log(GetNColumn(M));
	hygx = h - hx;
	hxgy = h - hy;
	uygx = (hy - hygx) / hy;
	uxgy = (hx - hxgy) / hx;
	uxy = 2.0f * (hx + hy - h) / (hx + hy);
    }
    else
	MatrixEntropy(M, M1, &h, &hx, &hy, &hygx, &hxgy, &uygx, &uxgy, &uxy);
    fprintf(stderr, "  Entropy of x variable:   H(x)   = %f\n", hx);
    fprintf(stderr, "  Entropy of y variable:   H(y)   = %f\n", hy);
    fprintf(stderr, "  Entropy of y given x:    H(y|x) = %f\n", hygx);
    fprintf(stderr, "  Entropy of x given y:    H(x|y) = %f\n", hxgy);
    fprintf(stderr, "  Table entropy:           H(x,y) = %f\n\n", h);

    fprintf(stderr, "  Dependency of y given x: U(y|x) = %f\n", uygx);
    fprintf(stderr, "  Dependency of x given y: U(x|y) = %f\n", uxgy);
    fprintf(stderr, "  Symmetrical dependency:  U(x,y) = %f\n", uxy);
}
#endif


void show_help () {
    printf("Usage:\n"
           "  nat-ipfp [-q] nsteps crpFile1 crpFile2 matIn matOut\n");
    printf("Supported options:\n"
           "  -h shows this help message and exits\n"
           "  -V shows "PACKAGE" version and exits\n"
           "  -q activates quiet mode\n"
           "Check nat-ipfp manpage for details.\n");
}


/* EM algorithm */

static nat_uint32_t MarginalCounts(CorpusCell *s, nat_uint32_t *st,
			      nat_uint32_t *n, nat_uint32_t l,
			      nat_uint32_t nullwrd)
{
    nat_uint32_t i, j, lt;
    i = 0;
    lt = 0;
    while (s[i].word) {
	j = 0;
	while (j < lt && st[j] < s[i].word) j++;
	if (j == lt) {
	    n[lt] = 1;
	    st[lt++] = s[i].word;
	}
	else {
	    if (st[j] == s[i].word)
		n[j] += 1;
	    else {
		memmove(st + j + 1, st + j, sizeof(nat_uint32_t) * (lt - j));
		memmove( n + j + 1,  n + j, sizeof(nat_uint32_t) * (lt - j));
		n[j] = 1;
		st[j] = s[i].word;
		lt++;
	    }
	}
	i++;
    }
    if (i < l) {
	memmove(st + 1, st, sizeof(nat_uint32_t) * lt);
	memmove( n + 1, n,  sizeof(nat_uint32_t) * lt);
	st[0] = nullwrd;
	n[0] = l - i;
	lt++;
    }
    st[lt] = 0;
    n[lt] = 0;
    return lt;
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

static void IPFP(double  *p, double  *pi, double  *pj,
		 nat_uint32_t *ni, nat_uint32_t *nj, nat_uint32_t  lr, nat_uint32_t  lc)
{
    nat_boolean_t ready;
    nat_uint32_t r, c;
    nat_uint32_t steps = NSTEPS;

    ready = FALSE;

    while (!ready && steps) {
	steps --;
	for (c = 0; c < lc; c++) pj[c] = 0;

	for (r = 0; r < lr; r++) {
	    for (c = 0; c < lc; c++) {
		p[r * MAXLEN + c] *= ((double) ni[r] / pi[r]);
		pj[c] += p[r * MAXLEN + c];
	    }   
	}

	for (r = 0; r < lr; r++) pi[r] = 0;

	for (c = 0; c < lc; c++) {
	    for (r = 0; r < lr; r++) {
		p[r * MAXLEN + c] *= ((double) nj[c] / pj[c]);
		pi[r] += p[r * MAXLEN + c];              
	    }
	}
	ready = TRUE;
	r = 0;
	while (ready && r < lr) {
	    double x;
	    if ((x = fabs((double)(pi[r] - ni[r]))) > 0.01f) {
		ready = FALSE;
	    }
	    r++;
	}
    }
}

static double OddsRatio(double pij, double pi, double pj, double p)
{
    double pr;

    pr = (pi-pij)*(pj-pij);
    if (pr == 0.0f)
	return (double) 1.0E17f;
    else {
	pr = (pij*(p-pi-pj+pij)) / pr;
	return pr;  
    }
}

static void EMalgorithm(nat_boolean_t quiet, Matrix *M, Corpus *C1, Corpus *C2, int step, int last)
{
    MatrixVal M1, M2;
    double *p  = g_new(double, MAXLEN * MAXLEN);
    double *pi = g_new(double, MAXLEN);
    double *pj = g_new(double, MAXLEN);
    double pN, nij, DUMMY;
    double *e  = g_new(double, MAXLEN*MAXLEN);
    double *ei = g_new(double, MAXLEN);
    double *ej = g_new(double, MAXLEN);
    nat_uint32_t k, length;
    CorpusCell *s1, *s2;
    nat_uint32_t r, c, lr, lc, l;
    nat_uint32_t *st1 = g_new(nat_uint32_t, MAXLEN + 1);
    nat_uint32_t *st2 = g_new(nat_uint32_t, MAXLEN + 1);
    nat_uint32_t *ni  = g_new(nat_uint32_t, MAXLEN + 1);
    nat_uint32_t *nj  = g_new(nat_uint32_t, MAXLEN + 1);

    if (step % 2) {
        M1 = MATRIX_1;
        M2 = MATRIX_2; 
    } else {
        M1 = MATRIX_2;
        M2 = MATRIX_1;
    }

    if (!quiet) fprintf(stderr, "Step %d of the EM-algorithm:      ", step);

    ClearMatrix(M, M2);
    k = 0;
    length = corpus_sentences_nr(C1);
    s1 = corpus_first_sentence(C1);
    s2 = corpus_first_sentence(C2);
    while (s1 != NULL && s2 != NULL) {
	if (!quiet) fprintf(stderr, "\b\b\b\b\b%4.1f%%", (double) (k++) * 99.9f / (double) length);
	l = max(corpus_sentence_length(s1),
		corpus_sentence_length(s2));
	if (l <= MAXLEN) {
	    lr = MarginalCounts(s1, st1, ni, l, 1);
	    lc = MarginalCounts(s2, st2, nj, l, 1);
	    if (GetPartialMatrix(M, M1, st1, st2, p, MAXLEN))
		report_error("EMalgorithm: GetPartialMatrix");
	    pN = MarginalProbs(p, pi, pj, lr, lc);
	    for (c = 0; c < lc; c++) 
		ej[c] = 0; 
	    for (r = 0; r < lr; r++) {
		ei[r] = 0;
		for (c = 0; c < lc; c++) {
		    nij = OddsRatio(p[r*MAXLEN + c], pi[r], pj[c], pN);
		    e[r * MAXLEN + c] = nij;
		    ei[r] += nij;
		    ej[c] += nij;
		}
	    }
	    IPFP(e, ei, ej, ni, nj, lr, lc);
	    if (last) {
		if (st1[0] == 1) {
		    for (c = 0; c < lc; c++) {
			for (r = 1; r < lr; r++)
			    e[r * MAXLEN + c] += e[0*MAXLEN + c] / (lr - 1);
			e[0 * MAXLEN + c] = 0.0f;
		    }
		}
		if (st2[0] == 1) {
		    for (r = 0; r < lr; r++) {
			for (c = 1; c < lc; c++)
			    e[r * MAXLEN + c] += e[r*MAXLEN + 0] / (lc - 1);
			e[r*MAXLEN + 0] = 0.0f;
		    }
		}
	    }
	    DUMMY = 0.0f;
	    for (r = 0; r < lr; r++) {
		for (c = 0; c < lc; c++) {
		    nij = e[r * MAXLEN + c];
		    if (IncValue(M, M2, nij, st1[r], st2[c]))
			report_error("EMalgorithm: IncValue failed");
		    DUMMY += nij;  
		}
	    }
	}
	s1 = corpus_next_sentence(C1);
	s2 = corpus_next_sentence(C2);
    }
    if (!quiet) printf("\b\b\b\b\bdone \n");
    
    g_free(p);
    g_free(pi);
    g_free(pj);
    g_free(e);
    g_free(ei);
    g_free(ej);
    g_free(st1);
    g_free(st2);
    g_free(ni);
    g_free(nj);
}




/**
 * @brief The main function 
 *
 * @todo Document this
 */
int main(int argc, char **argv)
{
    Corpus *Corpus1, *Corpus2;
    Matrix *Matrices;

    double t;
    int Nsteps, step;

    // extern char *optarg;
    extern int optind;
    int c;

    nat_boolean_t quiet = FALSE;
    
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
    
    if (argc != optind + 5) {
	printf("nat-ipfp: wrong number of arguments\n");
        show_help();
        return 1;
    }

    /* check number of steps range */
    Nsteps = atoi(argv[optind + 0]);
    if (Nsteps < 1 || Nsteps > 25) report_error("Number of steps out of range");

    /* Alloc first corpus structure */
    Corpus1 = corpus_new();
    if (!Corpus1) report_error("Can't alloc Corpus 1 structure");
    if (!quiet) printf("Loading Corpus file 1\n");
    if (corpus_load(Corpus1, argv[optind + 1])) report_error("Can't read corpus 1");

    /* Alloc second corpus structure */
    Corpus2 = corpus_new();
    if (!Corpus2) report_error("Can't alloc Corpus 2 structure");
    if (!quiet) printf("Loading Corpus file 2\n");
    if (corpus_load(Corpus2, argv[optind + 2])) report_error("Can't read corpus 2");

    /* Load matrix from disk */
    if (!quiet) printf("Loading matrix. This can take a while\n");
    Matrices = LoadMatrix(argv[optind + 3]);
    if (!Matrices) report_error("Can't load matrix");

    /* Say what we are doing :-) */
    printf("EM-algorithm, model A, Iterative Proportional Fitting\n\n");

    /* Show statistics */
    if (!quiet) {
        printf("Initial matrix total:%9.2f\n", MatrixTotal(Matrices, MATRIX_1));
        printf("Initial memory used:%10.1f kb\n\n", (double) BytesInUse(Matrices) / 1024.0f);
    }

    step = 1;
    while (step <= Nsteps) {
	EMalgorithm(quiet, Matrices, Corpus1, Corpus2, step, (!NULLWORD && step == Nsteps));
	step++;
	t = CompareMatrices(Matrices);
	if (!quiet) printf("Matrix mean difference: %f\n", t);
	
	if (step % 2) t = MatrixTotal(Matrices, MATRIX_1);
	else          t = MatrixTotal(Matrices, MATRIX_2);

        if (!quiet) {
            printf("Matrix total:%9.2f\n", t);
            printf("Memory used:%10.1f kb\n\n", (double) BytesInUse(Matrices) / 1024.0f);
        }
    }

    if (Nsteps % 2) CopyMatrix(Matrices, MATRIX_1);

    if (SaveMatrix(Matrices, argv[optind + 4])) report_error("SaveMatrix");

    /* Free structures */
    corpus_free(Corpus1);
    corpus_free(Corpus2);

    FreeMatrix(Matrices);

    return 0;
}
