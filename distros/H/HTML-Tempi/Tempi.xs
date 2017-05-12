/*   
		Tempi - A HTML Template system
    Copyright (C) 2002  Roger Faust <roger_faust@bluewin.ch>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
		
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "tempi_pub.h"

MODULE = HTML::Tempi		PACKAGE = HTML::Tempi		

int
tempi_init(arg)
		char *arg
	PROTOTYPE: $
	INIT:
		SV *error;
		char *ret;
	CODE:
 		error = get_sv("main::!", FALSE);
		ret = init (arg);
		RETVAL = 1;
		if (ret != NULL)
			{ 
				sv_setpv(error, ret);
				RETVAL = 0;
			}
	OUTPUT:
		RETVAL

int
parse_block(arg)
		char *arg
	PROTOTYPE: $
	INIT:
		SV *error;
		char *ret;	 
	CODE:
		error = get_sv("main::!", FALSE);
		ret = parse_block (arg);
		RETVAL = 1;
		if (ret != NULL)
			{ 
				sv_setpv(error, ret);
				RETVAL = 0;
			}
	OUTPUT:
		RETVAL			

int
set_var(arg1, arg2)
		char *arg1
		char *arg2
	PROTOTYPE: $;$
	INIT:
		SV *error;
		char *ret;
	CODE:
		error = get_sv("main::!", FALSE);
		ret = set_var (arg1, arg2);
		RETVAL = 1;
		if (ret != NULL)
			{ 
				sv_setpv(error, ret);
				RETVAL = 0;
			}
	OUTPUT:
		RETVAL

SV *
tempi_out()
	PROTOTYPE:
	INIT:
		SV *error;
		char *ret; 
	 CODE:
		error = get_sv("main::!", FALSE);
		ret = get_parsed ();
		if (ret == NULL)
			{ 
				sv_setpv(error, NO_INIT_RUN);
				RETVAL = newSViv (0);
			}
		else
			RETVAL = newSVpv (ret, 0);
	OUTPUT:
		RETVAL

int
tempi_free()
	PROTOTYPE:
	INIT:
		SV *error;
		char *ret;	 
	CODE:
		error = get_sv("main::!", FALSE);
		ret = free_memory ();
		RETVAL = 1;
		if (ret != NULL)
			{ 
				sv_setpv(error, ret);
				RETVAL = 0;
			}
	OUTPUT:
		RETVAL

int
tempi_reinit()
	PROTOTYPE:
	INIT:
		SV *error;
		char *ret;	 
	 CODE:
		error = get_sv("main::!", FALSE);
		ret = reinit ();
		RETVAL = 1;
		if (ret != NULL)
			{ 
				sv_setpv(error, ret);
				RETVAL = 0;
			}
	OUTPUT:
		RETVAL
