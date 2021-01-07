/*
   Copyright (C) 2004 muppet
   Copyright (C) 2000 CodeFactory AB
   Copyright (C) 2000 Jonas Borgström <jonas@codefactory.se>
   Copyright (C) 2000 Anders Carlsson <andersca@codefactory.se>
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public License
   along with this library; see the file COPYING.LIB.  If not, see
   <https://www.gnu.org/licenses/>.
*/
#include "gtkhtml2perl.h"

MODULE = Gtk2::Html2::Context	PACKAGE = Gtk2::Html2::Context	PREFIX = gtk_html_context_

BOOT:
	/* hi */

###define GTK_HTML_CONTEXT_TYPE            (gtk_html_context_get_type ())
###define GTK_HTML_CONTEXT(obj)            (GTK_CHECK_CAST ((obj), GTK_HTML_CONTEXT_TYPE, GtkHtmlContext))
###define GTK_HTML_CONTEXT_CLASS(klass)    (GTK_CHECK_CLASS_CAST ((klass), GTK_HTML_CONTEXT_TYPE, GtkHtmlContextClass))
###define GTK_HTML_IS_CONTEXT(obj)         (GTK_CHECK_TYPE ((obj), GTK_HTML_CONTEXT_TYPE))
###define GTK_HTML_IS_CONTEXT_CLASS(klass) (GTK_CHECK_CLASS_TYPE ((klass), GTK_HTML_CONTEXT_TYPE))
##
##struct _GtkHtmlContext {
##	GObject parent;
##
##	/* List of documents */
##	GSList *documents;
##
###if 0	/* FIXME: Use these */
##	/* Standard font */
##	HtmlFontSpecification *standard_font;
##
##	/* Standard fixed width font */
##	HtmlFontSpecification *fixed_font;
###endif
##
##	gboolean debug_painting;
##};
##
##struct _GtkHtmlContextClass {
##	GObjectClass parent;
##};
##
##GType    gtk_html_context_get_type (void);


GtkHtmlContext *gtk_html_context_get (class)
    C_ARGS:
	/*void*/

