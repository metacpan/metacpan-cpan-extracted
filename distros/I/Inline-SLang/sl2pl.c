/****************************************************************************
 *
 * $Id: sl2pl.c,v 1.5 2005/01/03 18:06:17 dburke Exp $
 *
 * sl2pl.c
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

#include "util.h"
#include "pdl.h"
#include "sl2pl.h"

static SV * sl2pl_type( SLtype type );

/*
 * implement support for ND arrays using a generic interface
 * - ie do not use the C API but use S-Lang itself -
 * which is not as efficient but handles everything.
 * Support for specific types can be added later if it is
 * decided to be worthwhile
 *
 * NOTE:
 *   the following algorithm is a mess since we have the array
 *   both on the stack and in C scope
 *
 * S-Lang's dimensions are stored in int arrays (at least in 1.4.9)
 *
 */
static SV *
sl2pl_array_aref( SLang_Array_Type *at ) {

  AV *aref[SLARRAY_MAX_DIMS];
  int dimsize[SLARRAY_MAX_DIMS], coord[SLARRAY_MAX_DIMS];

  SV *arrayref = NULL;

  SV *get_array_elem_sv;
  char *get_array_elem_str;
  SV *dval;

  SLtype dtype = at->data_type;
  int    nelem = at->num_elements;
  int    ndims = at->num_dims;
  int   *dims  = at->dims;

  int maxdim = ndims - 1;
  int i, j;

  /*
   * set up the arrays for the loop
   *  1 - the actual data array
   *  2 - the arrays used to loop through it
   */
  arrayref = _create_empty_array( ndims, dims );

  for ( i = 0; i < ndims; i++ ) {
    Printf( ("  *** dimension %d has size %d\n",i,dims[i]) );
    coord[i]   = 0;
    dimsize[i] = dims[i] - 1;
    if ( i )
      aref[i] = (AV *) SvRV( *av_fetch( aref[i-1], 0, 0 ) );
    else
      aref[i] = (AV *) SvRV( arrayref );
  } 

  /*
   * this is truly not wonderful: set up the string that
   * pops the array and coordinates off the
   * S-Lang stack and returns the value of the corresponding array element
   * - *and* I'm too lazy to do this in C!
   */
  Printf( ("Calling Array_Type::_private_get_read_string(%d)\n",maxdim) );
  {
    int count;
    dSP; ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs( sv_2mortal(newSViv(maxdim)) );
    PUTBACK;
    count = call_pv( "Array_Type::_private_get_read_string", G_SCALAR );
    SPAGAIN;
    if ( 1 != count )
      croak( "Internal error: unable to call _private_get_read_string()\n" );
    get_array_elem_sv = SvREFCNT_inc( POPs );
    PUTBACK; FREETMPS; LEAVE;
  }
  get_array_elem_str = SvPV_nolen(get_array_elem_sv);
  Printf( ("get str = [%s]\n",get_array_elem_str) );

  /*
   * We need the array in $1 with the current code,
   * so we have to push it back onto the stack but we do NOT
   * free at
   */
  UTIL_SLERR(
    SLang_push_array( at, 0 ),
    "Internal error - unable to push array onto the S-Lang stack"
  );
  (void) SLang_load_string( "$1=();" );

  /*
   * loop i=1 to nelem - see pl2sl_array() for more details
   */
  for ( i = 1; i < nelem; i++ ) {
    Printf( ("  **** Setting %dD array elem %d coord=[",ndims,i) );

    /*
     * since we are about to call sl2pl() we push $1 onto the stack
     * to protect it. Then we push the coordinates, and then the
     * current data value
     */
    for( j = 0; j < ndims; j++ ) {
      Printf( (" %d",coord[j]) );
      UTIL_SLERR(
	SLang_push_integer(coord[j]),
        "Internal error: unable to push onto the stack"
      );
    }
    Printf( (" ] and coord[maxdim] = %d\n",coord[maxdim]) );

    /* now get the value, convert to Perl, and store [also pushes array onto stack] */
    (void) SLang_load_string( get_array_elem_str );
    dval = sl2pl_type( dtype );
    av_store( aref[maxdim], coord[maxdim], dval );

    /* restore $1 to be the array */
    (void) SLang_load_string( "$1=();" );

    /* update the pointer */
    if ( coord[maxdim] < dimsize[maxdim] ) coord[maxdim]++;
    else {
      Printf( ("+++ start: loop to upate coords/array refs\n") );
      /*
       * loop through each previous coord until we find
       * one with 'coord[j] < dimsize[j]', increase it
       * and then reset the 'higher dim' coord/aref values
       */
      j = maxdim - 1;
      while ( coord[j] == dimsize[j] ) { j--; }
      Printf( ("++++++++ got to dim #%d with coord=[%d]\n",j,coord[j]) );
      coord[j]++;
      if ( j )
        aref[j] = (AV *) SvRV( *av_fetch( aref[j-1], coord[j-1], 0 ) );
      j++;
      while ( j <= maxdim ) {
	Printf( ("++++++ resetting dim #%d from %d to 0 (prev dimension val=%d)\n",
		 j,coord[j],coord[j-1]) );
	coord[j] = 0;
	aref[j] = (AV *) SvRV( *av_fetch( aref[j-1], coord[j-1], 0 ) );
	j++;
      }
      Printf( ("+++ finished coords/array refs update\n") );
    } /* if: coord[maxdim] == dimsize[maxdim] */

  } /* for: i=1 .. nelem-1 */

  /* handle the last element */
  Printf( ("  **** Setting %dD array elem %d coord=[",ndims,nelem) );
  for( j = 0; j <= maxdim; j++ ) {
    Printf( (" %d",coord[j]) );
    UTIL_SLERR(
      SLang_push_integer(coord[j]),
      "Internal error: unable to push onto the stack"
    );
  }
  Printf( (" ] [[last element]]\n") );

  /* now get the value, convert to Perl, and store */
  (void) SLang_load_string( get_array_elem_str );
  dval = sl2pl_type( dtype );
  av_store( aref[maxdim], coord[maxdim], dval );
  (void) SLang_load_string("$1=();"); /* clean up the stack */

  _clean_slang_vars(maxdim+2);
  SvREFCNT_dec( get_array_elem_sv );
  return arrayref;

} /* sl2pl_array_aref() */

/*
 * to reduce replicated code we delegate most of the conversion
 * to sl2pl_array_aref() and then convert the array reference into
 * an Array_Type object. It's somewhat wasteful since we have
 * to find the dimensions and datatype again (especially as I'm
 * just relying on sl_array() to do this in Perl).
 */
static SV *
sl2pl_array_atype( SLang_Array_Type *at ) {
  SV *aref = sl2pl_array_aref(at);
  SV *obj;

  /***
      Should create the dims and datatype values and send to sl_array
      so that things are converted properly (otherwise
      UChar_Type -> Integer_Type etc)
  ***/

  Printf( ("Calling Inline::SLang::sl_array() to convert to Array_Type\n") );
  {
    int count;
    dSP; ENTER; SAVETMPS; PUSHMARK(SP);
    fixme( "memleaks?" );
    //    XPUSHs( sv_2mortal(newSViv(maxdim)) );
    XPUSHs( aref );
    XPUSHs( sv_2mortal(newSVpv(SLclass_get_datatype_name(at->data_type),0)) );
    PUTBACK;
    count = call_pv( "Inline::SLang::sl_array", G_SCALAR );
    SPAGAIN;
    if ( 1 != count )
      croak( "Internal error: unable to call Inline::SLang::sl_array()\n" );
    fixme( "memleak?" );
    obj = SvREFCNT_inc( POPs );
    PUTBACK; FREETMPS; LEAVE;
  }

  return obj;
} /* sl2pl_array_atype() */

static SV *
sl2pl_array( void ) {

  SV *out;
  SLang_Array_Type *at = NULL;

  Printf( ("  S-Lang stack contains: array  ") );

  UTIL_SLERR(
	     SLang_pop_array( &at, 0 ),
	     "Internal error - unable to pop duplicated array off the stack"
	     );
  Printf( (" num dims=%d  nelem=%d  type=%s\n",
	   at->num_dims, at->num_elements,
	   SLclass_get_datatype_name(at->data_type)) );

  /*
   * Output is one of the following - determined by the
   * value of the variable _slang_array_format:
   *
   *       Non-numeric        Numeric
   *   0 - array ref          -
   *   1 - Array_Type         -
   *   2 - array ref          piddle
   *   3 - Array_Type         piddle
   *
   * could do comparison by bit manipulation
   */

  switch ( _slang_array_format ) {
  case 0:
    out = sl2pl_array_aref( at );
    break;

  case 1:
    out = sl2pl_array_atype( at );
    break;

  case 2:
#if I_SL_HAVE_PDL == 1
    if ( IS_CONVERTABLE_TO_PDL(at->data_type) )
      out = sl2pl_array_pdl( at );
    else
#endif
      out = sl2pl_array_aref( at );
    break;

  case 3:
#if I_SL_HAVE_PDL == 1
    if ( IS_CONVERTABLE_TO_PDL(at->data_type) )
      out = sl2pl_array_pdl( at );
    else
#endif
      out = sl2pl_array_atype( at );
    break;

  } /* switch: _slang_array_format */

  /*
   * can free up the array now (although will want to keep it around
   * once [if?] we re-implement the type-specific routines)
   */
  SLang_free_array( at );

  return out;

} /* sl2pl_array() */

/*
 * use a tied hash to represent a S-Lang structure
 * - see also Struct_Type
 */
static SV *
sl2pl_assoc( void ) {

  SLang_Array_Type *keys = NULL;
  SV *tied_object, *object;
  HV *hash;
  char *typename, *keyname;
  int i;

  Printf( ("  stack contains an associative array\n") );

  /*
   * use S-Lang to parse the Associative array
   * (approach suggested by John Davis) since there isn't
   * a public C API for them (ie internals liable to change)
   */
  (void) SLang_load_string( "$1=();assoc_get_keys($1);" );
  UTIL_SLERR(
	     SLang_pop_array( &keys, 0 ),
	     "Internal error: unable to pop keys array off the stack\n"
	     );
  
  (void) SLang_load_string( "string(_typeof(assoc_get_values($1)));" );
  UTIL_SLERR(
	     SLang_pop_slstring( &typename ),
	     "Internal error: unable to pop string off the S-Lang stack\n"
	     );
  Printf( (">> Assoc_Array has type = [%s]\n",typename) );
  CALL_METHOD_SCALAR_SV( sv_2mortal(newSVpv("Assoc_Type",0)), 
			 "new", C2PL_MARG_S(typename);, tied_object );
  SLang_free_slstring(typename);

  /*
   * get a reference to the hash which is actually storing the data
   */
  CALL_METHOD_SCALAR_SV( tied_object, "_private_get_hashref", , object );
  object = sv_2mortal( object );
  hash = (HV *) SvRV( object );
  
  /*
   * loop through each element, converting the values to Perl types
   * NOTE:
   *   previously converted all the field values to Perl in one go
   *   but as I'm planning to change the array handling to use
   *   tied arrays and I don't understand how to access them from
   *   C I'm doing them one at a time
   * (08/18/03 DJB - not sure how much of this statement remains true)
   */
  Printf( ("About to loop through the Assoc array keys [nelem=%d]\n",
	   keys->num_elements) );
  for ( i = 0; i < keys->num_elements; i++ ) {
    SV *value;
    
    /* get the key */
    (void) SLang_get_array_element( keys, &i, &keyname );
    Printf( ( "assoc array key = [%s]\n", keyname ) );

    /* convert the value from the S-Lang array - leave on stack */
    UTIL_SLERR(
	       SLang_push_string(keyname),
	       "Internal error during conversion of S-Lang Assoc_Array to Perl\n"
	       );

    /*
     * since the sl2pl() call may invalidate the value of $1
     * we cheat and stick $1 onto the S-Lang stack as well as
     * the value of the key we're interested in so that we can
     * reset $1 after the call to sl2pl()
     * THIS IS NOT MEMORY/TIME EFFICIENT !
     */
    (void) SLang_load_string( "$2 = (); $1; $1[$2];" );
    value = sl2pl();
    (void) SLang_load_string( "$1 = ();" );
    
    /* store in the hash */
    hv_store( hash, keyname, strlen(keyname), value, 0 );

    SLang_free_slstring( keyname ); // is this necessary?
  } /* for: i = 0 .. num_elements-1 */

  /* free up memory */
  _clean_slang_vars(2);
  SLang_free_array( keys );
  Printf( ("freed up keys array (S-Lang)\n") );

  return tied_object;

} /* sl2pl_assoc() */

/*
 * Convert S-Lang structs - including type-deffed ones
 * to Perl <> objects
 *
 * If we were just bothered about S-lang structs - ie not the
 * type-deffed ones - then we could just have this code directly
 * in sl2pl() within a "case SLANG_STRUCT_TYPE: {}".
 * However, as I don't know how we can easily tell whether an
 * item on the S_Lang stack is a type-deffed structure we go
 * with this method
 *
 * We are called with a S-Lang structure in $1
 */
static SV *
sl2pl_struct(void) {
  char *stype;
  SV *tied_object, *object;
  HV *hash;
  SV *fieldsref;
  AV *fields;
  int i, nfields;
  int a2p_flag;

  Printf( ("  stack contains: structure - ") );

  /*
   * get the Perl class name for this structure
   * (let S-Lang bother with the string handling)
   */
  (void) SLang_load_string( "string(typeof($1));" );
  UTIL_SLERR(
    SLang_pop_slstring(&stype), 
    "Error: unable to get datatype of a structure\n"
  );
  Printf( ("it's type is %s\n",stype) );

  /*
   * - handle similarly to associative arrays, in that
   *   we take advantage of the S-Lang stack
   * - can't guarantee that $1 isn't going to get trashed when
   *   converting the array of strings, so we push it on
   *
   */
  (void) SLang_load_string( "$1;get_struct_field_names($1);" );

  /*
   * convert the item on the stack (ie the field names) to a perl array
   *
   * NOTE:
   *   since we are going to convert an array from S-Lang to
   *   Perl we need to ensure that we do it as a array ref
   *   whatever the user actually wants (and set it back later)
   */
  a2p_flag = _slang_array_format;
  _slang_array_format = 0;
  fieldsref = sv_2mortal( sl2pl() );
  _slang_array_format = a2p_flag;
  fields = (AV *) SvRV( fieldsref );
  nfields = 1 + av_len( fields );
  Printf( ("Number of fields in the structure = %d\n", nfields ) );

  (void) SLang_load_string( "$1=();" );

  /*
   * create the <XXX> object and then get the underlying structure
   * used to implement the tied hash. object is a reference to the
   * hash that stores the data [ie it's not the full Struct_Type
   * implementation 'object' which is an array reference]
   */
  CALL_METHOD_SCALAR_SV( sv_2mortal(newSVpv(stype,0)), 
			 "new", XPUSHs(fieldsref);, tied_object );
  CALL_METHOD_SCALAR_SV( tied_object, "_private_get_hashref", , object );
  object = sv_2mortal( object );
  hash = (HV *) SvRV( object );

  /*
   * loop through each field: push its value onto the S-Lang stack, convert
   * it to a Perl SV *, and store in the Perl hash
   *
   * Since we call sl2pl() - which may trash $1 - we need to protect the value
   * in $1 by pushing it onto the stack prior to the sl2pl() call and then
   * popping it back again afterwards. Not really memory/time efficient
   */
  for ( i = 0; i<nfields; i++ ) {
    SV **name;
    SV *value;
    char *fieldname;
    
    /* get the field name */
    name = av_fetch( fields, (I32) i, 0 );
    fieldname = SvPV_nolen( *name );
    Printf( ("struct field name %d/%d = [%s]\n", i, nfields-1, fieldname) );

    UTIL_SLERR(
      SLang_push_string( fieldname ),
      "Internal error - Unable to push name of struct field onto stack"
    );
    (void) SLang_load_string( "$2=(); $1; get_struct_field($1,$2);" );
    value = sl2pl();

    /*
     * if value = undef [ie S-Lang value == NULL] then leave alone
     * since calling hv_store with an undef value seems to delete
     * the key from the hash
     *
     * should we check for failure/NULL from hv_store?
     */
    if ( SvOK(value) )
      hv_store( hash, fieldname, strlen(fieldname), value, 0 );
    else
      SvREFCNT_dec( value );

    (void) SLang_load_string( "$1=();" );

    Printf( ("  and finished with struct field %d/%d [%s]\n", i, nfields-1,
	     fieldname) );

  } /* for: i */
  
  /* free up memory/clean-up vars */
  SLang_free_slstring( stype );
  _clean_slang_vars(2);
  return tied_object;

} /* sl2pl_struct() */

/*
 * Handle S-Lang variables for which we 
 * consider the type to be "opaque" in Perl scope - ie
 * you can assign it to a variable and send it back to S-Lang
 * but there's not a lot else you can do with it.
 * To do this we store the variable in the _inline namespace
 * and return the index string for that variable. This
 * variable gets converted to a Perl object of class
 * <typeof S-Lang variable>, which inherits
 * from Inline::SLang::_Type.
 * See the definition of the _inline namespace in SLang.pm
 * (created during the load phase of processing)
 *
 * We are called with a S-Lang variable in $1
 */
static SV *
sl2pl_opaque(void) {
  char *sltype;
  char *slkey;
  SV *perlobj;

  (void) SLang_load_string( "_inline->_store_data( $1 );" );
  UTIL_SLERR(
     SLang_pop_slstring(&slkey),
    "Error: unable to store S-Lang data"
  );
  UTIL_SLERR(
     SLang_pop_slstring(&sltype),
    "Error: unable to store S-Lang data"
  );
  _clean_slang_vars(1);
  Printf( ("Storing S-Lang type %s using key %s\n", sltype, slkey) );

  /*
   * Now create an object of the right type
   */
  CALL_METHOD_SCALAR_SV(
			sv_2mortal(newSVpv(sltype,0)),
			"new",
			C2PL_MARG_S( slkey ),
			perlobj );
  return perlobj;

} /* sl2pl_opaque() */

/*
 * convert S-Lang variables to perl variables
 */

static SV *
sl2pl_type( SLtype type ) {

  /*
   * handle the various types
   * - having separate items for all the "integer" types is
   *   probably OTT
   */
  switch( type ) {

  case SLANG_NULL_TYPE:
    /* return an undef */
    Printf( ("  stack contains: NULL\n") );
    /* clear the stack of the NULL type variable (assume it works) */
    (void) SLdo_pop_n(1);
    return &PL_sv_undef;
    break;

    /* integers */
    SL2PL_ITYPE( CHAR,  char,    char )
    SL2PL_ITYPE( SHORT, short,   short )
    SL2PL_ITYPE( INT,   integer, int )
    SL2PL_ITYPE( LONG,  long,    long )

  case SLANG_FLOAT_TYPE:
    {
      float fval;
      UTIL_SLERR(
	SLang_pop_float( &fval ),
	"Error: unable to read float value from the stack\n"
      );
      Printf( ("  stack contains: float = %g\n", fval ) );
      return newSVnv(fval);
    }

  case SLANG_DOUBLE_TYPE:
    {
      double dval;
      UTIL_SLERR(
	SLang_pop_double( &dval, NULL, NULL ),
	"Error: unable to read double value from the stack\n"
      );
      Printf( ("  stack contains: double = %g\n", dval ) );
      return newSVnv(dval);
    }

  case SLANG_STRING_TYPE:
    {
      SV *out;
      char *sval;
      UTIL_SLERR(
        SLang_pop_slstring(&sval),
	"Error: unable to read a string from the stack\n"
      );
      Printf( ("  stack contains: string = %s\n", sval ) );
      out = newSVpv( sval, 0 );
      SLang_free_slstring( sval );
      return out;
    }

  case SLANG_COMPLEX_TYPE:
    {
      /*
       * store as a Math::Complex object
       */
      SV *object;
      double real, imag;

      UTIL_SLERR(
        SLang_pop_complex( &real, &imag ),
	"Error: unable to read complex value from the stack\n"
      );
      Printf( ("  stack contains: complex %g + %g i\n", real, imag ) );

      CALL_METHOD_SCALAR_SV(
       	 sv_2mortal(newSVpv("Math::Complex",0)),
         "make",
	 C2PL_MARG_D( real ); C2PL_MARG_D( imag );,
         object );

      return object;

    } /* COMPLEX */

  case SLANG_ARRAY_TYPE:
    return sl2pl_array();
    break;

  case SLANG_ASSOC_TYPE:
    return sl2pl_assoc();
    break;

  case SLANG_DATATYPE_TYPE:
    {
      char *dname;
      SLtype dtype;

      /*
       * store the datatype value as a string of the name,
       * into an DataType_Type object
       */
      Printf( ("  stack contains: a S-Lang datatype object\n") );
      UTIL_SLERR(
		 SLang_pop_datatype( &dtype ),
		 "Internal error - unable to pop datatype off the stack"
		 );
      Printf( ("  - value == %d\n", (int) dtype) );

      dname = SLclass_get_datatype_name( dtype );
      Printf( ("  - name  == %s\n", dname) );

      /* if use newRV [== newRV_inc] then this leaks memory */
      return
	sv_bless(
		 newRV_noinc( newSVpv(dname,0) ),
		 gv_stashpv("DataType_Type",1)
		 );
      break;

    } /* DATATYPE */

  default:
    {
      /*
       * There are 2 cases:
       *  - a struct, including type-deffed ones
       *  - everything else
       *
       * Important that $1 left as value since needed by sl2pl_struct|opaque
       * routines
       */
      int is_struct;
      (void) SLang_load_string( "$1 = (); is_struct_type($1);" );
      UTIL_SLERR(
		 SLang_pop_integer( &is_struct ),
		 "Error: unable to pop an item from the S-Lang stack"
		 );

      if ( is_struct ) return sl2pl_struct();
      else             return sl2pl_opaque();

    } /* default */
  }

} /* sl2pl_type() */

/*
 * convert the object on the S-Lang stack to
 * a perl object.
 *
 * The use of the S-Lang stack may limit recursion,
 * but it's easy to stick values back onto the S-Lang
 * stack. In fact, we make use of this when processing
 * certain types.
 */

SV *
sl2pl( void ) {

  /* should we really be using SLtype instead of int? */
  int type = SLang_peek_at_stack();
  return sl2pl_type( type );

} /* sl2pl() */
