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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Wnck/xs/WnckWindow.xs,v 1.19 2007/08/02 20:15:43 kaffeetisch Exp $
 */

#include "wnck2perl.h"

MODULE = Gnome2::Wnck::Window	PACKAGE = Gnome2::Wnck::Window	PREFIX = wnck_window_

##  WnckWindow* wnck_window_get (gulong xwindow)
WnckWindow*
wnck_window_get (class, xwindow)
	gulong xwindow
    C_ARGS:
	xwindow

##  WnckScreen* wnck_window_get_screen (WnckWindow *window)
WnckScreen*
wnck_window_get_screen (window)
	WnckWindow *window

##  const char* wnck_window_get_name (WnckWindow *window)
const char*
wnck_window_get_name (window)
	WnckWindow *window

##  const char* wnck_window_get_icon_name (WnckWindow *window)
const char*
wnck_window_get_icon_name (window)
	WnckWindow *window

##  WnckApplication* wnck_window_get_application (WnckWindow *window)
WnckApplication*
wnck_window_get_application (window)
	WnckWindow *window

##  gulong wnck_window_get_group_leader (WnckWindow *window)
gulong
wnck_window_get_group_leader (window)
	WnckWindow *window

##  gulong wnck_window_get_xid (WnckWindow *window)
gulong
wnck_window_get_xid (window)
	WnckWindow *window

##  const char* wnck_window_get_session_id (WnckWindow *window)
const char*
wnck_window_get_session_id (window)
	WnckWindow *window

##  const char* wnck_window_get_session_id_utf8 (WnckWindow *window)
const char*
wnck_window_get_session_id_utf8 (window)
	WnckWindow *window

##  int wnck_window_get_pid (WnckWindow *window)
int
wnck_window_get_pid (window)
	WnckWindow *window

##  gboolean wnck_window_is_minimized (WnckWindow *window)
gboolean
wnck_window_is_minimized (window)
	WnckWindow *window

##  gboolean wnck_window_is_maximized_horizontally (WnckWindow *window)
gboolean
wnck_window_is_maximized_horizontally (window)
	WnckWindow *window

##  gboolean wnck_window_is_maximized_vertically (WnckWindow *window)
gboolean
wnck_window_is_maximized_vertically (window)
	WnckWindow *window

##  gboolean wnck_window_is_maximized (WnckWindow *window)
gboolean
wnck_window_is_maximized (window)
	WnckWindow *window

##  gboolean wnck_window_is_shaded (WnckWindow *window)
gboolean
wnck_window_is_shaded (window)
	WnckWindow *window

##  gboolean wnck_window_is_skip_pager (WnckWindow *window)
gboolean
wnck_window_is_skip_pager (window)
	WnckWindow *window

##  gboolean wnck_window_is_skip_tasklist (WnckWindow *window)
gboolean
wnck_window_is_skip_tasklist (window)
	WnckWindow *window

##  gboolean wnck_window_is_sticky (WnckWindow *window)
gboolean
wnck_window_is_sticky (window)
	WnckWindow *window

##  void wnck_window_set_skip_pager (WnckWindow *window, gboolean skip)
void
wnck_window_set_skip_pager (window, skip)
	WnckWindow *window
	gboolean skip

##  void wnck_window_set_skip_tasklist (WnckWindow *window, gboolean skip)
void
wnck_window_set_skip_tasklist (window, skip)
	WnckWindow *window
	gboolean skip

##  void wnck_window_close (WnckWindow *window, guint32 timestamp)
void
wnck_window_close (window, timestamp)
	WnckWindow *window
	guint32 timestamp

##  void wnck_window_minimize (WnckWindow *window)
void
wnck_window_minimize (window)
	WnckWindow *window

##  void wnck_window_unminimize (WnckWindow *window, guint32 timestamp)
void
wnck_window_unminimize (window, timestamp)
	WnckWindow *window
	guint32 timestamp

##  void wnck_window_maximize (WnckWindow *window)
void
wnck_window_maximize (window)
	WnckWindow *window

##  void wnck_window_unmaximize (WnckWindow *window)
void
wnck_window_unmaximize (window)
	WnckWindow *window

##  void wnck_window_maximize_horizontally (WnckWindow *window)
void
wnck_window_maximize_horizontally (window)
	WnckWindow *window

##  void wnck_window_unmaximize_horizontally (WnckWindow *window)
void
wnck_window_unmaximize_horizontally (window)
	WnckWindow *window

##  void wnck_window_maximize_vertically (WnckWindow *window)
void
wnck_window_maximize_vertically (window)
	WnckWindow *window

##  void wnck_window_unmaximize_vertically (WnckWindow *window)
void
wnck_window_unmaximize_vertically (window)
	WnckWindow *window

##  void wnck_window_shade (WnckWindow *window)
void
wnck_window_shade (window)
	WnckWindow *window

##  void wnck_window_unshade (WnckWindow *window)
void
wnck_window_unshade (window)
	WnckWindow *window

##  void wnck_window_stick (WnckWindow *window)
void
wnck_window_stick (window)
	WnckWindow *window

##  void wnck_window_unstick (WnckWindow *window)
void
wnck_window_unstick (window)
	WnckWindow *window

##  void wnck_window_keyboard_move (WnckWindow *window)
void
wnck_window_keyboard_move (window)
	WnckWindow *window

##  void wnck_window_keyboard_size (WnckWindow *window)
void
wnck_window_keyboard_size (window)
	WnckWindow *window

##  WnckWorkspace* wnck_window_get_workspace (WnckWindow *window)
WnckWorkspace*
wnck_window_get_workspace (window)
	WnckWindow *window

##  void wnck_window_move_to_workspace (WnckWindow *window, WnckWorkspace *space)
void
wnck_window_move_to_workspace (window, space)
	WnckWindow *window
	WnckWorkspace *space

##  gboolean wnck_window_is_pinned (WnckWindow *window)
gboolean
wnck_window_is_pinned (window)
	WnckWindow *window

##  void wnck_window_pin (WnckWindow *window)
void
wnck_window_pin (window)
	WnckWindow *window

##  void wnck_window_unpin (WnckWindow *window)
void
wnck_window_unpin (window)
	WnckWindow *window

##  void wnck_window_activate (WnckWindow *window, guint32 timestamp)
void
wnck_window_activate (window, timestamp)
	WnckWindow *window
	guint32 timestamp

##  gboolean wnck_window_is_active (WnckWindow *window)
gboolean
wnck_window_is_active (window)
	WnckWindow *window

##  void wnck_window_activate_transient (WnckWindow *window, guint32 timestamp)
void
wnck_window_activate_transient (window, timestamp)
	WnckWindow *window
	guint32 timestamp

##  GdkPixbuf* wnck_window_get_icon (WnckWindow *window)
GdkPixbuf*
wnck_window_get_icon (window)
	WnckWindow *window

##  GdkPixbuf* wnck_window_get_mini_icon (WnckWindow *window)
GdkPixbuf*
wnck_window_get_mini_icon (window)
	WnckWindow *window

##  gboolean wnck_window_get_icon_is_fallback (WnckWindow *window)
gboolean
wnck_window_get_icon_is_fallback (window)
	WnckWindow *window

##  void wnck_window_set_icon_geometry (WnckWindow *window, int x, int y, int width, int height)
void
wnck_window_set_icon_geometry (window, x, y, width, height)
	WnckWindow *window
	int x
	int y
	int width
	int height

##  WnckWindowActions wnck_window_get_actions (WnckWindow *window)
WnckWindowActions
wnck_window_get_actions (window)
	WnckWindow *window

##  WnckWindowState wnck_window_get_state (WnckWindow *window)
WnckWindowState
wnck_window_get_state (window)
	WnckWindow *window

##  void wnck_window_get_geometry (WnckWindow *window, int *xp, int *yp, int *widthp, int *heightp)
void
wnck_window_get_geometry (WnckWindow *window, OUTLIST int xp, OUTLIST int yp, OUTLIST int widthp, OUTLIST int heightp)

void wnck_window_set_geometry (WnckWindow *window, WnckWindowGravity gravity, WnckWindowMoveResizeMask geometry_mask, int x, int y, int width, int height);

##  gboolean wnck_window_is_visible_on_workspace (WnckWindow *window, WnckWorkspace *workspace)
gboolean
wnck_window_is_visible_on_workspace (window, workspace)
	WnckWindow *window
	WnckWorkspace *workspace

##  gboolean wnck_window_is_on_workspace (WnckWindow *window, WnckWorkspace *workspace)
gboolean
wnck_window_is_on_workspace (window, workspace)
	WnckWindow *window
	WnckWorkspace *workspace

##  gboolean wnck_window_is_in_viewport (WnckWindow *window, WnckWorkspace *workspace)
gboolean
wnck_window_is_in_viewport (window, workspace)
	WnckWindow *window
	WnckWorkspace *workspace

##  WnckClassGroup *wnck_window_get_class_group (WnckWindow *window)
WnckClassGroup *
wnck_window_get_class_group (window)
	WnckWindow *window

##  WnckWindowType wnck_window_get_window_type (WnckWindow *window)
WnckWindowType
wnck_window_get_window_type (window)
	WnckWindow *window

##  gboolean wnck_window_is_fullscreen (WnckWindow *window)
gboolean
wnck_window_is_fullscreen (window)
	WnckWindow *window

##  void wnck_window_set_fullscreen (WnckWindow *window, gboolean fullscreen)
void
wnck_window_set_fullscreen (window, fullscreen)
	WnckWindow *window
	gboolean fullscreen

##  gboolean wnck_window_is_most_recently_activated (WnckWindow *window)
gboolean
wnck_window_is_most_recently_activated (window)
	WnckWindow *window

##  gint wnck_window_get_sort_order (WnckWindow *window)
gint
wnck_window_get_sort_order (window)
	WnckWindow *window

## gboolean wnck_window_needs_attention (WnckWindow *window);
gboolean
wnck_window_needs_attention (window)
	WnckWindow *window

##  gboolean wnck_window_or_transient_needs_attention (WnckWindow *window)
gboolean
wnck_window_or_transient_needs_attention (window)
	WnckWindow *window

##  gboolean wnck_window_transient_is_most_recently_activated (WnckWindow *window)
gboolean
wnck_window_transient_is_most_recently_activated (window)
	WnckWindow *window

##  WnckWindow * wnck_window_get_transient (WnckWindow *window)
WnckWindow *
wnck_window_get_transient (window)
	WnckWindow *window

##  void wnck_window_set_window_type (WnckWindow *window, WnckWindowType wintype)
void
wnck_window_set_window_type (window, wintype)
	WnckWindow *window
	WnckWindowType wintype

gboolean wnck_window_is_above (WnckWindow *window);

void wnck_window_make_above (WnckWindow *window);

void wnck_window_unmake_above (WnckWindow *window);

void wnck_window_get_client_window_geometry (WnckWindow *window, OUTLIST int x, OUTLIST int y, OUTLIST int width, OUTLIST int height);

void wnck_window_set_sort_order (WnckWindow *window, gint order);

gboolean wnck_window_is_below (WnckWindow *window);

void wnck_window_make_below (WnckWindow *window);

void wnck_window_unmake_below (WnckWindow *window);

MODULE = Gnome2::Wnck::Window	PACKAGE = Gnome2::Wnck::Window	PREFIX = wnck_

##  GtkWidget* wnck_create_window_action_menu (WnckWindow *window)
GtkWidget*
wnck_create_window_action_menu (window)
	WnckWindow *window
    ALIAS:
	create_action_menu = 0
    CLEANUP:
	PERL_UNUSED_VAR (ix);
