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

#include <EXTERN.h>
#include <perl.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <ctype.h>
#include <locale.h>
#include <string.h>

#include "standard.h"
#include "partials.h"

#include <glib.h>

PartialCounts *PartialCountsAdd(PartialCounts *partials, nat_uint32_t wid)
{
    if (wid > partials->size) {
	nat_uint32_t newsize = partials->size;
	while(newsize < wid) { newsize*=1.2; }
	partials->buffer = (nat_uint32_t*)g_realloc(partials->buffer,
                                                    sizeof(nat_uint32_t) * newsize);
	partials->size = newsize;
    }
    if (wid > partials->last) partials->last = wid;
    partials->buffer[wid]++;

    return partials;
}

void PartialCountsSave(PartialCounts *partials, const char* filename)
{
    FILE *fh = fopen(filename, "wb");
    nat_uint32_t x;
    if (!fh) report_error("Can't create partials counts");

    x = partials->last + 1;
    fwrite(&x, sizeof(nat_uint32_t), 1, fh);
    fwrite(partials->buffer, sizeof(nat_uint32_t), partials->last+1, fh);

    fclose(fh);
}

PartialCounts *PartialCountsLoad(const char* filename) 
{
    PartialCounts *partials;
    FILE *fh = fopen(filename, "rb");
    if (!fh) report_error("Can't load partials count");

    partials = g_new(PartialCounts, 1);

    fread(&partials->size, sizeof(nat_uint32_t), 1, fh);
    partials->last = partials->size - 1;
    partials->buffer = g_new0(nat_uint32_t, partials->size);
    fread(partials->buffer, sizeof(nat_uint32_t), partials->size, fh);

    return partials;
}

void PartialCountsFree(PartialCounts *partials)
{
    g_free(partials->buffer);
    g_free(partials);
}
