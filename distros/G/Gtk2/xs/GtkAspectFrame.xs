/*
 * Copyright (c) 2003, 2010 by the gtk2-perl team (see the file AUTHORS)
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

MODULE = Gtk2::AspectFrame	PACKAGE = Gtk2::AspectFrame	PREFIX = gtk_aspect_frame_

## GtkWidget* gtk_aspect_frame_new (const gchar *label, gfloat xalign, gfloat yalign, gfloat ratio, gboolean obey_child)
# label can be NULL for no label, as per gtk_frame_set_label() etc,
# though not actually in the gtk_aspect_frame_new() docs as of Gtk 2.20
GtkWidget *
gtk_aspect_frame_new (class, label, xalign, yalign, ratio, obey_child)
	const gchar_ornull * label
	gfloat        xalign
	gfloat        yalign
	gfloat        ratio
	gboolean      obey_child
    C_ARGS:
	label, xalign, yalign, ratio, obey_child

## void gtk_aspect_frame_set (GtkAspectFrame *aspect_frame, gfloat xalign, gfloat yalign, gfloat ratio, gboolean obey_child)
 ### NOTE: renamed to avoid clashing with Glib::Object->set
void
gtk_aspect_frame_set_params (aspect_frame, xalign, yalign, ratio, obey_child)
	GtkAspectFrame * aspect_frame
	gfloat           xalign
	gfloat           yalign
	gfloat           ratio
	gboolean         obey_child
    CODE:
	gtk_aspect_frame_set (aspect_frame, xalign, yalign, ratio, obey_child);

