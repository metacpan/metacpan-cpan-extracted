/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::FileChooserDialog PACKAGE = Gtk2::FileChooserDialog PREFIX = gtk_file_chooser_dialog_

BOOT:
	/* GtkFileChooserDialog implements the GtkFileChooserIface */
	gperl_prepend_isa ("Gtk2::FileChooserDialog", "Gtk2::FileChooser");

=for apidoc Gtk2::FileChooserDialog::new_with_backend
=for signature widget = Gtk2::FileChooserDialog->new_with_backend ($title, $parent, $action, $backend, ...)
=for arg backend (gchar*)
=for arg ... (list) list of button-text => response-id pairs
=cut

=for apidoc Gtk2::FileChooserDialog::new
=for arg ... list of button-text => response-id pairs
=cut

GtkWidget *
gtk_file_chooser_dialog_new (class, gchar *title, GtkWindow_ornull *parent, GtkFileChooserAction action, ...)
    ALIAS:
	Gtk2::FileChooserDialog::new_with_backend = 1
    PREINIT:
	gint i, first_index;
	gchar *backend;
    CODE:
	if (ix == 1) {
		first_index = 5;
		backend = SvGChar (ST (4));
	} else {
		first_index = 4;
		backend = NULL;
	}

	if (0 != (items - first_index) % 2) {
		if (ix == 1)
			croak ("Usage: Gtk2::FileChooserDialog->new_with_backend (title, parent, action, backend, button-text => response-id, ...)\n"
			       "   expecting list of button-text => response-id pairs");
		else
			croak ("Usage: Gtk2::FileChooserDialog->new (title, parent, action, button-text => response-id, ...)\n"
			       "   expecting list of button-text => response-id pairs");
	}

	RETVAL = g_object_new (GTK_TYPE_FILE_CHOOSER_DIALOG,
	                       "title", title,
	                       "action", action,
	                       "file-system-backend", backend,
	                       NULL);

	if (parent)
		gtk_window_set_transient_for (GTK_WINDOW (RETVAL), parent);

	for (i = first_index ; i < items ; i+=2) {
		gchar * button_text = SvGChar (ST (i));
		gint response_id = SvGtkResponseType (ST (i+1));
		gtk_dialog_add_button (GTK_DIALOG (RETVAL), button_text, response_id);
	}
    OUTPUT:
	RETVAL
