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

MODULE = Gnome2::PixmapEntry	PACKAGE = Gnome2::PixmapEntry	PREFIX = gnome_pixmap_entry_

##  GtkWidget *gnome_pixmap_entry_new (const gchar *history_id, const gchar *browse_dialog_title, gboolean do_preview) 
GtkWidget *
gnome_pixmap_entry_new (class, history_id, browse_dialog_title, do_preview)
	const gchar *history_id
	const gchar *browse_dialog_title
	gboolean do_preview
    C_ARGS:
	history_id, browse_dialog_title, do_preview

##  void gnome_pixmap_entry_set_pixmap_subdir(GnomePixmapEntry *pentry, const gchar *subdir) 
void
gnome_pixmap_entry_set_pixmap_subdir (pentry, subdir)
	GnomePixmapEntry *pentry
	const gchar *subdir

##  GtkWidget *gnome_pixmap_entry_scrolled_window(GnomePixmapEntry *pentry) 
GtkWidget *
gnome_pixmap_entry_scrolled_window (pentry)
	GnomePixmapEntry *pentry

##  GtkWidget *gnome_pixmap_entry_preview_widget(GnomePixmapEntry *pentry) 
GtkWidget *
gnome_pixmap_entry_preview_widget (pentry)
	GnomePixmapEntry *pentry

##  void gnome_pixmap_entry_set_preview (GnomePixmapEntry *pentry, gboolean do_preview) 
void
gnome_pixmap_entry_set_preview (pentry, do_preview)
	GnomePixmapEntry *pentry
	gboolean do_preview

##  void gnome_pixmap_entry_set_preview_size(GnomePixmapEntry *pentry, gint preview_w, gint preview_h) 
void
gnome_pixmap_entry_set_preview_size (pentry, preview_w, preview_h)
	GnomePixmapEntry *pentry
	gint preview_w
	gint preview_h

##  gchar *gnome_pixmap_entry_get_filename(GnomePixmapEntry *pentry) 
gchar_own *
gnome_pixmap_entry_get_filename (pentry)
	GnomePixmapEntry *pentry

