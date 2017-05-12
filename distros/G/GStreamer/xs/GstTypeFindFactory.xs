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

MODULE = GStreamer::TypeFindFactory	PACKAGE = GStreamer::TypeFindFactory	PREFIX = gst_type_find_factory_

# GList * gst_type_find_factory_get_list (void);
void
gst_type_find_factory_get_list (class)
    PREINIT:
	GList *list, *i;
    PPCODE:
	PERL_UNUSED_VAR (ax);
	list = gst_type_find_factory_get_list ();
	for (i = list; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGstTypeFindFactory (i->data)));
	g_list_free (list);

# gchar ** gst_type_find_factory_get_extensions (GstTypeFindFactory *factory);
void
gst_type_find_factory_get_extensions (GstTypeFindFactory *factory)
    PREINIT:
	gchar **list;
	gchar *ext;
    PPCODE:
	list = gst_type_find_factory_get_extensions (factory);
	while (list && (ext = *list++))
		XPUSHs (sv_2mortal (newSVGChar (ext)));

GstCaps * gst_type_find_factory_get_caps (GstTypeFindFactory *factory);

# FIXME: Need GstTypeFind support.
# void gst_type_find_factory_call_function (GstTypeFindFactory *factory, GstTypeFind *find);
