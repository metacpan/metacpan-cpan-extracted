/****************************************************************************
 *
 * $Id: pdl.c,v 1.6 2005/01/03 18:08:31 dburke Exp $
 *
 * pdl.c
 *   PDL support for Inline::SLang (at least the utility functions,
 *   since some PDL-specific code will appear in other files)
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

/* Should only ever be compiled if I_SL_HAVE_PDL is 1 so do not need to check */

/*
 * access the PDL internals
 * - this is essentially the output of
 *     use PDL::Core::Dev; print &PDL_AUTO_INCLUDE();
 */
Core* PDL;   /* Structure holds core C functions */
SV* CoreSV;  /* Gets pointer to perl var holding core structure */

/*
 * initialize the pointers that will allow us to call PDL functions 
 * - this is called from the BOOT section of the XS code
 *   we do it this way so that the PDL-related variables can be
 *   localised to this file (which now seems a bit pointless
 *   as they're no longer static)
 */
void initialize_pdl_core( void ) {

  /*
   * a 'use PDL::LiteF;' in SLang.pm would be simpler...
   * - using a flags setting of 0 (ie rather than PERL_LOADMOD_NOIMPORT)
   *   causes problems on OS-X and Linux [but not Solaris].
   *   I find the perl docs on this somewhat opaque; this was the
   *   first flag I guessed at using other than 0...
   */
  load_module( PERL_LOADMOD_NOIMPORT, newSVpv("PDL::Lite",0), NULL );

  /* 
   * this code fragment is essentially the output of:
   *    use PDL::Core::Dev; print &PDL_BOOT();
   * minus the require_pv line and the aTHX_ defines
   */
  CoreSV = perl_get_sv("PDL::SHARE",FALSE);
  if( NULL == CoreSV )
    Perl_croak(aTHX_ "The Inline::SLang module requires the PDL::Core module, which was not found");
  PDL = INT2PTR(Core*,SvIV( CoreSV ));
  if ( PDL_CORE_VERSION != PDL->Version )
    Perl_croak(aTHX_ "The Inline::SLang module needs to be recompiled against the latest installed PDL");

} /* initialize_pdl_core() */

/* Used by sl2pl.c - convert a S-Lang array into a piddle */

/*
 * see 'pdldoc API' for explanation of what's going on here
 *
 * SV *sl2pl_array_pdl( SLang_Array_Type * )
 *   convert the S-Lang array into a piddle
 *
 * void pl2sl_array_pdl( SV * )
 *   convert the piddle into a S-Lang array and
 *   push this array onto the S-Lang stack
 */

SV *
sl2pl_array_pdl( SLang_Array_Type *at ) {

  PDL_Long dims[SLARRAY_MAX_DIMS];
  pdl  *out;
  SV *sv;
  size_t dsize;
  int i;

  /*
   * copy over the dims
   * (we reverse them since PDL and S-Lang use different
   *  array-access schemes)
   */
  Printf( ("*** converting S-Lang array tp Piddle: ndims=%d [", at->num_dims) );
  for ( i = 0; i < at->num_dims; i++ ) {
    dims[at->num_dims-1-i] = at->dims[i];
    Printf( (" %d", at->dims[i]) );
  }
  Printf( ("] dtype=%d", at->data_type) );

  /* should we check for failure? */
  out = PDL->pdlnew();
  PDL->setdims( out, dims, at->num_dims );
#include "topdl.h"

  /*
   * copy the memory from the array since I don't know when S-Lang may delete it
   * (would be quicker to just point to it but that leads to memory-managment issues)
   *
   * It is not entirely clear to me from the S-Lang docs whether I can safely
   * access the data field of the array directly.
   */
  PDL->allocdata( out );
  (void) memcpy( out->data, at->data, (size_t) at->num_elements * dsize );

  /* covert the piddle into a 'SV *' */
  sv = sv_newmortal();
  PDL->SetSV_PDL( sv, out );
  SvREFCNT_inc( sv );
  return sv;

} /* sl2pl_array_pdl() */

void
pl2sl_array_pdl( SV *item ) {

  int dims[SLARRAY_MAX_DIMS];
  SLang_Array_Type *at;
  pdl *pdl;
  SLtype otype;
  size_t dsize;
  int i;

  /*
   * we have a piddle. I appear to have to call PDL->make_physdims()
   * on it (eg if it is a slice of another piddle), but is that 
   * all, or should I call PDL.make_physvaffine() instead?
   *
   * If we do have a piddle that is just a transformation of another
   * one then I 'cheat' and make it physical; in that way we can use
   * memcpy() to copy the data across rather than process the
   * transformation ourselves. It would be nice if there were a function
   * in the PDL API which would copy the contents of a "virtual" piddle
   * into a contiguous block of memory. Maybe there is one?
   *
   */
  pdl = PDL->SvPDLV(item);
  PDL->make_physdims(pdl);
  /* PDL->make_physvaffine(pdl); - do not need this since call make_physical() below */

  if ( pdl->ndims > SLARRAY_MAX_DIMS )
    croak( "Error: max number of dimensions for a S-Lang array is %d",
	   SLARRAY_MAX_DIMS );
  
  if ( pdl->ndims == 0 )
    croak( "Error: S-Lang does not allow a 0d array - perhaps should promote to 1d or convert to a scalar?" );
  
  /*
   * as in sl2pl_array_pdl() we need to reverse the dimensions
   */
  Printf( ("*** converting Piddle to S-Lang: ndims=%d [", pdl->ndims) );
  for ( i = 0; i < pdl->ndims; i++ ) {
    dims[pdl->ndims-1-i] = pdl->dims[i];
    Printf( (" %d", dims[i]) );
  }
  Printf( ("] dtype=%d", pdl->datatype) );

#include "toslang.h"

  Printf( (" -> %s\n", SLclass_get_datatype_name(otype)) );
  at = SLang_create_array( otype, 0, NULL, dims, pdl->ndims );
  if ( at == NULL )
    croak( "Error: Unable to create a S-Lang array of %ld elements",
	   pdl->nvals );

  /* copy over the data */
  if ( pdl->trans ) {
    /*
     * hack to make things easier for us; ensure that pdl->data contains
     * the actual data
     */
    Printf( ("*** NOTE: calling PDL->make_physical") );
    PDL->make_physical(pdl);
  }
  (void) memcpy( at->data, pdl->data, (size_t) pdl->nvals * dsize );

  /* stick array on the stack */
  (void) SLang_push_array (at, 1);

} /* pl2sl_array_pdl() */

/* pdl.c */
