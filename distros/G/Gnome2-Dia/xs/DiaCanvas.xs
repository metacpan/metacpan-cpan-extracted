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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaCanvas.xs,v 1.2 2004/11/10 18:41:48 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

MODULE = Gnome2::Dia::Canvas	PACKAGE = Gnome2::Dia::Canvas	PREFIX = dia_canvas_

##  Struct members that have no corresponding properties.
SV *
root (canvas)
	DiaCanvas *canvas
    ALIAS:
	solver = 1
    CODE:
	RETVAL = &PL_sv_undef;
	switch (ix) {
		case 0: RETVAL = newSVDiaCanvasItem (canvas->root); break;
		case 1: RETVAL = newSVDiaSolver (canvas->solver); break;
		default: g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

##  DiaCanvas* dia_canvas_new (void)
DiaCanvas_noinc *
dia_canvas_new (class)
    C_ARGS:
	/* void */

##  void dia_canvas_request_update (DiaCanvas *canvas)
void
dia_canvas_request_update (canvas)
	DiaCanvas *canvas

##  void dia_canvas_update_now (DiaCanvas *canvas)
void
dia_canvas_update_now (canvas)
	DiaCanvas *canvas

##  void dia_canvas_resolve_now (DiaCanvas *canvas)
void
dia_canvas_resolve_now (canvas)
	DiaCanvas *canvas

##  void dia_canvas_set_extents (DiaCanvas *canvas, const DiaRectangle *extents)
void
dia_canvas_set_extents (canvas, extents)
	DiaCanvas *canvas
	const DiaRectangle *extents

##  void dia_canvas_set_static_extents (DiaCanvas *canvas, gboolean stat)
void dia_canvas_set_static_extents (canvas, stat)
	DiaCanvas *canvas
	gboolean stat

##  void dia_canvas_snap_to_grid (DiaCanvas *canvas, gdouble *x, gdouble *y)
void
dia_canvas_snap_to_grid (canvas, x, y)
	DiaCanvas *canvas
	gdouble x
	gdouble y
    PPCODE:
	dia_canvas_snap_to_grid (canvas, &x, &y);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVnv (x)));
	PUSHs (sv_2mortal (newSVnv (y)));

##  void dia_canvas_set_snap_to_grid (DiaCanvas *canvas, gboolean snap)
void
dia_canvas_set_snap_to_grid (canvas, snap)
	DiaCanvas *canvas
	gboolean snap

##  gdouble dia_canvas_glue_handle (DiaCanvas *canvas, const DiaHandle *handle, const gdouble dest_x, const gdouble dest_y, gdouble *glue_x, gdouble *glue_y,DiaCanvasItem **item)
void
dia_canvas_glue_handle (canvas, handle, dest_x, dest_y)
	DiaCanvas *canvas
	DiaHandle *handle
	gdouble dest_x
	gdouble dest_y
    PREINIT:
	gdouble distance;
	gdouble glue_x;
	gdouble glue_y;
	DiaCanvasItem *item;
    PPCODE:
	distance = dia_canvas_glue_handle (canvas, handle, dest_x, dest_y,
	                                   &glue_x, &glue_y, &item);
	EXTEND (sp, 4);
	PUSHs (sv_2mortal (newSVnv (distance)));
	PUSHs (sv_2mortal (newSVnv (glue_x)));
	PUSHs (sv_2mortal (newSVnv (glue_y)));
	PUSHs (sv_2mortal (newSVDiaCanvasItem (item)));

##  GList* dia_canvas_find_objects_in_rectangle (DiaCanvas *canvas, DiaRectangle *rect)
void
dia_canvas_find_objects_in_rectangle (canvas, rect)
	DiaCanvas *canvas
	DiaRectangle *rect
    PREINIT:
	GList *list = NULL, *i;
    PPCODE:
	list = dia_canvas_find_objects_in_rectangle (canvas, rect);
	for (i = list; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVDiaCanvasItem (i->data)));
	g_list_free (list);

##  void dia_canvas_add_constraint (DiaCanvas *canvas, DiaConstraint *c)
void
dia_canvas_add_constraint (canvas, c)
	DiaCanvas *canvas
	DiaConstraint *c

##  void dia_canvas_remove_constraint (DiaCanvas *canvas, DiaConstraint *c)
void
dia_canvas_remove_constraint (canvas, c)
	DiaCanvas *canvas
	DiaConstraint *c

##  PangoLayout* dia_canvas_get_pango_layout (void)
PangoLayout_noinc *
dia_canvas_get_pango_layout (class)
    C_ARGS:
	/* void */

##  void dia_canvas_redraw_views (DiaCanvas *canvas)
void
dia_canvas_redraw_views (canvas)
	DiaCanvas *canvas

##  void dia_canvas_preserve (DiaCanvas *canvas, GObject *object, const char *property_name, const GValue *value, gboolean last)
void
dia_canvas_preserve (canvas, object, property_name, value, last)
	DiaCanvas *canvas
	GObject *object
	const char *property_name
	SV *value
	gboolean last
    PREINIT:
	GParamSpec *pspec;
	GValue real_value = {0,};
    CODE:
	pspec = g_object_class_find_property (G_OBJECT_GET_CLASS (object),
	                                      property_name);

	if (!pspec) {
		const char *class_name =
			gperl_object_package_from_type (G_OBJECT_TYPE (object));
		if (!class_name)
			class_name = G_OBJECT_TYPE_NAME (object);
		croak ("type %s does not support property '%s'",
		       class_name, property_name);
	}

	g_value_init (&real_value, G_PARAM_SPEC_VALUE_TYPE (pspec));
	gperl_value_from_sv (&real_value, value);

	/* Using pspec->name instead of property_name here because the former
	   will be around way longer, which is what dia_canvas_preserve
	   expects. */
	dia_canvas_preserve (canvas, object, pspec->name, &real_value, last);

	g_value_unset (&real_value);

##  void dia_canvas_preserve_property (DiaCanvas *canvas, GObject *object, const char *property_name)
void
dia_canvas_preserve_property (canvas, object, property_name)
	DiaCanvas *canvas
	GObject *object
	const char *property_name

##  void dia_canvas_preserve_property_last (DiaCanvas *canvas, GObject *object, const char *property_name)
void
dia_canvas_preserve_property_last (canvas, object, property_name)
	DiaCanvas *canvas
	GObject *object
	const char *property_name

##  void dia_canvas_push_undo (DiaCanvas *canvas, const char* optional_comment)
void
dia_canvas_push_undo (canvas, optional_comment=NULL)
	DiaCanvas *canvas
	const char_ornull *optional_comment

##  void dia_canvas_pop_undo (DiaCanvas *canvas)
void
dia_canvas_pop_undo (canvas)
	DiaCanvas *canvas

##  void dia_canvas_clear_undo (DiaCanvas *canvas)
void
dia_canvas_clear_undo (canvas)
	DiaCanvas *canvas

##  guint dia_canvas_get_undo_depth (DiaCanvas *canvas)
guint
dia_canvas_get_undo_depth (canvas)
	DiaCanvas *canvas

##  void dia_canvas_pop_redo (DiaCanvas *canvas)
void
dia_canvas_pop_redo (canvas)
	DiaCanvas *canvas

##  void dia_canvas_clear_redo (DiaCanvas *canvas)
void
dia_canvas_clear_redo (canvas)
	DiaCanvas *canvas

##  guint dia_canvas_get_redo_depth (DiaCanvas *canvas)
guint
dia_canvas_get_redo_depth (canvas)
	DiaCanvas *canvas

##  void dia_canvas_set_undo_stack_depth (DiaCanvas *canvas, guint depth)
void
dia_canvas_set_undo_stack_depth (canvas, depth)
	DiaCanvas *canvas
	guint depth

##  guint dia_canvas_get_undo_stack_depth (DiaCanvas *canvas)
guint
dia_canvas_get_undo_stack_depth (canvas)
	DiaCanvas *canvas
