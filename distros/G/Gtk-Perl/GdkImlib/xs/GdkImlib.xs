
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk/gtk.h>
#include <gdk_imlib.h>

#include "GtkDefs.h"
#include "GdkImlibTypes.h"

/*typedef GdkImlibImage * Gtk__Gdk__ImlibImage;
typedef GdkImlibSaveInfo * Gtk__Gdk__Imlib__SaveInfo;
typedef GdkImlibColorModifier * Gtk__Gdk__Imlib__ColorModifier;
*/

SV * newSVGdkImlibImage(GdkImlibImage * value) {
	int n = 0;
	SV * result = newSVMiscRef(value, "Gtk::Gdk::ImlibImage", &n);
	return result;
}

GdkImlibImage * SvGdkImlibImage(SV * value) { return (GdkImlibImage*)SvMiscRef(value, "Gtk::Gdk::ImlibImage"); }

SV * newSVGdkImlibColorModifier(GdkImlibColorModifier * m)
{
	HV * h;
	SV * r;
	
	if (!m)
		return newSVsv(&PL_sv_undef);
		
	h = newHV();
	r = newRV_inc((SV*)h);
	SvREFCNT_dec(h);

	hv_store(h, "gamma", 5, newSViv(m->gamma), 0);
	hv_store(h, "contrast", 8, newSViv(m->contrast), 0);
	hv_store(h, "brightness", 10, newSViv(m->brightness), 0);
	
	return r;
}

GdkImlibColorModifier * SvGdkImlibColorModifier(SV * data)
{
	HV * h;
	SV ** s;
	GdkImlibColorModifier * m;

	if ((!data) || (!SvOK(data)) || (!SvRV(data)) || (SvTYPE(SvRV(data)) != SVt_PVHV))
		return 0;
		
	h = (HV*)SvRV(data);

	m = pgtk_alloc_temp(sizeof(GdkImlibColorModifier));
	
	memset(m,0,sizeof(GdkImlibColorModifier));

	if ((s=hv_fetch(h, "gamma", 5, 0)) && SvOK(*s))
		m->gamma = SvIV(*s);
	if ((s=hv_fetch(h, "contrast", 8, 0)) && SvOK(*s))
		m->contrast = SvIV(*s);
	if ((s=hv_fetch(h, "brightness", 10, 0)) && SvOK(*s))
		m->brightness = SvIV(*s);

	return m;
}

SV * newSVGdkImlibSaveInfo(GdkImlibSaveInfo * m)
{
	HV * h;
	SV * r;
	
	if (!m)
		return newSVsv(&PL_sv_undef);
		
	h = newHV();
	r = newRV_inc((SV*)h);
	SvREFCNT_dec(h);

	hv_store(h, "quality", 7, newSViv(m->quality), 0);
	hv_store(h, "scaling", 7, newSViv(m->scaling), 0);
	hv_store(h, "xjustification", 14, newSViv(m->xjustification), 0);
	hv_store(h, "yjustification", 14, newSViv(m->yjustification), 0);
	hv_store(h, "page_size", 9, newSViv(m->page_size), 0);
	hv_store(h, "color", 5, newSViv(m->color), 0);
	
	return r;
}

GdkImlibSaveInfo * SvGdkImlibSaveInfo(SV * data)
{
	HV * h;
	SV ** s;
	GdkImlibSaveInfo * m;

	if ((!data) || (!SvOK(data)) || (!SvRV(data)) || (SvTYPE(SvRV(data)) != SVt_PVHV))
		return 0;
		
	h = (HV*)SvRV(data);

	m = pgtk_alloc_temp(sizeof(GdkImlibSaveInfo));
	
	memset(m,0,sizeof(GdkImlibSaveInfo));

	if ((s=hv_fetch(h, "quality", 7, 0)) && SvOK(*s))
		m->quality = SvIV(*s);
	if ((s=hv_fetch(h, "scaling", 7, 0)) && SvOK(*s))
		m->scaling = SvIV(*s);
	if ((s=hv_fetch(h, "xjustification", 14, 0)) && SvOK(*s))
		m->xjustification = SvIV(*s);
	if ((s=hv_fetch(h, "yjustification", 14, 0)) && SvOK(*s))
		m->yjustification = SvIV(*s);
	if ((s=hv_fetch(h, "page_size", 9, 0)) && SvOK(*s))
		m->page_size = SvIV(*s);
	if ((s=hv_fetch(h, "color", 5, 0)) && SvOK(*s))
		m->color = SvIV(*s);

	return m;
}

MODULE = Gtk::Gdk::ImlibImage	PACKAGE = Gtk::Gdk::Pixmap

void
imlib_free(pixmap)
	Gtk::Gdk::Pixmap pixmap
	CODE:
	gdk_imlib_free_pixmap(pixmap);

MODULE = Gtk::Gdk::ImlibImage	PACKAGE = Gtk::Gdk::Bitmap

void
imlib_free( bitmap)
	Gtk::Gdk::Bitmap bitmap
	CODE:
	gdk_imlib_free_bitmap(bitmap);

MODULE = Gtk::Gdk::ImlibImage	PACKAGE = Gtk::Gdk::ImlibImage	PREFIX = gdk_imlib_

void
gdk_imlib_init(Class)
	CODE:
	if (pgtk_did_we_init_gtk)
		gdk_imlib_init();

int
gdk_imlib_get_render_type(Class)
	SV * Class
	CODE:
	RETVAL = gdk_imlib_get_render_type();
	OUTPUT:
	RETVAL

void
gdk_imlib_set_render_type(Class, rend_type)
	SV * Class
	int rend_type
	CODE:
	gdk_imlib_set_render_type(rend_type);

int
gdk_imlib_load_colors(Class, file)
	SV * Class
	char* file
	CODE:
	RETVAL = gdk_imlib_load_colors(file);
	OUTPUT:
	RETVAL

Gtk::Gdk::ImlibImage
gdk_imlib_load_image(Class, file)
	SV * Class
	char* file
	CODE:
	RETVAL = gdk_imlib_load_image(file);
	OUTPUT:
	RETVAL

Gtk::Gdk::ImlibImage
gdk_imlib_load_alpha(Class, file)
	SV * Class
	char* file
	CODE:
	RETVAL = gdk_imlib_load_alpha(file);
	OUTPUT:
	RETVAL

void
gdk_imlib_best_color_match (Class, r, g, b)
	SV *	Class
	int	r
	int	g
	int	b
	PPCODE:
	{
		int res = gdk_imlib_best_color_match(&r, &g, &b);
		EXTEND(sp, 4);
		XPUSHs(sv_2mortal(newSViv(res)));
		XPUSHs(sv_2mortal(newSViv(r)));
		XPUSHs(sv_2mortal(newSViv(g)));
		XPUSHs(sv_2mortal(newSViv(b)));
	}

int
gdk_imlib_render( image, width, height)
	Gtk::Gdk::ImlibImage image
	int width
	int height

Gtk::Gdk::Pixmap
gdk_imlib_copy_image(image)
	Gtk::Gdk::ImlibImage image

Gtk::Gdk::Bitmap
gdk_imlib_copy_mask(image)
	Gtk::Gdk::ImlibImage image

Gtk::Gdk::Pixmap
gdk_imlib_move_image(image)
	Gtk::Gdk::ImlibImage image

Gtk::Gdk::Bitmap_OrNULL
gdk_imlib_move_mask(image)
	Gtk::Gdk::ImlibImage image

void
gdk_imlib_destroy_image(image)
	Gtk::Gdk::ImlibImage image
	CODE:
	gdk_imlib_destroy_image(image);
	UnregisterMisc((HV*)SvRV(ST(0)), image);

void
gdk_imlib_kill_image(image)
	Gtk::Gdk::ImlibImage image
	CODE:
	gdk_imlib_kill_image(image);
	UnregisterMisc((HV*)SvRV(ST(0)), image);

void
DESTROY(image)
	Gtk::Gdk::ImlibImage image
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)), image);

void
gdk_imlib_free_colors(Class)
	SV * Class
	CODE:
	gdk_imlib_free_colors();

void
gdk_imlib_set_image_border (image, left, right, top, bottom)
	Gtk::Gdk::ImlibImage image
	int	left
	int	right
	int	top
	int	bottom
	CODE:
	{
		GdkImlibBorder border;
		border.left = left;
		border.right = right;
		border.top = top;
		border.bottom = bottom;
		gdk_imlib_set_image_border(image, &border);
	}

void
gdk_imlib_get_image_border (image)
	Gtk::Gdk::ImlibImage image
	PPCODE:
	{
		GdkImlibBorder border;
		gdk_imlib_get_image_border (image, &border);
		EXTEND(sp, 4);
		XPUSHs(sv_2mortal(newSViv(border.left)));
		XPUSHs(sv_2mortal(newSViv(border.right)));
		XPUSHs(sv_2mortal(newSViv(border.top)));
		XPUSHs(sv_2mortal(newSViv(border.bottom)));
	}

void
gdk_imlib_set_image_shape(image, r, g, b)
	Gtk::Gdk::ImlibImage image
	int	r
	int	g
	int	b
	CODE:
	{
		GdkImlibColor color;
		color.r = r; color.g = g; color.b = b;
		gdk_imlib_set_image_shape(image, &color);
	}

int
gdk_imlib_save_image_to_eim(image, file)
	Gtk::Gdk::ImlibImage image
	char* file

int
gdk_imlib_add_image_to_eim(image, file)
	Gtk::Gdk::ImlibImage image
	char* file

int
gdk_imlib_save_image_to_ppm(image, file)
	Gtk::Gdk::ImlibImage image
	char* file

void
gdk_imlib_load_file_to_pixmap(Class, file)
	SV * Class
	char* file
	PPCODE:
	{
		GdkPixmap * result = 0;
		GdkBitmap * mask = 0;
		int ret;
		ret = gdk_imlib_load_file_to_pixmap(file, &result, &mask);
		if (result) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkPixmap(result)));
		}
		if (mask) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkBitmap(mask)));
		}
	}

void
gdk_imlib_set_image_modifier(image, mod)
	Gtk::Gdk::ImlibImage image
	Gtk::Gdk::Imlib::ColorModifier mod

void
gdk_imlib_set_image_red_modifier(image, mod)
	Gtk::Gdk::ImlibImage image
	Gtk::Gdk::Imlib::ColorModifier mod

void
gdk_imlib_set_image_green_modifier(image, mod)
	Gtk::Gdk::ImlibImage image
	Gtk::Gdk::Imlib::ColorModifier mod

void
gdk_imlib_set_image_blue_modifier(image, mod)
	Gtk::Gdk::ImlibImage image
	Gtk::Gdk::Imlib::ColorModifier mod

Gtk::Gdk::Imlib::ColorModifier
gdk_imlib_get_image_modifier(image)
	Gtk::Gdk::ImlibImage image
	CODE:
	{
		GdkImlibColorModifier mod;
		gdk_imlib_get_image_modifier(image, &mod);
		RETVAL = &mod;
	}
	OUTPUT:
	RETVAL

Gtk::Gdk::Imlib::ColorModifier
gdk_imlib_get_image_red_modifier(image)
	Gtk::Gdk::ImlibImage image
	CODE:
	{
		GdkImlibColorModifier mod;
		gdk_imlib_get_image_red_modifier(image, &mod);
		RETVAL = &mod;
	}
	OUTPUT:
	RETVAL

Gtk::Gdk::Imlib::ColorModifier
gdk_imlib_get_image_green_modifier(image)
	Gtk::Gdk::ImlibImage image
	CODE:
	{
		GdkImlibColorModifier mod;
		gdk_imlib_get_image_green_modifier(image, &mod);
		RETVAL = &mod;
	}
	OUTPUT:
	RETVAL

Gtk::Gdk::Imlib::ColorModifier
gdk_imlib_get_image_blue_modifier(image)
	Gtk::Gdk::ImlibImage image
	CODE:
	{
		GdkImlibColorModifier mod;
		gdk_imlib_get_image_blue_modifier(image, &mod);
		RETVAL = &mod;
	}
	OUTPUT:
	RETVAL

void
gdk_imlib_set_image_red_curve(image, mod)
	Gtk::Gdk::ImlibImage image
	SV * mod
	CODE:
	{
		STRLEN len;
		unsigned char* rmod = SvPV(mod, len);
		if ( len < 256 )
			croak("mod must be 256 bytes long");
		gdk_imlib_set_image_red_curve(image, rmod);
	}

void
gdk_imlib_set_image_green_curve(image, mod)
	Gtk::Gdk::ImlibImage image
	SV * mod
	CODE:
	{
		STRLEN len;
		unsigned char* rmod = SvPV(mod, len);
		if ( len < 256 )
			croak("mod must be 256 bytes long");
		gdk_imlib_set_image_green_curve(image, rmod);
	}

void
gdk_imlib_set_image_blue_curve(image, mod)
	Gtk::Gdk::ImlibImage image
	SV * mod
	CODE:
	{
		STRLEN len;
		unsigned char* rmod = SvPV(mod, len);
		if ( len < 256 )
			croak("mod must be 256 bytes long");
		gdk_imlib_set_image_blue_curve(image, rmod);
	}

SV*
gdk_imlib_get_image_red_curve(image)
	Gtk::Gdk::ImlibImage image
	CODE:
	{
		unsigned char mod[256];
		gdk_imlib_get_image_red_curve(image, mod);
		sv_setpvn(RETVAL, mod, 256);
	}
	OUTPUT:
	RETVAL

SV*
gdk_imlib_get_image_green_curve(image)
	Gtk::Gdk::ImlibImage image
	CODE:
	{
		unsigned char mod[256];
		gdk_imlib_get_image_green_curve(image, mod);
		sv_setpvn(RETVAL, mod, 256);
	}
	OUTPUT:
	RETVAL

SV*
gdk_imlib_get_image_blue_curve(image)
	Gtk::Gdk::ImlibImage image
	CODE:
	{
		unsigned char mod[256];
		gdk_imlib_get_image_blue_curve(image, mod);
		sv_setpvn(RETVAL, mod, 256);
	}
	OUTPUT:
	RETVAL

void
gdk_imlib_apply_modifiers_to_rgb(image)
	Gtk::Gdk::ImlibImage image

void
gdk_imlib_changed_image(image)
	Gtk::Gdk::ImlibImage image

void
gdk_imlib_apply_image(image, window)
	Gtk::Gdk::ImlibImage image
	Gtk::Gdk::Window window

void
gdk_imlib_paste_image(image, window, x, y, w, h)
	Gtk::Gdk::ImlibImage image
	Gtk::Gdk::Window window
	int x
	int y
	int w
	int h

void
gdk_imlib_paste_image_border(image, window, x, y, w, h)
	Gtk::Gdk::ImlibImage image
	Gtk::Gdk::Window window
	int x
	int y
	int w
	int h

void
gdk_imlib_flip_image_horizontal(image)
	Gtk::Gdk::ImlibImage image

void
gdk_imlib_flip_image_vertical(image)
	Gtk::Gdk::ImlibImage image

void
gdk_imlib_rotate_image(image, d)
	Gtk::Gdk::ImlibImage image
	int d

Gtk::Gdk::ImlibImage
gdk_imlib_create_image_from_data(Class, data, alpha, w, h)
	SV * Class 
	char* data
	char* alpha
	int w
	int h
	CODE:
	RETVAL = gdk_imlib_create_image_from_data(data, alpha, w, h);
	OUTPUT:
	RETVAL

Gtk::Gdk::ImlibImage
gdk_imlib_create_image_from_drawable(Class, gwin, gmask, x, y, width, height)
	SV *	Class
	Gtk::Gdk::Window	gwin
	Gtk::Gdk::Bitmap_OrNULL	gmask
	int	x
	int	y
	int	width
	int	height
	CODE:
	RETVAL = gdk_imlib_create_image_from_drawable(gwin, gmask, x, y, width, height);
	OUTPUT:
	RETVAL

Gtk::Gdk::ImlibImage
gdk_imlib_inlined_png_to_image(Class, data)
	SV *	Class
	SV *	data
	CODE:
	{
		STRLEN len;
		char * d = SvPV(data, len);
		RETVAL = gdk_imlib_inlined_png_to_image(d, len);
	}
	OUTPUT:
	RETVAL


Gtk::Gdk::ImlibImage
gdk_imlib_clone_image(image)
	Gtk::Gdk::ImlibImage image

Gtk::Gdk::ImlibImage
gdk_imlib_clone_scaled_image(image, w, h)
	Gtk::Gdk::ImlibImage image
	int w
	int h

void
gdk_imlib_crop_image(image, x, y, w, h)
       Gtk::Gdk::ImlibImage image
       int x
       int y
       int w
       int h

Gtk::Gdk::ImlibImage
gdk_imlib_crop_and_clone_image(image, x, y, w, h)
       Gtk::Gdk::ImlibImage image
       int x
       int y
       int w
       int h

int
gdk_imlib_get_fallback(Class)
	SV * Class
	CODE:
	RETVAL = gdk_imlib_get_fallback();
	OUTPUT:
	RETVAL

void
gdk_imlib_set_fallback(Class, fallback)
	SV * Class
	int fallback
	CODE:
	gdk_imlib_set_fallback(fallback);

Gtk::Gdk::Visual
gdk_imlib_get_visual(Class)
	SV * Class
	CODE:
	RETVAL = gdk_imlib_get_visual();
	OUTPUT:
	RETVAL

Gtk::Gdk::Colormap
gdk_imlib_get_colormap(Class)
	SV * Class
	CODE:
	RETVAL = gdk_imlib_get_colormap();
	OUTPUT:
	RETVAL

char*
gdk_imlib_get_sysconfig(Class)
	SV * Class
	CODE:
	RETVAL = gdk_imlib_get_sysconfig();
	OUTPUT:
	RETVAL

Gtk::Gdk::ImlibImage
gdk_imlib_create_image_from_xpm_data(Class, data, ...)
	SV * Class
	SV * data
	CODE:
	{
		char ** lines = (char**)malloc(sizeof(char*)*(items-1));
		int i;
		for(i=1;i<items;i++)
			lines[i-1] = SvPV(ST(i),PL_na);
		RETVAL = gdk_imlib_create_image_from_xpm_data(lines);
		free(lines);
	}
	OUTPUT:
	RETVAL

void
gdk_imlib_data_to_pixmap(Class, data, ...)
	SV *	data
	PPCODE:
	{
		GdkPixmap * result = 0;
		GdkBitmap * mask = 0;
		int ret;
		char ** lines = (char**)malloc(sizeof(char*)*(items-1));
		int i;
		for(i=1;i<items;i++)
			lines[i-1] = SvPV(ST(i),PL_na);
		ret = gdk_imlib_data_to_pixmap(lines, &result, &mask);
		if (result) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkPixmap(result)));
		}
		if (mask) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkBitmap(mask)));
		}
		free(lines);
	}

void
gdk_imlib_get_cache_info(Class)
	SV *	Class
	PPCODE:
	{
		int cache_p, cache_i;
		gdk_imlib_get_cache_info(&cache_p, &cache_i);
		EXTEND(sp,2);
		PUSHs(sv_2mortal(newSViv(cache_p)));
		PUSHs(sv_2mortal(newSViv(cache_i)));
	}

void
gdk_imlib_set_cache_info(Class, cache_pixmaps, cache_images)
	SV *	Class
	int	cache_pixmaps
	int	cache_images
	CODE:
	gdk_imlib_set_cache_info(cache_pixmaps, cache_images);

gint
gdk_imlib_save_image(image, file, info=0)
	Gtk::Gdk::ImlibImage image
	char *	file
	Gtk::Gdk::Imlib::SaveInfo info
	CODE:
	RETVAL = gdk_imlib_save_image(image, file, info);
	OUTPUT:
	RETVAL

int
rgb_width(image)
	Gtk::Gdk::ImlibImage image
	CODE:
	RETVAL = image->rgb_width;
	OUTPUT:
	RETVAL

int
rgb_height(image)
	Gtk::Gdk::ImlibImage image
	CODE:
	RETVAL = image->rgb_height;
	OUTPUT:
	RETVAL

