/*
 * Copyright (c) 2003, 2011 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::ToolItem PACKAGE = Gtk2::ToolItem PREFIX = gtk_tool_item_

GtkToolItem *gtk_tool_item_new (class);
    C_ARGS:
	/*void*/

void gtk_tool_item_set_homogeneous (GtkToolItem *tool_item, gboolean homogeneous);

gboolean gtk_tool_item_get_homogeneous (GtkToolItem *tool_item);


void gtk_tool_item_set_expand (GtkToolItem *tool_item, gboolean expand);

gboolean gtk_tool_item_get_expand (GtkToolItem *tool_item);


void gtk_tool_item_set_tooltip (GtkToolItem *tool_item, GtkTooltips *tooltips, const gchar *tip_text, const gchar *tip_private);


void gtk_tool_item_set_use_drag_window (GtkToolItem *toolitem, gboolean use_drag_window);

gboolean gtk_tool_item_get_use_drag_window (GtkToolItem *toolitem);


void gtk_tool_item_set_visible_horizontal (GtkToolItem *toolitem, gboolean visible_horizontal);

gboolean gtk_tool_item_get_visible_horizontal (GtkToolItem *toolitem);


void gtk_tool_item_set_visible_vertical (GtkToolItem *toolitem, gboolean visible_vertical);

gboolean gtk_tool_item_get_visible_vertical (GtkToolItem *toolitem);


gboolean gtk_tool_item_get_is_important (GtkToolItem *tool_item);

void gtk_tool_item_set_is_important (GtkToolItem *tool_item, gboolean is_important);


GtkIconSize gtk_tool_item_get_icon_size (GtkToolItem *tool_item);

GtkOrientation gtk_tool_item_get_orientation (GtkToolItem *tool_item);

GtkToolbarStyle gtk_tool_item_get_toolbar_style (GtkToolItem *tool_item);

GtkReliefStyle gtk_tool_item_get_relief_style (GtkToolItem *tool_item);


GtkWidget * gtk_tool_item_retrieve_proxy_menu_item (GtkToolItem *tool_item);

GtkWidget * gtk_tool_item_get_proxy_menu_item (GtkToolItem *tool_item, const gchar *menu_item_id);

# Crib: menu_item can be NULL here for no menu item.
# Docs of gtk_tool_item_set_proxy_menu_item() don't say so explicitly, but the
# docs of create-menu-proxy signal invite handlers to set NULL for no menu.
void gtk_tool_item_set_proxy_menu_item (GtkToolItem *tool_item, const gchar *menu_item_id, GtkWidget_ornull *menu_item);

#if GTK_CHECK_VERSION (2, 6, 0)

void gtk_tool_item_rebuild_menu (GtkToolItem *tool_item);

#endif

#if GTK_CHECK_VERSION(2, 12, 0)

void gtk_tool_item_set_tooltip_text (GtkToolItem *tool_item, const gchar_ornull *text);

void gtk_tool_item_set_tooltip_markup (GtkToolItem *tool_item, const gchar_ornull *markup);

#endif

#if GTK_CHECK_VERSION (2, 14, 0)

void gtk_tool_item_toolbar_reconfigured (GtkToolItem *tool_item);

#endif /* 2.14 */

#if GTK_CHECK_VERSION (2, 20, 0)

PangoEllipsizeMode  gtk_tool_item_get_ellipsize_mode    (GtkToolItem *tool_item);

gfloat              gtk_tool_item_get_text_alignment    (GtkToolItem *tool_item);

GtkOrientation      gtk_tool_item_get_text_orientation  (GtkToolItem *tool_item);

# We don't own the size group.
GtkSizeGroup *      gtk_tool_item_get_text_size_group   (GtkToolItem *tool_item);

#endif /* 2.20 */
