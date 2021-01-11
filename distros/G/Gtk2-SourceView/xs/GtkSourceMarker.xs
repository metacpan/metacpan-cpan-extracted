/*
 * Copyright (c) 2005 by Torsten Schoenfeld (see the file AUTHORS)
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
 * License along with this library; if not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "gtksourceviewperl.h"

MODULE = Gtk2::SourceView::Marker	PACKAGE = Gtk2::SourceView::Marker	PREFIX = gtk_source_marker_

void gtk_source_marker_set_marker_type (GtkSourceMarker *marker, const gchar_ornull *type);

gchar_ornull *
gtk_source_marker_get_marker_type (marker)
	GtkSourceMarker *marker
    CLEANUP:
	g_free (RETVAL);

gint gtk_source_marker_get_line (GtkSourceMarker *marker);

const gchar_ornull *gtk_source_marker_get_name (GtkSourceMarker *marker);

GtkSourceBuffer_ornull *gtk_source_marker_get_buffer (GtkSourceMarker *marker);

GtkSourceMarker_ornull *gtk_source_marker_next (GtkSourceMarker *marker);

GtkSourceMarker_ornull *gtk_source_marker_prev (GtkSourceMarker *marker);
