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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/GnomeCanvas/xs/GnomeCanvas.xs,v 1.20 2004/08/16 02:10:26 muppetman Exp $
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

=for object Gnome2::Canvas A structured graphics canvas

=cut

=for position SYNOPSIS

=head1 SYNOPSIS

  use strict;
  use Gtk2 -init;
  use Gnome2::Canvas;
  my $window = Gtk2::Window->new;
  my $scroller = Gtk2::ScrolledWindow->new;
  my $canvas = Gnome2::Canvas->new;
  $scroller->add ($canvas);
  $window->add ($scroller);
  $window->set_default_size (150, 150);
  $canvas->set_scroll_region (0, 0, 200, 200);
  $window->show_all;

  my $root = $canvas->root;
  Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Text',
                             x => 20,
                             y => 15,
                             fill_color => 'black',
                             font => 'Sans 14',
                             anchor => 'GTK_ANCHOR_NW',
                             text => 'Hello, World!');
  my $box = Gnome2::Canvas::Item->new ($root, 'Gnome2::Canvas::Rect',
                                       x1 => 10, y1 => 5,
                                       x2 => 150, y2 => 135,
                                       fill_color => 'red',
                                       outline_color => 'black');
  $box->lower_to_bottom;
  $box->signal_connect (event => sub {
          my ($item, $event) = @_;
          warn "event ".$event->type."\n";
  });

  Gtk2->main;

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

The Gnome Canvas is an engine for structured graphics that offers a
rich imaging model, high-performance rendering, and a powerful,
high level API.  It offers a choice of two rendering back-ends,
one based on GDK for extremely fast display, and another based on
Libart, a sophisticated, antialiased, alpha-compositing engine.
This widget can be used for flexible display of graphics and for
creating interactive user interface elements.

To create a new Gnome2::Canvas widget call C<< Gnome2::Canvas->new >> or
C<< Gnome2::Canvas->new_aa >> for an anti-aliased mode canvas.

A Gnome2::Canvas contains one or more Gnome2::CanvasItem
objects. Items consist of graphing elements like lines, ellipses,
polygons, images, text, and curves.  These items are organized using
Gnome2::CanvasGroup objects, which are themselves derived from
Gnome2::CanvasItem.  Since a group is an item it can be contained within
other groups, forming a tree of canvas items.  Certain operations, like
translating and scaling, can be performed on all items in a group.

There is a special root group created by a Gnome2::Canvas.  This is the top
level group under which all items in a canvas are contained.  The root group
is available as C<< $canvas->root >>.

There are several different coordinate systems used by Gnome2::Canvas
widgets.  The primary system is a logical, abstract coordinate space
called world coordinates.  World coordinates are expressed as unbounded
double floating point numbers.  When it comes to rendering to a screen
the canvas pixel coordinate system (also referred to as just canvas
coordinates) is used.  This system uses integers to specify screen
pixel positions.  A user defined scaling factor and offset are used to
convert between world coordinates and canvas coordinates.  Each item in
a canvas has its own coordinate system called item coordinates.  This
system is specified in world coordinates but they are relative to an
item (0.0, 0.0 would be the top left corner of the item).  The final
coordinate system of interest is window coordinates.  These are like
canvas coordinates but are offsets from within a window a canvas is
displayed in.  This last system is rarely used, but is useful when
manually handling GDK events (such as drag and drop) which are 
specified in window coordinates (the events processed by the canvas
are already converted for you).

Along with different coordinate systems come methods to convert
between them.  C<< $canvas->w2c >> converts world to canvas pixel
coordinates and C<< canvas->c2w >> converts from canvas to
world.  To get the affine transform matrix for converting
from world coordinates to canvas coordinates call C<< $canvas->w2c_affine >>.
C<< $canvas->window_to_world >> converts from window to world
coordinates and C<< $canvas->world_to_window >> converts in the other
direction.  There are no methods for converting between canvas and
window coordinates, since this is just a matter of subtracting the
canvas scrolling offset.  To convert to/from item coordinates use the
methods defined for Gnome2::CanvasItem objects.

To set the canvas zoom factor (canvas pixels per world unit, the
scaling factor) call C<< $canvas->set_pixels_per_unit >>; setting this
to 1.0 will cause the two coordinate systems to correspond (e.g., [5, 6]
in pixel units would be [5.0, 6.0] in world units).

Defining the scrollable area of a canvas widget is done by calling
C<< $canvas->set_scroll_region >> and to get the current region
C<< $canvas->get_scroll_region >> can be used.  If the window is
larger than the canvas scrolling region it can optionally be centered
in the window.  Use C<< $canvas->set_center_scroll_region >> to enable or
disable this behavior.  To scroll to a particular canvas pixel coordinate
use C<< $canvas->scroll_to >> (typically not used since scrollbars are
usually set up to handle the scrolling), and to get the current canvas pixel
scroll offset call C<< $canvas->get_scroll_offsets >>.

=cut

=for position SEE_ALSO

=head1 SEE ALSO

Gnome2::Canvas::index(3pm) lists the generated Perl API reference PODs.

Frederico Mena Quintero's whitepaper on the GNOME Canvas:
http://developer.gnome.org/doc/whitepapers/canvas/canvas.html

The real GnomeCanvas is implemented in a C library; the Gnome2::Canvas module
allows a Perl developer to use the canvas like a normal gtk2-perl object.
Like the Gtk2 module on which it depends, Gnome2::Canvas follows the C API of
libgnomecanvas-2.0 as closely as possible while still being perlish.
Thus, the C API reference remains the canonical documentation; the Perl
reference documentation lists call signatures and argument types, and is
meant to be used in conjunction with the C API reference.

GNOME Canvas Library Reference Manual
http://developer.gnome.org/doc/API/2.0/libgnomecanvas/index.html

perl(1), Glib(3pm), Gtk2(3pm).

To discuss gtk2-perl, ask questions and flame/praise the authors,
join gtk-perl-list@gnome.org at lists.gnome.org.

=cut

=for position COPYRIGHT

=head1 AUTHOR

muppet <scott at asofyet dot org>, with patches from
Torsten Schoenfeld <kaffetisch at web dot de>.

The DESCRIPTION section of this page is adapted from the documentation of
libgnomecanvas.

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2004 by the gtk2-perl team.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the 
Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
Boston, MA  02111-1307  USA.

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

