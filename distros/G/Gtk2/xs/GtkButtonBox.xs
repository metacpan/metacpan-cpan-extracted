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

MODULE = Gtk2::ButtonBox	PACKAGE = Gtk2::ButtonBox	PREFIX = gtk_button_box_

=for enum GtkButtonBoxStyle

=cut

## GtkButtonBoxStyle gtk_button_box_get_layout (GtkButtonBox *widget)
GtkButtonBoxStyle
gtk_button_box_get_layout (widget)
	GtkButtonBox * widget

## void gtk_button_box_set_layout (GtkButtonBox *widget, GtkButtonBoxStyle layout_style)
void
gtk_button_box_set_layout (widget, layout_style)
	GtkButtonBox      * widget
	GtkButtonBoxStyle   layout_style

#if GTK_CHECK_VERSION(2,4,0)

gboolean gtk_button_box_get_child_secondary (GtkButtonBox * widget, GtkWidget * child)

#endif

## void gtk_button_box_set_child_secondary (GtkButtonBox *widget, GtkWidget *child, gboolean is_secondary)
void
gtk_button_box_set_child_secondary (widget, child, is_secondary)
	GtkButtonBox * widget
	GtkWidget    * child
	gboolean       is_secondary

##void _gtk_button_box_child_requisition (GtkWidget *widget, int *nvis_children, int *nvis_secondaries, int *width, int *height)
