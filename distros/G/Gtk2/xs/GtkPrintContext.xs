/*
 * Copyright (c) 2006 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"
#include <cairo-perl.h>

MODULE = Gtk2::PrintContext	PACKAGE = Gtk2::PrintContext	PREFIX = gtk_print_context_

cairo_t * gtk_print_context_get_cairo_context (GtkPrintContext *context);

GtkPageSetup * gtk_print_context_get_page_setup (GtkPrintContext *context);

gdouble gtk_print_context_get_width (GtkPrintContext *context);

gdouble gtk_print_context_get_height (GtkPrintContext *context);

gdouble gtk_print_context_get_dpi_x (GtkPrintContext *context);

gdouble gtk_print_context_get_dpi_y (GtkPrintContext *context);

PangoFontMap * gtk_print_context_get_pango_fontmap (GtkPrintContext *context);

PangoContext_noinc * gtk_print_context_create_pango_context (GtkPrintContext *context);

PangoLayout_noinc * gtk_print_context_create_pango_layout (GtkPrintContext *context);

void gtk_print_context_set_cairo_context (GtkPrintContext *context, cairo_t *cr, double dpi_x, double dpi_y);

#if GTK_CHECK_VERSION (2, 20, 0)

# gboolean gtk_print_context_get_hard_margins (GtkPrintContext *context, gdouble *top, gdouble *bottom, gdouble *left, gdouble *right)
=for apidoc
=for signature (top, bottom, left, right) = $context->get_hard_margins

Returns an empty list if the hard margins could not be retrieved.

=cut
void
gtk_print_context_get_hard_margins (GtkPrintContext *context)
    PREINIT:
	gdouble top, bottom, left, right;
    PPCODE:
	if (!gtk_print_context_get_hard_margins (context, &top, &bottom, &left, &right))
		XSRETURN_EMPTY;
	EXTEND (SP, 4);
	PUSHs (sv_2mortal (newSVnv (top)));
	PUSHs (sv_2mortal (newSVnv (bottom)));
	PUSHs (sv_2mortal (newSVnv (left)));
	PUSHs (sv_2mortal (newSVnv (right)));

#endif /* 2.20 */
