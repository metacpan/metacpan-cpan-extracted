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
#include <stdio.h>
#include <zlib.h>
#include <string.h>
#include <math.h>
#include "dictionary.h"


/**
 * @file
 * @brief Code file for temporary dictionary data structure
 */



static int cmp(const void* pair1, const void* pair2) 
{
    /* Here we can't just subtract the values. They are floats, return
     * value will be between 0 and 1, that trunated to int will
     * be... 0! that together with qsort returns a random list.    */
    return (((DicPair*)pair1)->val > ((DicPair*)pair2)->val) ? -1 : 1;
}

/**
 * @brief Saves a dictionary using a filename
 *
 * @param dic the Dictionary object to be saved
 * @param name name of the file to be created
 *
 * @return 0 on error
 */
int dictionary_save(Dictionary *dic, const char *name)
{
    FILE *gzf;

    gzf = gzopen(name, "wb");
    if (!gzf) report_error("error opening file %s for writing.\n", name);

    return dictionary_save_fh(gzf, dic);
}

/**
 * @brief Saves a dictionary using a gzfile handle
 *
 * @param gzf zlib file handle where to save the dictioknary
 * @param dic the Dictionary to be saved
 *
 * @return 0 on error
 */
int dictionary_save_fh(FILE* gzf, Dictionary *dic)
{
    if (gzwrite(gzf, &dic->size, sizeof(nat_uint32_t)) != sizeof(nat_uint32_t)) return 0;
    if (gzwrite(gzf, dic->pairs, sizeof(DicPair)*MAXENTRY*(dic->size+1)) != 
	sizeof(DicPair)*MAXENTRY*(dic->size+1)) return 0;
    if (gzwrite(gzf, dic->occurs, sizeof(nat_uint32_t)*(dic->size+1)) != 
	sizeof(nat_uint32_t)*(dic->size+1)) return 0;
    gzclose(gzf);
    return 1;
}

/**
 * @brief Opens a dictionary file and returns the respective Dictionary object
 *
 * @param name name of the file containing the dictionary
 * @return the Dictionary object or NULL in case of error.
 */
Dictionary* dictionary_open(const char *name) 
{
    Dictionary *dic;
    FILE *gzf;
    gzf = gzopen(name, "rb");
    if (!gzf) report_error("error opening file %s for reading.\n", name);

    dic = dictionary_load(gzf);

    gzclose(gzf);
    return dic;
}

/**
 * @brief Loads a dictionary file from a zlib file handle
 *
 * @param gzf the zlib file handle to be used to read the Dictionary
 * @return the readed Dictionary object
 */
Dictionary *dictionary_load(FILE* gzf) 
{
    Dictionary *dic;
    nat_uint32_t size;
    if (gzread(gzf, &size, sizeof(nat_uint32_t)) != sizeof(nat_uint32_t)) return NULL;
    dic = dictionary_new(size);
    if (!dic) return NULL;
    if (gzread(gzf, dic->pairs, sizeof(DicPair)*MAXENTRY*(dic->size+1))	!=
	sizeof(DicPair)*MAXENTRY*(dic->size+1)) {
	dictionary_free(dic);
	return NULL;
    }
    if (gzread(gzf, dic->occurs, sizeof(nat_uint32_t)*(dic->size+1)) !=
	sizeof(nat_uint32_t)*(dic->size+1)) {
	dictionary_free(dic);
	return NULL;
    }
    return dic;
}
    
    
/**
 * @brief Gets a translation word id based on the source word id and
 * the translation offset
 *
 * @param dic the Dictionary to be consulted
 * @param wid the source word id to be searched
 * @param offset the offset of the translation (translation number). Note that
 *   this value will be less than MAXENTRY
 * @return the translation word id
 */
nat_uint32_t dictionary_get_id(Dictionary* dic, nat_uint32_t wid, int offset)  
{
    if (wid > dic->size || offset >= MAXENTRY) return 0;
    return DIC_POS(dic->pairs, wid, offset).id;
}


/**
 * @brief Gets a translation word probability based on the source id
 * and the translation offset
 *
 * @param dic the Dictionary to be consulted
 * @param wid the source word id to be searched
 * @param offset the offset of the translation (translation number). Note that
 *   this value needs to be less than MAXENTRY
 * @return the translation probability
 */
float dictionary_get_val(Dictionary* dic, nat_uint32_t wid, int offset) 
{
    if (wid > dic->size || offset >= MAXENTRY) return 0;
    return DIC_POS(dic->pairs, wid, offset).val;
}


    
/**
 * @brief Sets a translation word id based on the source word id and
 * the translation offset
 *
 * @bug Does not check offset or wid
 *
 * @param dic the Dictionary to be changed
 * @param wid the source word id to be changed
 * @param offset the offset of the translation (translation number). Note that
 *   this value will be less than MAXENTRY
 * @param id the translation word id to be set
 * @return the changed Dictionary
 */
Dictionary *dictionary_set_id(Dictionary* dic, nat_uint32_t wid, int offset, nat_uint32_t id) 
{
    DIC_POS(dic->pairs, wid, offset).id = id;
    return dic;
}


/**
 * @brief Sets a translation probability based on the source word id and
 * the translation offset
 *
 * @bug Does not check offset or wid
 *
 * @param dic the Dictionary to be changed
 * @param wid the source word id to be changed
 * @param offset the offset of the translation (translation number). Note that
 *   this value will be less than MAXENTRY
 * @param val translation to be set
 * @return the changed Dictionary
 */
Dictionary *dictionary_set_val(Dictionary* dic, nat_uint32_t wid, int offset, float val) 
{
    DIC_POS(dic->pairs, wid, offset).val = val;
    return dic;
}


/**
 * @brief Sets the occurrence count for a word based on its word id
 *
 * @bug Does not check wid
 *
 * @param dic Dictionary to be changed
 * @param wid word id of word to be changed
 * @param count new word occurrence count
 * @return the changed Dictionary
 */
Dictionary *dictionary_set_occ(Dictionary* dic, nat_uint32_t wid, nat_uint32_t count) 
{
    dic->occurs[wid] = count;
    return dic;
}


/**
 * @brief Gets the occurrence count for a word based on its word id
 *
 * @bug Does not check wid
 *
 * @param dic Dictionary to be consulted
 * @param wid word id of word to be searched
 * @return the word occurrence count
 */
nat_uint32_t dictionary_get_occ(Dictionary* dic, nat_uint32_t wid) 
{
    if (wid > dic->size) return 0;
    return dic->occurs[wid];
}


/**
 * @brief Gets the number of entries in a dictionary
 *
 * @param dic the Dictionary to get the size of
 * @return the dictionary size
 */
nat_uint32_t dictionary_get_size(Dictionary* dic) 
{
    return dic->size;
}


/**
 * @brief Allocates a new dictionary structure
 *
 * @param size the number of entries in the dictionary to be created
 *
 * @return the newly created dictionary
 */
Dictionary *dictionary_new(nat_uint32_t size) 
{
    Dictionary *new;

    new = (Dictionary*)malloc(sizeof(Dictionary));
    if (!new) return new;

    new->pairs=(DicPair*)malloc(sizeof(DicPair)*MAXENTRY*(size+1));
    if (!new->pairs) {
	free(new);
	return NULL;
    }
    memset(new->pairs, 0, sizeof(DicPair)*MAXENTRY*(size+1));

    new->occurs = (nat_uint32_t*)malloc(sizeof(nat_uint32_t)*MAXENTRY*(size+1));
    if (!new->occurs) {
	free(new->pairs);
	free(new);
	return NULL;
    }

    memset(new->occurs, 0, sizeof(nat_uint32_t)*MAXENTRY*(size+1));
    new->size = size;

    return new;
}

/**
 * @brief Frees a dictionary structure
 *
 * @param dic the dictionary to be freed
 */
void dictionary_free(Dictionary *dic) 
{
    free(dic->occurs);
    free(dic->pairs);
    free(dic);
}


/**
 * @brief Adds two dictionaries
 *
 * @param dic1 First dictionary
 * @param dic2 Second dictionary
 * @return the new dictionary 
 */
Dictionary* dictionary_add(Dictionary *dic1, Dictionary *dic2) 
{
    Dictionary *new;
    int j,k;
    nat_uint32_t size1 = 0, size2 = 0;
    nat_uint32_t i, count, id;
    DicPair buffer1[MAXENTRY * 2], buffer2[MAXENTRY * 2];
    nat_uint32_t new_size = dic1->size > dic2->size ? dic1->size : dic2->size;
    float factor1, factor2;

    for (i = 0; i < new_size; i++) {
	size1 +=  dictionary_get_occ(dic1, i);
	size2 +=  dictionary_get_occ(dic2, i);
    }

    factor1 = (size1 <= size2) ? 1 : (1 + log10f(size1/size2));
    factor2 = (size1 >= size2) ? 1 : (1 + log10f(size2/size1));

    new = dictionary_new(new_size);
    for (i = 0; i < new_size; i++) {
	memset(buffer1, 0, sizeof(DicPair)*MAXENTRY*2);
	memset(buffer2, 0, sizeof(DicPair)*MAXENTRY*2);

	for (j = 0; j < MAXENTRY; j++) {
	    buffer1[j].id  = dictionary_get_id(dic1, i, j);
	    buffer1[j].val = dictionary_get_val(dic1, i, j);
	}

	for (j = 0; j < MAXENTRY; j++) {
	    id = dictionary_get_id(dic2, i, j);
	    for (k = 0; k < MAXENTRY; k++) {
		if (id == buffer1[k].id) {
		    buffer2[k].id = id;
		    buffer2[k].val = dictionary_get_val(dic2, i, j);
		    break;
		}
	    }
	    if (k == MAXENTRY) { /* não existe no dic1 */
		for (; k<MAXENTRY*2; k++) {
		    if (buffer2[k].id == 0) {
			buffer2[k].id = id;
			buffer2[k].val = dictionary_get_val(dic2, i, j);
			break;
		    }
		}
	    }
	}

	/* OK. Neste ponto devemos ter os dois buffers prontos para
	 * serem somados */
	for (j = 0; j< MAXENTRY*2; j++) {
	    float tmp;
	    float v1,v2;

	    float occ1 = dictionary_get_occ(dic1,i);
	    float occ2 = dictionary_get_occ(dic2,i);

	    v1 = buffer1[j].val;
	    v2 = buffer2[j].val;

	    if (occ1 + occ2 == 0.0) {
		tmp = ((buffer1[j].val*(size1/100000)*factor1*size2 +
			buffer2[j].val*(size2/100000)*factor2*size1) /
		       ((size1/100000)*factor1*size2 + 
			(size2/100000)*factor2*size1));
	    } else {
		tmp = ((buffer1[j].val * occ1 * size2 * factor1 +
			buffer2[j].val * occ2 * size1 * factor2) /
		       (occ1 * size2 * factor1 + 
			occ2 * size1 * factor2));
	    }
	    buffer1[j].val = tmp;
	    buffer1[j].id = buffer1[j].id?buffer1[j].id:buffer2[j].id;
	}

	/* Buffers somados. */
	/* Ordenar */
	qsort(buffer1, MAXENTRY*2, sizeof(DicPair), &cmp);

	/* preencher o novo dicionário */
	for (j = 0; j < MAXENTRY; j++) {
	    dictionary_set_id(new, i, j, buffer1[j].id);
	    if (buffer1[j].val > 1) {
		fprintf(stderr, "Aqui vai um (%u,%u)... %f\n", i,buffer1[j].id,buffer1[j].val);
		buffer1[j].val = 1;
	    }
	    dictionary_set_val(new, i, j, buffer1[j].val);
	}
	
	count = dictionary_get_occ(dic1, i) + dictionary_get_occ(dic2, i);
	new = dictionary_set_occ(new, i, count);
    }

    return new;
}


/**
 * @brief uses a dictionary and two codified sentences returns a
 * measure of translation probability
 *
 * @todo change function name
 *
 * @param dic Dictionar to be used
 * @param s1 word ids buffer for first sentence
 * @param s1size size of s1 buffer
 * @param s2 word ids buffer for second sentence
 * @param s2size size of s2 buffer
 * @return a translation probability measure
 */
double dictionary_sentence_similarity(Dictionary *dic,
				      nat_uint32_t *s1, int s1size,
				      nat_uint32_t *s2, int s2size) 
{
    double val = 0.0;
    int i, j, k, done;
    
    for (i = 0; i < s1size; i++) {
	done = 0;
	if (s1[i] < dic->size) {
	    for (j = 0; j < MAXENTRY && !done; j++) {
		nat_uint32_t id = dictionary_get_id(dic, s1[i], j);
		for (k = 0; k < s2size && !done; k++) {
		    if (s2[k] == id) {
			float v = dictionary_get_val(dic, s1[i], j);
			val += ((double)1/s1size)*v;
			done = 1;
		    }
		}
	    }
	}
    }

    return val;

}


static void dictionary_remap_with_size(nat_uint32_t *Sit, nat_uint32_t *Tit, Dictionary *dic, nat_uint32_t size) 
{
    nat_uint32_t *occopy;
    DicPair *copy;
    nat_uint32_t i, j;

    occopy = g_new(nat_uint32_t, dic->size + 1);
    copy   = g_new(DicPair, dic->size * MAXENTRY + MAXENTRY);
    for (i=0; i < size; ++i) {
	occopy[Sit[i]] = dic->occurs[i];
	for (j = 0; j < MAXENTRY; ++j) {
	    DIC_POS(copy, Sit[i], j).val = DIC_POS(dic->pairs,i,j).val;
	    if (DIC_POS(copy, Sit[i], j).val == 0.0000000) {
		DIC_POS(copy, Sit[i], j).id  = 0;
	    } else {
		DIC_POS(copy, Sit[i], j).id = Tit[DIC_POS(dic->pairs,i,j).id];
	    }
	}
    }

    g_free(dic->occurs);
    dic->occurs = occopy;
    g_free(dic->pairs);
    dic->pairs  = copy;
}

/**
 * @brief ??
 *
 * @todo Fix these docs
 */
void dictionary_remap(nat_uint32_t *Sit, nat_uint32_t *Tit, Dictionary *dic) 
{
    dictionary_remap_with_size(Sit,Tit,dic,dic->size);
}

/**
 * @brief Reallocs size of dictionary and remaps identifiers
 *
 * @todo Fix these docs
 */
void dictionary_realloc_map(nat_uint32_t *Sit, nat_uint32_t *Tit, Dictionary *dic, nat_uint32_t nsize)
{
    nat_uint32_t i;
    nat_uint32_t osize;
    osize = dic->size;
    dictionary_realloc(dic, nsize);

    for (i = osize; i < nsize; i++) {
	int j;
	dic->occurs[i] = 0;
	for (j=0; j<MAXENTRY; ++j) {
	    dic->pairs[i*MAXENTRY+j].id = 0;
	    dic->pairs[i*MAXENTRY+j].val = 0;
	}
    }
    g_message("** Dictionary realloc done");
    dictionary_remap_with_size(Sit, Tit, dic, osize);
}

/**
 * @brief Reallocs buffers for a dictionary
 *
 * @param dic The dictionary to be enlarged
 * @param nsize The new dictionary size
 */
void dictionary_realloc(Dictionary *dic, nat_uint32_t nsize) {
    g_message("** old size is %u", dic->size);
    g_message("** new size is %u", nsize);
    dic->occurs = g_realloc(dic->occurs, nsize*sizeof(nat_uint32_t));
    dic->pairs  = g_realloc(dic->pairs,  nsize*sizeof(DicPair)*MAXENTRY);
    dic->size   = nsize;
}
