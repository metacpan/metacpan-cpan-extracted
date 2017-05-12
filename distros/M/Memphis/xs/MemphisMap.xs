/* Memphis.
 *
 * Perl bindings for libmemphis; a generic glib/cairo based OSM renderer
 * library. It draws maps on arbitrary cairo surfaces.
 *
 * Perl bindings by Emmanuel Rodriguez <emmanuel.rodriguez@gmail.com>
 *
 * Copyright (C) 2010 Emmanuel Rodriguez
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */


#include "memphis-perl.h"


MODULE = Memphis::Map  PACKAGE = Memphis::Map  PREFIX = memphis_map_


MemphisMap_noinc*
memphis_map_new (class)
	C_ARGS: /* No args */


void
memphis_map_free (MemphisMap *map)


void
memphis_map_load_from_file (MemphisMap *map, const gchar *filename)
	PREINIT:
		GError *error = NULL;

	CODE:
		memphis_map_load_from_file(map, filename, &error);
		if (error) {
			gperl_croak_gerror (NULL, error);
		}


void
memphis_map_load_from_data (MemphisMap *map, SV *sv_data)
	PREINIT:
		STRLEN length;
		char *data;
		GError *error = NULL;

	CODE:
		data = SvPV(sv_data, length);
		memphis_map_load_from_data (map, data, length, &error);
		if (error) {
			gperl_croak_gerror (NULL, error);
		}


void
memphis_map_get_bounding_box (MemphisMap *map)
	PREINIT:
		gdouble minlat = 0,
		        minlon = 0,
		        maxlat = 0,
		        maxlon = 0;

	PPCODE:
		memphis_map_get_bounding_box(map, &minlat, &minlon, &maxlat, &maxlon);
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(minlat)));
		PUSHs(sv_2mortal(newSVnv(minlon)));
		PUSHs(sv_2mortal(newSVnv(maxlat)));
		PUSHs(sv_2mortal(newSVnv(maxlon)));
