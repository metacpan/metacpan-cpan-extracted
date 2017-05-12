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

static GPerlCallback *
gst2perl_index_filter_create (SV *func, SV *data)
{
	GType param_types [2];
	param_types[0] = GST_TYPE_INDEX;
	param_types[1] = GST_TYPE_INDEX_ENTRY;
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, G_TYPE_BOOLEAN);
}

static gboolean
gst2perl_index_filter (GstIndex *index,
                       GstIndexEntry *entry,
		       gpointer data)
{
	GPerlCallback *callback = data;
	GValue value = { 0, };
	gboolean retval;

	g_value_init (&value, callback->return_type);
	gperl_callback_invoke (callback, &value, entry);
	retval = g_value_get_boolean (&value);
	g_value_unset (&value);

	return retval;
}

/* ------------------------------------------------------------------------- */

/* Implemented in gstindex.c, but not exported for some reason. */
extern GstIndexEntry * gst_index_add_associationv (GstIndex * index, gint id, GstAssocFlags flags, int n, const GstIndexAssociation * list);

/* ------------------------------------------------------------------------- */

#include <gperl_marshal.h>

static GQuark
gst2perl_index_resolver_quark (void)
{
	static GQuark q = 0;
	if (q == 0)
		q = g_quark_from_static_string ("gst2perl_index_resolver");
	return q;
}

static GPerlCallback *
gst2perl_index_resolver_create (SV *func, SV *data)
{
	return gperl_callback_new (func, data, 0, NULL, 0);
}

static gboolean
gst2perl_index_resolver (GstIndex *index,
                         GstObject *writer,
                         gchar **writer_string,
                         gpointer user_data)
{
	int n;
	SV *string;
	gboolean retval;
	GPerlCallback *callback;
	dGPERL_CALLBACK_MARSHAL_SP;

	callback = user_data;
	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVGstIndex (index)));
	PUSHs (sv_2mortal (newSVGstObject (writer)));
	if (callback->data)
		XPUSHs (sv_2mortal (newSVsv (callback->data)));

	PUTBACK;

	n = call_sv (callback->func, G_SCALAR);

	SPAGAIN;

	if (n != 1)
		croak ("resolver callback must return one value: the writer string");

	string = POPs;
	if (gperl_sv_is_defined (string)) {
		*writer_string = g_strdup (SvGChar (string));
		retval = TRUE;
	} else {
		*writer_string = NULL;
		retval = FALSE;
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return retval;
}

/* ------------------------------------------------------------------------- */

MODULE = GStreamer::Index	PACKAGE = GStreamer::Index	PREFIX = gst_index_

# GstIndex * gst_index_new (void);
GstIndex *
gst_index_new (class)
    C_ARGS:
	/* void */

void gst_index_commit (GstIndex *index, gint id);

gint gst_index_get_group (GstIndex *index);

gint gst_index_new_group (GstIndex *index);

gboolean gst_index_set_group (GstIndex *index, gint groupnum);

void gst_index_set_certainty (GstIndex *index, GstIndexCertainty certainty);

GstIndexCertainty gst_index_get_certainty (GstIndex *index);

# void gst_index_set_filter (GstIndex *index, GstIndexFilter filter, gpointer user_data);
void
gst_index_set_filter (index, func, data=NULL)
	GstIndex *index
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = gst2perl_index_filter_create (func, data);
	gst_index_set_filter_full (index,
				   gst2perl_index_filter,
				   callback,
				   (GDestroyNotify) gperl_callback_destroy);

# void gst_index_set_resolver (GstIndex *index, GstIndexResolver resolver, gpointer user_data);
void
gst_index_set_resolver (index, func, data=NULL)
	GstIndex *index
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = gst2perl_index_resolver_create (func, data);
	g_object_set_qdata_full (G_OBJECT (index),
	                         gst2perl_index_resolver_quark (),
	                         callback,
	                         (GDestroyNotify) gperl_callback_destroy);
	gst_index_set_resolver (index, gst2perl_index_resolver, callback);

# gboolean gst_index_get_writer_id (GstIndex *index, GstObject *writer, gint *id);
gint
gst_index_get_writer_id (index, writer)
	GstIndex *index
	GstObject *writer
    CODE:
	if (!gst_index_get_writer_id (index, writer, &RETVAL))
		XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

GstIndexEntry_ornull * gst_index_add_format (GstIndex *index, gint id, GstFormat format);

# GstIndexEntry * gst_index_add_association (GstIndex *index, gint id, GstAssocFlags flags, GstFormat format, gint64 value, ...);
GstIndexEntry_ornull *
gst_index_add_association (index, id, flags, format, value, ...)
	GstIndex *index
	gint id
	GstAssocFlags flags
	GstFormat format
	gint64 value
    PREINIT:
	GArray *array;
	int i, n_assocs = 0;
	GstIndexAssociation *list;
    CODE:
	PERL_UNUSED_VAR (format);
	PERL_UNUSED_VAR (value);

	array = g_array_new (FALSE, FALSE, sizeof (GstIndexAssociation));

	for (i = 3; i < items; i += 2) {
		GstIndexAssociation a;

		a.format = SvGstFormat (ST (i));
		a.value = SvGInt64 (ST (i + 1));

		g_array_append_val (array, a);
		n_assocs++;
	}

	list = (GstIndexAssociation *) g_array_free (array, FALSE);

	RETVAL = gst_index_add_associationv (index, id, flags, n_assocs, list);
	g_free (list);
    OUTPUT:
	RETVAL

# GstIndexEntry * gst_index_add_object (GstIndex *index, gint id, gchar *key, GType type, gpointer object);
GstIndexEntry_ornull *
gst_index_add_object (index, id, key, object)
	GstIndex *index
	gint id
	gchar *key
	SV *object
    PREINIT:
	GType type;
    CODE:
	type = gperl_object_type_from_package (sv_reftype (SvRV (object),
	                                                   TRUE));
	RETVAL = gst_index_add_object (index, id, key, type,
	                               gperl_get_object_check (object, type));
    OUTPUT:
	RETVAL

GstIndexEntry_ornull * gst_index_add_id (GstIndex *index, gint id, gchar *description);

GstIndexEntry_ornull * gst_index_get_assoc_entry (GstIndex *index, gint id, GstIndexLookupMethod method, GstAssocFlags flags, GstFormat format, gint64 value);

# FIXME?
# GstIndexEntry * gst_index_get_assoc_entry_full (GstIndex *index, gint id, GstIndexLookupMethod method, GstAssocFlags flags, GstFormat format, gint64 value, GCompareDataFunc func, gpointer user_data);

# --------------------------------------------------------------------------- #

MODULE = GStreamer::Index	PACKAGE = GStreamer::IndexEntry	PREFIX = gst_index_entry_

# gboolean gst_index_entry_assoc_map (GstIndexEntry *entry, GstFormat format, gint64 *value);
gint64
gst_index_entry_assoc_map (entry, format)
	GstIndexEntry *entry
	GstFormat format
    CODE:
	if (!gst_index_entry_assoc_map (entry, format, &RETVAL))
		XSRETURN_UNDEF;
    OUTPUT:
	RETVAL
