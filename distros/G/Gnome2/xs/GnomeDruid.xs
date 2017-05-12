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

MODULE = Gnome2::Druid	PACKAGE = Gnome2::Druid	PREFIX = gnome_druid_

GtkWidget *
help (druid)
	GnomeDruid * druid
    ALIAS:
	Gnome2::Druid::back = 1
	Gnome2::Druid::next = 2
	Gnome2::Druid::cancel = 3
	Gnome2::Druid::finish = 4
    CODE:
	switch (ix) {
		case 0: RETVAL = druid->help; break;
		case 1: RETVAL = druid->back; break;
		case 2: RETVAL = druid->next; break;
		case 3: RETVAL = druid->cancel; break;
		case 4: RETVAL = druid->finish; break;
		default: RETVAL = NULL;
	}
    OUTPUT:
	RETVAL


GtkWidget *
gnome_druid_new (class)
    C_ARGS:
	/* void */

## void gnome_druid_set_buttons_sensitive (GnomeDruid *druid, gboolean back_sensitive, gboolean next_sensitive, gboolean cancel_sensitive, gboolean help_sensitive) 
void
gnome_druid_set_buttons_sensitive (druid, back_sensitive, next_sensitive, cancel_sensitive, help_sensitive)
	GnomeDruid *druid
	gboolean back_sensitive
	gboolean next_sensitive
	gboolean cancel_sensitive
	gboolean help_sensitive

## void gnome_druid_set_show_finish (GnomeDruid *druid, gboolean show_finish) 
void
gnome_druid_set_show_finish (druid, show_finish)
	GnomeDruid *druid
	gboolean show_finish

## void gnome_druid_set_show_help (GnomeDruid *druid, gboolean show_help) 
void
gnome_druid_set_show_help (druid, show_help)
	GnomeDruid *druid
	gboolean show_help

## void gnome_druid_prepend_page (GnomeDruid *druid, GnomeDruidPage *page) 
void
gnome_druid_prepend_page (druid, page)
	GnomeDruid *druid
	GnomeDruidPage *page

## void gnome_druid_insert_page (GnomeDruid *druid, GnomeDruidPage *back_page, GnomeDruidPage *page) 
void
gnome_druid_insert_page (druid, back_page, page)
	GnomeDruid *druid
	GnomeDruidPage_ornull *back_page
	GnomeDruidPage *page

## void gnome_druid_append_page (GnomeDruid *druid, GnomeDruidPage *page) 
void
gnome_druid_append_page (druid, page)
	GnomeDruid *druid
	GnomeDruidPage *page

## void gnome_druid_set_page (GnomeDruid *druid, GnomeDruidPage *page) 
void
gnome_druid_set_page (druid, page)
	GnomeDruid *druid
	GnomeDruidPage *page

=for apidoc

Returns a GnomeDruid and a GtkWindow.

=cut
## GtkWidget * gnome_druid_new_with_window (const char *title, GtkWindow *parent, gboolean close_on_cancel, GtkWidget **window);
void
gnome_druid_new_with_window (class, title, parent, close_on_cancel)
	const char * title
	GtkWindow_ornull * parent
	gboolean close_on_cancel
    PREINIT:
	GtkWidget * window;
	GtkWidget * druid;
    PPCODE:
	druid = gnome_druid_new_with_window (title, parent, 
	                                     close_on_cancel, &window);
	XPUSHs (sv_2mortal (newSVGnomeDruid (druid)));
	XPUSHs (sv_2mortal (newSVGtkWindow (window)));

