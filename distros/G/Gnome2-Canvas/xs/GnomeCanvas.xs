/*
 * Copyright (c) 2003-2004 by the gtk2-perl team (see the file AUTHORS)
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
 * License along with this library; if not, see
 * <https://www.gnu.org/licenses/>.
 *
 * $Id$
 */
#include "gnomecanvasperl.h"

SV *
newSVArtAffine (double affine[6])
{
	AV * a;
	
	if (!affine)
		return &PL_sv_undef;
		
	a = newAV();
	
	av_push (a, newSVnv (affine[0]));
	av_push (a, newSVnv (affine[1]));
	av_push (a, newSVnv (affine[2]));
	av_push (a, newSVnv (affine[3]));
	av_push (a, newSVnv (affine[4]));
	av_push (a, newSVnv (affine[5]));

	return newRV_noinc ((SV*)a);
}

double*
SvArtAffine (SV * sv)
{
	AV * av;
	double * affine;
	if ((!sv) || (!SvOK (sv)) || (!SvRV (sv)) ||
	    (SvTYPE (SvRV(sv)) != SVt_PVAV) ||
	    5 != av_len ((AV*) SvRV (sv)))
		croak ("affine transforms must be expressed as a reference to an array containing the six transform values");
	av = (AV*) SvRV (sv);
	affine = gperl_alloc_temp (6 * sizeof (double));
	affine[0] = SvNV (*av_fetch (av, 0, 0));
	affine[1] = SvNV (*av_fetch (av, 1, 0));
	affine[2] = SvNV (*av_fetch (av, 2, 0));
	affine[3] = SvNV (*av_fetch (av, 3, 0));
	affine[4] = SvNV (*av_fetch (av, 4, 0));
	affine[5] = SvNV (*av_fetch (av, 5, 0));
	return affine;
}

MODULE = Gnome2::Canvas	PACKAGE = Gnome2::Canvas	PREFIX = gnome_canvas_

BOOT:
	{
#include "register.xsh"
#include "boot.xsh"
	gperl_handle_logs_for ("GnomeCanvas");
	}

#
# there are several classes in the library which have no non-virtual
# methods, and thus have no direct bindings.  let's declare object
# sections for them here, so they'll show up in the documentation.
#

=for object Gnome2::Canvas::Group - A group of Gnome2::CanvasItems

=cut

=for object Gnome2::Canvas::Line - Lines as CanvasItems

=cut

=for object Gnome2::Canvas::Pixbuf - Pixbufs as CanvasItems

=cut

=for object Gnome2::Canvas::RE - base class for rectangles and ellipses

=cut

=for object Gnome2::Canvas::Rect - Rectangles as CanvasItems

=cut

=for object Gnome2::Canvas::Ellipse - Ellipses as CanvasItems

=cut

=for object Gnome2::Canvas::Text - Text as CanvasItems

=cut

=for object Gnome2::Canvas::Widget - Gtk2::Widgets as CanvasItems

=cut

#
# and now back to Gnome2::Canvas
#

=for object Gnome2::Canvas::main - A structured graphics canvas
=cut

=for apidoc new_aa
Create a new empty canvas in antialiased mode.
=cut

=for apidoc
Create a new empty canvas in non-antialiased mode.
=cut
##  GtkWidget *gnome_canvas_new (void) 
##  GtkWidget *gnome_canvas_new_aa (void) 
GtkWidget *
gnome_canvas_new (class)
    ALIAS:
	new_aa = 1
    CODE:
	if (ix == 1)
		RETVAL = gnome_canvas_new_aa ();
	else
		RETVAL = gnome_canvas_new ();
    OUTPUT:
	RETVAL

##  GnomeCanvasGroup *gnome_canvas_root (GnomeCanvas *canvas) 
GnomeCanvasGroup *
gnome_canvas_root (canvas)
	GnomeCanvas *canvas


=for apidoc pixels_per_unit __hide__ 
This is an alias for get_pixels_per_unit, but we won't clutter the docs
with it.  We'll condone the get_pixels_per_unit/set_pixels_per_unit pair.
=cut

=for apidoc get_pixels_per_unit
=for signature double = $canvas->get_pixels_per_unit
Fetch I<$canvas>' scale factor.
=cut

=for apidoc
=for signature boolean = $canvas->aa

Returns true if I<$canvas> was created in anti-aliased mode.

=cut
SV *
aa (canvas)
	GnomeCanvas * canvas
    ALIAS:
	pixels_per_unit = 1
	get_pixels_per_unit = 2
    CODE:
	RETVAL = NULL;
	switch (ix) {
	    case 0: RETVAL = newSViv (canvas->aa); break;
	    case 1: /* fall through */
	    case 2: RETVAL = newSVnv (canvas->pixels_per_unit); break;
	}
    OUTPUT:
	RETVAL

=for apidoc

Set the zooming factor of I<$canvas> by specifying the number of screen
pixels that correspond to one canvas unit.

=cut
##  void gnome_canvas_set_pixels_per_unit (GnomeCanvas *canvas, double n) 
void
gnome_canvas_set_pixels_per_unit (canvas, n)
	GnomeCanvas *canvas
	double n

##  void gnome_canvas_set_scroll_region (GnomeCanvas *canvas, double x1, double y1, double x2, double y2) 
void
gnome_canvas_set_scroll_region (canvas, x1, y1, x2, y2)
	GnomeCanvas *canvas
	double x1
	double y1
	double x2
	double y2

##  void gnome_canvas_get_scroll_region (GnomeCanvas *canvas, double *x1, double *y1, double *x2, double *y2) 

void gnome_canvas_get_scroll_region (GnomeCanvas *canvas, OUTLIST double x1, OUTLIST double y1, OUTLIST double x2, OUTLIST double y2) 

##  void gnome_canvas_set_center_scroll_region (GnomeCanvas *canvas, gboolean center_scroll_region) 
void
gnome_canvas_set_center_scroll_region (canvas, center_scroll_region)
	GnomeCanvas *canvas
	gboolean center_scroll_region

##  gboolean gnome_canvas_get_center_scroll_region (GnomeCanvas *canvas) 
gboolean
gnome_canvas_get_center_scroll_region (canvas)
	GnomeCanvas *canvas

##  void gnome_canvas_scroll_to (GnomeCanvas *canvas, int cx, int cy) 
void
gnome_canvas_scroll_to (canvas, cx, cy)
	GnomeCanvas *canvas
	int cx
	int cy

##  void gnome_canvas_get_scroll_offsets (GnomeCanvas *canvas, int *cx, int *cy) 
void gnome_canvas_get_scroll_offsets (GnomeCanvas *canvas, OUTLIST int cx, OUTLIST int cy)

##  void gnome_canvas_update_now (GnomeCanvas *canvas) 
void
gnome_canvas_update_now (canvas)
	GnomeCanvas *canvas

##  GnomeCanvasItem *gnome_canvas_get_item_at (GnomeCanvas *canvas, double x, double y) 
GnomeCanvasItem *
gnome_canvas_get_item_at (canvas, x, y)
	GnomeCanvas *canvas
	double x
	double y

###  void gnome_canvas_request_redraw_uta (GnomeCanvas *canvas, ArtUta *uta) 
#void
#gnome_canvas_request_redraw_uta (canvas, uta)
#	GnomeCanvas *canvas
#	ArtUta *uta

##  void gnome_canvas_request_redraw (GnomeCanvas *canvas, int x1, int y1, int x2, int y2) 
void
gnome_canvas_request_redraw (canvas, x1, y1, x2, y2)
	GnomeCanvas *canvas
	int x1
	int y1
	int x2
	int y2

##  void gnome_canvas_w2c_affine (GnomeCanvas *canvas, double affine[6]) 
=for apidoc
=for signature $affine = $canvas->w2c_affine
=for arg a (__hide__)
Fetch the affine transform that converts from world coordinates to canvas
pixel coordinates.

Note: This method was completely broken for all
$Gnome2::Canvas::VERSION < 1.002.
=cut
SV *
gnome_canvas_w2c_affine (canvas, a=NULL)
	GnomeCanvas *canvas
	SV * a
    PREINIT:
	double affine[6];
    CODE:
	if (a != NULL || items > 1)
		warn ("Gnome2::Canvas::w2c_affine() was broken before 1.002;"
		      " the second parameter does nothing (see the Gnome2::"
		      "Canvas manpage)");
	gnome_canvas_w2c_affine (canvas, affine);
	RETVAL = newSVArtAffine (affine);
    OUTPUT:
	RETVAL

##  void gnome_canvas_w2c (GnomeCanvas *canvas, double wx, double wy, int *cx, int *cy) 
##  void gnome_canvas_w2c_d (GnomeCanvas *canvas, double wx, double wy, double *cx, double *cy) 
void gnome_canvas_w2c_d (GnomeCanvas *canvas, double wx, double wy, OUTLIST double cx, OUTLIST double cy) 
    ALIAS:
	Gnome2::Canvas::w2c = 1
    CLEANUP:
	PERL_UNUSED_VAR (ix);


##  void gnome_canvas_c2w (GnomeCanvas *canvas, int cx, int cy, double *wx, double *wy) 
void gnome_canvas_c2w (GnomeCanvas *canvas, int cx, int cy, OUTLIST double wx, OUTLIST double wy) 

##  void gnome_canvas_window_to_world (GnomeCanvas *canvas, double winx, double winy, double *worldx, double *worldy) 
void gnome_canvas_window_to_world (GnomeCanvas *canvas, double winx, double winy, OUTLIST double worldx, OUTLIST double worldy) 

##  void gnome_canvas_world_to_window (GnomeCanvas *canvas, double worldx, double worldy, double *winx, double *winy) 
void gnome_canvas_world_to_window (GnomeCanvas *canvas, double worldx, double worldy, OUTLIST double winx, OUTLIST double winy) 

=for apidoc

Returns an integer indicating the success of the color allocation and a
GdkColor.

=cut
##  int gnome_canvas_get_color (GnomeCanvas *canvas, const char *spec, GdkColor *color) 
void
gnome_canvas_get_color (canvas, spec)
	GnomeCanvas *canvas
	const char *spec
    PREINIT:
	int result;
	GdkColor color;
    PPCODE:
	result = gnome_canvas_get_color (canvas, spec, &color);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSViv (result)));
	PUSHs (sv_2mortal (newSVGdkColor (&color)));

##  gulong gnome_canvas_get_color_pixel (GnomeCanvas *canvas, guint rgba) 
gulong
gnome_canvas_get_color_pixel (canvas, rgba)
	GnomeCanvas *canvas
	guint rgba

##  void gnome_canvas_set_stipple_origin (GnomeCanvas *canvas, GdkGC *gc) 
void
gnome_canvas_set_stipple_origin (canvas, gc)
	GnomeCanvas *canvas
	GdkGC *gc

##  void gnome_canvas_set_dither (GnomeCanvas *canvas, GdkRgbDither dither) 
void
gnome_canvas_set_dither (canvas, dither)
	GnomeCanvas *canvas
	GdkRgbDither dither

##  GdkRgbDither gnome_canvas_get_dither (GnomeCanvas *canvas) 
GdkRgbDither
gnome_canvas_get_dither (canvas)
	GnomeCanvas *canvas


=for object Gnome2::Canvas::version
=cut

=for see_also Glib::version

=for apidoc
=for signature (MAJOR, MINOR, MICRO) = Gnome2::Canvas->GET_VERSION_INFO
Fetch as a list the version of libgnomecanvas for which Gnome2::Canvas was
built.
=cut
void
GET_VERSION_INFO (class)
    PPCODE:
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSViv (GNOME_CANVAS_MAJOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (GNOME_CANVAS_MINOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (GNOME_CANVAS_MICRO_VERSION)));
	PERL_UNUSED_VAR (ax);

gboolean
CHECK_VERSION (class, major, minor, micro)
	int major
	int minor
	int micro
    CODE:
	RETVAL = GNOME_CANVAS_CHECK_VERSION (major, minor, micro);
    OUTPUT:
	RETVAL

