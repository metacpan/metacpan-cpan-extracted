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

MODULE = Gtk2::SourceView::LanguagesManager	PACKAGE = Gtk2::SourceView::LanguagesManager	PREFIX = gtk_source_languages_manager_

GtkSourceLanguagesManager_noinc *
gtk_source_languages_manager_new (class)
    C_ARGS:
    	/* void */

##const GSList *gtk_source_languages_manager_get_available_languages (GtkSourceLanguagesManager *lm);
void
gtk_source_languages_manager_get_available_languages (lm)
	GtkSourceLanguagesManager *lm
    PREINIT:
	const GSList *list, *iter;
    PPCODE:
	list = gtk_source_languages_manager_get_available_languages (lm);
	for (iter = list; iter; iter = iter->next)
		XPUSHs (sv_2mortal (newSVGtkSourceLanguage (iter->data)));

GtkSourceLanguage_ornull *
gtk_source_languages_manager_get_language_from_mime_type (lm, mime_type)
	GtkSourceLanguagesManager * lm
	const gchar * mime_type

##const GSList *gtk_source_languages_manager_get_lang_files_dirs (GtkSourceLanguagesManager *lm);
void
gtk_source_languages_manager_get_lang_files_dirs (lm)
	GtkSourceLanguagesManager *lm
    PREINIT:
	const GSList *list, *iter;
    PPCODE:
	list = gtk_source_languages_manager_get_lang_files_dirs (lm);
	for (iter = list; iter; iter = iter->next)
		XPUSHs (sv_2mortal (newSVGChar (iter->data)));
