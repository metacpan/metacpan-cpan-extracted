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
 * License along with this library; if not, see
 * <https://www.gnu.org/licenses/>.
 *
 * $Id$
 */

#include "diacanvas2perl.h"

MODULE = Gnome2::Dia::CanvasElement	PACKAGE = Gnome2::Dia::CanvasElement	PREFIX = dia_canvas_element_

##  DiaHandle * dia_canvas_element_get_opposite_handle (DiaCanvasItem *item, DiaHandle *handle)
DiaHandle *
dia_canvas_element_get_opposite_handle (item, handle)
	DiaCanvasItem *item
	DiaHandle *handle

##  Marked as protected
##  void dia_canvas_element_align_handles (DiaCanvasElement *element)
