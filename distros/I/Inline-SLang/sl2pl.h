#ifndef SL2PL_SL2PL_H
#define SL2PL_SL2PL_H

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

SV * sl2pl( void );

#define C2PL_MARG(x)   XPUSHs( sv_2mortal( x ) )
#define C2PL_MARG_D(x) C2PL_MARG( newSVnv( x ) )
#define C2PL_MARG_S(x) C2PL_MARG( newSVpv( x, 0 ) )

/*
 * SL2PL_ITYPE( INT, integer, int ) 
 * will create code to handle scalar values of integer type
 *   SLANG_INT_TYPE and SLANG_UINT_TYPE
 * the second argument is the name of the SLang_pop_xxx
 * routine, and the third the c type (it's only for int/integer
 * that the second and third args are different)
 */

#define SL2PL_ITYPE(stypeu,stypel,ctype) \
  case SLANG_##stypeu##_TYPE: \
    { \
      ctype ival; \
      if ( -1 == SLang_pop_##stypel ( &ival ) ) \
	croak( "Error: unable to read stypel value from the stack\n" ); \
      Printf( ("  stack contains: ctype = %i\n", ival ) ); \
      return newSViv(ival); \
    } \
  \
  case SLANG_U##stypeu##_TYPE: \
    { \
      unsigned ctype ival; \
      if ( -1 == SLang_pop_u##stypel ( &ival ) ) \
	croak( "Error: unable to read stypel value from the stack\n" ); \
      Printf( ("  stack contains: unsigned ctype = %i\n", ival ) ); \
      return newSVuv(ival); \
    }

#endif /* SL2PL_SL2PL_H */

