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

MODULE = Gtk2::Gdk::Screen	PACKAGE = Gtk2::Gdk::Screen	PREFIX = gdk_screen_

BOOT:
	/* the gdk backends override the public GdkScreen with private,
	 * back-end-specific types.  tell gperl_get_object not to 
	 * complain about them.  */
	gperl_object_set_no_warn_unreg_subclass (GDK_TYPE_SCREEN, TRUE);

##  GdkColormap *gdk_screen_get_default_colormap (GdkScreen *screen) 
GdkColormap *
gdk_screen_get_default_colormap (screen)
	GdkScreen *screen

##  void gdk_screen_set_default_colormap (GdkScreen *screen, GdkColormap *colormap) 
void
gdk_screen_set_default_colormap (screen, colormap)
	GdkScreen *screen
	GdkColormap *colormap

##  GdkColormap* gdk_screen_get_system_colormap (GdkScreen *screen) 
GdkColormap*
gdk_screen_get_system_colormap (screen)
	GdkScreen *screen

##  GdkVisual* gdk_screen_get_system_visual (GdkScreen *screen) 
GdkVisual*
gdk_screen_get_system_visual (screen)
	GdkScreen *screen

##  GdkColormap *gdk_screen_get_rgb_colormap (GdkScreen *screen) 
GdkColormap *
gdk_screen_get_rgb_colormap (screen)
	GdkScreen *screen

##  GdkVisual * gdk_screen_get_rgb_visual (GdkScreen *screen) 
GdkVisual *
gdk_screen_get_rgb_visual (screen)
	GdkScreen *screen

##  GdkWindow * gdk_screen_get_root_window (GdkScreen *screen) 
GdkWindow *
gdk_screen_get_root_window (screen)
	GdkScreen *screen

##  GdkDisplay * gdk_screen_get_display (GdkScreen *screen) 
GdkDisplay *
gdk_screen_get_display (screen)
	GdkScreen *screen

##  gint gdk_screen_get_number (GdkScreen *screen) 
gint
gdk_screen_get_number (screen)
	GdkScreen *screen

##  gint gdk_screen_get_width (GdkScreen *screen) 
gint
gdk_screen_get_width (screen)
	GdkScreen *screen

##  gint gdk_screen_get_height (GdkScreen *screen) 
gint
gdk_screen_get_height (screen)
	GdkScreen *screen

##  gint gdk_screen_get_width_mm (GdkScreen *screen) 
gint
gdk_screen_get_width_mm (screen)
	GdkScreen *screen

##  gint gdk_screen_get_height_mm (GdkScreen *screen) 
gint
gdk_screen_get_height_mm (screen)
	GdkScreen *screen

##  GList * gdk_screen_list_visuals (GdkScreen *screen) 
=for apidoc
Returns a list of Gtk2::Gdk::Visual's.
=cut
void
gdk_screen_list_visuals (screen)
	GdkScreen *screen
    PREINIT:
	GList * list, * i;
    PPCODE:
	list = gdk_screen_list_visuals (screen);
	for (i = list ; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVGdkVisual (i->data)));
	g_list_free (list);

##  GList * gdk_screen_get_toplevel_windows (GdkScreen *screen) 
=for apidoc
Returns a list of Gtk2::Gdk::Window's.
=cut
void
gdk_screen_get_toplevel_windows (screen)
	GdkScreen *screen
    PREINIT:
	GList * list, * i;
    PPCODE:
	list = gdk_screen_get_toplevel_windows (screen);
	for (i = list ; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVGdkWindow (i->data)));
	g_list_free (list);

##  gchar * gdk_screen_make_display_name (GdkScreen *screen) 
gchar_own *
gdk_screen_make_display_name (screen)
	GdkScreen *screen

##  gint gdk_screen_get_n_monitors (GdkScreen *screen) 
gint
gdk_screen_get_n_monitors (screen)
	GdkScreen *screen

##  void gdk_screen_get_monitor_geometry (GdkScreen *screen, gint monitor_num, GdkRectangle *dest) 
GdkRectangle_copy *
gdk_screen_get_monitor_geometry (screen, monitor_num)
	GdkScreen *screen
	gint monitor_num
    PREINIT:
	GdkRectangle dest;
    CODE:
	gdk_screen_get_monitor_geometry (screen, monitor_num, &dest);
	RETVAL = &dest;
    OUTPUT:
	RETVAL

##  gint gdk_screen_get_monitor_at_point (GdkScreen *screen, gint x, gint y) 
gint
gdk_screen_get_monitor_at_point (screen, x, y)
	GdkScreen *screen
	gint x
	gint y

##  gint gdk_screen_get_monitor_at_window (GdkScreen *screen, GdkWindow *window) 
gint
gdk_screen_get_monitor_at_window (screen, window)
	GdkScreen *screen
	GdkWindow *window

##  void gdk_screen_broadcast_client_message (GdkScreen *screen, GdkEvent *event) 
void
gdk_screen_broadcast_client_message (screen, event)
	GdkScreen *screen
	GdkEvent *event

 ## Gdk owns this object, so no _noinc
##  GdkScreen *gdk_screen_get_default (void) 
GdkScreen_ornull *
gdk_screen_get_default (class)
    C_ARGS:
	/* void */

##  gboolean gdk_screen_get_setting (GdkScreen *screen, const gchar *name, GValue *value) 
SV *
gdk_screen_get_setting (screen, name)
	GdkScreen *screen
	const gchar *name
    PREINIT:
	GValue value = {0,};
    CODE:
	if (!gdk_screen_get_setting (screen, name, &value))
		XSRETURN_UNDEF;
	RETVAL = gperl_sv_from_value (&value);
	g_value_unset (&value);
    OUTPUT:
	RETVAL

#if GTK_CHECK_VERSION (2, 8, 0)

GdkColormap_ornull * gdk_screen_get_rgba_colormap (GdkScreen *screen);

GdkVisual_ornull * gdk_screen_get_rgba_visual (GdkScreen *screen);

#endif

#if GTK_CHECK_VERSION (2, 10, 0)

# gdk_screen_get_font_options and gdk_screen_set_font_options are wrapped in
# GdkCairo.xs.

void gdk_screen_set_resolution (GdkScreen *screen, gdouble dpi);

gdouble gdk_screen_get_resolution (GdkScreen *screen);

GdkWindow * gdk_screen_get_active_window (GdkScreen * screen);

##GList * gdk_screen_get_window_stack (GdkScreen *screen)
void
gdk_screen_get_window_stack (GdkScreen *screen)
    PREINIT:
	GList *list, *i;
    PPCODE:
	list = gdk_screen_get_window_stack (screen);
	for (i = list; i != NULL; i = i->next)
		/* The list owns a reference to the windows. */
		XPUSHs (sv_2mortal (newSVGdkWindow_noinc (i->data)));
	g_list_free (list);

gboolean gdk_screen_is_composited (GdkScreen *screen);

#endif /* 2.10 */

#if GTK_CHECK_VERSION (2, 14, 0)

gint gdk_screen_get_monitor_height_mm (GdkScreen *screen, gint monitor_num);

gint gdk_screen_get_monitor_width_mm (GdkScreen *screen, gint monitor_num);

gchar_own_ornull * gdk_screen_get_monitor_plug_name (GdkScreen *screen, gint monitor_num);

#endif /* 2.14 */

#if GTK_CHECK_VERSION (2, 20, 0)

gint gdk_screen_get_primary_monitor (GdkScreen *screen);

#endif /* 2.20 */
