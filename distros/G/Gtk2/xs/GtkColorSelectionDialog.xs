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

MODULE = Gtk2::ColorSelectionDialog	PACKAGE = Gtk2::ColorSelectionDialog	PREFIX = gtk_color_selection_dialog_

=for apidoc colorsel __hide__
=cut

GtkWidget *
get_color_selection (dialog)
	GtkColorSelectionDialog *dialog
    ALIAS:
	colorsel = 1
	ok_button = 2
	cancel_button = 3
	help_button = 4
    CODE:
	switch (ix) {
	    case 0:
	    case 1:
#if GTK_CHECK_VERSION (2, 14, 0)
		RETVAL = gtk_color_selection_dialog_get_color_selection (dialog);
#else
		RETVAL = dialog->colorsel;
#endif /* 2.14 */
		break;
	    case 2: RETVAL = dialog->ok_button; break;
	    case 3: RETVAL = dialog->cancel_button; break;
	    case 4: RETVAL = dialog->help_button; break;
	    default:
		RETVAL = NULL;
		g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL


## GtkWidget* gtk_color_selection_dialog_new (const gchar *title)
GtkWidget *
gtk_color_selection_dialog_new (class, title)
	const gchar * title
    C_ARGS:
	title

