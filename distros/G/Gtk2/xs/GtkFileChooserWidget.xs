/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::FileChooserWidget	PACKAGE = Gtk2::FileChooserWidget	PREFIX = gtk_file_chooser_widget_

BOOT:
	/* GtkFileChooserWidget implements the GtkFileChooserIface */
	gperl_prepend_isa ("Gtk2::FileChooserWidget", "Gtk2::FileChooser");
	/* apparently private, but still in list_interfaces 
	gperl_set_isa ("Gtk2::FileChooserWidget", "Gtk2::FileChooserEmbed");
	 */

GtkWidget *gtk_file_chooser_widget_new (class, GtkFileChooserAction action);
    C_ARGS:
	action

GtkWidget *gtk_file_chooser_widget_new_with_backend (class, GtkFileChooserAction action, const gchar *backend);
    C_ARGS:
	action, backend
