#line 2 "Libpng.xs.tmpl"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* There is some kind of collision between a file included by "perl.h"
   and "png.h" for very old versions of libpng, like the one used on
   Ubuntu Linux. */

#define PNG_SKIP_SETJMP_CHECK
#include <png.h>
#include <stdarg.h>
#include <time.h>

#include "my-xs.h"
#include "perl-libpng.c"
#include "const-c.inc"

MODULE = Image::PNG::Libpng PACKAGE = Image::PNG::Libpng PREFIX = perl_png_

PROTOTYPES: ENABLE

INCLUDE: const-xs.inc

Image::PNG::Libpng perl_png_create_read_struct ()
        CODE:
        RETVAL = perl_png_create_read_struct ();
        OUTPUT:
        RETVAL

Image::PNG::Libpng perl_png_create_write_struct ()
        CODE:
        RETVAL = perl_png_create_write_struct ();
        OUTPUT:
        RETVAL

void perl_png_destroy_read_struct (Png)
        Image::PNG::Libpng  Png
        CODE:
        perl_png_destroy_read_struct (Png);
        OUTPUT:

void perl_png_destroy_write_struct (Png)
        Image::PNG::Libpng  Png
        CODE:
        perl_png_destroy_write_struct (Png);
        OUTPUT:

void perl_png_write_png (Png, transforms = PNG_TRANSFORM_IDENTITY)
        Image::PNG::Libpng  Png
        int transforms
        CODE:
        perl_png_write_png (Png, transforms);
        OUTPUT:

void perl_png_init_io (Png, fp)
        Image::PNG::Libpng  Png
        FILE * fp
CODE:
        png_init_io (Png->png, fp);
        Png->init_io_done = 1;

void perl_png_read_info (Png)
        Image::PNG::Libpng  Png
        CODE:
        png_read_info (Png->png, Png->info);
        OUTPUT:

void perl_png_read_update_info (Png)
        Image::PNG::Libpng  Png
        CODE:
        png_read_update_info (Png->png, Png->info);
        OUTPUT:

void perl_png_read_image (Png)
        Image::PNG::Libpng  Png
        CODE:
        perl_png_read_image (Png);
        OUTPUT:

void perl_png_read_png (Png, transforms = PNG_TRANSFORM_IDENTITY)
        Image::PNG::Libpng  Png
        int transforms
CODE:
        perl_png_read_png (Png, transforms);
OUTPUT:

SV * perl_png_get_text (Png)
        Image::PNG::Libpng  Png
        CODE:
        RETVAL = perl_png_get_text (Png);
        OUTPUT:
        RETVAL

void perl_png_set_text (Png, text)
        Image::PNG::Libpng  Png
        AV * text
        CODE:
        perl_png_set_text (Png, text);
        OUTPUT:

int perl_png_sig_cmp (sig, start = 0, num_to_check = 8)
        SV * sig
        int start
        int num_to_check
        CODE:
        RETVAL = perl_png_sig_cmp (sig, start, num_to_check);
        OUTPUT:
        RETVAL

void perl_png_scalar_as_input (Png, scalar, transforms = 0)
        Image::PNG::Libpng Png
        SV * scalar
        int transforms
        CODE:
        perl_png_scalar_as_input (Png, scalar, transforms);
        OUTPUT:

Image::PNG::Libpng perl_png_read_from_scalar (scalar, transforms = 0)
        SV * scalar
        int transforms
        CODE:
        RETVAL = perl_png_read_from_scalar (scalar, transforms);
        OUTPUT:
	RETVAL

const char * perl_png_color_type_name (color_type)
        int color_type
        CODE:
        RETVAL = perl_png_color_type_name (color_type);
        OUTPUT:
        RETVAL

const char * perl_png_text_compression_name (text_compression)
        int text_compression
        CODE:
        RETVAL = perl_png_text_compression_name (text_compression);
        OUTPUT:
        RETVAL

const char * perl_png_get_libpng_ver ()
        CODE:
        RETVAL = png_get_libpng_ver (0);
        OUTPUT:
        RETVAL

int perl_png_access_version_number ()
        CODE:
        RETVAL = png_access_version_number ();
        OUTPUT:
        RETVAL

void * perl_png_get_row_pointers (Png)
        Image::PNG::Libpng  Png
        CODE:
        RETVAL = perl_png_get_row_pointers (Png);
        OUTPUT:
        RETVAL

SV * perl_png_get_rows (Png)
        Image::PNG::Libpng  Png
        CODE:
        RETVAL = perl_png_get_rows (Png);
        OUTPUT:
        RETVAL

int perl_png_get_rowbytes (Png)
        Image::PNG::Libpng  Png
        CODE:
        RETVAL = png_get_rowbytes (Png->png, Png->info);
        OUTPUT:
        RETVAL


SV * perl_png_get_valid (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_valid (Png);
        OUTPUT:
        RETVAL

void perl_png_set_tRNS_pointer (Png, tRNS_pointer, num_tRNS_pointer)
        Image::PNG::Libpng Png
        void * tRNS_pointer
        int num_tRNS_pointer
        CODE:
        perl_png_set_tRNS_pointer (Png, tRNS_pointer, num_tRNS_pointer);
        OUTPUT:

void perl_png_set_rows (Png, rows)
        Image::PNG::Libpng Png
        AV * rows
        CODE:
        perl_png_set_rows (Png, rows);
        OUTPUT:

SV * perl_png_write_to_scalar (Png, transforms = 0)
        Image::PNG::Libpng Png
        int transforms;
        CODE:
        RETVAL = perl_png_write_to_scalar (Png, transforms);
        OUTPUT:
        RETVAL

void perl_png_set_filter (Png, filters)
        Image::PNG::Libpng Png
        int filters;
        CODE:
        png_set_filter (Png->png, 0, filters);
        OUTPUT:

void perl_png_set_verbosity (Png, verbosity = 0)
        Image::PNG::Libpng Png
        int verbosity; 
        CODE:
        perl_png_set_verbosity (Png, verbosity);
        OUTPUT:
        
void perl_png_set_unknown_chunks (Png, unknown_chunks)
        Image::PNG::Libpng Png
        AV * unknown_chunks
        CODE:
        perl_png_set_unknown_chunks (Png, unknown_chunks);
        OUTPUT:

SV * perl_png_get_unknown_chunks (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_unknown_chunks (Png);
        OUTPUT:
        RETVAL

int perl_png_libpng_supports (what)
        const char * what
CODE:
        RETVAL = perl_png_libpng_supports (what);
OUTPUT:
        RETVAL

void perl_png_set_keep_unknown_chunks (Png, keep, chunk_list = 0)
        Image::PNG::Libpng Png
        int keep
        SV * chunk_list
        CODE:
        perl_png_set_keep_unknown_chunks (Png, keep, chunk_list);
        OUTPUT:

SV * perl_png_get_tRNS_palette (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_tRNS_palette (Png);
        OUTPUT:
        RETVAL

void perl_png_set_PLTE_pointer (Png, colors, n_colors)
        Image::PNG::Libpng Png
        void * colors
        int n_colors
        CODE:
        perl_png_set_PLTE_pointer (Png, colors, n_colors);
        OUTPUT:

void perl_png_set_expand (Png)
        Image::PNG::Libpng Png
        CODE:
        perl_png_set_expand (Png);
        OUTPUT:

void perl_png_set_gray_to_rgb (Png)
        Image::PNG::Libpng Png
        CODE:
        perl_png_set_gray_to_rgb (Png);
        OUTPUT:

void perl_png_set_filler (Png, filler, flags)
        Image::PNG::Libpng Png
        int filler
        int flags
        CODE:
        perl_png_set_filler (Png, filler, flags);
        OUTPUT:

int perl_png_get_sRGB (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_sRGB (Png);
        OUTPUT:
        RETVAL

void perl_png_set_sRGB (Png, sRGB)
        Image::PNG::Libpng Png
        int sRGB
        CODE:
        perl_png_set_sRGB (Png, sRGB);
        OUTPUT:

void perl_png_set_packing (Png)
        Image::PNG::Libpng Png
        CODE:
        png_set_packing (Png->png);
        OUTPUT:

void perl_png_set_strip_16 (Png)
        Image::PNG::Libpng Png
        CODE:
        perl_png_set_strip_16 (Png);
        OUTPUT: 

void perl_png_DESTROY (Png)
        Image::PNG::Libpng Png
	CODE:
        if (Png) {
        	perl_png_destroy (Png);
	}
	OUTPUT:

SV * perl_png_get_bKGD (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_bKGD (Png);
        OUTPUT:
        RETVAL

void perl_png_set_bKGD (Png, bKGD)
        Image::PNG::Libpng Png
        HV * bKGD
        CODE:
        perl_png_set_bKGD (Png, bKGD);
        OUTPUT:


SV * perl_png_get_cHRM (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_cHRM (Png);
        OUTPUT:
        RETVAL

void perl_png_set_cHRM (Png, cHRM)
        Image::PNG::Libpng Png
        HV * cHRM
        CODE:
        perl_png_set_cHRM (Png, cHRM);
        OUTPUT:


SV * perl_png_get_gAMA (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_gAMA (Png);
        OUTPUT:
        RETVAL

void perl_png_set_gAMA (Png, gAMA)
        Image::PNG::Libpng Png
        double gAMA
        CODE:
        perl_png_set_gAMA (Png, gAMA);
        OUTPUT:


SV * perl_png_get_hIST (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_hIST (Png);
        OUTPUT:
        RETVAL

void perl_png_set_hIST (Png, hIST)
        Image::PNG::Libpng Png
        AV * hIST
        CODE:
        perl_png_set_hIST (Png, hIST);
        OUTPUT:


SV * perl_png_get_iCCP (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_iCCP (Png);
        OUTPUT:
        RETVAL

void perl_png_set_iCCP (Png, iCCP)
        Image::PNG::Libpng Png
        HV * iCCP
        CODE:
        perl_png_set_iCCP (Png, iCCP);
        OUTPUT:


SV * perl_png_get_IHDR (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_IHDR (Png);
        OUTPUT:
        RETVAL

void perl_png_set_IHDR (Png, IHDR)
        Image::PNG::Libpng Png
        HV * IHDR
        CODE:
        perl_png_set_IHDR (Png, IHDR);
        OUTPUT:


SV * perl_png_get_oFFs (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_oFFs (Png);
        OUTPUT:
        RETVAL

void perl_png_set_oFFs (Png, oFFs)
        Image::PNG::Libpng Png
        HV * oFFs
        CODE:
        perl_png_set_oFFs (Png, oFFs);
        OUTPUT:


SV * perl_png_get_pCAL (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_pCAL (Png);
        OUTPUT:
        RETVAL

void perl_png_set_pCAL (Png, pCAL)
        Image::PNG::Libpng Png
        HV * pCAL
        CODE:
        perl_png_set_pCAL (Png, pCAL);
        OUTPUT:


SV * perl_png_get_pHYs (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_pHYs (Png);
        OUTPUT:
        RETVAL

void perl_png_set_pHYs (Png, pHYs)
        Image::PNG::Libpng Png
        HV * pHYs
        CODE:
        perl_png_set_pHYs (Png, pHYs);
        OUTPUT:


SV * perl_png_get_PLTE (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_PLTE (Png);
        OUTPUT:
        RETVAL

void perl_png_set_PLTE (Png, PLTE)
        Image::PNG::Libpng Png
        AV * PLTE
        CODE:
        perl_png_set_PLTE (Png, PLTE);
        OUTPUT:


SV * perl_png_get_sBIT (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_sBIT (Png);
        OUTPUT:
        RETVAL

void perl_png_set_sBIT (Png, sBIT)
        Image::PNG::Libpng Png
        HV * sBIT
        CODE:
        perl_png_set_sBIT (Png, sBIT);
        OUTPUT:


SV * perl_png_get_sCAL (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_sCAL (Png);
        OUTPUT:
        RETVAL

void perl_png_set_sCAL (Png, sCAL)
        Image::PNG::Libpng Png
        HV * sCAL
        CODE:
        perl_png_set_sCAL (Png, sCAL);
        OUTPUT:


SV * perl_png_get_sPLT (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_sPLT (Png);
        OUTPUT:
        RETVAL

void perl_png_set_sPLT (Png, sPLT)
        Image::PNG::Libpng Png
        AV * sPLT
        CODE:
        perl_png_set_sPLT (Png, sPLT);
        OUTPUT:


SV * perl_png_get_tIME (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_tIME (Png);
        OUTPUT:
        RETVAL

void perl_png_set_tIME (Png, tIME =  0)
        Image::PNG::Libpng Png
        SV * tIME
        CODE:
        perl_png_set_tIME (Png, tIME);
        OUTPUT:


SV * perl_png_get_tRNS (Png)
        Image::PNG::Libpng Png
        CODE:
        RETVAL = perl_png_get_tRNS (Png);
        OUTPUT:
        RETVAL

void perl_png_set_tRNS (Png, tRNS)
        Image::PNG::Libpng Png
        SV * tRNS
        CODE:
        perl_png_set_tRNS (Png, tRNS);
        OUTPUT:


#line 353 "Libpng.xs.tmpl"

void perl_png_get_internals (Png)
	Image::PNG::Libpng Png
PREINIT:
	png_structp png;
	png_infop info;
	SV * png_sv;
	SV * info_sv;
PPCODE:
	png = Png->png;
	info = Png->info;
	png_sv = newSViv (PTR2IV (png));
	info_sv = newSViv (PTR2IV (info));
	XPUSHs(sv_2mortal(png_sv));
	XPUSHs(sv_2mortal(info_sv));

void perl_png_set_transforms (Png, transforms)
	Image::PNG::Libpng Png;
	int transforms;
CODE:
	perl_png_set_transforms (Png, transforms);
OUTPUT:

void perl_png_copy_row_pointers (Png, row_pointers)
	Image::PNG::Libpng Png;
	SV * row_pointers;
CODE:
	perl_png_copy_row_pointers (Png, row_pointers);
OUTPUT:


int
perl_png_get_image_width (Png)
	Image::PNG::Libpng Png;
CODE: 
    	RETVAL = perl_png_get_image_width (Png);
OUTPUT:
	RETVAL

int
perl_png_get_image_height (Png)
	Image::PNG::Libpng Png;
CODE: 
    	RETVAL = perl_png_get_image_height (Png);
OUTPUT:
	RETVAL




int
perl_png_get_channels (Png)
	Image::PNG::Libpng Png;
CODE: 
    	RETVAL = perl_png_get_channels (Png);
OUTPUT:
	RETVAL

int
perl_png_get_bit_depth (Png)
	Image::PNG::Libpng Png;
CODE: 
    	RETVAL = png_get_bit_depth (Png->png, Png->info);
OUTPUT:
	RETVAL

int
perl_png_get_interlace_type (Png)
	Image::PNG::Libpng Png;
CODE: 
    	RETVAL = png_get_interlace_type (Png->png, Png->info);
OUTPUT:
	RETVAL

int
perl_png_set_user_limits (Png, w, h)
	Image::PNG::Libpng Png;
	unsigned w;
	unsigned h;
CODE: 
	perl_png_set_user_limits (Png, w, h);


SV *
perl_png_get_user_width_max (Png)
	Image::PNG::Libpng Png;
CODE:
	RETVAL = perl_png_get_user_width_max (Png);
OUTPUT:
	RETVAL


SV *
perl_png_get_user_height_max (Png)
	Image::PNG::Libpng Png;
CODE:
	RETVAL = perl_png_get_user_height_max (Png);
OUTPUT:
	RETVAL



void
perl_png_set_image_data (Png, image_data, own = & PL_sv_undef)
	Image::PNG::Libpng Png;
	void * image_data;
	SV * own;
CODE:
	if (Png->type != perl_png_write_obj) {
		perl_png_error (Png, "Cannot set image data in read PNG");
	}
	Png->image_data = image_data;
	Png->memory_gets++;

void
perl_png_set_row_pointers (Png, row_pointers)
	Image::PNG::Libpng Png;
	SV * row_pointers;
CODE:
	if (Png->type != perl_png_write_obj) {
		perl_png_error (Png, "Cannot set row pointers in read PNG");
	}
	Png->row_pointers = INT2PTR (png_bytepp, SvIV (row_pointers));
        png_set_rows (Png->png, Png->info, Png->row_pointers);
	Png->memory_gets++;

int
perl_png_set_rgb_to_gray_fixed (Png, error_action = 1, red_weight=-1, green_weight=-1)
	Image::PNG::Libpng Png;
	int error_action;
	int red_weight;
	int green_weight;
CODE:
	png_set_rgb_to_gray_fixed (Png->png, error_action, red_weight, green_weight);
	RETVAL = png_get_rgb_to_gray_status (Png->png);
	png_read_update_info (Png->png, Png->info);
OUTPUT:
	RETVAL
