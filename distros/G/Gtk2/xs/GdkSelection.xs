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

MODULE = Gtk2::Gdk::Selection	PACKAGE = Gtk2::Gdk

GdkAtom
SELECTION_PRIMARY (class)
    ALIAS:
	Gtk2::Gdk::SELECTION_SECONDARY     =  1
	Gtk2::Gdk::SELECTION_CLIPBOARD     =  2
	Gtk2::Gdk::TARGET_BITMAP           =  3
	Gtk2::Gdk::TARGET_COLORMAP         =  4
	Gtk2::Gdk::TARGET_DRAWABLE         =  5
	Gtk2::Gdk::TARGET_PIXMAP           =  6
	Gtk2::Gdk::TARGET_STRING           =  7
	Gtk2::Gdk::SELECTION_TYPE_ATOM     =  8
	Gtk2::Gdk::SELECTION_TYPE_BITMAP   =  9
	Gtk2::Gdk::SELECTION_TYPE_COLORMAP = 10
	Gtk2::Gdk::SELECTION_TYPE_DRAWABLE = 11
	Gtk2::Gdk::SELECTION_TYPE_INTEGER  = 12
	Gtk2::Gdk::SELECTION_TYPE_PIXMAP   = 13
	Gtk2::Gdk::SELECTION_TYPE_WINDOW   = 14
	Gtk2::Gdk::SELECTION_TYPE_STRING   = 15
    CODE:
	switch (ix) {
	    case  0: RETVAL = GDK_SELECTION_PRIMARY; break;
	    case  1: RETVAL = GDK_SELECTION_SECONDARY; break;
	    case  2: RETVAL = GDK_SELECTION_CLIPBOARD; break;
	    case  3: RETVAL = GDK_TARGET_BITMAP; break;
	    case  4: RETVAL = GDK_TARGET_COLORMAP; break;
	    case  5: RETVAL = GDK_TARGET_DRAWABLE; break;
	    case  6: RETVAL = GDK_TARGET_PIXMAP; break;
	    case  7: RETVAL = GDK_TARGET_STRING; break;
	    case  8: RETVAL = GDK_SELECTION_TYPE_ATOM; break;
	    case  9: RETVAL = GDK_SELECTION_TYPE_BITMAP; break;
	    case 10: RETVAL = GDK_SELECTION_TYPE_COLORMAP; break;
	    case 11: RETVAL = GDK_SELECTION_TYPE_DRAWABLE; break;
	    case 12: RETVAL = GDK_SELECTION_TYPE_INTEGER; break;
	    case 13: RETVAL = GDK_SELECTION_TYPE_PIXMAP; break;
	    case 14: RETVAL = GDK_SELECTION_TYPE_WINDOW; break;
	    case 15: RETVAL = GDK_SELECTION_TYPE_STRING; break;
	    default:
		RETVAL = 0;
		g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL


MODULE = Gtk2::Gdk::Selection	PACKAGE = Gtk2::Gdk::Selection	PREFIX = gdk_selection_

 ## since owner can be NULL, i interpret this to be a class method rather 
 ## than an object method.
##  gboolean gdk_selection_owner_set (GdkWindow *owner, GdkAtom selection, guint32 time_, gboolean send_event) 
gboolean
gdk_selection_owner_set (class, owner, selection, time_, send_event)
	GdkWindow_ornull *owner
	GdkAtom selection
	guint32 time_
	gboolean send_event
    C_ARGS:
	owner, selection, time_, send_event

##  GdkWindow* gdk_selection_owner_get (GdkAtom selection) 
GdkWindow_ornull*
gdk_selection_owner_get (class, selection)
	GdkAtom selection
    C_ARGS:
	selection

#if GTK_CHECK_VERSION(2,2,0)

##  gboolean gdk_selection_owner_set_for_display (GdkDisplay *display, GdkWindow *owner, GdkAtom selection, guint32 time_, gboolean send_event) 
gboolean
gdk_selection_owner_set_for_display (class, display, owner, selection, time_, send_event)
	GdkDisplay *display
	GdkWindow *owner
	GdkAtom selection
	guint32 time_
	gboolean send_event
    C_ARGS:
	display, owner, selection, time_, send_event

##  GdkWindow *gdk_selection_owner_get_for_display (GdkDisplay *display, GdkAtom selection) 
GdkWindow_ornull *
gdk_selection_owner_get_for_display (class, display, selection)
	GdkDisplay *display
	GdkAtom selection
    C_ARGS:
	display, selection

#endif /* >=2.2.0 */

##  void gdk_selection_convert (GdkWindow *requestor, GdkAtom selection, GdkAtom target, guint32 time_) 
void
gdk_selection_convert (class, requestor, selection, target, time_)
	GdkWindow *requestor
	GdkAtom selection
	GdkAtom target
	guint32 time_
    C_ARGS:
	requestor, selection, target, time_

  ## docs do not say deprecated, but recommend the use of GtkClipboard instead
##  gboolean gdk_selection_property_get (GdkWindow *requestor, guchar **data, GdkAtom *prop_type, gint *prop_format) 
=for apidoc
=for signature (data, prop_type, prop_format) = Gtk2::Gdk::Selection->property_get ($requestor)
Use Gtk2::Clipboard instead.
=cut
void
gdk_selection_property_get (class, requestor)
	GdkWindow *requestor
    PREINIT:
	guchar * data;
	GdkAtom prop_type;
	gint prop_format;
    PPCODE:
	if (!gdk_selection_property_get (requestor, &data, 
	                                 &prop_type, &prop_format))
		XSRETURN_EMPTY;
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSVpv ((gchar *) data, 0)));
	PUSHs (sv_2mortal (newSVGdkAtom (prop_type)));
	PUSHs (sv_2mortal (newSViv (prop_format)));
	g_free (data);
	

##  void gdk_selection_send_notify (guint32 requestor, GdkAtom selection, GdkAtom target, GdkAtom property, guint32 time_) 
void
gdk_selection_send_notify (class, requestor, selection, target, property, time_)
	guint32 requestor
	GdkAtom selection
	GdkAtom target
	GdkAtom property
	guint32 time_
    C_ARGS:
	requestor, selection, target, property, time_

#if GTK_CHECK_VERSION(2,2,0)

##  void gdk_selection_send_notify_for_display (GdkDisplay *display, guint32 requestor, GdkAtom selection, GdkAtom target, GdkAtom property, guint32 time_) 
void
gdk_selection_send_notify_for_display (class, display, requestor, selection, target, property, time_)
	GdkDisplay *display
	guint32 requestor
	GdkAtom selection
	GdkAtom target
	GdkAtom property
	guint32 time_
    C_ARGS:
	display, requestor, selection, target, property, time_

#endif /* >=2.2.0 */
