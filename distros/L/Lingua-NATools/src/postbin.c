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


/**
 * @file
 * @brief Post processing unit to output a binary dictionary
 */

#include <stdlib.h>
#include <stdio.h>
#include "standard.h"
#include <NATools/words.h>
#include "tempdict.h"
#include "dictionary.h"
#include "partials.h"

/**
 * @brief Lower threshold to add in the dictionary
 *
 * @todo Fix-me. I think I'm wrong.
 */
#define MINTOT 0.0f

static void setEntry(Dictionary* dic, nat_uint32_t word, 
		     Words *WL,
		     nat_uint32_t c[MAXENTRY], float *f, nat_uint32_t max, float total)
{
    nat_uint32_t j;
    float v;

    for(j = 0; j < max; j++) {
	v = f[j]/total;
	if (c[j] && v > 0.005f) {
	    dic = dictionary_set_id(dic, word, j, c[j]);
	    dic = dictionary_set_val(dic, word, j, v);
	}
    }
}

static void saveDicts(char *f1, char* f2, struct cMat2 *M, 
		      Words *WL1, Words *WL2,
		      PartialCounts *partials1, 
		      PartialCounts *partials2)
{
    float f[MAXENTRY], total;
    nat_uint32_t r, N, c[MAXENTRY];
    nat_uint32_t index;
    // unused -- WordLstNode *node;
    Dictionary* dic;
    
    N = words_size(WL1);

    dic = dictionary_new(N);

    index = 2;
    for (r = 2; r <= partials1->last; r++) {   
	total = tempdict_getrowmax2(M, index, c, f, MAXENTRY);
	if (total > (float) MINTOT) setEntry(dic, index, WL2, c, f, MAXENTRY, total);

	/* TO CHANGE */
	/* node = words_get_full_by_id(W1, index); */
	dic = dictionary_set_occ(dic, index, partials1->buffer[index]);

	index++;
    }
    total = tempdict_getrowmax2(M, 1, c, f, MAXENTRY);
    setEntry(dic, 1, WL2, c, f, MAXENTRY, total); /*  */

    if (!dictionary_save(dic, f1))
	report_error("Cannot save dictionary 2");

    dictionary_free(dic);


    /*  */

    /* SECOND DICTIONARY */

    N = words_size(WL2);

    dic = dictionary_new(N);

    index = 2;
    for(r = 2; r <= partials2->last; r++) {   
	total = tempdict_getcolumnmax2(M, index, c, f, MAXENTRY);
	if (total > (float) MINTOT) setEntry(dic, index, WL1, c, f, MAXENTRY, total);

	/* TO CHANGE */
	/* node = words_get_full_by_id(W2, index); */
	dic = dictionary_set_occ(dic, index, partials2->buffer[index]);
	index++;
    }   
    total = tempdict_getcolumnmax2(M, 1, c, f, MAXENTRY);   
    setEntry(dic, 1, WL1, c, f, MAXENTRY, total); /*  */

    if (!dictionary_save(dic, f2))
	report_error("Cannot save dictionary 2");

    dictionary_free(dic);
}

/**
 * @brief Main program
 *
 * @todo Document this
 */
int main(int argc, char **argv)
{
    struct cMat2 Dictionary;
    Words *Words1, *Words2;
    PartialCounts *partials1 = NULL, *partials2 = NULL;

    if (argc != 8)
	report_error("Usage: post dictfile partials1 partials2 lexiconfile1 lexiconfile2 out1 out2");
    
    printf("\n");
    printf("Loading %s...\n", argv[1]);
    if (tempdict_loadmatrix2(&Dictionary, argv[1])) 
	report_error("load dictionary");

    printf("Loading %s...\n", argv[2]);
    partials1 = PartialCountsLoad(argv[2]);
    if (!partials1) report_error("load partials 1");

    printf("Loading %s...\n", argv[3]);
    partials2 = PartialCountsLoad(argv[3]);
    if (!partials2) report_error("load partials 2");

    printf("Loading %s...\n", argv[4]);
    if (!(Words1 = words_load(argv[4]))) report_error("load strings 1");

    printf("Loading %s...\n", argv[5]);
    if (!(Words2 = words_load(argv[5]))) report_error("load strings 2");

    printf("Writing dictionaries %s,%s...\n\n", argv[6], argv[7]);
    saveDicts(argv[6], argv[7], &Dictionary, 
	      Words1, Words2, 
	      partials1, partials2);

    printf("Freeing data structures\n");
    tempdict_freematrix2(&Dictionary);
    words_free(Words1);
    words_free(Words2);
    
    return 0;
}

