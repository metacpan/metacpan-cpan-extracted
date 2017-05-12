/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
 * Boston, MA  02111-1307  USA.
 *
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/GnomeCanvas/xs/GnomeCanvasUtil.xs,v 1.7 2004/08/16 02:03:12 muppetman Exp $
 */
#include "gnomecanvasperl.h"

static SV*      gnomecanvasperl_points_wrap    (GType        gtype,
                                                const char * package,
                                                gpointer     boxed,
                                                gboolean     own);
static gpointer gnomecanvasperl_points_unwrap  (GType        gtype,
                                                const char * package,
                                                SV         * sv);

static GPerlBoxedWrapperClass point_wrapper_class = {
	gnomecanvasperl_points_wrap,
	gnomecanvasperl_points_unwrap,
	NULL
};

static SV*
gnomecanvasperl_points_wrap    (GType        gtype,
                                const char * package,
                                gpointer     boxed,
                                gboolean     own)
{
	AV * av;
	int i;
	GnomeCanvasPoints * points;

	if (!boxed)
		return &PL_sv_undef;

	points = (GnomeCanvasPoints*) boxed;

	av = newAV ();

	for (i = 0; i < points->num_points * 2 ; i++)
		av_push (av, newSVnv (points->coords[i]));

	if (own)
		g_boxed_free (gtype, boxed);

	return newRV_noinc ((SV*)av);
}

static gpointer
gnomecanvasperl_points_unwrap  (GType        gtype,
                                const char * package,
                                SV         * sv)
{
	GnomeCanvasPoints * points;
	AV * av;
	int i, n;

	if (!sv || !SvROK (sv) || SvTYPE (SvRV (sv)) != SVt_PVAV)
		return NULL;

	av = (AV*) SvRV (sv);
	n = av_len (av) + 1;

	points = gperl_alloc_temp (sizeof (GnomeCanvasPoints));
	points->ref_count = 1;
	points->num_points = n / 2;
	points->coords = gperl_alloc_temp (sizeof (double) * n);

	for (i = 0 ; i < n ; i++) {
		SV ** svp = av_fetch (av, i, FALSE);
		points->coords[i] = svp ? SvNV (*svp) : 0.0;
	}

	return points;
}


MODULE = Gnome2::Canvas::Util	PACKAGE = Gnome2::Canvas::Points	PREFIX = gnome_canvas_points_

BOOT:
	/* override default wrapper implementation for GnomeCanvasPoints */
	gperl_register_boxed (GNOME_TYPE_CANVAS_POINTS,
	                      "Gnome2::Canvas::Points",
	                      &point_wrapper_class);

 ## not needed
###  GnomeCanvasPoints *gnome_canvas_points_new (int num_points) 
###  GnomeCanvasPoints *gnome_canvas_points_ref (GnomeCanvasPoints *points) 
###  void gnome_canvas_points_free (GnomeCanvasPoints *points) 

MODULE = Gnome2::Canvas::Util	PACKAGE = Gnome2::Canvas	PREFIX = gnome_canvas_

##  int gnome_canvas_get_miter_points (double x1, double y1, double x2, double y2, double x3, double y3, double width, double *mx1, double *my1, double *mx2, double *my2) 
=for apidoc
=for signature ($mx1, $my1, $mx2, $my2) = Gnome2::Canvas->get_miter_points ($x1, $y1, $x2, $y2, $x3, $y3, $width)
=cut
void
gnome_canvas_get_miter_points (class, x1, y1, x2, y2, x3, y3, width)
	double x1
	double y1
	double x2
	double y2
	double x3
	double y3
	double width
    PREINIT:
	double mx1, my1, mx2, my2;
    PPCODE:
	if (!gnome_canvas_get_miter_points (x1, y1, x2, y2, x3, y3, width,
	                                    &mx1, &my1, &mx2, &my2))
		XSRETURN_EMPTY;
	EXTEND (SP, 4);
	PUSHs (sv_2mortal (newSVnv (mx1)));
	PUSHs (sv_2mortal (newSVnv (my1)));
	PUSHs (sv_2mortal (newSVnv (mx2)));
	PUSHs (sv_2mortal (newSVnv (my2)));

##  void gnome_canvas_get_butt_points (double x1, double y1, double x2, double y2, double width, int project, double *bx1, double *by1, double *bx2, double *by2) 
=for apidoc
=for signature ($bx1, $by1, $bx2, $by2) = Gnome2::Canvas->get_butt_points ($x1, $y1, $x2, $y2, $width, $project)
=cut
void
gnome_canvas_get_butt_points (class, x1, y1, x2, y2, width, project)
	double x1
	double y1
	double x2
	double y2
	double width
	int project
    PREINIT:
	double bx1, by1, bx2, by2;
    PPCODE:
	gnome_canvas_get_butt_points (x1, y1, x2, y2, width, project,
	                              &bx1, &by1, &bx2, &by2);
	EXTEND (SP, 4);
	PUSHs (sv_2mortal (newSVnv (bx1)));
	PUSHs (sv_2mortal (newSVnv (by1)));
	PUSHs (sv_2mortal (newSVnv (bx2)));
	PUSHs (sv_2mortal (newSVnv (by2)));

##  double gnome_canvas_polygon_to_point (double *poly, int num_points, double x, double y) 
=for apidoc
=for arg poly_ref (arrayref) coordinate pairs that make up the polygon
Return the distance from the point I<$x>,I<$y> to the polygon described by
the vertices in I<$poly_ref>, or zero if the point is inside the polygon.
=cut
double
gnome_canvas_polygon_to_point (class, poly_ref, x, y)
	SV *poly_ref
	double x
	double y
    PREINIT:
	double *poly;
	AV *array;
	int length, i;
    CODE:
	if (! (SvRV (poly_ref) && SvTYPE (SvRV (poly_ref)) == SVt_PVAV))
		croak ("the polygon parameter should be a reference to an "
		       "array of coordinate pairs");

	array = (AV *) SvRV (poly_ref);
	length = av_len (array) + 1;

	if (length % 2 != 0)
		croak ("the polygon array must contain x,y coordinate pairs,"
		       " so its length cannot be odd (got %d)", length);

	poly = g_new0 (double, length);

	for (i = 0; i < length; i += 2) {
		SV **value;
		value = av_fetch (array, i, 0);
		if (value && SvOK (*value))
			poly[i] = SvNV (*value);

		value = av_fetch (array, i + 1, 0);
		if (value && SvOK (*value))
			poly[i + 1] = SvNV (*value);
	}

	RETVAL = gnome_canvas_polygon_to_point (poly, length/2, x, y);

	g_free (poly);
    OUTPUT:
	RETVAL

###  void gnome_canvas_render_svp (GnomeCanvasBuf *buf, ArtSVP *svp, guint32 rgba) 
#void
#gnome_canvas_render_svp (buf, svp, rgba)
#	GnomeCanvasBuf *buf
#	ArtSVP *svp
#	guint32 rgba
#
###  void gnome_canvas_update_svp (GnomeCanvas *canvas, ArtSVP **p_svp, ArtSVP *new_svp) 
#void
#gnome_canvas_update_svp (canvas, p_svp, new_svp)
#	GnomeCanvas *canvas
#	ArtSVP **p_svp
#	ArtSVP *new_svp
#
###  void gnome_canvas_update_svp_clip (GnomeCanvas *canvas, ArtSVP **p_svp, ArtSVP *new_svp, ArtSVP *clip_svp) 
#void
#gnome_canvas_update_svp_clip (canvas, p_svp, new_svp, clip_svp)
#	GnomeCanvas *canvas
#	ArtSVP **p_svp
#	ArtSVP *new_svp
#	ArtSVP *clip_svp

MODULE = Gnome2::Canvas::Util	PACKAGE = Gnome2::Canvas::Item	PREFIX = gnome_canvas_item_

##  void gnome_canvas_item_reset_bounds (GnomeCanvasItem *item) 
=for apidoc
Reset the bounding box of I<$item> to an empty rectangle.
=cut
void
gnome_canvas_item_reset_bounds (item)
	GnomeCanvasItem *item

###  void gnome_canvas_item_update_svp (GnomeCanvasItem *item, ArtSVP **p_svp, ArtSVP *new_svp) 
#void
#gnome_canvas_item_update_svp (item, p_svp, new_svp)
#	GnomeCanvasItem *item
#	ArtSVP **p_svp
#	ArtSVP *new_svp
#
###  void gnome_canvas_item_update_svp_clip (GnomeCanvasItem *item, ArtSVP **p_svp, ArtSVP *new_svp, ArtSVP *clip_svp) 
#void
#gnome_canvas_item_update_svp_clip (item, p_svp, new_svp, clip_svp)
#	GnomeCanvasItem *item
#	ArtSVP **p_svp
#	ArtSVP *new_svp
#	ArtSVP *clip_svp
#
###  void gnome_canvas_item_request_redraw_svp (GnomeCanvasItem *item, const ArtSVP *svp) 
#void
#gnome_canvas_item_request_redraw_svp (item, svp)
#	GnomeCanvasItem *item
#	const ArtSVP *svp

MODULE = Gnome2::Canvas::Util	PACKAGE = Gnome2::Canvas::Item	PREFIX = gnome_canvas_

##  void gnome_canvas_update_bbox (GnomeCanvasItem *item, int x1, int y1, int x2, int y2) 
=for apidoc
Set I<$item>'s bounding box to a new rectangle, and request a full repaint.
=cut
void
gnome_canvas_update_bbox (item, x1, y1, x2, y2)
	GnomeCanvasItem *item
	int x1
	int y1
	int x2
	int y2

##MODULE = Gnome2::Canvas::Util	PACKAGE = Gnome2::Canvas::Buf	PREFIX = gnome_canvas_buf_
##
####  void gnome_canvas_buf_ensure_buf (GnomeCanvasBuf *buf) 
##void
##gnome_canvas_buf_ensure_buf (buf)
##	GnomeCanvasBuf *buf
##
##MODULE = Gnome2::Canvas::Util	PACKAGE = Gnome2::Canvas	PREFIX = gnome_canvas_
##
####  ArtPathStrokeJoinType gnome_canvas_join_gdk_to_art (GdkJoinStyle gdk_join) 
##ArtPathStrokeJoinType
##gnome_canvas_join_gdk_to_art (gdk_join)
##	GdkJoinStyle gdk_join
##
####  ArtPathStrokeCapType gnome_canvas_cap_gdk_to_art (GdkCapStyle gdk_cap) 
##ArtPathStrokeCapType
##gnome_canvas_cap_gdk_to_art (gdk_cap)
##	GdkCapStyle gdk_cap
##
