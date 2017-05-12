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
 * GdkGCValues code ported from Gtk-Perl 0.7009.  There's no boxed type
 * support for this structure, but since it's only used in a couple of
 * functions in this file, we can scrape by without typemaps.
 */
SV *
newSVGdkGCValues (GdkGCValues * v)
{
	HV * h;
	SV * r;

	if (!v)
		return newSVsv (&PL_sv_undef);

	h = newHV ();
	r = newRV_noinc ((SV*)h);

	gperl_hv_take_sv_s (h, "foreground", newSVGdkColor_copy (&v->foreground));
	gperl_hv_take_sv_s (h, "background", newSVGdkColor_copy (&v->background));
	if (v->font) gperl_hv_take_sv_s (h, "font", newSVGdkFont (v->font));
	gperl_hv_take_sv_s (h, "function", newSVGdkFunction (v->function));
	gperl_hv_take_sv_s (h, "fill", newSVGdkFill (v->fill));
	if (v->tile) gperl_hv_take_sv_s (h, "tile", newSVGdkPixmap (v->tile));
	if (v->stipple) gperl_hv_take_sv_s (h, "stipple", newSVGdkPixmap (v->stipple));
	if (v->clip_mask) gperl_hv_take_sv_s (h, "clip_mask", newSVGdkPixmap (v->clip_mask));
	gperl_hv_take_sv_s (h, "subwindow_mode", newSVGdkSubwindowMode (v->subwindow_mode));
	gperl_hv_take_sv_s (h, "ts_x_origin", newSViv (v->ts_x_origin));
	gperl_hv_take_sv_s (h, "ts_y_origin", newSViv (v->ts_y_origin));
	gperl_hv_take_sv_s (h, "clip_x_origin", newSViv (v->clip_x_origin));
	gperl_hv_take_sv_s (h, "clip_y_origin", newSViv (v->clip_y_origin));
	gperl_hv_take_sv_s (h, "graphics_exposures", newSViv (v->graphics_exposures));
	gperl_hv_take_sv_s (h, "line_width", newSViv (v->line_width));
	gperl_hv_take_sv_s (h, "line_style", newSVGdkLineStyle (v->line_style));
	gperl_hv_take_sv_s (h, "cap_style", newSVGdkCapStyle (v->cap_style));
	gperl_hv_take_sv_s (h, "join_style", newSVGdkJoinStyle (v->join_style));

	return r;
}

void
SvGdkGCValues (SV * data, GdkGCValues * v, GdkGCValuesMask * m)
{
	HV * h;
	SV ** s;
	GdkGCValuesMask mask = 0;

	if (!gperl_sv_is_hash_ref (data))
		return;

	h = (HV*) SvRV (data);

	if (!v)
		v = gperl_alloc_temp (sizeof(GdkGCValues));

	if ((s=hv_fetch (h, "foreground", 10, 0)) && gperl_sv_is_defined (*s)) {
		v->foreground = *((GdkColor*) SvGdkColor (*s));
		mask |= GDK_GC_FOREGROUND;
	}
	if ((s=hv_fetch (h, "background", 10, 0)) && gperl_sv_is_defined (*s)) {
		v->background = *((GdkColor*) SvGdkColor (*s));
		mask |= GDK_GC_BACKGROUND;
	}
	if ((s=hv_fetch (h, "font", 4, 0)) && gperl_sv_is_defined (*s)) {
		v->font = SvGdkFont (*s);
		mask |= GDK_GC_FONT;
	}
	if ((s=hv_fetch (h, "function", 8, 0)) && gperl_sv_is_defined (*s)) {
		v->function = SvGdkFunction (*s);
		mask |= GDK_GC_FUNCTION;
	}
	if ((s=hv_fetch (h, "fill", 4, 0)) && gperl_sv_is_defined (*s)) {
		v->fill = SvGdkFill (*s);
		mask |= GDK_GC_FILL;
	}
	if ((s=hv_fetch (h, "tile", 4, 0)) && gperl_sv_is_defined (*s)) {
		v->tile = SvGdkPixmap (*s);
		mask |= GDK_GC_TILE;
	}
	if ((s=hv_fetch (h, "stipple", 7, 0)) && gperl_sv_is_defined (*s)) {
		v->stipple = SvGdkPixmap (*s);
		mask |= GDK_GC_STIPPLE;
	}
	if ((s=hv_fetch (h, "clip_mask", 9, 0)) && gperl_sv_is_defined (*s)) {
		v->clip_mask = SvGdkPixmap (*s);
		mask |= GDK_GC_CLIP_MASK;
	}
	if ((s=hv_fetch (h, "subwindow_mode", 14, 0)) && gperl_sv_is_defined (*s)) {
		v->subwindow_mode = SvGdkSubwindowMode (*s);
		mask |= GDK_GC_SUBWINDOW;
	}
	if ((s=hv_fetch (h, "ts_x_origin", 11, 0)) && gperl_sv_is_defined (*s)) {
		v->ts_x_origin = SvIV (*s);
		mask |= GDK_GC_TS_X_ORIGIN;
	}
	if ((s=hv_fetch (h, "ts_y_origin", 11, 0)) && gperl_sv_is_defined (*s)) {
		v->ts_y_origin = SvIV (*s);
		mask |= GDK_GC_TS_Y_ORIGIN;
	}
	if ((s=hv_fetch (h, "clip_x_origin", 13, 0)) && gperl_sv_is_defined (*s)) {
		v->clip_x_origin = SvIV (*s);
		mask |= GDK_GC_CLIP_X_ORIGIN;
	}
	if ((s=hv_fetch (h, "clip_y_origin", 13, 0)) && gperl_sv_is_defined (*s)) {
		v->clip_y_origin = SvIV (*s);
		mask |= GDK_GC_CLIP_Y_ORIGIN;
	}
	if ((s=hv_fetch (h, "graphics_exposures", 18, 0)) && gperl_sv_is_defined (*s)) {
		v->graphics_exposures = SvIV (*s);
		mask |= GDK_GC_EXPOSURES;
	}
	if ((s=hv_fetch (h, "line_width", 10, 0)) && gperl_sv_is_defined (*s)) {
		v->line_width= SvIV (*s);
		mask |= GDK_GC_LINE_WIDTH;
	}
	if ((s=hv_fetch (h, "line_style", 10, 0)) && gperl_sv_is_defined (*s)) {
		v->line_style= SvGdkLineStyle (*s);
		mask |= GDK_GC_LINE_STYLE;
	}
	if ((s=hv_fetch (h, "cap_style", 9, 0)) && gperl_sv_is_defined (*s)) {
		v->cap_style = SvGdkCapStyle (*s);
		mask |= GDK_GC_CAP_STYLE;
	}
	if ((s=hv_fetch (h, "join_style", 10, 0)) && gperl_sv_is_defined (*s)) {
		v->join_style = SvGdkJoinStyle (*s);
		mask |= GDK_GC_JOIN_STYLE;
	}

	if (m)
		*m = mask;
}

MODULE = Gtk2::Gdk::GC	PACKAGE = Gtk2::Gdk::GC	PREFIX = gdk_gc_

BOOT:
	/* the gdk backends override the public GdkGC with private,
	 * back-end-specific types.  tell gperl_get_object not to
	 * complain about them.  */
	gperl_object_set_no_warn_unreg_subclass (GDK_TYPE_GC, TRUE);



 ## taken care of by typemaps
 ## void gdk_gc_unref (GdkGC *gc)

 ##GdkGC * gdk_gc_new (GdkDrawable * drawable);
 ##GdkGC * gdk_gc_new_with_values (GdkDrawable * drawable, GdkGCValues * values);
=for apidoc
Create and return a new GC.

C<$drawable> is used for the depth and the display
(C<Gtk2::Gdk::Display>) for the GC.  The GC can then be used with any
drawable of the same depth on that display.

C<$values> is a hashref containing some of the following keys,

    foreground          Gtk2::Gdk::Color
    background          Gtk2::Gdk::Color
    font                Gtk2::Gdk::Font
    function            Gtk2::Gdk::Function enum
    fill                Gtk2::Gdk::Fill enum
    tile                Gtk2::Gdk::Pixmap
    stipple             Gtk2::Gdk::Pixmap
    clip_mask           Gtk2::Gdk::Pixmap
    subwindow_mode      Gtk2::Gdk::SubwindowMode enum
    ts_x_origin         integer
    ts_y_origin         integer
    clip_x_origin       integer
    clip_y_origin       integer
    graphics_exposures  boolean integer 1 or 0
    line_width          integer
    line_style          Gtk2::Gdk::LineStyle enum
    cap_style           Gtk2::Gdk::CapStyle enum
    join_style          Gtk2::Gdk::JoinStyle enum

Keys not given get default values.  For the C<foreground> and
C<background> colour objects only the C<pixel> field is used; the red,
green and blue are ignored.  For example

    my $pixel = 0x123456;
    my $color = Gtk2::Gdk::Color->new (0,0,0, $pixel);
    my $gc = Gtk2::Gdk::GC->new_with_values
      ($win, { foreground => $color,
               line_style => 'on_off_dash' });

=cut
GdkGC_noinc*
gdk_gc_new (class, GdkDrawable * drawable, SV * values=NULL)
    ALIAS:
	new_with_values = 1
    CODE:
	if (gperl_sv_is_defined (values)) {
		GdkGCValuesMask m;
		GdkGCValues v;
		SvGdkGCValues (values, &v, &m);
		RETVAL = gdk_gc_new_with_values (drawable, &v, m);
	} else {
		if (ix == 1)
			warn ("passed empty values to new_with_values");
		RETVAL = gdk_gc_new (drawable);
	}
    OUTPUT:
	RETVAL


# ## void gdk_gc_get_values (GdkGC *gc, GdkGCValues *values)
=for apidoc
Return the attributes of C<$gc> in the form of a hashref with keys and
values as described with C<new> above.

In the C<foreground> and C<background> colour objects returned only
the C<pixel> fields are set; the red, green and blue fields are
garbage.
=cut
SV *
gdk_gc_get_values (gc)
	GdkGC *gc
    PREINIT:
	GdkGCValues values;
    CODE:
	gdk_gc_get_values (gc, &values);
	RETVAL = newSVGdkGCValues (&values);
    OUTPUT:
	RETVAL

 ## void gdk_gc_set_values (GdkGC *gc, GdkGCValues *values, GdkGCValuesMask values_mask)
=for apidoc
Set some of the attributes of C<$gc>.  C<$values> is a hashref of keys
and values as described for C<new> and C<new_with_values> above.
Fields not present in C<$values> are left unchanged.
=cut
void
gdk_gc_set_values (gc, values)
	GdkGC *gc
	SV *values
    PREINIT:
	GdkGCValues v;
	GdkGCValuesMask m;
    CODE:
	SvGdkGCValues (values, &v, &m);
	gdk_gc_set_values (gc, &v, m);

 ## void gdk_gc_set_foreground (GdkGC *gc, GdkColor *color)
void
gdk_gc_set_foreground (gc, color)
	GdkGC *gc
	GdkColor *color

 ## void gdk_gc_set_background (GdkGC *gc, GdkColor *color)
void
gdk_gc_set_background (gc, color)
	GdkGC *gc
	GdkColor *color

 ## void gdk_gc_set_font (GdkGC *gc, GdkFont *font)
void
gdk_gc_set_font (gc, font)
	GdkGC *gc
	GdkFont *font

 ## void gdk_gc_set_function (GdkGC *gc, GdkFunction function)
void
gdk_gc_set_function (gc, function)
	GdkGC *gc
	GdkFunction function

 ## void gdk_gc_set_fill (GdkGC *gc, GdkFill fill)
void
gdk_gc_set_fill (gc, fill)
	GdkGC *gc
	GdkFill fill

 ## void gdk_gc_set_tile (GdkGC *gc, GdkPixmap *tile)
void
gdk_gc_set_tile (gc, tile)
	GdkGC *gc
	GdkPixmap *tile

 ## void gdk_gc_set_stipple (GdkGC *gc, GdkPixmap *stipple)
void
gdk_gc_set_stipple (gc, stipple)
	GdkGC *gc
	GdkPixmap *stipple

 ## void gdk_gc_set_ts_origin (GdkGC *gc, gint x, gint y)
void
gdk_gc_set_ts_origin (gc, x, y)
	GdkGC *gc
	gint x
	gint y

 ## void gdk_gc_set_clip_origin (GdkGC *gc, gint x, gint y)
void
gdk_gc_set_clip_origin (gc, x, y)
	GdkGC *gc
	gint x
	gint y

 ## void gdk_gc_set_clip_mask (GdkGC *gc, GdkBitmap *mask)
void
gdk_gc_set_clip_mask (gc, mask)
	GdkGC *gc
	SV *mask
    CODE:
	gdk_gc_set_clip_mask (gc, SvGdkBitmap_ornull (mask));

 ## void gdk_gc_set_clip_rectangle (GdkGC *gc, GdkRectangle *rectangle)
void
gdk_gc_set_clip_rectangle (gc, rectangle)
	GdkGC *gc
	GdkRectangle_ornull *rectangle

 ## void gdk_gc_set_clip_region (GdkGC *gc, GdkRegion *region)
void
gdk_gc_set_clip_region (gc, region)
	GdkGC *gc
	GdkRegion_ornull *region

 ## void gdk_gc_set_subwindow (GdkGC *gc, GdkSubwindowMode mode)
void
gdk_gc_set_subwindow (gc, mode)
	GdkGC *gc
	GdkSubwindowMode mode

 ## void gdk_gc_set_exposures (GdkGC *gc, gboolean exposures)
void
gdk_gc_set_exposures (gc, exposures)
	GdkGC *gc
	gboolean exposures

 ## void gdk_gc_set_line_attributes (GdkGC *gc, gint line_width, GdkLineStyle line_style, GdkCapStyle cap_style, GdkJoinStyle join_style)
void
gdk_gc_set_line_attributes (gc, line_width, line_style, cap_style, join_style)
	GdkGC *gc
	gint line_width
	GdkLineStyle line_style
	GdkCapStyle cap_style
	GdkJoinStyle join_style

 ## void gdk_gc_set_dashes (GdkGC *gc, gint dash_offset, gint8 dash_list[], gint n)
=for apidoc
=for arg ... of integers, the length of the dash segments
Sets the way dashed-lines are drawn. Lines will be drawn with alternating on
and off segments of the lengths specified in list of dashes. The manner in
which the on and off segments are drawn is determined by the line_style value
of the GC.
=cut
void
gdk_gc_set_dashes (gc, dash_offset, ...)
	GdkGC * gc
	gint    dash_offset
    PREINIT:
	gint8 * dash_list;
	gint    n;
    CODE:
	n = --items-1;
	dash_list = g_new(gint8, n);
	for( ; items > 1; items-- )
		dash_list[items-2] = (gint8) SvIV(ST(items));
	gdk_gc_set_dashes(gc, dash_offset, dash_list, n);
	g_free(dash_list);

 ## void gdk_gc_offset (GdkGC *gc, gint x_offset, gint y_offset)
void
gdk_gc_offset (gc, x_offset, y_offset)
	GdkGC *gc
	gint x_offset
	gint y_offset

 ## void gdk_gc_copy (GdkGC *dst_gc, GdkGC *src_gc)
void
gdk_gc_copy (dst_gc, src_gc)
	GdkGC *dst_gc
	GdkGC *src_gc

 ## void gdk_gc_set_colormap (GdkGC *gc, GdkColormap *colormap)
void
gdk_gc_set_colormap (gc, colormap)
	GdkGC *gc
	GdkColormap *colormap

 ##  GdkColormap *colormap gdk_gc_get_colormap (GdkGC *gc)
GdkColormap *
gdk_gc_get_colormap (gc)
	GdkGC *gc

 ## void gdk_gc_set_rgb_fg_color (GdkGC *gc, GdkColor *color)
void
gdk_gc_set_rgb_fg_color (gc, color)
	GdkGC *gc
	GdkColor *color

 ## void gdk_gc_set_rgb_bg_color (GdkGC *gc, GdkColor *color)
void
gdk_gc_set_rgb_bg_color (gc, color)
	GdkGC *gc
	GdkColor *color

#if GTK_CHECK_VERSION(2,2,0)

 ## GdkScreen * gdk_gc_get_screen (GdkGC *gc)
GdkScreen *
gdk_gc_get_screen (gc)
	GdkGC *gc

#endif /* have GdkScreen */
