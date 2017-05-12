/*
 * Copyright (c) 2003, 2010 by the gtk2-perl team (see the file AUTHORS)
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

MODULE = Gtk2::Viewport	PACKAGE = Gtk2::Viewport	PREFIX = gtk_viewport_

## GtkWidget* gtk_viewport_new (GtkAdjustment *hadjustment, GtkAdjustment *vadjustment)
GtkWidget *
gtk_viewport_new (class, hadjustment=NULL, vadjustment=NULL)
	GtkAdjustment_ornull * hadjustment
	GtkAdjustment_ornull * vadjustment
    C_ARGS:
	hadjustment, vadjustment

## GtkAdjustment* gtk_viewport_get_hadjustment (GtkViewport *viewport)
GtkAdjustment *
gtk_viewport_get_hadjustment (viewport)
	GtkViewport * viewport

## GtkAdjustment* gtk_viewport_get_vadjustment (GtkViewport *viewport)
GtkAdjustment *
gtk_viewport_get_vadjustment (viewport)
	GtkViewport * viewport

## void gtk_viewport_set_hadjustment (GtkViewport *viewport, GtkAdjustment *adjustment)
void
gtk_viewport_set_hadjustment (viewport, adjustment)
	GtkViewport   * viewport
	GtkAdjustment * adjustment

## void gtk_viewport_set_vadjustment (GtkViewport *viewport, GtkAdjustment *adjustment)
void
gtk_viewport_set_vadjustment (viewport, adjustment)
	GtkViewport   * viewport
	GtkAdjustment * adjustment

## void gtk_viewport_set_shadow_type (GtkViewport *viewport, GtkShadowType type)
void
gtk_viewport_set_shadow_type (viewport, type)
	GtkViewport   * viewport
	GtkShadowType   type

## GtkShadowType gtk_viewport_get_shadow_type (GtkViewport *viewport)
GtkShadowType
gtk_viewport_get_shadow_type (viewport)
	GtkViewport * viewport

#if GTK_CHECK_VERSION (2, 20, 0)

GdkWindow_ornull*
gtk_viewport_get_bin_window (GtkViewport *viewport)

#endif /* 2.20 */

#if GTK_CHECK_VERSION (2, 22, 0)

GdkWindow_ornull * gtk_viewport_get_view_window (GtkViewport *viewport);

#endif /* 2.22 */
