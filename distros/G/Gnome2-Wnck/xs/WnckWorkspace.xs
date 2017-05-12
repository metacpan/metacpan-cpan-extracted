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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Wnck/xs/WnckWorkspace.xs,v 1.8 2007/08/02 20:15:43 kaffeetisch Exp $
 */

#include "wnck2perl.h"

MODULE = Gnome2::Wnck::Workspace	PACKAGE = Gnome2::Wnck::Workspace	PREFIX = wnck_workspace_

##  int wnck_workspace_get_number (WnckWorkspace *space)
int
wnck_workspace_get_number (space)
	WnckWorkspace *space

##  const char* wnck_workspace_get_name (WnckWorkspace *space)
const char*
wnck_workspace_get_name (space)
	WnckWorkspace *space

##  void wnck_workspace_change_name (WnckWorkspace *space, const char *name)
void
wnck_workspace_change_name (space, name)
	WnckWorkspace *space
	const char *name

##  void wnck_workspace_activate (WnckWorkspace *space, guint32 timestamp)
void
wnck_workspace_activate (space, timestamp)
	WnckWorkspace *space
	guint32 timestamp

##  int wnck_workspace_get_width (WnckWorkspace *space)
int
wnck_workspace_get_width (space)
	WnckWorkspace *space

##  int wnck_workspace_get_height (WnckWorkspace *space)
int
wnck_workspace_get_height (space)
	WnckWorkspace *space

##  int wnck_workspace_get_viewport_x (WnckWorkspace *space)
int
wnck_workspace_get_viewport_x (space)
	WnckWorkspace *space

##  int wnck_workspace_get_viewport_y (WnckWorkspace *space)
int
wnck_workspace_get_viewport_y (space)
	WnckWorkspace *space

##  gboolean wnck_workspace_is_virtual (WnckWorkspace *space)
gboolean
wnck_workspace_is_virtual (space)
	WnckWorkspace *space

WnckScreen* wnck_workspace_get_screen (WnckWorkspace *space);

int wnck_workspace_get_layout_row (WnckWorkspace *space);

int wnck_workspace_get_layout_column (WnckWorkspace *space);

WnckWorkspace_ornull* wnck_workspace_get_neighbor (WnckWorkspace *space, WnckMotionDirection direction);
