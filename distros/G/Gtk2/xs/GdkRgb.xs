/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
 * Boston, MA  02110-1301  USA.
 *
 * $Id$
 */
 #include "gtk2perl.h"

/*
####MODULE = Gtk2::Gdk::Rgb	PACKAGE = Gtk2::Gdk::Drawable	PREFIX = gdk_

 ## no longer does anything, no need to bind it
##  void gdk_rgb_init (void) 

 ## deprecated
##  gulong gdk_rgb_xpixel_from_rgb (guint32 rgb) G_GNUC_CONST 
*/

static guchar *
SvImageDataPointer (SV * sv)
{
	if (gperl_sv_is_defined (sv)) {
		if (SvIOK (sv))
			return INT2PTR (guchar*, SvUV (sv));
		else if (SvPOK (sv))
			return (guchar *) SvPV_nolen (sv);
	}
	croak ("expecting either a string containing pixel data or "
	       "an integer pointing to the underlying C image data "
	       "buffer");
	return NULL; /* not reached */
}

static GdkRgbCmap *
SvGdkRgbCmap (SV *sv)
{
	GdkRgbCmap *cmap = NULL;
	AV *av;
	int length, i;

	if (!gperl_sv_is_array_ref (sv))
		croak ("cmap must be an array reference");

	av = (AV *) SvRV (sv);
	length = av_len (av);

	if (length > 255)
		croak ("a cmap may not consist of more than 256 colors");

	cmap = gperl_alloc_temp (sizeof (GdkRgbCmap));
	cmap->n_colors = length + 1;

	for (i = 0; i <= length; i++) {
		SV **color = av_fetch (av, i, 0);
		if (color && gperl_sv_is_defined (*color))
			cmap->colors[i] = SvIV (*color);
	}

	return cmap;
}

MODULE = Gtk2::Gdk::Rgb	PACKAGE = Gtk2::Gdk::GC	PREFIX = gdk_

##  void gdk_rgb_gc_set_foreground (GdkGC *gc, guint32 rgb) 
void gdk_rgb_gc_set_foreground (GdkGC * gc, guint32 rgb)
    ALIAS:
	Gtk2::Gdk::GC::set_rgb_foreground = 1
    CLEANUP:
	PERL_UNUSED_VAR (ix);

##  void gdk_rgb_gc_set_background (GdkGC *gc, guint32 rgb) 
void gdk_rgb_gc_set_background (GdkGC * gc, guint32 rgb)
    ALIAS:
	Gtk2::Gdk::GC::set_rgb_background = 1
    CLEANUP:
	PERL_UNUSED_VAR (ix);

MODULE = Gtk2::Gdk::Rgb	PACKAGE = Gtk2::Gdk::Colormap	PREFIX = gdk_

##  void gdk_rgb_find_color (GdkColormap *colormap, GdkColor *color) 
void gdk_rgb_find_color (GdkColormap *colormap, GdkColor *color)

MODULE = Gtk2::Gdk::Rgb	PACKAGE = Gtk2::Gdk::Drawable	PREFIX = gdk_

##  void gdk_draw_rgb_image (GdkDrawable *drawable, GdkGC *gc, gint x, gint y, gint width, gint height, GdkRgbDither dith, guchar *rgb_buf, gint rowstride) 
##  void gdk_draw_rgb_32_image (GdkDrawable *drawable, GdkGC *gc, gint x, gint y, gint width, gint height, GdkRgbDither dith, guchar *buf, gint rowstride) 
##  void gdk_draw_gray_image (GdkDrawable *drawable, GdkGC *gc, gint x, gint y, gint width, gint height, GdkRgbDither dith, guchar *buf, gint rowstride) 
void
gdk_draw_rgb_image (drawable, gc, x, y, width, height, dith, buf, rowstride)
	GdkDrawable *drawable
	GdkGC *gc
	gint x
	gint y
	gint width
	gint height
	GdkRgbDither dith
	SV * buf
	gint rowstride
    ALIAS:
	draw_rgb_32_image = 1
	draw_gray_image = 2
    CODE:
	switch (ix) {
	    case 0:
		gdk_draw_rgb_image (drawable, gc, x, y, width, height,
		                    dith, SvImageDataPointer(buf),
		                    rowstride);
		break;
	    case 1:
		gdk_draw_rgb_32_image (drawable, gc, x, y, width, height,
		                       dith, SvImageDataPointer(buf),
		                       rowstride);
		break;
	    case 2:
		gdk_draw_gray_image (drawable, gc, x, y, width, height,
		                     dith, SvImageDataPointer(buf),
		                     rowstride);
		break;
	    default:
		g_assert_not_reached ();
	}

##  void gdk_draw_rgb_image_dithalign (GdkDrawable *drawable, GdkGC *gc, gint x, gint y, gint width, gint height, GdkRgbDither dith, guchar *rgb_buf, gint rowstride, gint xdith, gint ydith) 
##  void gdk_draw_rgb_32_image_dithalign (GdkDrawable *drawable, GdkGC *gc, gint x, gint y, gint width, gint height, GdkRgbDither dith, guchar *buf, gint rowstride, gint xdith, gint ydith) 
void
gdk_draw_rgb_image_dithalign (drawable, gc, x, y, width, height, dith, rgb_buf, rowstride, xdith, ydith)
	GdkDrawable *drawable
	GdkGC *gc
	gint x
	gint y
	gint width
	gint height
	GdkRgbDither dith
	SV *rgb_buf
	gint rowstride
	gint xdith
	gint ydith
    ALIAS:
	draw_rgb_32_image_dithalign = 1
    CODE:
	if (ix == 1)
		gdk_draw_rgb_32_image_dithalign (drawable, gc, x, y,
		                                 width, height, dith,
		                                 SvImageDataPointer (rgb_buf),
		                                 rowstride, xdith, ydith);
	else
		gdk_draw_rgb_image_dithalign (drawable, gc, x, y,
		                              width, height, dith,
		                              SvImageDataPointer(rgb_buf),
		                              rowstride, xdith, ydith);

##  void gdk_draw_indexed_image (GdkDrawable *drawable, GdkGC *gc, gint x, gint y, gint width, gint height, GdkRgbDither dith, guchar *buf, gint rowstride, GdkRgbCmap *cmap) 
void
gdk_draw_indexed_image (drawable, gc, x, y, width, height, dith, buf, rowstride, cmap)
	GdkDrawable *drawable
	GdkGC *gc
	gint x
	gint y
	gint width
	gint height
	GdkRgbDither dith
	SV *buf
	gint rowstride
	SV *cmap
    CODE:
	gdk_draw_indexed_image (drawable,
	                        gc,
	                        x,
	                        y,
	                        width,
	                        height,
	                        dith,
	                        SvImageDataPointer (buf),
	                        rowstride,
	                        SvGdkRgbCmap (cmap));

MODULE = Gtk2::Gdk::Rgb	PACKAGE = Gtk2::Gdk::Rgb	PREFIX = gdk_rgb_

##  void gdk_rgb_set_verbose (gboolean verbose) 
void
gdk_rgb_set_verbose (class, verbose)
	gboolean verbose
    C_ARGS:
	verbose

##  void gdk_rgb_set_install (gboolean install) 
void
gdk_rgb_set_install (class, install)
	gboolean install
    C_ARGS:
	install

##  void gdk_rgb_set_min_colors (gint min_colors) 
void
gdk_rgb_set_min_colors (class, min_colors)
	gint min_colors
    C_ARGS:
	min_colors

 ## no longer needed
##  GdkColormap *gdk_rgb_get_colormap (void) 
##  GdkVisual * gdk_rgb_get_visual (void) 

##  gboolean gdk_rgb_ditherable (void) 
gboolean
gdk_rgb_ditherable (class)
    C_ARGS:
	/*void*/

#if GTK_CHECK_VERSION (2, 6, 0)

##  gboolean gdk_rgb_colormap_ditherable (GdkColormap *cmap);
gboolean
gdk_rgb_colormap_ditherable (class, cmap)
	GdkColormap *cmap
    C_ARGS:
	cmap

#endif
