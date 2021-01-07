/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
   Copyright (C) 2004 muppet
   Copyright (C) 2000-2001 CodeFactory AB
   Copyright (C) 2000-2001 Jonas Borgström <jonas@codefactory.se>
   Copyright (C) 2000-2001 Anders Carlsson <andersca@codefactory.se>
   
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

MODULE = Gtk2::Html2::Document	PACKAGE = Gtk2::Html2::Document	PREFIX = html_document_


 ## typedef enum {
 ## 	HTML_DOCUMENT_STATE_DONE,
 ## 	HTML_DOCUMENT_STATE_PARSING
 ## } HtmlDocumentState;
 ## 
 ## struct _HtmlDocument {
 ## 	GObject parent_instance;
 ## 	
 ## 	DomDocument *dom_document;
 ## 	
 ## 	GSList *stylesheets;
 ## 
 ## 	HtmlParser *parser;
 ## 	HtmlStream *current_stream;
 ## 
 ## 	HtmlImageFactory *image_factory;
 ## 
 ## 	HtmlDocumentState state;
 ## 
 ## 	DomNode *hover_node;
 ## 	DomNode *active_node;
 ## 	DomElement *focus_element;
 ## };
 ## 
 ## struct _HtmlDocumentClass {
 ## 	GObjectClass parent_class;
 ## 
 ## 	void (*request_url) (HtmlDocument *document, const gchar *url, HtmlStream *stream);
 ## 	void (*link_clicked) (HtmlDocument *document, const gchar *url);
 ## 	void (*set_base) (HtmlDocument *document, const gchar *url);
 ## 	void (*title_changed) (HtmlDocument *document, const gchar *new_title);
 ## 	void (*submit) (HtmlDocument *document, const gchar *method, const gchar *url, const gchar *encoding);
 ## 
 ## 	/* DOM change events */
 ## 	void (*node_inserted) (HtmlDocument *document, DomNode *node);
 ## 	void (*node_removed) (HtmlDocument *document, DomNode *node);
 ## 	void (*text_updated) (HtmlDocument *document, DomNode *node);
 ## 	void (*style_updated) (HtmlDocument *document, DomNode *node, HtmlStyleChange style_change);
 ## 
 ## 	/* View notifications */
 ## 	void (*relayout_node) (HtmlDocument *document, DomNode *node);
 ## 	void (*repaint_node) (HtmlDocument *document, DomNode *node);
 ## 
 ## 	/* DOM events */
 ## 	gboolean (*dom_mouse_down) (HtmlDocument *document, DomEvent *event);
 ## 	gboolean (*dom_mouse_up) (HtmlDocument *document, DomEvent *event);
 ## 	gboolean (*dom_mouse_click) (HtmlDocument *document, DomEvent *event);
 ## 	gboolean (*dom_mouse_over) (HtmlDocument *document, DomEvent *event);
 ## 	gboolean (*dom_mouse_out) (HtmlDocument *document, DomEvent *event);
 ## };
 ## 
 ## 
 ## GType html_document_get_type (void);

HtmlDocument_noinc *html_document_new (class)
    C_ARGS:
	/*void*/

gboolean html_document_open_stream (HtmlDocument *document, const gchar *mime_type);

void html_document_write_stream (HtmlDocument *document, const gchar_length *buffer, int length(buffer));

void html_document_close_stream (HtmlDocument *document);

HtmlStream * current_stream (HtmlDocument * document)
    CODE:
	if (!HTML_IS_STREAM (document->current_stream))
		XSRETURN_UNDEF;
	RETVAL = document->current_stream;
    OUTPUT:
	RETVAL

void html_document_clear (HtmlDocument *document);


 ## void html_document_update_hover_node (HtmlDocument *document, DomNode *node);

 ## void html_document_update_active_node (HtmlDocument *document, DomNode *node);

 ## void html_document_update_focus_element (HtmlDocument *document, DomElement *element);

 ## DomNode *html_document_find_anchor (HtmlDocument *doc, const gchar *anchor);

