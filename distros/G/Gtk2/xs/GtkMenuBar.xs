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

MODULE = Gtk2::MenuBar	PACKAGE = Gtk2::MenuBar	PREFIX = gtk_menu_bar_

## GtkWidget* gtk_menu_bar_new (void)
GtkWidget *
gtk_menu_bar_new (class)
    C_ARGS:
	/* void */

#if GTK_CHECK_VERSION (2, 8, 0)

GtkPackDirection gtk_menu_bar_get_child_pack_direction (GtkMenuBar *menubar);

void gtk_menu_bar_set_child_pack_direction (GtkMenuBar *menubar, GtkPackDirection child_pack_dir);

GtkPackDirection gtk_menu_bar_get_pack_direction (GtkMenuBar *menubar);

void gtk_menu_bar_set_pack_direction (GtkMenuBar *menubar, GtkPackDirection pack_dir);

#endif

##void _gtk_menu_bar_cycle_focus (GtkMenuBar *menubar, GtkDirectionType dir
