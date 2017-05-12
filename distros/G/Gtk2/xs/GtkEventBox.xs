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

MODULE = Gtk2::EventBox	PACKAGE = Gtk2::EventBox	PREFIX = gtk_event_box_

## GtkWidget* gtk_event_box_new (void)
GtkWidget *
gtk_event_box_new (class)
    C_ARGS:
	/* void */

#if GTK_CHECK_VERSION(2,4,0)

gboolean gtk_event_box_get_visible_window (GtkEventBox *event_box);

void gtk_event_box_set_visible_window (GtkEventBox *event_box, gboolean visible_window);

gboolean gtk_event_box_get_above_child (GtkEventBox *event_box);

void gtk_event_box_set_above_child (GtkEventBox *event_box, gboolean above_child);

#endif
