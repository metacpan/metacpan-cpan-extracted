/*
 * Copyright (c) 2006 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::PageSetup	PACKAGE = Gtk2::PageSetup	PREFIX = gtk_page_setup_

# GtkPageSetup * gtk_page_setup_new (void);
GtkPageSetup_noinc * gtk_page_setup_new (class)
    C_ARGS:
	/* void */

# FIXME: needed?
# GtkPageSetup * gtk_page_setup_copy (GtkPageSetup *other);

GtkPageOrientation gtk_page_setup_get_orientation (GtkPageSetup *setup);

void gtk_page_setup_set_orientation (GtkPageSetup *setup, GtkPageOrientation orientation);

# setup still owns the size object
GtkPaperSize * gtk_page_setup_get_paper_size (GtkPageSetup *setup);

# setup takes a copy of the size object
void gtk_page_setup_set_paper_size (GtkPageSetup *setup, GtkPaperSize *size);

gdouble gtk_page_setup_get_top_margin (GtkPageSetup *setup, GtkUnit unit);

void gtk_page_setup_set_top_margin (GtkPageSetup *setup, gdouble margin, GtkUnit unit);

gdouble gtk_page_setup_get_bottom_margin (GtkPageSetup *setup, GtkUnit unit);

void gtk_page_setup_set_bottom_margin (GtkPageSetup *setup, gdouble margin, GtkUnit unit);

gdouble gtk_page_setup_get_left_margin (GtkPageSetup *setup, GtkUnit unit);

void gtk_page_setup_set_left_margin (GtkPageSetup *setup, gdouble margin, GtkUnit unit);

gdouble gtk_page_setup_get_right_margin (GtkPageSetup *setup, GtkUnit unit);

void gtk_page_setup_set_right_margin (GtkPageSetup *setup, gdouble margin, GtkUnit unit);

# setup takes a copy of the size object
void gtk_page_setup_set_paper_size_and_default_margins (GtkPageSetup *setup, GtkPaperSize *size);

gdouble gtk_page_setup_get_paper_width (GtkPageSetup *setup, GtkUnit unit);

gdouble gtk_page_setup_get_paper_height (GtkPageSetup *setup, GtkUnit unit);

gdouble gtk_page_setup_get_page_width (GtkPageSetup *setup, GtkUnit unit);

gdouble gtk_page_setup_get_page_height (GtkPageSetup *setup, GtkUnit unit);

#if GTK_CHECK_VERSION (2, 12, 0)

# GtkPageSetup * gtk_page_setup_new_from_file (const gchar *file_name, GError **error);
=for apidoc __gerror__
=cut
GtkPageSetup_noinc * gtk_page_setup_new_from_file (class, GPerlFilename file_name)
    PREINIT:
	GError *error = NULL;
    CODE:
	RETVAL = gtk_page_setup_new_from_file (file_name, &error);
	if (error)
		gperl_croak_gerror (NULL, error);
    OUTPUT:
	RETVAL

# gboolean gtk_page_setup_to_file (GtkPageSetup *setup, const char *file_name, GError **error);
=for apidoc __gerror__
=cut
void gtk_page_setup_to_file (GtkPageSetup *setup, GPerlFilename file_name)
    PREINIT:
	GError *error = NULL;
    CODE:
	if (!gtk_page_setup_to_file (setup, file_name, &error))
		gperl_croak_gerror (NULL, error);

# GtkPageSetup * gtk_page_setup_new_from_key_file (GKeyFile *key_file, const gchar *group_name, GError **error);
=for apidoc __gerror__
=cut
GtkPageSetup_noinc * gtk_page_setup_new_from_key_file (class, GKeyFile *key_file, const gchar_ornull *group_name)
    PREINIT:
	GError *error = NULL;
    CODE:
	RETVAL = gtk_page_setup_new_from_key_file (key_file, group_name, &error);
	if (error)
		gperl_croak_gerror (NULL, error);
    OUTPUT:
	RETVAL

void gtk_page_setup_to_key_file (GtkPageSetup *setup, GKeyFile *key_file, const gchar_ornull *group_name);

#endif

#if GTK_CHECK_VERSION (2, 14, 0)

=for apidoc __gerror__
=cut
# gboolean gtk_page_setup_load_file (GtkPageSetup *setup, const char *file_name, GError **error);
void
gtk_page_setup_load_file (GtkPageSetup *setup, const char *file_name)
    PREINIT:
	GError *error = NULL;
    CODE:
	if (!gtk_page_setup_load_file (setup, file_name, &error))
		gperl_croak_gerror (NULL, error);

=for apidoc __gerror__
=cut
# gboolean gtk_page_setup_load_key_file (GtkPageSetup *setup, GKeyFile *key_file, const gchar *group_name, GError **error);
void
gtk_page_setup_load_key_file (GtkPageSetup *setup, GKeyFile *key_file, const gchar_ornull *group_name)
    PREINIT:
	GError *error = NULL;
    CODE:
	if (!gtk_page_setup_load_key_file (setup, key_file, group_name, &error))
		gperl_croak_gerror (NULL, error);

#endif /* 2.14 */
