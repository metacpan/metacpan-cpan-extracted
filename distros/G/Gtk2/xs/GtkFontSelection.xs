/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
 * Boston, MA  02110-1301  USA.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::FontSelection	PACKAGE = Gtk2::FontSelection	PREFIX = gtk_font_selection_

## GtkWidget* gtk_font_selection_new (void)
GtkWidget *
gtk_font_selection_new (class)
    C_ARGS:
	/* void */

## gchar* gtk_font_selection_get_font_name (GtkFontSelection *fontsel)
gchar_own *
gtk_font_selection_get_font_name (fontsel)
	GtkFontSelection * fontsel

## GdkFont* gtk_font_selection_get_font (GtkFontSelection *fontsel)
GdkFont *
gtk_font_selection_get_font (fontsel)
	GtkFontSelection * fontsel

## gboolean gtk_font_selection_set_font_name (GtkFontSelection *fontsel, const gchar *fontname)
gboolean
gtk_font_selection_set_font_name (fontsel, fontname)
	GtkFontSelection * fontsel
	const gchar      * fontname

## void gtk_font_selection_set_preview_text (GtkFontSelection *fontsel, const gchar *text)
void
gtk_font_selection_set_preview_text (fontsel, text)
	GtkFontSelection * fontsel
	const gchar      * text

## G_CONST_RETURN gchar* gtk_font_selection_get_preview_text (GtkFontSelection *fontsel)
const gchar *
gtk_font_selection_get_preview_text (fontsel)
	GtkFontSelection * fontsel

#if GTK_CHECK_VERSION (2, 14, 0)

# We don't own the face, so no _noinc.
PangoFontFace * gtk_font_selection_get_face (GtkFontSelection *fontsel);

GtkWidget * gtk_font_selection_get_face_list (GtkFontSelection *fontsel);

# We don't own the family, so no _noinc.
PangoFontFamily * gtk_font_selection_get_family (GtkFontSelection *fontsel);

GtkWidget * gtk_font_selection_get_family_list (GtkFontSelection *fontsel);

GtkWidget * gtk_font_selection_get_preview_entry (GtkFontSelection *fontsel);

gint gtk_font_selection_get_size (GtkFontSelection *fontsel);

GtkWidget * gtk_font_selection_get_size_entry (GtkFontSelection *fontsel);

GtkWidget * gtk_font_selection_get_size_list (GtkFontSelection *fontsel);

#endif /* 2.14 */

MODULE = Gtk2::FontSelection	PACKAGE = Gtk2::FontSelectionDialog	PREFIX = gtk_font_selection_dialog_

## GtkWidget* gtk_font_selection_dialog_new (const gchar *title)
GtkWidget *
gtk_font_selection_dialog_new (class, title)
	const gchar * title
    C_ARGS:
	title

=for apidoc Gtk2::FontSelectionDialog::ok_button __hide__
=cut

=for apidoc Gtk2::FontSelectionDialog::apply_button __hide__
=cut

=for apidoc Gtk2::FontSelectionDialog::cancel_button __hide__
=cut

GtkWidget *
get_ok_button (fsd)
	GtkFontSelectionDialog * fsd
    ALIAS:
	Gtk2::FontSelectionDialog::ok_button = 1
	Gtk2::FontSelectionDialog::get_apply_button = 2
	Gtk2::FontSelectionDialog::apply_button = 3
	Gtk2::FontSelectionDialog::get_cancel_button = 4
	Gtk2::FontSelectionDialog::cancel_button = 5
    CODE:
	switch(ix)
	{
	case 0:
	case 1:
#if GTK_CHECK_VERSION (2, 14, 0)
		RETVAL = gtk_font_selection_dialog_get_ok_button (fsd);
#else
		RETVAL = fsd->ok_button;
#endif
		break;
	case 2:
	case 3:
#if GTK_CHECK_VERSION (2, 14, 0)
		RETVAL = gtk_font_selection_dialog_get_apply_button (fsd);
#else
		RETVAL = fsd->apply_button;
#endif
		break;
	case 4:
	case 5:
#if GTK_CHECK_VERSION (2, 14, 0)
		RETVAL = gtk_font_selection_dialog_get_cancel_button (fsd);
#else
		RETVAL = fsd->cancel_button;
#endif
		break;
	default:
		RETVAL = NULL;
		g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

##gchar* gtk_font_selection_dialog_get_font_name (GtkFontSelectionDialog *fsd)
gchar_own *
gtk_font_selection_dialog_get_font_name (fsd)
	GtkFontSelectionDialog * fsd

##GdkFont* gtk_font_selection_dialog_get_font (GtkFontSelectionDialog *fsd)
GdkFont *
gtk_font_selection_dialog_get_font (fsd)
	GtkFontSelectionDialog * fsd

##gboolean gtk_font_selection_dialog_set_font_name (GtkFontSelectionDialog *fsd, const gchar *fontname)
gboolean
gtk_font_selection_dialog_set_font_name (fsd, fontname)
	GtkFontSelectionDialog * fsd
	gchar                  * fontname

##void gtk_font_selection_dialog_set_preview_text (GtkFontSelectionDialog *fsd, const gchar *text)
void
gtk_font_selection_dialog_set_preview_text (fsd, text)
	GtkFontSelectionDialog * fsd
	gchar                  * text

##G_CONST_RETURN gchar* gtk_font_selection_dialog_get_preview_text (GtkFontSelectionDialog *fsd)
const gchar *
gtk_font_selection_dialog_get_preview_text (fsd)
	GtkFontSelectionDialog * fsd

#if GTK_CHECK_VERSION (2, 22, 0)

GtkWidget * gtk_font_selection_dialog_get_font_selection (GtkFontSelectionDialog *fsd);

#endif /* 2.22 */

