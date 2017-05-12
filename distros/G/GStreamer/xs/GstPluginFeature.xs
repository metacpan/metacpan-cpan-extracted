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
 * Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * $Id$
 */

#include "gst2perl.h"

/* ------------------------------------------------------------------------- */

/* Used in GstPlugin.xs, GstRegistry.xs, and GstRegistryPool.xs. */

GPerlCallback *
gst2perl_plugin_feature_filter_create (SV *func, SV *data)
{
	GType param_types [1];
	param_types[0] = GST_TYPE_PLUGIN_FEATURE;
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, G_TYPE_BOOLEAN);
}

gboolean
gst2perl_plugin_feature_filter (GstPluginFeature *feature,
                                gpointer user_data)
{
	GPerlCallback *callback = user_data;
	GValue value = { 0, };
	gboolean retval;

	g_value_init (&value, callback->return_type);
	gperl_callback_invoke (callback, &value, feature);
	retval = g_value_get_boolean (&value);
	g_value_unset (&value);

	return retval;
}

/* ------------------------------------------------------------------------- */

MODULE = GStreamer::PluginFeature	PACKAGE = GStreamer::PluginFeature	PREFIX = gst_plugin_feature_

BOOT:
	gperl_object_set_no_warn_unreg_subclass (GST_TYPE_PLUGIN_FEATURE, TRUE);

GstPluginFeature * gst_plugin_feature_load (GstPluginFeature *feature);

# FIXME: Is this needed?  It's not documented.
# gboolean gst_plugin_feature_type_name_filter (GstPluginFeature *feature, GstTypeNameData *data);

void gst_plugin_feature_set_rank (GstPluginFeature *feature, guint rank);

void gst_plugin_feature_set_name (GstPluginFeature *feature, const gchar *name);

# FIXME: Use enum typemap instead?
guint gst_plugin_feature_get_rank (GstPluginFeature *feature);

const gchar *gst_plugin_feature_get_name (GstPluginFeature *feature);

gboolean gst_plugin_feature_check_version (GstPluginFeature *feature, guint min_major, guint min_minor, guint min_micro);
