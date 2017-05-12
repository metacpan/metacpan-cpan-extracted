#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "cairo.h"

/* There is some kind of collision between a file included by "perl.h"
   and "png.h" for very old versions of libpng, like the one used on
   Ubuntu Linux. */

#define PNG_SKIP_SETJMP_CHECK

#include "png.h"

#include "image-png-cairo-perl.c"

MODULE=Image::PNG::Cairo PACKAGE=Image::PNG::Cairo

PROTOTYPES: DISABLE

void * fill_png_from_cairo_surface (surface, png, info)
     	SV * surface;
	SV * png;
	SV * info;
PREINIT:
	cairo_surface_t * csurface;
	png_struct * cpng;
	png_info * cinfo;
	png_byte ** row_pointers;
CODE:
	csurface = INT2PTR (cairo_surface_t *, SvIV ((SV *) SvRV (surface)));
	cpng = INT2PTR (png_struct *, SvIV (png));
	cinfo = INT2PTR (png_info *, SvIV (info));

	row_pointers = fill_png_from_cairo_surface (csurface, cpng, cinfo);
	RETVAL = row_pointers;
OUTPUT:
	RETVAL

void free_row_pointers (row_pointers)
	SV * row_pointers
PREINIT:
	png_byte ** crow_pointers;
CODE:
	crow_pointers = INT2PTR (png_byte **, SvIV (row_pointers));
	Safefree (crow_pointers);
