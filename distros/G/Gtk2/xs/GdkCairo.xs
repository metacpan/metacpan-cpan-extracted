/*
 * Copyright (c) 2005, 2011 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"
#include <cairo-perl.h>

MODULE = Gtk2::Gdk::Cairo	PACKAGE = Gtk2::Gdk::Cairo::Context	PREFIX = gdk_cairo_

=for position SYNOPSIS

=head1 HIERARCHY

    Cairo::Context
    +---- Gtk2::Gdk::Cairo::Context   (Perl subclass)

=head1 DESCRIPTION

This is some inter-operation between Cairo (see L<Cairo>) and Gdk
things.

A C<Gtk2::Gdk::Cairo::Context> lets Cairo draw on a Gdk drawable
(window or pixmap).  It's a Perl-level subclass of C<Cairo::Context>
and the various functions below can be used as methods on it.

The methods can also be used on other C<Cairo::Context> as plain
functions.  For example C<set_source_pixbuf> can setup to draw from a
C<Gtk2::Gdk::Pixbuf> to any Cairo context,

    my $cr = Cairo::Context->create ($surface);
    Gtk2::Gdk::Cairo::Context::set_source_pixbuf ($cr, $pixbuf, $x,$y);
    $cr->paint;

=cut

BOOT:
	gperl_set_isa ("Gtk2::Gdk::Cairo::Context", "Cairo::Context");

# cairo_t *gdk_cairo_create (GdkDrawable *drawable);
=for signature gdkcr = Gtk2::Gdk::Cairo::Context->create ($drawable)
=cut
SV *
gdk_cairo_create (class, GdkDrawable *drawable)
    PREINIT:
	cairo_t *cr;
    CODE:
	/* We own cr. */
	cr = gdk_cairo_create (drawable);
	RETVAL = newSV (0);
	sv_setref_pv (RETVAL, "Gtk2::Gdk::Cairo::Context", (void *) cr);
    OUTPUT:
	RETVAL

=for signature $gdkcr->set_source_color ($color)
=for signature Gtk2::Gdk::Cairo::Context::set_source_color ($anycr, $color)
=cut
void gdk_cairo_set_source_color (cairo_t *cr, GdkColor *color);

=for signature $gdkcr->set_source_pixbuf ($pixbuf, $pixbuf_x, $pixbuf_y)
=for signature Gtk2::Gdk::Cairo::Context::set_source_pixbuf ($anycr, $pixbuf, $pixbuf_x, $pixbuf_y)
=cut
void gdk_cairo_set_source_pixbuf (cairo_t *cr, GdkPixbuf *pixbuf, double pixbuf_x, double pixbuf_y);

# void gdk_cairo_rectangle (cairo_t *cr, GdkRectangle *rectangle);
=for apidoc
=for signature $gdkcr->rectangle ($rectangle)
=for signature $gdkcr->rectangle ($x, $y, $width, $height)
=for signature Gtk2::Gdk::Cairo::Context::rectangle ($anycr, $rectangle)
=for arg rectangle (Gtk2::Gdk::Rectangle)
=for arg cr (__hide__)
=for arg ... (__hide__)
The 4-argument x,y,width,height is the base L<Cairo::Context> style.  This
extends to also take a C<Gtk2::Gdk::Rectangle>.
=cut
void
gdk_cairo_rectangle (cairo_t *cr, ...)
    CODE:
	if (items == 2) {
		GdkRectangle *rect = SvGdkRectangle (ST (1));
		gdk_cairo_rectangle (cr, rect);
	} else if (items == 5) {
		double x = SvNV (ST(1));
		double y = SvNV (ST(2));
		double width = SvNV (ST(3));
		double height = SvNV (ST(4));
		cairo_rectangle (cr, x, y, width, height);
	} else {
		croak ("Usage: Gtk2::Gdk::Cairo::Context::rectangle (cr, rectangle)");
	}

=for signature $gdkcr->region ($region)
=for signature Gtk2::Gdk::Cairo::Context::region ($anycr, $region)
=cut
void gdk_cairo_region (cairo_t *cr, GdkRegion *region);

#if GTK_CHECK_VERSION (2, 10, 0)

=for signature $gdkcr->set_source_pixmap ($pixmap, $pixmap_x, $pixmap_y)
=for signature Gtk2::Gdk::Cairo::Context::set_source_pixmap ($anycr, $pixmap, $pixmap_x, $pixmap_y)
=cut
void gdk_cairo_set_source_pixmap (cairo_t *cr, GdkPixmap *pixmap, double pixmap_x, double pixmap_y);

#endif

#if GTK_CHECK_VERSION (2, 18, 0)

=for signature $gdkcr->reset_clip ($drawable)
=for signature Gtk2::Gdk::Cairo::Context::reset_clip ($anycr, $drawable)
=cut
void gdk_cairo_reset_clip (cairo_t *cr, GdkDrawable *drawable);

#endif

# ---------------------------------------------------------------------------- #

#if GTK_CHECK_VERSION (2, 10, 0)

MODULE = Gtk2::Gdk::Cairo	PACKAGE = Gtk2::Gdk::Screen	PREFIX = gdk_screen_

const cairo_font_options_t_ornull* gdk_screen_get_font_options (GdkScreen *screen);

void gdk_screen_set_font_options (GdkScreen *screen, const cairo_font_options_t_ornull *options);

#endif

# ---------------------------------------------------------------------------- #

MODULE = Gtk2::Gdk::Cairo	PACKAGE = Gtk2::Gdk::Window	PREFIX = gdk_window_

#if GTK_CHECK_VERSION (2, 22, 0)

cairo_surface_t * gdk_window_create_similar_surface (GdkWindow *window, cairo_content_t content, int width, int height);

cairo_pattern_t * gdk_window_get_background_pattern (GdkWindow *window);

#endif
