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

MODULE = Gtk2::SourceView2::View PACKAGE = Gtk2::SourceView2::View PREFIX = gtk_source_view_


GtkWidget*
gtk_source_view_new (class)
	C_ARGS: /* No args */

GtkWidget*
gtk_source_view_new_with_buffer (class, GtkSourceBuffer *buffer)
	C_ARGS: buffer


void
gtk_source_view_set_show_line_numbers (GtkSourceView *view, gboolean show)

gboolean
gtk_source_view_get_show_line_numbers (GtkSourceView *view)


void
gtk_source_view_set_tab_width (GtkSourceView *view, guint width)

guint
gtk_source_view_get_tab_width (GtkSourceView *view)


void
gtk_source_view_set_indent_width (GtkSourceView *view, gint width)

gint
gtk_source_view_get_indent_width (GtkSourceView *view)


void
gtk_source_view_set_auto_indent (GtkSourceView *view, gboolean enable)

gboolean
gtk_source_view_get_auto_indent (GtkSourceView *view)


void
gtk_source_view_set_insert_spaces_instead_of_tabs (GtkSourceView *view, gboolean enable)

gboolean
gtk_source_view_get_insert_spaces_instead_of_tabs (GtkSourceView *view)


void
gtk_source_view_set_indent_on_tab (GtkSourceView *view, gboolean enable)

gboolean
gtk_source_view_get_indent_on_tab (GtkSourceView *view)


void
gtk_source_view_set_highlight_current_line (GtkSourceView *view, gboolean show)

gboolean
gtk_source_view_get_highlight_current_line (GtkSourceView *view)


void
gtk_source_view_set_show_right_margin (GtkSourceView *view, gboolean show)

gboolean
gtk_source_view_get_show_right_margin (GtkSourceView *view)


void
gtk_source_view_set_right_margin_position (GtkSourceView *view, guint pos)

guint
gtk_source_view_get_right_margin_position (GtkSourceView *view)


void
gtk_source_view_set_show_line_marks (GtkSourceView *view, gboolean show)

gboolean
gtk_source_view_get_show_line_marks (GtkSourceView *view)


void
gtk_source_view_set_mark_category_pixbuf (GtkSourceView *view, const gchar *category, GdkPixbuf_ornull *pixbuf)

GdkPixbuf_ornull*
gtk_source_view_get_mark_category_pixbuf (GtkSourceView *view, const gchar *category)


void
gtk_source_view_set_mark_category_background (GtkSourceView *view, const gchar *category, const GdkColor_ornull *color)

GdkColor_copy*
gtk_source_view_get_mark_category_background (GtkSourceView *view, const gchar *category)
	PREINIT:
		GdkColor color;

	CODE:
		gtk_source_view_get_mark_category_background(view, category, &color);
		RETVAL = &color;

	OUTPUT:
		RETVAL


void
gtk_source_view_set_mark_category_priority (GtkSourceView *view, const gchar *category, gint priority)

gint
gtk_source_view_get_mark_category_priority (GtkSourceView *view, const gchar *category)


void
gtk_source_view_set_smart_home_end (GtkSourceView *view, GtkSourceSmartHomeEndType smart_he)

GtkSourceSmartHomeEndType
gtk_source_view_get_smart_home_end (GtkSourceView *view)


void
gtk_source_view_set_draw_spaces (GtkSourceView *view, GtkSourceDrawSpacesFlags flags)

GtkSourceDrawSpacesFlags
gtk_source_view_get_draw_spaces (GtkSourceView *view)
