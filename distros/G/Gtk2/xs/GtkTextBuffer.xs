/*
 * Copyright (c) 2003-2006 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
 * Boston, MA  02110-1301  USA.
 *
 * $Id$
 */

#include "gtk2perl.h"

/* is a GObject */

MODULE = Gtk2::TextBuffer	PACKAGE = Gtk2::TextBuffer	PREFIX = gtk_text_buffer_

GtkTextBuffer_noinc*
gtk_text_buffer_new (class, tagtable=NULL)
	GtkTextTagTable_ornull * tagtable
    C_ARGS:
	tagtable

gint
gtk_text_buffer_get_line_count (buffer)
	GtkTextBuffer *buffer

gint
gtk_text_buffer_get_char_count (buffer)
	GtkTextBuffer *buffer

GtkTextTagTable*
gtk_text_buffer_get_tag_table (buffer)
	GtkTextBuffer *buffer


void gtk_text_buffer_insert (GtkTextBuffer * buffer, GtkTextIter * iter, const gchar_length * text, int length(text))

void gtk_text_buffer_insert_at_cursor (GtkTextBuffer *buffer, const gchar_length *text, int length(text))

gboolean gtk_text_buffer_insert_interactive (GtkTextBuffer *buffer, GtkTextIter *iter, const gchar_length *text, int length(text), gboolean default_editable)


gboolean gtk_text_buffer_insert_interactive_at_cursor (GtkTextBuffer *buffer, const gchar_length *text, int length(text), gboolean default_editable)

## void gtk_text_buffer_insert_range (GtkTextBuffer *buffer, GtkTextIter *iter, const GtkTextIter *start, const GtkTextIter *end)
void
gtk_text_buffer_insert_range (buffer, iter, start, end)
	GtkTextBuffer *buffer
	GtkTextIter *iter
	GtkTextIter *start
	GtkTextIter *end

## gboolean gtk_text_buffer_insert_range_interactive (GtkTextBuffer *buffer, GtkTextIter *iter, const GtkTextIter *start, const GtkTextIter *end, gboolean default_editable)
gboolean
gtk_text_buffer_insert_range_interactive (buffer, iter, start, end, default_editable)
	GtkTextBuffer *buffer
	GtkTextIter *iter
	GtkTextIter *start
	GtkTextIter *end
	gboolean default_editable

#### void gtk_text_buffer_insert_with_tags (GtkTextBuffer *buffer, GtkTextIter *iter, const gchar *text, gint len, GtkTextTag *first_tag, ...)
=for apidoc
=for arg ... of Gtk2::TextTag's
=cut
void
gtk_text_buffer_insert_with_tags (buffer, iter, text, ...)
	GtkTextBuffer *buffer
	GtkTextIter *iter
	const gchar *text
    PREINIT:
	int i;
	gint start_offset;
	GtkTextIter start;
    CODE:
	start_offset = gtk_text_iter_get_offset (iter);
	gtk_text_buffer_insert (buffer, iter, text, -1);
	gtk_text_buffer_get_iter_at_offset (buffer, &start, start_offset);
	for (i = 3 ; i < items ; i++) {
		gtk_text_buffer_apply_tag (buffer, SvGtkTextTag (ST (i)),
					   &start, iter);
	}
 

## void gtk_text_buffer_insert_with_tags_by_name (GtkTextBuffer *buffer, GtkTextIter *iter, const gchar *text, gint len, const gchar *first_tag_name, ...)
=for apidoc
=for arg ... of strings, tag names
=cut
void
gtk_text_buffer_insert_with_tags_by_name (buffer, iter, text, ...)
	GtkTextBuffer *buffer
	GtkTextIter *iter
	const gchar *text
    PREINIT:
	int i;
	gint start_offset;
	GtkTextTagTable * tag_table;
	GtkTextIter start;
    CODE:
	start_offset = gtk_text_iter_get_offset (iter);
	gtk_text_buffer_insert (buffer, iter, text, -1);
	tag_table = gtk_text_buffer_get_tag_table (buffer);
	gtk_text_buffer_get_iter_at_offset (buffer, &start, start_offset);
	for (i = 3 ; i < items ; i++) {
		char * tag_name;
		GtkTextTag * tag;

		tag_name = SvGChar (ST (i));
		tag = gtk_text_tag_table_lookup (tag_table, tag_name);
		if (!tag)
			warn ("no tag with name %s", tag_name);
		else
			gtk_text_buffer_apply_tag (buffer, tag, &start, iter);
	}


## void gtk_text_buffer_delete (GtkTextBuffer *buffer, GtkTextIter *start, GtkTextIter *end)
void
gtk_text_buffer_delete (buffer, start, end)
	GtkTextBuffer *buffer
	GtkTextIter *start
	GtkTextIter *end

## gboolean gtk_text_buffer_delete_interactive (GtkTextBuffer *buffer, GtkTextIter *start_iter, GtkTextIter *end_iter, gboolean default_editable)
gboolean
gtk_text_buffer_delete_interactive (buffer, start_iter, end_iter, default_editable)
	GtkTextBuffer *buffer
	GtkTextIter *start_iter
	GtkTextIter *end_iter
	gboolean default_editable

void gtk_text_buffer_set_text (GtkTextBuffer *buffer, const gchar_length *text, int length(text))

gchar_own * gtk_text_buffer_get_text (GtkTextBuffer *buffer, GtkTextIter * start, GtkTextIter* end, gboolean include_hidden_chars)

gchar_own * gtk_text_buffer_get_slice (GtkTextBuffer *buffer, GtkTextIter *start, GtkTextIter *end, gboolean include_hidden_chars);

## void gtk_text_buffer_insert_pixbuf (GtkTextBuffer *buffer, GtkTextIter *iter, GdkPixbuf *pixbuf)
void
gtk_text_buffer_insert_pixbuf (buffer, iter, pixbuf)
	GtkTextBuffer *buffer
	GtkTextIter *iter
	GdkPixbuf *pixbuf

## void gtk_text_buffer_insert_child_anchor (GtkTextBuffer *buffer, GtkTextIter *iter, GtkTextChildAnchor *anchor)
void
gtk_text_buffer_insert_child_anchor (buffer, iter, anchor)
	GtkTextBuffer *buffer
	GtkTextIter *iter
	GtkTextChildAnchor *anchor

GtkTextMark* gtk_text_buffer_create_mark (GtkTextBuffer *buffer, const gchar_ornull *mark_name, GtkTextIter *where, gboolean left_gravity);

## void gtk_text_buffer_move_mark (GtkTextBuffer *buffer, GtkTextMark *mark, const GtkTextIter *where)
void
gtk_text_buffer_move_mark (buffer, mark, where)
	GtkTextBuffer *buffer
	GtkTextMark *mark
	GtkTextIter *where

## void gtk_text_buffer_delete_mark (GtkTextBuffer *buffer, GtkTextMark *mark)
void
gtk_text_buffer_delete_mark (buffer, mark)
	GtkTextBuffer *buffer
	GtkTextMark *mark

## GtkTextMark* gtk_text_buffer_get_mark (GtkTextBuffer *buffer, const gchar *name)
GtkTextMark_ornull*
gtk_text_buffer_get_mark (buffer, name)
	GtkTextBuffer *buffer
	const gchar *name

## void gtk_text_buffer_move_mark_by_name (GtkTextBuffer *buffer, const gchar *name, const GtkTextIter *where)
void
gtk_text_buffer_move_mark_by_name (buffer, name, where)
	GtkTextBuffer *buffer
	const gchar *name
	GtkTextIter *where

## void gtk_text_buffer_delete_mark_by_name (GtkTextBuffer *buffer, const gchar *name)
void
gtk_text_buffer_delete_mark_by_name (buffer, name)
	GtkTextBuffer *buffer
	const gchar *name

## GtkTextMark* gtk_text_buffer_get_insert (GtkTextBuffer *buffer)
GtkTextMark*
gtk_text_buffer_get_insert (buffer)
	GtkTextBuffer *buffer

## GtkTextMark* gtk_text_buffer_get_selection_bound (GtkTextBuffer *buffer)
GtkTextMark*
gtk_text_buffer_get_selection_bound (buffer)
	GtkTextBuffer *buffer

## void gtk_text_buffer_place_cursor (GtkTextBuffer *buffer, const GtkTextIter *where)
void
gtk_text_buffer_place_cursor (buffer, where)
	GtkTextBuffer *buffer
	GtkTextIter *where

#if GTK_CHECK_VERSION(2,4,0)

## void gtk_text_buffer_select_range (GtkTextBuffer *buffer, const GtkTextIter *ins, const GtkTextIter *bound);
void gtk_text_buffer_select_range (GtkTextBuffer *buffer, GtkTextIter *ins, GtkTextIter *bound);

#endif

## void gtk_text_buffer_apply_tag (GtkTextBuffer *buffer, GtkTextTag *tag, const GtkTextIter *start, const GtkTextIter *end)
void
gtk_text_buffer_apply_tag (buffer, tag, start, end)
	GtkTextBuffer *buffer
	GtkTextTag *tag
	GtkTextIter *start
	GtkTextIter *end

## void gtk_text_buffer_remove_tag (GtkTextBuffer *buffer, GtkTextTag *tag, const GtkTextIter *start, const GtkTextIter *end)
void
gtk_text_buffer_remove_tag (buffer, tag, start, end)
	GtkTextBuffer *buffer
	GtkTextTag *tag
	GtkTextIter *start
	GtkTextIter *end

## void gtk_text_buffer_apply_tag_by_name (GtkTextBuffer *buffer, const gchar *name, const GtkTextIter *start, const GtkTextIter *end)
void
gtk_text_buffer_apply_tag_by_name (buffer, name, start, end)
	GtkTextBuffer *buffer
	const gchar *name
	GtkTextIter *start
	GtkTextIter *end

## void gtk_text_buffer_remove_tag_by_name (GtkTextBuffer *buffer, const gchar *name, const GtkTextIter *start, const GtkTextIter *end)
void
gtk_text_buffer_remove_tag_by_name (buffer, name, start, end)
	GtkTextBuffer *buffer
	const gchar *name
	GtkTextIter *start
	GtkTextIter *end

## void gtk_text_buffer_remove_all_tags (GtkTextBuffer *buffer, const GtkTextIter *start, const GtkTextIter *end)
void
gtk_text_buffer_remove_all_tags (buffer, start, end)
	GtkTextBuffer *buffer
	GtkTextIter *start
	GtkTextIter *end


##GtkTextTag* gtk_text_buffer_create_tag      (GtkTextBuffer *buffer,
##                                             const gchar *tag_name,
##                                             const gchar *first_property_name,
##                                             ...);
## tag_name may be NULL.
## The returned tag is owned by the buffer's tag table!  do not use _noinc!
=for apidoc
=for arg property_name1 (string) the first property name
=for arg property_value1 (string) the first property value
=for arg ... pairs of names and values
=cut
GtkTextTag *
gtk_text_buffer_create_tag (buffer, tag_name, property_name1, property_value1, ...)
	GtkTextBuffer * buffer
	const gchar_ornull * tag_name
    PREINIT:
	GtkTextTagTable * tag_table;
	int i;
    CODE:
	if ((items - 2) % 2)
		croak ("expecting tag name followed by name=>value pairs");
	/*
	 * since we can't really pass on the varargs call from perl to C,
	 * we'll have to reimplement this convenience function ourselves.
	 */
	RETVAL = gtk_text_tag_new (tag_name);
	tag_table = gtk_text_buffer_get_tag_table (buffer);
	gtk_text_tag_table_add (tag_table, RETVAL);
	g_object_unref (RETVAL); /* the tag table owns the object now */
	for (i = 2 ; i < items ; i+= 2) {
		GValue gvalue = {0, };
		GParamSpec * pspec;
		const gchar * propname = SvGChar (ST (i));
		pspec = g_object_class_find_property (G_OBJECT_GET_CLASS (RETVAL),
		                                      propname);
		if (!pspec)
			warn ("   unknown property %s for class %s",
				propname, G_OBJECT_TYPE_NAME (RETVAL));
		else {
			g_value_init (&gvalue, pspec->value_type);
			gperl_value_from_sv (&gvalue, ST (i+1));
			g_object_set_property (G_OBJECT (RETVAL), propname,
			                       &gvalue);
			g_value_unset (&gvalue);
		}
	}
    OUTPUT:
	RETVAL

#### void gtk_text_buffer_get_iter_at_line_offset (GtkTextBuffer *buffer, GtkTextIter *iter, gint line_number, gint char_offset)
GtkTextIter_copy *
gtk_text_buffer_get_iter_at_line_offset (buffer, line_number, char_offset)
	GtkTextBuffer *buffer
	gint line_number
	gint char_offset
    PREINIT:
	GtkTextIter iter;
    CODE:
	gtk_text_buffer_get_iter_at_line_offset (buffer, &iter,
	                                         line_number, char_offset);
	RETVAL = &iter;
    OUTPUT:
	RETVAL


#### void gtk_text_buffer_get_iter_at_line_index (GtkTextBuffer *buffer, GtkTextIter *iter, gint line_number, gint byte_index)
GtkTextIter_copy *
gtk_text_buffer_get_iter_at_line_index (buffer, line_number, byte_index)
	GtkTextBuffer *buffer
	gint line_number
	gint byte_index
    PREINIT:
	GtkTextIter iter;
    CODE:
	gtk_text_buffer_get_iter_at_line_index (buffer, &iter,
	                                        line_number, byte_index);
	RETVAL = &iter;
    OUTPUT:
	RETVAL

#### void gtk_text_buffer_get_iter_at_offset (GtkTextBuffer *buffer, GtkTextIter *iter, gint char_offset)
GtkTextIter_copy *
gtk_text_buffer_get_iter_at_offset (buffer, char_offset)
	GtkTextBuffer *buffer
	gint char_offset
    PREINIT:
	GtkTextIter iter;
    CODE:
	gtk_text_buffer_get_iter_at_offset (buffer, &iter, char_offset);
	RETVAL = &iter;
    OUTPUT:
	RETVAL

#### void gtk_text_buffer_get_iter_at_line (GtkTextBuffer *buffer, GtkTextIter *iter, gint line_number)
GtkTextIter_copy *
gtk_text_buffer_get_iter_at_line (buffer, line_number)
	GtkTextBuffer *buffer
	gint line_number
    PREINIT:
	GtkTextIter iter;
    CODE:
	gtk_text_buffer_get_iter_at_line (buffer, &iter, line_number);
	RETVAL = &iter;
    OUTPUT:
	RETVAL

#### void gtk_text_buffer_get_start_iter (GtkTextBuffer *buffer, GtkTextIter *iter)
#### void gtk_text_buffer_get_end_iter (GtkTextBuffer *buffer, GtkTextIter *iter)
GtkTextIter_copy *
gtk_text_buffer_get_start_iter (buffer)
	GtkTextBuffer *buffer
    ALIAS:
	Gtk2::TextBuffer::get_end_iter = 1
    PREINIT:
	GtkTextIter iter;
    CODE:
	if (ix == 1)
		gtk_text_buffer_get_end_iter (buffer, &iter);
	else
		gtk_text_buffer_get_start_iter (buffer, &iter);
	RETVAL = &iter;
    OUTPUT:
	RETVAL


#### void gtk_text_buffer_get_bounds (GtkTextBuffer *buffer, GtkTextIter *start, GtkTextIter *end)
=for apidoc
=for signature (start, end) = $buffer->get_bounds
Retrieves the first and last iterators in the buffer, i.e. the entire buffer
lies within the range (start,end).
=cut
void
gtk_text_buffer_get_bounds (buffer)
	GtkTextBuffer *buffer
    PREINIT:
	GtkTextIter start = {0, };
	GtkTextIter end = {0, };
    PPCODE:
	gtk_text_buffer_get_bounds (buffer, &start, &end);
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVGtkTextIter_copy (&start)));
	PUSHs (sv_2mortal (newSVGtkTextIter_copy (&end)));

#### void gtk_text_buffer_get_iter_at_mark (GtkTextBuffer *buffer, GtkTextIter *iter, GtkTextMark *mark)
GtkTextIter_copy *
gtk_text_buffer_get_iter_at_mark (buffer, mark)
	GtkTextBuffer * buffer
	GtkTextMark * mark
    PREINIT:
	GtkTextIter iter;
    CODE:
	gtk_text_buffer_get_iter_at_mark (buffer, &iter, mark);
	RETVAL = &iter;
    OUTPUT:
	RETVAL

#### void gtk_text_buffer_get_iter_at_child_anchor (GtkTextBuffer *buffer, GtkTextIter *iter, GtkTextChildAnchor *anchor)
GtkTextIter_copy *
gtk_text_buffer_get_iter_at_child_anchor (buffer, anchor)
	GtkTextBuffer * buffer
	GtkTextChildAnchor * anchor
    PREINIT:
	GtkTextIter iter;
    CODE:
	gtk_text_buffer_get_iter_at_child_anchor (buffer, &iter, anchor);
	RETVAL = &iter;
    OUTPUT:
	RETVAL

## gboolean gtk_text_buffer_get_modified (GtkTextBuffer *buffer)
gboolean
gtk_text_buffer_get_modified (buffer)
	GtkTextBuffer *buffer

## void gtk_text_buffer_set_modified (GtkTextBuffer *buffer, gboolean setting)
void
gtk_text_buffer_set_modified (buffer, setting)
	GtkTextBuffer *buffer
	gboolean setting

#if GTK_CHECK_VERSION(2,2,0)

## void gtk_text_buffer_add_selection_clipboard (GtkTextBuffer *buffer, GtkClipboard *clipboard)
void
gtk_text_buffer_add_selection_clipboard (buffer, clipboard)
	GtkTextBuffer *buffer
	GtkClipboard *clipboard

## void gtk_text_buffer_remove_selection_clipboard (GtkTextBuffer *buffer, GtkClipboard *clipboard)
void
gtk_text_buffer_remove_selection_clipboard (buffer, clipboard)
	GtkTextBuffer *buffer
	GtkClipboard *clipboard

## void gtk_text_buffer_cut_clipboard (GtkTextBuffer *buffer, GtkClipboard *clipboard, gboolean default_editable)
void
gtk_text_buffer_cut_clipboard (buffer, clipboard, default_editable)
	GtkTextBuffer *buffer
	GtkClipboard *clipboard
	gboolean default_editable

## void gtk_text_buffer_copy_clipboard (GtkTextBuffer *buffer, GtkClipboard *clipboard)
void
gtk_text_buffer_copy_clipboard (buffer, clipboard)
	GtkTextBuffer *buffer
	GtkClipboard *clipboard

## void gtk_text_buffer_paste_clipboard (GtkTextBuffer *buffer, GtkClipboard *clipboard, GtkTextIter *override_location, gboolean default_editable)
void
gtk_text_buffer_paste_clipboard (buffer, clipboard, override_location, default_editable)
	GtkTextBuffer *buffer
	GtkClipboard *clipboard
	GtkTextIter_ornull *override_location
	gboolean default_editable

#endif /* defined GTK_TYPE_CLIPBOARD */

## gboolean gtk_text_buffer_get_selection_bounds (GtkTextBuffer *buffer, GtkTextIter *start, GtkTextIter *end)
## returns empty list if there is no selection
=for apidoc
=for signature (start, end) = $buffer->get_selection_bounds
Returns start and end if some text is selected, empty otherwise; places the
bounds of the selection in start and end (if the selection has length 0, then
start and end are filled in with the same value). start and end will be in
ascending order.  
=cut
void
gtk_text_buffer_get_selection_bounds (buffer)
	GtkTextBuffer *buffer
    PREINIT:
	GtkTextIter start;
	GtkTextIter end;
    PPCODE:
	if (!gtk_text_buffer_get_selection_bounds (buffer, &start, &end))
		XSRETURN_EMPTY;
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVGtkTextIter_copy (&start)));
	PUSHs (sv_2mortal (newSVGtkTextIter_copy (&end)));

## gboolean gtk_text_buffer_delete_selection (GtkTextBuffer *buffer, gboolean interactive, gboolean default_editable)
gboolean
gtk_text_buffer_delete_selection (buffer, interactive, default_editable)
	GtkTextBuffer *buffer
	gboolean interactive
	gboolean default_editable

## void gtk_text_buffer_begin_user_action (GtkTextBuffer *buffer)
void
gtk_text_buffer_begin_user_action (buffer)
	GtkTextBuffer *buffer

## void gtk_text_buffer_end_user_action (GtkTextBuffer *buffer)
void
gtk_text_buffer_end_user_action (buffer)
	GtkTextBuffer *buffer

##GtkTextChildAnchor * gtk_text_buffer_create_child_anchor (GtkTextBuffer *buffer, GtkTextIter *iter)
GtkTextChildAnchor *
gtk_text_buffer_create_child_anchor (buffer, iter)
	GtkTextBuffer * buffer
	GtkTextIter   * iter

#if GTK_CHECK_VERSION (2, 6, 0)

gboolean gtk_text_buffer_backspace (GtkTextBuffer *buffer, GtkTextIter *iter, gboolean interactive, gboolean default_editable);

#endif

#if GTK_CHECK_VERSION (2, 10, 0)

gboolean gtk_text_buffer_get_has_selection (GtkTextBuffer *buffer);

GtkTargetList* gtk_text_buffer_get_copy_target_list (GtkTextBuffer *buffer);

GtkTargetList* gtk_text_buffer_get_paste_target_list (GtkTextBuffer *buffer);

#endif /* 2.10 */

#if GTK_CHECK_VERSION (2, 12, 0)

void gtk_text_buffer_add_mark (GtkTextBuffer *buffer, GtkTextMark *mark, GtkTextIter *where);

#endif
