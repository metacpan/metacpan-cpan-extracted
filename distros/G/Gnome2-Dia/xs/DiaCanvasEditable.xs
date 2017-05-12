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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaCanvasEditable.xs,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

MODULE = Gnome2::Dia::CanvasEditable	PACKAGE = Gnome2::Dia::CanvasEditable	PREFIX = dia_canvas_editable_

##  void dia_canvas_editable_start_editing (DiaCanvasEditable *editable, DiaShapeText *text_shape)
void
dia_canvas_editable_start_editing (editable, text_shape)
	DiaCanvasEditable *editable
	DiaShapeText *text_shape

##  void dia_canvas_editable_editing_done (DiaCanvasEditable *editable, DiaShapeText *text_shape, const gchar *new_text)
void
dia_canvas_editable_editing_done (editable, text_shape, new_text)
	DiaCanvasEditable *editable
	DiaShapeText *text_shape
	const gchar *new_text

##  void dia_canvas_editable_text_changed (DiaCanvasEditable *editable, DiaShapeText *text_shape, const gchar *new_text)
void
dia_canvas_editable_text_changed (editable, text_shape, new_text)
	DiaCanvasEditable *editable
	DiaShapeText *text_shape
	const gchar *new_text
