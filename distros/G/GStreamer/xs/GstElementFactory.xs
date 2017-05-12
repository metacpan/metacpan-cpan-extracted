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

MODULE = GStreamer::ElementFactory	PACKAGE = GStreamer::ElementFactory	PREFIX = gst_element_factory_

# FIXME?
# gboolean gst_element_register (GstPlugin *plugin, const gchar *name, guint rank, GType type);

# GstElementFactory * gst_element_factory_find (const gchar *name);
GstElementFactory_ornull *
gst_element_factory_find (class, name)
	const gchar *name
    C_ARGS:
	name

# GType gst_element_factory_get_element_type (GstElementFactory *factory);
const char *
gst_element_factory_get_element_type (GstElementFactory *factory)
    CODE:
	RETVAL = gperl_package_from_type (gst_element_factory_get_element_type (factory));
    OUTPUT:
	RETVAL

const gchar * gst_element_factory_get_longname (GstElementFactory *factory);

const gchar * gst_element_factory_get_klass (GstElementFactory *factory);

const gchar * gst_element_factory_get_description (GstElementFactory *factory);

const gchar * gst_element_factory_get_author (GstElementFactory *factory);

# FIXME: Need GstStaticPadTemplate handlers.
# # guint gst_element_factory_get_num_pad_templates (GstElementFactory *factory);
# # const GList * gst_element_factory_get_static_pad_templates (GstElementFactory *factory);
# void
# gst_element_factory_get_static_pad_templates (factory)
# 	GstElementFactory *factory
#     PREINIT:
# 	GList *templates, *i;
#     PPCODE:
# 	templates = (GList *) gst_element_factory_get_static_pad_templates (factory);
# 	for (i = templates; i != NULL; i = i->next)
# 		XPUSHs (sv_2mortal (newSVGstPadTemplate (i->data)));

GstURIType gst_element_factory_get_uri_type (GstElementFactory *factory);

# gchar ** gst_element_factory_get_uri_protocols (GstElementFactory *factory);
void
gst_element_factory_get_uri_protocols (factory)
	GstElementFactory *factory
    PREINIT:
	gchar **uris;
    PPCODE:
	uris = gst_element_factory_get_uri_protocols (factory);
	if (uris) {
		gchar *uri;
		while ((uri = *(uris++)) != NULL)
		XPUSHs (sv_2mortal (newSVGChar (uri)));
	}

GstElement_ornull * gst_element_factory_create (GstElementFactory *factory, const gchar_ornull *name);

# GstElement * gst_element_factory_make (const gchar *factoryname, const gchar *name);
void
gst_element_factory_make (class, factoryname, name, ...);
	const gchar *factoryname
	const gchar *name
    PREINIT:
	int i;
    PPCODE:
	for (i = 1; i < items; i += 2)
		XPUSHs (
		  sv_2mortal (
		    newSVGstElement_ornull (
		      gst_element_factory_make (SvGChar (ST (i)),
		                                SvGChar (ST (i + 1))))));

# void __gst_element_factory_add_static_pad_template (GstElementFactory *elementfactory, GstStaticPadTemplate *templ);
# void __gst_element_factory_add_interface (GstElementFactory *elementfactory, const gchar *interfacename);

gboolean gst_element_factory_can_src_caps (GstElementFactory *factory, const GstCaps *caps);

gboolean gst_element_factory_can_sink_caps (GstElementFactory *factory, const GstCaps *caps);
