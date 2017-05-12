/*
 * Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS)
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the LICENSE file in the top level of this distribution
 * for the complete license terms.
 *
 */

#include "gnome2perl.h"

/* gnome-popup-menu.h was deprecated in 2003. */
#undef GNOME_DISABLE_DEPRECATED

extern void gtk2perl_menu_position_func (GtkMenu       * menu,
                                         gint          * x,
                                         gint          * y,
                                         gboolean      * push_in,
                                         GPerlCallback * callback);

MODULE = Gnome2::PopupMenu	PACKAGE = Gnome2::PopupMenu	PREFIX = gnome_popup_menu_

##  GtkWidget *gnome_popup_menu_new (GnomeUIInfo *uiinfo) 
##  GtkWidget *gnome_popup_menu_new_with_accelgroup (GnomeUIInfo *uiinfo, GtkAccelGroup *accelgroup) 
GtkWidget *
gnome_popup_menu_new (class, uiinfo, accelgroup=NULL)
	GnomeUIInfo *uiinfo
	GtkAccelGroup *accelgroup
    ALIAS:
	new_with_accelgroup = 1
    CODE:
	if (ix == 1 || accelgroup != NULL)
		RETVAL = gnome_popup_menu_new_with_accelgroup (uiinfo,
		                                               accelgroup);
	else
		RETVAL = gnome_popup_menu_new (uiinfo);

	gnome2perl_refill_infos_popup (ST (1), uiinfo);
    OUTPUT:
	RETVAL

MODULE = Gnome2::PopupMenu	PACKAGE = Gtk2::Menu	PREFIX = gnome_popup_menu_

=for object Gnome2::PopupMenu
=cut

## same as gtk_menu_get_accel_group
##  GtkAccelGroup *gnome_popup_menu_get_accel_group(GtkMenu *menu) 

##  void gnome_popup_menu_attach (GtkWidget *popup, GtkWidget *widget, gpointer user_data) 
void
gnome_popup_menu_attach_to (popup, widget, user_data=NULL)
	GtkWidget *popup
	GtkWidget *widget
	SV * user_data
    CODE:
	gnome_popup_menu_attach (popup, widget, user_data);

####  void gnome_popup_menu_do_popup (GtkWidget *popup, GtkMenuPositionFunc pos_func, gpointer pos_data, GdkEventButton *event, gpointer user_data, GtkWidget *for_widget) 
void
gnome_popup_menu_do_popup (popup, pos_func, pos_data, event, user_data, for_widget)
	GtkMenu * popup
	SV * pos_func
	SV * pos_data
	GdkEvent * event
	SV * user_data
	GtkWidget * for_widget
    CODE:
	if (SvTRUE (pos_func)) {
		GPerlCallback * callback;
		/* we don't need to worry about the callback arg types since
		 * we already have to marshall this callback ourselves. */
		callback = gperl_callback_new (pos_func, pos_data, 0, NULL, 0);
		gnome_popup_menu_do_popup (GTK_WIDGET (popup),
		                           (GtkMenuPositionFunc)
		                                 gtk2perl_menu_position_func,
		                           callback, (GdkEventButton*) event,
		                           user_data, for_widget);
		/* NOTE: this isn't a proper destructor, as it could leak
		 *    if replaced somewhere else.  on the other hand, how
		 *    likely is that? */
		g_object_set_data_full (G_OBJECT (popup), "_menu_pos_callback",
		                        callback,
		                        (GDestroyNotify)
		                             gperl_callback_destroy);
	} else
		gnome_popup_menu_do_popup (GTK_WIDGET (popup), NULL, NULL,
		                           (GdkEventButton*) event,
		                           user_data, for_widget);


####  int gnome_popup_menu_do_popup_modal (GtkWidget *popup, GtkMenuPositionFunc pos_func, gpointer pos_data, GdkEventButton *event, gpointer user_data, GtkWidget *for_widget) 
int
gnome_popup_menu_do_popup_modal (popup, pos_func, pos_data, event, user_data, for_widget)
	GtkMenu * popup
	SV * pos_func
	SV * pos_data
	GdkEvent * event
	SV * user_data
	GtkWidget * for_widget
    CODE:
	if (SvTRUE (pos_func)) {
		GPerlCallback * callback;
		/* we don't need to worry about the callback arg types since
		 * we already have to marshall this callback ourselves. */
		callback = gperl_callback_new (pos_func, pos_data, 0, NULL, 0);
		RETVAL = gnome_popup_menu_do_popup_modal (GTK_WIDGET (popup),
		                      (GtkMenuPositionFunc)
		                            gtk2perl_menu_position_func,
		                      callback, (GdkEventButton *) event,
		                      user_data, for_widget);
		gperl_callback_destroy (callback);
	} else
		RETVAL = gnome_popup_menu_do_popup_modal
		                        (GTK_WIDGET (popup), NULL, NULL,
		                        (GdkEventButton*) event, user_data,
		                        for_widget);
    OUTPUT:
	RETVAL

##  void gnome_popup_menu_append (GtkWidget *popup, GnomeUIInfo *uiinfo) 
void
gnome_popup_menu_append_from (popup, uiinfo)
	GtkWidget *popup
	GnomeUIInfo *uiinfo
    CODE:
	gnome_popup_menu_append (popup, uiinfo);
	gnome2perl_refill_infos_popup (ST (1), uiinfo);

MODULE = Gnome2::PopupMenu	PACKAGE = Gtk2::Widget	PREFIX = gnome_gtk_widget_

=for object Gnome2::PopupMenu
=cut

##  void gnome_gtk_widget_add_popup_items (GtkWidget *widget, GnomeUIInfo *uiinfo, gpointer user_data) 
void
gnome_gtk_widget_add_popup_items (widget, uiinfo, user_data=NULL)
	GtkWidget *widget
	GnomeUIInfo *uiinfo
	SV * user_data
    CODE:
	gnome_gtk_widget_add_popup_items (widget, uiinfo, user_data);
	gnome2perl_refill_infos_popup (ST (1), uiinfo);
