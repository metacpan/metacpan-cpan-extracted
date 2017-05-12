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


#include <EXTERN.h>
#include <perl.h>
#include <stdio.h>
#include <stdlib.h>
#include <zlib.h>
#include <string.h>

#include <NATools/words.h>
#include "dictionary.h"
#include "unicode.h"
#include "natdict.h"

/**
 * @file
 * @brief Based on lexicon files and temporary dictionaries, creates a
 * NATools dictionary
 */

static nat_uint32_t put_string(wchar_t *str, wchar_t *orig,
                               nat_uint32_t ptr, nat_uint32_t size) {
    nat_uint32_t i = 0;
    while(orig[i]) {
	str[ptr++] = orig[i++];
	if (ptr == size) {
	    str = g_realloc(str, size + 32000);
	    g_message("** REALLOC **");
	}
    }
    str[ptr++] = '\0';
    return ptr;
}

static nat_uint32_t tree_to_array(nat_uint32_t nrwords, wchar_t *str, 
                                  NATCell *cells, WordLstNode *tree, nat_uint32_t ptr,
                                  nat_uint32_t size, nat_uint32_t *cellptr, nat_uint32_t *tab) {
    nat_uint32_t offset = ptr;
    if (tree->left)
	offset = tree_to_array(nrwords, str, cells, tree->left, offset, size, cellptr, tab);

    cells[*cellptr].offset = offset;
    cells[*cellptr].count = tree->count;
    cells[*cellptr].id = *cellptr;

#ifdef DEBUG
    if (tree->id >= nrwords || *cellptr >= nrwords) 
	g_message("*** Words/id/cellptr (%u,%u,%u) ***", nrwords, tree->id, *cellptr);
#endif
    tab[tree->id] = *cellptr;

    ++*cellptr;

    offset = put_string(str, tree->string, offset, size);

    if (tree->right)
	offset = tree_to_array(nrwords, str, cells, tree->right, offset, size, cellptr, tab);
    return offset;
}

static int save(char *outfile,
		char *lang1, char *lang2,
		char *dicfile1, nat_uint32_t *tab1,
		char *dicfile2, nat_uint32_t *tab2,
		wchar_t *string1, nat_uint32_t ptr1, NATCell *cells1, nat_uint32_t size1,
		wchar_t *string2, nat_uint32_t ptr2, NATCell *cells2, nat_uint32_t size2) {
    FILE *out = NULL;
    nat_int_t s;

    Dictionary *dic;

    out = gzopen(outfile, "wb");
    if (!out) return 0;

    // Say this is a NATDict
    gzprintf(out,"!NATDict");

    s = strlen(lang1)+1;
    gzwrite(out, &s, sizeof(nat_int_t));
    gzwrite(out, lang1, s);

    s = strlen(lang2)+1;
    gzwrite(out, &s, sizeof(nat_int_t));
    gzwrite(out, lang2, s);

    // Save first lexicon
    g_message("** Saving source Lexicon **");
    gzwrite(out, &ptr1, sizeof(nat_uint32_t));
    gzwrite(out, string1, ptr1);
    gzwrite(out, &size1, sizeof(nat_uint32_t));
    g_message("\tSize: %u", size1);
    gzwrite(out, cells1, sizeof(NATCell) * size1);

    // Save second lexicon
    g_message("** Saving target Lexicon **");
    gzwrite(out, &ptr2, sizeof(nat_uint32_t));
    gzwrite(out, string2, ptr2);
    gzwrite(out, &size2, sizeof(nat_uint32_t));
    g_message("\tSize: %u", size2);
    gzwrite(out, cells2, sizeof(NATCell)* size2);

    // Load first dictionary
    g_message("** Source -> Target dictionary **");
    g_message("\tLoading...");
    dic = dictionary_open(dicfile1);

    dictionary_remap(tab1, tab2, dic);

    g_message("\tSaving...");
    gzwrite(out, &dic->size, sizeof(nat_uint32_t));
    gzwrite(out, dic->pairs, sizeof(DicPair)*MAXENTRY*(dic->size+1));
    gzwrite(out, dic->occurs, sizeof(nat_uint32_t)*(dic->size+1));
    dictionary_free(dic);

    // Load second dictionary
    g_message("** Target -> Source dictionary **");
    g_message("\tLoading...");
    dic = dictionary_open(dicfile2);

    dictionary_remap(tab2, tab1, dic);

    g_message("\tSaving...");
    gzwrite(out, &dic->size, sizeof(nat_uint32_t));
    gzwrite(out, dic->pairs, sizeof(DicPair)*MAXENTRY*(dic->size+1));
    gzwrite(out, dic->occurs, sizeof(nat_uint32_t)*(dic->size+1));
    dictionary_free(dic);

    // Close the file
    g_message("** DONE **");
    gzclose(out);

    return 1;
}

static void go(char *lang1, char *lang2,
               char *lexfile1, char *dicfile1,
               char *lexfile2, char *dicfile2,
               char *outfile) {
    Words *lex1, *lex2;
    wchar_t *string1 = NULL;
    wchar_t *string2 = NULL;
    nat_uint32_t ptr1 = 0;
    nat_uint32_t ptr2 = 0;
    nat_uint32_t size1, size2;
    NATCell *cells1 = NULL;
    NATCell *cells2 = NULL;
    nat_uint32_t cellptr1 = 0;
    nat_uint32_t cellptr2 = 0;
    nat_uint32_t *tab1 = NULL;
    nat_uint32_t *tab2 = NULL;

    /* ---- First ------------------------------- */
    lex1 = words_quick_load(lexfile1);
    if (!lex1) { fprintf(stderr, "Error loading lexicon 1\n"); exit(1); }

    size1 = 11 * lex1->count;

    string1 = g_new0(wchar_t, size1);
    if (!string1) { fprintf(stderr, "Error allocating string1\n"); exit(1); }

    cells1 = g_new0(NATCell, lex1->count + 1);
    if (!cells1) { fprintf(stderr, "Error allocating cells1\n"); exit(1); }

    tab1 = g_new0(nat_uint32_t, lex1->count + 1);
    if (!tab1) { fprintf(stderr, "Error allocating tab1\n"); exit(1); }

    tab1[0] = tab1[1] = lex1->count-1;
    ptr1 = tree_to_array(lex1->count,string1, cells1, lex1->tree, ptr1, size1, &cellptr1, tab1);
    
    cells1[cellptr1].offset = ptr1;
    cells1[cellptr1].count = 0;
    cells1[cellptr1].id = cellptr1;
    cellptr1++;

    g_message("** Preparing source Lexicon **");
    g_message("\tPtr is at %u and original size was %u", ptr1, size1);
    g_message("\tOffset on the array is %u", cellptr1);
    g_message("\tNULL is pointing to %u", tab1[0]);

    /* ---- Second ------------------------------ */
    lex2 = words_quick_load(lexfile2);
    if (!lex2) report_error("Error loading lexicon 2\n");

    size2 = 11*lex2->count;

    string2 = g_new0(wchar_t, size2);
    if (!string2) report_error("Error allocating string2\n");

    cells2 = g_new0(NATCell, lex2->count+1);
    if (!cells2) report_error("Error allocating cells2\n");

    tab2 = g_new0(nat_uint32_t, lex2->count+1);
    if (!tab2) report_error("Error allocating tab2\n");

    tab2[0] = tab2[1] = lex2->count-1;
    ptr2 = tree_to_array(lex2->count,string2, cells2, lex2->tree, ptr2, size2, &cellptr2, tab2);

    cells2[cellptr2].offset = ptr2;
    cells2[cellptr2].count = 0;
    cells2[cellptr2].id = cellptr2;
    cellptr2++;

    g_message("** Preparing target Lexicon **");
    g_message("\tPtr is at %u and original size was %u", ptr2, size2);
    g_message("\tOffset on the array is %u", cellptr2);
    g_message("\tNULL is pointing to %u", tab2[0]);

    save(outfile,
	 lang1, lang2, 
	 dicfile1, tab1, dicfile2, tab2,
	 string1, ptr1, cells1, cellptr1,
	 string2, ptr2, cells2, cellptr2);   

/*    save(outfile, lang1, lang2, 
	 dicfile1, tab1, dicfile2, tab2,
	 string1, ptr1, cells1, lex1->count,
	 string2, ptr2, cells2, lex2->count);   */


    words_free(lex1);
    words_free(lex2);
}

/**
 * @brief Main Program
 *
 * @todo Document all this program
 */
int main(int argc, char *argv[]) {

    init_locale();
    
    if (argc != 8) {
	printf("mkdict <lang1> <lang2> <lex1> <dic1> <lex2> <dic2> <outfile>\n");
	return 1;
    } else {
	go(argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7]);
	return 0;
    }
}



