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

MODULE = Gtk2::Layout	PACKAGE = Gtk2::Layout	PREFIX = gtk_layout_

=for apidoc bin_window __hide__
=cut

## GdkWindow* gtk_layout_get_bin_window (GtkLayout *layout)
GdkWindow_ornull *
get_bin_window (layout)
	GtkLayout * layout
    ALIAS:
	bin_window = 1
    CODE:
	PERL_UNUSED_VAR (ix);
#if GTK_CHECK_VERSION (2, 14, 0)
	RETVAL = gtk_layout_get_bin_window (layout);
#else
	RETVAL = layout->bin_window;
#endif /* 2.14 */
    OUTPUT:
	RETVAL

## GtkWidget* gtk_layout_new (GtkAdjustment *hadjustment, GtkAdjustment *vadjustment)
GtkWidget *
gtk_layout_new (class, hadjustment=NULL, vadjustment=NULL)
	GtkAdjustment_ornull * hadjustment
	GtkAdjustment_ornull * vadjustment
    C_ARGS:
	hadjustment, vadjustment

## void gtk_layout_put (GtkLayout *layout, GtkWidget *child_widget, gint x, gint y)
void
gtk_layout_put (layout, child_widget, x, y)
	GtkLayout * layout
	GtkWidget * child_widget
	gint        x
	gint        y

## void gtk_layout_move (GtkLayout *layout, GtkWidget *child_widget, gint x, gint y)
void
gtk_layout_move (layout, child_widget, x, y)
	GtkLayout * layout
	GtkWidget * child_widget
	gint        x
	gint        y


## void gtk_layout_set_size (GtkLayout *layout, guint width, guint height)
void
gtk_layout_set_size (layout, width, height)
	GtkLayout * layout
	guint       width
	guint       height

## void gtk_layout_get_size (GtkLayout *layout, guint *width, guint *height)
void
gtk_layout_get_size (GtkLayout * layout, OUTLIST guint width, OUTLIST guint height)

## GtkAdjustment* gtk_layout_get_hadjustment (GtkLayout *layout)
GtkAdjustment *
gtk_layout_get_hadjustment (layout)
	GtkLayout * layout

## GtkAdjustment* gtk_layout_get_vadjustment (GtkLayout *layout)
GtkAdjustment *
gtk_layout_get_vadjustment (layout)
	GtkLayout * layout

## void gtk_layout_set_hadjustment (GtkLayout *layout, GtkAdjustment *adjustment)
void
gtk_layout_set_hadjustment (layout, adjustment)
	GtkLayout     * layout
	GtkAdjustment * adjustment

## void gtk_layout_set_vadjustment (GtkLayout *layout, GtkAdjustment *adjustment)
void
gtk_layout_set_vadjustment (layout, adjustment)
	GtkLayout     * layout
	GtkAdjustment * adjustment

## void gtk_layout_thaw (GtkLayout *layout)
void
gtk_layout_thaw (layout)
	GtkLayout * layout

##void gtk_layout_freeze (GtkLayout *layout)
void
gtk_layout_freeze (layout)
	GtkLayout * layout

