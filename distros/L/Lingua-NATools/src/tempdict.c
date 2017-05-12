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
#include <EXTERN.h>
#include <perl.h>
#include "matrix.h"
#include "tempdict.h"

#include <glib.h>

/**
 * @file
 * @brief Code file for temporary dictionary created during 
 *             co-occurrence matrix interpretation
 */



/**
 * @brief Frees a cMat2 temporary matrix
 *
 * @todo Check if we should free also the Matrix variable
 *
 * @param Matrix the matrix object to be freed.
 */
void tempdict_freematrix2(struct cMat2 *Matrix)
{
    free(Matrix->items);
    free(Matrix->firstR);
    free(Matrix->firstC);
}

/**
 * @brief Allocates memory for temporary dictionary
 *
 * @todo Change mallocs to g_new, which to not need success testing
 *
 * @todo Change the function signature to return the pointer instead
 * of receiving it. Thus, the tempdict_freematrix2 will need to delete
 * the main Matrix variable too.
 *
 * @param Matrix pointer to a cMat2 structure
 * @param Nrow number of rows to be allocated
 * @param Ncolumn number of columns to be allocated
 *
 * @return 0 on success
 */
int tempdict_allocmatrix2(struct cMat2 *Matrix, nat_uint32_t Nrow, nat_uint32_t Ncolumn)
{
    Matrix->Nrows = Nrow;
    Matrix->Ncolumns = Ncolumn;

    Matrix->memory = MEMBLOCK;

    if ((Matrix->firstR = (struct cItem **) malloc(Nrow * sizeof(struct cItem *))) == NULL)
	return 1;
    if ((Matrix->firstC = (struct cItem **) malloc(Ncolumn * sizeof(struct cItem *))) == NULL)
	return 2;
    if ((Matrix->items = (struct cItem *) malloc(Matrix->memory * sizeof(struct cItem))) == NULL)
	return 3;
    Matrix->clean = 0;
    Matrix->p = 0;

    return 0;
}


static int tempdict_incpointer(struct cMat2 *Matrix)
{
    Matrix->p++;
    if (Matrix->p >= Matrix->memory) {
	Matrix->memory += MEMBLOCK;
/*	fprintf(stderr, "is %ld \n", Matrix->memory); */
	Matrix->items = (struct cItem *) realloc(Matrix->items, (Matrix->memory+1)*sizeof(struct cItem)); 
    }
    return (Matrix->items == NULL);
}


/**
 * @brief ??
 *
 * @todo Document this function
 *
 * @param Matrix ??
 * @param f ??
 * @param r ??
 * @param c ??
 *
 * @return ??
 */
int tempdict_dirtyputvalue2(struct cMat2 *Matrix, float f, nat_uint32_t r, nat_uint32_t c)
{
    struct cItem *I;
    I = Matrix->items + Matrix->p;
    I->row = r; I->column = c;
    I->nextC = NULL;
    if (f < MAXVAL) {
	I->value = (nat_uint32_t) (f * MAXDEC + 0.5f);
	return tempdict_incpointer(Matrix);
    }
    else { 
	I->value = (nat_uint32_t) (((long) (f* (float) MAXDEC + 0.5f)) % ((long) MAXVAL* (long) MAXDEC)); 
	if (tempdict_incpointer(Matrix)) return 1;
	I = Matrix->items + Matrix->p;
	I->row = r; I->column = c;
	I->nextC = NULL;
	I->value = (nat_uint32_t) (f / (float) MAXVAL);
	return tempdict_incpointer(Matrix);      
    }
}

static void tempdict_markdoubleitems(struct cMat2 *Matrix)
{
    long i;
    struct cItem *I;
    I = Matrix->items;
    i = 0;
    while (i < Matrix->p - 1) {
	if (I[i].row == I[i+1].row && I[i].column == I[i+1].column)
	    I[i].nextC = I+i+1;
	else
	    I[i].nextC = NULL;
	i++;
    }
}


static void tempdict_swapitems(struct cMat2 *Matrix, long i, long j)
{
    long l;
    struct cItem dummy, *I;
    I = Matrix->items;
    if (i>j) { l=i; i=j; j=l; }
    dummy = I[i];
    I[i] = I[j];
    I[j] = dummy;
    if (i < Matrix->p -1 && I[i].nextC == I+i+1) {
	if (j < Matrix->p -1 && I[j].nextC == I+j+1) {
	    dummy = I[i+1];
	    I[i+1] = I[j+1];
	    I[j+1] = dummy;
	}
	else {
	    dummy = I[i+1];
	    memmove(I+i+1, I+i+2, (j-i-1) * sizeof(struct cItem));
	    I[j] = dummy;
	}
    }
    else {
	if (j < Matrix->p -1 && I[j].nextC == I+j+1) {
	    dummy = I[j+1];
	    memmove(I+i+2, I+i+1, (j-i) * sizeof(struct cItem));
	    I[i+1] = dummy;
	}
    }  
}

static void tempdict_removeitem(struct cMat2 *Matrix, long i)
{
    struct cItem *I;
    I = Matrix->items;
    if (I[i].nextC == I+i+1) 
	memmove(I+i, I+i+2, (Matrix->p -i -2) * sizeof(struct cItem));
    else
	memmove(I+i, I+i+1, (Matrix->p -i -1) * sizeof(struct cItem));
}

static void tempdict_bubblesortitems(struct cMat2 *Matrix)
{
    long i, j;
    int done;
    struct cItem *I;
    I = Matrix->items;
    i = 0;
    done = 1;
    do {
	while (i < Matrix->p -1) {
	    j = i+1;
	    if (i < Matrix->p -2 && I[i].nextC == I+i+1) j++;
	    if (I[i].row > I[j].row) {
		tempdict_swapitems(Matrix, j, i);
		done = 0;
	    } 
	    else {
		if (I[i].row == I[j].row && I[i].column > I[j].column) {
		    tempdict_swapitems(Matrix, j, i);
		    done = 0;      
		}
		else {
		    if (I[i].row == I[j].row && I[i].column == I[j].column)
			tempdict_removeitem(Matrix, i);
		}
	    }
	    i = j; 
	}
    } while (!done);
}

static void tempdict_setrowpointers(struct cMat2 *Matrix)
{
    long l;
    nat_uint32_t i;
    l=0;
    for (i=1; i<= Matrix->Nrows; i++) {
	while (l < Matrix->p && Matrix->items[l].row < i) l++;
	if (Matrix->items[l].row == i)
	    Matrix->firstR[i-1] = Matrix->items + l;
	else
	    Matrix->firstR[i-1] = NULL;
    }
}  

static void tempdict_setcolumnpointers(struct cMat2 *Matrix)
{
    long l;
    nat_uint32_t i;
    struct cItem *I;
    for (i=1; i <= Matrix->Ncolumns; i++)
	Matrix->firstC[i-1] = NULL;
    l=0;
    while (l < Matrix->p) {
	Matrix->items[l].nextC = NULL;
	I = Matrix->firstC[Matrix->items[l].column - 1];
	if (I == NULL) { 
	    Matrix->firstC[Matrix->items[l].column - 1] = Matrix->items + l;
	}
	else {
	    while (I->nextC != NULL) 
		I = I->nextC;
	    I->nextC = Matrix->items + l;
	}
	l++;
    } 
}

static int tempdict_cleanmatrix2(struct cMat2 *Matrix)
{
    if (Matrix->p <= 0) return 1;
    tempdict_markdoubleitems(Matrix);
    tempdict_bubblesortitems(Matrix);
    tempdict_setrowpointers(Matrix);
    tempdict_setcolumnpointers(Matrix);
    Matrix->clean = 1;
    Matrix->items[Matrix->p].row = 0;  /* voor GetValue */ 
    return 0;
}

#if 0
/* This is not being used, but might be useful later */
static float GetValue2(struct cMat2 *Matrix, nat_uint32_t r, nat_uint32_t c)
{
    long i;
    float f;
    struct cItem *p;

    if (r < 1 || r > Matrix->Nrows || c < 1 || c > Matrix->Ncolumns)
	return 0.0f;
    if (!Matrix->clean) 
	if (tempdict_cleanmatrix2(Matrix)) return 0.0f;

    p = Matrix->firstR[r-1];
    if (p == NULL) return 0.0f;
    i = 0;
    while (p[i].row == r && p[i].column >0 && p[i].column < c) i++;
    if (p[i].row == r && p[i].column == c) {
	f = (float) (p[i].value) / (float) MAXDEC;
	if (p[i+1].row == r  && p[i+1].column == c)
	    f += (float) (p[i+1].value) * MAXVAL;
	return f;
    }
    else 
	return 0.0f;     
}
#endif


/**
 * @brief ??
 *
 * @todo Document this function
 *
 * @param Matrix ??
 * @param r ??
 * @param c ??
 * @param f ??
 * @param max ??
 *
 * @return ??
 */
float tempdict_getrowmax2(struct cMat2 *Matrix, nat_uint32_t r, nat_uint32_t *c, float *f, nat_uint32_t max)
{
    nat_uint32_t i, j, k;
    float fm, total;
    struct cItem *p;

    if (r < 1 || r > Matrix->Nrows) {
	fprintf(stderr, "tempdict: wrong row number\n");
	return 0.0f;
    }
    if (!Matrix->clean) 
	if (tempdict_cleanmatrix2(Matrix)) return 0.0f; /* eigenlijk fout */

    for (j = 0; j < max; j++) {
	f[j] = 0.0f;
	c[j] = 0;
    }
    p = Matrix->firstR[r-1];
    if (p == NULL) {
	return 0.0f;
    }
    i = 0;
    total = 0.0f;
    while (p[i].row == r) {
	fm = (float) (p[i].value) / (float) MAXDEC;
	if (p[i+1].row == r  && p[i].column == p[i+1].column) {
	    fm += (float) (p[i+1].value) * MAXVAL;
	    i++;
	}

	total += fm;
	j = 0;
	while (j < max && c[j] > 0 && f[j] >= fm) j++;
	if (j<max) {
	    for(k = max-1; k >j; k--) {
		c[k] = c[k-1];
		f[k] = f[k-1];
	    }
	    c[j] = p[i].column;
	    f[j] = fm;
	}
	i++;    
    }
    return total;
}

/**
 * @brief ??
 *
 * @todo Document this function
 *
 * @param Matrix ??
 * @param c ??
 * @param r ??
 * @param f ??
 * @param max ??
 *
 * @return ??
 */
float tempdict_getcolumnmax2(struct cMat2 *Matrix, nat_uint32_t c, nat_uint32_t *r, float *f, nat_uint32_t max)
{
    long j, k;
    float fm, total;
    struct cItem *p;

    if (c < 1 || c > Matrix->Ncolumns)
	return 0.0f;
    if (!Matrix->clean) 
	if (tempdict_cleanmatrix2(Matrix)) return 0.0f;  /* eigenlijk fout */

    for (j = 0; j < max; j++) {
	f[j] = 0.0f;
	r[j] = 0;
    }
    total = 0;
    p = Matrix->firstC[c-1];
    while (p != NULL) {
	fm = (float) (p[0].value) / (float) MAXDEC;
	if (p[1].column == c  && p[0].row == p[1].row) {
	    fm += (float) (p[1].value) * MAXVAL;
	    p++;
	}

	total += fm;
	j = 0;
	while (j < max && r[j] > 0 && f[j] >= fm) j++;
	if (j<max) {
	    for(k = max-1; k >j; k--) {
		r[k] = r[k-1];
		f[k] = f[k-1];
	    }
	    r[j] = p[0].row;
	    f[j] = fm;
	}
	p = p->nextC;    
    }
    return total;
}

/**
 * @brief Loads a cMat2 temporary matrix
 *
 * @param Matrix pointer to a cMat2 object where to place the matrix
 * @param filename the filename for the file containing the matrix
 *
 * @return 0 on success
 */
int tempdict_loadmatrix2(struct cMat2 *Matrix, const char *filename)
{
    FILE *fd;
    long l;

    fd = fopen(filename, "rb");
    if (fd == NULL) return 1;
    if (fread(&Matrix->Nrows, sizeof(nat_uint32_t), 1, fd) != 1) return 2;
    if (fread(&Matrix->Ncolumns, sizeof(nat_uint32_t), 1, fd) != 1) return 3;
    if (fread(&Matrix->p, sizeof(long), 1, fd) != 1) return 4;
    Matrix->memory = Matrix->p;
    Matrix->items  = (struct cItem *)  malloc((Matrix->memory + 1) * sizeof(struct cItem));
    Matrix->firstR = (struct cItem **) malloc(Matrix->Nrows * sizeof(struct cItem *));
    Matrix->firstC = (struct cItem **) malloc(Matrix->Ncolumns * sizeof(struct cItem *));
    if (Matrix->items == NULL || Matrix->firstR == NULL || Matrix->firstC == NULL) return 5;
    for(l=0; l<Matrix->memory; l++)
	if (fread(&(Matrix->items[l].row), 3 * sizeof(nat_uint32_t), 1, fd) != 1) return 6;
    tempdict_setrowpointers(Matrix);
    tempdict_setcolumnpointers(Matrix);
    Matrix->clean = 1;
    Matrix->items[Matrix->p].row = 0;  /* voor GetValue */ 
    fclose(fd);
    return 0;
}


/**
 * @brief Saves a cMat2 temporary matrix
 *
 * @param Matrix the matrix object to be saved
 * @param filename the filename to be used
 *
 * @return 0 on success
 */
int tempdict_savematrix2(struct cMat2 *Matrix, const char *filename)
{
    FILE *fd;
    long l;
    nat_uint32_t i;

    if (!Matrix->clean)
	if (tempdict_cleanmatrix2(Matrix)) return 1;
    fd = fopen(filename, "wb");
    if (fd == NULL) return 2;
    i = Matrix->Nrows;
    if (fwrite(&i, sizeof(i), 1, fd) != 1) return 3;
    i = Matrix->Ncolumns;
    if (fwrite(&i, sizeof(i), 1, fd) != 1) return 4;
    l = Matrix->p;
    if (fwrite(&l, sizeof(l), 1, fd) != 1) return 5;
    for (l=0; l < Matrix->p; l++)
	if (fwrite(&(Matrix->items[l].row), 3 * sizeof(nat_uint32_t), 1, fd) != 1) return 6;
    if (fclose(fd)) return 7;
    return 0;
}
