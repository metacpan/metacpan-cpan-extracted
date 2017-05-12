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

MODULE = Gtk2::Gdk::DisplayManager	PACKAGE = Gtk2::Gdk::DisplayManager	PREFIX = gdk_display_manager_

#if GTK_CHECK_VERSION(2,2,0)

##  void (*display_opened) (GdkDisplayManager *display_manager, GdkDisplay *display) 

 ##
 ## GdkDisplayManager is a singleton object, so we must not attempt to 
 ## unref it.
 ##
##  GdkDisplayManager *gdk_display_manager_get (void) 
GdkDisplayManager *
gdk_display_manager_get (class)
    C_ARGS:
	/*void*/

##  GdkDisplay * gdk_display_manager_get_default_display (GdkDisplayManager *display_manager) 
GdkDisplay *
gdk_display_manager_get_default_display (display_manager)
	GdkDisplayManager *display_manager

##  void gdk_display_manager_set_default_display (GdkDisplayManager *display_manager, GdkDisplay *display) 
void
gdk_display_manager_set_default_display (display_manager, display)
	GdkDisplayManager *display_manager
	GdkDisplay *display

##  GSList * gdk_display_manager_list_displays (GdkDisplayManager *display_manager) 
=for apidoc
Returns a list of Gtk2::Gdk::Display's.
=cut
void
gdk_display_manager_list_displays (display_manager)
	GdkDisplayManager *display_manager
    PREINIT:
	GSList * displays, * i;
    PPCODE:
	displays = gdk_display_manager_list_displays (display_manager);
	for (i = displays ; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVGdkDisplay (i->data)));
	g_slist_free (displays);

#endif /* >= 2.2.0 */
