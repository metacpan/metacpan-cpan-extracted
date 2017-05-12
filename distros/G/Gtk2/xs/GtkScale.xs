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

MODULE = Gtk2::Scale	PACKAGE = Gtk2::Scale	PREFIX = gtk_scale_

## void gtk_scale_set_digits (GtkScale *scale, gint digits)
void
gtk_scale_set_digits (scale, digits)
	GtkScale * scale
	gint       digits

## gint gtk_scale_get_digits (GtkScale *scale)
gint
gtk_scale_get_digits (scale)
	GtkScale * scale

## void gtk_scale_set_draw_value (GtkScale *scale, gboolean draw_value)
void
gtk_scale_set_draw_value (scale, draw_value)
	GtkScale * scale
	gboolean   draw_value

## gboolean gtk_scale_get_draw_value (GtkScale *scale)
gboolean
gtk_scale_get_draw_value (scale)
	GtkScale * scale

## void gtk_scale_set_value_pos (GtkScale *scale, GtkPositionType pos)
void
gtk_scale_set_value_pos (scale, pos)
	GtkScale        * scale
	GtkPositionType   pos

## GtkPositionType gtk_scale_get_value_pos (GtkScale *scale)
GtkPositionType
gtk_scale_get_value_pos (scale)
	GtkScale * scale

## void _gtk_scale_get_value_size (GtkScale *scale, gint *width, gint *height)


#if GTK_CHECK_VERSION (2, 4, 0)

## PangoLayout* gtk_scale_get_layout (GtkScale *scale)
PangoLayout *
gtk_scale_get_layout (scale)
	GtkScale *scale

void gtk_scale_get_layout_offsets (GtkScale *scale, OUTLIST gint x, OUTLIST gint y)

#endif

#if GTK_CHECK_VERSION (2, 16, 0)

## void gtk_scale_add_mark (GtkScale *scale, gdouble value, GtkPositionType  position, const gchar *markup)
void
gtk_scale_add_mark (scale, value, position, markup)
	GtkScale *scale
	gdouble   value
	GtkPositionType   position
	const gchar_ornull *markup

void gtk_scale_clear_marks (GtkScale *scale)

#endif
