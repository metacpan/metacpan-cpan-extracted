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

MODULE = Gnome2::App	PACKAGE = Gnome2::App	PREFIX = gnome_app_

SV *
prefix (app)
	GnomeApp *app
    ALIAS:
	Gnome2::App::dock = 1
	Gnome2::App::statusbar = 2
	Gnome2::App::vbox = 3
	Gnome2::App::menubar = 4
	Gnome2::App::contents = 5
	Gnome2::App::layout = 6
	Gnome2::App::accel_group = 7
	Gnome2::App::get_enable_layout_config = 8
    CODE:
	switch (ix) {
		case 0: RETVAL = newSVGChar (app->prefix); break;
		case 1: RETVAL = newSVGtkWidget (app->dock); break;
		case 2: RETVAL = newSVGtkWidget (app->statusbar); break;
		case 3: RETVAL = newSVGtkWidget (app->vbox); break;
		case 4: RETVAL = newSVGtkWidget (app->menubar); break;
		case 5: RETVAL = newSVGtkWidget (app->contents); break;
		case 6: RETVAL = newSVBonoboDockLayout (app->layout); break;
		case 7: RETVAL = newSVGtkAccelGroup (app->accel_group); break;
		case 8: RETVAL = newSVuv (app->enable_layout_config); break;
		default: RETVAL = &PL_sv_undef;
	}
    OUTPUT:
	RETVAL

## Create a new (empty) application window.  You must specify the application's
## name (used internally as an identifier).  The window title can be left as
## NULL, in which case the window's title will not be set.
GtkWidget *gnome_app_new (class, appname, title=NULL)
	const gchar *appname
	const gchar *title
    C_ARGS:
	appname, title

## Sets the menu bar of the application window
void gnome_app_set_menus (GnomeApp *app, GtkMenuBar *menubar);

## Sets the main toolbar of the application window
void gnome_app_set_toolbar (GnomeApp *app, GtkToolbar *toolbar);

## Sets the status bar of the application window
void gnome_app_set_statusbar (GnomeApp *app, GtkWidget *statusbar);

## Sets the status bar of the application window, but uses the given
## container widget rather than creating a new one.
void gnome_app_set_statusbar_custom (GnomeApp *app, GtkWidget *container, GtkWidget *statusbar);

## Sets the content area of the application window 
void gnome_app_set_contents (GnomeApp *app, GtkWidget *contents);

void gnome_app_add_toolbar (GnomeApp *app, GtkToolbar *toolbar, const gchar *name, BonoboDockItemBehavior behavior, BonoboDockPlacement placement, gint band_num, gint band_position, gint offset);

GtkWidget *gnome_app_add_docked (GnomeApp *app, GtkWidget *widget, const gchar *name, BonoboDockItemBehavior behavior, BonoboDockPlacement placement, gint band_num, gint band_position, gint offset);

void gnome_app_add_dock_item (GnomeApp *app, BonoboDockItem *item, BonoboDockPlacement placement, gint band_num, gint band_position, gint offset);

void gnome_app_enable_layout_config (GnomeApp *app, gboolean enable);

BonoboDock *gnome_app_get_dock (GnomeApp *app);

BonoboDockItem *gnome_app_get_dock_item_by_name (GnomeApp *app, const gchar *name);
