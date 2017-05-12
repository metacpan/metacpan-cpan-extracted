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

MODULE = Gtk2::Item	PACKAGE = Gtk2::Item	PREFIX = gtk_item_

## void gtk_item_select (GtkItem *item)
void
gtk_item_select (item)
	GtkItem * item

## void gtk_item_deselect (GtkItem *item)
void
gtk_item_deselect (item)
	GtkItem * item

## void gtk_item_toggle (GtkItem *item)
void
gtk_item_toggle (item)
	GtkItem * item

