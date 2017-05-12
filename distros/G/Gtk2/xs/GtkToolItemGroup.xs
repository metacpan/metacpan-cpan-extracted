/*
 * Copyright (c) 2010 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::ToolItemGroup	PACKAGE = Gtk2::ToolItemGroup	PREFIX = gtk_tool_item_group_

GtkWidget *
gtk_tool_item_group_new (class, const gchar *label)
    C_ARGS:
	label

gboolean gtk_tool_item_group_get_collapsed (GtkToolItemGroup *group);

GtkToolItem* gtk_tool_item_group_get_drop_item (GtkToolItemGroup *group, gint x, gint y);

PangoEllipsizeMode gtk_tool_item_group_get_ellipsize (GtkToolItemGroup *group);

gint gtk_tool_item_group_get_item_position (GtkToolItemGroup *group, GtkToolItem *item);

guint gtk_tool_item_group_get_n_items (GtkToolItemGroup *group);

const gchar* gtk_tool_item_group_get_label (GtkToolItemGroup *group);

GtkWidget * gtk_tool_item_group_get_label_widget (GtkToolItemGroup *group);

GtkToolItem* gtk_tool_item_group_get_nth_item (GtkToolItemGroup *group, guint index);

GtkReliefStyle gtk_tool_item_group_get_header_relief (GtkToolItemGroup *group);

void gtk_tool_item_group_insert (GtkToolItemGroup *group, GtkToolItem *item, gint position);

void gtk_tool_item_group_set_collapsed (GtkToolItemGroup *group, gboolean collapsed);

void gtk_tool_item_group_set_ellipsize (GtkToolItemGroup *group, PangoEllipsizeMode ellipsize);

void gtk_tool_item_group_set_item_position (GtkToolItemGroup *group, GtkToolItem *item, gint position);

void gtk_tool_item_group_set_label (GtkToolItemGroup *group, const gchar *label);

void gtk_tool_item_group_set_label_widget (GtkToolItemGroup *group, GtkWidget *label_widget);

void gtk_tool_item_group_set_header_relief (GtkToolItemGroup *group, GtkReliefStyle style);
