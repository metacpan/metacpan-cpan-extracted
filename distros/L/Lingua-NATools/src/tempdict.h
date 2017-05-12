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

#ifndef __TEMPDICT_H__
#define __TEMPDICT_H__


/**
 * @file
 * @brief Header file for temporary dictionary created during 
 *             co-occurrence matrix interpretation
 */

/**
 * @brief ??
 *
 * @todo Understand this and document
 */
struct cItem {
    /** next column  */
    struct cItem *nextC;
    /** row number  */
    nat_uint32_t       row;
    /** column number  */
    nat_uint32_t       column;
    /** cell value  */
    nat_uint32_t       value;
} __attribute__((packed));

/**
 * @brief ??
 *
 * @todo Understand this and document
 */
struct cMat2 {
    /** Number of rows */
    nat_uint32_t        Nrows;
    /** Number of columns */
    nat_uint32_t        Ncolumns;    
    /** list of pointers to first item per row */
    struct cItem **firstR;
    /** list of pointers to first item per column */
    struct cItem **firstC;      
    /** sparse data structure */
    struct cItem *items;       
    /** bool 0 = matrix is dirty, 1 = matrix = clean */ 
    nat_boolean_t clean;       
    /** ??  */
    long          p;
    /** pointer to empty space & memory available */
    long          memory;      
};

int          tempdict_allocmatrix2(struct cMat2 *Matrix, nat_uint32_t Nrow, nat_uint32_t Ncolumn);
void         tempdict_freematrix2(struct cMat2    *Matrix);
int          tempdict_dirtyputvalue2(struct cMat2 *Matrix, float f,
                                     nat_uint32_t r, nat_uint32_t c);
float        tempdict_getrowmax2(struct cMat2 *Matrix, nat_uint32_t r, nat_uint32_t *c,
                                 float *f, nat_uint32_t max);
float        tempdict_getcolumnmax2 (struct cMat2 *Matrix, nat_uint32_t c, nat_uint32_t *r,
                                     float *f, nat_uint32_t max);
int          tempdict_loadmatrix2(struct cMat2 *Matrix, const char *filename);
int          tempdict_savematrix2(struct cMat2 *Matrix, const char *filename);

#endif
