
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define G_LOG_DOMAIN "Gtk"

#if !defined(PERLIO_IS_STDIO) && defined(HASATTRIBUTE)
# undef printf
#endif

#include <gtk/gtk.h>

#if !defined(PERLIO_IS_STDIO) && defined(HASATTRIBUTE)
# define printf PerlIO_stdoutf
#endif

#include "GtkTypes.h"
#include "GdkTypes.h"
#include "MiscTypes.h"

#include "GtkDefs.h"

MODULE = Gtk11		PACKAGE = Gtk::Gdk::Rgb::Cmap				PREFIX = gdk_rgb_cmap_

#if GTK_HVER > 0x010100

Gtk::Gdk::Rgb::Cmap
gdk_rgb_cmap_new(Class, ...)
	SV *	Class
	CODE:
	{
		guint32 n_colors = items-1;
		guint32 * colors = malloc(sizeof(guint32)*items);
		int i;
		for(i=0;i<n_colors;i++)
			colors[i] = SvIV(ST(i+1));
		RETVAL = gdk_rgb_cmap_new(colors, n_colors);
		free(colors);
	}
	OUTPUT:
	RETVAL

void
gdk_rgb_cmap_free(cmap)
	Gtk::Gdk::Rgb::Cmap	cmap

#endif

MODULE = Gtk11		PACKAGE = Gtk::Gdk::Pixmap	PREFIX = gdk_

#if GTK_HVER > 0x010100

void
gdk_draw_rgb_image (pixmap, gc, x, y, width, height, dith, rgb_buf, rowstride)
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::GC	gc
	gint	x
	gint	y
	gint	width
	gint	height
	Gtk::Gdk::Rgb::Dither	dith
	unsigned char *	rgb_buf
	gint	rowstride
	ALIAS:
		Gtk::Gdk::Pixmap::draw_rgb_image = 0
		Gtk::Gdk::Pixmap::draw_rgb_32_image = 1
		Gtk::Gdk::Pixmap::draw_gray_image = 2
	CODE:
	switch (ix) {
	case 0: gdk_draw_rgb_image (pixmap, gc, x, y, width, height, dith, rgb_buf, rowstride); break;
	case 1: gdk_draw_rgb_32_image (pixmap, gc, x, y, width, height, dith, rgb_buf, rowstride); break;
	case 2: gdk_draw_gray_image (pixmap, gc, x, y, width, height, dith, rgb_buf, rowstride); break;
	}

void
gdk_draw_rgb_image_dithalign (pixmap, gc, x, y, width, height, dith, rgb_buf, rowstride, xdith, ydith)
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::GC	gc
	gint	x
	gint	y
	gint	width
	gint	height
	Gtk::Gdk::Rgb::Dither	dith
	unsigned char *	rgb_buf
	gint	rowstride
	gint	xdith
	gint	ydith

void
gdk_draw_indexed_image (pixmap, gc, x, y, width, height, dith, rgb_buf, rowstride, cmap)
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::GC	gc
	gint	x
	gint	y
	gint	width
	gint	height
	Gtk::Gdk::Rgb::Dither	dith
	unsigned char *	rgb_buf
	gint	rowstride
	Gtk::Gdk::Rgb::Cmap	cmap

#endif
