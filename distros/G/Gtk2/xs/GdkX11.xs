/*
 * Copyright (c) 2003-2005, 2009 by the gtk2-perl team (see the file AUTHORS)
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
#ifdef GDK_WINDOWING_X11
# include <gdk/gdkx.h>
#endif /* GDK_WINDOWING_X11 */

/*
 * there is no typemap for Display*, Screen*, etc, and indeed no perl-side
 * functions to manipulate them, so they are out for the time being.
 *
 * XID/XWINDOW/XATOM is treated as UV.
 *
 * all XS blocks are wrapped in #ifdef GDK_WINDOWING_X11 to make sure this
 * stuff doesn't exist when wrapping gdk compiled for other backends.
 */

/* ------------------------------------------------------------------------- */

MODULE = Gtk2::Gdk::X11	PACKAGE = Gtk2::Gdk::Drawable	PREFIX = gdk_x11_drawable_

#ifdef GDK_WINDOWING_X11

###define GDK_WINDOW_XID(win)           (gdk_x11_drawable_get_xid (win))
###define GDK_WINDOW_XWINDOW(win)       (gdk_x11_drawable_get_xid (win))
###define GDK_PIXMAP_XID(win)           (gdk_x11_drawable_get_xid (win))
###define GDK_DRAWABLE_XID(win)         (gdk_x11_drawable_get_xid (win))
##XID      gdk_x11_drawable_get_xid         (GdkDrawable *drawable);
UV
gdk_x11_drawable_get_xid (GdkDrawable *drawable)
    ALIAS:
	XID     = 1
        XWINDOW = 2
    CLEANUP:
	PERL_UNUSED_VAR (ix);

#endif /* GDK_WINDOWING_X11 */

# --------------------------------------------------------------------------- #

MODULE = Gtk2::Gdk::X11	PACKAGE = Gtk2::Gdk::X11	PREFIX = gdk_x11_

#ifdef GDK_WINDOWING_X11

guint32
gdk_x11_get_server_time (class, GdkWindow *window)
    C_ARGS:
	window

#ifndef GDK_MULTIHEAD_SAFE

gboolean
net_wm_supports (class, GdkAtom property)
    CODE:
	RETVAL = gdk_net_wm_supports (property);
    OUTPUT:
	RETVAL

void
gdk_x11_grab_server (class)
    C_ARGS:
	/* void */

void
gdk_x11_ungrab_server (class)
    C_ARGS:
	/* void */

gint
gdk_x11_get_default_screen (class)
    C_ARGS:
	/* void */

# FIXME?
## GdkVisual* gdkx_visual_get (VisualID xvisualid);

#endif /* GDK_MULTIHEAD_SAFE */

#endif /* GDK_WINDOWING_X11 */

# --------------------------------------------------------------------------- #

MODULE = Gtk2::Gdk::X11	PACKAGE = Gtk2::Gdk::Display	PREFIX = gdk_x11_display_

#### GdkDisplay didn't exist before 2.2.x

#if defined(GDK_WINDOWING_X11) && defined(GDK_TYPE_DISPLAY)

void gdk_x11_display_grab (GdkDisplay *display);

void gdk_x11_display_ungrab (GdkDisplay *display);

#if GTK_CHECK_VERSION (2, 4, 0)

# Even though the naming doesn't suggest it, this seems to be a GdkDisplay
# method.
##void gdk_x11_register_standard_event_type (GdkDisplay *display, gint event_base, gint n_events);
void
register_standard_event_type (GdkDisplay *display, gint event_base, gint n_events)
    CODE:
	gdk_x11_register_standard_event_type (display, event_base, n_events);

#endif /* 2.4.0 */

#if GTK_CHECK_VERSION (2, 8, 0)

void gdk_x11_display_set_cursor_theme (GdkDisplay *display, const gchar *theme, gint size);

guint32 gdk_x11_display_get_user_time (GdkDisplay *display);

#endif /* 2.8.0 */

#if GTK_CHECK_VERSION (2, 12, 0)

# FIXME: gdk_x11_display_broadcast_startup_message

const gchar *gdk_x11_display_get_startup_notification_id (GdkDisplay *display);

#endif

#endif /* GDK_WINDOWING_X11, GDK_TYPE_DISPLAY */

# --------------------------------------------------------------------------- #

MODULE = Gtk2::Gdk::X11	PACKAGE = Gtk2::Gdk::Window	PREFIX = gdk_x11_window_

#ifdef GDK_WINDOWING_X11

#if GTK_CHECK_VERSION (2, 6, 0)

void gdk_x11_window_set_user_time (GdkWindow *window, guint32 timestamp);

#endif /* 2.6.0 */

#if GTK_CHECK_VERSION (2, 8, 0)

void gdk_x11_window_move_to_current_desktop (GdkWindow *window);

#endif /* 2.8.0 */

#endif /* GDK_WINDOWING_X11 */

# --------------------------------------------------------------------------- #

MODULE = Gtk2::Gdk::X11	PACKAGE = Gtk2::Gdk::Screen	PREFIX = gdk_x11_screen_

#ifdef GDK_WINDOWING_X11

#if GTK_CHECK_VERSION (2, 2, 0)

int gdk_x11_screen_get_screen_number (GdkScreen *screen);

const char* gdk_x11_screen_get_window_manager_name (GdkScreen *screen);

# FIXME?
##GdkVisual* gdk_x11_screen_lookup_visual (GdkScreen *screen, VisualID xvisualid);

gboolean gdk_x11_screen_supports_net_wm_hint (GdkScreen *screen, GdkAtom property);

#endif /* 2.2.0 */

#if GTK_CHECK_VERSION (2, 14, 0)

UV gdk_x11_screen_get_monitor_output (GdkScreen *screen, gint monitor_num);

#endif /* 2.14.0 */

#endif /* GDK_WINDOWING_X11 */

# --------------------------------------------------------------------------- #

MODULE = Gtk2::Gdk::X11	PACKAGE = Gtk2::Gdk::Atom	PREFIX = gdk_x11_atom_

#ifdef GDK_WINDOWING_X11

#if GTK_CHECK_VERSION (2, 2, 0)

UV
to_xatom_for_display (GdkAtom atom, GdkDisplay *display)
    CODE:
	RETVAL = gdk_x11_atom_to_xatom_for_display(display, atom);
    OUTPUT:
	RETVAL

#endif /* 2.2.0 */

#ifndef GDK_MULTIHEAD_SAFE

UV gdk_x11_atom_to_xatom (GdkAtom atom);

#endif /* GDK_MULTIHEAD_SAFE */

#endif /* GDK_WINDOWING_X11 */
