/*
 * Copyright (C) 2005 by the gtk2-perl team
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
 * $Id$
 */

#include "gstinterfacesperl.h"

MODULE = GStreamer::PropertyProbe	PACKAGE = GStreamer::PropertyProbe	PREFIX = gst_property_probe_

# const GList * gst_property_probe_get_properties (GstPropertyProbe *probe);
void
gst_property_probe_get_probe_properties (probe)
	GstPropertyProbe *probe
    PREINIT:
	const GList *result, *i;
    PPCODE:
	result = gst_property_probe_get_properties (probe);
	for (i = result; i; i = i->next)
	       XPUSHs (sv_2mortal (newSVGParamSpec (i->data)));

# const GParamSpec * gst_property_probe_get_property (GstPropertyProbe *probe, const gchar *name);
GParamSpec *
gst_property_probe_get_probe_property (probe, name)
	GstPropertyProbe *probe
	const gchar *name
    CODE:
	RETVAL = (GParamSpec *) gst_property_probe_get_property (probe, name);
    OUTPUT:
	RETVAL

# void gst_property_probe_probe_property (GstPropertyProbe *probe, const GParamSpec *pspec);
void
gst_property_probe_probe_property (probe, pspec)
	GstPropertyProbe *probe
	GParamSpec *pspec
    CODE:
	gst_property_probe_probe_property (probe, (const GParamSpec *) pspec);

void gst_property_probe_probe_property_name (GstPropertyProbe *probe, const gchar *name);

# gboolean gst_property_probe_needs_probe (GstPropertyProbe *probe, const GParamSpec *pspec);
gboolean
gst_property_probe_needs_probe (probe, pspec)
	GstPropertyProbe *probe
	GParamSpec *pspec
    CODE:
	RETVAL = gst_property_probe_needs_probe (probe, (const GParamSpec *) pspec);
    OUTPUT:
	RETVAL

gboolean gst_property_probe_needs_probe_name (GstPropertyProbe *probe, const gchar *name);

# GValueArray * gst_property_probe_get_values (GstPropertyProbe *probe, const GParamSpec *pspec);
# GValueArray * gst_property_probe_probe_and_get_values (GstPropertyProbe *probe, const GParamSpec *pspec);
void
gst_property_probe_get_probe_values (probe, pspec)
	GstPropertyProbe *probe
	GParamSpec *pspec
    ALIAS:
	GStreamer::PropertyProbe::probe_and_get_probe_values = 1
    PREINIT:
	GValueArray *array;
	int i;
    PPCODE:
	switch (ix) {
	    case 0:
		array = gst_property_probe_get_values (probe, (const GParamSpec *) pspec);
		break;
	    case 1:
		array = gst_property_probe_probe_and_get_values (probe, (const GParamSpec *) pspec);
		break;
	    default:
		array = NULL;
		break;
	}

	if (array) {
		EXTEND (sp, array->n_values);
		for (i = 0; i < array->n_values; i++) {
		       GValue *value = g_value_array_get_nth (array, i);
		       PUSHs (sv_2mortal (gperl_sv_from_value ((const GValue *) value)));
		}
		g_value_array_free (array);
	}

# GValueArray * gst_property_probe_get_values_name (GstPropertyProbe *probe, const gchar *name);
# GValueArray * gst_property_probe_probe_and_get_values_name (GstPropertyProbe *probe, const gchar *name);
void
gst_property_probe_get_probe_values_name (probe, name)
	GstPropertyProbe *probe
	const gchar *name
    ALIAS:
	GStreamer::PropertyProbe::probe_and_get_probe_values_name = 1
    PREINIT:
	GValueArray *array;
	int i;
    PPCODE:
	switch (ix) {
	    case 0:
		array = gst_property_probe_get_values_name (probe, name);
		break;
	    case 1:
		array = gst_property_probe_probe_and_get_values_name (probe, name);
		break;
	    default:
		array = NULL;
		break;
	}

	if (array) {
		EXTEND (sp, array->n_values);
		for (i = 0; i < array->n_values; i++) {
		       GValue *value = g_value_array_get_nth (array, i);
		       PUSHs (sv_2mortal (gperl_sv_from_value ((const GValue *) value)));
		}
		g_value_array_free (array);
	}
