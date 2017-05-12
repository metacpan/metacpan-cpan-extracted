/*
 * Copyright (c) 2003, 2010 by the gtk2-perl team (see the file AUTHORS)
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
#include "gperl_marshal.h"

/* ------------------------------------------------------------------------- */

GType
gtk2perl_gdk_region_get_type (void)
{
	static GType t = 0;
	if (!t)
		t = g_boxed_type_register_static ("GdkRegion",
		      (GBoxedCopyFunc) gdk_region_copy,
		      (GBoxedFreeFunc) gdk_region_destroy);
	return t;
}

/* ------------------------------------------------------------------------- */

static void
gtk2perl_gdk_span_func (GdkSpan *span,
                        GPerlCallback *callback)
{
	dGPERL_CALLBACK_MARSHAL_SP;
	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSViv (span->x)));
	PUSHs (sv_2mortal (newSViv (span->y)));
	PUSHs (sv_2mortal (newSViv (span->width)));
	if (callback->data)
		XPUSHs (sv_2mortal (newSVsv (callback->data)));

	PUTBACK;

	call_sv (callback->func, G_DISCARD);

	FREETMPS;
	LEAVE;
}

/* ------------------------------------------------------------------------- */

MODULE = Gtk2::Gdk::Region	PACKAGE = Gtk2::Gdk::Region	PREFIX = gdk_region_

##  GdkRegion *gdk_region_new (void) 
GdkRegion_own *
gdk_region_new (class)
    C_ARGS:
	/* void */

##  GdkRegion *gdk_region_polygon (GdkPoint *points, gint npoints, GdkFillRule fill_rule) 
GdkRegion_own *
gdk_region_polygon (class, points_ref, fill_rule)
	SV * points_ref
	GdkFillRule fill_rule
    PREINIT:
	GdkPoint *points = NULL;
	gint npoints, i;
	AV *array;
	SV **value;
    CODE:
	if (!gperl_sv_is_array_ref (points_ref))
		croak ("point list has to be a reference to an array");

	array = (AV *) SvRV (points_ref);
	npoints = (av_len (array) + 1) / 2;
	points = g_new0 (GdkPoint, npoints);

	for (i = 0; i < npoints; i++) {
		if ((value = av_fetch (array, 2*i, 0)) && gperl_sv_is_defined (*value))
			points[i].x = SvIV (*value);
		if ((value = av_fetch (array, 2*i + 1, 0)) && gperl_sv_is_defined (*value))
			points[i].y = SvIV (*value);
	}

	RETVAL = gdk_region_polygon (points, npoints, fill_rule);

	g_free (points);
    OUTPUT:
	RETVAL

##  GdkRegion *gdk_region_copy (GdkRegion *region) 

##  GdkRegion *gdk_region_rectangle (GdkRectangle *rectangle) 
GdkRegion_own *
gdk_region_rectangle (class, rectangle)
	GdkRectangle *rectangle
    C_ARGS:
	rectangle

##  void gdk_region_destroy (GdkRegion *region) 

##  void gdk_region_get_clipbox (GdkRegion *region, GdkRectangle *rectangle) 
GdkRectangle_copy *
gdk_region_get_clipbox (region)
	GdkRegion *region
    PREINIT:
	GdkRectangle rectangle;
    CODE:
	gdk_region_get_clipbox (region, &rectangle);
	RETVAL = &rectangle;
    OUTPUT:
	RETVAL

##  void gdk_region_get_rectangles (GdkRegion *region, GdkRectangle **rectangles, gint *n_rectangles) 
=for apidoc
Returns a list of rectangles (Gtk2::Gdk::Rectangle's), the area covered by the
region.
=cut
void
gdk_region_get_rectangles (region)
	GdkRegion *region
    PREINIT:
	GdkRectangle *rectangles = NULL;
	gint n_rectangles;
	int i;
    PPCODE:
	gdk_region_get_rectangles (region, &rectangles, &n_rectangles);
	EXTEND (SP, n_rectangles);
	for (i = 0 ; i < n_rectangles ; i++)
		PUSHs (sv_2mortal (newSVGdkRectangle_copy (rectangles + i)));
	g_free (rectangles);

##  gboolean gdk_region_empty (GdkRegion *region) 
gboolean
gdk_region_empty (region)
	GdkRegion *region

##  gboolean gdk_region_equal (GdkRegion *region1, GdkRegion *region2) 
gboolean
gdk_region_equal (region1, region2)
	GdkRegion *region1
	GdkRegion *region2

##  gboolean gdk_region_point_in (GdkRegion *region, int x, int y) 
gboolean
gdk_region_point_in (region, x, y)
	GdkRegion *region
	int x
	int y

##  GdkOverlapType gdk_region_rect_in (GdkRegion *region, GdkRectangle *rect) 
GdkOverlapType
gdk_region_rect_in (region, rect)
	GdkRegion *region
	GdkRectangle *rect

##  void gdk_region_offset (GdkRegion *region, gint dx, gint dy) 
void
gdk_region_offset (region, dx, dy)
	GdkRegion *region
	gint dx
	gint dy

##  void gdk_region_shrink (GdkRegion *region, gint dx, gint dy) 
void
gdk_region_shrink (region, dx, dy)
	GdkRegion *region
	gint dx
	gint dy

##  void gdk_region_union_with_rect (GdkRegion *region, GdkRectangle *rect) 
void
gdk_region_union_with_rect (region, rect)
	GdkRegion *region
	GdkRectangle *rect

##  void gdk_region_intersect (GdkRegion *source1, GdkRegion *source2) 
void
gdk_region_intersect (source1, source2)
	GdkRegion *source1
	GdkRegion *source2

##  void gdk_region_union (GdkRegion *source1, GdkRegion *source2) 
void
gdk_region_union (source1, source2)
	GdkRegion *source1
	GdkRegion *source2

##  void gdk_region_subtract (GdkRegion *source1, GdkRegion *source2) 
void
gdk_region_subtract (source1, source2)
	GdkRegion *source1
	GdkRegion *source2

##  void gdk_region_xor (GdkRegion *source1, GdkRegion *source2) 
void
gdk_region_xor (source1, source2)
	GdkRegion *source1
	GdkRegion *source2

##  void gdk_region_spans_intersect_foreach (GdkRegion *region, GdkSpan *spans, int n_spans, gboolean sorted, GdkSpanFunc function, gpointer data) 
=for arg spans_ref (scalar) arrayref of triples [$x1,$y1,$width1, $x2,$y2,$width2, ...]
=for apidoc
Call C<$function> for horizontal lines which intersect C<$region>.

C<$spans_ref> is an arrayref of x,y,width horizontal lines.  If
C<$sorted> is true then they're assumed to be sorted by increasing y
coordinate (allowing a single pass across the region rectangles).
C<$function> is called

    &$function ($x, $y, $width, $data)

for each portion of a span which intersects C<$region>.  C<$function>
must not change C<$region>.

    $region->spans_intersect_foreach ([ 0,0,50, 20,20,100, 0,10,50 ],
                                      0, # spans not sorted by y
                                      \&my_callback,
                                      'hello');  # userdata
    sub my_callback {
      my ($x, $y, $width, $userdata) = @_;
      print "$userdata: $x, $y, $width\n";
    }
=cut
void
gdk_region_spans_intersect_foreach (region, spans_ref, sorted, func, data=NULL)
	GdkRegion *region
	SV * spans_ref
	gboolean sorted
	SV * func
	SV * data
    PREINIT:
	GdkSpan *spans = NULL;
	int n_spans, i;
	AV *array;
	SV **value;
	GPerlCallback * callback;
    CODE:
	if (!gperl_sv_is_array_ref (spans_ref))
		croak ("span list must be an arrayref of triples [ $x,$y,$width,$x,$y,$width,...]");

	array = (AV *) SvRV (spans_ref);
	n_spans = av_len (array) + 1;
	if ((n_spans % 3) != 0)
		croak ("span list not a multiple of 3");
	n_spans /= 3;

	/* gdk_region_spans_intersect_foreach() is happy to take n_spans==0
	   and do nothing, but it doesn't like spans==NULL (as of Gtk 2.20),
	   and NULL is what g_new0() gives for a count of 0.  So explicit
	   skip if n_spans==0.  */
	if (n_spans != 0) {
		spans = g_new0 (GdkSpan, n_spans);

		for (i = 0; i < n_spans; i++) {
			if ((value = av_fetch (array, 3*i, 0)) && gperl_sv_is_defined (*value))
				spans[i].x = SvIV (*value);
			if ((value = av_fetch (array, 3*i + 1, 0)) && gperl_sv_is_defined (*value))
				spans[i].y = SvIV (*value);
			if ((value = av_fetch (array, 3*i + 2, 0)) && gperl_sv_is_defined (*value))
				spans[i].width = SvIV (*value);
		}

		callback = gperl_callback_new (func, data, 0, NULL, 0);

		gdk_region_spans_intersect_foreach (region,
		                                    spans,
		                                    n_spans,
		                                    sorted,
		                                    (GdkSpanFunc) gtk2perl_gdk_span_func,
		                                    callback);

		gperl_callback_destroy (callback);
		g_free (spans);
	}

#if GTK_CHECK_VERSION (2, 18, 0)

gboolean gdk_region_rect_equal (const GdkRegion *region, const GdkRectangle *rectangle);

#endif

