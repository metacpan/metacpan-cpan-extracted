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

MODULE = Gnome2::IconSelection	PACKAGE = Gnome2::IconSelection	PREFIX = gnome_icon_selection_

##  GtkWidget * gnome_icon_selection_new (void) 
GtkWidget *
gnome_icon_selection_new (class)
    C_ARGS:
	/* void */

##  void gnome_icon_selection_add_defaults (GnomeIconSelection * gis) 
void
gnome_icon_selection_add_defaults (gis)
	GnomeIconSelection * gis

##  void gnome_icon_selection_add_directory (GnomeIconSelection * gis, const gchar * dir) 
void
gnome_icon_selection_add_directory (gis, dir)
	GnomeIconSelection * gis
	const gchar * dir

##  void gnome_icon_selection_show_icons (GnomeIconSelection * gis) 
void
gnome_icon_selection_show_icons (gis)
	GnomeIconSelection * gis

##  void gnome_icon_selection_clear (GnomeIconSelection * gis, gboolean not_shown) 
void
gnome_icon_selection_clear (gis, not_shown)
	GnomeIconSelection * gis
	gboolean not_shown

##  gchar * gnome_icon_selection_get_icon (GnomeIconSelection * gis, gboolean full_path) 
gchar_own *
gnome_icon_selection_get_icon (gis, full_path)
	GnomeIconSelection * gis
	gboolean full_path

##  void gnome_icon_selection_select_icon (GnomeIconSelection * gis, const gchar * filename) 
void
gnome_icon_selection_select_icon (gis, filename)
	GnomeIconSelection * gis
	const gchar * filename

##  void gnome_icon_selection_stop_loading (GnomeIconSelection * gis) 
void
gnome_icon_selection_stop_loading (gis)
	GnomeIconSelection * gis

##  GtkWidget *gnome_icon_selection_get_gil (GnomeIconSelection * gis) 
GtkWidget *
gnome_icon_selection_get_gil (gis)
	GnomeIconSelection * gis

##  GtkWidget *gnome_icon_selection_get_box (GnomeIconSelection * gis) 
GtkWidget *
gnome_icon_selection_get_box (gis)
	GnomeIconSelection * gis

