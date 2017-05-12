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

MODULE = Gtk2::Invisible	PACKAGE = Gtk2::Invisible	PREFIX = gtk_invisible_

## GtkWidget* gtk_invisible_new (void)
GtkWidget *
gtk_invisible_new (class)
    C_ARGS:
	/* void */

#if GTK_CHECK_VERSION(2,2,0)

##GtkWidget * gtk_invisible_new_for_screen (GdkScreen *screen)
GtkWidget *
gtk_invisible_new_for_screen (class, screen)
	GdkScreen *screen
    C_ARGS:
	screen

##void gtk_invisible_set_screen (GtkInvisible *invisible, GdkScreen *screen)
void gtk_invisible_set_screen (invisible, screen)
	GtkInvisible *invisible
	GdkScreen *screen

##GdkScreen * gtk_invisible_get_screen (GtkInvisible *invisible)
GdkScreen * gtk_invisible_get_screen (invisible)
	GtkInvisible *invisible

#endif
