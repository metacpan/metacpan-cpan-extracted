#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* There is some kind of collision between a file included by "perl.h"
   and "png.h" for very old versions of libpng, like the one used on
   Ubuntu Linux. */

#define PNG_SKIP_SETJMP_CHECK

#include <png.h>

#define UNUSED_ZERO_ARG 0

#include "image-png-data-perl.c"

typedef image_png_data_t * Image__PNG__Data;

MODULE=Image::PNG::Data PACKAGE=Image::PNG::Data

PROTOTYPES: DISABLE

Image::PNG::Data
from_png (png, info)
	SV * png;
	SV * info;
CODE:
	Newxz(RETVAL, 1, image_png_data_t);
	RETVAL->png = INT2PTR (png_struct *, SvIV (png));
	RETVAL->info = INT2PTR (png_info *, SvIV (info));
	png_get_IHDR (RETVAL->png, RETVAL->info, & RETVAL->width,
		      & RETVAL->height, & RETVAL->bit_depth,
		      & RETVAL->color_type, & RETVAL->interlace_type,
		      UNUSED_ZERO_ARG, UNUSED_ZERO_ARG);
	RETVAL->channels = png_get_channels (RETVAL->png, RETVAL->info);
	RETVAL->rowbytes = png_get_rowbytes (RETVAL->png, RETVAL->info);
	RETVAL->rows = png_get_rows (RETVAL->png, RETVAL->info);
OUTPUT:
	RETVAL

SV *
alpha_unused_data (data)
	Image::PNG::Data data
CODE:
	RETVAL = image_png_data_alpha_unused (data);
OUTPUT:
	RETVAL
