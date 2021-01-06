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
 * License along with this library; if not, see
 * <https://www.gnu.org/licenses/>.
 *
 * $Id$
 */

#include "wnck2perl.h"

MODULE = Gnome2::Wnck::Workspace	PACKAGE = Gnome2::Wnck::Workspace	PREFIX = wnck_workspace_

=for object Gnome2::Wnck::Workspace - an object representing a workspace

=cut

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
