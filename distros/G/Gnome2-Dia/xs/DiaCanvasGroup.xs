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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaCanvasGroup.xs,v 1.2 2005/02/20 20:54:05 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

/* ------------------------------------------------------------------------- */

static GPerlCallback *
diacanvas2perl_item_foreach_func_create (SV *func, SV *data)
{
	GType param_types[] = {
		DIA_TYPE_CANVAS_ITEM
	};
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, G_TYPE_INT);
}

static gint
diacanvas2perl_item_foreach_func (DiaCanvasItem *item,
                                  gpointer data)
{
	GPerlCallback *callback = (GPerlCallback *) data;
	GValue value = {0,};
	gint retval;

	g_value_init (&value, callback->return_type);
	gperl_callback_invoke (callback, &value, item);
	retval = g_value_get_int (&value);
	g_value_unset (&value);

	return retval;
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::Dia::CanvasGroup	PACKAGE = Gnome2::Dia::CanvasGroup	PREFIX = dia_canvas_group_

BOOT:
	gperl_set_isa ("Gnome2::Dia::CanvasGroup", "Gnome2::Dia::CanvasGroupable");

##  No _noinc here because we don't actually own the item.
##  DiaCanvasItem * dia_canvas_group_create_item (DiaCanvasGroup *group, GType type, const gchar* first_arg_name, ...)
DiaCanvasItem *
dia_canvas_group_create_item (group, type, ...)
	DiaCanvasGroup *group
	const char *type
    PREINIT:
	GType real_type;
	int i;
    CODE:
	if (((items - 2) % 2) != 0)
		croak ("expected name => value pairs to follow object class; "
		       "odd number of arguments detected");

	real_type = gperl_object_type_from_package (type);
	if (!real_type)
		croak ("%s is not registered with Perl as an object type",
		       type);

	RETVAL = dia_canvas_group_create_item (group, real_type, NULL);

	for (i = 2; i < items ; i += 2) {
		const char *name = SvPV_nolen (ST (i));
		SV *new_value = ST (i + 1);
		GParamSpec *pspec;
		GValue value = {0, };

		pspec = g_object_class_find_property (
		          G_OBJECT_GET_CLASS (RETVAL), name);
		if (!pspec)
			croak ("property %s not found in object class %s",
			       name, g_type_name (real_type));

		g_value_init (&value, G_PARAM_SPEC_VALUE_TYPE (pspec));
		gperl_value_from_sv (&value, new_value);
		g_object_set_property (G_OBJECT (RETVAL), name, &value);
		g_value_unset (&value);
	}
    OUTPUT:
	RETVAL

##  void dia_canvas_group_raise_item (DiaCanvasGroup *group, DiaCanvasItem *item, gint pos)
void
dia_canvas_group_raise_item (group, item, pos)
	DiaCanvasGroup *group
	DiaCanvasItem *item
	gint pos

##  void dia_canvas_group_lower_item (DiaCanvasGroup *group, DiaCanvasItem *item, gint pos)
void
dia_canvas_group_lower_item (group, item, pos)
	DiaCanvasGroup *group
	DiaCanvasItem *item
	gint pos

##  gint dia_canvas_group_foreach (DiaCanvasGroup *item, DiaCanvasItemForeachFunc func, gpointer data)
gint
dia_canvas_group_foreach (item, func, data=NULL)
	DiaCanvasGroup *item
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = diacanvas2perl_item_foreach_func_create (func, data);
	RETVAL = dia_canvas_group_foreach (item,
	                                   diacanvas2perl_item_foreach_func,
	                                   callback);
	gperl_callback_destroy (callback);
    OUTPUT:
	RETVAL
