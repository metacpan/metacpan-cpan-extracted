/*
 * ELFF-Parser is a perl module for parsing ELFF formatted log files.
 *
 * Copyright (C) 2007-2010 Mark Warren <mwarren42@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = ELFF::Parser		PACKAGE = ELFF::Parser		

AV*
tokenize(value)
	SV* value
  PROTOTYPE: $
  CODE:
	STRLEN len;
	unsigned int l;
	char *line, *ptr;
	SV* field;

	// bail if value is undef or not a string
	if(!SvPOK(value)) {
		croak("wrong type of scalar for tokenize(), must be a string");
	}

	// set up pointers
	ptr = line = SvPV(value, len);

	// allocate a new array
	RETVAL = newAV();
	sv_2mortal((SV*)RETVAL);

	// trim trailing white space from the line
	while(isspace(line[len - 1])) {
		line[len - 1] = '\0';
		len--;
	}

	while(ptr - line < len) {
		// is this a quoted field?
		int quotes = *ptr == '"' ? 1 : 0;

		// find the ptr to the first index of either '"' or ' ',
		// depending on whether or not the field is quoted
		char *end = strchr(ptr + quotes, quotes == 1 ? '"' : ' ');

		// find the length of the field
		if(end == NULL) {
			if(quotes == 1) {
				// last field is missing trailing quote, malformed line
				croak("malformed line, missing trailing quote");
			}

			l = strlen(ptr);
			end = ptr + l;
		}
		else
			l = end - ptr - quotes;

		// push the field into the result array
		field = newSVpvn(ptr + quotes, l);
		av_push((AV*)RETVAL, field);

		// set ptr to end + quotes and space
		ptr =  ptr + quotes + l + quotes + 1;
	}

  OUTPUT:
	RETVAL

