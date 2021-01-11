/*
 * Copyright (c) 2005 by Torsten Schoenfeld (see the file AUTHORS)
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

MODULE = Gtk2::SourceView::StyleScheme	PACKAGE = Gtk2::SourceView::StyleScheme	PREFIX = gtk_source_style_scheme_

BOOT:
	gperl_object_set_no_warn_unreg_subclass (GTK_TYPE_SOURCE_STYLE_SCHEME, TRUE);

GtkSourceTagStyle_own_ornull *gtk_source_style_scheme_get_tag_style (GtkSourceStyleScheme *scheme, const gchar *style_name);

const gchar *gtk_source_style_scheme_get_name (GtkSourceStyleScheme *scheme);

# GSList *gtk_source_style_scheme_get_style_names (GtkSourceStyleScheme *scheme);
void
gtk_source_style_scheme_get_style_names (scheme)
	GtkSourceStyleScheme *scheme
    PREINIT:
	GSList *names, *iter;
    PPCODE:
	names = gtk_source_style_scheme_get_style_names (scheme);
	for (iter = names; iter; iter = iter->next) {
		XPUSHs (sv_2mortal (newSVGChar (iter->data)));
		g_free (iter->data);
	}
	if (names)
		g_slist_free (names);

# GtkSourceStyleScheme *gtk_source_style_scheme_get_default (void);
GtkSourceStyleScheme *
gtk_source_style_scheme_get_default (class)
    C_ARGS:
	/* void */
