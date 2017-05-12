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

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "matrix.h"

#include <glib.h>

/**
 * @file
 * @brief Code file for the matrix data structure module
 */

/**
 * @brief debug flag. Set to 1 to activate dubugging.
 */
#define DEBUG 0

/**
 * @brief Allocates a new Matrix object
 * 
 * @param nrow number of rows
 * @param ncolumn number of columns
 *
 * @return the new Matrix object
 */
Matrix* AllocMatrix(nat_uint32_t nrow, nat_uint32_t ncolumn)
{
    nat_uint32_t r;
    Row row;
    Matrix *matrix;

    /* Alloc structure */
    //matrix = g_new(Matrix, 1);
    matrix = (Matrix*)malloc(sizeof(Matrix));
    if (!matrix) return NULL;

    matrix->Nrows = nrow;
    matrix->Ncolumns = ncolumn;

    /* Alloc structure pointers for rows */
    //matrix->rows = g_new(Row, 1+nrow);
    matrix->rows = (Row*)malloc(sizeof(Row) * (nrow + 1));
    if (!matrix->rows) {
	//g_free(matrix);
	free(matrix);
	return NULL;
    }

    /* Alloc row */
    for (r = 1; r <= nrow; r++) {
	row = matrix->rows[r];
	matrix->rows[r].length = MEMBLOCK;
	//matrix->rows[r].cells = g_new0(Cell, MEMBLOCK);
	matrix->rows[r].cells = (Cell*)malloc(sizeof(Cell)*MEMBLOCK);
	if (!matrix->rows[r].cells) {
	    /* FIXME: desalloc all allocked things or just use g_new :-) */
	    return NULL;
	}
	memset(matrix->rows[r].cells, 0, sizeof(Cell)*MEMBLOCK);
    }

    return matrix;
}

/**
 * @brief Frees a matrix structure
 * 
 * @param matrix the matrix object to free
 */
void FreeMatrix(Matrix *matrix)
{
    nat_uint32_t r;

    for (r = 1; r <= matrix->Nrows; ++r) {
	free(matrix->rows[r].cells);
    }
    free(matrix->rows);
    free(matrix);
}

#if 0
/* not used, it seems */
nat_uint32_t UsedRow(Matrix *matrix,
		 nat_uint32_t row)
{
    Cell *pointer;
    nat_uint32_t length, i;

    pointer = matrix->rows[row].cells;
    length = matrix->rows[row].length;
    i = 0;
    while (i < length && pointer[i].column > 0) i++;
    return i;
}
#endif


static int SearchItem(Matrix *matrix,
		      nat_uint32_t row, nat_uint32_t column,
		      Cell **pointer,
		      nat_uint32_t *i, nat_uint32_t *length)
{
    if (row > matrix->Nrows || column > matrix->Ncolumns) 
	return 1;
    else {
	nat_uint32_t low, high, m;
	*pointer = matrix->rows[row].cells;
	*length = matrix->rows[row].length;
	*i = 0;

	/* while (*i < *length && (*pointer)[*i].column > 0 && (*pointer)[*i].column < column) (*i)++; */

	low = 0;
	high = *length - 1;
	while (low <= high) {
	    m = (low+high)/2;
	    if ((*pointer)[m].column == column) {
		if (m > 0 && (*pointer)[m-1].column == column) m--;
		*i = m;
		return 0;
	    }
	    if ((*pointer)[m].column > column || (*pointer)[m].column == 0) {
		if (!m) {
		    *i = 0;
		    return 0;
		}
		high = m - 1;
	    } else {
		low = m + 1;
		if (low == *length) {
		    *i = low;
		    return 0;
		}
	    }
	}

	*i = low;
	return 0;
    }
}

static int EnlargeRow(Matrix *matrix, nat_uint32_t r)
{
    nat_uint32_t N, nlength, olength;

    N = matrix->Nrows;

    olength = matrix->rows[r].length;
    nlength = olength * 2;
    if (nlength > matrix->Ncolumns)
	nlength = olength*1.2;

    /* matrix->rows[r].cells = g_renew(Cell, matrix->rows[r].cells, nlength); */
    matrix->rows[r].cells = (Cell*)realloc(matrix->rows[r].cells, nlength * sizeof(Cell));

    if (matrix->rows[r].cells == NULL || r > N)
	return 1;
    else {
	memset(matrix->rows[r].cells + matrix->rows[r].length, 0, (nlength-matrix->rows[r].length) * sizeof(Cell));
	matrix->rows[r].length = nlength;
	return 0;
    }
}

/**
 * @brief Gets a value from a matrix cell
 *
 * @param p Cell object
 * @param Ma Copy selector
 *
 * @return Cell value
 */
nat_uint32_t Get(Cell *p, MatrixVal Ma)
{
    return Ma?p->value1:p->value2;
}

static void Inc(Cell *p, MatrixVal Ma, nat_uint32_t inc)
{
    if (Ma)
        p->value1 += inc;
    else
        p->value2 += inc;
}

static int Put(Matrix *matrix, MatrixVal Ma, float f, nat_uint32_t i, nat_uint32_t row)
{
    Cell *pointer;
    nat_uint32_t v;
    nat_uint32_t length;

    pointer = matrix->rows[row].cells;
    length = matrix->rows[row].length;

    if (f < MAXVAL) {
	v = (nat_uint32_t) (f * MAXDEC + 0.5f);
	if (Ma)
            pointer[i].value1 = v;
	else
            pointer[i].value2 = v;
	++i;
	if (i < length && pointer[i].column == pointer[i-1].column) {
	    if (Get(pointer + i, !Ma) == 0) {
		memmove(pointer + i, pointer + i + 1,(length-i)*sizeof(Cell));
		pointer[length].column = 0;
		pointer[length].value1 = 0;
		pointer[length].value2 = 0;
	    }
	    else
		if (Ma) pointer[i].value1 = 0;
		else pointer[i].value2 = 0;
	}
    }
    else {
	v = (nat_uint32_t) (((int) (f* (float) MAXDEC + 0.5f)) % ((nat_uint32_t) MAXVAL * (nat_uint32_t) MAXDEC));
#if DEBUG
	printf("Matrix: double precision\n");
#endif
	if (Ma)
            pointer[i].value1 = v;
	else
            pointer[i].value2 = v;
	i++;
	if ((i <length && pointer[i].column != pointer[i-1].column) || (i>=length)) {
	    /* if ((i < length && pointer[length].column != 0) || (i>length)) { */
	    if (i>=length) {
		if (EnlargeRow(matrix, row)) {
		    printf("Error Enlarging row...\n");
		    return 1;
		}
		pointer = matrix->rows[row].cells;
		length = matrix->rows[row].length;
	    }
	    memmove(pointer+i,pointer+i-1,(length-i)*sizeof(Cell));
	    if (Ma) pointer[i].value2 = 0;
	    else pointer[i].value1 = 0;
	}
	v = (nat_uint32_t) (f / (float) MAXVAL);
	if (Ma) pointer[i].value1 = v;
	else pointer[i].value2 = v;
    }
    return 0;
}

static int PutValue(Matrix *matrix, MatrixVal Ma, float f, 
		    nat_uint32_t row, nat_uint32_t column)
{
    Cell *pointer;
    nat_uint32_t i, length;
    if (SearchItem(matrix, row, column, &pointer, &i, &length)) {
	printf("PutValue: Error searching item\n");
	return 1;
    } else {
	/* column is free or already exists */
	if (i < length && (pointer[i].column == 0 || pointer[i].column == column)) {
	    pointer[i].column = column;

	} else {

	    if (i >= length) { /*  || pointer[i].column != 0) { */
		/* printf("Enlarging 2\n"); */
		// printf("ROW: %d\n", row);
		if (EnlargeRow(matrix, row)) {
		    printf("PutValue: Cannot enlarge matrix row\n");
		    return 1;
		}
		pointer = matrix->rows[row].cells;
		length  = matrix->rows[row].length;

	    }
	    memmove(pointer+i+1, pointer+i, (length-i-1)*sizeof(Cell));
	    pointer[i].column = column;
	    pointer[i].value1 = 0;
	    pointer[i].value2 = 0;
	}
	return Put(matrix, Ma, f, i, row);
    }
}

/**
 * @brief Don't know
 * 
 * @todo discover what this does
 */
int IncValue(Matrix *matrix, 
	     MatrixVal Ma,
	     float incfactor,
	     nat_uint32_t row, nat_uint32_t column)
{
    Cell *p;
    nat_uint32_t i, l;
    nat_uint32_t inc;
    float f;

    if (SearchItem(matrix, row, column, &p, &i, &l)) {
        fprintf(stderr, "** WARNING ** IncValue: Failed on Search Item (%d,%d)\n",row,column);
	return 1;
    } else {
	if (i < l && (p[i].column == 0 || p[i].column == column)) {
	    inc = (nat_uint32_t) (incfactor * MAXDEC + 0.5f);
	    p[i].column = column;
	    if (Get(p+i, Ma) + inc < MAXVAL * MAXDEC) {
		Inc(p+i, Ma, inc);
		return 0;
	    } else {
		f = (float) Get(p+i, Ma) / (float) MAXDEC;
		if (i+1 <= l && p[i+1].column == column)
		    f += (float) (Get(p+i+1, Ma) * MAXVAL);
		return Put(matrix, Ma, f+incfactor, i, row);
	    }
	} else {
	    return PutValue(matrix, Ma, incfactor, row, column);
	}
    }
}

/**
 * @brief Don't know
 * 
 * @todo discover what this does
 */
float GetValue(Matrix *matrix, MatrixVal Ma,
	       nat_uint32_t r, nat_uint32_t c)
{
    Cell *p;
    nat_uint32_t i, l;
    float f;
    if (SearchItem(matrix, r, c, &p, &i, &l))
	return 0.0f;
    else {
	if (i<=l && p[i].column == c) {
	    f = (float) Get(p+i, Ma) / (float) MAXDEC;
	    if (i+1 <= l && p[i+1].column == c)
		f += (float) Get(p+i+1, Ma) * MAXVAL;
	    return f;
	}
	else return 0.0f;
    }
}

/**
 * @brief Don't know
 * 
 * c -> array de indices das colunas preenchidas
 * f -> array dos valores nessas células
 *
 * retorna total da linha
 *
 * @todo discover what this does
 */
float GetRow(Matrix *matrix, MatrixVal Ma, nat_uint32_t r, nat_uint32_t *c, float *f)
{
    Cell *p;
    nat_uint32_t i, j, l;
    float fm, total;
    if (r < 1 || r > matrix->Nrows)
	return 0.0f;
    else {
	p = matrix->rows[r].cells;
	l = matrix->rows[r].length;
	i = 0;
	j = 0;
	total = 0.0f;
	while (i < l && p[i].column > 0) {
	    fm = (float) Get(p+i, Ma) / (float) MAXDEC;
	    if (i+1 < l && p[i].column == p[i+1].column) {
		fm += (float) (Get(p+i+1, Ma)*MAXVAL);
		i++;
	    }
	    total += fm;
	    c[j] = p[i].column;
	    f[j] = fm;
	    j++;      
	    i++;
	}
	c[j] = 0;
	f[j] = 0.0f;
    }
    return total;
}

/* Not used, it seems */
#if 0
static float GetRowMax(Matrix *matrix, MatrixVal Ma, nat_uint32_t r, 
		       nat_uint32_t *c, float *f, nat_uint32_t max)
{
    Cell *p;
    nat_uint32_t i, j, k, l;
    float fm, total;
    if (r < 1 || r > matrix->Nrows)
	return 0.0f;
    else {
	for (j = 0; j < max; j++) {
	    f[j] = 0.0f;
	    c[j] = 0;
	}
	p = matrix->rows[r].cells;
	l = matrix->rows[r].length;
	i = 0;
	total = 0.0f;
	while (i < l && p[i].column > 0) {
	    fm = (float) Get(p+i, Ma) / (float) MAXDEC;
	    if (i+1 < l && p[i].column == p[i+1].column) {
		fm += (float) (Get(p+i+1, Ma)*MAXVAL);
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
    }
    return total;
}
#endif

#if 0
/* Not used, it seems */
static float GetColumnMax(Matrix *matrix, MatrixVal Ma, nat_uint32_t c, 
			  nat_uint32_t *r, float *f, nat_uint32_t max)
{
    Cell *p;
    nat_uint32_t i, j, k, l;
    float fm, total;
    if (c < 1 || c > matrix->Ncolumns)
	return 0.0f;
    else {
	for (j = 0; j < max; j++) {
	    f[j] = 0.0f;
	    r[j] = 0;
	}
	i = 1;
	total = 0.0f;
	while (i <= matrix->Nrows) {
	    p = matrix->rows[i].cells;
	    l = matrix->rows[i].length;
	    j = 0;
	    while (j < l && p[j].column > 0 && p[j].column < c) j++;
	    if (j < l && p[j].column == c) {
		fm = (float) Get(p+j, Ma) / (float) MAXDEC;
		if (j+1 < l && p[j+1].column == c)
		    fm += (float) (Get(p+j+1, Ma)*MAXVAL);
		total += fm;
		j = 0;
		while (j < max && r[j] > 0 && f[j] >= fm) j++;
		if (j<max) {
		    for(k = max-1; k >j; k--) {
			r[k] = r[k-1];
			f[k] = f[k-1];
		    }
		    r[j] = i+1;
		    f[j] = fm;
		}
	    }
	    i++;
	}
    }
    return total;
}
#endif

/**
 * @brief Don't know
 * 
 * @todo discover what this does
 */
int GetPartialMatrix(Matrix *matrix, MatrixVal Ma, nat_uint32_t *r,
		     nat_uint32_t *c, double *M, nat_uint32_t max)
{
    Cell *p;
    nat_uint32_t i, l, m, n;
    nat_uint32_t *tmp;
    tmp = c;
    while (*c > 0)
	if (*c++ > matrix->Ncolumns)
	    return 1;
    c = tmp;
    m = 0;
    n = 0;
    while (*r > 0) {
	if (*r > matrix->Nrows)
	    return 1;
	else {
	    p = matrix->rows[*r].cells;
	    l = matrix->rows[*r].length;
	    i = 0;
	    while (*c > 0) {

#if 1
		Cell *x;
		nat_uint32_t xx;
		SearchItem(matrix, *r, *c, &x, &i, &xx);
#else
		while (i < l && p[i].column > 0 && p[i].column < *c) i++;
#endif
		if (i < l && p[i].column == *c) {
		    M[m*max + n] = (double) Get(p+i, Ma) / (double) MAXDEC ;
		    if (i+1 < l && p[i+1].column == *c)
			M[m*max + n] += (double) Get(p +i+1, Ma) * MAXVAL;
		}
		else M[m*max + n] = 0.0f;
		c++;
		n++;
	    }
	}
	r++;
	m++;
	c = tmp;
	n = 0;
    }
    return 0;
}


/* Not used at the moment, it seems */
#if 0
static int GetConditionalMatrix(Matrix *matrix, MatrixVal Ma, nat_uint32_t *r, 
				nat_uint32_t *c, float *M, nat_uint32_t max)
{
    Cell *p;
    nat_uint32_t i, l, *tmp, m, n;
    float f, pm;
    tmp = c;
    while (*c > 0)
	if (*c++ > matrix->Ncolumns) return 1;
    c = tmp;
    m = 0;
    n = 0;
    while (*r > 0) {
	if (*r > matrix->Nrows)
	    return 1;
	else {
	    p = matrix->rows[*r].cells;
	    l = matrix->rows[*r].length;
	    i = 0;
	    pm = 0.0f;
	    while (i < l && p[i].column > 0) {
		f = (float) Get(p+ (i++), Ma) / (float) MAXDEC ;
		if (i < l && p[i].column == p[i-1].column)
		    f += (float) Get(p + (i++), Ma) * (float) MAXVAL;	
		pm += f;
		while (*c > 0 && p[i-1].column >= *c) {
		    if (p[i-1].column == *c) M[m*max + n] = f;
		    else M[m*max + n] = 0.0f;
		    c++;
		    n++;
		}
	    }
	}
	c = tmp;
	n = 0;
	while (*c++ > 0)
	    M[m*max + n++] /= pm;   /* conditional */
	
	r++;
	m++;
	c = tmp;
	n = 0;
    }
    return 0;
}
#endif

/**
 * @brief Don't know
 * 
 * @todo discover what this does
 */
void ClearMatrix(Matrix *matrix, MatrixVal Ma)
{
    Cell *p;
    nat_uint32_t r, i, l;
    for (r = 1; r <= matrix->Nrows; r++) {
	p = matrix->rows[r].cells;
	l = matrix->rows[r].length;
	i = 0;
	while (i < l && p[i].column > 0) {
	    if (Ma)
                p[i].value1 = 0;
	    else
                p[i].value2 = 0;
            ++i;
	    if (i < l && p[i].column == p[i-1].column)
		if ((Ma && p[i].value2 == 0) || (!Ma && p[i].value1 == 0)) {
		    if (i+1 < l)
			memmove(p+i, p+i+1, sizeof(Cell)*(l-i-1)); // was ...*(l-i)
		    p[l-1].column = 0;  // was p[l]
		    p[l-1].value1 = 0;  // was p[l]
		    p[l-1].value2 = 0;  // was p[l]
		}
	}
    }
}

/**
 * @brief Copy the matrices values to the other "copy"
 * 
 * @param matrix the matrix pair
 * @param Mdet the matrix copy where to copy the matrix to
 */
void CopyMatrix(Matrix *matrix,  MatrixVal Mdest)
{
    Cell *p;
    nat_uint32_t r, i, l;
    for (r = 1; r <= matrix->Nrows; r++) {
	p = matrix->rows[r].cells;
	l = matrix->rows[r].length;
	i = 0;
	while (i < l && p[i].column > 0) {
	    if (Mdest)
                p[i].value1 = p[i].value2; 
	    else
                p[i].value2 = p[i].value1;
	    i++;
	}
    }
}

/**
 * @brief Calculate the man difference from all matrices cells
 * 
 * This function receives a pair of matrices (Each Matrix structure
 * cell includes two values) and calculates the difference of each
 * cell values, and then its average.
 *
 * Basically, this value shows how much the matrices have changed.
 *
 * @param matrix The pair of matrices to be compared
 * @return mean difference for all matrix values
 */
float CompareMatrices(Matrix *matrix)
/* Gives mean difference */
{
    Cell *p;
    unsigned long r, i, l;
    int total;
    float f1, f2, diff;
    
    total = 0;
    diff = 0.0f;

    /* Go by all the matrix rows */
    for (r = 1; r <= matrix->Nrows; ++r) {
	p = matrix->rows[r].cells;
	l = matrix->rows[r].length;
	i = 0;
	while (i < l && p[i].column > 0) {
	    f1 = (float) Get(p+i, 0) / (float) MAXDEC ;
	    f2 = (float) Get(p+i, 1) / (float) MAXDEC ;
            ++i;
	    if (i < l && p[i].column == p[i-1].column) {
		f1 += (float) Get(p + i, 0) * MAXVAL;
		f2 += (float) Get(p + i, 1) * MAXVAL;
                ++i;
	    }
	    diff += fabs(f1 - f2);
	    ++total;
	}
    }
    return (diff / total);
}

/**
 * @brief Sums the values in a matrix
 *
 * Goes through all matrix values an sum them all.
 *
 * @param matrix the matrix pair to be used
 * @param Ma     the matrix copy choice
 * 
 * @return the sum of the matrix values
 */
float MatrixTotal(Matrix *matrix, MatrixVal Ma)
{
    Cell *p;
    float total, f;
    nat_uint32_t r, i, l;
    total = 0;
    for (r = 1; r <= matrix->Nrows; r++) {
	p = matrix->rows[r].cells;
	l = matrix->rows[r].length;
	i = 1;
	while (i < l && p[i].column > 0) {
	    f = (float) Get(p+i, Ma) / (float) MAXDEC ;
            ++i;
	    if (i < l && p[i].column == p[i-1].column) {
		f += (float) Get(p + i, Ma) * MAXVAL;
                ++i;
            }
	    total += f;
	}
    }
    return total;
}

/**
 * @brief Calculates the entropy for a matrix
 *
 * @todo Fix this documentation
 *
 *  Given the 2-dimensional contigency table this routine returns the entropy
 *  h of the whole table
 *  hx of the distribution of x (the 'row-language')
 *  hy of the distribution of y (the 'column-language')
 *  hygx of y given x, 
 *  hxgy of x given y, 
 *  the dependency uxgy of x on y
 *  the dependency uygx of y on x
 *  and the symmetrical dependency uxy
 * (see e.g. Press et al., Numerical recipes in C, 2nd edition, 1992)
 */
void MatrixEntropy(Matrix *matrix, MatrixVal Ma, double *h,
		   double *hx, double *hy, double *hygx, double *hxgy,
		   double *uygx, double *uxgy, double *uxy)
 {
    Cell *p;
    double f, *sumi, *sumj, sum;
    nat_uint32_t r, i, l;
    sum = 0.0f;
    // sumi = g_new(double, matrix->Nrows);
    sumi = (double*)malloc(sizeof(double)*matrix->Nrows);
    //sumj = g_new(double, matrix->Ncolumns);
    sumj = (double*)malloc(sizeof(double)*matrix->Ncolumns);
    for (i = 0; i <= matrix->Ncolumns; i++)
	sumj[i] = 0.0f;
    for (r = 1; r <= matrix->Nrows; r++) {
	p = matrix->rows[r].cells;
	l = matrix->rows[r].length;
	i = 0;
	sumi[r-1] = 0.0f;
	while (i <= l && p[i].column > 0) {
	    f = (double) Get(p+(i++), Ma) / (double) MAXDEC ;
	    if (i <= l && p[i].column == p[i-1].column)
		f += (double) Get(p + (i++), Ma) * MAXVAL;
	    sum += f;
	    sumi[r-1] += f;
	    sumj[p[i-1].column - 1] += f;
	}
    }
    *h = 0.0f;
    *hx = 0.0f; 
    *hy = 0.0f;
    for (r = 1; r <= matrix->Nrows; r++) {
	f = sumi[r-1] / sum; 
	if (f) *hx -= f*log(f);
    }
    for (i = 0; i < matrix->Ncolumns; i++) {
	f = sumj[i] / sum;
	if (f) *hy -= f*log(f);
    }
    for (r = 1; r <= matrix->Nrows; r++) {
	p = matrix->rows[r-1].cells;
	l = matrix->rows[r-1].length;
	i = 0;
	while (i <= l && p[i].column > 0) {
	    f = (double) Get(p+(i++), Ma) / (double) MAXDEC ;
	    if (i <= l && p[i].column == p[i-1].column)
		f += (double) Get(p + (i++), Ma) * MAXVAL;
	    if (f) {
		f /= sum;
		*h -= f*log(f);
	    }
	}
    }
    *hygx = *h - *hx;
    *hxgy = *h - *hy;
    *uygx = (*hy - *hygx) / *hy;
    *uxgy = (*hx - *hxgy) / *hx;
    *uxy = 2.0f * (*hx + *hy - *h) / (*hx + *hy);
    free(sumi);
    free(sumj); 
}

/**
 * @brief Calculates totals by columns (??)
 *
 * @todo Fix this documentation
 *
 * @param matrix the matrix to be used
 * @param Ma     (??)
 * @param cf pointer to a buffer of floats where the totals will be placed
 */
void ColumnTotals(Matrix *matrix, MatrixVal Ma, float *cf)
{
    Cell *p;
    float f;
    nat_uint32_t r, i, l;
    for (i = 1; i <= matrix->Ncolumns; i++)
	cf[i] = 0.0f;
    for (r = 1; r <= matrix->Nrows; r++) {
	p = matrix->rows[r].cells;
	l = matrix->rows[r].length;
	i = 0;
	while (i < l && p[i].column > 0) {
	    f = (float) Get(p+i, Ma) / (float) MAXDEC ;
	    if (i+1 < l && p[i+1].column == p[i].column)
		f += (float) Get(p + (++i), Ma) * MAXVAL;
	    cf[p[i].column] += f;
	    i++;
	}
    }
}

/**
 * @brief Calculates the size/memory used by a matrix
 *
 * @param matrix the matrix to analyze
 *
 * @return the memory used by matrix
 */
nat_uint32_t BytesInUse(Matrix *matrix)
{
    nat_uint32_t size = 0;
    nat_uint32_t i = 0;

    size = sizeof(Matrix) + sizeof(Row)*matrix->Nrows;
    for (i = 1; i <= matrix->Nrows; ++i) {
	size += sizeof(Cell)*matrix->rows[i].length;
    }
    return size;
}

/**
 * @brief Save the matrix to disk
 *
 * @param matrix the matrix to be saved
 * @param filename the filename of the file to be created
 *
 * @return 0 on success
 */
int SaveMatrix(Matrix *matrix, char *filename)
{
    FILE *fd;
    nat_uint32_t r, i;
    
    fd = fopen(filename, "wb");
    if (!fd) return 1;

    /*  
     * FILE IS:
     *
     * nrows
     * ncolumns
     * row1ncols col val1 val2 col val1 val2
     * row2ncols col val1 val2 col val1 val2
     */

    i = matrix->Nrows;
    if (fwrite(&i, sizeof(nat_uint32_t), 1, fd) != 1) return 1;
    i = matrix->Ncolumns;
    if (fwrite(&i, sizeof(nat_uint32_t), 1, fd) != 1) return 1;

    for (r = 1; r <= matrix->Nrows; ++r) {
	i = matrix->rows[r].length;
	if (fwrite(&i, sizeof(nat_uint32_t), 1, fd) != 1) return 1;
	if (fwrite(matrix->rows[r].cells, sizeof(Cell), i, fd) != i) return 1;
    }

    fclose(fd);
    return 0;
}

/**
 * @brief Load a matrix from disk
 *
 * @param filename the filename of the file containing the matrix
 * information
 *
 * @return the newly created Matrix structure
 */
Matrix *LoadMatrix(char *filename)
{
    Matrix *matrix;
    FILE *fd;
    nat_uint32_t r, i;
    
    fd = fopen(filename, "rb"); 
    if (!fd) {
	report_error("matrix.c: error opening file");
	return NULL;
    }
    
    /*  
     * FILE IS:
     *
     * nrows
     * ncolumns
     * row1ncols col val1 val2 col val1 val2
     * row2ncols col val1 val2 col val1 val2
     */

    //matrix = g_new(Matrix, 1);
    matrix = (Matrix*)malloc(sizeof(Matrix));
    if (!matrix) {
	report_error("matrix.c: error allocating matrix structure");
	return NULL;
    }

    if (fread(&matrix->Nrows, sizeof(nat_uint32_t), 1, fd) != 1) {
	report_error("matrix.c: error loading number of rows");
	return NULL;
    }
    if (fread(&matrix->Ncolumns, sizeof(nat_uint32_t), 1, fd) != 1) {
	report_error("matrix.c: error loading number of columns");
	return NULL;
    }
    //matrix->rows = g_new(Row, matrix->Nrows + 1);
    matrix->rows = (Row*)malloc(sizeof(Row)*(matrix->Nrows+1));
    if (!matrix->rows) {
	free(matrix);
	report_error("matrix.c: error allocating row pointers");
	return NULL;
    }

    for (r = 1; r <= matrix->Nrows; ++r) {
	if (fread(&i, sizeof(nat_uint32_t), 1, fd) != 1) {
	    /* FIXME: free previous rows */
	    free(matrix->rows);
	    free(matrix);
	    report_error("matrix.c: error reading value");
	    return NULL;
	}
	matrix->rows[r].length=i;
	//matrix->rows[r].cells = g_new(Cell, i);
	matrix->rows[r].cells = (Cell*)malloc(sizeof(Cell)*i);

	if (!matrix->rows[r].cells) {
	    report_error("matrix.c: error allocating cells memory");
	    return NULL;
	}

	/* FIXME: CHECK MALLOC */
	if (fread(matrix->rows[r].cells, sizeof(Cell), i, fd) != i) {
	    /* FIXME: free previous rows */
	    free(matrix->rows);
	    free(matrix);
	    return NULL;
	}
    }

    fclose(fd);
    return matrix;
}
