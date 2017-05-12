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

MODULE = GStreamer::ChildProxy	PACKAGE = GStreamer::ChildProxy	PREFIX = gst_child_proxy_

=for position DESCRIPTION

=head1 DESCRIPTION

To avoid a name clash with Glib::Object::get, gst_child_proxy_get and
gst_child_proxy_set are bound as I<GStreamer::ChildProxy::get_child_property>
and I<GStreamer::ChildProxy::set_child_property> respectively.

=cut

GstObject_ornull *gst_child_proxy_get_child_by_name (GstChildProxy * parent, const gchar * name);

GstObject_ornull *gst_child_proxy_get_child_by_index (GstChildProxy * parent, guint index);

guint gst_child_proxy_get_children_count (GstChildProxy * parent);

# FIXME: Needed?
# gboolean gst_child_proxy_lookup (GstObject *object, const gchar *name, GstObject **target, GParamSpec **pspec);

# void gst_child_proxy_get_property (GstObject * object, const gchar *name, GValue *value);
# void gst_child_proxy_get_valist (GstObject * object, const gchar * first_property_name, va_list var_args);
# void gst_child_proxy_get (GstObject * object, const gchar * first_property_name, ...);
void
gst_child_proxy_get_child_property (GstObject *object, const gchar *property, ...)
    PREINIT:
	int i;
    PPCODE:
	for (i = 1; i < items; i++) {
		char *name = SvGChar (ST (i));
		SV *sv;

		GParamSpec *pspec;
		GValue value = { 0, };
		GstObject *target = NULL;

		if (!gst_child_proxy_lookup (object, name, &target, &pspec)) {
			const char * classname =
				gperl_object_package_from_type (G_OBJECT_TYPE (object));
			if (!classname)
				classname = G_OBJECT_TYPE_NAME (object);
			croak ("type %s does not support property '%s'",
			       classname, name);
		}

		g_value_init (&value, G_PARAM_SPEC_VALUE_TYPE (pspec));
		g_object_get_property (G_OBJECT (target), pspec->name, &value);
		sv = gperl_sv_from_value (&value);
		g_value_unset (&value);
		gst_object_unref (target);

		XPUSHs (sv_2mortal (sv));
	}

# void gst_child_proxy_set_property (GstObject * object, const gchar *name, const GValue *value);
# void gst_child_proxy_set_valist (GstObject* object, const gchar * first_property_name, va_list var_args);
# void gst_child_proxy_set (GstObject * object, const gchar * first_property_name, ...);
void
gst_child_proxy_set_child_property (GstObject *object, const gchar *property, SV *value, ...)
    PREINIT:
	int i;
    CODE:
	PERL_UNUSED_VAR (value);

	for (i = 1; i < items; i += 2) {
		char *name = SvGChar (ST (i));
		SV *value = ST (i + 1);

		GParamSpec *pspec;
		GValue real_value = { 0, };
		GstObject *target = NULL;

		if (!gst_child_proxy_lookup (object, name, &target, &pspec)) {
			const char * classname =
				gperl_object_package_from_type (G_OBJECT_TYPE (object));
			if (!classname)
				classname = G_OBJECT_TYPE_NAME (object);
			croak ("type %s does not support property '%s'",
			       classname, name);
		}

		g_value_init (&real_value, G_PARAM_SPEC_VALUE_TYPE (pspec));
		gperl_value_from_sv (&real_value, value);
		g_object_set_property (G_OBJECT (target), pspec->name, &real_value);
		g_value_unset (&real_value);
		gst_object_unref (target);
	}

void gst_child_proxy_child_added (GstObject * object, GstObject * child);

void gst_child_proxy_child_removed (GstObject * object, GstObject * child);
