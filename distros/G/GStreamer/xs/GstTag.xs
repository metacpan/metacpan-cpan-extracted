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

static GPerlBoxedWrapperClass gst_tag_list_wrapper_class;

static void
fill_hv (const GstTagList *list,
         const gchar *tag,
         gpointer user_data)
{
	HV *hv = (HV *) user_data;
	AV *av = newAV ();
	guint size, i;

	size = gst_tag_list_get_tag_size (list, tag);
	for (i = 0; i < size; i++) {
		const GValue *value;
		SV *sv;

		value = gst_tag_list_get_value_index (list, tag, i);
		sv = gperl_sv_from_value (value);

		av_store (av, i, sv);
	}

	hv_store (hv, tag, strlen (tag), newRV_noinc ((SV *) av), 0);
}

static SV *
gst_tag_list_wrap (GType gtype,
                   const char *package,
                   GstTagList *list,
		   gboolean own)
{
	HV *hv = newHV ();

	gst_tag_list_foreach (list, fill_hv, hv);
	if (own)
		gst_tag_list_free (list);

	return newRV_noinc ((SV *) hv);
}

static GstTagList *
gst_tag_list_unwrap (GType gtype,
                     const char *package,
                     SV *sv)
{
	/* FIXME: Do we leak the list? */
	GstTagList *list = gst_tag_list_new ();
	HV *hv = (HV *) SvRV (sv);
	HE *he;

	hv_iterinit (hv);
	while (NULL != (he = hv_iternext (hv))) {
		I32 length, i;
		char *tag;
		GType type;
		SV *ref;
		AV *av;

		tag = hv_iterkey (he, &length);
		if (!gst_tag_exists (tag))
			continue;

		ref = hv_iterval (hv, he);
		if (!gperl_sv_is_array_ref (ref))
			croak ("The values inside of GstTagList's have to be array references");

		type = gst_tag_get_type (tag);

		av = (AV *) SvRV (ref);
		for (i = 0; i <= av_len (av); i++) {
			GValue value = { 0 };
			SV **entry = av_fetch (av, i, 0);

			if (!(entry && gperl_sv_is_defined (*entry)))
				continue; /* FIXME: Why not croak here, too? */

			g_value_init (&value, type);
			gperl_value_from_sv (&value, *entry);

			gst_tag_list_add_values (list, GST_TAG_MERGE_APPEND, tag, &value, NULL);

			g_value_unset (&value);
		}
	}

	return list;
}

/* ------------------------------------------------------------------------- */

MODULE = GStreamer::Tag	PACKAGE = GStreamer::Tag	PREFIX = gst_tag_

BOOT:
	gst_tag_list_wrapper_class = *gperl_default_boxed_wrapper_class ();
	gst_tag_list_wrapper_class.wrap = (GPerlBoxedWrapFunc) gst_tag_list_wrap;
	gst_tag_list_wrapper_class.unwrap = (GPerlBoxedUnwrapFunc) gst_tag_list_unwrap;
	gperl_register_boxed (GST_TYPE_TAG_LIST, "GStreamer::TagList",
	                      &gst_tag_list_wrapper_class);
	gperl_set_isa ("GStreamer::TagList", "Glib::Boxed");

# FIXME: Might be handy.  But GstTagMergeFunc looks ugly.
# void gst_tag_register (const gchar * name, GstTagFlag flag, GType type, const gchar * nick, const gchar * blurb, GstTagMergeFunc func);

# void gst_tag_merge_use_first (GValue * dest, const GValue * src);
# void gst_tag_merge_strings_with_comma (GValue * dest, const GValue * src);

=for apidoc __function__
=cut
gboolean gst_tag_exists (const gchar * tag);

=for apidoc __function__
=cut
# GType gst_tag_get_type (const gchar * tag);
const char *
gst_tag_get_type (tag)
	const gchar * tag
    CODE:
	RETVAL = gperl_package_from_type (gst_tag_get_type (tag));
    OUTPUT:
	RETVAL

=for apidoc __function__
=cut
const gchar * gst_tag_get_nick (const gchar * tag);

=for apidoc __function__
=cut
const gchar * gst_tag_get_description (const gchar * tag);

=for apidoc __function__
=cut
GstTagFlag gst_tag_get_flag (const gchar * tag);

=for apidoc __function__
=cut
gboolean gst_tag_is_fixed (const gchar * tag);
