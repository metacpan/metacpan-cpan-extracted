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

MODULE = Gtk2::CheckButton	PACKAGE = Gtk2::CheckButton	PREFIX = gtk_check_button_

## GtkWidget* gtk_check_button_new (void)
## GtkWidget* gtk_check_button_new_with_mnemonic (const gchar *label)
## GtkWidget* gtk_check_button_new_with_label (const gchar *label)
GtkWidget*
gtk_check_button_new (class, label=NULL)
	const gchar * label
    ALIAS:
	Gtk2::CheckButton::new_with_mnemonic = 1
	Gtk2::CheckButton::new_with_label = 2
    CODE:
	if (label) {
		if (ix == 2)
			RETVAL = gtk_check_button_new_with_label (label);
		else /* if (ix == 1) */
			RETVAL = gtk_check_button_new_with_mnemonic (label);
	} else
		RETVAL = gtk_check_button_new ();
    OUTPUT:
	RETVAL

## void _gtk_check_button_get_props (GtkCheckButton *check_button, gint *indicator_size, gint *indicator_spacing)
