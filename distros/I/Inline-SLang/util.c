/****************************************************************************
 *
 * $Id: util.c,v 1.52 2005/01/03 18:04:47 dburke Exp $
 *
 * util.c
 *   Conversion routines between S-Lang and Perl data types.
 *
 ****************************************************************************/

/*
This software is Copyright (C) 2003, 2004, 2005 Smithsonian
Astrophysical Observatory. All rights are reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
02111-1307 USA

Or, surf on over to

  http://www.fsf.org/copyleft/gpl.html
*/

/*
 * Need to relook at Astro::CFITSIO to see how it handles arrays
 *
 * A note on error handling:
 *  We ignore the return value of SLang_load_string() [*] because
 *  we have installed (see BOOT: code in SLang.xs) an error
 *  handler that croak's on error with the S-Lang error message.
 *  For the code in this file it might be beneficial to use a different
 *  error handler - since if there is an error message it will not make
 *  sense to the casual user [as it will come from the mucking around
 *  we do whilst converting between S-Lang and Perl representation].
 *  However, we don't do this at the moment.
 *
 *  [* unfortunately I don't think this means we can ignore the
 *     return value of things like SLang_push_complex() ? ]
 *
 */

#include "util.h"

/* used by the CALL_xxx macros: can not be static since use in SLang.xs */
char *
_get_object_type( SV *obj ) {
  HV *stash = SvSTASH( obj ); /* assume obj really is an object */
  return ( stash ? HvNAME(stash) : "<none>" );
} /* _get_object_type() */

/*
 * since we use $1..$n to create/manipulate variables
 * it can lead to mis-leading results (ie what you think a routine
 * is doing is only happening because $1 happens to be set
 * correctly from a previous call [can happen if test set/get
 * routines next to each other].
 *
 * so, we try and clean things out (setting them to null)
 * could also free up some memory quicker
 */
void
_clean_slang_vars( int n ) {
  char stxt[12]; /* assuming n <= 99 */
  int i;
  for ( i = 1; i <= n; i++ ) {
    (void) sprintf( stxt, "$%d = NULL;", i );
    (void) SLang_load_string( stxt );
  }
} /* _clean_slang_vars() */

/* called from XS and from sl2pl.c */
SV *
_create_empty_array( int ndims, int dims[] ) {
  AV *array;
  int dimsize = dims[0] - 1;
  long i;

  /* create the array */
  array = (AV *) sv_2mortal( (SV *) newAV() );

  /* fill it in */
  if ( ndims > 0 ) {
    av_extend( array, (I32) dimsize );

    if ( ndims > 1 ) {
      for ( i = 0; i <= dimsize; i++ ) {
	av_store( array, i, _create_empty_array( ndims-1, dims+1 ) );
      }
    }
  }

  return newRV_inc( (SV *) array );

} /* _create_empty_array */
		    
/* util.c */
