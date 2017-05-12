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

static GHashTable *package_by_type = NULL;
static GHashTable *package_lookup_by_type = NULL;

G_LOCK_DEFINE_STATIC (package_by_type);
G_LOCK_DEFINE_STATIC (package_lookup_by_type);

void
gst2perl_register_mini_object (GType type, const char *package)
{
	G_LOCK (package_by_type);

	if (!package_by_type)
		package_by_type = g_hash_table_new_full (g_direct_hash,
						         g_direct_equal,
						         NULL,
						         NULL);

	g_hash_table_insert (package_by_type,
			     (gpointer) type,
			     (gpointer) package);

	G_UNLOCK (package_by_type);

	if (0 != strncmp (package, "GStreamer::MiniObject",
	      	 	  sizeof ("GStreamer::MiniObject")))
		gperl_set_isa(package, "GStreamer::MiniObject");
}

void
gst2perl_register_mini_object_package_lookup_func (GType type, Gst2PerlMiniObjectPackageLookupFunc func)
{
	G_LOCK (package_lookup_by_type);

	if (!package_lookup_by_type)
		package_lookup_by_type = g_hash_table_new_full (g_direct_hash,
						                g_direct_equal,
						         	NULL,
						         	NULL);

	g_hash_table_insert (package_lookup_by_type,
			     (gpointer) type,
			     (gpointer) func);

	G_UNLOCK (package_lookup_by_type);
}

/* ------------------------------------------------------------------------- */

static const char *
get_package (GstMiniObject *object)
{
	GType type = G_TYPE_FROM_INSTANCE (&object->instance);
	Gst2PerlMiniObjectPackageLookupFunc func = NULL;
	const char *result = NULL;

	func = g_hash_table_lookup (package_lookup_by_type, (gpointer) type);
	if (func)
		return func (object);

	result = g_hash_table_lookup (package_by_type, (gpointer) type);
	if (!result) {
		GType parent = type;
		while (result == NULL) {
			parent = g_type_parent (parent);
			result = g_hash_table_lookup (
				package_by_type,
				(gpointer) parent);
		}
	}

	return result;
}

SV *
gst2perl_sv_from_mini_object (GstMiniObject *object, gboolean own)
{
	if (!object)
		return &PL_sv_undef;

	if (!GST_IS_MINI_OBJECT (object))
		croak ("object 0x%p is not really a GstMiniObject", object);

	if (own)
		gst_mini_object_ref (object);

	return sv_setref_pv (newSV (0), get_package (object), object);
}

GstMiniObject *
gst2perl_mini_object_from_sv (SV *sv)
{
	return INT2PTR (GstMiniObject *, SvIV (SvRV (sv)));

}

/* ------------------------------------------------------------------------- */

static GPerlValueWrapperClass gst2perl_mini_object_wrapper_class;

static SV *
gst2perl_mini_object_wrap (const GValue *value)
{
	/* The object's refcount didn't get incremented, so we must not use
	 * _noinc. */
	return newSVGstMiniObject (gst_value_get_mini_object (value));
}

static void
gst2perl_mini_object_unwrap (GValue *value, SV *sv)
{
	gst_value_set_mini_object (value, SvGstMiniObject (sv));
}

static void
gst2perl_mini_object_initialize (void)
{
	gst2perl_mini_object_wrapper_class.wrap = gst2perl_mini_object_wrap;
	gst2perl_mini_object_wrapper_class.unwrap = gst2perl_mini_object_unwrap;

	gperl_register_fundamental_full (GST_TYPE_MINI_OBJECT,
	                                 "GStreamer::MiniObject",
	                                 &gst2perl_mini_object_wrapper_class);
}

/* ------------------------------------------------------------------------- */

MODULE = GStreamer::MiniObject	PACKAGE = GStreamer::MiniObject	PREFIX = gst_mini_object_

BOOT:
	gst2perl_mini_object_initialize ();

void
DESTROY (GstMiniObject *object)
    CODE:
	gst_mini_object_unref (object);

# FIXME: Needed?
# GstMiniObject * gst_mini_object_new (GType type);
# GstMiniObject * gst_mini_object_copy (const GstMiniObject *mini_object);

gboolean gst_mini_object_is_writable (const GstMiniObject *mini_object);

# GstMiniObject * gst_mini_object_make_writable (GstMiniObject *mini_object);
GstMiniObject_noinc *
gst_mini_object_make_writable (GstMiniObject *mini_object)
    C_ARGS:
	/* gst_mini_object_make_writable unref's mini_object, so we need to
	 * keep it alive. */
	gst_mini_object_ref (mini_object)

# FIXME: Needed?
# void gst_mini_object_replace (GstMiniObject **olddata, GstMiniObject *newdata);
# GParamSpec * gst_param_spec_mini_object (const char *name, const char *nick, const char *blurb, GType object_type, GParamFlags flags);
# void gst_value_set_mini_object (GValue *value, GstMiniObject *mini_object);
# void gst_value_take_mini_object (GValue *value, GstMiniObject *mini_object);
# GstMiniObject * gst_value_get_mini_object (const GValue *value);
