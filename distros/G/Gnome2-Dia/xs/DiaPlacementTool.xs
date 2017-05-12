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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaPlacementTool.xs,v 1.3 2004/10/15 16:14:04 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

MODULE = Gnome2::Dia::PlacementTool	PACKAGE = Gnome2::Dia::PlacementTool	PREFIX = dia_placement_tool_

##  DiaTool * dia_placement_tool_new (GType object_type, const gchar *first_property_name, ...)
##  DiaTool * dia_placement_tool_newv (GType object_type, guint n_params, GParameter *params)
DiaTool_noinc *
dia_placement_tool_new (class, type, ...)
	const char *type
    PREINIT:
	GType object_type;
    CODE:
	object_type = gperl_object_type_from_package (type);
#if DIACANVAS_CHECK_VERSION (0, 14, 0)
#define FIRST_ARG 2
{
	guint n_params = 0;
	GParameter *params = NULL;
	GObjectClass *class = NULL;
	int i;

	if (!object_type)
		croak ("%s is not registered with gperl as an object type",
		       class);

	if (items > FIRST_ARG) {
		class = g_type_class_ref (object_type);

		if (!class)
			croak ("could not get a reference to type class");

		n_params = (items - FIRST_ARG) / 2;
		params = g_new0 (GParameter, n_params);

		for (i = 0; i < n_params; i++) {
			const char *key = SvPV_nolen (ST (FIRST_ARG + i*2 + 0));
			GParamSpec *pspec = g_object_class_find_property (class, key);

			if (!pspec) {
				croak ("type %s does not support property '%s'",
				       class, key);
			}

			g_value_init (&params[i].value,
			              G_PARAM_SPEC_VALUE_TYPE (pspec));

			/* note: this croaks if there is a problem.  this is
			 * usually the right thing to do, because if it
			 * doesn't know how to convert the value, then there's
			 * something seriously wrong; however, it means that
			 * if there is a problem, all non-trivial values we've
			 * converted will be leaked. */
			gperl_value_from_sv (&params[i].value, ST (FIRST_ARG + i*2 + 1));

			/* will be valid until this xsub is finished */
			params[i].name = key;
		}
	}

	RETVAL = dia_placement_tool_newv (object_type, n_params, params);

	if (n_params) {
		for (i = 0; i < n_params; i++)
			g_value_unset (&params[i].value);
		g_free (params);
	}
	if (class)
		g_type_class_unref (class);
}
#undef FIRST_ARG
#else
	RETVAL = dia_placement_tool_new (object_type, NULL);
#endif
    OUTPUT:
	RETVAL
