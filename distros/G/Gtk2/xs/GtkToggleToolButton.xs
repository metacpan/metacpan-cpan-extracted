/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::ToggleToolButton PACKAGE = Gtk2::ToggleToolButton PREFIX = gtk_toggle_tool_button_


GtkToolItem *gtk_toggle_tool_button_new (class);
    C_ARGS:
	/*void*/

GtkToolItem *gtk_toggle_tool_button_new_from_stock (class, const gchar *stock_id);
    C_ARGS:
	stock_id

void gtk_toggle_tool_button_set_active (GtkToggleToolButton *button, gboolean is_active);

gboolean gtk_toggle_tool_button_get_active (GtkToggleToolButton *button);

