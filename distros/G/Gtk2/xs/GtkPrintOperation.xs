/*
 * Copyright (c) 2006 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

static GPerlCallback *
gtk2perl_page_setup_done_func_create (SV * func, SV * data)
{
	GType param_types [1];
	param_types[0] = GTK_TYPE_PAGE_SETUP;
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, 0);
}

static void
gtk2perl_page_setup_done_func (GtkPageSetup *page_setup, gpointer data)
{
	gperl_callback_invoke ((GPerlCallback *) data, NULL, page_setup);
	/* The callback is always called exactly once, so free it now. */
	gperl_callback_destroy ((GPerlCallback *) data);
}

MODULE = Gtk2::PrintOperation	PACKAGE = Gtk2::PrintOperation	PREFIX = gtk_print_operation_

# GtkPrintOperation * gtk_print_operation_new (void);
GtkPrintOperation_noinc * gtk_print_operation_new (class)
    C_ARGS:
	/* void */

void gtk_print_operation_set_default_page_setup (GtkPrintOperation *op, GtkPageSetup_ornull *default_page_setup);

GtkPageSetup_ornull * gtk_print_operation_get_default_page_setup (GtkPrintOperation *op);

void gtk_print_operation_set_print_settings (GtkPrintOperation *op, GtkPrintSettings_ornull *print_settings);

GtkPrintSettings_ornull * gtk_print_operation_get_print_settings (GtkPrintOperation *op);

void gtk_print_operation_set_job_name (GtkPrintOperation *op, const gchar *job_name);

void gtk_print_operation_set_n_pages (GtkPrintOperation *op, gint n_pages);

void gtk_print_operation_set_current_page (GtkPrintOperation *op, gint current_page);

void gtk_print_operation_set_use_full_page (GtkPrintOperation *op, gboolean full_page);

void gtk_print_operation_set_unit (GtkPrintOperation *op, GtkUnit unit);

void gtk_print_operation_set_export_filename (GtkPrintOperation *op, const gchar *filename);

void gtk_print_operation_set_track_print_status (GtkPrintOperation *op, gboolean track_status);

void gtk_print_operation_set_show_progress (GtkPrintOperation *op, gboolean show_progress);

void gtk_print_operation_set_allow_async (GtkPrintOperation *op, gboolean allow_async);

void gtk_print_operation_set_custom_tab_label (GtkPrintOperation *op, const gchar *label);

=for apidoc __gerror__
=cut
# GtkPrintOperationResult gtk_print_operation_run (GtkPrintOperation *op, GtkPrintOperationAction action, GtkWindow *parent, GError **error);
GtkPrintOperationResult
gtk_print_operation_run (GtkPrintOperation *op, GtkPrintOperationAction action, GtkWindow_ornull *parent)
    PREINIT:
	GError *error = NULL;
    CODE:
	RETVAL = gtk_print_operation_run (op, action, parent, &error);
	if (error)
		gperl_croak_gerror (NULL, error);
    OUTPUT:
	RETVAL

# FIXME: Does it makes sense to wrap it like this?
# void gtk_print_operation_get_error (GtkPrintOperation *op, GError **error);
SV *
gtk_print_operation_get_error (GtkPrintOperation *op)
    PREINIT:
	GError *error = NULL;
    CODE:
	gtk_print_operation_get_error (op, &error);
	RETVAL = gperl_sv_from_gerror (error);
    OUTPUT:
	RETVAL

GtkPrintStatus gtk_print_operation_get_status (GtkPrintOperation *op);

const gchar * gtk_print_operation_get_status_string (GtkPrintOperation *op);

gboolean gtk_print_operation_is_finished (GtkPrintOperation *op);

void gtk_print_operation_cancel (GtkPrintOperation *op);

#if GTK_CHECK_VERSION (2, 16, 0)

=for apidoc

=for signature $op->draw_page_finish ()

The method draw_page_finish() can only be called if the method
set_defer_drawing() has been called previously otherwise a segmentation fault
will occur. This means that the application will crash and even an eval will not
be able to recover from that error.

=cut
void gtk_print_operation_draw_page_finish (GtkPrintOperation *op);


=for apidoc

=for signature $op->set_defer_drawing ()

The method set_defer_drawing() can only be called from the callback
C<'draw-page'>.

=cut
void gtk_print_operation_set_defer_drawing (GtkPrintOperation *op);

#endif /* 2.16 */

#if GTK_CHECK_VERSION (2, 18, 0)

void gtk_print_operation_set_embed_page_setup (GtkPrintOperation *op, gboolean embed);

gboolean gtk_print_operation_get_embed_page_setup (GtkPrintOperation *op);

void gtk_print_operation_set_support_selection (GtkPrintOperation *op, gboolean support_selection);

gboolean gtk_print_operation_get_support_selection (GtkPrintOperation *op);

void gtk_print_operation_set_has_selection (GtkPrintOperation *op, gboolean has_selection);

gboolean gtk_print_operation_get_has_selection (GtkPrintOperation *op);

gint gtk_print_operation_get_n_pages_to_print (GtkPrintOperation *op);

#endif /* 2.18 */

MODULE = Gtk2::PrintOperation	PACKAGE = Gtk2::Print	PREFIX = gtk_print_

# GtkPageSetup * gtk_print_run_page_setup_dialog (GtkWindow *parent, GtkPageSetup *page_setup, GtkPrintSettings *settings);
GtkPageSetup_noinc *
gtk_print_run_page_setup_dialog (class, GtkWindow_ornull *parent, GtkPageSetup_ornull *page_setup, GtkPrintSettings *settings)
    C_ARGS:
	parent, page_setup, settings

# void gtk_print_run_page_setup_dialog_async (GtkWindow_ornull *parent, GtkPageSetup_ornull *page_setup, GtkPrintSettings *settings, GtkPageSetupDoneFunc done_cb, gpointer data);
void
gtk_print_run_page_setup_dialog_async (class, GtkWindow_ornull *parent, GtkPageSetup_ornull *page_setup, GtkPrintSettings *settings, SV *func, SV *data=NULL)
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = gtk2perl_page_setup_done_func_create (func, data);
	gtk_print_run_page_setup_dialog_async (
		parent, page_setup, settings,
		gtk2perl_page_setup_done_func,
		callback);
	/* Since it's always called exactly once, the callback is destroyed
	 * directly in the marshaller. */
