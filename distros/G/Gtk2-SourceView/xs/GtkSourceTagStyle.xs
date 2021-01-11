/*
 * Copyright (c) 2005 by Torsten Schoenfeld (see the file AUTHORS)
 * Copyright (c) 2005 by Emmanuele Bassi (see the file AUTHORS)
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

MODULE = Gtk2::SourceView::TagStyle	PACKAGE = Gtk2::SourceView::TagStyle	PREFIX = gtk_source_tag_style_

# GtkSourceTagStyle *gtk_source_tag_style_new (void);
GtkSourceTagStyle_own *
gtk_source_tag_style_new (class)
    C_ARGS:
	/* void */

SV *
is_default (t, newval=NULL)
	GtkSourceTagStyle * t
	SV * newval
    ALIAS:
	Gtk2::SourceView::TagStyle::mask          = 1
	Gtk2::SourceView::TagStyle::foreground    = 2
	Gtk2::SourceView::TagStyle::background    = 3
	Gtk2::SourceView::TagStyle::italic        = 4
	Gtk2::SourceView::TagStyle::bold          = 5
	Gtk2::SourceView::TagStyle::underline     = 6
	Gtk2::SourceView::TagStyle::strikethrough = 7
    CODE:
	switch (ix) {
		case 0:	RETVAL = newSViv (t->is_default); break;
		case 1:
			if (newval)
				t->mask = SvGtkSourceTagStyleMask (newval);
			RETVAL = newSVGtkSourceTagStyleMask (t->mask);
			break;
		case 2:
			if (newval)
				t->foreground = *((GdkColor*) SvGdkColor (newval));
			RETVAL = newSVGdkColor (&(t->foreground));
			break;
		case 3:
			if (newval)
				t->background = *((GdkColor*) SvGdkColor (newval));
			RETVAL = newSVGdkColor (&(t->background));
			break;
		case 4:
			if (newval)
				t->italic = SvIV (newval);
			RETVAL = newSViv (t->italic);
			break;
		case 5:
			if (newval)
				t->bold = SvIV (newval);
			RETVAL = newSViv (t->bold);
			break;
		case 6:
			if (newval)
				t->underline = SvIV (newval);
			RETVAL = newSViv (t->underline);
			break;
		case 7:
			if (newval)
				t->strikethrough = SvIV (newval);
			RETVAL = newSViv (t->strikethrough);
			break;
		default:
			RETVAL = NULL;
			g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

