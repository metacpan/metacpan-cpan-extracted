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

MODULE = Gtk2::List	PACKAGE = Gtk2::List	PREFIX = gtk_list_

=for position DESCRIPTION

=head1 DESCRIPTION

Gtk2::List is deprecated; use Gtk2::TreeView and a Gtk2::ListStore instead.

Gtk2::List is included in Gtk2-Perl only because Gtk2::Combo still makes
use of it, and Gtk2::Combo's replacement, Gtk2::ComboBox, didn't appear in
gtk+ until 2.4.0.

=cut

#ifdef GTK_TYPE_LIST

##  GtkWidget* gtk_list_new (void) 
GtkWidget *
gtk_list_new (class)
    C_ARGS:
	/* void */

## parameter order flipped on this function so the item
## list soaks up the rest of the arg stack
##  void gtk_list_insert_items (GtkList *list, GList *items, gint position) 
=for apidoc
=for arg ... of Gtk2::ListItem's to be inserted
=cut
void
gtk_list_insert_items (list, position, ...)
	GtkList       * list
	gint            position
    PREINIT:
	GList * list_items = NULL;
    CODE:
	for( items--; items > 0; items-- )
		list_items = g_list_prepend(list_items, 
					SvGtkListItem(ST(items)));
	if( list_items )
	{
		gtk_list_insert_items(list, list_items, position);
		g_list_free(list_items);
	}

##  void gtk_list_append_items (GtkList *list, GList *items) 
=for apidoc
=for arg ... of Gtk2::ListItem's to be appended
=cut
void
gtk_list_append_items (list, ...)
	GtkList       * list
    PREINIT:
	GList * list_items = NULL;
    CODE:
	for( items--; items > 0; items-- )
		list_items = g_list_prepend(list_items, 
					SvGtkListItem(ST(items)));
	if( list_items )
	{
		gtk_list_append_items(list, list_items);
		g_list_free(list_items);
	}

##  void gtk_list_prepend_items (GtkList *list, GList *items) 
=for apidoc
=for arg list_item (GtkListItem)
=for arg ... of Gtk2::ListItem's to be prepended
=cut
void
gtk_list_prepend_items (list, ...)
	GtkList       * list
    PREINIT:
	GList * list_items = NULL;
    CODE:
	for( items--; items > 0; items-- )
		list_items = g_list_prepend(list_items, 
					SvGtkListItem(ST(items)));
	if( list_items )
	{
		gtk_list_prepend_items(list, list_items);
		g_list_free(list_items);
	}

##  void gtk_list_remove_items (GtkList *list, GList *items) 
=for apidoc
=for arg list_item (GtkListItem)
=for arg ... of Gtk2::ListItem's to be removed
=cut
void
gtk_list_remove_items (list, ...)
	GtkList       * list
    PREINIT:
	GList * list_items = NULL;
    CODE:
	for( items--; items > 0; items-- )
		list_items = g_list_prepend(list_items, 
					SvGtkListItem(ST(items)));
	if( list_items )
	{
		gtk_list_remove_items(list, list_items);
		g_list_free(list_items);
	}

## should this function be through since perl handles the ref counting, i'm
## going to go with no till i hear otherwise
##  void gtk_list_remove_items_no_unref (GtkList *list, GList *items) 
##void
##gtk_list_remove_items_no_unref (list, list_item, ...)
##	GtkList       * list
##	GtkListItem   * list_item
##    PREINIT:
##	GList * list_items = NULL;
##    CODE:
##	for( items--; items > 0; items-- )
##		list_items = g_list_prepend(list_items, 
##					SvGtkListItem(ST(items)));
##	if( list_items )
##	{
##		gtk_list_remove_items_no_unref(list, list_items);
##		g_list_free(list_items);
##	}

##  void gtk_list_clear_items (GtkList *list, gint start, gint end) 
void
gtk_list_clear_items (list, start, end)
	GtkList * list
	gint      start
	gint      end

##  void gtk_list_select_item (GtkList *list, gint item) 
void
gtk_list_select_item (list, item)
	GtkList * list
	gint      item

##  void gtk_list_unselect_item (GtkList *list, gint item) 
void
gtk_list_unselect_item (list, item)
	GtkList * list
	gint      item

##  void gtk_list_select_child (GtkList *list, GtkWidget *child) 
void
gtk_list_select_child (list, child)
	GtkList   * list
	GtkWidget * child

##  void gtk_list_unselect_child (GtkList *list, GtkWidget *child) 
void
gtk_list_unselect_child (list, child)
	GtkList   * list
	GtkWidget * child

##  gint gtk_list_child_position (GtkList *list, GtkWidget *child) 
gint
gtk_list_child_position (list, child)
	GtkList   * list
	GtkWidget * child

##  void gtk_list_set_selection_mode (GtkList *list, GtkSelectionMode mode) 
void
gtk_list_set_selection_mode (list, mode)
	GtkList          * list
	GtkSelectionMode   mode

##  void gtk_list_extend_selection (GtkList *list, GtkScrollType scroll_type, gfloat position, gboolean auto_start_selection) 
void
gtk_list_extend_selection (list, scroll_type, position, auto_start_selection)
	GtkList       * list
	GtkScrollType   scroll_type
	gfloat          position
	gboolean        auto_start_selection

##  void gtk_list_start_selection (GtkList *list) 
void
gtk_list_start_selection (list)
	GtkList * list

##  void gtk_list_end_selection (GtkList *list) 
void
gtk_list_end_selection (list)
	GtkList * list

##  void gtk_list_select_all (GtkList *list) 
void
gtk_list_select_all (list)
	GtkList *list

##  void gtk_list_unselect_all (GtkList *list) 
void
gtk_list_unselect_all (list)
	GtkList *list

##  void gtk_list_scroll_horizontal (GtkList *list, GtkScrollType scroll_type, gfloat position) 
void
gtk_list_scroll_horizontal (list, scroll_type, position)
	GtkList *list
	GtkScrollType scroll_type
	gfloat position

##  void gtk_list_scroll_vertical (GtkList *list, GtkScrollType scroll_type, gfloat position) 
void
gtk_list_scroll_vertical (list, scroll_type, position)
	GtkList *list
	GtkScrollType scroll_type
	gfloat position

##  void gtk_list_toggle_add_mode (GtkList *list) 
void
gtk_list_toggle_add_mode (list)
	GtkList *list

##  void gtk_list_toggle_focus_row (GtkList *list) 
void
gtk_list_toggle_focus_row (list)
	GtkList *list

##  void gtk_list_toggle_row (GtkList *list, GtkWidget *item) 
void
gtk_list_toggle_row (list, item)
	GtkList *list
	GtkWidget *item

##  void gtk_list_undo_selection (GtkList *list) 
void
gtk_list_undo_selection (list)
	GtkList *list

##  void gtk_list_end_drag_selection (GtkList *list) 
void
gtk_list_end_drag_selection (list)
	GtkList *list

#endif /* GTK_TYPE_LIST */
