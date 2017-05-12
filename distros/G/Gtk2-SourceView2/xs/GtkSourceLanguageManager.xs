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


MODULE = Gtk2::SourceView2::LanguageManager PACKAGE = Gtk2::SourceView2::LanguageManager PREFIX = gtk_source_language_manager_

GtkSourceLanguageManager*
gtk_source_language_manager_new (class)
	C_ARGS: /* no args */

GtkSourceLanguageManager*
gtk_source_language_manager_get_default (class)
	C_ARGS: /* no args */

=for apidoc

Sets the list of directories where the lm looks for language files. If no dirs
are given (empty list) then the search path is cleared, if C<undef> is passed
then the search path is reset to default.

B<Note>: At the moment this function can be called only before the language
files are loaded for the first time. In practice to set a custom search path for
a Gtk2::SourceLanguageManager, you have to call this function right after
creating it.

=cut
void
gtk_source_language_manager_set_search_path (GtkSourceLanguageManager *lm, ...)
	CODE:
		sourceview2perl_generic_set_dirs(
			gtk_source_language_manager_set_search_path,
			lm
		);


void
gtk_source_language_manager_get_search_path (GtkSourceLanguageManager *lm)
	PPCODE:
		sourceview2perl_return_strv(
			gtk_source_language_manager_get_search_path(lm),
			FALSE
		);


void
gtk_source_language_manager_get_language_ids (GtkSourceLanguageManager *lm)
	PPCODE:
		sourceview2perl_return_strv(
			gtk_source_language_manager_get_language_ids(lm),
			FALSE
		);


GtkSourceLanguage_ornull*
gtk_source_language_manager_get_language (GtkSourceLanguageManager *lm, const gchar *id)

GtkSourceLanguage_ornull*
gtk_source_language_manager_guess_language (GtkSourceLanguageManager *lm, const gchar_ornull *filename, const gchar_ornull *content_type = NULL)
