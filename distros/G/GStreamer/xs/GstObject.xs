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

MODULE = GStreamer::Object	PACKAGE = GStreamer::Object	PREFIX = gst_object_

BOOT:
	/* Register gst_object_sink() as the sink function to get the
	   ref-counting right. */
	gperl_register_sink_func (GST_TYPE_OBJECT,
	                          (GPerlObjectSinkFunc) gst_object_sink);

void gst_object_set_name (GstObject *object, const gchar_ornull *name);

gchar_ornull * gst_object_get_name (GstObject *object)
    CLEANUP:
	g_free (RETVAL);

void gst_object_set_name_prefix	(GstObject *object, const gchar_ornull *name_prefix);

gchar_ornull * gst_object_get_name_prefix (GstObject *object)
    CLEANUP:
	g_free (RETVAL);

void gst_object_set_parent (GstObject *object, GstObject *parent);

GstObject_ornull * gst_object_get_parent (GstObject *object);

void gst_object_unparent (GstObject *object);

gboolean gst_object_has_ancestor (GstObject *object, GstObject *ancestor);

# FIXME?
# void gst_object_default_deep_notify (GObject *object, GstObject *orig, GParamSpec *pspec, gchar **excluded_props);
# void gst_object_replace (GstObject **oldobj, GstObject *newobj);

gchar_own * gst_object_get_path_string (GstObject *object);

# FIXME?
# gboolean gst_object_check_uniqueness (GList *list, const gchar *name);
# guint gst_class_signal_connect (GstObjectClass *klass, const gchar *name, gpointer func, gpointer func_data);
