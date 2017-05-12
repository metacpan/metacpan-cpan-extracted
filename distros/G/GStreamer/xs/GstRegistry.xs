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

/* Implemented in GstPlugin.xs. */

extern GPerlCallback * gst2perl_plugin_filter_create (SV *func, SV *data);

extern gboolean gst2perl_plugin_filter (GstPlugin *plugin, gpointer user_data);

/* ------------------------------------------------------------------------- */

/* Implemented in GstPluginFeature.xs. */

extern GPerlCallback * gst2perl_plugin_feature_filter_create (SV *func, SV *data);

extern gboolean gst2perl_plugin_feature_filter (GstPluginFeature *feature, gpointer user_data);

/* ------------------------------------------------------------------------- */

MODULE = GStreamer::Registry	PACKAGE = GStreamer::Registry	PREFIX = gst_registry_

BOOT:
	gperl_object_set_no_warn_unreg_subclass (GST_TYPE_REGISTRY, TRUE);

# GstRegistry * gst_registry_get_default (void);
GstRegistry * gst_registry_get_default (class)
    C_ARGS:
	/* void */

void gst_registry_scan_path (GstRegistry *registry, const gchar *path);

# GList* gst_registry_get_path_list (GstRegistry *registry);
void
gst_registry_get_path_list (registry)
	GstRegistry *registry
    PREINIT:
	GList *paths, *i;
    PPCODE:
	paths = gst_registry_get_path_list (registry);
	for (i = paths; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGChar (i->data)));
	g_list_free (paths);

gboolean gst_registry_add_plugin (GstRegistry *registry, GstPlugin *plugin);

void gst_registry_remove_plugin (GstRegistry *registry, GstPlugin *plugin);

gboolean gst_registry_add_feature (GstRegistry * registry, GstPluginFeature * feature);

void gst_registry_remove_feature (GstRegistry * registry, GstPluginFeature * feature);

# GList * gst_registry_get_plugin_list (GstRegistry *registry);
void
gst_registry_get_plugin_list (registry)
	GstRegistry *registry
    PREINIT:
	GList *plugins, *i;
    PPCODE:
	plugins = gst_registry_get_plugin_list (registry);
	for (i = plugins; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGstPlugin (i->data)));
	g_list_free (plugins);

# GList* gst_registry_plugin_filter (GstRegistry *registry, GstPluginFilter filter, gboolean first, gpointer user_data);
void
gst_registry_plugin_filter (registry, filter, first, data=NULL)
	GstRegistry *registry
	SV *filter
	gboolean first
	SV *data
    PREINIT:
	GPerlCallback *callback;
	GList *list, *i;
    PPCODE:
	callback = gst2perl_plugin_filter_create (filter, data);
	list = gst_registry_plugin_filter (registry,
	                                   gst2perl_plugin_filter,
	                                   first,
	                                   callback);

	for (i = list; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGstPlugin (i->data)));

	g_list_free (list);
	gperl_callback_destroy (callback);

# GList* gst_registry_feature_filter (GstRegistry *registry, GstPluginFeatureFilter filter, gboolean first, gpointer user_data);
void
gst_registry_feature_filter (registry, filter, first, data=NULL)
	GstRegistry *registry
	SV *filter
	gboolean first
	SV *data
    PREINIT:
	GPerlCallback *callback;
	GList *list, *i;
    PPCODE:
	callback = gst2perl_plugin_feature_filter_create (filter, data);
	list = gst_registry_feature_filter (registry,
	                                    gst2perl_plugin_feature_filter,
	                                    first,
	                                    callback);

	for (i = list; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGstPluginFeature (i->data)));

	g_list_free (list);
	gperl_callback_destroy (callback);

# GList * gst_registry_get_feature_list (GstRegistry *registry, GType type);
void
gst_registry_get_feature_list (registry, type)
	GstRegistry *registry
	const char *type
    PREINIT:
	GList *features, *i;
    PPCODE:
	features = gst_registry_get_feature_list (registry, gperl_type_from_package (type));
	for (i = features; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGstPluginFeature (i->data)));
	g_list_free (features);

# GList * gst_registry_get_feature_list_by_plugin (GstRegistry *registry, const gchar *name);
void
gst_registry_get_feature_list_by_plugin (registry, name)
	GstRegistry *registry
	const gchar *name
    PREINIT:
	GList *features, *i;
    PPCODE:
	features = gst_registry_get_feature_list_by_plugin (registry, name);
	for (i = features; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGstPluginFeature (i->data)));
	g_list_free (features);

GstPlugin* gst_registry_find_plugin (GstRegistry *registry, const gchar *name);

# GstPluginFeature* gst_registry_find_feature (GstRegistry *registry, const gchar *name, GType type);
GstPluginFeature *
gst_registry_find_feature (registry, name, type)
	GstRegistry *registry
	const gchar *name
	const char *type
    C_ARGS:
	registry, name, gperl_type_from_package (type)

GstPlugin * gst_registry_lookup (GstRegistry *registry, const char *filename);

GstPluginFeature * gst_registry_lookup_feature (GstRegistry *registry, const char *name);

gboolean gst_registry_xml_read_cache (GstRegistry * registry, const char *location);

gboolean gst_registry_xml_write_cache (GstRegistry * registry, const char *location);

# void _gst_registry_remove_cache_plugins (GstRegistry *registry);
# void _gst_registry_cleanup (void);

# FIXME?
# gboolean gst_default_registry_check_feature_version (const gchar *feature_name, guint min_major, guint min_minor, guint min_micro);
