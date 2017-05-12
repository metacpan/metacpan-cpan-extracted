/*
 * Copyright (c) 2010 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::ToolPalette	PACKAGE = Gtk2::ToolPalette	PREFIX = gtk_tool_palette_

GtkWidget *
gtk_tool_palette_new (class)
    C_ARGS:
	/* void */

gboolean gtk_tool_palette_get_exclusive (GtkToolPalette *palette, GtkToolItemGroup *group);

void gtk_tool_palette_set_exclusive (GtkToolPalette *palette, GtkToolItemGroup *group, gboolean exclusive);

gboolean gtk_tool_palette_get_expand (GtkToolPalette *palette, GtkToolItemGroup *group);

void gtk_tool_palette_set_expand (GtkToolPalette *palette, GtkToolItemGroup *group, gboolean expand);

gint gtk_tool_palette_get_group_position (GtkToolPalette *palette, GtkToolItemGroup *group);

void gtk_tool_palette_set_group_position (GtkToolPalette *palette, GtkToolItemGroup *group, gint position);

GtkIconSize gtk_tool_palette_get_icon_size (GtkToolPalette *palette);

void gtk_tool_palette_set_icon_size (GtkToolPalette *palette, GtkIconSize icon_size);

void gtk_tool_palette_unset_icon_size (GtkToolPalette *palette);

GtkToolbarStyle gtk_tool_palette_get_style (GtkToolPalette *palette);

void gtk_tool_palette_set_style (GtkToolPalette *palette, GtkToolbarStyle style);

void gtk_tool_palette_unset_style (GtkToolPalette *palette);

void gtk_tool_palette_add_drag_dest (GtkToolPalette *palette, GtkWidget *widget, GtkDestDefaults flags, GtkToolPaletteDragTargets targets, GdkDragAction actions);

GtkWidget* gtk_tool_palette_get_drag_item (GtkToolPalette *palette, const GtkSelectionData *selection);

# const GtkTargetEntry* gtk_tool_palette_get_drag_target_group (void)
GtkTargetEntry*
gtk_tool_palette_get_drag_target_group (class)
    CODE:
	RETVAL = (GtkTargetEntry*) gtk_tool_palette_get_drag_target_group ();
    OUTPUT:
	RETVAL

# const GtkTargetEntry* gtk_tool_palette_get_drag_target_item (void)
GtkTargetEntry*
gtk_tool_palette_get_drag_target_item (class)
    CODE:
	RETVAL = (GtkTargetEntry*) gtk_tool_palette_get_drag_target_item ();
    OUTPUT:
	RETVAL

GtkToolItemGroup_ornull* gtk_tool_palette_get_drop_group (GtkToolPalette *palette, gint x, gint y);

GtkToolItem_ornull* gtk_tool_palette_get_drop_item (GtkToolPalette *palette, gint x, gint y);

void gtk_tool_palette_set_drag_source (GtkToolPalette *palette, GtkToolPaletteDragTargets targets);

GtkAdjustment* gtk_tool_palette_get_hadjustment (GtkToolPalette *palette);

GtkAdjustment* gtk_tool_palette_get_vadjustment (GtkToolPalette *palette);
