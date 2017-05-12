/* -*- Mode: C; c-file-style: "stroustrup" -*- */

/* NATools - Package with parallel corpora tools
 * Copyright (C) 2002-2012  Alberto Simões
 *
 * This package is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */


#include <stdio.h>
#include "natdict.h"

/**
 * @file
 * @brief Main program to dump a NATools dctionary in Perl format
 */

/**
 * @brief Main program
 *
 * @todo document this BIG program
 */
int main(int argc, char *argv[]) {

    NATDict *d1;

    if (argc != 2) {
	printf("USAGE:\n\tnat-ntd-dump <ntdic>");
    } else {
	d1 = natdict_open(argv[1]);
	if (!d1) { printf("Error loading dictionary: %s\n", argv[1]); return 1; }
	natdict_perldump(d1);
    }
    return 0;
}
