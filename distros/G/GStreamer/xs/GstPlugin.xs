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

/* Implemented in GstPluginFeature.xs. */

extern GPerlCallback * gst2perl_plugin_feature_filter_create (SV *func, SV *data);

extern gboolean gst2perl_plugin_feature_filter (GstPluginFeature *feature, gpointer user_data);

/* ------------------------------------------------------------------------- */

/* Used in GstRegistry.xs and GstRegistryPool.xs. */

GPerlCallback *
gst2perl_plugin_filter_create (SV *func, SV *data)
{
	GType param_types [1];
	param_types[0] = GST_TYPE_PLUGIN;
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, G_TYPE_BOOLEAN);
}

gboolean
gst2perl_plugin_filter (GstPlugin *plugin,
                        gpointer user_data)
{
	GPerlCallback *callback = user_data;
	GValue value = { 0, };
	gboolean retval;

	g_value_init (&value, callback->return_type);
	gperl_callback_invoke (callback, &value, plugin);
	retval = g_value_get_boolean (&value);
	g_value_unset (&value);

	return retval;
}

/* ------------------------------------------------------------------------- */

MODULE = GStreamer::Plugin	PACKAGE = GStreamer::Plugin	PREFIX = gst_plugin_

const gchar* gst_plugin_get_name (GstPlugin *plugin);

const gchar* gst_plugin_get_description (GstPlugin *plugin);

const gchar* gst_plugin_get_filename (GstPlugin *plugin);

const gchar* gst_plugin_get_version (GstPlugin *plugin);

const gchar* gst_plugin_get_license (GstPlugin *plugin);

const gchar* gst_plugin_get_source (GstPlugin *plugin);

const gchar* gst_plugin_get_package (GstPlugin *plugin);

const gchar* gst_plugin_get_origin (GstPlugin *plugin);

# FIXME?
# GModule * gst_plugin_get_module (GstPlugin *plugin);

gboolean gst_plugin_is_loaded (GstPlugin *plugin);

gboolean gst_plugin_name_filter (GstPlugin *plugin, const gchar *name);

=for apidoc __function__
=cut
# GstPlugin * gst_plugin_load_file (const gchar *filename, GError** error);
GstPlugin *
gst_plugin_load_file (filename)
	const gchar *filename
    PREINIT:
	GError *error = NULL;
    CODE:
	RETVAL = gst_plugin_load_file (filename, &error);
	if (!RETVAL)
		gperl_croak_gerror (NULL, error);
    OUTPUT:
	RETVAL

GstPlugin * gst_plugin_load (GstPlugin *plugin);

=for apidoc __function__
=cut
GstPlugin * gst_plugin_load_by_name (const gchar *name);
