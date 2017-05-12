#ifndef SL2PL_PDL_H
#define SL2PL_PDL_H

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

#if I_SL_HAVE_PDL == 1

#include "pdlcore.h"

/*
 * access the PDL internals
 * - this is essentially the output of
 *     use PDL::Core::Dev; print &PDL_AUTO_INCLUDE();
 */
extern Core* PDL;   /* Structure holds core C functions */
extern SV* CoreSV;  /* Gets pointer to perl var holding core structure */

extern void initialize_pdl_core( void );

extern SV   *sl2pl_array_pdl( SLang_Array_Type * );
extern void  pl2sl_array_pdl( SV * );


/*
 * Is the S-Lang datatype something that we can convert
 * to a piddle?
 *
 * - need to sort out datatype sizes for piddles and
 *   S-Lang numeric types
 * - and perhaps we should return the type (rather than just
 *   a yes/no here)? [would mean a function and not a macro)
 * - should this set of rules be created by Makefile.PL
 *
 */
#define IS_CONVERTABLE_TO_PDL(type) \
  ( (type) == SLANG_CHAR_TYPE  || (type) == SLANG_UCHAR_TYPE  || \
    (type) == SLANG_SHORT_TYPE || (type) == SLANG_USHORT_TYPE || \
    (type) == SLANG_INT_TYPE   || (type) == SLANG_UINT_TYPE   || \
    (type) == SLANG_LONG_TYPE  || (type) == SLANG_ULONG_TYPE  || \
    (type) == SLANG_FLOAT_TYPE || (type) == SLANG_DOUBLE_TYPE )

#define INIT_PDL_CORE initialize_pdl_core()

#else

#define INIT_PDL_CORE

#endif /* I_SL_HAVE_PDL */

#endif /* SL2PL_PDL_H */
