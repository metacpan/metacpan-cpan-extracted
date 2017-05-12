/*
 * Copyright (c) 2003-2005 by Emmanuele Bassi (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
 * Boston, MA  02111-1307  USA.
 */

#include "gtksourceviewperl.h"

MODULE = Gtk2::SourceView::PrintJob	PACKAGE = Gtk2::SourceView::PrintJob	PREFIX = gtk_source_print_job_

GtkSourcePrintJob_noinc *
gtk_source_print_job_new (class, GnomePrintConfig_ornull  * config)
    C_ARGS:
	config

GtkSourcePrintJob_noinc *
gtk_source_print_job_new_with_buffer (class, config, buffer)
	GnomePrintConfig  * config
	GtkSourceBuffer   * buffer
    C_ARGS:
	config, buffer

void
gtk_source_print_job_set_config (GtkSourcePrintJob * job, GnomePrintConfig * config)

GnomePrintConfig *
gtk_source_print_job_get_config (GtkSourcePrintJob * job)

void
gtk_source_print_job_set_buffer (GtkSourcePrintJob * job, GtkSourceBuffer * buffer)

GtkSourceBuffer *
gtk_source_print_job_get_buffer (GtkSourcePrintJob * job)

void
gtk_source_print_job_setup_from_view (GtkSourcePrintJob * job, GtkSourceView * view)

void
gtk_source_print_job_set_tabs_width (GtkSourcePrintJob * job, guint tabs_width)

guint
gtk_source_print_job_get_tabs_width (GtkSourcePrintJob * job)

void
gtk_source_print_job_set_wrap_mode (GtkSourcePrintJob * job, GtkWrapMode wrap)

GtkWrapMode
gtk_source_print_job_get_wrap_mode (GtkSourcePrintJob * job)

void
gtk_source_print_job_set_highlight (GtkSourcePrintJob * job, gboolean highlight)

gboolean
gtk_source_print_job_get_highlight (GtkSourcePrintJob * job)

void
gtk_source_print_job_set_font (GtkSourcePrintJob *job, const gchar * font_name)

gchar_own *
gtk_source_print_job_get_font (GtkSourcePrintJob * job)

void
gtk_source_print_job_set_numbers_font (GtkSourcePrintJob * job, const gchar * font_name)

gchar_own *
gtk_source_print_job_get_numbers_font (GtkSourcePrintJob * job)

void
gtk_source_print_job_set_print_numbers (GtkSourcePrintJob * job, guint interval)

guint
gtk_source_print_job_get_print_numbers (GtkSourcePrintJob * job)

void
gtk_source_print_job_set_text_margins (job, top, bottom, left, right)
	GtkSourcePrintJob * job
	gdouble           top
	gdouble           bottom
	gdouble           left
	gdouble           right

##void               gtk_source_print_job_get_text_margins       (GtkSourcePrintJob *job,
##								gdouble           *top,
##								gdouble           *bottom,
##								gdouble           *left,
##								gdouble           *right);
=for apidoc
=for signature (top, bottom, left, right) = $job->get_text_margins
=cut
void
gtk_source_print_job_get_text_margins (job)
	GtkSourcePrintJob * job
    PREINIT:
	gdouble top, bottom, left, right;
    PPCODE:
	gtk_source_print_job_get_text_margins(job, &top, &bottom, &left, &right);
	EXTEND(SP, 4);
	PUSHs(sv_2mortal(newSVnv(top)));
	PUSHs(sv_2mortal(newSVnv(bottom)));
	PUSHs(sv_2mortal(newSVnv(left)));
	PUSHs(sv_2mortal(newSVnv(right)));

#if GTK_SOURCE_VIEW_CHECK_VERSION (1, 2, 0)

void
gtk_source_print_job_set_font_desc (GtkSourcePrintJob *job, PangoFontDescription *desc);

PangoFontDescription *
gtk_source_print_job_get_font_desc (GtkSourcePrintJob *job);

void
gtk_source_print_job_set_numbers_font_desc (GtkSourcePrintJob *job, PangoFontDescription *desc);

PangoFontDescription *
gtk_source_print_job_get_numbers_font_desc (GtkSourcePrintJob *job);

void
gtk_source_print_job_set_header_footer_font_desc (GtkSourcePrintJob *job, PangoFontDescription *desc);

PangoFontDescription *
gtk_source_print_job_get_header_footer_font_desc (GtkSourcePrintJob *job);

#endif

###/* printing operations */
GnomePrintJob *
gtk_source_print_job_print (GtkSourcePrintJob * job)

GnomePrintJob *
gtk_source_print_job_print_range (job, start, end)
	GtkSourcePrintJob * job
	const GtkTextIter * start
	const GtkTextIter *end

###/* asynchronous printing */
gboolean
gtk_source_print_job_print_range_async (job, start, end)
	GtkSourcePrintJob * job
	const GtkTextIter * start
	const GtkTextIter * end

void
gtk_source_print_job_cancel (GtkSourcePrintJob * job)

GnomePrintJob *
gtk_source_print_job_get_print_job (GtkSourcePrintJob * job)

###/* information for asynchronous ops and headers and footers callback */
guint
gtk_source_print_job_get_page (GtkSourcePrintJob * job)

guint
gtk_source_print_job_get_page_count (GtkSourcePrintJob * job)

GnomePrintContext *
gtk_source_print_job_get_print_context (GtkSourcePrintJob * job)


###/* header and footer */
void
gtk_source_print_job_set_print_header (GtkSourcePrintJob * job, gboolean setting)

gboolean
gtk_source_print_job_get_print_header (GtkSourcePrintJob * job)

void
gtk_source_print_job_set_print_footer (GtkSourcePrintJob * job, gboolean setting)

gboolean
gtk_source_print_job_get_print_footer (GtkSourcePrintJob * job)

void
gtk_source_print_job_set_header_footer_font (job, font_name)
	GtkSourcePrintJob * job
	const gchar * font_name

gchar_own *
gtk_source_print_job_get_header_footer_font (GtkSourcePrintJob * job)

###/* format strings are strftime like */
=for apidoc
Format strings are strftime like.
=cut
void
gtk_source_print_job_set_header_format (job, left, center, right, separator)
	GtkSourcePrintJob  * job
	const gchar_ornull * left
	const gchar_ornull * center
	const gchar_ornull * right
	gboolean          separator

=for apidoc
Format strings are strftime like.
=cut
void
gtk_source_print_job_set_footer_format (job, left, center, right, separator)
	GtkSourcePrintJob  * job
	const gchar_ornull * left
	const gchar_ornull * center
	const gchar_ornull * right
	gboolean          separator
