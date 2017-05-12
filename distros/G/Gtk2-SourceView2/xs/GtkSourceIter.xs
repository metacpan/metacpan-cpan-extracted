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

MODULE = Gtk2::SourceView2::Iter PACKAGE = Gtk2::SourceView2::Iter PREFIX = gtk_source_iter_

=for apidoc backward_search
=for signature (match_start, match_end) = Gtk2::SourceView2::Iter->backward_search ($iter, $str, $flags, $limit=NULL)
=cut

=for apidoc
=for signature (match_start, match_end) = Gtk2::SourceView2::Iter->forward_search ($iter, $str, $flags, $limit=NULL)
gtk_source_iter_forward_search (class, const GtkTextIter *iter, const gchar *str, GtkSourceSearchFlags flags, const GtkTextIter *limit = NULL)
=cut

void
gtk_source_iter_forward_search (class, const GtkTextIter *iter, const gchar *str, GtkSourceSearchFlags flags)
	ALIAS:
		backward_search = 1

	PREINIT:
		GtkTextIter match_start;
		GtkTextIter match_end;
		gboolean found = FALSE;
		gboolean (*searchfunc) (const GtkTextIter *iter, const gchar *str, GtkSourceSearchFlags flags, GtkTextIter *match_start, GtkTextIter *match_end, const GtkTextIter *limit);
		GtkTextIter *limit = NULL;

	PPCODE:
		
		searchfunc = (ix == 0 ? gtk_source_iter_forward_search : gtk_source_iter_backward_search);

		found = searchfunc(iter, str, flags, &match_start, &match_end, limit);
		if (! found) {
			XSRETURN_EMPTY;
		}

		EXTEND (SP, 2);
		PUSHs (sv_2mortal (newSVGtkTextIter_copy (&match_start)));
		PUSHs (sv_2mortal (newSVGtkTextIter_copy (&match_end)));
