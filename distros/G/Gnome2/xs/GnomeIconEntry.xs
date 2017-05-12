/*
 * Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS)
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the LICENSE file in the top level of this distribution
 * for the complete license terms.
 *
 */

#include "gnome2perl.h"

MODULE = Gnome2::IconEntry	PACKAGE = Gnome2::IconEntry	PREFIX = gnome_icon_entry_

##  GtkWidget *gnome_icon_entry_new (const gchar *history_id, const gchar *browse_dialog_title) 
GtkWidget *
gnome_icon_entry_new (class, history_id, browse_dialog_title)
	const gchar *history_id
	const gchar *browse_dialog_title
    C_ARGS:
	history_id, browse_dialog_title

##  void gnome_icon_entry_set_pixmap_subdir(GnomeIconEntry *ientry, const gchar *subdir) 
void
gnome_icon_entry_set_pixmap_subdir (ientry, subdir)
	GnomeIconEntry *ientry
	const gchar *subdir

##  gchar *gnome_icon_entry_get_filename(GnomeIconEntry *ientry) 
gchar_own *
gnome_icon_entry_get_filename (ientry)
	GnomeIconEntry *ientry

##  gboolean gnome_icon_entry_set_filename(GnomeIconEntry *ientry, const gchar *filename) 
gboolean
gnome_icon_entry_set_filename (ientry, filename)
	GnomeIconEntry *ientry
	const gchar *filename

##  void gnome_icon_entry_set_browse_dialog_title(GnomeIconEntry *ientry, const gchar *browse_dialog_title) 
void
gnome_icon_entry_set_browse_dialog_title (ientry, browse_dialog_title)
	GnomeIconEntry *ientry
	const gchar *browse_dialog_title

##  void gnome_icon_entry_set_history_id(GnomeIconEntry *ientry, const gchar *history_id) 
void
gnome_icon_entry_set_history_id (ientry, history_id)
	GnomeIconEntry *ientry
	const gchar *history_id

#### this appeared sometime between 2.3.0 and 2.3.3.1 ...

#if LIBGNOMEUI_CHECK_VERSION(2, 4, 0)

##  void gnome_icon_entry_set_max_saved (GnomeIconEntry *ientry, guint max_saved) 
void
gnome_icon_entry_set_max_saved (ientry, max_saved)
	GnomeIconEntry *ientry
	guint max_saved

#endif

##  GtkWidget *gnome_icon_entry_pick_dialog (GnomeIconEntry *ientry) 
GtkWidget_ornull *
gnome_icon_entry_pick_dialog (ientry)
	GnomeIconEntry *ientry
