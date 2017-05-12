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

MODULE = Gnome2::Bonobo::DockItem	PACKAGE = Gnome2::Bonobo::DockItem	PREFIX = bonobo_dock_item_

##  GtkWidget *bonobo_dock_item_new (const gchar *name, BonoboDockItemBehavior behavior) 
GtkWidget *
bonobo_dock_item_new (class, name, behavior)
	const gchar *name
	BonoboDockItemBehavior behavior
    C_ARGS:
	name, behavior

##  GtkWidget *bonobo_dock_item_get_child (BonoboDockItem *dock_item) 
GtkWidget *
bonobo_dock_item_get_child (dock_item)
	BonoboDockItem *dock_item

##  char *bonobo_dock_item_get_name (BonoboDockItem *dock_item) 
char *
bonobo_dock_item_get_name (dock_item)
	BonoboDockItem *dock_item

##  void bonobo_dock_item_set_shadow_type (BonoboDockItem *dock_item, GtkShadowType type) 
void
bonobo_dock_item_set_shadow_type (dock_item, type)
	BonoboDockItem *dock_item
	GtkShadowType type

##  GtkShadowType bonobo_dock_item_get_shadow_type (BonoboDockItem *dock_item) 
GtkShadowType
bonobo_dock_item_get_shadow_type (dock_item)
	BonoboDockItem *dock_item

##  gboolean bonobo_dock_item_set_orientation (BonoboDockItem *dock_item, GtkOrientation orientation) 
gboolean
bonobo_dock_item_set_orientation (dock_item, orientation)
	BonoboDockItem *dock_item
	GtkOrientation orientation

##  GtkOrientation bonobo_dock_item_get_orientation (BonoboDockItem *dock_item) 
GtkOrientation
bonobo_dock_item_get_orientation (dock_item)
	BonoboDockItem *dock_item

##  BonoboDockItemBehavior bonobo_dock_item_get_behavior (BonoboDockItem *dock_item) 
BonoboDockItemBehavior
bonobo_dock_item_get_behavior (dock_item)
	BonoboDockItem *dock_item
