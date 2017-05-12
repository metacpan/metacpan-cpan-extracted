
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::Canvas	PACKAGE = Gnome::Canvas	PREFIX = gnome_canvas_

#ifdef GNOME_CANVAS

Gnome::Canvas_Sink
gnome_canvas_new(Class)
	SV*	Class
	CODE:
	RETVAL= (GnomeCanvas*)(gnome_canvas_new());
	OUTPUT:
	RETVAL

#if GNOME_HVER >= 0x010200

Gnome::Canvas_Sink
gnome_canvas_new_aa(Class)
	SV*	Class
	CODE:
	RETVAL= (GnomeCanvas*)(gnome_canvas_new_aa());
	OUTPUT:
	RETVAL

#endif

Gnome::CanvasGroup
gnome_canvas_root(canvas)
	Gnome::Canvas	canvas

void
gnome_canvas_set_scroll_region(canvas, x1, y1, x2, y2)
	Gnome::Canvas	canvas
	double	x1
	double	y1
	double	x2
	double	y2

void
gnome_canvas_get_scroll_region (canvas)
	Gnome::Canvas	canvas
	PPCODE:
	{
		double x1, y1, x2, y2;
		gnome_canvas_get_scroll_region(canvas, &x1, &y1, &x2, &y2);
		EXTEND(sp, 4);
		PUSHs(sv_2mortal(newSVnv(x1)));
		PUSHs(sv_2mortal(newSVnv(y1)));
		PUSHs(sv_2mortal(newSVnv(x2)));
		PUSHs(sv_2mortal(newSVnv(y2)));
	}

void
gnome_canvas_set_pixels_per_unit(canvas, n)
	Gnome::Canvas	canvas
	double	n

double
get_pixels_per_unit (canvas)
	Gnome::Canvas	canvas
	CODE:
	RETVAL = canvas->pixels_per_unit;
	OUTPUT:
	RETVAL

#if 0

void
gnome_canvas_set_size(self, width, height)
	Gnome::Canvas	self
	int	width
	int	height

#endif

void
gnome_canvas_scroll_to(canvas, x, y)
	Gnome::Canvas	canvas
	int	x
	int	y

void
gnome_canvas_get_scroll_offsets (canvas)
	Gnome::Canvas	canvas
	PPCODE:
	{
		int x, y;
		gnome_canvas_get_scroll_offsets(canvas, &x, &y);
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSViv(x)));
		PUSHs(sv_2mortal(newSViv(y)));
	}

void
gnome_canvas_update_now(canvas)
	Gnome::Canvas	canvas

Gnome::CanvasItem_OrNULL
gnome_canvas_get_item_at (canvas, x, y)
	Gnome::Canvas	canvas
	double x
	double y

void
gnome_canvas_request_redraw(canvas, x1, y1, x2, y2)
	Gnome::Canvas	canvas
	int	x1
	int	y1
	int	x2
	int	y2

# missing: gnome_canvas_request_redraw_uta

void
gnome_canvas_w2c_affine (canvas)
	Gnome::Canvas	canvas
	PPCODE:
	{
		double affine[6];
		int i;
		gnome_canvas_w2c_affine(canvas, affine);
		EXTEND(sp, 6);
		for(i=0; i < 6; ++i)
			PUSHs(sv_2mortal(newSVnv(affine[i])));
	}

void
gnome_canvas_w2c (canvas, wx, wy)
	Gnome::Canvas	canvas
	double	wx
	double	wy
	PPCODE:
	{
		int cx, cy;
		gnome_canvas_w2c(canvas, wx, wy, &cx, &cy);
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSViv(cx)));
		PUSHs(sv_2mortal(newSViv(cy)));

	}

void
gnome_canvas_w2c_d (canvas, wx, wy)
	Gnome::Canvas	canvas
	double	wx
	double	wy
	PPCODE:
	{
		double cx, cy;
		gnome_canvas_w2c_d(canvas, wx, wy, &cx, &cy);
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSVnv(cx)));
		PUSHs(sv_2mortal(newSVnv(cy)));
	}

void
gnome_canvas_c2w (canvas, cx, cy)
	Gnome::Canvas	canvas
	int	cx
	int	cy
	PPCODE:
	{
		double wx, wy;
		gnome_canvas_c2w(canvas, cx, cy, &wx, &wy);
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSVnv(wx)));
		PUSHs(sv_2mortal(newSVnv(wy)));
	}

void
gnome_canvas_window_to_world (canvas, winx, winy)
	Gnome::Canvas	canvas
	double	winx
	double	winy
	PPCODE:
	{
		double wx, wy;
		gnome_canvas_window_to_world(canvas, winx, winy, &wx, &wy);
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSVnv(wx)));
		PUSHs(sv_2mortal(newSVnv(wy)));
	}

void
gnome_canvas_world_to_window (canvas, wx, wy)
	Gnome::Canvas	canvas
	double	wx
	double	wy
	PPCODE:
	{
		double winx, winy;
		gnome_canvas_world_to_window(canvas, wx, wy, &winx, &winy);
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSVnv(winx)));
		PUSHs(sv_2mortal(newSVnv(winy)));
	}

Gtk::Gdk::Color
gnome_canvas_get_color (canvas, spec)
	Gnome::Canvas	canvas
	char *	spec
	CODE:
	{
		GdkColor color;
		RETVAL = NULL;
		if (gnome_canvas_get_color (canvas, spec, &color))
			RETVAL = &color;
	}
	OUTPUT:
	RETVAL

gulong
gnome_canvas_get_color_pixel (canvas, rgba)
	Gnome::Canvas	canvas
	guint	rgba

void
gnome_canvas_set_stipple_origin (canvas, gc)
	Gnome::Canvas	canvas
	Gtk::Gdk::GC	gc

void
gnome_canvas_set_close_enough(canvas, ce)
	Gnome::Canvas	canvas
	int		ce
	CODE:
	canvas->close_enough = ce;

#if GNOME_HVER >= 0x010209

void
gnome_canvas_set_dither (canvas, dither)
	Gnome::Canvas	canvas
	Gtk::Gdk::Rgb::Dither	dither

Gtk::Gdk::Rgb::Dither
gnome_canvas_get_dither (canvas)
	Gnome::Canvas	canvas

#endif

#endif

