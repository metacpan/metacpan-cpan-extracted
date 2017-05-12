/*
 * Copyright (c) 2004 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::MenuToolButton	PACKAGE = Gtk2::MenuToolButton	PREFIX = gtk_menu_tool_button_

##  GtkToolItem * gtk_menu_tool_button_new (GtkWidget *icon_widget, const gchar *label)
GtkToolItem *
gtk_menu_tool_button_new (class, icon_widget, label)
	GtkWidget_ornull *icon_widget
	const gchar_ornull *label
    C_ARGS:
	icon_widget, label

##  GtkToolItem * gtk_menu_tool_button_new_from_stock (const gchar *stock_id)
GtkToolItem *
gtk_menu_tool_button_new_from_stock (class, stock_id)
	const gchar *stock_id
    C_ARGS:
	stock_id

void gtk_menu_tool_button_set_menu (GtkMenuToolButton *button, GtkWidget_ornull *menu);

GtkWidget_ornull * gtk_menu_tool_button_get_menu (GtkMenuToolButton *button);

void gtk_menu_tool_button_set_arrow_tooltip (GtkMenuToolButton *button, GtkTooltips *tooltips, const gchar *tip_text, const gchar *tip_private);

#if GTK_CHECK_VERSION(2, 12, 0)

void gtk_menu_tool_button_set_arrow_tooltip_text (GtkMenuToolButton *button, const gchar_ornull *text);

void gtk_menu_tool_button_set_arrow_tooltip_markup (GtkMenuToolButton *button, const gchar_ornull *markup);

#endif
