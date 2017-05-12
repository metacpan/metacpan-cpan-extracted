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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaTool.xs,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

MODULE = Gnome2::Dia::Tool	PACKAGE = Gnome2::Dia::Tool	PREFIX = dia_tool_

##  gboolean dia_tool_button_press (DiaTool *tool, DiaCanvasView *view, GdkEventButton *event)
gboolean
dia_tool_button_press (tool, view, event)
	DiaTool *tool
	DiaCanvasView *view
	GdkEvent *event
    C_ARGS:
	tool, view, (GdkEventButton *) event

##  gboolean dia_tool_button_release (DiaTool *tool, DiaCanvasView *view, GdkEventButton *event)
gboolean
dia_tool_button_release (tool, view, event)
	DiaTool *tool
	DiaCanvasView *view
	GdkEvent *event
    C_ARGS:
	tool, view, (GdkEventButton *) event

##  gboolean dia_tool_motion_notify (DiaTool *tool, DiaCanvasView *view, GdkEventMotion *event)
gboolean
dia_tool_motion_notify (tool, view, event)
	DiaTool *tool
	DiaCanvasView *view
	GdkEvent *event
    C_ARGS:
	tool, view, (GdkEventMotion *) event

##  gboolean dia_tool_key_press (DiaTool *tool, DiaCanvasView *view, GdkEventKey *event)
gboolean
dia_tool_key_press (tool, view, event)
	DiaTool *tool
	DiaCanvasView *view
	GdkEvent *event
    C_ARGS:
	tool, view, (GdkEventKey *) event

##  gboolean dia_tool_key_release (DiaTool *tool, DiaCanvasView *view, GdkEventKey *event)
gboolean
dia_tool_key_release (tool, view, event)
	DiaTool *tool
	DiaCanvasView *view
	GdkEvent *event
    C_ARGS:
	tool, view, (GdkEventKey *) event
