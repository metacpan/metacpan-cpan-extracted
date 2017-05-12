/*
# NATools - Package with parallel corpora tools
# Copyright (C) 1998-2001  Djoerd Hiemstra
# Copyright (C) 2002-2012  Alberto Simões
#
# This package is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.
*/

#include <stdio.h>
#include "invindex.h"

/**
 * @file
 * @brief Main program to join invertion index files
 */

/**
 * @brief The main function 
 *
 * @todo Document this
 */
int main(int argc, char *argv[]) {
    if (argc < 3) {
	printf("Usage...\n");
    } else {
	InvIndex *full_index;
	nat_uchar_t chunk;
	int i;

	full_index = inv_index_new(150000);

	fprintf(stderr, " Creating index");
	for (i=2, chunk = 1; i<argc; i++, chunk++) {
	    CompactInvIndex *cii;
	    fprintf(stderr, ".");

	    cii = inv_index_compact_load(argv[i]);
	    full_index = inv_index_add_chunk(full_index, chunk, cii);
	    inv_index_compact_free(cii);
	}
	fprintf(stderr, "\n");
	inv_index_save_hash(full_index, argv[1], FALSE);
    }
    return 0;
}
