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

MODULE = Gtk2::SourceView::Tag	PACKAGE = Gtk2::SourceView::Tag	PREFIX = gtk_source_tag_

gchar_own *gtk_source_tag_get_id (GtkSourceTag *tag);

GtkSourceTagStyle *gtk_source_tag_get_style (GtkSourceTag *tag);

void gtk_source_tag_set_style (GtkSourceTag *tag, const GtkSourceTagStyle *style);

MODULE = Gtk2::SourceView::Tag	PACKAGE = Gtk2::SourceView::SyntaxTag	PREFIX = gtk_syntax_tag_

# #define gtk_block_comment_tag_new gtk_syntax_tag_new
# GtkTextTag *gtk_syntax_tag_new (const gchar *id, const gchar *name, const gchar *pattern_start, const gchar *pattern_end);
GtkTextTag_noinc *
gtk_syntax_tag_new (class, id, name, pattern_start, pattern_end)
	const gchar *id
	const gchar *name
	const gchar *pattern_start
	const gchar *pattern_end
    C_ARGS:
	id, name, pattern_start, pattern_end

MODULE = Gtk2::SourceView::Tag	PACKAGE = Gtk2::SourceView::PatternTag	PREFIX = gtk_pattern_tag_

# GtkTextTag *gtk_pattern_tag_new (const gchar *id, const gchar *name, const gchar *pattern);
GtkTextTag_noinc *
gtk_pattern_tag_new (class, id, name, pattern)
	const gchar *id
	const gchar *name
	const gchar *pattern
    C_ARGS:
	id, name, pattern

MODULE = Gtk2::SourceView::Tag	PACKAGE = Gtk2::SourceView::KeywordListTag	PREFIX = gtk_keyword_list_tag_

# GtkTextTag *gtk_keyword_list_tag_new (const gchar *id, const gchar *name, const GSList *keywords, gboolean case_sensitive, gboolean match_empty_string_at_beginning, gboolean match_empty_string_at_end, const gchar *beginning_regex, const gchar *end_regex);
GtkTextTag_noinc *
gtk_keyword_list_tag_new (class, id, name, keywords, case_sensitive, match_empty_string_at_beginning, match_empty_string_at_end, beginning_regex, end_regex)
	const gchar *id
	const gchar *name
	SV *keywords
	gboolean case_sensitive
	gboolean match_empty_string_at_beginning
	gboolean match_empty_string_at_end
	const gchar *beginning_regex
	const gchar *end_regex
    PREINIT:
	AV *av;
	SV **value;
	int i;
	GSList *list = NULL;
    CODE:
	if (!SvOK (keywords) || !SvROK (keywords) || SvTYPE (SvRV (keywords)) != SVt_PVAV)
		croak ("The keywords argument must be an array reference");

	av = (AV *) SvRV (keywords);
	for (i = 0; i <= av_len (av); i++) {
		value = av_fetch (av, i, 0);
		if (value && SvOK (*value))
			list = g_slist_append (list, SvGChar (*value));
	}

	RETVAL = gtk_keyword_list_tag_new (id, name, list, case_sensitive,
	                                   match_empty_string_at_beginning,
	                                   match_empty_string_at_end,
	                                   beginning_regex, end_regex);

	g_slist_free (list);
    OUTPUT:
	RETVAL

MODULE = Gtk2::SourceView::Tag	PACKAGE = Gtk2::SourceView::LineCommentTag	PREFIX = gtk_line_comment_tag_

# GtkTextTag *gtk_line_comment_tag_new (const gchar *id, const gchar *name, const gchar *pattern_start);
GtkTextTag_noinc *
gtk_line_comment_tag_new (class, id, name, pattern_start)
	const gchar *id
	const gchar *name
	const gchar *pattern_start
    C_ARGS:
	id, name, pattern_start

MODULE = Gtk2::SourceView::Tag	PACKAGE = Gtk2::SourceView::StringTag	PREFIX = gtk_string_tag_

# GtkTextTag *gtk_string_tag_new (const gchar *id, const gchar *name, const gchar *pattern_start, const gchar *pattern_end, gboolean end_at_line_end);
GtkTextTag_noinc *
gtk_string_tag_new (class, id, name, pattern_start, pattern_end, end_at_line_end)
	const gchar *id
	const gchar *name
	const gchar *pattern_start
	const gchar *pattern_end
	gboolean end_at_line_end
    C_ARGS:
	id, name, pattern_start, pattern_end, end_at_line_end
