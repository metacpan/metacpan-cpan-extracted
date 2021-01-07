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

MODULE = Gtk2::Html2::View	PACKAGE = Gtk2::Html2::View	PREFIX = html_view_

 ## typedef enum {
 ## 	HTML_VIEW_SCROLL_TO_TOP,
 ## 	HTML_VIEW_SCROLL_TO_BOTTOM,
 ## } HtmlViewScrollToType;
 ## 
 ## struct _HtmlView {
 ## 	GtkLayout parent;
 ## 
 ## 
 ## 	HtmlDocument *document;
 ## 
 ## 	HtmlBox *root;
 ## 	
 ## 	GHashTable *node_table;
 ## 
 ## 	HtmlPainter *painter;
 ## 
 ## 	guint relayout_idle_id;
 ## 	guint relayout_timeout_id;
 ## 
 ## 	gint mouse_down_x, mouse_down_y;
 ## 	gint mouse_detail;
 ## 
 ## 	/* Begin selection */
 ## 	HtmlBox *sel_start;
 ## 	gint     sel_start_ypos;
 ## 	gint     sel_start_index;
 ## 
 ## 	HtmlBox *sel_end;
 ## 	gint     sel_end_ypos;
 ## 	gint     sel_end_index;
 ## 
 ## 	gboolean sel_flag;
 ## 	gboolean sel_backwards;
 ## 	gboolean sel_start_found;
 ## 
 ## 	GSList *sel_list;
 ## 	/* End selection */
 ## 
 ## 	/* Anchor jumping */
 ## 	gchar   *jump_to_anchor;
 ## 
 ## 	gdouble magnification;
 ## 	gboolean magnification_modified;
 ## 	gboolean on_url;
 ## };
 ## 
 ## struct _HtmlViewClass {
 ## 	GtkLayoutClass parent;
 ## 
 ## 	/* move insertion point */
 ## 	void (* move_cursor) (HtmlView       *html_view,
 ## 			      GtkMovementStep step,
 ## 			      gint            count,
 ## 			      gboolean        extend_selection);
 ## 
 ## 	gboolean (* request_object) (HtmlView *html_view, HtmlEmbedded *widget);
 ## 	void (*on_url) (HtmlView *html_view, const gchar *url);
 ## 	void (*activate) (HtmlView *html_view);
 ## 	void (* move_focus_out) (HtmlView         *html_view,
 ## 				 GtkDirectionType  direction);
 ## };

 ## GType html_view_get_type (void);

GtkWidget *html_view_new (class)
    C_ARGS:
	/*void*/

void html_view_set_document (HtmlView *view, HtmlDocument_ornull *document);

void html_view_jump_to_anchor (HtmlView *view, const gchar *anchor);

gdouble html_view_get_magnification (HtmlView *view);

void html_view_set_magnification (HtmlView *view, gdouble magnification);

void html_view_zoom_in (HtmlView *view);

void html_view_zoom_out (HtmlView *view);

void html_view_zoom_reset (HtmlView *view);

 ## no typemap for HtmlBox
 ## HtmlBox * html_view_find_layout_box (HtmlView *view, DomNode *node, gboolean find_parent);

 ## no GType (and therefore no typemap) for HtmlViewScrollToType
 ## void html_view_scroll_to_node (HtmlView *view, DomNode *node, HtmlViewScrollToType type);
