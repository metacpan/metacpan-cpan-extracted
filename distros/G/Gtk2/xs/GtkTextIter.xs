/*
 * Copyright (c) 2003-2005 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"
#include <gperl_marshal.h>

static GPerlCallback *
create_text_char_predicate_callback (SV * func, SV * data)
{
	return gperl_callback_new (func, data, 0, NULL, G_TYPE_BOOLEAN);
}

static gboolean
gtk2perl_text_char_predicate (gunichar ch,
                              gpointer user_data)
{
	GPerlCallback * callback = (GPerlCallback *) user_data;
	gboolean ret;
	SV * svch;
	gchar temp[6];
	gint length;
	dGPERL_CALLBACK_MARSHAL_SP;

	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;
	PUSHMARK (SP);

	length = g_unichar_to_utf8 (ch, temp);
	svch = newSVpv (temp, length);
	SvUTF8_on (svch);
	XPUSHs (sv_2mortal (svch));

	if (callback->data)
		XPUSHs (callback->data);

	PUTBACK;
	call_sv (callback->func, G_SCALAR);
	SPAGAIN;

	ret = POPi;

	PUTBACK;
	FREETMPS;
	LEAVE;
 
	return ret;
}

MODULE = Gtk2::TextIter	PACKAGE = Gtk2::TextIter	PREFIX = gtk_text_iter_

GtkTextBuffer*
gtk_text_iter_get_buffer (iter)
	GtkTextIter * iter

 # boxed wrapper support taken care of by Glib::Boxed
## GtkTextIter* gtk_text_iter_copy (const GtkTextIter *iter);
## void gtk_text_iter_free (GtkTextIter *iter);

## gint gtk_text_iter_get_offset (const GtkTextIter *iter)
gint
gtk_text_iter_get_offset (iter)
	GtkTextIter *iter

## gint gtk_text_iter_get_line (const GtkTextIter *iter)
gint
gtk_text_iter_get_line (iter)
	GtkTextIter *iter

## gint gtk_text_iter_get_line_offset (const GtkTextIter *iter)
gint
gtk_text_iter_get_line_offset (iter)
	GtkTextIter *iter

## gint gtk_text_iter_get_line_index (const GtkTextIter *iter)
gint
gtk_text_iter_get_line_index (iter)
	GtkTextIter *iter

## gint gtk_text_iter_get_visible_line_offset (const GtkTextIter *iter)
gint
gtk_text_iter_get_visible_line_offset (iter)
	GtkTextIter *iter

## gint gtk_text_iter_get_visible_line_index (const GtkTextIter *iter)
gint
gtk_text_iter_get_visible_line_index (iter)
	 GtkTextIter *iter

## gunichar gtk_text_iter_get_char (const GtkTextIter *iter)
gunichar
gtk_text_iter_get_char (iter)
	GtkTextIter *iter

gchar_own *
gtk_text_iter_get_slice (start, end)
	GtkTextIter * start
	GtkTextIter * end

gchar_own *
gtk_text_iter_get_text (start, end)
	GtkTextIter * start
	GtkTextIter * end

gchar_own * gtk_text_iter_get_visible_slice (GtkTextIter *start, GtkTextIter *end)

gchar_own * gtk_text_iter_get_visible_text (GtkTextIter *start, GtkTextIter *end)

## GdkPixbuf* gtk_text_iter_get_pixbuf (const GtkTextIter *iter)
GdkPixbuf_ornull*
gtk_text_iter_get_pixbuf (iter)
	GtkTextIter *iter

## GSList * gtk_text_iter_get_marks (const GtkTextIter *iter)
=for apidoc
Returns a list of all Gtk2::TextMark at this location. Because marks are not
iterable (they don't take up any "space" in the buffer, they are just marks in
between iterable locations), multiple marks can exist in the same place. The
returned list is not in any meaningful order.
=cut
void
gtk_text_iter_get_marks (GtkTextIter *iter)
    PREINIT:
	GSList * marks, * i;
    PPCODE:
	marks = gtk_text_iter_get_marks (iter);
	for (i = marks ; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVGtkTextMark (i->data)));
	g_slist_free (marks);

## GSList* gtk_text_iter_get_toggled_tags  (const GtkTextIter *iter, gboolean toggled_on)
=for apidoc
Returns a list of Gtk2::TextTag that are toggled on or off at this point. (If
toggled_on is TRUE, the list contains tags that are toggled on.) If a tag is
toggled on at iter, then some non-empty range of characters following iter has
that tag applied to it. If a tag is toggled off, then some non-empty range
following iter does not have the tag applied to it.
=cut
void
gtk_text_iter_get_toggled_tags (GtkTextIter * iter, gboolean toggled_on)
    PREINIT:
	GSList * tags, * i;
    PPCODE:
	tags = gtk_text_iter_get_toggled_tags (iter, toggled_on);
	for (i = tags ; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVGtkTextTag (i->data)));
	g_slist_free (tags);

## GtkTextChildAnchor* gtk_text_iter_get_child_anchor (const GtkTextIter *iter)
GtkTextChildAnchor_ornull*
gtk_text_iter_get_child_anchor (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_begins_tag (const GtkTextIter *iter, GtkTextTag *tag)
gboolean
gtk_text_iter_begins_tag (iter, tag)
	GtkTextIter *iter
	GtkTextTag_ornull *tag

## gboolean gtk_text_iter_ends_tag (const GtkTextIter *iter, GtkTextTag *tag)
gboolean
gtk_text_iter_ends_tag (iter, tag)
	GtkTextIter *iter
	GtkTextTag_ornull *tag

## gboolean gtk_text_iter_toggles_tag (const GtkTextIter *iter, GtkTextTag *tag)
gboolean
gtk_text_iter_toggles_tag (iter, tag)
	GtkTextIter *iter
	GtkTextTag_ornull *tag

## gboolean gtk_text_iter_has_tag (const GtkTextIter *iter, GtkTextTag *tag)
gboolean
gtk_text_iter_has_tag (iter, tag)
	GtkTextIter *iter
	GtkTextTag *tag

### GSList* gtk_text_iter_get_tags (const GtkTextIter *iter)
=for apidoc
Returns a list of tags that apply to iter, in ascending order of priority
(highest-priority tags are last). 
=cut
void
gtk_text_iter_get_tags (GtkTextIter *iter)
    PREINIT:
	GSList* slist, *i;
    PPCODE:
	slist = gtk_text_iter_get_tags (iter);
	for (i = slist ; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVGtkTextTag (i->data)));
	g_slist_free (slist);
	

## gboolean gtk_text_iter_editable (const GtkTextIter *iter, gboolean default_setting)
gboolean
gtk_text_iter_editable (iter, default_setting)
	GtkTextIter *iter
	gboolean default_setting

## gboolean gtk_text_iter_can_insert (const GtkTextIter *iter, gboolean default_editability)
gboolean
gtk_text_iter_can_insert (iter, default_editability)
	GtkTextIter *iter
	gboolean default_editability

## gboolean gtk_text_iter_starts_word (const GtkTextIter *iter)
gboolean
gtk_text_iter_starts_word (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_ends_word (const GtkTextIter *iter)
gboolean
gtk_text_iter_ends_word (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_inside_word (const GtkTextIter *iter)
gboolean
gtk_text_iter_inside_word (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_starts_sentence (const GtkTextIter *iter)
gboolean
gtk_text_iter_starts_sentence (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_ends_sentence (const GtkTextIter *iter)
gboolean
gtk_text_iter_ends_sentence (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_inside_sentence (const GtkTextIter *iter)
gboolean
gtk_text_iter_inside_sentence (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_starts_line (const GtkTextIter *iter)
gboolean
gtk_text_iter_starts_line (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_ends_line (const GtkTextIter *iter)
gboolean
gtk_text_iter_ends_line (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_is_cursor_position (const GtkTextIter *iter)
gboolean
gtk_text_iter_is_cursor_position (iter)
	GtkTextIter *iter

## gint gtk_text_iter_get_chars_in_line (const GtkTextIter *iter)
gint
gtk_text_iter_get_chars_in_line (iter)
	GtkTextIter *iter

## gint gtk_text_iter_get_bytes_in_line (const GtkTextIter *iter)
gint
gtk_text_iter_get_bytes_in_line (iter)
	GtkTextIter *iter

### gboolean gtk_text_iter_get_attributes (const GtkTextIter *iter, GtkTextAttributes *values)
GtkTextAttributes_copy*
gtk_text_iter_get_attributes (GtkTextIter *iter)
    PREINIT:
	GtkTextAttributes values;
    CODE:
	if (!gtk_text_iter_get_attributes (iter, &values))
		XSRETURN_UNDEF;
	RETVAL = &values;
    OUTPUT:
	RETVAL

# i think the returned value should NOT be owned
## PangoLanguage* gtk_text_iter_get_language (const GtkTextIter *iter)
PangoLanguage*
gtk_text_iter_get_language (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_is_end (const GtkTextIter *iter)
gboolean
gtk_text_iter_is_end (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_is_start (const GtkTextIter *iter)
gboolean
gtk_text_iter_is_start (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_forward_char (GtkTextIter *iter)
gboolean
gtk_text_iter_forward_char (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_backward_char (GtkTextIter *iter)
gboolean
gtk_text_iter_backward_char (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_forward_chars (GtkTextIter *iter, gint count)
gboolean
gtk_text_iter_forward_chars (iter, count)
	GtkTextIter *iter
	gint count

## gboolean gtk_text_iter_backward_chars (GtkTextIter *iter, gint count)
gboolean
gtk_text_iter_backward_chars (iter, count)
	GtkTextIter *iter
	gint count

## gboolean gtk_text_iter_forward_line (GtkTextIter *iter)
gboolean
gtk_text_iter_forward_line (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_backward_line (GtkTextIter *iter)
gboolean
gtk_text_iter_backward_line (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_forward_lines (GtkTextIter *iter, gint count)
gboolean
gtk_text_iter_forward_lines (iter, count)
	GtkTextIter *iter
	gint count

## gboolean gtk_text_iter_backward_lines (GtkTextIter *iter, gint count)
gboolean
gtk_text_iter_backward_lines (iter, count)
	GtkTextIter *iter
	gint count

## gboolean gtk_text_iter_forward_word_end (GtkTextIter *iter)
gboolean
gtk_text_iter_forward_word_end (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_backward_word_start (GtkTextIter *iter)
gboolean
gtk_text_iter_backward_word_start (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_forward_word_ends (GtkTextIter *iter, gint count)
gboolean
gtk_text_iter_forward_word_ends (iter, count)
	GtkTextIter *iter
	gint count

## gboolean gtk_text_iter_backward_word_starts (GtkTextIter *iter, gint count)
gboolean
gtk_text_iter_backward_word_starts (iter, count)
	GtkTextIter *iter
	gint count

#if GTK_CHECK_VERSION(2,4,0)

gboolean gtk_text_iter_forward_visible_word_end (GtkTextIter *iter);

gboolean gtk_text_iter_backward_visible_word_start (GtkTextIter *iter);

gboolean gtk_text_iter_forward_visible_word_ends (GtkTextIter *iter, gint count);

gboolean gtk_text_iter_backward_visible_word_starts (GtkTextIter *iter, gint count);

#endif

## gboolean gtk_text_iter_forward_sentence_end (GtkTextIter *iter)
gboolean
gtk_text_iter_forward_sentence_end (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_backward_sentence_start (GtkTextIter *iter)
gboolean
gtk_text_iter_backward_sentence_start (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_forward_sentence_ends (GtkTextIter *iter, gint count)
gboolean
gtk_text_iter_forward_sentence_ends (iter, count)
	GtkTextIter *iter
	gint count

## gboolean gtk_text_iter_backward_sentence_starts (GtkTextIter *iter, gint count)
gboolean
gtk_text_iter_backward_sentence_starts (iter, count)
	GtkTextIter *iter
	gint count

## gboolean gtk_text_iter_forward_cursor_position (GtkTextIter *iter)
gboolean
gtk_text_iter_forward_cursor_position (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_backward_cursor_position (GtkTextIter *iter)
gboolean
gtk_text_iter_backward_cursor_position (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_forward_cursor_positions (GtkTextIter *iter, gint count)
gboolean
gtk_text_iter_forward_cursor_positions (iter, count)
	GtkTextIter *iter
	gint count

## gboolean gtk_text_iter_backward_cursor_positions (GtkTextIter *iter, gint count)
gboolean
gtk_text_iter_backward_cursor_positions (iter, count)
	GtkTextIter *iter
	gint count

#if GTK_CHECK_VERSION(2,4,0)

gboolean gtk_text_iter_forward_visible_cursor_position   (GtkTextIter *iter);

gboolean gtk_text_iter_backward_visible_cursor_position  (GtkTextIter *iter);

gboolean gtk_text_iter_forward_visible_cursor_positions  (GtkTextIter *iter, gint count);

gboolean gtk_text_iter_backward_visible_cursor_positions (GtkTextIter *iter, gint count);

#endif

## void gtk_text_iter_set_offset (GtkTextIter *iter, gint char_offset)
void
gtk_text_iter_set_offset (iter, char_offset)
	GtkTextIter *iter
	gint char_offset

## void gtk_text_iter_set_line (GtkTextIter *iter, gint line_number)
void
gtk_text_iter_set_line (iter, line_number)
	GtkTextIter *iter
	gint line_number

## void gtk_text_iter_set_line_offset (GtkTextIter *iter, gint char_on_line)
void
gtk_text_iter_set_line_offset (iter, char_on_line)
	GtkTextIter *iter
	gint char_on_line

## void gtk_text_iter_set_line_index (GtkTextIter *iter, gint byte_on_line)
void
gtk_text_iter_set_line_index (iter, byte_on_line)
	GtkTextIter *iter
	gint byte_on_line

## void gtk_text_iter_forward_to_end (GtkTextIter *iter)
void
gtk_text_iter_forward_to_end (iter)
	GtkTextIter *iter

## gboolean gtk_text_iter_forward_to_line_end (GtkTextIter *iter)
gboolean
gtk_text_iter_forward_to_line_end (iter)
	GtkTextIter *iter

## void gtk_text_iter_set_visible_line_offset (GtkTextIter *iter, gint char_on_line)
void
gtk_text_iter_set_visible_line_offset (iter, char_on_line)
	GtkTextIter *iter
	gint char_on_line

## void gtk_text_iter_set_visible_line_index (GtkTextIter *iter, gint byte_on_line)
void
gtk_text_iter_set_visible_line_index (iter, byte_on_line)
	GtkTextIter *iter
	gint byte_on_line

## gboolean gtk_text_iter_forward_to_tag_toggle (GtkTextIter *iter, GtkTextTag *tag)
gboolean
gtk_text_iter_forward_to_tag_toggle (iter, tag)
	GtkTextIter       * iter
	GtkTextTag_ornull * tag

## gboolean gtk_text_iter_backward_to_tag_toggle (GtkTextIter *iter, GtkTextTag *tag)
gboolean
gtk_text_iter_backward_to_tag_toggle (iter, tag)
	GtkTextIter       * iter
	GtkTextTag_ornull * tag

## gboolean gtk_text_iter_forward_find_char (GtkTextIter *iter, GtkTextCharPredicate pred, gpointer user_data, const GtkTextIter *limit)
## gboolean gtk_text_iter_backward_find_char (GtkTextIter *iter, GtkTextCharPredicate pred, gpointer user_data, const GtkTextIter *limit)
gboolean
gtk_text_iter_forward_find_char (iter, pred, user_data=NULL, limit=NULL)
	GtkTextIter *iter
	SV * pred
	SV * user_data
	GtkTextIter_ornull *limit
    ALIAS:
	backward_find_char = 1
    PREINIT:
	GPerlCallback * callback;
    CODE:
	callback = create_text_char_predicate_callback (pred, user_data);
	if (ix == 1)
		RETVAL = gtk_text_iter_backward_find_char
				(iter, gtk2perl_text_char_predicate,
				 callback, limit);
	else
		RETVAL = gtk_text_iter_forward_find_char
				(iter, gtk2perl_text_char_predicate,
				 callback, limit);
	gperl_callback_destroy (callback);
    OUTPUT:
	RETVAL

## gboolean gtk_text_iter_forward_search (const GtkTextIter *iter, const gchar *str, GtkTextSearchFlags flags, GtkTextIter *match_start, GtkTextIter *match_end, const GtkTextIter *limit)
#### gboolean gtk_text_iter_backward_search (const GtkTextIter *iter, const gchar *str, GtkTextSearchFlags flags, GtkTextIter *match_start, GtkTextIter *match_end, const GtkTextIter *limit)

=for apidoc backward_search
=for signature (match_start, match_end) = $iter->backward_search ($str, $flags, $limit=NULL)
=cut

=for apidoc
=for signature (match_start, match_end) = $iter->forward_search ($str, $flags, $limit=NULL)
=cut
void
gtk_text_iter_forward_search (iter, str, flags, limit=NULL)
	const GtkTextIter *iter
	const gchar *str
	GtkTextSearchFlags flags
	GtkTextIter_ornull *limit
    ALIAS:
	backward_search = 1
    PREINIT:
	GtkTextIter match_start;
	GtkTextIter match_end;
	gboolean (*searchfunc) (const GtkTextIter*, const gchar*,
	                        GtkTextSearchFlags, GtkTextIter*, GtkTextIter*,
	                        const GtkTextIter*);
    PPCODE:
	searchfunc = ix == 1
	           ? gtk_text_iter_backward_search
	           : gtk_text_iter_forward_search;
	if (! searchfunc (iter, str, flags, &match_start, &match_end, limit))
		XSRETURN_EMPTY;
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVGtkTextIter_copy (&match_start)));
	PUSHs (sv_2mortal (newSVGtkTextIter_copy (&match_end)));


## gboolean gtk_text_iter_equal (const GtkTextIter *lhs, const GtkTextIter *rhs)
gboolean
gtk_text_iter_equal (lhs, rhs)
	GtkTextIter *lhs
	GtkTextIter *rhs

## gint gtk_text_iter_compare (const GtkTextIter *lhs, const GtkTextIter *rhs)
gint
gtk_text_iter_compare (lhs, rhs)
	GtkTextIter *lhs
	GtkTextIter *rhs

## gboolean gtk_text_iter_in_range (const GtkTextIter *iter, const GtkTextIter *start, const GtkTextIter *end)
gboolean
gtk_text_iter_in_range (iter, start, end)
	GtkTextIter *iter
	GtkTextIter *start
	GtkTextIter *end

## void gtk_text_iter_order (GtkTextIter *first, GtkTextIter *second)
void
gtk_text_iter_order (first, second)
	GtkTextIter *first
	GtkTextIter *second

#if GTK_CHECK_VERSION (2, 8, 0)

gboolean gtk_text_iter_forward_visible_line (GtkTextIter *iter);

gboolean gtk_text_iter_backward_visible_line (GtkTextIter *iter);

gboolean gtk_text_iter_forward_visible_lines (GtkTextIter *iter, gint count);

gboolean gtk_text_iter_backward_visible_lines (GtkTextIter *iter, gint count);

#endif
