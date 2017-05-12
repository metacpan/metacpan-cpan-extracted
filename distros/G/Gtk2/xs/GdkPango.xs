/*
 * Copyright (c) 2005-2006 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

#define GTK2PERL_PANGO_ATTR_REGISTER_CUSTOM_TYPE(attr, package)	\
{								\
	static gboolean type_registered_already = FALSE;	\
	if (!type_registered_already) {				\
		gtk2perl_pango_attribute_register_custom_type	\
			((attr)->klass->type, package);		\
		type_registered_already = TRUE;			\
	}							\
}

#define GTK2PERL_PANGO_ATTR_STORE_INDICES(offset, attr)	\
	if (items == offset + 2) {			\
		guint start = SvUV (ST (offset));	\
		guint end = SvUV (ST (offset + 1));	\
		attr->start_index = start;		\
		attr->end_index = end;			\
	}

MODULE = Gtk2::Gdk::Pango	PACKAGE = Gtk2::Gdk::PangoRenderer	PREFIX = gdk_pango_renderer_

# We own the reference.
# PangoRenderer *gdk_pango_renderer_new (GdkScreen *screen);
PangoRenderer_noinc *
gdk_pango_renderer_new (class, screen)
	GdkScreen *screen
    C_ARGS:
	screen

# gtk+ owns the reference.
# PangoRenderer *gdk_pango_renderer_get_default (GdkScreen *screen);
PangoRenderer *
gdk_pango_renderer_get_default (class, screen)
	GdkScreen *screen
    C_ARGS:
	screen

void gdk_pango_renderer_set_drawable (GdkPangoRenderer *gdk_renderer, GdkDrawable_ornull *drawable);

void gdk_pango_renderer_set_gc (GdkPangoRenderer *gdk_renderer, GdkGC_ornull *gc);

void gdk_pango_renderer_set_stipple (GdkPangoRenderer *gdk_renderer, PangoRenderPart part, GdkBitmap_ornull *stipple);

void gdk_pango_renderer_set_override_color (GdkPangoRenderer *gdk_renderer, PangoRenderPart part, const GdkColor_ornull *color);

# FIXME: Do we need this?  The docs say to use gtk_widget_get_pango_context()
#        instead.
# PangoContext *gdk_pango_context_get_for_screen (GdkScreen *screen);

# FIXME: How to bind these?  Class static method or function?
# GdkRegion *gdk_pango_layout_line_get_clip_region (PangoLayoutLine *line, gint x_origin, gint y_origin, gint *index_ranges, gint n_ranges);
# GdkRegion *gdk_pango_layout_get_clip_region (PangoLayout *layout, gint x_origin, gint y_origin, gint *index_ranges, gint n_ranges);

# --------------------------------------------------------------------------- #

MODULE = Gtk2::Gdk::Pango	PACKAGE = Gtk2::Gdk::Pango::AttrStipple	PREFIX = gdk_pango_attr_stipple_

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Pango::AttrStipple", "Gtk2::Pango::Attribute");

PangoAttribute_own *
gdk_pango_attr_stipple_new (class, GdkBitmap_ornull *stipple, ...);
    C_ARGS:
	stipple
    POSTCALL:
	GTK2PERL_PANGO_ATTR_REGISTER_CUSTOM_TYPE (RETVAL, "Gtk2::Gdk::Pango::AttrStipple");
	GTK2PERL_PANGO_ATTR_STORE_INDICES (2, RETVAL);

GdkBitmap_noinc *
stipple (PangoAttribute * attr, ...)
    CODE:
	RETVAL = ((GdkPangoAttrStipple*) attr)->stipple;
	if (items > 1)
		((GdkPangoAttrStipple*) attr)->stipple =
			g_object_ref (SvGdkBitmap_ornull (ST (1)));
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Gtk2::Gdk::Pango	PACKAGE = Gtk2::Gdk::Pango::AttrEmbossed	PREFIX = gdk_pango_attr_embossed_

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Pango::AttrEmbossed", "Gtk2::Pango::Attribute");

PangoAttribute_own *
gdk_pango_attr_embossed_new (class, gboolean embossed, ...);
    C_ARGS:
	embossed
    POSTCALL:
	GTK2PERL_PANGO_ATTR_REGISTER_CUSTOM_TYPE (RETVAL, "Gtk2::Gdk::Pango::AttrEmbossed");
	GTK2PERL_PANGO_ATTR_STORE_INDICES (2, RETVAL);

gboolean
embossed (PangoAttribute * attr, ...)
    CODE:
	RETVAL = ((GdkPangoAttrEmbossed*) attr)->embossed;
	if (items > 1)
		((GdkPangoAttrEmbossed*) attr)->embossed = SvTRUE (ST (1));
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

#if GTK_CHECK_VERSION (2, 12, 0)

MODULE = Gtk2::Gdk::Pango	PACKAGE = Gtk2::Gdk::Pango::AttrEmbossColor	PREFIX = gdk_pango_attr_emboss_color_

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Pango::AttrEmbossColor", "Gtk2::Pango::Attribute");

PangoAttribute_own *
gdk_pango_attr_emboss_color_new (class, const GdkColor *color, ...);
    C_ARGS:
	color
    POSTCALL:
	GTK2PERL_PANGO_ATTR_REGISTER_CUSTOM_TYPE (RETVAL, "Gtk2::Gdk::Pango::AttrEmbossColor");
	GTK2PERL_PANGO_ATTR_STORE_INDICES (2, RETVAL);

PangoColor *
color (PangoAttribute * attr, ...)
    PREINIT:
	PangoColor color;
    CODE:
	color = ((GdkPangoAttrEmbossColor*) attr)->color;
	RETVAL = &color;
	if (items > 1)
		((GdkPangoAttrEmbossColor*) attr)->color = *((PangoColor *) SvPangoColor (ST (1)));
    OUTPUT:
	RETVAL

#endif
