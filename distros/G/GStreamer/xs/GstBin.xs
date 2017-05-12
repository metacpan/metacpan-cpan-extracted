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

MODULE = GStreamer::Bin	PACKAGE = GStreamer::Bin	PREFIX = gst_bin_

BOOT:
	gperl_object_set_no_warn_unreg_subclass (GST_TYPE_BIN, TRUE);

# GstElement* gst_bin_new (const gchar *name);
GstElement *
gst_bin_new (class, name)
	const gchar *name
    C_ARGS:
	name

# void gst_bin_add (GstBin *bin, GstElement *element);
void
gst_bin_add (bin, element, ...)
	GstBin *bin
	GstElement *element
    PREINIT:
	int i;
    CODE:
	PERL_UNUSED_VAR (element);
	for (i = 1; i < items; i++)
		gst_bin_add (bin, SvGstElement (ST (i)));

# void gst_bin_remove (GstBin *bin, GstElement *element);
void
gst_bin_remove (bin, element, ...)
	GstBin *bin
	GstElement *element
    PREINIT:
	int i;
    CODE:
	PERL_UNUSED_VAR (element);
	for (i = 1; i < items; i++)
		gst_bin_remove (bin, SvGstElement (ST (i)));

GstElement* gst_bin_get_by_name (GstBin *bin, const gchar *name);

GstElement* gst_bin_get_by_name_recurse_up (GstBin *bin, const gchar *name);

# GstElement* gst_bin_get_by_interface (GstBin *bin, GType interface);
GstElement* gst_bin_get_by_interface (GstBin *bin, const char *interface)
    C_ARGS:
	bin, gperl_type_from_package (interface)

GstIterator* gst_bin_iterate_elements (GstBin *bin);

GstIterator* gst_bin_iterate_sorted (GstBin *bin);

GstIterator* gst_bin_iterate_recurse (GstBin *bin);

GstIterator* gst_bin_iterate_sinks (GstBin *bin);

# GstIterator* gst_bin_iterate_all_by_interface (GstBin *bin, GType interface);
GstIterator* gst_bin_iterate_all_by_interface (GstBin *bin, const char *interface)
    C_ARGS:
	bin, gperl_type_from_package (interface)
