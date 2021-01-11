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

MODULE = Gtk2::SourceView::Language	PACKAGE = Gtk2::SourceView::Language	PREFIX = gtk_source_language_

gchar_own *
gtk_source_language_get_id (GtkSourceLanguage * language)

gchar_own *
gtk_source_language_get_name (GtkSourceLanguage * language)

gchar_own *
gtk_source_language_get_section (GtkSourceLanguage * language)

# GSList *gtk_source_language_get_tags (GtkSourceLanguage *language);
void
gtk_source_language_get_tags (language)
	GtkSourceLanguage *language
    PREINIT:
	GSList *list, *iter;
    PPCODE:
	list = gtk_source_language_get_tags (language);
	for (iter = list; iter; iter = iter->next)
		XPUSHs (sv_2mortal (newSVGtkSourceTag_noinc (iter->data)));
	g_slist_free (list);

gunichar gtk_source_language_get_escape_char (GtkSourceLanguage *language);

# GSList *gtk_source_language_get_mime_types (GtkSourceLanguage *language);
void
gtk_source_language_get_mime_types (language)
	GtkSourceLanguage *language
    PREINIT:
	GSList *list, *iter;
    PPCODE:
	list = gtk_source_language_get_mime_types (language);
	for (iter = list; iter; iter = iter->next) {
		XPUSHs (sv_2mortal (newSVGChar (iter->data)));
		g_free (iter->data);
	}
	g_slist_free (list);

# void gtk_source_language_set_mime_types (GtkSourceLanguage *language, const GSList *mime_types);
void
gtk_source_language_set_mime_types (language, ...)
	GtkSourceLanguage *language
    PREINIT:
	GSList *types = NULL;
	int i;
    CODE:
	if (items == 2 && ST (1) == &PL_sv_undef)
		types = NULL;
	else
		for (i = 1; i < items; i++)
			types = g_slist_append (types, SvGChar (ST (i)));

	gtk_source_language_set_mime_types (language, (const GSList *) types);

	if (types)
		g_slist_free (types);

GtkSourceStyleScheme *gtk_source_language_get_style_scheme (GtkSourceLanguage *language);

void gtk_source_language_set_style_scheme (GtkSourceLanguage *language, GtkSourceStyleScheme *scheme);

GtkSourceTagStyle_own_ornull *gtk_source_language_get_tag_style (GtkSourceLanguage *language, const gchar *tag_id);

void gtk_source_language_set_tag_style (GtkSourceLanguage *language, const gchar *tag_id, const GtkSourceTagStyle_ornull *style);

GtkSourceTagStyle_own *gtk_source_language_get_tag_default_style (GtkSourceLanguage *language, const gchar *tag_id);
