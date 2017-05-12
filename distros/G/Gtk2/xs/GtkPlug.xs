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

MODULE = Gtk2::Plug	PACKAGE = Gtk2::Plug	PREFIX = gtk_plug_

## no plug/socket on non-X11 despite patches exist for years.

#ifdef GDK_WINDOWING_X11

## void gtk_plug_construct (GtkPlug *plug, GdkNativeWindow socket_id)
void
gtk_plug_construct (plug, socket_id)
	GtkPlug         * plug
	GdkNativeWindow   socket_id

# for 2.2 compat this function needs to be updated to include
# the for_display version
## GtkWidget* gtk_plug_new (GdkNativeWindow socket_id)
GtkWidget *
gtk_plug_new (class, socket_id)
	GdkNativeWindow   socket_id
    C_ARGS:
	socket_id

#if GTK_CHECK_VERSION(2,2,0)

##GtkWidget * gtk_plug_new_for_display (GdkDisplay *display, GdkNativeWindow socket_id)
GtkWidget *
gtk_plug_new_for_display (...)
    CODE:
	if (items == 2) {
		RETVAL = gtk_plug_new_for_display (
			SvGdkDisplay (ST (0)), SvUV (ST (1)));
	} else if (items == 3) {
		RETVAL = gtk_plug_new_for_display (
			SvGdkDisplay (ST (1)), SvUV (ST (2)));
	} else {
		RETVAL = NULL;
		croak ("Usage: Gtk2::Plug->new_for_display(display, socket_id)");
	}
    OUTPUT:
	RETVAL

## void gtk_plug_construct_for_disaplay (GtkPlug *plug, GdkDisplay * display, GdkNativeWindow socket_id)
void
gtk_plug_construct_for_display (plug, display, socket_id)
	GtkPlug         * plug
	GdkDisplay      * display
	GdkNativeWindow   socket_id

#endif

## GdkNativeWindow gtk_plug_get_id (GtkPlug *plug)
GdkNativeWindow
gtk_plug_get_id (plug)
	GtkPlug * plug

#if GTK_CHECK_VERSION (2, 14, 0)

gboolean gtk_plug_get_embedded (GtkPlug *plug);

GdkWindow_ornull* gtk_plug_get_socket_window (GtkPlug *plug);

#endif /* 2.14 */

## void _gtk_plug_add_to_socket (GtkPlug *plug, GtkSocket *socket)
## void _gtk_plug_remove_from_socket (GtkPlug *plug, GtkSocket *socket)

#endif
