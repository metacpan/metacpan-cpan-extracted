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


#ifndef __MATRIX_H__
#define __MATRIX_H__


/**
 * @file
 * @brief Header file for the matrix data structure module
 */



/**
 * @brief increment value when enlarging a row. A bigger number makes
 * it slurp much more memory.  A smaller makes it slower 
 */
#define MEMBLOCK 8 

/**
 * @brief maximum value in one cell  (was 130)
 */
#define MAXVAL 2000000

/**
 * @brief number of significant decimals: 100 means 2  (was 500)
 */
#define MAXDEC 1000  


#include "standard.h"

/**
 * @brief Macro to return the number of rows from a Matrix
 */
#define     GetNRow(x)        (x->Nrows)

/**
 * @brief Macro to return the number of columns from a Matrix
 */
#define     GetNColumn(x)     (x->Ncolumns)

/**
 * @brief Matrix selector. The matrix structure stores two matrices at
 * a time.
 */
typedef enum {
    MATRIX_2 = 0,
    MATRIX_1 = 1
} MatrixVal;

/**
 * @brief Data structure for cell in the spare matrix
 */
typedef struct cCell {
    /** number of the column */
    nat_uint32_t   column;
    /** 
     * @brief value1
     *
     * @todo explain why value1 and value2
     */
    nat_uint32_t   value1;
    /** 
     * @brief value2
     *
     * @todo explain why value1 and value2
     */
    nat_uint32_t   value2;
} __attribute__((packed)) Cell;

/**
 * @brief Data structure for each sparse matrix row
 */
typedef struct cRow {
    /** number of cells */
    nat_uint32_t   length;
    /** array of cells */
    Cell     *cells;
} Row;

/**
 * @brief Main sparse matrix structure
 */
typedef struct cMatrix {
    /** number of rows in the matrix  */
    nat_uint32_t   Nrows;
    /** number of columns int the matrix  */
    nat_uint32_t   Ncolumns;
    /** array with pointers for each row information  */
    Row      *rows;
} Matrix;

Matrix*            AllocMatrix           (nat_uint32_t       Nrow,
					  nat_uint32_t       Ncolumn);

void               FreeMatrix            (Matrix       *matrix);

/*
int                PutValue              (Matrix       *matrix,
					  MatrixVal     Ma,
					  float         f,
					  nat_uint32_t       r,
					  nat_uint32_t       c);
*/

int                IncValue              (Matrix       *matrix,
					  MatrixVal     Ma,
					  float         incf,
					  nat_uint32_t       r,
					  nat_uint32_t       c);

float              GetValue              (Matrix       *matrix,
					  MatrixVal     Ma, 
					  nat_uint32_t       r,
					  nat_uint32_t       c);

Matrix*            LoadMatrix            (char         *filename);

int                SaveMatrix            (Matrix       *matrix,
					  char         *filename);

void               MatrixEntropy         (Matrix       *matrix,
					  MatrixVal     Ma, 
					  double       *h,
				 	  double       *hx,
					  double       *hy, 
					  double       *hygx,
					  double       *hxgy,
					  double       *uygx,
					  double       *uxgy,
					  double       *uxy);

float              GetRow                (Matrix       *matrix,
					  MatrixVal     Ma, 
					  nat_uint32_t       r,
					  nat_uint32_t      *c,
					  float        *f);

/*
float              GetRowMax             (Matrix       *matrix,
					  MatrixVal     Ma, 
					  nat_uint32_t       r,
					  nat_uint32_t      *c,
					  float        *f,
					  nat_uint32_t       max);
*/

/*
float              GetColumnMax          (Matrix       *matrix,
					  MatrixVal     Ma, 
					  nat_uint32_t       c,
					  nat_uint32_t      *r,
					  float        *f,
					  nat_uint32_t       max);
*/

int                GetPartialMatrix      (Matrix       *matrix,
					  MatrixVal     Ma, 
					  nat_uint32_t      *r,
					  nat_uint32_t      *c,
					  double       *M,
					  nat_uint32_t       max);

/*
int                GetConditionalMatrix  (Matrix       *matrix,
					  MatrixVal     Ma, 
					  nat_uint32_t      *r,
					  nat_uint32_t      *c,
					  float        *M,
					  nat_uint32_t       max);
*/

void               ClearMatrix           (Matrix       *matrix,
				          MatrixVal     Ma);

void               CopyMatrix            (Matrix       *matrix,
  			                  MatrixVal     Mdest);

float              CompareMatrices       (Matrix       *matrix);

/* Gives mean difference */
float              MatrixTotal           (Matrix       *matrix,
			     	          MatrixVal     Ma);

void               ColumnTotals          (Matrix       *matrix,
					  MatrixVal     Ma,
					  float        *cf);

nat_uint32_t            BytesInUse            (Matrix       *matrix);

#endif /* __MATRIX_H__ */
