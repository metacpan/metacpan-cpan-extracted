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

MODULE = GStreamer::TagSetter	PACKAGE = GStreamer::TagSetter	PREFIX = gst_tag_setter_

void gst_tag_setter_merge_tags (GstTagSetter *setter, const GstTagList *list, GstTagMergeMode mode);

# void gst_tag_setter_add_tags (GstTagSetter *setter, GstTagMergeMode mode, const gchar *tag, ...);
# void gst_tag_setter_add_tag_values (GstTagSetter *setter, GstTagMergeMode mode, const gchar *tag, ...);
# void gst_tag_setter_add_tag_valist (GstTagSetter *setter, GstTagMergeMode mode, const gchar *tag, va_list var_args);
# void gst_tag_setter_add_tag_valist_values (GstTagSetter *setter, GstTagMergeMode mode, const gchar *tag, va_list var_args);
void
gst_tag_setter_add_tags (setter, mode, tag, sv, ...)
	GstTagSetter *setter
	GstTagMergeMode mode
	const gchar *tag
	SV *sv
    PREINIT:
	int i;
    CODE:
	for (i = 2; i < items; i += 2) {
		GType type = 0;
		GValue value = { 0, };

		tag = SvGChar (ST (i));
		sv = ST (i + 1);

		type = gst_tag_get_type (tag);
		if (!type)
			croak ("Could not determine type for tag `%s'", tag);

		g_value_init (&value, type);
		gperl_value_from_sv (&value, sv);

		gst_tag_setter_add_tag_values (setter, mode,
		                       	       tag, &value,
		                               NULL);
		g_value_unset (&value);
	}

const GstTagList* gst_tag_setter_get_tag_list (GstTagSetter *setter);

void gst_tag_setter_set_tag_merge_mode (GstTagSetter *setter, GstTagMergeMode mode);

GstTagMergeMode gst_tag_setter_get_tag_merge_mode (GstTagSetter *setter);
