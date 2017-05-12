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

MODULE = Gtk2::TextMark	PACKAGE = Gtk2::TextMark	PREFIX = gtk_text_mark_

#if GTK_CHECK_VERSION (2, 12, 0)

## GtkTextMark * gtk_text_mark_new (const gchar *name, gboolean left_gravity)
GtkTextMark_noinc *
gtk_text_mark_new (class, const gchar_ornull *name, gboolean left_gravity)
    C_ARGS:
	name, left_gravity

#endif

## void gtk_text_mark_set_visible (GtkTextMark *mark, gboolean setting)
void
gtk_text_mark_set_visible (mark, setting)
	GtkTextMark *mark
	gboolean setting

## gboolean gtk_text_mark_get_visible (GtkTextMark *mark)
gboolean
gtk_text_mark_get_visible (mark)
	GtkTextMark *mark

## gboolean gtk_text_mark_get_deleted (GtkTextMark *mark)
gboolean
gtk_text_mark_get_deleted (mark)
	GtkTextMark *mark

## gchar* gtk_text_mark_get_name (GtkTextMark *mark);
const gchar_ornull *
gtk_text_mark_get_name (mark)
	GtkTextMark * mark

## GtkTextBuffer* gtk_text_mark_get_buffer (GtkTextMark *mark)
GtkTextBuffer_ornull*
gtk_text_mark_get_buffer (mark)
	GtkTextMark *mark

## gboolean gtk_text_mark_get_left_gravity (GtkTextMark *mark)
gboolean
gtk_text_mark_get_left_gravity (mark)
	GtkTextMark *mark

