/*
 * Copyright (c) 2003-2006 by the gtk2-perl team (see the file AUTHORS)
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

MODULE = Gtk2::SizeGroup	PACKAGE = Gtk2::SizeGroup	PREFIX = gtk_size_group_

=for enum GtkSizeGroupMode
=cut

##  GtkSizeGroup * gtk_size_group_new (GtkSizeGroupMode mode) 
GtkSizeGroup_noinc *
gtk_size_group_new (class, mode)
	GtkSizeGroupMode mode
    C_ARGS:
	mode

##  void gtk_size_group_set_mode (GtkSizeGroup *size_group, GtkSizeGroupMode mode) 
void
gtk_size_group_set_mode (size_group, mode)
	GtkSizeGroup *size_group
	GtkSizeGroupMode mode

##  GtkSizeGroupMode gtk_size_group_get_mode (GtkSizeGroup *size_group) 
GtkSizeGroupMode
gtk_size_group_get_mode (size_group)
	GtkSizeGroup *size_group

##  void gtk_size_group_add_widget (GtkSizeGroup *size_group, GtkWidget *widget) 
void
gtk_size_group_add_widget (size_group, widget)
	GtkSizeGroup *size_group
	GtkWidget *widget

##  void gtk_size_group_remove_widget (GtkSizeGroup *size_group, GtkWidget *widget) 
void
gtk_size_group_remove_widget (size_group, widget)
	GtkSizeGroup *size_group
	GtkWidget *widget

#if GTK_CHECK_VERSION (2, 8, 0)

void gtk_size_group_set_ignore_hidden (GtkSizeGroup *size_group, gboolean ignore_hidden);

gboolean gtk_size_group_get_ignore_hidden (GtkSizeGroup *size_group);

#endif /* 2.8 */

#if GTK_CHECK_VERSION (2, 10, 0)

## the returned list is owned by GTK+ and should not be modified.
void gtk_size_group_get_widgets (GtkSizeGroup *size_group)
    PREINIT:
        GSList * widgets;
    PPCODE:
        widgets = gtk_size_group_get_widgets (size_group);
        while (widgets) {
                XPUSHs (sv_2mortal (newSVGtkWidget (widgets->data)));
                widgets = widgets->next;
        }

#endif /* 2.10 */
