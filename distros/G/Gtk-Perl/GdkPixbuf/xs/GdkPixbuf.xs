
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk/gtk.h>

#include "GtkDefs.h"
#include "GdkPixbufDefs.h"

static void     callXS (void (*subaddr)(CV* cv), CV *cv, SV **mark)
{
        int items;
        dSP;
        PUSHMARK (mark);
        (*subaddr)(cv);

        PUTBACK;  /* Forget the return values */
}

MODULE = Gtk::Gdk::Pixbuf	PACKAGE = Gtk::Gdk::Pixbuf	PREFIX = gdk_pixbuf_


void
init (Class)
	SV* Class
	CODE:
	{
		static int did_it = 0;
		if (did_it)
			return;
		did_it = 1;
		GdkPixbuf_InstallTypedefs();
		GdkPixbuf_InstallObjects();
	}

Gtk::Gdk::Pixbuf
gdk_pixbuf_new (Class, format, has_alpha, bits_per_sample, width, height)
	SV	*Class
	int	format
	bool	has_alpha
	int	bits_per_sample
	int	width
	int	height
	CODE:
	RETVAL = gdk_pixbuf_new (format, has_alpha, bits_per_sample, width, height);
	sv_2mortal(newSVGdkPixbuf(RETVAL));
	gdk_pixbuf_unref(RETVAL);
	OUTPUT:
	RETVAL
	
Gtk::Gdk::Pixbuf
gdk_pixbuf_new_from_file (Class, filename)
	SV	*Class
	char	*filename
	CODE:
	RETVAL = gdk_pixbuf_new_from_file(filename);
	sv_2mortal(newSVGdkPixbuf(RETVAL));
	gdk_pixbuf_unref(RETVAL);
	OUTPUT:
	RETVAL

Gtk::Gdk::Pixbuf
gdk_pixbuf_new_from_data (Class, data, colorspace, has_alpha, bits_per_sample, width, height, rowstride)
	SV	*Class
	SV	*data
	Gtk::Gdk::Colorspace colorspace
	bool	has_alpha
	int bits_per_sample
	int	width
	int	height
	int	rowstride
	CODE:
	{
		STRLEN len;
		char *datas = SvPV(data, len);
		char *datap = malloc(len);
		if (!datap)
			croak("Out of memory");
		memcpy(datap, datas, len);
		/* uhm: change this to work from the data in the SV */
		RETVAL = gdk_pixbuf_new_from_data (datap, colorspace, has_alpha, 
			bits_per_sample, width, height, rowstride, (GdkPixbufDestroyNotify)free, datap);
		sv_2mortal(newSVGdkPixbuf(RETVAL));
		gdk_pixbuf_unref(RETVAL);
	}
	OUTPUT:
	RETVAL

Gtk::Gdk::Pixbuf
gdk_pixbuf_new_from_xpm_data (Class, data, ...)
	SV	*Class
	SV	*data
	CODE:
	{
		char ** lines = (char**)malloc(sizeof(char*)*(items-1));
		int i;
		if (!lines)
			croak("Out of memory");
		for(i=1;i<items;i++)
			lines[i-1] = SvPV(ST(i),PL_na);
		RETVAL = gdk_pixbuf_new_from_xpm_data (lines);
		free(lines);
		sv_2mortal(newSVGdkPixbuf(RETVAL));
		gdk_pixbuf_unref(RETVAL);
	}

Gtk::Gdk::Pixbuf
gdk_pixbuf_copy (pixbuf)
	Gtk::Gdk::Pixbuf	pixbuf
	CODE:
	{
		RETVAL = gdk_pixbuf_copy (pixbuf);
		sv_2mortal(newSVGdkPixbuf(RETVAL));
		gdk_pixbuf_unref(RETVAL);
	}
	OUTPUT:
	RETVAL

Gtk::Gdk::Pixbuf
gdk_pixbuf_add_alpha (pixbuf, ...)
	Gtk::Gdk::Pixbuf	pixbuf
	CODE:
	{
		int	r;
		int	g;
		int	b;
		gboolean subst = items > 1;
		int i = 1;
		switch (items) {
		case 2:
			r = g = b = SvIV(ST(1));
			break;
		case 5:
			i = 2;
			/* continues */
		case 4:
			r = SvIV(ST(i)); i++;
			g = SvIV(ST(i)); i++;
			b = SvIV(ST(i)); i++;
			break;
		default:
			croak("Usage: Gtk::Gdk::Pixbuf:add_alpha(pixbuf[, rgbval|(r, g, b)])");
		}
		RETVAL = gdk_pixbuf_add_alpha (pixbuf, subst, r, g, b);
		sv_2mortal(newSVGdkPixbuf(RETVAL));
		gdk_pixbuf_unref(RETVAL);
	}
	OUTPUT:
	RETVAL

void
gdk_pixbuf_render_threshold_alpha (pixbuf, bitmap, src_x, src_y, dest_x, dest_y, width, height, alpha_threshold)
	Gtk::Gdk::Pixbuf	pixbuf
	Gtk::Gdk::Bitmap	bitmap
	int	src_x
	int	src_y
	int	dest_x
	int	dest_y
	int	width
	int	height
	int	alpha_threshold

void
gdk_pixbuf_render_to_drawable (pixbuf, drawable, gc, src_x, src_y, dest_x, dest_y, width, height, dither=GDK_RGB_DITHER_NORMAL, x_dither=0, y_dither=0)
	Gtk::Gdk::Pixbuf	pixbuf
	Gtk::Gdk::Pixmap	drawable
	Gtk::Gdk::GC	gc
	int	src_x
	int	src_y
	int	dest_x
	int	dest_y
	int	width
	int	height
	Gtk::Gdk::Rgb::Dither	dither
	int	x_dither
	int	y_dither

void
gdk_pixbuf_render_to_drawable_alpha (pixbuf, drawable, src_x, src_y, dest_x, dest_y, width, height, alpha_mode, alpha_threshold, dither=GDK_RGB_DITHER_NORMAL, x_dither=0, y_dither=0)
	Gtk::Gdk::Pixbuf	pixbuf
	Gtk::Gdk::Pixmap	drawable
	int	src_x
	int	src_y
	int	dest_x
	int	dest_y
	int	width
	int	height
	Gtk::Gdk::PixbufAlphaMode	alpha_mode
	int	alpha_threshold
	Gtk::Gdk::Rgb::Dither	dither
	int	x_dither
	int	y_dither

void
gdk_pixbuf_render_pixmap_and_mask (pixbuf, alpha_threshold)
	Gtk::Gdk::Pixbuf	pixbuf
	int	alpha_threshold
	PPCODE:
	{
		GdkPixmap *pixmap=NULL;
		GdkBitmap *bitmap=NULL;
		gdk_pixbuf_render_pixmap_and_mask (pixbuf, &pixmap, &bitmap, alpha_threshold);
		if (pixmap) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVGdkPixmap(pixmap)));
		}
		if (bitmap) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVGdkBitmap(bitmap)));
		}
	}

Gtk::Gdk::Pixbuf
gdk_pixbuf_get_from_drawable (dest, src, cmap, src_x, src_y, dest_x, dest_y, width, height)
	Gtk::Gdk::Pixbuf	dest
	Gtk::Gdk::Pixmap	src
	Gtk::Gdk::Colormap_OrNULL	cmap
	int	src_x
	int	src_y
	int	dest_x
	int	dest_y
	int	width
	int	height
	CODE:
	{
		RETVAL = gdk_pixbuf_get_from_drawable (dest, src, cmap, src_x, src_y, dest_x, dest_y, width, height);
		sv_2mortal(newSVGdkPixbuf(RETVAL));
		gdk_pixbuf_unref(RETVAL);
	}
	OUTPUT:
	RETVAL

void
gdk_pixbuf_copy_area (src, src_x, src_y, width, height, dest, dest_x, dest_y)
	Gtk::Gdk::Pixbuf	src
	int	src_x
	int	src_y
	int	width
	int	height
	Gtk::Gdk::Pixbuf	dest
	int	dest_x
	int	dest_y

void
gdk_pixbuf_scale (src, dest, dest_x, dest_y, dest_width, dest_height, offset_x, offset_y, scale_x, scale_y, filter_level)
	Gtk::Gdk::Pixbuf	src
	Gtk::Gdk::Pixbuf	dest
	int	dest_x
	int	dest_y
	int	dest_width
	int	dest_height
	double	offset_x
	double	offset_y
	double	scale_x
	double	scale_y
	int	filter_level

void
gdk_pixbuf_composite (src, dest, dest_x, dest_y, dest_width, dest_height, offset_x, offset_y, scale_x, scale_y, filter_level, overall_alpha)
	Gtk::Gdk::Pixbuf	src
	Gtk::Gdk::Pixbuf	dest
	int	dest_x
	int	dest_y
	int	dest_width
	int	dest_height
	double	offset_x
	double	offset_y
	double	scale_x
	double	scale_y
	int	filter_level
	int	overall_alpha

void
gdk_pixbuf_composite_color (src, dest, dest_x, dest_y, dest_width, dest_height, offset_x, offset_y, scale_x, scale_y, filter_level, overall_alpha, check_x, check_y, check_size, color1, color2)
	Gtk::Gdk::Pixbuf	src
	Gtk::Gdk::Pixbuf	dest
	int	dest_x
	int	dest_y
	int	dest_width
	int	dest_height
	double	offset_x
	double	offset_y
	double	scale_x
	double	scale_y
	int	filter_level
	int	overall_alpha
	int	check_x
	int	check_y
	int	check_size
	int	color1
	int	color2

Gtk::Gdk::Pixbuf
gdk_pixbuf_scale_simple (src, dest_width, dest_height, filter_level)
	Gtk::Gdk::Pixbuf	src
	int	dest_width
	int	dest_height
	int	filter_level
	CODE:
	{
		RETVAL = gdk_pixbuf_scale_simple (src, dest_width, dest_height, filter_level);
		sv_2mortal(newSVGdkPixbuf(RETVAL));
		gdk_pixbuf_unref(RETVAL);
	}
	OUTPUT:
	RETVAL

Gtk::Gdk::Pixbuf
gdk_pixbuf_composite_color_simple (src, dest_width, dest_height, filter_level, overall_alpha, check_size, color1, color2)
	Gtk::Gdk::Pixbuf	src
	int	dest_width
	int	dest_height
	int	filter_level
	int	overall_alpha
	int	check_size
	int	color1
	int	color2
	CODE:
	{
		RETVAL = gdk_pixbuf_composite_color_simple (src, dest_width, dest_height, filter_level, overall_alpha, check_size, color1, color2);
		sv_2mortal(newSVGdkPixbuf(RETVAL));
		gdk_pixbuf_unref(RETVAL);
	}
	OUTPUT:
	RETVAL

#if 0

int
gdk_pixbuf_get_format (pixbuf)
	Gtk::Gdk::Pixbuf	pixbuf

#endif

int
gdk_pixbuf_get_n_channels (pixbuf)
	Gtk::Gdk::Pixbuf	pixbuf

int
gdk_pixbuf_get_has_alpha (pixbuf)
	Gtk::Gdk::Pixbuf	pixbuf

int
gdk_pixbuf_get_bits_per_sample (pixbuf)
	Gtk::Gdk::Pixbuf	pixbuf

int
gdk_pixbuf_get_width (pixbuf)
	Gtk::Gdk::Pixbuf	pixbuf

int
gdk_pixbuf_get_height (pixbuf)
	Gtk::Gdk::Pixbuf	pixbuf

int
gdk_pixbuf_get_rowstride (pixbuf)
	Gtk::Gdk::Pixbuf	pixbuf

# access to RGBA data ...

SV*
get_pixels (pixbuf, row, col=-1)
	Gtk::Gdk::Pixbuf	pixbuf
	int	row
	int	col
	CODE:
	{
		int startc, endc, rowstride, n_channels;
		char * buffer;
		
		rowstride = gdk_pixbuf_get_rowstride(pixbuf);
		n_channels = gdk_pixbuf_get_n_channels(pixbuf);
		buffer = gdk_pixbuf_get_pixels(pixbuf);
		endc = gdk_pixbuf_get_width(pixbuf);
		if (col < 0) {
			startc = 0;
		} else {
			startc = MIN(endc-1,col);
		}
		buffer = buffer + rowstride * row + startc * n_channels;
		RETVAL = newSVpvn(buffer, n_channels *(endc-startc));
	}
	OUTPUT:
	RETVAL

SV*
get_gray_pixels (pixbuf, row, col=-1)
	Gtk::Gdk::Pixbuf	pixbuf
	int	row
	int	col
	CODE:
	{
		int startc, endc, rowstride, n_channels;
		unsigned char * buffer;
		unsigned char gray;
		
		rowstride = gdk_pixbuf_get_rowstride(pixbuf);
		n_channels = gdk_pixbuf_get_n_channels(pixbuf);
		buffer = gdk_pixbuf_get_pixels(pixbuf);
		endc = gdk_pixbuf_get_width(pixbuf);
		if (col < 0) {
			startc = 0;
		} else {
			startc = MIN(endc-1,col);
		}
		buffer = buffer + rowstride * row + startc * n_channels;
		RETVAL = newSVpvn(buffer, 0);
		/* assume RGB */
		while (startc < endc) {
			gray = buffer[0]*0.301+buffer[1]*0.586+buffer[2]*0.113+0.5;
			sv_catpvn(RETVAL, &gray, 1);
			buffer += n_channels;
			++startc;
		}
	}
	OUTPUT:
	RETVAL

void
put_pixels (pixbuf, data, row, col)
	Gtk::Gdk::Pixbuf	pixbuf
	SV	*data
	int	row
	int	col
	CODE:
	{
		STRLEN blen;
		char * pixels = gdk_pixbuf_get_pixels(pixbuf);
		int rowstride = gdk_pixbuf_get_rowstride(pixbuf);
		int n_channels = gdk_pixbuf_get_n_channels(pixbuf);
		char * buffer = SvPV(data, blen);
		char * dest = pixels + rowstride*row + col * n_channels;
		memcpy(dest, buffer, blen);
	}

MODULE = Gtk::Gdk::Pixbuf	PACKAGE = Gtk::Gdk::PixbufAnimation	PREFIX = gdk_pixbuf_animation_

Gtk::Gdk::PixbufAnimation
gdk_pixbuf_animation_new_from_file (Class, filename)
	SV	*Class
	char	*filename
	CODE:
	RETVAL = gdk_pixbuf_animation_new_from_file(filename);
	sv_2mortal(newSVGdkPixbufAnimation(RETVAL));
	gdk_pixbuf_animation_unref(RETVAL);
	OUTPUT:
	RETVAL

INCLUDE: ../build/boxed.xsh

INCLUDE: ../build/objects.xsh

INCLUDE: ../build/extension.xsh

