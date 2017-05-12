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

MODULE = GStreamer::IndexFactory	PACKAGE = GStreamer::IndexFactory	PREFIX = gst_index_factory_

# GstIndexFactory * gst_index_factory_new (const gchar *name, const gchar *longdesc, GType type);
GstIndexFactory *
gst_index_factory_new (class, name, longdesc, type)
	const gchar *name
	const gchar *longdesc
	const char *type
    PREINIT:
	GType real_type;
    CODE:
	real_type = gperl_type_from_package (type);
	RETVAL = gst_index_factory_new (name, longdesc, real_type);
    OUTPUT:
	RETVAL

void gst_index_factory_destroy (GstIndexFactory *factory);

# GstIndexFactory * gst_index_factory_find (const gchar *name);
GstIndexFactory *
gst_index_factory_find (class, name)
	const gchar *name
    C_ARGS:
	name

GstIndex * gst_index_factory_create (GstIndexFactory *factory);

# GstIndex * gst_index_factory_make (const gchar *name);
GstIndex *
gst_index_factory_make (class, name)
	const gchar *name
    C_ARGS:
	name
