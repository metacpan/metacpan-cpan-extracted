/*
 * Copyright (c) 2006 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

static GPerlCallback *
gtk2perl_print_settings_func_create (SV * func, SV * data)
{
	GType param_types [2];
	param_types[0] = G_TYPE_STRING;
	param_types[1] = G_TYPE_STRING;
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, 0);
}

static void
gtk2perl_print_settings_func (const gchar *key, const gchar *value, gpointer data)
{
	gperl_callback_invoke ((GPerlCallback *) data, NULL, key, value);
}

MODULE = Gtk2::PrintSettings	PACKAGE = Gtk2::PrintSettings	PREFIX = gtk_print_settings_

# GtkPrintSettings * gtk_print_settings_new (void);
GtkPrintSettings_noinc * gtk_print_settings_new (class)
    C_ARGS:
	/* void */

# Needed?
# GtkPrintSettings * gtk_print_settings_copy (GtkPrintSettings *other);

gboolean gtk_print_settings_has_key (GtkPrintSettings *settings, const gchar *key);

const gchar_ornull * gtk_print_settings_get (GtkPrintSettings *settings, const gchar *key);

void gtk_print_settings_set (GtkPrintSettings *settings, const gchar *key, const gchar_ornull *value);

void gtk_print_settings_unset (GtkPrintSettings *settings, const gchar *key);

# void gtk_print_settings_foreach (GtkPrintSettings *settings, GtkPrintSettingsFunc func, gpointer user_data);
void
gtk_print_settings_foreach (GtkPrintSettings *settings, SV *func, SV *data=NULL)
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = gtk2perl_print_settings_func_create (func, data);
	gtk_print_settings_foreach (settings, gtk2perl_print_settings_func,
	                            callback);
	gperl_callback_destroy (callback);

#if GTK_CHECK_VERSION (2, 12, 0)

# GtkPrintSettings * gtk_print_settings_new_from_file (const gchar *file_name, GError **error);
=for apidoc __gerror__
=cut
GtkPrintSettings_noinc * gtk_print_settings_new_from_file (class, GPerlFilename file_name)
    PREINIT:
	GError *error = NULL;
    CODE:
	RETVAL = gtk_print_settings_new_from_file (file_name, &error);
	if (error)
		gperl_croak_gerror (NULL, error);
    OUTPUT:
	RETVAL

# gboolean gtk_print_settings_to_file (GtkPrintSettings *settings, const gchar *file_name, GError **error);
=for apidoc __gerror__
=cut
void gtk_print_settings_to_file (GtkPrintSettings *settings, GPerlFilename file_name)
    PREINIT:
	GError *error = NULL;
    CODE:
	if (!gtk_print_settings_to_file (settings, file_name, &error))
		gperl_croak_gerror (NULL, error);

# GtkPrintSettings * gtk_print_settings_new_from_key_file (GKeyFile *key_file, const gchar *group_name, GError **error);
=for apidoc __gerror__
=cut
GtkPrintSettings_noinc * gtk_print_settings_new_from_key_file (class, GKeyFile *key_file, const gchar_ornull *group_name)
    PREINIT:
	GError *error = NULL;
    CODE:
	RETVAL = gtk_print_settings_new_from_key_file (key_file, group_name, &error);
	if (error)
		gperl_croak_gerror (NULL, error);
    OUTPUT:
	RETVAL

void gtk_print_settings_to_key_file (GtkPrintSettings *settings, GKeyFile *key_file, const gchar_ornull *group_name);

#endif

#if GTK_CHECK_VERSION (2, 14, 0)

=for apidoc __gerror__
=cut
# gboolean gtk_print_settings_load_file (GtkPrintSettings *settings, const char *file_name, GError **error);
void
gtk_print_settings_load_file (GtkPrintSettings *settings, const char *file_name)
    PREINIT:
	GError *error = NULL;
    CODE:
	if (!gtk_print_settings_load_file (settings, file_name, &error))
		gperl_croak_gerror (NULL, error);

=for apidoc __gerror__
=cut
# gboolean gtk_print_settings_load_key_file (GtkPrintSettings *settings, GKeyFile *key_file, const gchar *group_name, GError **error);
void
gtk_print_settings_load_key_file (GtkPrintSettings *settings, GKeyFile *key_file, const gchar_ornull *group_name)
    PREINIT:
	GError *error = NULL;
    CODE:
	if (!gtk_print_settings_load_key_file (settings, key_file, group_name, &error))
		gperl_croak_gerror (NULL, error);

#endif /* 2.14 */

# We do not wrap the convenience getters and setters intentionally, but these
# few slipped in accidentally.  We hide them in the generated POD.

#if GTK_CHECK_VERSION (2, 16, 0)

=for apidoc __hide__
=cut
gdouble gtk_print_settings_get_printer_lpi (GtkPrintSettings *settings);

=for apidoc __hide__
=cut
gint gtk_print_settings_get_resolution_x (GtkPrintSettings *settings);

=for apidoc __hide__
=cut
gint gtk_print_settings_get_resolution_y (GtkPrintSettings *settings);

=for apidoc __hide__
=cut
void gtk_print_settings_set_printer_lpi  (GtkPrintSettings *settings, gdouble lpi);

=for apidoc __hide__
=cut
void gtk_print_settings_set_resolution_xy (GtkPrintSettings *settings, gint resolution_x, gint resolution_y);

#endif /* 2.16 */
