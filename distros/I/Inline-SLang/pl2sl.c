/****************************************************************************
 *
 * $Id: pl2sl.c,v 1.5 2005/01/03 18:07:20 dburke Exp $
 *
 * pl2sl.c
 *   Conversion routines between Perl and S-Lang data types.
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
#include "pl2sl.h"

static void pl2sl_type( SV *item, SLtype item_type, int item_flag );

/*
 * Usage:
 *   SLtype = pltype( SV *val, int *flag )
 *
 * Aim:
 *   Given a Perl object (as a SV *), return the approproiate
 *   S-Lang type (as a SLtype value) for it. flag is an output
 *   variable -
 *     if 1 then the SLtype should be considered to mean just that,
 *     if 0 then it indicates a "special" meaning
 *     (used by assoc/array types)
 *
 * Notes:
 *   Initial version - needs thinking/work
 *
 *   - probably important to do integer/double/string check in
 *     that order due to Perl's DWIM-ery wrt types
 *
 * used by _guess_type in SLang.xs so can't be static
 */
SLtype
pltype( SV *plval, int *flag ) {

  *flag = 1;

  /* before we do any checks ensure we have something to check */
  if ( !SvOK(plval) ) return SLANG_NULL_TYPE;

  if ( SvROK(plval) ) {

    /*
     * assume that if an object we either know what to do
     * or it can't be converted
     */
    if ( sv_isobject(plval) ) {

      if ( sv_derived_from(plval,"Math::Complex") ) return SLANG_COMPLEX_TYPE;
      if ( sv_derived_from(plval,"DataType_Type") ) return SLANG_DATATYPE_TYPE;
      if ( sv_derived_from(plval,"Struct_Type") )   return SLANG_STRUCT_TYPE;
      if ( sv_derived_from(plval,"Assoc_Type") )    return SLANG_ASSOC_TYPE;
      if ( sv_derived_from(plval,"Array_Type") )    return SLANG_ARRAY_TYPE;

      /* need to extend the meaning of the flag field */
      if ( sv_derived_from(plval,"PDL") ) {
	*flag = 2;
	return SLANG_ARRAY_TYPE;
      }

      /*
       * run out of specific types
       *  - indicate this by returning SLANG_UNDEFINED_TYPE 
       *    but with a flag of 0
       */
      if ( sv_derived_from(plval,"Inline::SLang::_Type") ) {
	*flag = 0;
	return SLANG_UNDEFINED_TYPE;
      }
      
    } else {
      SV *ref = SvRV(plval);

      if ( SvTYPE(ref) == SVt_PVHV ) { *flag = 0; return SLANG_ASSOC_TYPE; }
      if ( SvTYPE(ref) == SVt_PVAV ) { *flag = 0; return SLANG_ARRAY_TYPE; }
  
    }

  } else {
    /* not a reference */
    if ( SvIOK(plval) ) return SLANG_INT_TYPE;
    if ( SvNOK(plval) ) return SLANG_DOUBLE_TYPE;
    if ( SvPOK(plval) ) return SLANG_STRING_TYPE;

  }

  croak( "Sent a perl type that can not be converted to S-Lang." );

} /* pltype() */

/*
 * pl2sl_assoc_intenal( HV *hash )
 * - called by pl2sl_assoc()
 * - this does the actual conversion
 */
static void
pl2sl_assoc_internal( HV *hash ) {
  I32 nfields, i;

  /*
   * loop through the keys in the Perl hash and set the corresponding 
   * value in the S-Lang Assoc_Type array
   */
  nfields = hv_iterinit( hash );
  Printf( ("  hash ref contains %d fields\n",nfields) );
  for ( i = 0; i < nfields; i++ ) {
    SV *value;
    char *fieldname;
    I32 ignore;

    /* get the next key/value pair from the hash */
    value = hv_iternextsv( hash, &fieldname, &ignore );
    Printf( ("  - field %d/%d name=[%s]\n",i,nfields-1,fieldname) );

    /* 
     * push $1 [in case pl2sl() trashes it], the field name,
     * and then the Perl value (converted to S-Lang) onto the
     * S-Lang stack
     *
     * TODO: [low priority enhancement]
     *   we know the type of the variable we are converting to
     *   so we could save some time by calling the correct part
     *   of pl2sl(). Although not sure about Any_Type arrays
     *   in this scheme.
     */
    (void) SLang_load_string( "$1;" );
    UTIL_SLERR(
      SLang_push_string( fieldname ),
      "Unable to push a string onto the stack"
    );
    pl2sl( value );

    /*
     * this sort of a call can leak mem prior to S-Lang < 1.4.9 but I think we're
     * okay with this version. Any mem leaks in the struct code should first
     * check that S-Lang lib >= 1.4.9
     */
    (void) SLang_load_string( "$3=(); $2=(); $1=(); $1[$2] = $3;" );
    
  }

  SL_PUSH_ELEM1_ONTO_STACK(3);
  return;

} /* pl2sl_assoc_internal() */

/*
 * pl2sl_assoc( SV *item, int item_flag )
 */
static void
pl2sl_assoc( SV *item, int item_flag ) {

  HV *hash;

  if ( item_flag ) {
    SV *typename;
    SV *object;
    Printf( ("*** converting Perl Assoc_Type object to S-Lang\n") );
    
    /*
     * create the array with the correct type
     *
     * TODO: [low priority]
     *   Newz() to create a char * large enough to contain
     *     '$1 = Assoc_Type[%s];', typename
     *   and then SLang_load_string() that
     */
    CALL_METHOD_SCALAR_SV( item, "_private_get_typeof", , typename );
    Printf( ("  assoc type = [%s]\n", SvPV_nolen(typename)) );
    (void) SLang_load_string( SvPV_nolen(typename) );
    (void) SLang_load_string( "$2=(); $1 = Assoc_Type [$2];" );
    SvREFCNT_dec( typename );
    
    /*
     * get the hash used to store the actual data
     */
    CALL_METHOD_SCALAR_SV( item, "_private_get_hashref", , object );
    object = sv_2mortal( object );
    hash = (HV *) SvRV( object );
    
  } else {
    /*
     * hash ref: follow Assoc_Type object handling above - we convert
     * to an 'Assoc_Type [Any_Type];' array since we can't be sure
     * about the type without looping through all the keys
     */
    Printf( ("*** converting Perl {...} object to S-Lang\n") );
    
    /* create the assoc array in $1 */
    (void) SLang_load_string( "$1 = Assoc_Type [Any_Type];" );
    
    /* iterate through the hash, filling in the values */
    hash = (HV*) SvRV( item ); // sv_2mortal ???
    
  }
  
  /* and delegate all the complicated stuff */
  pl2sl_assoc_internal( hash );
  
} /* pl2sl_assoc() */

/*
 * pl2sl_struct()
 */
static void
pl2sl_struct( SV *item ) {

  SV *dstruct;
  SV *object;
  HV *hash;
  I32 nfields, i;

  Printf( ("*** converting Perl struct to S-Lang\n") );

  /*
   * create a structure in $1 with the correct fields
   * - once the string has been used we can decrease the
   *   reference count to ensure it is freed
   */
  CALL_METHOD_SCALAR_SV( item, "_define_struct", , dstruct );
  Printf( ("struct definition =\n[%s]\n", SvPV_nolen(dstruct)) );
  (void) SLang_load_string( SvPV_nolen(dstruct) );
  SvREFCNT_dec( dstruct );

  /*
   * get the hash used to store the actual data
   */
  CALL_METHOD_SCALAR_SV( item, "_private_get_hashref", , object );
  object = sv_2mortal( object );
  hash = (HV *) SvRV( object );

  /*
   * loop through the keys in the Perl hash and set the corresponding 
   * value in the S-Lang struct
   */
  nfields = hv_iterinit( hash );
  Printf( ("  struct contains %d fields\n",nfields) );
  for ( i = 0; i < nfields; i++ ) {
    SV *value;
    char *fieldname;
    I32 ignore;

    /* get the next key/value pair from the hash */
    value = hv_iternextsv( hash, &fieldname, &ignore );
    Printf( ("  - field %d/%d name=[%s]\n",i,nfields-1,fieldname) );

    /* 
     * push $1 [in case pl2sl() trashes it], the field name,
     * and then the Perl value (converted to S-Lang) onto the
     * S-Lang stack
     */
    (void) SLang_load_string( "$1;" );
    UTIL_SLERR(
	       SLang_push_string( fieldname ),
	       "Unable to push a string onto the stack"
	       );
    pl2sl( value );

    /*
     * this sort of a call can leak mem prior to S-Lang < 1.4.9 but I think we're
     * okay with this version. Any mem leaks in the struct code should first
     * check that S-Lang lib >= 1.4.9
     */
    (void) SLang_load_string(
			     "$3=(); $2=(); $1=(); set_struct_field( $1, $2, $3 );"
			     );

  }

  SL_PUSH_ELEM1_ONTO_STACK(3);
  return;

} /* pl2sl_struct() */

/*
 * pl2sl_array_internal()
 * must be called with the S-Lang array in $1
 * - originally had hard-coded 1/2D routines and a generic
 *   support system for up to 7D data structure.
 *   Have moved to just using the generic system.
 *   The plan is to add support for arrays of particular
 *   types - ie those with a C API - and it's easier if
 *   we only have to code them once.
 *
 * Note:
 *   this is being written in such a way as to force users to use
 *   piddles for arrays wherever possible!
 *
 */
static void
pl2sl_array_internal( AV *array, AV *dims ) {
  long dimsize[SLARRAY_MAX_DIMS], coord[SLARRAY_MAX_DIMS];
  AV *aref[SLARRAY_MAX_DIMS];

  SV *set_array_elem_sv;
  char *set_array_elem_str;
  SV **dval;

  long nelem;
  I32 maxdim, i, j;

  SLtype sl_type;
  int sl_flag;

  maxdim = av_len( dims ); /* count from 0 */

  /*
   * I think S-Lang arrays are limited to <= 7 [SLARRAY_MAX_DIMS]
   * - left check in in case this changes (the reason why we are
   *   limited to 7 is that we need to use 2 $x (ie temp) vars
   *   for the array and the value, which leaves a max of 7 for
   *   coordinates
   */
  Printf( ("  * converting %dD Array_Type array to S_Lang\n",maxdim+1) );

  if ( maxdim > 6 )
    croak( "Error: unable to convert an array of dimensionality %d\n", maxdim+1 );

  /* not a very useful array */
  if ( -1 == maxdim )     {
    SL_PUSH_ELEM1_ONTO_STACK(2);
    return;
  }

  /*
   * set up arrays for looping through the array
   */
  nelem = 1;
  for ( i = 0; i <= maxdim; i++ ) {
    SV **numsv = av_fetch( dims, i, 0 );
    long num = SvIV( *numsv );
    Printf( ("  *** dimension %d has size %d\n",i,num) );
    nelem *= num;
    dimsize[i] = num-1; /* want to start counting at 0 */
    coord[i] = 0;
    if ( 0 == i )
      aref[i] = array;
    else
      aref[i] = (AV *) SvRV( *av_fetch( aref[i-1], 0, 0 ) );
  }

  /*
   * this is truly not wonderful: set up the string that
   * pops the array, coordinates, and data value off the
   * S-Lang stack and fills in the array element
   * - *and* I'm too lazy to do this in C!
   */
  Printf( ("Calling Array_Type::_private_get_assign_string(%d)\n",maxdim) );
  {
    int count;
    dSP; ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs( sv_2mortal(newSViv(maxdim)) );
    PUTBACK;
    count = call_pv( "Array_Type::_private_get_assign_string", G_SCALAR );
    SPAGAIN;
    if ( 1 != count )
      croak( "Internal error: unable to call _private_get_assign_string()\n" );
    set_array_elem_sv = SvREFCNT_inc( POPs );
    PUTBACK; FREETMPS; LEAVE;
  }
  set_array_elem_str = SvPV_nolen(set_array_elem_sv);
  Printf( ("set str = [%s]\n",set_array_elem_str) );

  /*
   * loop i=1 to nelem
   *   - from coord/aref arrays can get the data value from Perl
   *     and set the S-Lang value
   *   - increase coord/aref arrays to point to the next value
   *     [a recursive loop
   *      if last elem of coord array < ndims[last element]
   *        add 1 to it; update aref[last element]
   *      else
   *        reset last element to 0, repeat with previous
   *        coord element [possibly repeat]
   *        update the necessary aref elements
   *
   */
  dval = av_fetch( aref[maxdim], coord[maxdim], 0 );
  sl_type = pltype( *dval, &sl_flag );
  for ( i = 1; i < nelem; i++ ) {
    Printf( ("  **** Setting %dD array elem %d coord=[",maxdim+1,i) );

    /*
     * since we are about to call pl2l() we push $1 onto the stack
     * to protect it. Then we push the coordinates, and then the
     * current data value
     */
    (void) SLang_load_string( "$1;" );
    for( j = 0; j <= maxdim; j++ ) {
      Printf( (" %d",coord[j]) );
      UTIL_SLERR(
	SLang_push_integer(coord[j]),
        "Internal error: unable to push onto the stack"
      );
    }
    Printf( (" ] and coord[maxdim] = %d\n",coord[maxdim]) );
    dval = av_fetch( aref[maxdim], coord[maxdim], 0 );
    pl2sl_type( *dval, sl_type, sl_flag );

    /* now set the value (also resets $1 to be the array) */
    (void) SLang_load_string( set_array_elem_str );

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
	Printf( ("++++++ resetting dim #%d to 0\n",j) );
	coord[j] = 0;
	aref[j] = (AV *) SvRV( *av_fetch( aref[j-1], coord[j-1], 0 ) );
	j++;
      }
      Printf( ("+++ finished coords/array refs update\n") );
    } /* if: coord[maxdim] == dimsize[maxdim] */

  } /* for: i=1 .. nelem-1 */

  /* handle the last element */
  Printf( ("  **** Setting %dD array elem %d coord=[",maxdim+1,nelem) );
  (void) SLang_load_string( "$1;" );
  for( j = 0; j <= maxdim; j++ ) {
    Printf( (" %d",coord[j]) );
    UTIL_SLERR(
      SLang_push_integer(coord[j]),
      "Internal error: unable to push onto the stack"
    );
  }
  Printf( (" ] [[last element]]\n") );
  dval = av_fetch( aref[maxdim], coord[maxdim], 0 );
  pl2sl_type( *dval, sl_type, sl_flag );
  (void) SLang_load_string( set_array_elem_str );

  SL_PUSH_ELEM1_ONTO_STACK(maxdim+3);
  SvREFCNT_dec( set_array_elem_sv ); /* free up mem */
  return;

} /* pl2sl_array_internal() */

static void
pl2sl_array_atype( SV *item ) {
  SV *arraystr;
  SV *arrayref, *dimsref;
  AV *array, *dims;

  Printf( ("*** converting Perl Array_Type object to S-Lang\n") );

  /*
   * create the array with the correct type & dims in $1
   */
  CALL_METHOD_SCALAR_SV( item, "_private_define_array", , arraystr );
  Printf( ("  array definition = [%s]\n", SvPV_nolen(arraystr)) );
  (void) SLang_load_string( SvPV_nolen(arraystr) );
  SvREFCNT_dec( arraystr );

  /*
   * get the array reference used to store the actual data
   * and the array dimensions [could do in one call]
   */
  CALL_METHOD_SCALAR_SV( item, "_private_get_arrayref", , arrayref );
  arrayref = sv_2mortal( arrayref );
  array = (AV *) SvRV( arrayref );

  CALL_METHOD_SCALAR_SV( item, "_private_get_dims", , dimsref );
  dimsref = sv_2mortal( dimsref );
  dims = (AV *) SvRV( dimsref );

  /*
   * and delegate all the complicated stuff, including pushing
   * the array back onto the S-Lang stack and clearing $1..$n
   */
  pl2sl_array_internal( array, dims );
  return;

} /* pl2sl_array_atype() */

/*
 * an array reference
 * - we have to guess the array dimensions and data type
 *   the current algorithm is LESS THAN OPTIMAL
 *   eg given [ [ 1, 2 ], "foo" ] it should return Any_Type [1]
 *   but it will assume Integer_Type [2]
 *   also  something like [ 1, 2.3, "foo" ] is prob best
 *   converted as a String_Type array - this code selects Integer_Type
 * >>>> will change at some point but not a high priority just now <<<<
 *
 * - see Array_Type
 *
 */
static void
pl2sl_array_aref( SV *item ) {
  int dimsize[SLARRAY_MAX_DIMS];

  AV *array = (AV*) SvRV(item);
  AV *temp;
  AV *dims;

  SLang_Array_Type *sl_dims;
  SLtype dtype;
  int i, ndims, nelem, dtype_flag;

  for ( i = 0; i < SLARRAY_MAX_DIMS; i++ ) dimsize[i] = 0;
    
  array = (AV*) SvRV(item);
  Printf( ("*** converting Perl array ref to ") );
  
  /*
   * what is the data type and array size?
   * ALGORITHM SHOULD BE MORE CLEVERERER
   */
  ndims = 0;
  dimsize[ndims] = av_len(array) + 1;
  nelem = dimsize[ndims];
  temp  = array;
  Printf( ("[%d]",dimsize[ndims]) );
  ndims++;

  fixme( "think dimension handling is wrong" );
  
  while ( 1 ) {
    SV *val = *av_fetch( temp, 0, 0 );
    if ( SvROK(val) && SVt_PVAV == SvTYPE(SvRV(val)) ) {
      if ( SLARRAY_MAX_DIMS == ndims )
	croak( "Error: Max array dimension for S-Lang is %d.\n", SLARRAY_MAX_DIMS );
      temp = (AV *) SvRV(val);
      dimsize[ndims] = av_len(temp) + 1;
      nelem *= dimsize[ndims];
      Printf( ("[%d]", dimsize[ndims]) );
      ndims++;
    } else {
      /* found a non-array element: guess its data type */
      dtype = pltype( val, &dtype_flag );
      break;
    }
  }

  /*
   * create a Perl array containing the array dimensions
   * - I think I need to re-work pl2sl_array_internal()!
   */
  dims = (AV *) sv_2mortal( (SV *) newAV() );
  av_extend( dims, ndims );
  for ( i=0; i<ndims; i++ ) {
    Printf( (" Hack: setting dimsize[%d] = %d\n",i,dimsize[i]) );
    av_store( dims, i, newSViv(dimsize[i]) );
  }
  
  Printf( (" %s [%d dim] array - nelem=%d\n",
	   SLclass_get_datatype_name(dtype), ndims, nelem) );

  /*
   * create the array in $1; $2 = datatype and $3 = array dims
   */
  UTIL_SLERR(
	     SLang_push_datatype(dtype),
	     "Internal error: unable to push datatype name onto the S-Lang stack"
	     );
  sl_dims = SLang_create_array( SLANG_INT_TYPE, 0, NULL, &ndims, 1 );
  if ( NULL == sl_dims )
    croak("Internal error: unable to make S-Lang int array.");
  for ( i = 0; i < ndims; i++ ) {
    if ( -1 == SLang_set_array_element( sl_dims, &i, &dimsize[i] ) )
      croak("Internal error: unable to set element of S-Lang int array.");
  }
  UTIL_SLERR(
	     SLang_push_array( sl_dims, 1 ),
	     "Internal error: unable to push array onto the S-Lang stack."
	     );
  (void) SLang_load_string( "$3=();$2=(); $1 = @Array_Type($2,$3);" );
  
  /*
   * and delegate all the complicated stuff, including pushing
   * the array back onto the S-Lang stack and clearing $1..$n
   */
  pl2sl_array_internal( array, dims );
  return;

} /* pl2sl_array_aref() */

static void
pl2sl_type( SV *item, SLtype item_type, int item_flag ) {

  switch( item_type ) {

    /* undef */
  case SLANG_NULL_TYPE:
    Printf( ("item=undef\n") );
    UTIL_SLERR(
	       SLang_push_null(),
	       "Error: unable to push a null onto the S-Lang stack"
	       );
    break;

    /* integer */
  case SLANG_INT_TYPE:
    Printf( ("item=integer %d\n", SvIV(item)) );
    UTIL_SLERR(
	       SLang_push_integer( SvIV(item) ),
	       "Error: unable to push an integer onto the S-Lang stack"
	       );
    break;

    /* floating-point */
  case SLANG_DOUBLE_TYPE:
    Printf( ("item=float %f\n", SvNV(item)) );
    UTIL_SLERR(
	       SLang_push_double( SvNV(item) ),
	       "Error: unable to push a floating-point number onto the S-Lang stack"
	       );
    break;

    /* string */
  case SLANG_STRING_TYPE:
    {
      STRLEN len;
      char *ptr = SvPV(item, len);
      Printf(("string: %s\n", ptr));
      UTIL_SLERR(
		 SLang_push_string( ptr ),
		 "Error: unable to push a string onto the S-Lang stack"
		 );
    }
    break;
    
    /* Math::Complex */
  case SLANG_COMPLEX_TYPE:
    {
      double real, imag;

      Printf( ("*** converting Perl's Math::Complex to S-Lang Complex_Type\n") );

      /* call the Re and Im methods */
      CALL_METHOD_SCALAR_DOUBLE( item, "Re", , real );
      CALL_METHOD_SCALAR_DOUBLE( item, "Im", , imag );

      /* push the complex number onto the S-Lang stack */
      UTIL_SLERR(
		 SLang_push_complex( real, imag ),
		 "Error: unable to push a complex number onto the S-Lang stack"
		 );
    }
    break;
    
    /* DataType_Type */
  case SLANG_DATATYPE_TYPE:
    {
      char *name;
      
      Printf( ("*** converting DataType_Type to S-Lang Datatype_Type\n") );
      
      /* de-reference the object (we can do this since it's our class) */
      name = SvPV_nolen( SvRV(item) );

      /*
       * now, we have the "printed" name of the datatype which we need to
       * convert to the S-Lang datatype. All we do is push the name
       * onto the stack and let S-Lang do the conversion to an
       * actual DataType_Type
       * - not the most efficient implementation but saves messing
       *   with the internals of S-Lang
       */
      (void) SLang_load_string( name );
    }
    break;

  case SLANG_STRUCT_TYPE:
    pl2sl_struct( item );
    break;

  case SLANG_ASSOC_TYPE:
    pl2sl_assoc( item, item_flag );
    break;

  case SLANG_ARRAY_TYPE:
    /* since the array handling needs work on we split up the three cases for now */
    switch ( item_flag ) {

#if I_SL_HAVE_PDL == 1
    case 2:
      pl2sl_array_pdl( item );
      break;
#endif

    case 1:
      pl2sl_array_atype( item );
      break;

      /* can we have anything but 0 for item_flag here? */
    default:
      pl2sl_array_aref( item );
    }
    break;

  default:
    /*
     * if we've got this far then assume we're a type that Perl can't handle
     * directly (ie the S-Lang data is actually stored in_inline->_store[])
     *
     * Perhaps we need to add a routine to the _Type class to indicate
     * this condition?
     */
    Printf( ("*** converting Perl _Type object to S-Lang\n") );
    pl2sl( SvRV(item) );
    (void) SLang_load_string( "$1 = (); _inline->_push_data( $1 );" );
    _clean_slang_vars(1);

  } /* switch: item_type */

} /* pl2sl_type() */

/*
 * convert perl variables to S-Lang variables
 *
 * note: we automatically push each variable onto the S-Lang stack
 * - this will probably turn out to be a bad idea; for instance it
 *   means it can't be called recursively when converting
 *   array/associative arrays.
 *
 * - we croak for those types we do not recognise [in pltype]
 */

void
pl2sl( SV *item ) {
  SLtype item_type;
  int    item_flag;

  item_type = pltype( item, &item_flag );
  pl2sl_type( item, item_type, item_flag );

}

/* end of pl2sl.c */
