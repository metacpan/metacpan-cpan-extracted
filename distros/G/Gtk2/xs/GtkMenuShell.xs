/*
 * Copyright (c) 2003-2005 by the gtk2-perl team (see the file AUTHORS)
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

MODULE = Gtk2::MenuShell	PACKAGE = Gtk2::MenuShell	PREFIX = gtk_menu_shell_

## void gtk_menu_shell_append (GtkMenuShell *menu_shell, GtkWidget *child)
void
gtk_menu_shell_append (menu_shell, child)
	GtkMenuShell * menu_shell
	GtkWidget    * child

## void gtk_menu_shell_prepend (GtkMenuShell *menu_shell, GtkWidget *child)
void
gtk_menu_shell_prepend (menu_shell, child)
	GtkMenuShell * menu_shell
	GtkWidget    * child

## void gtk_menu_shell_insert (GtkMenuShell *menu_shell, GtkWidget *child, gint position)
void
gtk_menu_shell_insert (menu_shell, child, position)
	GtkMenuShell * menu_shell
	GtkWidget    * child
	gint           position

## void gtk_menu_shell_deactivate (GtkMenuShell *menu_shell)
void
gtk_menu_shell_deactivate (menu_shell)
	GtkMenuShell * menu_shell

## void gtk_menu_shell_select_item (GtkMenuShell *menu_shell, GtkWidget *menu_item)
void
gtk_menu_shell_select_item (menu_shell, menu_item)
	GtkMenuShell * menu_shell
	GtkWidget    * menu_item

## void gtk_menu_shell_deselect (GtkMenuShell *menu_shell)
void
gtk_menu_shell_deselect (menu_shell)
	GtkMenuShell * menu_shell

## void gtk_menu_shell_activate_item (GtkMenuShell *menu_shell, GtkWidget *menu_item, gboolean force_deactivate)
void
gtk_menu_shell_activate_item (menu_shell, menu_item, force_deactivate)
	GtkMenuShell * menu_shell
	GtkWidget    * menu_item
	gboolean       force_deactivate

#if GTK_CHECK_VERSION(2, 2, 0)

void gtk_menu_shell_select_first (GtkMenuShell *menu_shell, gboolean search_sensitive)

#endif /* >= 2.2.0 */

#if GTK_CHECK_VERSION(2, 4, 0)

void gtk_menu_shell_cancel (GtkMenuShell *menu_shell);

#endif

#if GTK_CHECK_VERSION (2, 8, 0)

gboolean gtk_menu_shell_get_take_focus (GtkMenuShell *menu_shell);

void gtk_menu_shell_set_take_focus (GtkMenuShell *menu_shell, gboolean take_focus);

#endif

# __PRIVATE__
## void _gtk_menu_shell_select_first (GtkMenuShell *menu_shell, gboolean search_sensitive)
## void _gtk_menu_shell_select_last (GtkMenuShell *menu_shell, gboolean search_sensitive)
## void _gtk_menu_shell_activate (GtkMenuShell *menu_shell)
## gint _gtk_menu_shell_get_popup_delay (GtkMenuShell *menu_shell)
