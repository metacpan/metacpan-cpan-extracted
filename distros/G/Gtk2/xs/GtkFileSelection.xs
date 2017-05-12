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

MODULE = Gtk2::FileSelection	PACKAGE = Gtk2::FileSelection	PREFIX = gtk_file_selection_

=for deprecated_by Gtk2::FileChooserDialog
=cut

GtkWidget *
dir_list (fs)
	GtkFileSelection* fs
    ALIAS:
	Gtk2::FileSelection::file_list        = 1
	Gtk2::FileSelection::selection_entry  = 2
	Gtk2::FileSelection::selection_text   = 3
	Gtk2::FileSelection::main_vbox        = 4
	Gtk2::FileSelection::ok_button        = 5
	Gtk2::FileSelection::cancel_button    = 6
	Gtk2::FileSelection::help_button      = 7
	Gtk2::FileSelection::history_pulldown = 8
	Gtk2::FileSelection::history_menu     = 9
	Gtk2::FileSelection::fileop_dialog    = 10
	Gtk2::FileSelection::fileop_entry     = 11
	Gtk2::FileSelection::fileop_c_dir     = 12
	Gtk2::FileSelection::fileop_del_file  = 13
	Gtk2::FileSelection::fileop_ren_file  = 14
	Gtk2::FileSelection::button_area      = 15
	Gtk2::FileSelection::action_area      = 16
    CODE:
	switch (ix) {
		case  0: RETVAL = fs->dir_list;         break;
		case  1: RETVAL = fs->file_list;        break;
		case  2: RETVAL = fs->selection_entry;  break;
		case  3: RETVAL = fs->selection_text;   break;
		case  4: RETVAL = fs->main_vbox;        break;
		case  5: RETVAL = fs->ok_button;        break;
		case  6: RETVAL = fs->cancel_button;    break;
		case  7: RETVAL = fs->help_button;      break;
		case  8: RETVAL = fs->history_pulldown; break;
		case  9: RETVAL = fs->history_menu;     break;
		case 10: RETVAL = fs->fileop_dialog;    break;
		case 11: RETVAL = fs->fileop_entry;     break;
		case 12: RETVAL = fs->fileop_c_dir;     break;
		case 13: RETVAL = fs->fileop_del_file;  break;
		case 14: RETVAL = fs->fileop_ren_file;  break;
		case 15: RETVAL = fs->button_area;      break;
		case 16: RETVAL = fs->action_area;      break;
		default:
			RETVAL = NULL;
			g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

gchar *
fileop_file (fs)
	GtkFileSelection* fs
    CODE:
	RETVAL = fs->fileop_file;
    OUTPUT:
	RETVAL

## GtkWidget* gtk_file_selection_new (const gchar *title)
GtkWidget *
gtk_file_selection_new (class, title)
	const gchar * title
    C_ARGS:
	title

## void gtk_file_selection_set_filename (GtkFileSelection *filesel, const gchar *filename)
void
gtk_file_selection_set_filename (filesel, filename)
	GtkFileSelection * filesel
	GPerlFilename filename

## void gtk_file_selection_complete (GtkFileSelection *filesel, const gchar *pattern)
void
gtk_file_selection_complete (filesel, pattern)
	GtkFileSelection * filesel
	const gchar      * pattern

## void gtk_file_selection_show_fileop_buttons (GtkFileSelection *filesel)
void
gtk_file_selection_show_fileop_buttons (filesel)
	GtkFileSelection * filesel

## void gtk_file_selection_hide_fileop_buttons (GtkFileSelection *filesel)
void
gtk_file_selection_hide_fileop_buttons (filesel)
	GtkFileSelection * filesel

## void gtk_file_selection_set_select_multiple (GtkFileSelection *filesel, gboolean select_multiple)
void
gtk_file_selection_set_select_multiple (filesel, select_multiple)
	GtkFileSelection * filesel
	gboolean           select_multiple

## gboolean gtk_file_selection_get_select_multiple (GtkFileSelection *filesel)
gboolean
gtk_file_selection_get_select_multiple (filesel)
	GtkFileSelection * filesel

## gtk_file_selection_get_filename returns a statically allocated string
GPerlFilename_const
gtk_file_selection_get_filename (filesel)
	GtkFileSelection * filesel

=for apidoc
Returns the list of file name(s) selected.
=cut
void
gtk_file_selection_get_selections (filesel)
	GtkFileSelection * filesel
    PREINIT:
	int      i;
	gchar ** rets;
    PPCODE:
	rets = gtk_file_selection_get_selections(filesel);
	for (i = 0; rets[i] != NULL; i++)
		XPUSHs (sv_2mortal (gperl_sv_from_filename (rets[i])));
	g_strfreev(rets);

