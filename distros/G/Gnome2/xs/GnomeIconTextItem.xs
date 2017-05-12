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

MODULE = Gnome2::IconTextItem	PACKAGE = Gnome2::IconTextItem	PREFIX = gnome_icon_text_item_

##  void gnome_icon_text_item_configure (GnomeIconTextItem *iti, int x, int y, int width, const char *fontname, const char *text, gboolean is_editable, gboolean is_static) 
void
gnome_icon_text_item_configure (iti, x, y, width, fontname, text, is_editable, is_static)
	GnomeIconTextItem *iti
	int x
	int y
	int width
	const char *fontname
	const char *text
	gboolean is_editable
	gboolean is_static

##  void gnome_icon_text_item_setxy (GnomeIconTextItem *iti, int x, int y) 
void
gnome_icon_text_item_setxy (iti, x, y)
	GnomeIconTextItem *iti
	int x
	int y

##  void gnome_icon_text_item_select (GnomeIconTextItem *iti, gboolean sel) 
void
gnome_icon_text_item_select (iti, sel)
	GnomeIconTextItem *iti
	gboolean sel

##  void gnome_icon_text_item_focus (GnomeIconTextItem *iti, gboolean focused) 
void
gnome_icon_text_item_focus (iti, focused)
	GnomeIconTextItem *iti
	gboolean focused

##  const char *gnome_icon_text_item_get_text (GnomeIconTextItem *iti)
const char *
gnome_icon_text_item_get_text (iti)
	GnomeIconTextItem *iti

##  void gnome_icon_text_item_start_editing (GnomeIconTextItem *iti) 
void
gnome_icon_text_item_start_editing (iti)
	GnomeIconTextItem *iti

##  void gnome_icon_text_item_stop_editing (GnomeIconTextItem *iti, gboolean accept) 
void
gnome_icon_text_item_stop_editing (iti, accept)
	GnomeIconTextItem *iti
	gboolean accept

##  GtkEditable *gnome_icon_text_item_get_editable (GnomeIconTextItem *iti) 
GtkEditable *
gnome_icon_text_item_get_editable (iti)
	GnomeIconTextItem *iti
