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

MODULE = Gtk2::VScale	PACKAGE = Gtk2::VScale	PREFIX = gtk_vscale_

## GtkWidget* gtk_vscale_new (GtkAdjustment *adjustment)
GtkWidget *
gtk_vscale_new (class, adjustment=NULL)
	GtkAdjustment_ornull * adjustment
    C_ARGS:
	adjustment

## GtkWidget* gtk_vscale_new_with_range (gdouble min, gdouble max, gdouble step)
GtkWidget *
gtk_vscale_new_with_range (class, min, max, step)
	gdouble min
	gdouble max
	gdouble step
    C_ARGS:
	min, max, step

