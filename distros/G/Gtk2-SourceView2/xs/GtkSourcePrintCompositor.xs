/*
 * Copyright (c) 2009-2010 by Emmanuel Rodriguez (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version; or the
 * Artistic License, version 2.0.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details; or the Artistic License.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307 USA.
 */

#include "gtk2-sourceview2-perl.h"

MODULE = Gtk2::SourceView2::PrintCompositor PACKAGE = Gtk2::SourceView2::PrintCompositor PREFIX = gtk_source_print_compositor_

GtkSourcePrintCompositor*
gtk_source_print_compositor_new (class, GtkSourceBuffer *buffer)
	C_ARGS: buffer

GtkSourcePrintCompositor*
gtk_source_print_compositor_new_from_view (class, GtkSourceView *view)
	C_ARGS: view


GtkSourceBuffer*
gtk_source_print_compositor_get_buffer (GtkSourcePrintCompositor *compositor)


void
gtk_source_print_compositor_set_tab_width (GtkSourcePrintCompositor *compositor, guint width)

guint
gtk_source_print_compositor_get_tab_width (GtkSourcePrintCompositor *compositor)


void
gtk_source_print_compositor_set_wrap_mode (GtkSourcePrintCompositor *compositor, GtkWrapMode wrap_mode)

GtkWrapMode
gtk_source_print_compositor_get_wrap_mode (GtkSourcePrintCompositor *compositor)


void
gtk_source_print_compositor_set_highlight_syntax (GtkSourcePrintCompositor *compositor, gboolean highlight)

gboolean
gtk_source_print_compositor_get_highlight_syntax (GtkSourcePrintCompositor *compositor)


void
gtk_source_print_compositor_set_print_line_numbers (GtkSourcePrintCompositor *compositor, guint interval)

guint
gtk_source_print_compositor_get_print_line_numbers (GtkSourcePrintCompositor *compositor)


void
gtk_source_print_compositor_set_body_font_name (GtkSourcePrintCompositor *compositor, const gchar *font_name)

gchar*
gtk_source_print_compositor_get_body_font_name (GtkSourcePrintCompositor *compositor)


void
gtk_source_print_compositor_set_line_numbers_font_name (GtkSourcePrintCompositor *compositor, const gchar_ornull *font_name)

gchar*
gtk_source_print_compositor_get_line_numbers_font_name (GtkSourcePrintCompositor *compositor)


void
gtk_source_print_compositor_set_header_font_name (GtkSourcePrintCompositor *compositor, const gchar_ornull *font_name)

gchar*
gtk_source_print_compositor_get_header_font_name (GtkSourcePrintCompositor *compositor)


void
gtk_source_print_compositor_set_footer_font_name (GtkSourcePrintCompositor *compositor, const gchar_ornull *font_name)

gchar*
gtk_source_print_compositor_get_footer_font_name (GtkSourcePrintCompositor *compositor)



gdouble
gtk_source_print_compositor_get_top_margin (GtkSourcePrintCompositor *compositor, GtkUnit unit)

void
gtk_source_print_compositor_set_top_margin (GtkSourcePrintCompositor *compositor, gdouble margin, GtkUnit unit)


gdouble
gtk_source_print_compositor_get_bottom_margin (GtkSourcePrintCompositor *compositor, GtkUnit unit)

void
gtk_source_print_compositor_set_bottom_margin (GtkSourcePrintCompositor *compositor, gdouble margin, GtkUnit unit)


gdouble
gtk_source_print_compositor_get_left_margin (GtkSourcePrintCompositor *compositor, GtkUnit unit)

void
gtk_source_print_compositor_set_left_margin (GtkSourcePrintCompositor *compositor, gdouble margin, GtkUnit unit)


gdouble
gtk_source_print_compositor_get_right_margin (GtkSourcePrintCompositor *compositor, GtkUnit unit)

void
gtk_source_print_compositor_set_right_margin (GtkSourcePrintCompositor *compositor, gdouble margin, GtkUnit unit)


void
gtk_source_print_compositor_set_print_header (GtkSourcePrintCompositor *compositor, gboolean print)

gboolean
gtk_source_print_compositor_get_print_header (GtkSourcePrintCompositor *compositor)


void
gtk_source_print_compositor_set_print_footer (GtkSourcePrintCompositor *compositor, gboolean print)

gboolean
gtk_source_print_compositor_get_print_footer (GtkSourcePrintCompositor *compositor)


void
gtk_source_print_compositor_set_header_format (GtkSourcePrintCompositor *compositor, gboolean separator, const gchar_ornull *left, const gchar_ornull *center, const gchar_ornull *right)

void
gtk_source_print_compositor_set_footer_format (GtkSourcePrintCompositor *compositor, gboolean separator, const gchar_ornull *left, const gchar_ornull *center, const gchar_ornull *right)


gint
gtk_source_print_compositor_get_n_pages (GtkSourcePrintCompositor *compositor)

gboolean
gtk_source_print_compositor_paginate (GtkSourcePrintCompositor *compositor, GtkPrintContext *context)

gdouble
gtk_source_print_compositor_get_pagination_progress (GtkSourcePrintCompositor *compositor)

void
gtk_source_print_compositor_draw_page (GtkSourcePrintCompositor *compositor, GtkPrintContext *context, gint page_nr)
