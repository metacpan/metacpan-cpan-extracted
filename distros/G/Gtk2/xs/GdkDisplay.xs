/*
 * Copyright (c) 2003-2005 by the gtk2-perl team (see the file AUTHORS)
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

MODULE = Gtk2::Gdk::Display	PACKAGE = Gtk2::Gdk::Display	PREFIX = gdk_display_

BOOT:
	/* the various gdk backends will provide private subclasses of
	 * GdkDisplay; we shouldn't complain about them. */
	gperl_object_set_no_warn_unreg_subclass (GDK_TYPE_DISPLAY, TRUE);

##  gint (*get_n_screens) (GdkDisplay *display) 
##  void (*closed) (GdkDisplay *display, gboolean is_error) 

##  GdkDisplay *gdk_display_open (const gchar *display_name) 
GdkDisplay_ornull *
gdk_display_open (class, const gchar_ornull * display_name)
    C_ARGS:
	display_name

const gchar * gdk_display_get_name (GdkDisplay * display)

gint gdk_display_get_n_screens (GdkDisplay *display) 

GdkScreen * gdk_display_get_screen (GdkDisplay *display, gint screen_num) 

GdkScreen * gdk_display_get_default_screen (GdkDisplay *display) 

void gdk_display_pointer_ungrab (GdkDisplay *display, guint32 time_) 

void gdk_display_keyboard_ungrab (GdkDisplay *display, guint32 time_) 

gboolean gdk_display_pointer_is_grabbed (GdkDisplay *display) 

void gdk_display_beep (GdkDisplay *display) 

void gdk_display_sync (GdkDisplay *display) 

void gdk_display_close (GdkDisplay *display) 

##  GList * gdk_display_list_devices (GdkDisplay *display) 
=forapi
Returns a list of Gtk2::Gdk::Devices
=cut
void
gdk_display_list_devices (display)
	GdkDisplay *display
    PREINIT:
	GList * devices, * i;
    PPCODE:
	devices = gdk_display_list_devices (display);
	for (i = devices ; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVGdkDevice (i->data)));

GdkEvent* gdk_display_get_event (GdkDisplay *display) 

GdkEvent* gdk_display_peek_event (GdkDisplay *display) 

void gdk_display_put_event (GdkDisplay *display, GdkEvent *event) 

 # FIXME
###  void gdk_display_add_client_message_filter (GdkDisplay *display, GdkAtom message_type, GdkFilterFunc func, gpointer data) 
#void
#gdk_display_add_client_message_filter (display, message_type, func, data)
#	GdkDisplay *display
#	GdkAtom message_type
#	GdkFilterFunc func
#	gpointer data

void gdk_display_set_double_click_time (GdkDisplay *display, guint msec) 

#if GTK_CHECK_VERSION(2, 4, 0)

void gdk_display_set_double_click_distance (GdkDisplay *display, guint distance)

#endif

##  GdkDisplay *gdk_display_get_default (void) 
GdkDisplay_ornull *
gdk_display_get_default (class)
    C_ARGS:
	/*void*/

##  GdkDevice *gdk_display_get_core_pointer (GdkDisplay *display) 
GdkDevice *
gdk_display_get_core_pointer (display)
	GdkDisplay *display

##  void gdk_display_get_pointer (GdkDisplay *display, GdkScreen **screen, gint *x, gint *y, GdkModifierType *mask) 
void gdk_display_get_pointer (GdkDisplay *display)
    PREINIT:
	GdkScreen *screen = NULL;
	gint x;
	gint y;
	GdkModifierType mask;
    PPCODE:
	gdk_display_get_pointer (display, &screen, &x, &y, &mask);
	EXTEND (SP, 4);
	PUSHs (sv_2mortal (newSVGdkScreen (screen)));
	PUSHs (sv_2mortal (newSViv (x)));
	PUSHs (sv_2mortal (newSViv (y)));
	PUSHs (sv_2mortal (newSVGdkModifierType (mask)));

##  GdkWindow * gdk_display_get_window_at_pointer (GdkDisplay *display, gint *win_x, gint *win_y) 
###GdkWindow * gdk_display_get_window_at_pointer (GdkDisplay *display, OUTLIST gint win_x, OUTLIST gint win_y) 
=for apidoc
=for signature (window, win_x, win_y) = $display->get_window_at_pointer ($display)
=cut
void
gdk_display_get_window_at_pointer (GdkDisplay *display) 
    PREINIT:
	GdkWindow * window;
	gint win_x = 0, win_y = 0;
    PPCODE:
	window = gdk_display_get_window_at_pointer (display, &win_x, &win_y);
	if (!window)
		XSRETURN_EMPTY;
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSVGdkWindow (window)));
	PUSHs (sv_2mortal (newSViv (win_x)));
	PUSHs (sv_2mortal (newSViv (win_y)));


 # API reference says this shouldn't be used by apps, and is only useful for
 # event recorders.  would a perl event recorder be usable?
##  GdkDisplayPointerHooks *gdk_display_set_pointer_hooks (GdkDisplay *display, const GdkDisplayPointerHooks *new_hooks) 
 # not documented
##  GdkDisplay *gdk_display_open_default_libgtk_only (void) 

#if GTK_CHECK_VERSION(2, 4, 0)

gboolean gdk_display_supports_cursor_alpha (GdkDisplay * display)

gboolean gdk_display_supports_cursor_color (GdkDisplay * display)

guint gdk_display_get_default_cursor_size (GdkDisplay * display)

## void gdk_display_get_maximal_cursor_size (GdkDisplay *display, guint *width, guint *height)
void gdk_display_get_maximal_cursor_size (GdkDisplay *display, OUTLIST guint width, OUTLIST guint height)

void gdk_display_flush (GdkDisplay *display)

GdkWindow *gdk_display_get_default_group (GdkDisplay *display)

#endif

#if GTK_CHECK_VERSION (2, 6, 0)

gboolean gdk_display_supports_selection_notification (GdkDisplay *display);

gboolean gdk_display_request_selection_notification (GdkDisplay *display, GdkAtom selection);

gboolean gdk_display_supports_clipboard_persistence (GdkDisplay *display);

##  void gdk_display_store_clipboard (GdkDisplay *display, GdkWindow *clipboard_window, guint32 time_, GdkAtom *targets, gint n_targets);
=for apidoc
=for arg ... of Gtk2::Gdk::Atom's
=cut
void
gdk_display_store_clipboard (display, clipboard_window, time_, ...);
	GdkDisplay *display
	GdkWindow *clipboard_window
	guint32 time_
    PREINIT:
	GdkAtom *targets = NULL;
	gint n_targets = 0;
    CODE:
	if (items > 3) {
		int i;

		n_targets = items - 3;
		targets = g_new0 (GdkAtom, n_targets);

		for (i = 3; i < items; i++)
			targets[i - 3] = SvGdkAtom (ST (i));
	}

	gdk_display_store_clipboard (display, clipboard_window, time_, targets, n_targets);

	if (targets)
		g_free (targets);

#endif

#if GTK_CHECK_VERSION (2, 8, 0)

void gdk_display_warp_pointer (GdkDisplay *display, GdkScreen *screen, gint x, gint y);

#endif

#if GTK_CHECK_VERSION (2, 10, 0)

gboolean gdk_display_supports_shapes (GdkDisplay *display);

gboolean gdk_display_supports_input_shapes (GdkDisplay *display);

#endif

#if GTK_CHECK_VERSION (2, 12, 0)

gboolean gdk_display_supports_composite (GdkDisplay *display);

#endif

#if GTK_CHECK_VERSION (2, 22, 0)

gboolean gdk_display_is_closed (GdkDisplay *display);

#endif /* 2.22 */
