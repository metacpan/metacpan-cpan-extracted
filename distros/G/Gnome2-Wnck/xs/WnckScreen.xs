/*
 * Copyright (C) 2003-2004 by the gtk2-perl team
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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Wnck/xs/WnckScreen.xs,v 1.11 2007/08/02 20:15:43 kaffeetisch Exp $
 */

#include "wnck2perl.h"

MODULE = Gnome2::Wnck::Screen	PACKAGE = Gnome2::Wnck::Screen	PREFIX = wnck_screen_

##  WnckScreen* wnck_screen_get_default (void)
WnckScreen*
wnck_screen_get_default (class)
    C_ARGS:
	/* void */

##  WnckScreen* wnck_screen_get (int index)
WnckScreen*
wnck_screen_get (class, index)
	int index
    C_ARGS:
	index

##  WnckScreen* wnck_screen_get_for_root (gulong root_window_id)
WnckScreen*
wnck_screen_get_for_root (class, root_window_id)
	gulong root_window_id
    C_ARGS:
	root_window_id

##  WnckWorkspace* wnck_screen_get_workspace (WnckScreen *screen, int workspace)
WnckWorkspace*
wnck_screen_get_workspace (screen, workspace)
	WnckScreen *screen
	int workspace

##  WnckWorkspace* wnck_screen_get_active_workspace (WnckScreen *screen)
WnckWorkspace*
wnck_screen_get_active_workspace (screen)
	WnckScreen *screen

##  WnckWindow* wnck_screen_get_active_window (WnckScreen *screen)
WnckWindow*
wnck_screen_get_active_window (screen)
	WnckScreen *screen

##  WnckWindow * wnck_screen_get_previously_active_window (WnckScreen *screen)
WnckWindow *
wnck_screen_get_previously_active_window (screen)
	WnckScreen *screen

=for apidoc

Returns a list of WnckWindow's.

=cut
##  GList* wnck_screen_get_windows (WnckScreen *screen)
void
wnck_screen_get_windows (screen)
	WnckScreen *screen
    PREINIT:
	GList *i, *list = NULL;
    PPCODE:
	list = wnck_screen_get_windows (screen);
	for (i = list; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVWnckWindow (i->data)));

=for apidoc

Returns a list of WnckWindow's.

=cut
##  GList* wnck_screen_get_windows_stacked (WnckScreen *screen)
void
wnck_screen_get_windows_stacked (screen)
	WnckScreen *screen
    PREINIT:
	GList *i, *list = NULL;
    PPCODE:
	list = wnck_screen_get_windows_stacked (screen);
	for (i = list; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVWnckWindow (i->data)));

##  void wnck_screen_force_update (WnckScreen *screen)
void
wnck_screen_force_update (screen)
	WnckScreen *screen

##  int wnck_screen_get_workspace_count (WnckScreen *screen)
int
wnck_screen_get_workspace_count (screen)
	WnckScreen *screen

##  void wnck_screen_change_workspace_count (WnckScreen *screen, int count)
void
wnck_screen_change_workspace_count (screen, count)
	WnckScreen *screen
	int count

##  gboolean wnck_screen_net_wm_supports (WnckScreen *screen, const char *atom)
gboolean
wnck_screen_net_wm_supports (screen, atom)
	WnckScreen *screen
	const char *atom

##  gulong wnck_screen_get_background_pixmap (WnckScreen *screen)
gulong
wnck_screen_get_background_pixmap (screen)
	WnckScreen *screen

##  int wnck_screen_get_width (WnckScreen *screen)
int
wnck_screen_get_width (screen)
	WnckScreen *screen

##  int wnck_screen_get_height (WnckScreen *screen)
int
wnck_screen_get_height (screen)
	WnckScreen *screen

##  gboolean wnck_screen_get_showing_desktop (WnckScreen *screen)
gboolean
wnck_screen_get_showing_desktop (screen)
	WnckScreen *screen

##  void wnck_screen_toggle_showing_desktop (WnckScreen *screen, gboolean show)
void
wnck_screen_toggle_showing_desktop (screen, show)
	WnckScreen *screen
	gboolean show

##  void wnck_screen_move_viewport (WnckScreen *screen, int x, int y)
void
wnck_screen_move_viewport (screen, x, y)
	WnckScreen *screen
	int x
	int y

##  int wnck_screen_try_set_workspace_layout (WnckScreen *screen, int current_token, int rows, int columns)
int
wnck_screen_try_set_workspace_layout (screen, current_token, rows, columns)
	WnckScreen *screen
	int current_token
	int rows
	int columns

##  void wnck_screen_release_workspace_layout (WnckScreen *screen, int current_token)
void
wnck_screen_release_workspace_layout (screen, current_token)
	WnckScreen *screen
	int current_token

# GList * wnck_screen_get_workspaces (WnckScreen *screen);
void
wnck_screen_get_workspaces (WnckScreen *screen)
    PREINIT:
	GList *list, *i;
    PPCODE:
	list = wnck_screen_get_workspaces (screen);
	for (i = list; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVWnckWorkspace (i->data)));

const char_ornull * wnck_screen_get_window_manager_name (WnckScreen *screen);

int wnck_screen_get_number (WnckScreen *screen);
