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

#include "matrix.h"
#include "tempdict.h"
#include "standard.h"

#include <glib.h>

/**
 * @file
 * @brief Unit to interpret sparse matrix and create a temporary dictionary
 */

/**
 * @brief Threshold for adding or not in the dictionary (was 0.1f)
 */
#define FMIN 0.005f

/**
 * @brief Main function
 *
 * Receives two file names. The input matrix file and the output
 * temporary dictionary file.
 */
int main(int argc, char **argv)
{
    Matrix* matrix;
    struct cMat2 Dictionary;
    nat_uint32_t length, k;
    float rftot, *cftot, *cf;
    nat_uint32_t r, c, Nrow, Ncolumn;
    nat_uint32_t *pc;

    if (argc != 3)
	report_error("Usage: mat2dic matrixfile_in dictfile_out");

    matrix = (Matrix*)malloc(sizeof(Matrix));
    if (!matrix) return 1;

    if (!(matrix = LoadMatrix(argv[1]))) report_error("LoadMatrix");

    Nrow = GetNRow(matrix);
    Ncolumn = GetNColumn(matrix);

    if (tempdict_allocmatrix2(&Dictionary, Nrow, Ncolumn))
	report_error("Error allocing matrix");

    cftot = g_new(float, Ncolumn + 1);
    cf    = g_new(float, Ncolumn + 1);
    pc    = g_new0(nat_uint32_t, Ncolumn + 1);

    cftot = (float *) memset(cftot, 0, (Ncolumn+1) * sizeof(float));

    fprintf(stderr, "\n");
    fprintf(stderr, "Converting matrix to dictionary:      ");
    k = 1;
    length = Nrow + 1;

    /* Calcular somatório das colunas da matrix -> cftot[1..]*/
    ColumnTotals(matrix, MATRIX_1, cftot);

    fprintf(stderr, "\b\b\b\b\b%4.1f%%", (float) (k++) * 99.9f / (float) length);
    for (r = 1; r <= Nrow; r++) {

	/* Calcular total da linha */
	/* pc -> indices de colunas */
	/* cf -> valores das celulas por coluna */
	rftot = GetRow(matrix, MATRIX_1, r, pc, cf);
	c = 0; 
	while (pc[c] > 0) {
	    if (cf[c] > rftot*FMIN || cf[c] > cftot[c] * FMIN)
		tempdict_dirtyputvalue2(&Dictionary, cf[c], r, pc[c]);
	    c++;
	}
	fprintf(stderr, "\b\b\b\b\b%4.1f%%", (float) (k++) * 99.9f / (float) length);
    }
    fprintf(stderr, "\b\b\b\b\bdone \n\n");
  
    if (tempdict_savematrix2(&Dictionary, argv[2]))
	report_error("SaveMatrix2");
    FreeMatrix(matrix);
    tempdict_freematrix2(&Dictionary);

    return 0;
}
