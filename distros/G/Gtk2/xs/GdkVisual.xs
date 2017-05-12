/*
 * Copyright (c) 2004 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::Gdk::Visual	PACKAGE = Gtk2::Gdk	PREFIX = gdk_

=for apidoc
Returns a list of depths.
=cut
## void gdk_query_depths (gint **depths, gint *count)
void
gdk_query_depths (class)
    PREINIT:
	gint *depths = NULL;
	gint i, count = 0;
    PPCODE:
	gdk_query_depths (&depths, &count);

	if (count <= 0 || depths == NULL)
		XSRETURN_EMPTY;

	EXTEND (sp, count);

	for (i = 0; i < count; i++)
		PUSHs (sv_2mortal (newSViv (depths[i])));

## void gdk_query_visual_types (GdkVisualType **visual_types, gint *count)
void
gdk_query_visual_types (class)
    PREINIT:
	GdkVisualType *visual_types = NULL;
	gint i, count = 0;
    PPCODE:
	gdk_query_visual_types (&visual_types, &count);

	if (count <= 0 || visual_types == NULL)
		XSRETURN_EMPTY;

	EXTEND (sp, count);

	for (i = 0; i < count; i++)
		PUSHs (sv_2mortal (newSVGdkVisualType (visual_types[i])));

## GList* gdk_list_visuals (void)
void
gdk_list_visuals (class)
    PREINIT:
	GList *i, *visuals = NULL;
    PPCODE:
	PERL_UNUSED_VAR (ax);
	visuals = gdk_list_visuals ();
	for (i = visuals; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGdkVisual (i->data)));
	g_list_free (visuals);

MODULE = Gtk2::Gdk::Visual	PACKAGE = Gtk2::Gdk::Visual	PREFIX = gdk_visual_

## gint gdk_visual_get_best_depth (void)
gint
gdk_visual_get_best_depth (class)
    C_ARGS:
	/* void */

## GdkVisualType gdk_visual_get_best_type (void)
GdkVisualType
gdk_visual_get_best_type (class)
    C_ARGS:
	/* void */

## GdkVisual* gdk_visual_get_system (void)
GdkVisual*
gdk_visual_get_system (class)
    C_ARGS:
	/* void */

## GdkVisual* gdk_visual_get_best (void)
GdkVisual*
gdk_visual_get_best (class)
    C_ARGS:
	/* void */

## GdkVisual* gdk_visual_get_best_with_depth (gint depth)
GdkVisual_ornull*
gdk_visual_get_best_with_depth (class, depth)
	gint depth
    C_ARGS:
	depth

## GdkVisual* gdk_visual_get_best_with_type (GdkVisualType visual_type)
GdkVisual_ornull*
gdk_visual_get_best_with_type (class, visual_type)
	GdkVisualType visual_type
    C_ARGS:
	visual_type

## GdkVisual* gdk_visual_get_best_with_both (gint depth, GdkVisualType visual_type)
GdkVisual_ornull*
gdk_visual_get_best_with_both (class, depth, visual_type)
	gint depth
	GdkVisualType visual_type
    C_ARGS:
	depth, visual_type

#if GTK_CHECK_VERSION(2, 2, 0)

## GdkScreen* gdk_visual_get_screen (GdkVisual *visual)
GdkScreen*
gdk_visual_get_screen (visual)
	GdkVisual *visual

#endif

# --------------------------------------------------------------------------- #

GdkVisualType
type (visual)
	GdkVisual *visual
    CODE:
	RETVAL = visual->type;
    OUTPUT:
	RETVAL

GdkByteOrder
byte_order (visual)
	GdkVisual *visual
    CODE:
	RETVAL = visual->byte_order;
    OUTPUT:
	RETVAL

gint
depth (visual)
	GdkVisual *visual
    ALIAS:
	colormap_size = 1
	bits_per_rgb = 2
	red_shift = 3
	red_prec = 4
	green_shift = 5
	green_prec = 6
	blue_shift = 7
	blue_prec = 8
    CODE:
	RETVAL = 0; /* -W */
	switch (ix) {
		case 0: RETVAL = visual->depth; break;
		case 1: RETVAL = visual->colormap_size; break;
		case 2: RETVAL = visual->bits_per_rgb; break;
		case 3: RETVAL = visual->red_shift; break;
		case 4: RETVAL = visual->red_prec; break;
		case 5: RETVAL = visual->green_shift; break;
		case 6: RETVAL = visual->green_prec; break;
		case 7: RETVAL = visual->blue_shift; break;
		case 8: RETVAL = visual->blue_prec; break;
		default: g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

guint32
red_mask (visual)
	GdkVisual *visual
    ALIAS:
	green_mask = 1
	blue_mask = 2
    CODE:
	RETVAL = 0; /* -W */
	switch (ix) {
		case 0: RETVAL = visual->red_mask; break;
		case 1: RETVAL = visual->green_mask; break;
		case 2: RETVAL = visual->blue_mask; break;
		default: g_assert_not_reached();
	}
    OUTPUT:
	RETVAL

#if GTK_CHECK_VERSION (2, 22, 0)

void gdk_visual_get_blue_pixel_details (GdkVisual *visual, OUTLIST guint32 mask, OUTLIST gint shift, OUTLIST gint precision);

void gdk_visual_get_green_pixel_details (GdkVisual *visual, OUTLIST guint32 mask, OUTLIST gint shift, OUTLIST gint precision);

void gdk_visual_get_red_pixel_details (GdkVisual *visual, OUTLIST guint32 mask, OUTLIST gint shift, OUTLIST gint precision);

gint gdk_visual_get_bits_per_rgb (GdkVisual *visual);

GdkByteOrder gdk_visual_get_byte_order (GdkVisual *visual);

gint gdk_visual_get_colormap_size (GdkVisual *visual);

gint gdk_visual_get_depth (GdkVisual *visual);

GdkVisualType gdk_visual_get_visual_type (GdkVisual *visual);

#endif /* 2.22 */
