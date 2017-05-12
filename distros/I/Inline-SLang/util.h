#ifndef SL2PL_UTIL_H
#define SL2PL_UTIL_H

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


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef I_SL_DEBUG
#  define Printf(x)	printf x
#else
#  define Printf(x)	/* empty */
#endif

/* is this correct ? */
#ifdef I_SL_FIXME
#  define fixme(x) \
         printf("FIXME at line %d\n", __LINE__); \
         printf( (x) );
#else
#  define fixme(x)     /* empty */
#endif

#include "slang.h"

/* utility functions */

/*
 *   char *_get_obj_type( SV *obj )
 *     returns a string giving the object name (or "<none>")
 *     the string does not have to be freed after use (I believe)
 */
char *_get_object_type( SV *obj );

void _clean_slang_vars( int n );
SV *_create_empty_array( int ndims, int dims[] );

/*
 * we can convert a S-Lang array into
 *
 * numeric types:
 *   perl array reference
 *   Array_Type object
 *   piddle
 *
 * non-numeric types:
 *   perl array reference
 *   Array_Type object
 */
#define I_SL_ARRAY2AREF  0
#define I_SL_ARRAY2ATYPE 1 
#define I_SL_ARRAY2PDL   (I_SL_HAVE_PDL<<1)

extern int _slang_array_format; /* declaration in SLang.xs */

/*
 * utility routines for calling Perl object methods from C
 *
 * extra_par_code is a set of XPUSHs(...) statements used to push
 * method parameters onto the stack. If there are none then use ""
 *
 * Note:
 *   these routines assume that the return value - if there is
 *   one - is going to be placed onto the Perl stack, hence they
 *   explicitly increase the reference count of the returned variable.
 *   This may turn out to be silly.
 *
 *   CALL_METHOD_VOID( SV *obj, char *method, extra_par_code )
 *     calls the method on the given object which is expected
 *     to return nothing
 *     Currently unused so commented out
 *
 *   CALL_METHOD_SCALAR_DOUBLE( SV *obj, char *method, extra_par_code, double result  )
 *     calls the method on the given object which is expected
 *     to return a double.
 *
 *   CALL_METHOD_SCALAR_SV( SV *obj, char *method, extra_par_code, SV * result )
 *     calls the method on the given object which is expected
 *     to return a SV *
 *
 * see 'perldoc perlcall' for information on what's happening here
 *
 */

/***
#define CALL_METHOD_VOID(object,method,parstring) \
 { \
  dSP; ENTER; SAVETMPS; PUSHMARK(SP); \
  XPUSHs(object); \
  parstring; \
  PUTBACK; \
  Printf( ("Calling <some object>->%s(...)\n",method) ); \
  (void) call_method( method, G_VOID ); \
  SPAGAIN; PUTBACK; FREETMPS; LEAVE; \
 }
***/

#define CALL_METHOD_SCALAR_DOUBLE(object,method,parstring,result) \
 { \
  int count; \
  dSP; ENTER; SAVETMPS; PUSHMARK(SP); \
  XPUSHs(object); \
  parstring; \
  PUTBACK; \
  Printf( ("Calling <some object>->%s(...)\n",method) ); \
  count = call_method( method, G_SCALAR ); \
  SPAGAIN; \
  if ( 1 != count ) { \
    char emsg[256]; /* if it over-runs, it over-runs */ \
    snprintf( emsg, 256, "%s->%s() did not return a value (expected double)\n", \
      _get_object_type(object), method ); \
    croak ( emsg ); \
  } \
  result = (double) POPn; \
  PUTBACK; FREETMPS; LEAVE; \
 }
   
#define CALL_METHOD_SCALAR_SV(object,method,parstring,result) \
 { \
  int count; \
  dSP; ENTER; SAVETMPS; PUSHMARK(SP); \
  XPUSHs(object); \
  parstring; \
  PUTBACK; \
  Printf( ("Calling <some object>->%s(...)\n",method) ); \
  count = call_method( method, G_SCALAR ); \
  SPAGAIN; \
  if ( 1 != count ) { \
    char emsg[256]; /* if it over-runs, it over-runs */ \
    snprintf( emsg, 256, "%s->%s() did not return a value (expected SV *)\n", \
      _get_object_type(object), method ); \
    croak ( emsg ); \
  } \
  result = SvREFCNT_inc( POPs ); /* is this correct ? */ \
  PUTBACK; FREETMPS; LEAVE; \
 }

/* macros only used in SLang.xs but placed here for convenience */

/*
 * a macro to convert the S-Lang stack to a perl one
 * - should have made it a function but since it messes
 *   around with perl stack commands (eg EXTEND()) I
 *   couldn't be bothered working out how to do that
 *
 * note the minor complication in that we have to reverse
 * the order of the stack when moving from S-Lang to perl
 *
 * The macro calls the function 'SV * sl2pl()'
 *
 * unlike Inline::Python/Ruby I always check the context
 */

/* taken from _slang.h */
extern int _SLstack_depth(void);

#define CONVERT_SLANG2PERL_STACK \
  { \
    int sdepth = _SLstack_depth(); \
    Printf( ("    *** stack depth = %d\n", sdepth) ); \
 \
    Printf( ("  checking context:\n") ); \
    Printf( ("    GIMME_V=%i\n", GIMME_V) ); \
    Printf( ("    G_VOID=%i\n", G_VOID) ); \
    Printf( ("    G_ARRAY=%i\n", G_ARRAY) ); \
    Printf( ("    G_SCALAR=%i\n", G_SCALAR) ); \
 \
    /* We can save a little time by checking our context */ \
    switch( GIMME_V ) { \
      case G_VOID: \
        /* let's clear the S-Lang stack */ \
        if ( sdepth ) { \
          Printf( ("clearing the S-Lang stack (%d items) since run in void context\n", sdepth) ); \
          if ( -1 == SLdo_pop_n( sdepth ) ) \
            croak( "Error: unable to clear the S-Lang stack\n" ); \
        } \
        XSRETURN_EMPTY; \
        break; \
 \
      case G_SCALAR: \
        if ( sdepth ) { \
          /* dump everything but the 'first' item */ \
          Printf( ("removing %d items from the stack since run in scalar context\n", \
	    sdepth-1 ) ); \
          if ( sdepth > 1 ) \
            if ( -1 == SLdo_pop_n( sdepth-1 ) ) \
              croak( "Error: unable to clear the S-Lang stack\n" ); \
 \
          Printf( ("trying to set perl stack item 0\n" ) ); \
          PUSHs( sv_2mortal( sl2pl() ) ); \
        } /* if: sdepth */ \
        break; \
 \
      case G_ARRAY: \
        /*  \
         * convert the S-Lang objects on the S-Lang stack into perl objects on  \
         * the perl stack \
         * \
         * note: the order of the S-Lang stack has to be reversed (which is why we \
         * need the slist array)  \
         */ \
        if ( sdepth ) { \
          SV **slist = NULL; \
          int i; \
 \
          Newz( 0, slist, sdepth, SV * ); \
          if ( NULL == slist ) \
            croak("Error: unable to allocate memory\n" ); /* ott ? */ \
          for ( i = sdepth-1; i >= 0; i-- ) { \
            Printf( ("reading from S-Lang stack item #%d\n", i ) ); \
            slist[i] = sl2pl(); \
          } \
 \
          /* now can stick the objects onto the perl stack */ \
          EXTEND( SP, sdepth ); \
          for ( i = 0; i < sdepth; i++ ) { \
            Printf( ("trying to set perl stack #%d\n", i ) ); \
            PUSHs( sv_2mortal( slist[i] ) ); \
          } \
 \
          Printf( ("freeing up stack-related memory\n") ); \
          Safefree( slist ); \
        } /* if: sdepth */ \
        break; \
 \
      default: \
        /* shouldn't happen with perl <= 5.8.0 */ \
        croak( "Internal error: GIMME_V is set to a value I don't understand\n" ); \
 \
    } /* switch(GIMME_V) */ \
  } /* end of macro */


/*
 * a badly-named macro
 * This is used when calling a S-Lang function whose error code we
 * should check but I'm not sure whether the error handler catches
 * the error or not. So, I've wrapped the code in a define which
 * we can easily change if the error handler works
 */
#define UTIL_SLERR( slfunc, emsg ) if ( -1 == slfunc ) croak( emsg )

#endif /* SL2PL_UTIL_H */
