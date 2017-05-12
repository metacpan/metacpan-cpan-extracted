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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaHandleLayer.xs,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

MODULE = Gnome2::Dia::HandleLayer	PACKAGE = Gnome2::Dia::HandleLayer	PREFIX = dia_handle_layer_

##  void dia_handle_layer_update_handles (DiaHandleLayer *layer, DiaCanvasViewItem *item)
void
dia_handle_layer_update_handles (layer, item)
	DiaHandleLayer *layer
	DiaCanvasViewItem *item

##  void dia_handle_layer_get_pos_c (DiaHandleLayer *layer, DiaHandle *handle, gint *x, gint *y)
void dia_handle_layer_get_pos_c (DiaHandleLayer *layer, DiaHandle *handle, OUTLIST gint x, OUTLIST gint y)

##  void dia_handle_layer_request_redraw (DiaHandleLayer *layer, gint x, gint y)
void
dia_handle_layer_request_redraw (layer, x, y)
	DiaHandleLayer *layer
	gint x
	gint y

##  void dia_handle_layer_request_redraw_handle (DiaHandleLayer *layer, DiaHandle *handle)
void
dia_handle_layer_request_redraw_handle (layer, handle)
	DiaHandleLayer *layer
	DiaHandle *handle

##  Deprecated.
##  void dia_handle_layer_grab_handle (DiaHandleLayer *layer, DiaHandle *handle)
