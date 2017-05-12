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

MODULE = Gtk2::SourceView::Buffer	PACKAGE = Gtk2::SourceView::Buffer	PREFIX = gtk_source_buffer_

GtkSourceBuffer_noinc *
gtk_source_buffer_new (class, GtkSourceTagTable_ornull * table)
    C_ARGS:
    	table

GtkSourceBuffer_noinc *
gtk_source_buffer_new_with_language (class, GtkSourceLanguage * language)
    C_ARGS:
    	language

###/* Properties */
gboolean
gtk_source_buffer_get_check_brackets (GtkSourceBuffer * buffer)

void
gtk_source_buffer_set_check_brackets (GtkSourceBuffer * buffer, gboolean check_brackets)

void
gtk_source_buffer_set_bracket_match_style (GtkSourceBuffer *source_buffer, const GtkSourceTagStyle *style);

gboolean
gtk_source_buffer_get_highlight	(GtkSourceBuffer * buffer)

void
gtk_source_buffer_set_highlight	(GtkSourceBuffer * buffer, gboolean highlight)

gint
gtk_source_buffer_get_max_undo_levels (GtkSourceBuffer * buffer)

void
gtk_source_buffer_set_max_undo_levels (GtkSourceBuffer * buffer, gint max_undo_levels)

GtkSourceLanguage_ornull *
gtk_source_buffer_get_language (GtkSourceBuffer * buffer)

void
gtk_source_buffer_set_language (GtkSourceBuffer * buffer, GtkSourceLanguage * language)

gunichar
gtk_source_buffer_get_escape_char (GtkSourceBuffer * buffer)

void
gtk_source_buffer_set_escape_char (GtkSourceBuffer * buffer, gunichar escape_char)

###/* Undo/redo methods */
gboolean
gtk_source_buffer_can_undo (GtkSourceBuffer * buffer)

gboolean
gtk_source_buffer_can_redo (GtkSourceBuffer * buffer)

void
gtk_source_buffer_undo (GtkSourceBuffer * buffer)

void
gtk_source_buffer_redo (GtkSourceBuffer * buffer)

void
gtk_source_buffer_begin_not_undoable_action (GtkSourceBuffer * buffer)

void
gtk_source_buffer_end_not_undoable_action (GtkSourceBuffer * buffer)

GtkSourceMarker *
gtk_source_buffer_create_marker (GtkSourceBuffer *buffer, const gchar_ornull *name, const gchar_ornull *type, const GtkTextIter *where);

void
gtk_source_buffer_move_marker (GtkSourceBuffer *buffer, GtkSourceMarker *marker, const GtkTextIter *where);

void
gtk_source_buffer_delete_marker (GtkSourceBuffer *buffer, GtkSourceMarker *marker);

GtkSourceMarker_ornull *
gtk_source_buffer_get_marker (GtkSourceBuffer *buffer, const gchar *name);

##GSList *
##gtk_source_buffer_get_markers_in_region (GtkSourceBuffer *buffer, const GtkTextIter *begin, const GtkTextIter *end);
void
gtk_source_buffer_get_markers_in_region (GtkSourceBuffer *buffer, const GtkTextIter *begin, const GtkTextIter *end)
    PREINIT:
	GSList * markers, * i;
    PPCODE:
	markers = gtk_source_buffer_get_markers_in_region (buffer, begin, end);
	for (i = markers ; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVGtkSourceMarker
					(GTK_SOURCE_MARKER (i->data))));
	g_slist_free (markers);

GtkSourceMarker_ornull *
gtk_source_buffer_get_first_marker (GtkSourceBuffer *buffer);

GtkSourceMarker_ornull *
gtk_source_buffer_get_last_marker (GtkSourceBuffer *buffer);

##void
##gtk_source_buffer_get_iter_at_marker (GtkSourceBuffer *buffer, GtkTextIter *iter, GtkSourceMarker *marker);
GtkTextIter_copy *
gtk_source_buffer_get_iter_at_marker (buffer, marker)
	GtkSourceBuffer *buffer
	GtkSourceMarker *marker
    PREINIT:
	GtkTextIter iter;
    CODE:
	gtk_source_buffer_get_iter_at_marker (buffer, &iter, marker);
	RETVAL = &iter;
    OUTPUT:
	RETVAL

GtkSourceMarker_ornull *
gtk_source_buffer_get_next_marker (GtkSourceBuffer *buffer, GtkTextIter *iter);

GtkSourceMarker_ornull *
gtk_source_buffer_get_prev_marker (GtkSourceBuffer *buffer, GtkTextIter *iter);
