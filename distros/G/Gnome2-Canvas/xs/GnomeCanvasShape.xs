/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, see
 * <https://www.gnu.org/licenses/>.
 *
 * $Id$
 */
#include "gnomecanvasperl.h"

MODULE = Gnome2::Canvas::Shape	PACKAGE = Gnome2::Canvas::Shape	PREFIX = gnome_canvas_shape_

void
gnome_canvas_shape_set_path_def (shape, path_def)
	GnomeCanvasShape * shape
	GnomeCanvasPathDef * path_def

GnomeCanvasPathDef_copy *
gnome_canvas_shape_get_path_def (shape)
	GnomeCanvasShape * shape
