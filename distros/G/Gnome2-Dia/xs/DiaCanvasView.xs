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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaCanvasView.xs,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

MODULE = Gnome2::Dia::CanvasView	PACKAGE = Gnome2::Dia::CanvasView	PREFIX = dia_canvas_view_

##  Accessors.
DiaCanvas *
canvas (view)
	DiaCanvasView *view
    CODE:
	RETVAL = view->canvas;
    OUTPUT:
	RETVAL

DiaCanvasViewItem *
root_item (view)
	DiaCanvasView *view
    CODE:
	RETVAL = view->root_item;
    OUTPUT:
	RETVAL

GnomeCanvasItem *
handle_layer (view)
	DiaCanvasView *view
    CODE:
	RETVAL = view->handle_layer;
    OUTPUT:
	RETVAL

##  GtkWidget * dia_canvas_view_new (DiaCanvas *canvas, gboolean aa)
GtkWidget *
dia_canvas_view_new (class, canvas, aa)
	DiaCanvas *canvas
	gboolean aa
    C_ARGS:
	canvas, aa

##  GtkWidget * dia_canvas_view_aa_new (void)
GtkWidget *
dia_canvas_view_aa_new (class)
    C_ARGS:
	/* void */

##  void dia_canvas_view_set_canvas (DiaCanvasView *view, DiaCanvas *canvas)
void
dia_canvas_view_set_canvas (view, canvas)
	DiaCanvasView *view
	DiaCanvas *canvas

##  void dia_canvas_view_unset_canvas (DiaCanvasView *view)
void
dia_canvas_view_unset_canvas (view)
	DiaCanvasView *view

##  DiaCanvas * dia_canvas_view_get_canvas (DiaCanvasView *view)
DiaCanvas *
dia_canvas_view_get_canvas (view)
	DiaCanvasView *view

##  gdouble dia_canvas_view_get_zoom (DiaCanvasView *view)
gdouble
dia_canvas_view_get_zoom (view)
	DiaCanvasView *view

##  void dia_canvas_view_set_zoom (DiaCanvasView *view, gdouble zoom)
void
dia_canvas_view_set_zoom (view, zoom)
	DiaCanvasView *view
	gdouble zoom

##  void dia_canvas_view_set_tool (DiaCanvasView *view, DiaTool *tool)
void
dia_canvas_view_set_tool (view, tool)
	DiaCanvasView *view
	DiaTool *tool

#if DIACANVAS_CHECK_VERSION (0, 13, 0)

##  DiaTool * dia_canvas_view_get_tool (DiaCanvasView *view)
DiaTool *
dia_canvas_view_get_tool (view)
	DiaCanvasView *view

##  DiaTool * dia_canvas_view_get_default_tool (DiaCanvasView *view)
DiaTool *
dia_canvas_view_get_default_tool (view)
	DiaCanvasView *view

##  void dia_canvas_view_set_default_tool (DiaCanvasView *view, DiaTool *tool)
void
dia_canvas_view_set_default_tool (view, tool)
	DiaCanvasView *view
	DiaTool *tool

#endif

##  void dia_canvas_view_select (DiaCanvasView *view, DiaCanvasViewItem *item)
void
dia_canvas_view_select (view, item)
	DiaCanvasView *view
	DiaCanvasViewItem *item

##  void dia_canvas_view_select_rectangle (DiaCanvasView *view, DiaRectangle *rect)
void
dia_canvas_view_select_rectangle (view, rect)
	DiaCanvasView *view
	DiaRectangle *rect

##  void dia_canvas_view_select_all (DiaCanvasView *view)
void
dia_canvas_view_select_all (view)
	DiaCanvasView *view

##  void dia_canvas_view_unselect (DiaCanvasView *view, DiaCanvasViewItem *item)
void
dia_canvas_view_unselect (view, item)
	DiaCanvasView *view
	DiaCanvasViewItem *item

##  void dia_canvas_view_unselect_all (DiaCanvasView *view)
void
dia_canvas_view_unselect_all (view)
	DiaCanvasView *view

##  void dia_canvas_view_focus (DiaCanvasView *view, DiaCanvasViewItem *item)
void
dia_canvas_view_focus (view, item)
	DiaCanvasView *view
	DiaCanvasViewItem *item

##  void dia_canvas_view_move (DiaCanvasView *view, gdouble dx, gdouble dy, DiaCanvasViewItem *originator)
void
dia_canvas_view_move (view, dx, dy, originator)
	DiaCanvasView *view
	gdouble dx
	gdouble dy
	DiaCanvasViewItem *originator

##  void dia_canvas_view_request_update (DiaCanvasView *view)
void
dia_canvas_view_request_update (view)
	DiaCanvasView *view

##  DiaCanvasViewItem * dia_canvas_view_find_view_item (DiaCanvasView *view, DiaCanvasItem *item)
DiaCanvasViewItem_ornull *
dia_canvas_view_find_view_item (view, item)
	DiaCanvasView *view
	DiaCanvasItem *item

##  Deprecated.
##  void dia_canvas_view_gdk_event_to_dia_event (DiaCanvasView *view, DiaCanvasViewItem *item, GdkEvent *gdk_event, DiaEvent *dia_event)

#if DIACANVAS_CHECK_VERSION (0, 13, 2)

##  void dia_canvas_view_start_editing (DiaCanvasView *view, DiaCanvasViewItem *item, gdouble x, gdouble y)
void
dia_canvas_view_start_editing (view, item, x, y)
	DiaCanvasView *view
	DiaCanvasViewItem *item
	gdouble x
	gdouble y

#else /* FIXME: Remove altogether? */

##  void dia_canvas_view_start_editing (DiaCanvasView *view, DiaCanvasViewItem *item, DiaShapeText *text_shape)
void
dia_canvas_view_start_editing (view, item, text_shape)
	DiaCanvasView *view
	DiaCanvasViewItem *item
	DiaShapeText *text_shape

#endif

##  void dia_canvas_view_editing_done (DiaCanvasView *view)
void
dia_canvas_view_editing_done (view)
	DiaCanvasView *view

##  DiaCanvasView * dia_canvas_view_get_active_view (void)
DiaCanvasView_ornull *
dia_canvas_view_get_active_view (class)
    C_ARGS:
	/* void */
