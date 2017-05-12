/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
 * Boston, MA  02111-1307  USA.
 *
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/GnomeCanvas/xs/GnomeCanvasRichText.xs,v 1.2 2003/12/05 05:26:41 muppetman Exp $
 */
#include "gnomecanvasperl.h"

MODULE = Gnome2::Canvas::RichText	PACKAGE = Gnome2::Canvas::RichText	PREFIX = gnome_canvas_rich_text_

##  void gnome_canvas_rich_text_cut_clipboard(GnomeCanvasRichText *text) 
void
gnome_canvas_rich_text_cut_clipboard (text)
	GnomeCanvasRichText *text

##  void gnome_canvas_rich_text_copy_clipboard(GnomeCanvasRichText *text) 
void
gnome_canvas_rich_text_copy_clipboard (text)
	GnomeCanvasRichText *text

##  void gnome_canvas_rich_text_paste_clipboard(GnomeCanvasRichText *text) 
void
gnome_canvas_rich_text_paste_clipboard (text)
	GnomeCanvasRichText *text

##  void gnome_canvas_rich_text_set_buffer(GnomeCanvasRichText *text, GtkTextBuffer *buffer) 
void
gnome_canvas_rich_text_set_buffer (text, buffer)
	GnomeCanvasRichText *text
	GtkTextBuffer *buffer

##  GtkTextBuffer *gnome_canvas_rich_text_get_buffer(GnomeCanvasRichText *text) 
GtkTextBuffer *
gnome_canvas_rich_text_get_buffer (text)
	GnomeCanvasRichText *text

##  void gnome_canvas_rich_text_get_iter_location (GnomeCanvasRichText *text, const GtkTextIter *iter, GdkRectangle *location) 
GdkRectangle_copy *
gnome_canvas_rich_text_get_iter_location (text, iter)
	GnomeCanvasRichText *text
	GtkTextIter * iter;
    PREINIT:
	GdkRectangle location;
    CODE:
	gnome_canvas_rich_text_get_iter_location (text, iter, &location);
	RETVAL = &location;
    OUTPUT:
	RETVAL
	

##  void gnome_canvas_rich_text_get_iter_at_location (GnomeCanvasRichText *text, GtkTextIter *iter, gint x, gint y) 
GtkTextIter_copy *
gnome_canvas_rich_text_get_iter_at_location (text, x, y)
	GnomeCanvasRichText *text
	gint x
	gint y
    PREINIT:
	GtkTextIter iter;
    CODE:
	gnome_canvas_rich_text_get_iter_at_location (text, &iter, x, y);
	RETVAL = &iter;
    OUTPUT:
	RETVAL

