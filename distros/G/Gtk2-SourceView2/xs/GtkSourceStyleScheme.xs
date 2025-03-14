/*
 * Copyright (c) 2009-2010 by Emmanuel Rodriguez (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version; or the
 * Artistic License, version 2.0.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details; or the Artistic License.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "gtk2-sourceview2-perl.h"

MODULE = Gtk2::SourceView2::StyleScheme PACKAGE = Gtk2::SourceView2::StyleScheme PREFIX = gtk_source_style_scheme_

const gchar*
gtk_source_style_scheme_get_id (GtkSourceStyleScheme *style)

const gchar*
gtk_source_style_scheme_get_name (GtkSourceStyleScheme *style)

const gchar_ornull*
gtk_source_style_scheme_get_description (GtkSourceStyleScheme *style)

const gchar_ornull*
gtk_source_style_scheme_get_filename (GtkSourceStyleScheme *style)

GtkSourceStyle_ornull*
gtk_source_style_scheme_get_style (GtkSourceStyleScheme *style, const gchar *style_id)

void
gtk_source_style_scheme_get_authors (GtkSourceStyleScheme *style)
	PPCODE:
		sourceview2perl_return_strv(
			gtk_source_style_scheme_get_authors(style),
			FALSE
		);
