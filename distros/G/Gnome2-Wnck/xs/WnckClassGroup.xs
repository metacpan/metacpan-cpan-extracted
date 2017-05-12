/*
 * Copyright (C) 2004 by the gtk2-perl team
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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Wnck/xs/WnckClassGroup.xs,v 1.3 2007/08/02 20:15:43 kaffeetisch Exp $
 */

#include "wnck2perl.h"

MODULE = Gnome2::Wnck::ClassGroup	PACKAGE = Gnome2::Wnck::ClassGroup	PREFIX = wnck_class_group_

##  WnckClassGroup *wnck_class_group_get (const char *res_class)
WnckClassGroup *
wnck_class_group_get (class, res_class)
	const char *res_class
    C_ARGS:
	res_class

=for apidoc

Returns a list of WnckWindows.

=cut
##  GList *wnck_class_group_get_windows (WnckClassGroup *class_group)
void
wnck_class_group_get_windows (class_group)
	WnckClassGroup *class_group
    PREINIT:
	GList *i, *list;
    PPCODE:
	list = wnck_class_group_get_windows (class_group);
	for (i = list; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVWnckWindow (i->data)));

##  const char * wnck_class_group_get_res_class (WnckClassGroup *class_group)
const char *
wnck_class_group_get_res_class (class_group)
	WnckClassGroup *class_group

##  const char * wnck_class_group_get_name (WnckClassGroup *class_group)
const char *
wnck_class_group_get_name (class_group)
	WnckClassGroup *class_group

##  GdkPixbuf *wnck_class_group_get_icon (WnckClassGroup *class_group)
GdkPixbuf *
wnck_class_group_get_icon (class_group)
	WnckClassGroup *class_group

##  GdkPixbuf *wnck_class_group_get_mini_icon (WnckClassGroup *class_group)
GdkPixbuf *
wnck_class_group_get_mini_icon (class_group)
	WnckClassGroup *class_group
