#ifndef SL2PL_PL2SL_H
#define SL2PL_PL2SL_H

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

/* functions that are visible outside of util.c */
void pl2sl( SV *item );
SLtype pltype( SV *plval, int *flag );

/* 
 * need to pop item off S-Lang's internal stack and push
 * it onto S-Lang's main stack (or I've confused myself)
 */
#define SL_PUSH_ELEM1_ONTO_STACK(nelem) \
  (void) SLang_load_string( \
    "$2=struct {value};set_struct_field($2,\"value\",$1);__push_args($2);" \
  ); \
  _clean_slang_vars(nelem);

#endif /* SL2PL_PL2SL_H */

