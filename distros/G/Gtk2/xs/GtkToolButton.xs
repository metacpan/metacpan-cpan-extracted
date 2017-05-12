/*
 * Copyright (c) 2003-2005 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::ToolButton PACKAGE = Gtk2::ToolButton PREFIX = gtk_tool_button_

GtkToolItem *gtk_tool_button_new (class, GtkWidget_ornull *icon_widget, const gchar_ornull *label);
    C_ARGS:
	icon_widget, label

GtkToolItem *gtk_tool_button_new_from_stock (class, const gchar *stock_id);
    C_ARGS:
	stock_id


void gtk_tool_button_set_label (GtkToolButton *button, const gchar_ornull *label);

 ##G_CONST_RETURN
const gchar_ornull *gtk_tool_button_get_label (GtkToolButton *button);

void gtk_tool_button_set_use_underline (GtkToolButton *button, gboolean use_underline);

gboolean gtk_tool_button_get_use_underline (GtkToolButton *button);

void gtk_tool_button_set_stock_id (GtkToolButton *button, const gchar_ornull *stock_id);

 ##G_CONST_RETURN 
const gchar *gtk_tool_button_get_stock_id (GtkToolButton *button);

void gtk_tool_button_set_icon_widget (GtkToolButton *button, GtkWidget_ornull *icon_widget);

GtkWidget_ornull * gtk_tool_button_get_icon_widget (GtkToolButton *button);

void gtk_tool_button_set_label_widget (GtkToolButton *button, GtkWidget_ornull *label_widget);

GtkWidget_ornull * gtk_tool_button_get_label_widget (GtkToolButton *button);

#if GTK_CHECK_VERSION (2, 8, 0)

void gtk_tool_button_set_icon_name (GtkToolButton *button, const gchar_ornull *icon_name);

const gchar_ornull* gtk_tool_button_get_icon_name (GtkToolButton *button);

#endif
