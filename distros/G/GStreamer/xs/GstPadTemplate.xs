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

MODULE = GStreamer::PadTemplate	PACKAGE = GStreamer::PadTemplate	PREFIX = gst_pad_template_

# GstPadTemplate* gst_pad_template_new (const gchar *name_template, GstPadDirection direction, GstPadPresence presence, GstCaps *caps);
GstPadTemplate *
gst_pad_template_new (class, name_template, direction, presence, caps)
	const gchar *name_template
	GstPadDirection direction
	GstPadPresence presence
	GstCaps *caps
    C_ARGS:
	/* The template takes over ownership of caps, so we have to hand it a
	   copy. */
	name_template, direction, presence, gst_caps_copy (caps)

# FIXME?
# GstPadTemplate * gst_static_pad_template_get (GstStaticPadTemplate *pad_template);
# GstCaps * gst_static_pad_template_get_caps (GstStaticPadTemplate *templ);

const GstCaps * gst_pad_template_get_caps (GstPadTemplate *templ);

void gst_pad_template_pad_created (GstPadTemplate * templ, GstPad * pad);

# FIXME: File bug reports about these missing accessors?

const gchar *
get_name_template (templ)
	GstPadTemplate *templ
    CODE:
	RETVAL = templ->name_template;
    OUTPUT:
	RETVAL

GstPadDirection
get_direction (templ)
	GstPadTemplate *templ
    CODE:
	RETVAL = templ->direction;
    OUTPUT:
	RETVAL

GstPadPresence
get_presence (templ)
	GstPadTemplate *templ
    CODE:
	RETVAL = templ->presence;
    OUTPUT:
	RETVAL
