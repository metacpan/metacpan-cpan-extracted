/*
 * Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS)
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the LICENSE file in the top level of this distribution
 * for the complete license terms.
 *
 */

#include "gnome2perl.h"

MODULE = Gnome2::PasswordDialog		PACKAGE = Gnome2::PasswordDialog	PREFIX = gnome_password_dialog_

BOOT:
/* pass -Werror even if there are no xsubs at all */
#ifndef GNOME_TYPE_PASSWORD_DIALOG
	PERL_UNUSED_VAR (file);
#endif

#ifdef GNOME_TYPE_PASSWORD_DIALOG

##  GtkWidget* gnome_password_dialog_new (const char *dialog_title, const char *message, const char *username, const char *password, gboolean readonly_username) 
GtkWidget*
gnome_password_dialog_new (class, dialog_title, message, username, password, readonly_username)
	const char *dialog_title
	const char *message
	const char *username
	const char *password
	gboolean readonly_username
    C_ARGS:
	dialog_title, message, username, password, readonly_username

##  gboolean gnome_password_dialog_run_and_block (GnomePasswordDialog *password_dialog) 
gboolean
gnome_password_dialog_run_and_block (password_dialog)
	GnomePasswordDialog *password_dialog

##  void gnome_password_dialog_set_username (GnomePasswordDialog *password_dialog, const char *username) 
void
gnome_password_dialog_set_username (password_dialog, username)
	GnomePasswordDialog *password_dialog
	const char *username

##  void gnome_password_dialog_set_password (GnomePasswordDialog *password_dialog, const char *password) 
void
gnome_password_dialog_set_password (password_dialog, password)
	GnomePasswordDialog *password_dialog
	const char *password

##  void gnome_password_dialog_set_readonly_username (GnomePasswordDialog *password_dialog, gboolean readonly) 
void
gnome_password_dialog_set_readonly_username (password_dialog, readonly)
	GnomePasswordDialog *password_dialog
	gboolean readonly

##  char * gnome_password_dialog_get_username (GnomePasswordDialog *password_dialog) 
char *
gnome_password_dialog_get_username (password_dialog)
	GnomePasswordDialog *password_dialog
    CLEANUP:
	g_free (RETVAL);

##  char * gnome_password_dialog_get_password (GnomePasswordDialog *password_dialog) 
char *
gnome_password_dialog_get_password (password_dialog)
	GnomePasswordDialog *password_dialog
    CLEANUP:
	g_free (RETVAL);

# --------------------------------------------------------------------------- #

#if LIBGNOMEUI_CHECK_VERSION (2, 6, 0)

## void gnome_password_dialog_set_show_username (GnomePasswordDialog *password_dialog, gboolean show)
void
gnome_password_dialog_set_show_username (password_dialog, show)
	GnomePasswordDialog *password_dialog
	gboolean show

## void gnome_password_dialog_set_show_domain (GnomePasswordDialog *password_dialog, gboolean show)
void
gnome_password_dialog_set_show_domain (password_dialog, show)
	GnomePasswordDialog *password_dialog
	gboolean show

## void gnome_password_dialog_set_show_password (GnomePasswordDialog *password_dialog, gboolean show)
void
gnome_password_dialog_set_show_password (password_dialog, show)
	GnomePasswordDialog *password_dialog
	gboolean show

##  void gnome_password_dialog_set_domain (GnomePasswordDialog *password_dialog, const char *domain) 
void
gnome_password_dialog_set_domain (password_dialog, domain)
	GnomePasswordDialog *password_dialog
	const char *domain

##  void gnome_password_dialog_set_readonly_domain (GnomePasswordDialog *password_dialog, gboolean readonly) 
void
gnome_password_dialog_set_readonly_domain (password_dialog, readonly)
	GnomePasswordDialog *password_dialog
	gboolean readonly

##  void gnome_password_dialog_set_show_remember (GnomePasswordDialog *password_dialog, gboolean show_remember) 
void
gnome_password_dialog_set_show_remember (password_dialog, show_remember)
	GnomePasswordDialog *password_dialog
	gboolean show_remember

##  void gnome_password_dialog_set_remember (GnomePasswordDialog *password_dialog, GnomePasswordDialogRemember remember) 
void
gnome_password_dialog_set_remember (password_dialog, remember)
	GnomePasswordDialog *password_dialog
	GnomePasswordDialogRemember remember

##  GnomePasswordDialogRemember gnome_password_dialog_get_remember (GnomePasswordDialog *password_dialog) 
GnomePasswordDialogRemember
gnome_password_dialog_get_remember (password_dialog)
	GnomePasswordDialog *password_dialog

##  char * gnome_password_dialog_get_domain (GnomePasswordDialog *password_dialog) 
char *
gnome_password_dialog_get_domain (password_dialog)
	GnomePasswordDialog *password_dialog
    CLEANUP:
	g_free (RETVAL);

#endif /* 2.6.0 */

# --------------------------------------------------------------------------- #

#if LIBGNOMEUI_CHECK_VERSION (2, 8, 0)

##  void gnome_password_dialog_set_show_userpass_buttons (GnomePasswordDialog *password_dialog, gboolean show_userpass_buttons)
void
gnome_password_dialog_set_show_userpass_buttons (password_dialog, show_userpass_buttons)
	GnomePasswordDialog *password_dialog
	gboolean show_userpass_buttons

##  gboolean gnome_password_dialog_anon_selected (GnomePasswordDialog *password_dialog)
gboolean
gnome_password_dialog_anon_selected (password_dialog)
	GnomePasswordDialog *password_dialog

#endif /* 2.8.0 */

#endif /* GNOME_TYPE_PASSWORD_DIALOG */
