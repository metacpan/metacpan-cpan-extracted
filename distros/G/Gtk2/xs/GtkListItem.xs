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
 *
 * NOTE: GtkList and GtkListItem are deprecated and only included b/c GtkCombo
 * still makes use of them, they are subject to removal at any point so you
 * should not utilize them unless absolutly necessary.)
 *
 */

#include "gtk2perl.h"

MODULE = Gtk2::ListItem	PACKAGE = Gtk2::ListItem	PREFIX = gtk_list_item_

=for position DESCRIPTION

=head1 DESCRIPTION

Gtk2::ListItem is the widget used for each item in a Gtk2::List.  Gtk2::List
and Gtk2::ListItem are deprecated; use Gtk2::TreeView and a Gtk2::ListStore
instead.

Gtk2::ListItem is included in Gtk2-Perl only because Gtk2::Combo contains a
Gtk2::List, and Gtk2::Combo's replacement, Gtk2::ComboBox, didn't appear in
gtk+ until 2.4.0.

=cut

#ifdef GTK_TYPE_LIST_ITEM

##  GtkWidget* gtk_list_item_new (void) 
##  GtkWidget* gtk_list_item_new_with_label (const gchar *label) 
GtkWidget *
gtk_list_item_new (class, label=NULL)
	gchar * label
    ALIAS:
	Gtk2::ListItem::new_with_label = 1
    CODE:
	PERL_UNUSED_VAR (ix);
	if( label )
		RETVAL = gtk_list_item_new_with_label(label);
	else
		RETVAL = gtk_list_item_new();
    OUTPUT:
	RETVAL

##  void gtk_list_item_select (GtkListItem *list_item) 
void
gtk_list_item_select (list_item)
	GtkListItem * list_item

##  void gtk_list_item_deselect (GtkListItem *list_item) 
void
gtk_list_item_deselect (list_item)
	GtkListItem * list_item

#endif

