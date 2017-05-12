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
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307 USA.
 */

#include "gtk2-sourceview2-perl.h"


MODULE = Gtk2::SourceView2::Language PACKAGE = Gtk2::SourceView2::Language PREFIX = gtk_source_language_

const gchar*
gtk_source_language_get_id (GtkSourceLanguage *language)

const gchar*
gtk_source_language_get_name (GtkSourceLanguage *language)

const gchar*
gtk_source_language_get_section (GtkSourceLanguage *language)

gboolean
gtk_source_language_get_hidden (GtkSourceLanguage *language)

const gchar_ornull*
gtk_source_language_get_metadata (GtkSourceLanguage *language, const gchar *name)

const gchar_ornull*
gtk_source_language_get_style_name (GtkSourceLanguage *language, const char *style_id)


void
gtk_source_language_get_mime_types (GtkSourceLanguage *language)
	PPCODE:
		sourceview2perl_return_strv(
			gtk_source_language_get_mime_types(language),
			TRUE
		);

void
gtk_source_language_get_globs (GtkSourceLanguage *language)
	PPCODE:
		sourceview2perl_return_strv(
			gtk_source_language_get_globs(language),
			TRUE
		);

void
gtk_source_language_get_style_ids (GtkSourceLanguage *language)
	PPCODE:
		sourceview2perl_return_strv(
			gtk_source_language_get_style_ids(language),
			TRUE
		);
