/* -*- Mode: C; c-file-style: "stroustrup" -*- */

/* NATools - Package with parallel corpora tools
 * Copyright (C) 1998-2001  Djoerd Hiemstra
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

#include <glib.h>
#include <stdio.h>
#include "standard.h"

GHashTable* parse_ini(const char* filename)
{
    GKeyFile *file;
    GHashTable *hash;
    char **keys, **iterator;

    file = g_key_file_new();

    if (g_key_file_load_from_file(file, filename, G_KEY_FILE_NONE, NULL)) {
	
	hash = g_hash_table_new(g_str_hash, g_str_equal);

	keys = g_key_file_get_keys(file, "nat", NULL, NULL);
	iterator = keys;

	while(*iterator) {
	    char *value;
	    value = g_key_file_get_value(file, "nat", *iterator, NULL);
	    g_hash_table_insert(hash, g_strdup(*iterator), value);
	    iterator++;
	}

	g_strfreev(keys);

	return hash;
    } else {
	return NULL;
    }
}


