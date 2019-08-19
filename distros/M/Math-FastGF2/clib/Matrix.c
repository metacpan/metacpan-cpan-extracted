/* Fast GF(2^m) library routines */
/*
  Copyright (c) by Declan Malone 2009-2019.
  Licensed under the terms of the GNU General Public License and
  the GNU Lesser (Library) General Public License.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "FastGF2.h"

/* Matrix arithmetic */
int gf2_matrix_offset_right (gf2_matrix_t *m) {

  if (m == NULL) return 0;

  switch (m->organisation) {
  case ROWWISE:
    return m->width;
  case COLWISE:
    return m->rows * m->width;
  }
  return 0;
}

int gf2_matrix_offset_down (gf2_matrix_t *m) {

  if (m == NULL) return 0;

  switch (m->organisation) {
  case ROWWISE:
    return m->cols * m->width;
  case COLWISE:
    return m->width;
  }
  return 0;
}

#ifdef NOW_IS_OK

/* 
  Misc stuff that's implemented in Perl now, but I might enable as C
  routines later
*/

OFF_T
gf2_process_streams(gf2_matrix_t *xform,
		    gf2_matrix_t *in,  
		    struct gf2_streambuf_control *fill_ctl, 
		    int fillers,
		    gf2_matrix_t *out,  
		    struct gf2_streambuf_control *empty_ctl, 
		    int emptiers,
		    OFF_T bytes_to_read) {

  OFF_T  bytes_read=0;
  int    width;

  /* variables for controlling usage of input/output buffer */
  /* All the commented-out variables are now handled in the
     gf2_streambuf_control structure on a per-stream basis. */
  char*     IR;			/* input read ptr (where we read) */
  /*  char*     IW;*/		/* input write ptr (where callback writes) */
  char*     OW;			/* output write ptr (where we write) */
  /* char*     OR; */		/* output read ptr (where callback reads) */
  /* char*     IEND; */		/* last address in input buffer */
  /* char*     OEND; */		/* last address in output buffer */

  /* 
    The following variables can vary depending on whether we have a
    single stream or multiple streams. When dealing with a single
    stream, they represent the full size of the matrix buffer, but for
    multiple streams, the values are divided by the number of streams.
  */
  OFF_T   ILEN;		/* length of input buffer */
  OFF_T   OLEN;		/* length of output buffer */
  OFF_T   IFmin;		/* input fill levels (bytes) */
  OFF_T   OFmax;		/* output fill levels (bytes) */
  OFF_T   want_in_size;	/* min input needed to process */
  OFF_T   want_out_size;	/* min amount of output space needed */

  char      eof;
  OFF_T   rc;
  OFF_T   max_fill_or_empty;
  /*  gf2_matrix_closure_t fill_some; */
  /*  gf2_matrix_closure_t empty_some; */

  /* variables for doing the matrix multiply */
  int      i,j,k;
  gf2_u32  p;
  char*    trow;
  char*    icol;
  char*    ocol;
  OFF_T    idown,iright,odown,oright,tdown,tright;

  printf ("Asked to process " OFF_T_FMT " bytes\n", bytes_to_read);

  /*
    Many checks based on code in gf2_matrix_multiply, but we have a
    few new ones
  */

  if ((in == out) || (in == xform) || (xform == out)) {
    printf("ERROR: in, out and xform must be separate matrices\n");
    return 0;
  }
  if ((in->rows != xform->cols) || (in->rows != out->rows)) {
    printf("ERROR: incompatible matrix sizes gf2_process_streams\n");
    return 0;
  }
  width=in->width;
  if ((out->width != width) || (xform->width != width)) {
    printf("ERROR: Differing element widths in gf2_process_streams\n");
    return 0;
  }
  if (((fillers == 1)  && (in->organisation != COLWISE)) ||
      ((emptiers == 1) && (out->organisation != COLWISE)) ) {
    printf("ERROR: expect single-stream buffer to be COLWISE\n");
    return 0;
  }
  if (((fillers > 1) && (in->organisation != ROWWISE)) ||
      ((emptiers > 1) && (out->organisation != ROWWISE)) ) {
    printf("ERROR: expect multi-stream buffer to be ROWWISE\n");
    return 0;
  }
  if (xform->organisation != ROWWISE) {
    printf("ERROR: expect transform matrix to be ROWWISE\n");
    return 0;
  }
  if (bytes_to_read % (width * xform->cols)) {
    printf("ERROR: number of bytes to read should be a multiple of k * s\n");
    return 0;
  }

  idown=gf2_matrix_offset_down(in);  
  iright=gf2_matrix_offset_right(in);
  odown=gf2_matrix_offset_down(out); 
  oright=gf2_matrix_offset_right(out);
  tdown=gf2_matrix_offset_down(xform); 
  tright=gf2_matrix_offset_right(xform);

  /*
    Some variables have different values depending on whether we're
    provided with a single stream or multiple streams
  */
  IFmin=0; OFmax=0;  eof=0;
  OW=out->values;
  IR=in->values;
  if (fillers == 1) {
    ILEN=in->rows * in->cols * in->width; 
    fill_ctl[0].hp.IW = in->values;
    fill_ctl[0].END   = in->values + ILEN - 1;
    fill_ctl[0].BF=0;
    want_in_size = width * in->rows;
  } else {
    ILEN=in->cols * in->width;
    for (i=0; i < fillers; ++i) {
      fill_ctl[i].hp.IW = in->values + i * ILEN;
      fill_ctl[i].END   = fill_ctl[i].hp.IW + ILEN - 1;
      fill_ctl[i].BF=0;
    }
    want_in_size = width;
  }
  if (emptiers == 1) {
    OLEN=out->rows * out->cols * out->width;
    empty_ctl[0].hp.OR = out->values;
    empty_ctl[0].END   = out->values + OLEN - 1;
    empty_ctl[0].BF=0;
    want_out_size = width * out->rows;
  } else {
    OLEN=out->cols * out->width;
    for (i=0; i < emptiers; ++i) {
      empty_ctl[i].hp.OR = out->values + i * OLEN;
      empty_ctl[i].END   = empty_ctl[i].hp.OR + OLEN - 1;
      empty_ctl[i].BF=0;
    }
    want_out_size=width;
  }

  /* printf("want_in_size is %Ld; want_out_size is %Ld\n",
      (long long) want_in_size,(long long) want_out_size); 
      printf("ILEN is %Ld; OLEN is %Ld\n",
      (long long) ILEN,(long long) OLEN); */
  do {

    while (!eof && (IFmin < want_in_size)) {

      /* 
	go through each gf2_streambuf_control struct and request more
	input. Save IFMin as the (new) minimum fill level among them.
      */
      /* printf("Need input: IFmin is %Ld\n", (long long) IFmin);   */

      for (i = 0, IFmin=ILEN; i < fillers; ++i) {
	max_fill_or_empty=ILEN - fill_ctl[i].BF;
	if (fill_ctl[i].hp.IW >= IR + i * idown) {
	  if (fill_ctl[i].hp.IW + max_fill_or_empty > 
	      fill_ctl[i].END)
	    max_fill_or_empty=fill_ctl[i].END - 
	      fill_ctl[i].hp.IW + 1;
	} else {
	  if (fill_ctl[i].hp.IW + max_fill_or_empty >= 
	      IR + i * idown) 
	    max_fill_or_empty=IR  + i * idown -
	      fill_ctl[i].hp.IW;
	}

	/* printf ("Before maxfill adjustment: " OFF_T_FMT "\n",max_fill_or_empty); */
	if (bytes_to_read && 
	    (bytes_read + fill_ctl[i].BF + max_fill_or_empty > 
	     bytes_to_read))
	  max_fill_or_empty=
	    bytes_to_read - fill_ctl[i].BF - bytes_read;

	/* printf ("Calling fill handler with maxfill " OFF_T_FMT "\n",max_fill_or_empty); */
	/* call handler */
	rc=(*(fill_ctl[i].handler.fp))
	  ( &(fill_ctl[i].handler), fill_ctl[i].hp.IW, max_fill_or_empty);

	/* check return value */
	if (rc < 0) {
	  printf ("ERROR: read error on input stream: %s\n",
	     strerror(errno)); 
	  return 0;
	} else if (rc == 0) {
	  /* printf ("Natural EOF on input stream\n");  */
	  eof++;
	} else {
	  fill_ctl[i].BF   +=rc;
	  fill_ctl[i].hp.IW+=rc;
	  if (fill_ctl[i].hp.IW > fill_ctl[i].END)
	    fill_ctl[i].hp.IW -= ILEN;
	  bytes_read+=rc;
	  /* WRONG!
	  if (bytes_to_read && 
	      (fill_ctl[i].BF + bytes_read >= bytes_to_read)) {
	    printf ("Read would exceed %lld\n",(long long) bytes_to_read);
	    eof++;
	  }
	  */
	}
	if (fill_ctl[i].BF < IFmin) 
	  IFmin=fill_ctl[i].BF;
      }

      if (eof) {
	/* printf ("EOF detected in one or more streams\n");  */
	if ((fillers > 1) && (eof % fillers)) {
	  printf ("Not all input streams of same length\n");
	  return 0;
	}
      }

    }

    /* printf("After input: IFmin is %Ld\n", (long long) IFmin);  */
    

    do {			/* loop to flush output */

      /* printf ("Checking for output space; OFmax is %Ld\n",
	 (long long) OFmax);  */
 
      /* Do we have enough space in oputput buffer to allow us to process */
      /* a chunk? If not, empty some until we do.                         */
      while ((eof && OFmax) || (OFmax + want_out_size > OLEN)) {

        /* printf ("Seems like we needed to flush\n"); */

	for (i=0,OFmax=0; i< emptiers; ++i) {

	  /* printf ("Outbuf %d is %Ld full, and OFmax is ???\n",
	     i,(long long)empty_ctl[i].BF); */

	  max_fill_or_empty=empty_ctl[i].BF;
	  if (empty_ctl[i].hp.OR >= OW + i * odown)  {
	    if (empty_ctl[i].BF + want_out_size > OLEN) {
	      max_fill_or_empty=empty_ctl[i].END - empty_ctl[i].hp.OR + 1;
	      /* printf ("Stopping overflow, max_empty is now %lld\n", 
		 (long long) max_fill_or_empty); */
	    }
	  } else {
	    if (empty_ctl[i].hp.OR + want_out_size > OW + i * odown) {
		max_fill_or_empty=OW + i * odown - empty_ctl[i].hp.OR;
		/* printf ("Stopping tail overwrite, max_empty is now %Ld\n", 
		   (long long) max_fill_or_empty);  */
	    }
	  }


	  if(max_fill_or_empty == 0) 
	    continue;
	  
	  /* call handler */
	  rc=(*(empty_ctl[i].handler.fp))
	    ( &(empty_ctl[i].handler),empty_ctl[i].hp.OR,max_fill_or_empty);
	  if (rc ==0) {
	    printf ("ERROR: write error in gf2_process_streams\n");
	    return 0;
	  }
	  empty_ctl[i].BF   -=rc;
	  empty_ctl[i].hp.OR+=rc;
	  if (empty_ctl[i].hp.OR > empty_ctl[i].END) 
	    empty_ctl[i].hp.OR -= OLEN;
	  if (empty_ctl[i].BF > OFmax) 
	    OFmax=empty_ctl[i].BF;
	}
      }

      /*
	The actual processing ... produce one column of output from
	one column of input
      */
      /* printf ("On to processing: IFmin, OFmax are (%Ld,%Ld)\n",
	 (long long) IFmin, (long long) OFmax); */

      for (k=0;			/* kolumns processed */
	   (IFmin >= want_in_size) && (OFmax + want_out_size <= OLEN);
	   ++k) {

	/* for each row of xform matrix ...*/
	for (i=0, trow=xform->values;
	     i < xform->rows ; 
	     ++i, trow += tdown ) {

	  /* multiply first row element by first column element */
	  icol=IR; ocol=OW;
	  /* gf2_multiply(OW + i *odown,trow,icol,poly,width,scratch); */
	  /* printf("{%02x}x{%02x} = {%02x}\n",
	     (unsigned char)*trow,(unsigned char)*icol,
	     (unsigned char)*(OW+i*odown));  */

	  /* then add the products of all the rest */
	  for (j=1; j < xform->cols; ++j) {
	    icol += idown; ocol+=odown;
	    /* gf2_multiply(p, trow + j * tright, icol, poly, width, scratch); */
	    /* printf("{%02x}x{%02x} = {%02x}",
	       (unsigned char)*(trow+j*tright),
	       (unsigned char)*icol,(unsigned char)*p); */
	    /* vector_xor(OW + i*odown,p,width); */
	    /* printf(" running total = {%02x}\n",
	       (unsigned char)*(OW + i*odown)); */
	  }
	  /* printf("Total: {%02x}\n",(unsigned char)*(OW + i*odown)); */
	  
	}

	/* printf ("Processed one column: IFmin, OFmax are (%Ld,%Ld)\n",
		  (long long) IFmin, (long long) OFmax); */
	IFmin-=want_in_size; OFmax+=want_out_size;
	IR+=iright;
	if (IR > fill_ctl[0].END)
	  IR=in->values;
	OW+=oright;
	if (OW > empty_ctl[0].END) 
	  OW=out->values;
	/* printf ("Moving to next column: IFmin, OFmax are (%lld, %lld)\n",
	  (long long) IFmin, (long long) OFmax); */
      }

      /* printf ("Finished processing chunk of k=%d columns\n",k);*/

      /* we've been updating IFmin and OFmax, but not the real BF
	 variables in the gf2_streambuf_control structures. We do that
	 after the processing loop is finished.
      */
      if (k) {
	for (i=0;  i < fillers; ++i) {
	  fill_ctl[i].BF -= k * want_in_size;
	}
	for (i=0; i < emptiers; ++i) {
	  empty_ctl[i].BF += k * want_out_size;
	}
      }

      /* If we're at eof here, keep looping until all output is flushed... */
      /* printf ("Finished post-processing chunks: eof, IFmin, OFmax are (%d,%lld,%lld)\n",
	 eof, (long long) IFmin, (long long) OFmax);  */

    } while (eof && OFmax);


  } while (!eof);
}


/* Create a new identity matrix or if passed an existing matrix, store
   an identity matrix in it. If matrix is passed in, any other passed
   values may be set to 0 to indicate that the values from the
   existing structure should be used. Otherwise, they should agree
   with the stored values, or else the routine returns with an error.

   Returns pointer to matrix on success, or NULL otherwise.
*/

gf2_matrix_t*
gf2_identity_matrix (gf2_matrix_t* dest, int rows, int cols, 
		     int width, int org) {

  int   i,j,k;

  if (dest == NULL) {

    if (rows != cols)                         return NULL;
    if ((rows <= 0) || (cols <= 0))	      return NULL;
    if ((width <= 0) || (width > 128))	      return NULL;
    if (org == 0)			      return NULL;

    dest=malloc(sizeof(gf2_matrix_t));
    if (dest == NULL) return NULL;

    dest->values=malloc(rows * cols * width);
    if (dest->values == NULL) {
      free(dest);
      return NULL;
    }

    dest->alloc_bits=FREE_BOTH;

    dest->rows         = rows;
    dest->cols         = cols;
    dest->width        = width;
    dest->organisation = org;

  } else {

    if (dest->rows != dest->cols)             return NULL;
    if (rows  && (dest->rows != rows))        return NULL;
    if (cols  && (dest->cols != rows))        return NULL;
    if (org   && (dest->organisation != org)) return NULL;
    if (width && (dest->rows != width))       return NULL;

    /* update local vars with values from struct */
    rows=dest->rows;
    cols=dest->cols;
    width=dest->width;

  }

  /*
    Blank matrix values, then set diagonal elements to 1.
      Since the matrix is square, we don't need to distinguish between
    ROWWISE/COLWISE organisation.
  */
  memset(dest->values, 0, rows * cols * width);
  i=0; j=width-1;
  k=(rows + 1) * width;           /* offset of next diagonal */
  do {
    (dest->values)[j]=1;	      	 /* set low byte/bit */
    j+=k;
  } while (++i < rows);

  return dest;
}

/*
  Some routines to help find the location of a given cell within the
  block allocated to the matrix and otherwise navigate within that
  block. All take account of the organisation setting for the matrix,
  where relevant. The most efficient way to navigate a matrix would be
  to write a routine which assumes a certain ROWWISE/COLWISE
  organisation. The next best would be to call gf2_matrix_offset_right
  and gf2_matrix_offset_down once in the code and then use them to
  traverse to the right/down the matrix. The least efficient way would
  be to call gf2_matrix_offset to calculate the address of the desired
  row and colum.
*/

int gf2_matrix_row_size_in_bytes (gf2_matrix_t *m) {

  if (m == NULL) return 0;

  return (m->cols * m->width);
}

int gf2_matrix_col_size_in_bytes (gf2_matrix_t *m) {

  if (m == NULL) return 0;

  return (m->rows * m->width);
}

/*
  Note we use (row, column) style rather than (x,y). Also, we return
  the address of the chosen element rather than an offset, since this
  is usually more useful. Since this is the least efficient method
  (and it's documented as such), we can afford to do some bounds
  checking here, since presumably efficiency is not the main concern.
*/
char* gf2_matrix_element (gf2_matrix_t *m, int r, int c) {
  if (m == NULL) return NULL;

  if ((r < 0) || (r >= m->rows)) return NULL;
  if ((c < 0) || (c >= m->cols)) return NULL;

  return (char*) (m + (gf2_matrix_offset_down(m) * r) +
                      (gf2_matrix_offset_right(m) * c));

}

#endif
