/*
 * Copyright (c) 2004-2006 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::FileChooserButton	PACKAGE = Gtk2::FileChooserButton	PREFIX = gtk_file_chooser_button_

BOOT:
	gperl_prepend_isa ("Gtk2::FileChooserButton", "Gtk2::FileChooser");

##  GtkWidget * gtk_file_chooser_button_new (const gchar *title, GtkFileChooserAction action)
GtkWidget *
gtk_file_chooser_button_new (class, title, action)
	const gchar *title
	GtkFileChooserAction action
    C_ARGS:
	title, action

##  GtkWidget * gtk_file_chooser_button_new_with_backend (const gchar *title, GtkFileChooserAction action, const gchar *backend)
GtkWidget *
gtk_file_chooser_button_new_with_backend (class, title, action, backend)
	const gchar *title
	GtkFileChooserAction action
	const gchar *backend
    C_ARGS:
	title, action, backend

##  GtkWidget * gtk_file_chooser_button_new_with_dialog (GtkWidget *dialog)
GtkWidget *
gtk_file_chooser_button_new_with_dialog (class, dialog)
	GtkWidget *dialog
    C_ARGS:
	dialog

const gchar *gtk_file_chooser_button_get_title (GtkFileChooserButton *button);

void gtk_file_chooser_button_set_title (GtkFileChooserButton *button, const gchar *title);

gint gtk_file_chooser_button_get_width_chars (GtkFileChooserButton *button);

void gtk_file_chooser_button_set_width_chars (GtkFileChooserButton *button, gint n_chars);

#if GTK_CHECK_VERSION (2, 10, 0)

void gtk_file_chooser_button_set_focus_on_click (GtkFileChooserButton *button, gboolean focus_on_click)

gboolean gtk_file_chooser_button_get_focus_on_click (GtkFileChooserButton *button)

#endif
