
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk/gtk.h>
#include <gdk_imlib.h>

#include "GtkTypes.h"
#include "GdkTypes.h"
#include "MiscTypes.h"

#include "GtkDefs.h"

#ifndef boolSV
# define boolSV(b) ((b) ? &sv_yes : &sv_no)
#endif

typedef GdkImlibImage * Gtk__Gdk__ImlibImage;

SV * newSVGdkImlibImage(GdkImlibImage * value) {
	int n = 0;
	SV * result = newSVMiscRef(value, "Gtk::Gdk::ImlibImage", &n);
	return result;
}

GdkImlibImage * SvGdkImlibImage(SV * value) { return (GdkImlibImage*)SvMiscRef(value, "Gtk::Gdk::ImlibImage"); }


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
	SV * Class
	CODE:
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

# comment gdk_imlib_best_color_match()

int
gdk_imlib_render( self, width, height)
	Gtk::Gdk::ImlibImage self
	int width
	int height

Gtk::Gdk::Pixmap
gdk_imlib_copy_image(self)
	Gtk::Gdk::ImlibImage self

Gtk::Gdk::Bitmap
gdk_imlib_copy_mask(self)
	Gtk::Gdk::ImlibImage self

Gtk::Gdk::Pixmap
gdk_imlib_move_image(self)
	Gtk::Gdk::ImlibImage self

Gtk::Gdk::Bitmap
gdk_imlib_move_mask(self)
	Gtk::Gdk::ImlibImage self

void
gdk_imlib_destroy_image(self)
	Gtk::Gdk::ImlibImage self

void
gdk_imlib_kill_image(self)
	Gtk::Gdk::ImlibImage self

void
gdk_imlib_free_colors(Class)
	SV * Class
	CODE:
	gdk_imlib_free_colors();


# comment missing get/set border/shape

int
gdk_imlib_save_image_to_eim(self, file)
	Gtk::Gdk::ImlibImage self
	char* file

int
gdk_imlib_add_image_to_eim(self, file)
	Gtk::Gdk::ImlibImage self
	char* file

int
gdk_imlib_save_image_to_ppm(self, file)
	Gtk::Gdk::ImlibImage self
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

# comment missing *modifier

void
gdk_imlib_set_image_red_curve(self, mod)
	Gtk::Gdk::ImlibImage self
	SV * mod
	CODE:
	{
		STRLEN len;
		unsigned char* rmod = SvPV(mod, len);
		if ( len < 256 )
			croak("mod must be 256 bytes long");
		gdk_imlib_set_image_red_curve(self, rmod);
	}

void
gdk_imlib_set_image_green_curve(self, mod)
	Gtk::Gdk::ImlibImage self
	SV * mod
	CODE:
	{
		STRLEN len;
		unsigned char* rmod = SvPV(mod, len);
		if ( len < 256 )
			croak("mod must be 256 bytes long");
		gdk_imlib_set_image_green_curve(self, rmod);
	}

void
gdk_imlib_set_image_blue_curve(self, mod)
	Gtk::Gdk::ImlibImage self
	SV * mod
	CODE:
	{
		STRLEN len;
		unsigned char* rmod = SvPV(mod, len);
		if ( len < 256 )
			croak("mod must be 256 bytes long");
		gdk_imlib_set_image_blue_curve(self, rmod);
	}

SV*
gdk_imlib_get_image_red_curve(self)
	Gtk::Gdk::ImlibImage self
	CODE:
	{
		unsigned char mod[256];
		gdk_imlib_get_image_red_curve(self, mod);
		sv_setpvn(RETVAL, mod, 256);
	}
	OUTPUT:
	RETVAL

SV*
gdk_imlib_get_image_green_curve(self)
	Gtk::Gdk::ImlibImage self
	CODE:
	{
		unsigned char mod[256];
		gdk_imlib_get_image_green_curve(self, mod);
		sv_setpvn(RETVAL, mod, 256);
	}
	OUTPUT:
	RETVAL

SV*
gdk_imlib_get_image_blue_curve(self)
	Gtk::Gdk::ImlibImage self
	CODE:
	{
		unsigned char mod[256];
		gdk_imlib_get_image_blue_curve(self, mod);
		sv_setpvn(RETVAL, mod, 256);
	}
	OUTPUT:
	RETVAL

void
gdk_imlib_apply_modifiers_to_rgb(self)
	Gtk::Gdk::ImlibImage self

void
gdk_imlib_changed_image(self)
	Gtk::Gdk::ImlibImage self

void
gdk_imlib_apply_image(self, window)
	Gtk::Gdk::ImlibImage self
	Gtk::Gdk::Window window

void
gdk_imlib_paste_image(self, window, x, y, w, h)
	Gtk::Gdk::ImlibImage self
	Gtk::Gdk::Window window
	int x
	int y
	int w
	int h

void
gdk_imlib_paste_image_border(self, window, x, y, w, h)
	Gtk::Gdk::ImlibImage self
	Gtk::Gdk::Window window
	int x
	int y
	int w
	int h

void
gdk_imlib_flip_image_horizontal(self)
	Gtk::Gdk::ImlibImage self

void
gdk_imlib_flip_image_vertical(self)
	Gtk::Gdk::ImlibImage self

void
gdk_imlib_rotate_image(self, d)
	Gtk::Gdk::ImlibImage self
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
gdk_imlib_clone_image(self)
	Gtk::Gdk::ImlibImage self

Gtk::Gdk::ImlibImage
gdk_imlib_clone_scaled_image(self, w, h)
	Gtk::Gdk::ImlibImage self
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
			lines[i-1] = SvPV(ST(i),na);
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
			lines[i-1] = SvPV(ST(i),na);
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

int
rgb_width(self)
	Gtk::Gdk::ImlibImage self
	CODE:
	RETVAL = self->rgb_width;
	OUTPUT:
	RETVAL

int
rgb_height(self)
	Gtk::Gdk::ImlibImage self
	CODE:
	RETVAL = self->rgb_height;
	OUTPUT:
	RETVAL

