/*
 * Copyright (c) 2010 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::OffscreenWindow	PACKAGE = Gtk2::OffscreenWindow	PREFIX = gtk_offscreen_window_

GtkWidget *
gtk_offscreen_window_new (class)
    C_ARGS:
	/* void */

# Docs say we don't own the pixmap.
GdkPixmap_ornull * gtk_offscreen_window_get_pixmap (GtkOffscreenWindow *offscreen);

# Docs say we do own the pixbuf
GdkPixbuf_noinc_ornull * gtk_offscreen_window_get_pixbuf (GtkOffscreenWindow *offscreen);
