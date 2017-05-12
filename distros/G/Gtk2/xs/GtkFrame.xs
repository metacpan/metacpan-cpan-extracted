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

MODULE = Gtk2::Frame	PACKAGE = Gtk2::Frame	PREFIX = gtk_frame_

GtkWidget*
gtk_frame_new (class, label=NULL)
	gchar_ornull *label
    C_ARGS:
	label

void
gtk_frame_set_label (frame, label=NULL)
	GtkFrame *frame
	gchar_ornull *label

void
gtk_frame_set_label_widget (frame, label_widget)
	GtkFrame *frame
	GtkWidget *label_widget

GtkWidget *
gtk_frame_get_label_widget (frame)
	GtkFrame * frame

void
gtk_frame_set_label_align (frame, xalign, yalign)
	GtkFrame *frame
	gfloat xalign
	gfloat yalign

# G_CONST_RETURN
const gchar *
gtk_frame_get_label (frame)
	GtkFrame * frame

void
gtk_frame_get_label_align (GtkFrame * frame, OUTLIST gfloat xalign, OUTLIST gfloat yalign)

void
gtk_frame_set_shadow_type (frame, type)
	GtkFrame *frame
	GtkShadowType type

GtkShadowType
gtk_frame_get_shadow_type (frame)
	GtkFrame *frame

