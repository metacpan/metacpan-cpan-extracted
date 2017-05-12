/*
 * Copyright (c) 2003-2005, 2010 by the gtk2-perl team (see the file AUTHORS)
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

MODULE = Gtk2::Gdk::Cursor	PACKAGE = Gtk2::Gdk::Cursor	PREFIX = gdk_cursor_

=for position DESCRIPTION

=head1 DESCRIPTION

For reference, cursors are a per-display resource and can only be used
with the display they were created on.

As of Gtk 2.22 a cursor doesn't keep a reference to its
C<Gtk2::Gdk::Display> and if the display object is destroyed before
the cursor then a later destroy of the cursor may get a segv.
Perl-Gtk2 doesn't try to do anything about this.  Care may be needed
if keeping a cursor separate from a widget or window.  (Closing the
display is fine, but not destroying it.)

=cut

GdkCursorType
gdk_cursor_type (cursor)
	GdkCursor *cursor
    CODE:
	RETVAL = cursor->type;
    OUTPUT:
	RETVAL

#if GTK_CHECK_VERSION(2,2,0)

## GdkCursor* gdk_cursor_new_for_display (GdkDisplay *display, GdkCursorType cursor_type)
GdkCursor_own*
gdk_cursor_new_for_display (class, display, cursor_type)
	GdkDisplay *display
	GdkCursorType cursor_type
    C_ARGS:
	display, cursor_type

## GdkDisplay* gdk_cursor_get_display (GdkCursor *cursor)
GdkDisplay*
gdk_cursor_get_display (cursor)
	GdkCursor *cursor

#endif

 ## GdkCursor* gdk_cursor_new (GdkCursorType cursor_type)
GdkCursor_own*
gdk_cursor_new (class, cursor_type)
	GdkCursorType cursor_type
    C_ARGS:
	cursor_type

 ## GdkCursor* gdk_cursor_new_from_pixmap (GdkPixmap *source, GdkPixmap *mask, GdkColor *fg, GdkColor *bg, gint x, gint y)
GdkCursor_own*
gdk_cursor_new_from_pixmap (class, source, mask, fg, bg, x, y)
	GdkPixmap *source
	GdkPixmap *mask
	GdkColor *fg
	GdkColor *bg
	gint x
	gint y
    C_ARGS:
	source, mask, fg, bg, x, y


#if GTK_CHECK_VERSION(2, 4, 0)

## GdkCursor * gdk_cursor_new_from_pixbuf (GdkDisplay *display, GdkPixbuf  *pixbuf, gint x, gint y)
GdkCursor_own *
gdk_cursor_new_from_pixbuf (class, display, pixbuf, x, y)
	GdkDisplay *display
	GdkPixbuf  *pixbuf
	gint x
	gint y
    C_ARGS:
	display, pixbuf, x, y

#endif

#if GTK_CHECK_VERSION (2, 8, 0)

## GdkCursor* gdk_cursor_new_from_name (GdkDisplay  *display, const gchar *name);
GdkCursor_own*
gdk_cursor_new_from_name (class, display, name)
	GdkDisplay  *display
	const gchar *name
    C_ARGS:
	display, name

GdkPixbuf_noinc* gdk_cursor_get_image (GdkCursor *cursor);

#endif

#if GTK_CHECK_VERSION (2, 22, 0)

GdkCursorType gdk_cursor_get_cursor_type (GdkCursor *cursor);

#endif /* 2.22 */
