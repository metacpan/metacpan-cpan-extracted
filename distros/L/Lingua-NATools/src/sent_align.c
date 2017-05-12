/* -*- Mode: C; c-file-style: "stroustrup" -*- */

/* NATools - Package with parallel corpora tools
 * Original Implementation Copyright:
 *               Pernilla Danielsson and Daniel Ridings
 * Algorithm Copyright:
 *               William Gale and Kenneth Church
 * Copyright (C) 2002-2004  Alberto Simões
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
#include <fcntl.h>
/* #include <malloc.h> */
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <limits.h>
#include <sys/stat.h>
#include <sys/types.h>

#include "NATools.h"

/**
 * @file
 * @brief Sentence-aligner main program
 *
 * Sentence-aligner software heavily based on Pernilla Danielsson and
 * Daniel Ridings implementation of William Gale and Kenneth Church
 * sentence aligner algorithm
 *
 * The compiled program is used as
 * <pre>
 *  nat-sentence-aligner -D '.PARA' -d '.End of Sentence'  file1 file2
 * </pre>
 * where both <i>file1</i> and <i>file2</i> are tokenized and with a 
 * token per line. In the example, '.PARA' is the hard delimiter,
 * and '.End of Sentence' the soft delimiter. They are considered as
 * single tokens, and as such, should appear in a line by themselves.
 *
 * The program is allowed to delete soft delimiters as necessary in
 * order to align the files, but it cannot change hard delimiters.
 *
 * The output will be written in two files: file1.al and file2.al
 * where each one contains aligned sentences.
 *
 * For debugging it can be useful to output the data in just one file.
 * In this case, use the '-s' switch and just the 'file1.al' will be
 * created.
 *
 * @todo Check if we want to document all the functions
 */



/**
 * @brief this is an utility macro to access the dist array
 */
#define dist(x,y) distances[(x) * ((ny) + 1) + (y)]

/**
 * @brief this is an utility macro to access the pathx array
 */
#define pathx(x,y) path_x[(x) * ((ny) + 1) + (y)]

/**
 * @brief this is an utility macro to access the pathy array
 */
#define pathy(x,y) path_y[(x) * ((ny) + 1) + (y)]

/**
 * @brief Contant representing a big align distance between two
 * sentences
 */
#define BIG_DISTANCE 2500

/**
 * @brief ??
 *
 * @todo Fix-me
 */
struct alignment {
    /** Fix-me  */
    int x1;
    /** Fix-me  */
    int y1;
    /** Fix-me  */
    int x2;
    /** Fix-me  */
    int y2;
    /** Fix-me  */
    int d;
};

/**
 * @brief Contains the character used as hard delimiter (-D flag)
 */
char *hard_delimiter = NULL;	/* -D arg */

/**
 * @brief Contains the character used as soft delimiter (-d flag)
 */
char *soft_delimiter = NULL;	/* -d arg */

/**
 * @brief Contains a bool value to check if we are running in
 * verbose mode (-v flag)
 */
nat_boolean_t verbose = 0;		/* -v arg */

/**
 * @brief Contains a bool value to check if we are running in
 * debug mode (-V flag)
 */
nat_boolean_t debug = 0;                  /* -V arg */

static void show_usage(void) {
    fprintf(stderr, "usage:\n");
    fprintf(stderr, 
	    "   align_regions [-s] [-d (soft delimiter)] [-D (hard delimiter)] file1.tok file2.tok\n");
}

/* 

seq_align by Mike Riley
Sequence alignment routine.
This version allows for contraction/expansions.

x and y are sequences of objects, represented as non-zero ints, to be aligned.

dist_funct(x1, y1, x2, y2) is a distance function of 4 args:

dist_funct(x1, y1, 0, 0) gives cost of substitution of x1 by y1.
dist_funct(x1, 0, 0, 0) gives cost of deletion of x1.
dist_funct(0, y1, 0, 0) gives cost of insertion of y1.
dist_funct(x1, y1, x2, 0) gives cost of contraction of (x1,x2) to y1.
dist_funct(x1, y1, 0, y2) gives cost of expansion of x1 to (y1,y2).
dist_funct(x1, y1, x2, y2) gives cost to match (x1,x2) to (y1,y2).

align is the alignment, with (align[i].x1, align[i].x2) aligned
with (align[i].y1, align[i].y2).  Zero in align[].x1 and align[].y1
correspond to insertion and deletion, respectively.  Non-zero in
align[].x2 and align[].y2 correspond to contraction and expansion,
respectively.  align[].d gives the distance for that pairing.

The function returns the length of the alignment.

*/

static int seq_align(int *x, int *y,
		     int nx, int ny, 
		     int (*dist_funct)(),
		     struct alignment **align)
{
    int *distances, *path_x, *path_y, n;
    int i, j, oi, oj, di, dj, d1, d2, d3, d4, d5, d6, dmin;
    struct alignment *ralign;
 
    distances = (int *) malloc((nx + 1) * (ny + 1) * sizeof(int));
    path_x = (int *) malloc((nx + 1) * (ny + 1) * sizeof(int));
    path_y = (int *) malloc((nx + 1) * (ny + 1) * sizeof(int));
    ralign = (struct alignment *) malloc((nx + ny) * sizeof(struct alignment));
    
    for (j = 0; j <= ny; j++) {
	for (i = 0; i <= nx; i++) {
	    d1 = i>0 && j>0 ?		/* substitution */
		dist(i-1, j-1) + (*dist_funct)(x[i-1], y[j-1], 0, 0)
		: INT_MAX;
	    d2 = i>0 ?		/* deletion */
		dist(i-1, j) + (*dist_funct)(x[i-1], 0, 0, 0)
		: INT_MAX;
	    d3 = j>0 ?		/* insertion */
		dist(i, j-1) + (*dist_funct)(0, y[j-1], 0, 0)
		: INT_MAX;
	    d4 = i>1 && j>0 ?		/* contraction */
		dist(i-2, j-1) + (*dist_funct)(x[i-2], y[j-1], x[i-1], 0)
		: INT_MAX;
	    d5 = i>0 && j>1 ?		/* expansion */
		dist(i-1, j-2) + (*dist_funct)(x[i-1], y[j-2], 0, y[j-1])
		: INT_MAX;
	    d6 = i>1 && j>1 ?		/* melding */
		dist(i-2, j-2) + (*dist_funct)(x[i-2], y[j-2], x[i-1], y[j-1])
		: INT_MAX;
 
	    dmin = d1;
	    if (d2<dmin) dmin=d2;
	    if (d3<dmin) dmin=d3;
	    if (d4<dmin) dmin=d4;
	    if (d5<dmin) dmin=d5;
	    if (d6<dmin) dmin=d6;
 
	    if (dmin == INT_MAX) {
		dist(i,j) = 0;
	    }
	    else if (dmin == d1) {
		dist(i,j) = d1;
		pathx(i,j) = i-1;
		pathy(i,j) = j-1;
	    }
	    else if (dmin == d2) {
		dist(i,j) = d2;
		pathx(i,j) = i-1;
		pathy(i,j) = j;
	    }
	    else if (dmin == d3) {
		dist(i,j) = d3;
		pathx(i,j) = i;
		pathy(i,j) = j-1;
	    }
	    else if (dmin == d4) {
		dist(i,j) = d4;
		pathx(i,j) = i-2;
		pathy(i,j) = j-1;
	    }
	    else if (dmin == d5){
		dist(i,j) = d5;
		pathx(i,j) = i-1;
		pathy(i,j) = j-2;
	    }
	    else			/* dmin == d6 */ {
		dist(i,j) = d6;
		pathx(i,j) = i-2;
		pathy(i,j) = j-2;
	    }
	}  
    }
 
    n = 0;
    for (i=nx, j=ny ; i>0 || j>0 ; i = oi, j = oj) {
	oi = pathx(i, j);
	oj = pathy(i, j);
	di = i - oi;
	dj = j - oj;
 
	if (di == 1 && dj == 1) {  /* substitution */
	    ralign[n].x1 = x[i-1];
	    ralign[n].y1 = y[j-1];
	    ralign[n].x2 = 0;
	    ralign[n].y2 = 0;
	    ralign[n++].d = dist(i, j) - dist(i-1, j-1);
	}
 
	else if (di == 1 && dj == 0) {  /* deletion */
	    ralign[n].x1 = x[i-1];
	    ralign[n].y1 = 0;
	    ralign[n].x2 = 0;
	    ralign[n].y2 = 0;
	    ralign[n++].d = dist(i, j) - dist(i-1, j);
	}
 
	else if (di == 0 && dj == 1) {  /* insertion */
	    ralign[n].x1 = 0;
	    ralign[n].y1 = y[j-1];
	    ralign[n].x2 = 0;
	    ralign[n].y2 = 0;
	    ralign[n++].d = dist(i, j) - dist(i, j-1);
	}
 
	else if (dj == 1) {  /* contraction */
	    ralign[n].x1 = x[i-2];
	    ralign[n].y1 = y[j-1];
	    ralign[n].x2 = x[i-1];
	    ralign[n].y2 = 0;
	    ralign[n++].d = dist(i, j) - dist(i-2, j-1);
	}
 
	else if (di == 1) {    /* expansion */
	    ralign[n].x1 = x[i-1];
	    ralign[n].y1 = y[j-2];
	    ralign[n].x2 = 0;
	    ralign[n].y2 = y[j-1];
	    ralign[n++].d = dist(i, j) - dist(i-1, j-2);
	}
	else /* di == 2 && dj == 2 */ { /* melding */
	    ralign[n].x1 = x[i-2];
	    ralign[n].y1 = y[j-2];
	    ralign[n].x2 = x[i-1];
	    ralign[n].y2 = y[j-1];
	    ralign[n++].d = dist(i, j) - dist(i-2, j-2);
	}
    }
 
    *align = (struct alignment *) malloc(n * sizeof(struct alignment));
 
    for (i=0; i<n; i++)
	bcopy(ralign + i, (*align) + (n-i-1), sizeof(struct alignment));
 
    free(distances);
    free(path_x);
    free(path_y);
    free(ralign);
    return(n);
}

/* Returns the area under a normal distribution
   from -inf to z standard deviations */
static double pnorm(double z)
{
    double t, pd;
    t = 1/(1 + 0.2316419 * z);
    pd = 1 - 0.3989423 *   
	exp(-z * z/2) * 
	((((1.330274429 * t - 1.821255978) * t 
	   + 1.781477937) * t - 0.356563782) * t + 0.319381530) * t;
    /* see Gradsteyn & Rhyzik, 26.2.17 p932 */
    return(pd);
}


/* Return -100 * log probability that an English sentence of length
   len1 is a translation of a foreign sentence of length len2.  The
   probability is based on two parameters, the mean and variance of
   number of foreign characters per English character.
*/

static int match(int len1,int len2)
{
    double z, pd, mean;

    /* foreign characters per english character */
    double foreign_chars_per_eng_char = 1;

    /* variance per english character */
    double var_per_eng_char = 6.8 ;	
  
    if (len1==0 && len2==0) return(0);
    mean = (len1 + len2/foreign_chars_per_eng_char)/2;
    z = (foreign_chars_per_eng_char * len1 - len2)/sqrt(var_per_eng_char * mean);

    /* Need to deal with both sides of the normal distribution */
    if (z < 0) z = -z;
    pd = 2 * (1 - pnorm(z));

    if (pd > 0) return((int)(-100 * log(pd)));
    else return(BIG_DISTANCE);
}

static int two_side_distance(int x1, int y1, int x2, int y2)
{
    int penalty21 = 230;		/* -100 * log([prob of 2-1 match] / [prob of 1-1 match]) */
    int penalty22 = 440;		/* -100 * log([prob of 2-2 match] / [prob of 1-1 match]) */
    int penalty01 = 450;		/* -100 * log([prob of 0-1 match] / [prob of 1-1 match]) */

    if (x2 == 0 && y2 == 0)

	if (x1 == 0)			/* insertion */
	    return(match(x1, y1) + penalty01);

	else if (y1 == 0)		/* deletion */
	    return(match(x1, y1) + penalty01);

	else return (match(x1, y1)); /* substitution */

    else if (x2 == 0)		/* expansion */
	return (match(x1, y1 + y2) + penalty21);

    else if (y2 == 0)		/* contraction */
	return(match(x1 + x2, y1) + penalty21); 

    else				/* melding */
	return(match(x1 + x2, y1 + y2) + penalty22);
}

static void error(char *msg)
{
    fprintf(stderr, "**ERROR**: %s\n", msg);
    exit(2);
}

/* return the contents of the file as a string
   and stuff the length of this string into len_ptr */
static char *readchars(char *filename, int *len_ptr)
{
    FILE *fd;
    char *result;
    struct stat stat_buf;

    fd = fopen(filename, "r");
    if (fd == NULL) error("open failed");

    if (fstat(fileno(fd), &stat_buf) == -1)
	error("stat failed");
    
    *len_ptr = stat_buf.st_size;

    result = malloc(*len_ptr);
    if (result == NULL) error("malloc failed\n");

/* This doesn't work in MSDOS because of the way the GCC compiler
   handles \r\n. They are included in the file size (*len_ptr =
   stat_buf.st_size) but when the functions read a msdos text file
   they automatically strip off the \r without reading it in. Therefore
   the number of characters read and recorded will always be different
   from the exact size of the file. If you move this over to UNIX
   then uncomment the error report.
*/
    if (fread(result, sizeof(char), *len_ptr, fd) != *len_ptr) {
/*  
    err("fread failed");
*/
    }

    if (fclose(fd) == -1)
	error("fclose failed");
    return(result);
}

/* split string into a number of substrings delimited by a delimiter character
   return an array of substrings
   stuff the length of this array into len_ptr */
static char ** substrings(char *string, char *end, char delimiter, int *len_ptr)
{
    char *s, **result;
    int i = 0;

    while(string < end && *string == delimiter) string++;

    for (s = string; s < end; s++)
	if (*s == delimiter) i++;
    *len_ptr = i;
  
    result = (char **)malloc(sizeof(char *) * (i+1));
    if (result == NULL) error("malloc failed");

    i = 0;
    result[i++] = string;
    for (s = string; s < end; s++)
	if (*s == delimiter) {
	    result[i++] = s+1;
	    *s = 0;
	}
    i--; /*the last entry is beyond the end*/
    if (i != *len_ptr) {
	fprintf(stderr, "align_regions: confusion; i= %d; *len_ptr = %d\n", i, *len_ptr);
	exit(2);
    }

    return(result);
}

/* return an array of strings, one string for each line of the file
   set len_ptr to the number of lines in the file */
static char **readlines(char *filename, int *len_ptr)
{
    char *chars;
    int number_of_chars;
    chars = readchars(filename, &number_of_chars);
    return(substrings(chars, chars + number_of_chars, '\n', len_ptr));
}

/** 
 * @brief ??
 *
 * @todo Understand this
 */
struct region {
    /** ??  */
    char **lines;
    /** ??  */
    int length;
};

static void print_region(FILE *fd, struct region region, int score)
{
    char **lines, **end;

    lines = region.lines;
    end = lines + region.length;
    for ( ; lines < end ; lines++)
	fprintf(fd, "%s ", *lines);
}     

static int length_of_a_region(struct region region)
{
    int result;
    char **lines, **end;


    lines = region.lines;
    end = lines + region.length;
    result = end - lines;

    for ( ; lines < end; lines++) {
	result += strlen(*lines);
    }
    return(result);
}

static int *region_lengths(struct region *regions, int n)
{
    int i;
    int *result;

    result = (int *)malloc(n * sizeof(int));
    if (result == NULL) error("malloc failed");

    for (i = 0; i < n; i++)
	result[i] = length_of_a_region(regions[i]);
    return(result);
} 

static struct region *find_sub_regions(struct region *region, char *delimiter, int *len_ptr)
{
    struct region *result;
    char **l, **lines, **end;
    int n = 0;

    lines = region->lines;
    end = lines + region->length;

    for (l = lines; l < end; l++)
	if (delimiter && strcmp(*l, delimiter) == 0) n++;

    result = (struct region *)calloc(n+1, sizeof(struct region));
    if (result == NULL) error("malloc failed");
    *len_ptr = n;
    n = 0;
    result[0].lines = lines;
    for (l = lines; l < end; l++)
	if (delimiter && strcmp(*l, delimiter) == 0) {
	    result[n].length = l - result[n].lines;
	    result[n+1].lines = l+1;
	    n++;
	}
    result[n].length = l - result[n].lines;
    if (n != *len_ptr) {
	fprintf(stderr, "find_sub_regions: n = %d, *len_ptr = %d\n", n, *len_ptr);
	exit(2);
    }
    return(result);
}

/**
 * @brief maximum size for the output file filename
 */
#define MAX_FILENAME 256

/**
 * @brief the main...
 *
 * @todo Document all this file correctly
 */
int main(int argc, char *argv[])
{
    char **lines1, **lines2;
    int number_of_lines1, number_of_lines2;

    struct region *hard_regions1, *hard_regions2, *soft_regions1, *soft_regions2;

    struct region *hard_end1, *hard_end2, tmp;
    int number_of_hard_regions1;
    int number_of_hard_regions2;
    int number_of_soft_regions1;
    int number_of_soft_regions2;

    int *len1, *len2;

    int c, n, i, ix, iy, prevx, prevy;
    struct alignment *align, *a;

    FILE *out1, *out2 = NULL;
    char filename[MAX_FILENAME];

    int twooutputfiles = 1;
  
    extern char *optarg;
    extern int optind;

    while((c = getopt(argc, argv, "svVd:D:")) != EOF)
	switch(c) {
	case 's':
	    twooutputfiles = 0;
	    break;
	case 'V':
	    debug = 1; 		
	    /* no break */
	case 'v':
	    verbose = 1;
	    break;
	case 'd':
	    soft_delimiter = strdup(optarg);
	    break;
	case 'D':
	    hard_delimiter = strdup(optarg);
	    break;
	default:
	    show_usage();
	    exit(2);
	}

    if (argc != optind + 2) {
	show_usage();
	exit(2);
    }

    sprintf(filename, "%s.al", argv[optind]);
    out1 = fopen(filename, "w");
    if (out1 == NULL) {
	fprintf(stderr, "can't open %s\n", filename);
	exit(2);
    }
    
    if (twooutputfiles) {
	sprintf(filename, "%s.al", argv[optind+1]);
	out2 = fopen(filename, "w");
	if (out2 == NULL) {
	    fprintf(stderr, "can't open %s\n", filename);
	    exit(2);
	}
    }
    lines1 = readlines(argv[optind], &number_of_lines1);
    lines2 = readlines(argv[optind+1], &number_of_lines2);
    tmp.lines = lines1;
    tmp.length = number_of_lines1;  
    hard_regions1 = find_sub_regions(&tmp, hard_delimiter, &number_of_hard_regions1);
    tmp.lines = lines2;
    tmp.length = number_of_lines2;  
    hard_regions2 = find_sub_regions(&tmp, hard_delimiter, &number_of_hard_regions2);

    if (number_of_hard_regions1 != number_of_hard_regions2) {
	fprintf(stderr, "align_regions: input files do not contain the same number of hard regions\n");
	fprintf(stderr, "(%s)\n", hard_delimiter);
	fprintf(stderr, "%s has %d and %s has %d.\n",
		argv[optind], number_of_hard_regions1,
		argv[optind+1], number_of_hard_regions2);
	exit(2);
    }
    
    hard_end1 = hard_regions1 + number_of_hard_regions1;
    hard_end2 = hard_regions2 + number_of_hard_regions2;

    for ( ; hard_regions1 < hard_end1 ; hard_regions1++, hard_regions2++) {
	soft_regions1 = find_sub_regions(hard_regions1, soft_delimiter, &number_of_soft_regions1);
	soft_regions2 = find_sub_regions(hard_regions2, soft_delimiter, &number_of_soft_regions2);

	if (debug){
	    fprintf(out1,"Text 1:number of soft regions=%d\n",number_of_soft_regions1);
	    if (twooutputfiles) {
		fprintf(out2,"Text 2:number of soft regions=%d\n",number_of_soft_regions2);
		fflush(out1);
		fflush(out2);
	    } else {
		fprintf(out1,"Text 2:number of soft regions=%d\n",number_of_soft_regions2);
		fflush(out1);
	    }
	}

	len1 = region_lengths(soft_regions1, number_of_soft_regions1);
	len2 = region_lengths(soft_regions2, number_of_soft_regions2);


	n = seq_align(len1, len2, 
		      number_of_soft_regions1, number_of_soft_regions2,
		      two_side_distance, &align);

	prevx = prevy = ix = iy = 0;
	for (i = 0; i < n; i++) {
	    a = &align[i];
	    if (a->x2 > 0) ix++; else if (a->x1 == 0) ix--;
	    if (a->y2 > 0) iy++; else if (a->y1 == 0) iy--;
	    if (a->x1 == 0 && a->y1 == 0 && a->x2 == 0 && a->y2 == 0) {ix++; iy++;}
	    ix++;
	    iy++;

	    if (!twooutputfiles) {
		if (verbose) {fprintf(out1, ".Score %d\n", a->d);}
		fprintf(out1,"*** Link: %d - %d ***\n",(ix-prevx),(iy-prevy));
	    }
      
	    for ( ; prevx < ix; prevx++)
		print_region(out1, soft_regions1[prevx], a->d);
	    fprintf(out1, "\n");

	    if (twooutputfiles) {
		fprintf(out1, "$\n");
		for ( ; prevy < iy; prevy++)
		    print_region(out2, soft_regions2[prevy], a->d);
		fprintf(out2, "\n$\n");
	    } else {
		for ( ; prevy < iy; prevy++)
		    print_region(out1, soft_regions2[prevy], a->d);
		fprintf(out1, "\n\n");
	    }
	}

	free(align);
	free(soft_regions1);
	free(soft_regions2);
	free(len1);
	free(len2);
    }
    return 0;
}





