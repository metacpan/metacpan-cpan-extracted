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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Wnck/xs/WnckPager.xs,v 1.7 2007/08/02 20:15:43 kaffeetisch Exp $
 */

#include "wnck2perl.h"

MODULE = Gnome2::Wnck::Pager	PACKAGE = Gnome2::Wnck::Pager	PREFIX = wnck_pager_

##  GtkWidget* wnck_pager_new (WnckScreen *screen)
GtkWidget*
wnck_pager_new (class, screen)
	WnckScreen *screen
    C_ARGS:
	screen

##  void wnck_pager_set_screen (WnckPager *pager, WnckScreen *screen)
void
wnck_pager_set_screen (pager, screen)
	WnckPager *pager
	WnckScreen *screen

##  gboolean wnck_pager_set_orientation (WnckPager *pager, GtkOrientation orientation)
gboolean
wnck_pager_set_orientation (pager, orientation)
	WnckPager *pager
	GtkOrientation orientation

##  void wnck_pager_set_n_rows (WnckPager *pager, int n_rows)
void
wnck_pager_set_n_rows (pager, n_rows)
	WnckPager *pager
	int n_rows

##  void wnck_pager_set_display_mode (WnckPager *pager, WnckPagerDisplayMode mode)
void
wnck_pager_set_display_mode (pager, mode)
	WnckPager *pager
	WnckPagerDisplayMode mode

##  void wnck_pager_set_show_all (WnckPager *pager, gboolean show_all_workspaces)
void
wnck_pager_set_show_all (pager, show_all_workspaces)
	WnckPager *pager
	gboolean show_all_workspaces

##  void wnck_pager_set_shadow_type (WnckPager *pager, GtkShadowType shadow_type)
void
wnck_pager_set_shadow_type (pager, shadow_type)
	WnckPager *pager
	GtkShadowType shadow_type
