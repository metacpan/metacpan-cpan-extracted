/* Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

   This file is part of Filter-gunzip.

   Filter-gunzip is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the
   Free Software Foundation; either version 3, or (at your option) any later
   version.

   Filter-gunzip is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
   Public License for more details.

   You should have received a copy of the GNU General Public License along
   with Filter-gunzip.  If not, see <http://www.gnu.org/licenses/>. */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_PL_parser
#include "ppport.h"

MODULE = Filter::gunzip   PACKAGE = Filter::gunzip

SV *
_rsfp_filters ()
CODE:
    /* printf ("%p\n", PL_parser); */
    if (PL_parser && PL_rsfp_filters) {
      /* printf ("%p\n", PL_rsfp_filters); */
      RETVAL = newRV_inc ((SV *) PL_rsfp_filters);
    } else {
      RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

PerlIO *
_rsfp ()
CODE:
    /* PL_parser != NULL is meant to be checked by first calling
       _rsfp_filters() */
    /* printf ("%p\n", PL_rsfp); */
    RETVAL = PL_rsfp;
OUTPUT:
    RETVAL
