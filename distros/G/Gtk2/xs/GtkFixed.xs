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

MODULE = Gtk2::Fixed	PACKAGE = Gtk2::Fixed	PREFIX = gtk_fixed_

## GtkWidget* gtk_fixed_new (void)
GtkWidget *
gtk_fixed_new (class)
    C_ARGS:
	/* void */

## void gtk_fixed_put (GtkFixed *fixed, GtkWidget *widget, gint x, gint y)
void
gtk_fixed_put (fixed, widget, x, y)
	GtkFixed  * fixed
	GtkWidget * widget
	gint        x
	gint        y

## void gtk_fixed_move (GtkFixed *fixed, GtkWidget *widget, gint x, gint y)
void
gtk_fixed_move (fixed, widget, x, y)
	GtkFixed  * fixed
	GtkWidget * widget
	gint        x
	gint        y

## void gtk_fixed_set_has_window (GtkFixed *fixed, gboolean has_window)
void
gtk_fixed_set_has_window (fixed, has_window)
	GtkFixed * fixed
	gboolean   has_window

## gboolean gtk_fixed_get_has_window (GtkFixed *fixed)
gboolean
gtk_fixed_get_has_window (fixed)
	GtkFixed * fixed

