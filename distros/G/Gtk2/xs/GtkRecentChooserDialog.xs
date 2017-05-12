/*
 * Copyright (c) 2006 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::RecentChooserDialog	PACKAGE = Gtk2::RecentChooserDialog	PREFIX = gtk_recent_chooser_dialog_

BOOT:
	gperl_prepend_isa ("Gtk2::RecentChooserDialog", "Gtk2::RecentChooser");

=for apidoc Gtk2::RecentChooserDialog::new_for_manager
=for signature widget = Gtk2::RecentChooserDialog->new_for_manager ($title, $parent, $manager, ...)
=for arg manager (Gtk2::RecentManager)
=for arg ... (list) list of button-text => response-id pairs
=cut

=for apidoc Gtk2::RecentChooserDialog::new
=for arg ... list of button-text => response-id pairs
=cut

GtkWidget *
gtk_recent_chooser_dialog_new (class, gchar *title, GtkWindow_ornull *parent, ...)
    ALIAS:
        Gtk2::RecentChooserDialog::new_for_manager = 1
    PREINIT:
        gint i, first_index;
	GtkRecentManager *manager;
    CODE:
        if (ix == 1) {
		first_index = 4;
		manager = SvGtkRecentManager (ST (3));
	}
	else {
		first_index = 3;
		manager = NULL;
	}

	if (0 != (items - first_index) % 2) {
		if (ix == 1) {
			croak ("Usage: Gtk2::RecentChooserDialog->new_for_manager (title, parent, manager, button-text => response-id, ...)\n"
			       "   expecting list of button-text => response-id pairs");
		}
		else {
			croak ("Usage: Gtk2::RecentChooserDialog->new (title, parent, button-text => response-id, ...)\n"
			       "   expecting list of button-text => response-id pairs");
		}
	}

	RETVAL = g_object_new (GTK_TYPE_RECENT_CHOOSER_DIALOG,
			       "title", title,
			       "recent-manager", manager,
			       NULL);
	if (parent)
		gtk_window_set_transient_for (GTK_WINDOW (RETVAL), parent);

	for (i = first_index; i < items; i += 2) {
		gchar *button_text = SvGChar (ST (i));
		gint response_id = SvGtkResponseType (ST (i + 1));

		gtk_dialog_add_button (GTK_DIALOG (RETVAL), button_text, response_id);
	}
    OUTPUT:
        RETVAL
