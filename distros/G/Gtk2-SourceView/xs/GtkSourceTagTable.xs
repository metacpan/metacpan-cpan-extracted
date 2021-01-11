/*
 * Copyright (c) 2003-2005 by Emmanuele Bassi (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "gtksourceviewperl.h"

MODULE = Gtk2::SourceView::TagTable	PACKAGE = Gtk2::SourceView::TagTable	PREFIX = gtk_source_tag_table_

GtkSourceTagTable_noinc *
gtk_source_tag_table_new (class)
    C_ARGS:
    	/* void */

# void gtk_source_tag_table_add_tags (GtkSourceTagTable *table, const GSList *tags)
void
gtk_source_tag_table_add_tags (table, ...)
	GtkSourceTagTable *table
    PREINIT:
	int i;
	GSList *tags = NULL;
    CODE:
	for (i = 1; i < items; i++)
		tags = g_slist_append (tags, SvGtkTextTag (ST (i)));
	gtk_source_tag_table_add_tags (table, (const GSList *) tags);
	g_slist_free (tags);

void
gtk_source_tag_table_remove_source_tags (GtkSourceTagTable * table)
