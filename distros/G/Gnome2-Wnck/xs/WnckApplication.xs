/*
 * Copyright (C) 2003 by the gtk2-perl team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Wnck/xs/WnckApplication.xs,v 1.7 2007/08/02 20:15:43 kaffeetisch Exp $
 */

#include "wnck2perl.h"

MODULE = Gnome2::Wnck::Application	PACKAGE = Gnome2::Wnck::Application	PREFIX = wnck_application_

##  WnckApplication* wnck_application_get (gulong xwindow)
WnckApplication*
wnck_application_get (class, xwindow)
	gulong xwindow
    C_ARGS:
	xwindow

##  gulong wnck_application_get_xid (WnckApplication *app)
gulong
wnck_application_get_xid (app)
	WnckApplication *app

=for apidoc

Returns a list of WnckWindow's.

=cut
##  GList* wnck_application_get_windows (WnckApplication *app)
void
wnck_application_get_windows (app)
	WnckApplication *app
    PREINIT:
	GList *i, *list = NULL;
    PPCODE:
	list = wnck_application_get_windows (app);
	for (i = list; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVWnckWindow (i->data)));

##  int wnck_application_get_n_windows (WnckApplication *app)
int
wnck_application_get_n_windows (app)
	WnckApplication *app

##  const char* wnck_application_get_name (WnckApplication *app)
const char*
wnck_application_get_name (app)
	WnckApplication *app

##  const char* wnck_application_get_icon_name (WnckApplication *app)
const char*
wnck_application_get_icon_name (app)
	WnckApplication *app

##  int wnck_application_get_pid (WnckApplication *app)
int
wnck_application_get_pid (app)
	WnckApplication *app

##  GdkPixbuf* wnck_application_get_icon (WnckApplication *app)
GdkPixbuf*
wnck_application_get_icon (app)
	WnckApplication *app

##  GdkPixbuf* wnck_application_get_mini_icon (WnckApplication *app)
GdkPixbuf*
wnck_application_get_mini_icon (app)
	WnckApplication *app

##  gboolean wnck_application_get_icon_is_fallback (WnckApplication *app)
gboolean
wnck_application_get_icon_is_fallback (app)
	WnckApplication *app

##  const char* wnck_application_get_startup_id (WnckApplication *app)
const char*
wnck_application_get_startup_id (app)
	WnckApplication *app
