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

MODULE = Gtk2::Combo	PACKAGE = Gtk2::Combo	PREFIX = gtk_combo_

=for deprecated_by Gtk2::ComboBox
=cut

## GtkWidget* gtk_combo_new (void)
GtkWidget*
gtk_combo_new (class)
    C_ARGS:
	/* void */

## void gtk_combo_disable_activate (GtkCombo* combo)
void
gtk_combo_disable_activate (combo)
	GtkCombo * combo

##void gtk_combo_set_value_in_list (GtkCombo* combo, gboolean val, gboolean ok_if_empty)
void
gtk_combo_set_value_in_list (combo, val, ok_if_empty)
	GtkCombo * combo
	gboolean   val
	gboolean   ok_if_empty

##void gtk_combo_set_use_arrows (GtkCombo* combo, gboolean val)
void
gtk_combo_set_use_arrows (combo, val)
	GtkCombo * combo
	gboolean   val

##void gtk_combo_set_use_arrows_always (GtkCombo* combo, gboolean val)
void
gtk_combo_set_use_arrows_always (combo, val)
	GtkCombo * combo
	gboolean   val

##void gtk_combo_set_case_sensitive (GtkCombo* combo, gboolean val)
void
gtk_combo_set_case_sensitive (combo, val)
	GtkCombo * combo
	gboolean   val

##void gtk_combo_set_item_string (GtkCombo* combo, GtkItem* item, const gchar* item_value)
void
gtk_combo_set_item_string (combo, item, item_value)
	GtkCombo * combo
	GtkItem  * item
	gchar    * item_value

##void gtk_combo_set_popdown_strings (GtkCombo* combo, GList *strings)
=for apidoc
=for arg ... of strings
=cut
void
gtk_combo_set_popdown_strings (combo, ...)
	GtkCombo * combo
    PREINIT:
	GList * strings = NULL;
    CODE:
	for( items--; items > 0; items-- )
		strings = g_list_prepend(strings, SvGChar(ST(items)));
	if( strings )
	{
		gtk_combo_set_popdown_strings(combo, strings);
		g_list_free(strings);
	}

GtkWidget *
entry (combo)
	GtkCombo * combo
    ALIAS:
	Gtk2::Combo::list = 1
    CODE:
	switch (ix) {
	    case 0: RETVAL = combo->entry; break;
	    case 1: RETVAL = combo->list;  break;
	    default:
		RETVAL = NULL;
		g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

