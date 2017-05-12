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

MODULE = Gtk2::Dnd	PACKAGE = Gtk2::Gdk::DragContext	PREFIX = gtk_drag_

##  void gtk_drag_finish (GdkDragContext *context, gboolean success, gboolean del, guint32 time_) 
void
gtk_drag_finish (context, success, del, time_)
	GdkDragContext *context
	gboolean success
	gboolean del
	guint32 time_

##  GtkWidget *gtk_drag_get_source_widget (GdkDragContext *context) 
GtkWidget *
gtk_drag_get_source_widget (context)
	GdkDragContext *context

##  void gtk_drag_set_icon_widget (GdkDragContext *context, GtkWidget *widget, gint hot_x, gint hot_y) 
void
gtk_drag_set_icon_widget (context, widget, hot_x, hot_y)
	GdkDragContext *context
	GtkWidget *widget
	gint hot_x
	gint hot_y

##  void gtk_drag_set_icon_pixmap (GdkDragContext *context, GdkColormap *colormap, GdkPixmap *pixmap, GdkBitmap *mask, gint hot_x, gint hot_y) 
void
gtk_drag_set_icon_pixmap (context, colormap, pixmap, mask, hot_x, hot_y)
	GdkDragContext *context
	GdkColormap *colormap
	GdkPixmap *pixmap
	GdkBitmap_ornull *mask
	gint hot_x
	gint hot_y

##  void gtk_drag_set_icon_pixbuf (GdkDragContext *context, GdkPixbuf *pixbuf, gint hot_x, gint hot_y) 
void
gtk_drag_set_icon_pixbuf (context, pixbuf, hot_x, hot_y)
	GdkDragContext *context
	GdkPixbuf *pixbuf
	gint hot_x
	gint hot_y

##  void gtk_drag_set_icon_stock (GdkDragContext *context, const gchar *stock_id, gint hot_x, gint hot_y) 
void
gtk_drag_set_icon_stock (context, stock_id, hot_x, hot_y)
	GdkDragContext *context
	const gchar *stock_id
	gint hot_x
	gint hot_y

#if GTK_CHECK_VERSION (2, 8, 0)

void gtk_drag_set_icon_name (GdkDragContext *context, const gchar *icon_name, gint hot_x, gint hot_y)

#endif

##  void gtk_drag_set_icon_default (GdkDragContext *context) 
void
gtk_drag_set_icon_default (context)
	GdkDragContext *context

MODULE = Gtk2::Dnd	PACKAGE = Gtk2::Drag	PREFIX = gtk_drag_

##  GdkDragContext *gtk_drag_begin (GtkWidget *widget, GtkTargetList *targets, GdkDragAction actions, gint button, GdkEvent *event) 
GdkDragContext_noinc *
gtk_drag_begin (class, widget, targets, actions, button, event)
	GtkWidget *widget
	GtkTargetList *targets
	GdkDragAction actions
	gint button
	GdkEvent *event
    C_ARGS:
	widget, targets, actions, button, event

MODULE = Gtk2::Dnd	PACKAGE = Gtk2::Widget	PREFIX = gtk_

##  GdkDragContext *gtk_drag_begin (GtkWidget *widget, GtkTargetList *targets, GdkDragAction actions, gint button, GdkEvent *event) 
GdkDragContext_noinc *
gtk_drag_begin (widget, targets, actions, button, event)
	GtkWidget *widget
	GtkTargetList *targets
	GdkDragAction actions
	gint button
	GdkEvent *event

##  void gtk_drag_get_data (GtkWidget *widget, GdkDragContext *context, GdkAtom target, guint32 time_) 
void
gtk_drag_get_data (widget, context, target, time_)
	GtkWidget *widget
	GdkDragContext *context
	GdkAtom target
	guint32 time_

##  void gtk_drag_highlight (GtkWidget *widget) 
void
gtk_drag_highlight (widget)
	GtkWidget *widget

##  void gtk_drag_unhighlight (GtkWidget *widget) 
void
gtk_drag_unhighlight (widget)
	GtkWidget *widget

####  void gtk_drag_dest_set (GtkWidget *widget, GtkDestDefaults flags, const GtkTargetEntry *targets, gint n_targets, GdkDragAction actions) 
=for apidoc
=for arg ... of Gtk2::TargetEntry's
=cut
void
gtk_drag_dest_set (widget, flags, actions, ...)
	GtkWidget *widget
	GtkDestDefaults flags
	GdkDragAction actions
    PREINIT:
	GtkTargetEntry * targets = NULL;
	gint n_targets, i;
    CODE:
#define FIRST_TARGET 3
	n_targets = items - FIRST_TARGET;
	targets = g_new (GtkTargetEntry, n_targets);
	for (i = 0 ; i < n_targets ; i++)
		gtk2perl_read_gtk_target_entry (ST (i+FIRST_TARGET), targets+i);
	gtk_drag_dest_set (widget, flags, targets, n_targets, actions);
#undef FIRST_TARGET
    CLEANUP:
	g_free (targets);

##  void gtk_drag_dest_set_proxy (GtkWidget *widget, GdkWindow *proxy_window, GdkDragProtocol protocol, gboolean use_coordinates) 
void
gtk_drag_dest_set_proxy (widget, proxy_window, protocol, use_coordinates)
	GtkWidget *widget
	GdkWindow *proxy_window
	GdkDragProtocol protocol
	gboolean use_coordinates

##  void gtk_drag_dest_unset (GtkWidget *widget) 
void
gtk_drag_dest_unset (widget)
	GtkWidget *widget

##  GdkAtom gtk_drag_dest_find_target (GtkWidget *widget, GdkDragContext *context, GtkTargetList *target_list) 
GdkAtom
gtk_drag_dest_find_target (widget, context, target_list)
	GtkWidget *widget
	GdkDragContext *context
	GtkTargetList_ornull *target_list

##  GtkTargetList* gtk_drag_dest_get_target_list (GtkWidget *widget) 
GtkTargetList_ornull*
gtk_drag_dest_get_target_list (widget)
	GtkWidget *widget

##  void gtk_drag_dest_set_target_list (GtkWidget *widget, GtkTargetList *target_list) 
void
gtk_drag_dest_set_target_list (widget, target_list)
	GtkWidget *widget
	GtkTargetList_ornull *target_list

####  void gtk_drag_source_set (GtkWidget *widget, GdkModifierType start_button_mask, const GtkTargetEntry *targets, gint n_targets, GdkDragAction actions) 
=for apidoc
=for arg ... of Gtk2::TargetEntry's
=cut
void
gtk_drag_source_set (widget, start_button_mask, actions, ...)
	GtkWidget *widget
	GdkModifierType start_button_mask
	GdkDragAction actions
    PREINIT:
	GtkTargetEntry * targets = NULL;
	gint n_targets, i;
    CODE:
#define FIRST_TARGET 3
	n_targets = items - FIRST_TARGET;
	targets = g_new (GtkTargetEntry, n_targets);
	for (i = 0 ; i < n_targets ; i++)
		gtk2perl_read_gtk_target_entry (ST (i+FIRST_TARGET), targets+i);
	gtk_drag_source_set (widget, start_button_mask,
	                     targets, n_targets, actions);
#undef FIRST_TARGET
    CLEANUP:
	g_free (targets);

##  void gtk_drag_source_unset (GtkWidget *widget) 
void
gtk_drag_source_unset (widget)
	GtkWidget *widget

##  void gtk_drag_source_set_icon (GtkWidget *widget, GdkColormap *colormap, GdkPixmap *pixmap, GdkBitmap *mask) 
void
gtk_drag_source_set_icon (widget, colormap, pixmap, mask)
	GtkWidget *widget
	GdkColormap_ornull *colormap
	GdkPixmap_ornull *pixmap
	GdkBitmap_ornull *mask

##  void gtk_drag_source_set_icon_pixbuf (GtkWidget *widget, GdkPixbuf *pixbuf) 
void
gtk_drag_source_set_icon_pixbuf (widget, pixbuf)
	GtkWidget *widget
	GdkPixbuf_ornull *pixbuf

##  void gtk_drag_source_set_icon_stock (GtkWidget *widget, const gchar *stock_id) 
void
gtk_drag_source_set_icon_stock (widget, stock_id)
	GtkWidget *widget
	const gchar *stock_id

##  gboolean gtk_drag_check_threshold (GtkWidget *widget, gint start_x, gint start_y, gint current_x, gint current_y) 
gboolean
gtk_drag_check_threshold (widget, start_x, start_y, current_x, current_y)
	GtkWidget *widget
	gint start_x
	gint start_y
	gint current_x
	gint current_y

#if GTK_CHECK_VERSION(2,4,0)

GtkTargetList_ornull *
gtk_drag_source_get_target_list (widget)
	GtkWidget *widget

void
gtk_drag_source_set_target_list (widget, target_list)
	GtkWidget *widget
	GtkTargetList_ornull *target_list

#endif

#if GTK_CHECK_VERSION(2,6,0)

void gtk_drag_dest_add_text_targets (GtkWidget *widget);

void gtk_drag_dest_add_image_targets (GtkWidget *widget);

void gtk_drag_dest_add_uri_targets (GtkWidget *widget);

void gtk_drag_source_add_text_targets (GtkWidget *widget);

void gtk_drag_source_add_image_targets (GtkWidget *widget);

void gtk_drag_source_add_uri_targets (GtkWidget *widget);

#endif

#if GTK_CHECK_VERSION(2,8,0)

void gtk_drag_source_set_icon_name (GtkWidget *widget, const gchar *icon_name);

#endif

#if GTK_CHECK_VERSION (2,10,0)

void gtk_drag_dest_set_track_motion (GtkWidget *widget, gboolean track_motion);

gboolean gtk_drag_dest_get_track_motion  (GtkWidget *widget);

#endif
