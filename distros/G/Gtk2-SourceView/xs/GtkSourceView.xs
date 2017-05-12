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

MODULE = Gtk2::SourceView	PACKAGE = Gtk2::SourceView	PREFIX = gtk_source_view_

=for object Gtk2::SourceView::main

=cut

BOOT:
#include "register.xsh"
#include "boot.xsh"

=for apidoc
=signature (major_version, minor_version, micro_version) = Gtk2::SourceView->GET_VERSION_INFO
=cut
void
GET_VERSION_INFO (class)
    PPCODE:
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSViv (GTK_SOURCE_VIEW_MAJOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (GTK_SOURCE_VIEW_MINOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (GTK_SOURCE_VIEW_MICRO_VERSION)));
	PERL_UNUSED_VAR (ax);

gboolean
CHECK_VERSION (class, major, minor, micro)
	int major
	int minor
	int micro
    CODE:
	RETVAL = GTK_SOURCE_VIEW_CHECK_VERSION (major, minor, micro);
    OUTPUT:
	RETVAL

MODULE = Gtk2::SourceView	PACKAGE = Gtk2::SourceView::View	PREFIX = gtk_source_view_

GtkWidget *
gtk_source_view_new (class)
    C_ARGS:
    	/* void */

GtkWidget *
gtk_source_view_new_with_buffer	(class, GtkSourceBuffer * buffer)
    C_ARGS:
    	buffer

###/* Properties */
void
gtk_source_view_set_show_line_numbers (GtkSourceView * view, gboolean show)

gboolean
gtk_source_view_get_show_line_numbers (GtkSourceView * view)

void
gtk_source_view_set_show_line_markers (GtkSourceView * view, gboolean show)

gboolean
gtk_source_view_get_show_line_markers (GtkSourceView * view)

void
gtk_source_view_set_tabs_width (GtkSourceView * view, guint width)

guint
gtk_source_view_get_tabs_width (GtkSourceView * view)

void
gtk_source_view_set_auto_indent (GtkSourceView * view, gboolean enable)

gboolean
gtk_source_view_get_auto_indent (GtkSourceView * view)

void
gtk_source_view_set_insert_spaces_instead_of_tabs (GtkSourceView * view, gboolean enable)

gboolean
gtk_source_view_get_insert_spaces_instead_of_tabs (GtkSourceView * view)

void
gtk_source_view_set_show_margin (GtkSourceView * view, gboolean show)

gboolean
gtk_source_view_get_show_margin (GtkSourceView * view)

void
gtk_source_view_set_margin (GtkSourceView * view, guint margin)

guint
gtk_source_view_get_margin (GtkSourceView * view)

#if GTK_SOURCE_VIEW_CHECK_VERSION (1, 2, 0)

void
gtk_source_view_set_highlight_current_line (GtkSourceView *view, gboolean show)

gboolean
gtk_source_view_get_highlight_current_line (GtkSourceView *view)

#endif

void
gtk_source_view_set_marker_pixbuf (view, marker_type, pixbuf)
	GtkSourceView * view
	const gchar * marker_type
	GdkPixbuf_ornull * pixbuf

GdkPixbuf_noinc_ornull *
gtk_source_view_get_marker_pixbuf (view, marker_type)
	GtkSourceView * view
	const gchar * marker_type

void
gtk_source_view_set_smart_home_end (GtkSourceView * view, gboolean enable)

gboolean
gtk_source_view_get_smart_home_end (GtkSourceView * view)
