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

/**
 * Returns a GSList in the stack and frees the input list.
 */
#define sourceview2perl_return_gslist(list) \
do {\
	GSList *iter_ = (list); /* Iterator, doesn't need to be freed */ \
	for (; iter_ != NULL ; iter_ = iter_->next) { \
		GtkSourceMark *mark = GTK_SOURCE_MARK(iter_->data); \
		SV *sv = newSVGtkSourceMark(mark); \
		XPUSHs(sv_2mortal(sv)); \
	} \
	g_slist_free(list); \
} while (FALSE)


MODULE = Gtk2::SourceView2::Buffer PACKAGE = Gtk2::SourceView2::Buffer PREFIX = gtk_source_buffer_

GtkSourceBuffer*
gtk_source_buffer_new (class, GtkTextTagTable_ornull *table)
	C_ARGS: table

GtkSourceBuffer*
gtk_source_buffer_new_with_language (class, GtkSourceLanguage *language)
	C_ARGS: language


gboolean
gtk_source_buffer_get_highlight_syntax (GtkSourceBuffer *buffer)

void
gtk_source_buffer_set_highlight_syntax (GtkSourceBuffer *buffer, gboolean highlight)


gboolean
gtk_source_buffer_get_highlight_matching_brackets (GtkSourceBuffer *buffer)

void
gtk_source_buffer_set_highlight_matching_brackets (GtkSourceBuffer *buffer, gboolean highlight)


gint
gtk_source_buffer_get_max_undo_levels (GtkSourceBuffer *buffer)

void
gtk_source_buffer_set_max_undo_levels (GtkSourceBuffer *buffer, gint max_undo_levels)


GtkSourceLanguage_ornull*
gtk_source_buffer_get_language (GtkSourceBuffer *buffer)

void
gtk_source_buffer_set_language (GtkSourceBuffer *buffer, GtkSourceLanguage_ornull *language)


gboolean
gtk_source_buffer_can_undo (GtkSourceBuffer *buffer)

gboolean
gtk_source_buffer_can_redo (GtkSourceBuffer *buffer)


GtkSourceStyleScheme_ornull*
gtk_source_buffer_get_style_scheme (GtkSourceBuffer *buffer)

void
gtk_source_buffer_set_style_scheme (GtkSourceBuffer *buffer, GtkSourceStyleScheme *scheme)


void
gtk_source_buffer_ensure_highlight (GtkSourceBuffer *buffer, const GtkTextIter *start, const GtkTextIter *end)



void
gtk_source_buffer_undo (GtkSourceBuffer *buffer)

void
gtk_source_buffer_redo (GtkSourceBuffer *buffer)


void
gtk_source_buffer_begin_not_undoable_action (GtkSourceBuffer *buffer)

void
gtk_source_buffer_end_not_undoable_action (GtkSourceBuffer *buffer)



GtkSourceMark*
gtk_source_buffer_create_source_mark (GtkSourceBuffer *buffer, const gchar_ornull *name, const gchar *category, const GtkTextIter *where)

gboolean
gtk_source_buffer_forward_iter_to_source_mark (GtkSourceBuffer *buffer, GtkTextIter *iter, const gchar_ornull *category)

gboolean
gtk_source_buffer_backward_iter_to_source_mark (GtkSourceBuffer *buffer, GtkTextIter *iter, const gchar_ornull *category)

void
gtk_source_buffer_get_source_marks_at_iter (GtkSourceBuffer *buffer, GtkTextIter *iter, const gchar_ornull *category)
	PREINIT:
		GSList *list = NULL;

	PPCODE:
		list = gtk_source_buffer_get_source_marks_at_iter(buffer, iter, category);
		sourceview2perl_return_gslist(list);

void
gtk_source_buffer_get_source_marks_at_line (GtkSourceBuffer *buffer, gint line, const gchar_ornull *category)
	PREINIT:
		GSList *list = NULL;

	PPCODE:
		list = gtk_source_buffer_get_source_marks_at_line(buffer, line, category);
		sourceview2perl_return_gslist(list);

void
gtk_source_buffer_remove_source_marks (GtkSourceBuffer *buffer, const GtkTextIter *start, const GtkTextIter *end, const gchar_ornull *category)
