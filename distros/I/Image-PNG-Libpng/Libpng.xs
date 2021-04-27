#line 2 "Libpng.xs.tmpl"

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* There is some kind of collision between a file included by "perl.h"
   and "png.h" for very old versions of libpng, like the one used on
   Ubuntu Linux. */

#define PNG_SKIP_SETJMP_CHECK
#include <zlib.h>
#include <png.h>

#include <stdarg.h>
#include <time.h>

#include "my-xs.h"
#include "perl-libpng.c"
#include "const-c.inc"

MODULE = Image::PNG::Libpng PACKAGE = Image::PNG::Libpng PREFIX = perl_png_

PROTOTYPES: ENABLE

INCLUDE: const-xs.inc

 # Constructors and destructors

Image::PNG::Libpng
perl_png_create_read_struct ()
CODE:
        RETVAL = perl_png_create_read_struct ();
OUTPUT:
        RETVAL


Image::PNG::Libpng
perl_png_create_write_struct ()
CODE:
        RETVAL = perl_png_create_write_struct ();
OUTPUT:
        RETVAL

 # XS destructor, this does the work.

void
perl_png_DESTROY (Png)
        Image::PNG::Libpng Png
	CODE:
        if (Png) {
        	perl_png_destroy (Png);
	}

 # No-ops supplied since they used to be in use in old versions of the module.

void
perl_png_destroy_read_struct (Png)
        Image::PNG::Libpng  Png
CODE:
        perl_png_destroy_read_struct (Png);


void
perl_png_destroy_write_struct (Png)
        Image::PNG::Libpng  Png
CODE:
        perl_png_destroy_write_struct (Png);


 # libpng-style input/output functions

void
perl_png_write_image(Png, rows)
	Image::PNG::Libpng Png;
	AV * rows
CODE:
	check_init_io (Png);
	perl_png_write_image (Png, rows);


void
perl_png_write_info(Png)
	Image::PNG::Libpng Png;
CODE:
	check_init_io (Png);
	png_write_info (Png->png, Png->info);


void
perl_png_write_end(Png)
	Image::PNG::Libpng Png;
CODE:
	check_init_io (Png);
	png_write_end (Png->png, Png->info);


SV *
perl_png_read_image(Png)
	Image::PNG::Libpng Png;
CODE:
	check_init_io (Png);
	RETVAL = perl_png_read_image (Png);
OUTPUT:
	RETVAL


void
perl_png_read_end(Png)
	Image::PNG::Libpng Png;
CODE:
	check_init_io (Png);
	png_read_end (Png->png, Png->info);


void
perl_png_write_png (Png, transforms = PNG_TRANSFORM_IDENTITY)
        Image::PNG::Libpng  Png
        int transforms
CODE:
        perl_png_write_png (Png, transforms);


void
perl_png_init_io (Png, fpsv)
        Image::PNG::Libpng  Png
        SV * fpsv
CODE:
	perl_png_init_io_x (Png, fpsv);


void
perl_png_read_info (Png)
        Image::PNG::Libpng  Png
CODE:
	check_init_io (Png);
        png_read_info (Png->png, Png->info);


void
perl_png_read_update_info (Png)
        Image::PNG::Libpng  Png
CODE:
	check_init_io (Png);
        png_read_update_info (Png->png, Png->info);


void
perl_png_read_png (Png, transforms = PNG_TRANSFORM_IDENTITY)
        Image::PNG::Libpng  Png
        int transforms
CODE:
	check_init_io (Png);
        perl_png_read_png (Png, transforms);


SV *
perl_png_get_text (Png)
        Image::PNG::Libpng  Png
CODE:
        RETVAL = perl_png_get_text (Png);
OUTPUT:
        RETVAL


void
perl_png_set_text (Png, text)
        Image::PNG::Libpng  Png
        AV * text
CODE:
        perl_png_set_text (Png, text);


int
perl_png_sig_cmp (sig, start = 0, num_to_check = 8)
        SV * sig
        int start
        int num_to_check
CODE:
        RETVAL = perl_png_sig_cmp (sig, start, num_to_check);
OUTPUT:
        RETVAL


void
perl_png_scalar_as_input (Png, scalar, transforms = 0)
        Image::PNG::Libpng Png
        SV * scalar
        int transforms
CODE:
        perl_png_scalar_as_input (Png, scalar, transforms);


Image::PNG::Libpng
perl_png_read_from_scalar (scalar, transforms = 0)
        SV * scalar
        int transforms
CODE:
        RETVAL = perl_png_read_from_scalar (scalar, transforms);
OUTPUT:
	RETVAL


const char *
perl_png_get_libpng_ver ()
CODE:
        RETVAL = png_get_libpng_ver (UNUSED_ZERO_ARG);
OUTPUT:
        RETVAL


int
perl_png_access_version_number ()
CODE:
        RETVAL = png_access_version_number ();
OUTPUT:
        RETVAL


SV *
perl_png_get_rows (Png)
        Image::PNG::Libpng  Png
CODE:
        RETVAL = perl_png_get_rows (Png);
OUTPUT:
        RETVAL


int
perl_png_get_rowbytes (Png)
        Image::PNG::Libpng  Png
CODE:
        RETVAL = png_get_rowbytes (Png->png, Png->info);
OUTPUT:
        RETVAL


SV *
perl_png_get_valid (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_valid (Png);
OUTPUT:
        RETVAL


void
perl_png_set_tRNS_pointer (Png, tRNS_pointer, num_tRNS_pointer)
        Image::PNG::Libpng Png
        void * tRNS_pointer
        int num_tRNS_pointer
CODE:
        perl_png_set_tRNS_pointer (Png, tRNS_pointer, num_tRNS_pointer);


void
perl_png_set_rows (Png, rows)
        Image::PNG::Libpng Png
        AV * rows
CODE:
        perl_png_set_rows (Png, rows);


SV *
perl_png_write_to_scalar (Png, transforms = 0)
        Image::PNG::Libpng Png
        int transforms;
CODE:
        RETVAL = perl_png_write_to_scalar (Png, transforms);
OUTPUT:
        RETVAL


void
perl_png_set_filter (Png, filters)
        Image::PNG::Libpng Png
        int filters;
CODE:
        png_set_filter (Png->png, UNUSED_ZERO_ARG, filters);


void
perl_png_set_unknown_chunks (Png, unknown_chunks)
        Image::PNG::Libpng Png
        AV * unknown_chunks
CODE:
        perl_png_set_unknown_chunks (Png, unknown_chunks);


SV *
perl_png_get_unknown_chunks (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_unknown_chunks (Png);
OUTPUT:
        RETVAL


void
perl_png_set_keep_unknown_chunks (Png, keep, chunk_list = 0)
        Image::PNG::Libpng Png
        int keep
        SV * chunk_list
CODE:
        perl_png_set_keep_unknown_chunks (Png, keep, chunk_list);

int
perl_png_get_chunk_malloc_max (Png)
	Image::PNG::Libpng Png;
CODE:
#ifdef PNG_CHUNK_MALLOC_MAX_SUPPORTED
	RETVAL = png_get_chunk_malloc_max (Png->png);
#else
	UNSUPPORTED(CHUNK_MALLOC_MAX);
	RETVAL = 0;
#endif /* chunk_malloc_max supported */
OUTPUT:
	RETVAL


void
perl_png_set_chunk_malloc_max (Png, max)
	Image::PNG::Libpng Png;
	int max;
CODE:
#ifdef PNG_CHUNK_MALLOC_MAX_SUPPORTED
	png_set_chunk_malloc_max (Png->png, max);
#else
	UNSUPPORTED(CHUNK_MALLOC_MAX);
#endif /* chunk_malloc_max supported */





 # Chunk code which is not automatically generated.

int
perl_png_get_sRGB (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_sRGB (Png);
OUTPUT:
        RETVAL


void
perl_png_set_sRGB (Png, sRGB)
        Image::PNG::Libpng Png
        int sRGB
CODE:
        perl_png_set_sRGB (Png, sRGB);



SV *
perl_png_get_tRNS_palette (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_tRNS_palette (Png);
OUTPUT:
        RETVAL


 # Transform routines. These generally doesn't take any arguments but
 # usually do require conditional wrappers to compile on older
 # versions of libpng.

void
perl_png_set_add_alpha(Png, filler, filler_loc)
	Image::PNG::Libpng Png;
	unsigned int filler;
	int filler_loc;
CODE:
	if (Png->type == perl_png_read_obj) {
#if defined(PNG_READ_FILLER_SUPPORTED)
	    png_set_add_alpha (Png->png, filler, filler_loc);
#else
	    UNSUPPORTED(READ_FILLER);
#endif /* read/write filler */
	}
	else {
#if defined(PNG_WRITE_FILLER_SUPPORTED)
	    png_set_add_alpha (Png->png, filler, filler_loc);
#else
	    UNSUPPORTED(WRITE_FILLER);
#endif /* read/write filler */
	}

void
perl_png_set_alpha_mode (Png, mode, screen_gamma)
	Image::PNG::Libpng Png;
	int mode;
	double screen_gamma;
CODE:
#ifdef PNG_READ_ALPHA_MODE_SUPPORTED
	png_set_alpha_mode (Png->png, mode, screen_gamma);
#else
	UNSUPPORTED(READ_ALPHA_MODE);
#endif /* def PNG_READ_ALPHA_MODE */


void
perl_png_set_bgr(Png)
	Image::PNG::Libpng Png;
CODE:
	if (Png->type == perl_png_read_obj) { 
#if defined(PNG_READ_BGR_SUPPORTED)
            png_set_bgr (Png->png);
#else
	    UNSUPPORTED (READ_BGR);
#endif /* READ_BGR */
	}
	else {
#if defined(PNG_WRITE_BGR_SUPPORTED)
            png_set_bgr (Png->png);
#else
	    UNSUPPORTED (WRITE_BGR);
#endif /* WRITE_BGR */
	}


void
perl_png_set_expand (Png)
        Image::PNG::Libpng Png
CODE:
#ifdef PNG_READ_EXPAND_SUPPORTED
        png_set_expand (Png->png);
#else
	UNSUPPORTED (READ_EXPAND);
#endif /* READ_EXPAND */


void
perl_png_set_expand_16 (Png)
        Image::PNG::Libpng Png
CODE:
#ifdef PNG_READ_EXPAND_16_SUPPORTED
        png_set_expand_16 (Png->png);
#else
	UNSUPPORTED (READ_EXPAND_16);
#endif /* READ_EXPAND_16 */


void
perl_png_set_filler (Png, filler, flags)
        Image::PNG::Libpng Png
        int filler
        int flags
CODE:
	if (Png->type == perl_png_read_obj) { 
#if defined(PNG_READ_FILLER_SUPPORTED)
	    png_set_filler (Png->png, filler, flags);
#else
	    UNSUPPORTED (READ_FILLER);
#endif /* read/write filler */
	}
	else {
#if defined(PNG_WRITE_FILLER_SUPPORTED)
	    png_set_filler (Png->png, filler, flags);
#else
	    UNSUPPORTED (WRITE_FILLER);
#endif /* read/write filler */
	}


void
perl_png_set_gray_to_rgb (Png)
        Image::PNG::Libpng Png
CODE:
#ifdef PNG_READ_GRAY_TO_RGB_SUPPORTED
        png_set_gray_to_rgb (Png->png);
#else
	UNSUPPORTED (READ_GRAY_TO_RGB);
#endif /* READ_GRAY_TO_RGB */


void
perl_png_set_expand_gray_1_2_4_to_8(Png)
	Image::PNG::Libpng Png;
CODE:
#ifdef PNG_READ_EXPAND_SUPPORTED
	png_set_expand_gray_1_2_4_to_8 (Png->png);
#else
	UNSUPPORTED (READ_EXPAND);
#endif /* read_expand */


void
perl_png_set_invert_alpha(Png)
	Image::PNG::Libpng Png;
CODE:
#ifdef PNG_READ_INVERT_ALPHA_SUPPORTED
	png_set_invert_alpha (Png->png);
#else
	UNSUPPORTED (READ_INVERT_ALPHA);
#endif /* READ_INVERT_ALPHA */


void
perl_png_set_invert_mono(Png)
	Image::PNG::Libpng Png;
CODE:
#ifdef PNG_READ_INVERT_SUPPORTED
	png_set_invert_mono (Png->png);
#else
	UNSUPPORTED (READ_INVERT);
#endif /* READ_INVERT */


void
perl_png_set_packing (Png)
        Image::PNG::Libpng Png
CODE:
	if (Png->type == perl_png_read_obj) { 
#if defined(PNG_READ_PACK_SUPPORTED)
            png_set_packing (Png->png);
#else
	    UNSUPPORTED (READ_PACK);
#endif /* READ_PACK */
	}
	else {
#if defined(PNG_WRITE_PACK_SUPPORTED)
            png_set_packing (Png->png);
#else
	    UNSUPPORTED (WRITE_PACK);
#endif /* WRITE_PACK */
	}

void
perl_png_set_packswap(Png)
	Image::PNG::Libpng Png;
CODE:
	if (Png->type == perl_png_read_obj) { 
#if defined(PNG_READ_PACKSWAP_SUPPORTED)
            png_set_packing (Png->png);
#else
	    UNSUPPORTED (READ_PACKSWAP);
#endif /* READ_PACKSWAP */
	}
	else {
#if defined(PNG_WRITE_PACKSWAP_SUPPORTED)
	    png_set_packswap (Png->png);
#else
	    UNSUPPORTED (WRITE_PACKSWAP);
#endif /* WRITE_PACKSWAP */
	}


void
perl_png_set_palette_to_rgb(Png)
	Image::PNG::Libpng Png;
CODE:
#ifdef PNG_READ_EXPAND_SUPPORTED
	png_set_palette_to_rgb (Png->png);
#else
	UNSUPPORTED (READ_EXPAND);
#endif /* READ_EXPAND */


void
perl_png_set_scale_16(Png)
	Image::PNG::Libpng Png;
CODE:
#ifdef PNG_READ_SCALE_16_TO_8_SUPPORTED
	png_set_scale_16 (Png->png);
#else
	UNSUPPORTED (READ_SCALE_16_TO_8);
#endif /* READ_SCALE_16_TO_8 */


void
perl_png_set_tRNS_to_alpha(Png)
	Image::PNG::Libpng Png;
CODE:
#ifdef PNG_READ_EXPAND_SUPPORTED
	png_set_tRNS_to_alpha(Png->png);
#else
	UNSUPPORTED (READ_EXPAND);
#endif /* read_expand */


void
perl_png_set_strip_16 (Png)
        Image::PNG::Libpng Png
CODE:
#ifdef PNG_READ_STRIP_16_TO_8_SUPPORTED
        png_set_strip_16 (Png->png);
#else 
	UNSUPPORTED (READ_STRIP_16_TO_8);
#endif /* READ_STRIP_16_TO_8 */


void
perl_png_set_strip_alpha (Png)
        Image::PNG::Libpng Png
CODE:
#ifdef PNG_READ_STRIP_ALPHA_SUPPORTED
        png_set_strip_alpha (Png->png);
#else 
	UNSUPPORTED (READ_STRIP_ALPHA);
#endif /* READ_STRIP_ALPHA */


void
perl_png_set_swap(Png)
	Image::PNG::Libpng Png;
CODE:
	if (Png->type == perl_png_read_obj) { 
#if defined(PNG_READ_SWAP_SUPPORTED)
	    png_set_swap (Png->png);
#else
	    UNSUPPORTED (WRITE_SWAP);
#endif
	}
	else {
#if defined(PNG_WRITE_SWAP_SUPPORTED)
	    png_set_swap (Png->png);
#else
	    UNSUPPORTED (READ_SWAP);
#endif
	}

void
perl_png_set_swap_alpha(Png)
	Image::PNG::Libpng Png;
CODE:
#ifdef PNG_READ_SWAP_ALPHA_SUPPORTED
	png_set_swap_alpha (Png->png);
#else
	UNSUPPORTED (READ_SWAP_ALPHA);
#endif /* READ_SWAP_ALPHA */


void
perl_png_set_transforms (Png, transforms)
	Image::PNG::Libpng Png;
	int transforms;
CODE:
	perl_png_set_transforms (Png, transforms);
OUTPUT:


int
perl_png_get_palette_max(Png)
	Image::PNG::Libpng Png;
CODE:
	RETVAL = -1;
#ifdef PNG_CHECK_FOR_INVALID_INDEX_SUPPORTED
#  ifdef PNG_GET_PALETTE_MAX_SUPPORTED
	RETVAL = png_get_palette_max (Png->png, Png->info);
#  else
	UNSUPPORTED (GET_PALETTE_MAX);
#  endif
#else
        UNSUPPORTED (CHECK_FOR_INVALID_INDEX);
#endif
OUTPUT:
	RETVAL


 # Functions which retrieve individual values from the header.



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
perl_png_get_color_type (Png)
	Image::PNG::Libpng Png;
CODE: 
    	RETVAL = png_get_color_type (Png->png, Png->info);
OUTPUT:
	RETVAL

 # http://www.cpantesters.org/cpan/report/fc1cade6-3f17-11eb-9d08-9e4a1f24ea8f

#ifdef PNG_SET_USER_LIMITS_SUPPORTED

void
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
perl_png_set_chunk_cache_max(Png, max)
	Image::PNG::Libpng Png;
	int max;
CODE:
#ifdef PNG_CHUNK_CACHE_MAX_SUPPORTED
	png_set_chunk_cache_max(Png->png, max);
#else
	UNSUPPORTED (CHUNK_CACHE_MAX);
#endif /* CHUNK_CACHE_MAX */


int
perl_png_get_chunk_cache_max(Png)
	Image::PNG::Libpng Png;
CODE:
#ifdef PNG_CHUNK_CACHE_MAX_SUPPORTED
	RETVAL = png_get_chunk_cache_max(Png->png);
#else
	RETVAL = -1;
	UNSUPPORTED (CHUNK_CACHE_MAX);
#endif /* CHUNK_CACHE_MAX */
OUTPUT:
	RETVAL

#endif /* SET_USER_LIMITS */


void
perl_png_set_image_data (Png, image_data, own = & PL_sv_undef)
	Image::PNG::Libpng Png;
	void * image_data;
	SV * own;
CODE:
	if (Png->type != perl_png_write_obj) {
		croak ("Cannot set image data in read PNG");
	}
	Png->image_data = image_data;
	Png->memory_gets++;


void
perl_png_set_row_pointers (Png, row_pointers)
	Image::PNG::Libpng Png;
	SV * row_pointers;
CODE:
	if (Png->type != perl_png_write_obj) {
		croak ("Cannot set row pointe	rs in read PNG");
	}
	Png->row_pointers = INT2PTR (png_bytepp, SvIV (row_pointers));
        png_set_rows (Png->png, Png->info, Png->row_pointers);
	Png->memory_gets++;

 # These functions predate the macro and were valid in libpng 1.2, yet
 # the macro is invalid except for libpng 1.6.17, so conditional
 # compilation doesn't seem to offer any benefit, hence the following
 # is commented out. 

 # #ifdef PNG_WRITE_CUSTOMIZE_COMPRESSION_SUPPORTED

void
perl_png_set_compression_level (Png, level)
	Image::PNG::Libpng Png;
	int level
CODE:
	if (level != Z_DEFAULT_COMPRESSION) {
	    if (level < Z_NO_COMPRESSION || level > Z_BEST_COMPRESSION) {
		croak ("Compression level must be %d for default or "
		       "between %d and %d",
		       Z_DEFAULT_COMPRESSION, Z_NO_COMPRESSION,
		       Z_BEST_COMPRESSION);
	    }
	}
	png_set_compression_level (Png->png, level);

void
perl_png_set_compression_buffer_size (Png, size)
	Image::PNG::Libpng Png;
	size_t size;
CODE:
	png_set_compression_buffer_size (Png->png, size);


SV *
perl_png_get_compression_buffer_size (Png)
	Image::PNG::Libpng Png;
PREINIT:
	size_t size;
CODE:
	size = png_get_compression_buffer_size (Png->png);
	RETVAL = newSViv (size);
OUTPUT:
	RETVAL
	

void
perl_png_set_compression_mem_level (Png, mem_level);
	Image::PNG::Libpng Png;
	int mem_level;
CODE:
	png_set_compression_mem_level (Png->png, mem_level);


void
perl_png_set_compression_strategy (Png, strategy);
	Image::PNG::Libpng Png;
	int strategy;
CODE:
	png_set_compression_strategy (Png->png, strategy);


void
perl_png_set_compression_window_bits  (Png,   window_bits);
	Image::PNG::Libpng Png;
	int window_bits;
CODE:
	png_set_compression_window_bits (Png->png, window_bits);

 # #endif /* WRITE_CUSTOMIZE_COMPRESSION */


 # This macro is not documented in CHANGES in libpng.

#ifdef PNG_WRITE_CUSTOMIZE_ZTXT_COMPRESSION_SUPPORTED

void
perl_png_set_text_compression_level (Png, level);
	Image::PNG::Libpng Png;
	int level;
CODE:
	png_set_text_compression_level (Png->png, level);


void
perl_png_set_text_compression_mem_level (Png, mem_level);
	Image::PNG::Libpng Png;
	int mem_level;
CODE:
	png_set_compression_mem_level (Png->png, mem_level);


void
perl_png_set_text_compression_strategy (Png, strategy);
	Image::PNG::Libpng Png;
	int strategy;
CODE:
	png_set_compression_strategy (Png->png, strategy);


void
perl_png_set_text_compression_window_bits  (Png,   window_bits);
	Image::PNG::Libpng Png;
	int window_bits;
CODE:
	png_set_compression_window_bits (Png->png, window_bits);

#endif /* WRITE_CUSTOMIZE_ZTXT_COMPRESSION */


#if 0

void
perl_png_set_compression_method (Png, method);
	Image::PNG::Libpng Png;
	int method;
CODE:
	png_set_compression_method (Png->png, method);

#endif /* 0 */

#if 0

void
perl_png_set_crc_action  (Png, crit_action, ancil_action);
	Image::PNG::Libpng Png;
	int crit_action;
	int ancil_action;
CODE:
	png_set_crc_action (Png->png, crit_action, ancil_action);

#endif /* 0 */


void
perl_png_set_gamma (Png, gamma, override_gamma)
	Image::PNG::Libpng Png;
	double gamma;
	double override_gamma;
CODE:
#ifdef PNG_READ_GAMMA_SUPPORTED
	png_set_gamma (Png->png, gamma, override_gamma);
#else
	UNSUPPORTED (READ_GAMMA);
#endif /* READ_GAMMA */
	

void
perl_png_permit_mng_features(Png, mask)
	Image::PNG::Libpng Png;
	int mask;
CODE:
#ifdef PNG_MNG_FEATURES_SUPPORTED
	png_permit_mng_features(Png->png, mask);
#else
	UNSUPPORTED (MNG_FEATURES);
#endif /* MNG_FEATURES */


 # Transform functions which require arguments.

void
perl_png_set_quantize(Png, palette, max_screen_colors, histogram, full_quantize_sv)
	Image::PNG::Libpng Png;
	AV * palette;
	int max_screen_colors;
	AV * histogram;
	SV * full_quantize_sv;
PREINIT:
	int full_quantize;
CODE:
	full_quantize = SvTRUE (full_quantize_sv);
	perl_png_set_quantize(Png, palette, max_screen_colors, histogram,
			      full_quantize);


 # These macros are for rgb_to_gray

#ifndef PNG_RGB_TO_GRAY_DEFAULT
#define PNG_RGB_TO_GRAY_DEFAULT (-1)
#endif /* PNG_RGB_TO_GRAY_DEFAULT */

#ifndef PNG_ERROR_ACTION_NONE
#define PNG_ERROR_ACTION_NONE 1
#endif /* ndef PNG_ERROR_ACTION_NONE */
	
void
perl_png_set_rgb_to_gray (Png, error_action = PNG_ERROR_ACTION_NONE, red = PNG_RGB_TO_GRAY_DEFAULT, green = PNG_RGB_TO_GRAY_DEFAULT)
	Image::PNG::Libpng Png;
	int error_action;
	double red;
	double green;
CODE: 
#ifdef PNG_READ_RGB_TO_GRAY_SUPPORTED
    	perl_png_set_rgb_to_gray (Png, error_action, red, green);
#else
	UNSUPPORTED ("READ_RGB_TO_GRAY");
#endif /* READ_RGB_TO_GRAY */

#undef DEFAULT_WEIGHT

int
perl_png_get_rgb_to_gray_status (Png)
	Image::PNG::Libpng Png;
CODE: 
#ifdef PNG_READ_RGB_TO_GRAY_SUPPORTED
    	RETVAL = (int) png_get_rgb_to_gray_status (Png->png);
#else
	UNSUPPORTED ("READ_RGB_TO_GRAY");
	RETVAL = 0;
#endif /* READ_RGB_TO_GRAY */
OUTPUT:
	RETVAL


void
perl_png_set_background(Png, perl_color, gamma_code, need_expand, background_gamma = 1)
	Image::PNG::Libpng Png;
	HV * perl_color;
	int gamma_code;
	SV * need_expand;
	double background_gamma;
CODE:
#ifdef PNG_READ_BACKGROUND_SUPPORTED
	perl_png_set_back (Png, perl_color, gamma_code, SvTRUE(need_expand),
			   background_gamma);
#else
	UNSUPPORTED (READ_BACKGROUND);
#endif /* READ_BACKGROUND */


 # These functions are not part of libpng and do not need preprocessor
 # conditional wrappers.

int
perl_png_color_type_channels (color_type)
        int color_type
CODE:
        RETVAL = perl_png_color_type_channels (color_type);
OUTPUT:
        RETVAL


const char *
perl_png_color_type_name (color_type)
        int color_type
CODE:
        RETVAL = perl_png_color_type_name (color_type);
OUTPUT:
        RETVAL


void
perl_png_copy_row_pointers (Png, row_pointers)
	Image::PNG::Libpng Png;
	SV * row_pointers;
CODE:
	perl_png_copy_row_pointers (Png, row_pointers);


void
perl_png_get_internals (Png)
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


int
perl_png_libpng_supports (what)
        const char * what
CODE:
        RETVAL = perl_png_libpng_supports (what);
OUTPUT:
        RETVAL


int
perl_png_read_struct (Png)
	Image::PNG::Libpng Png;
CODE:
	RETVAL = (Png->type == perl_png_read_obj);
OUTPUT:
	RETVAL


void
perl_png_set_verbosity (Png, verbosity = 0)
        Image::PNG::Libpng Png
        int verbosity; 
CODE:
        perl_png_set_verbosity (Png, verbosity);
        

SV *
perl_png_split_alpha (Png)
	Image::PNG::Libpng Png;
CODE:
	RETVAL = perl_png_split_alpha (Png);
OUTPUT:
	RETVAL


const char *
perl_png_text_compression_name (text_compression)
        int text_compression
CODE:
        RETVAL = perl_png_text_compression_name (text_compression);
OUTPUT:
        RETVAL

SV *
perl_png_get_pixel (png, x, y)
	Image::PNG::Libpng png;
	int x;
	int y;
PREINIT:
CODE:
	RETVAL = perl_png_get_pixel (png, x, y);
OUTPUT:
	RETVAL
	

 # The following automatically generates the get and set functions for
 # the chunks.

SV *
perl_png_get_bKGD (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_bKGD (Png);
OUTPUT:
        RETVAL

void
perl_png_set_bKGD (Png, bKGD)
        Image::PNG::Libpng Png
        HV * bKGD
CODE:
        perl_png_set_bKGD (Png, bKGD);


SV *
perl_png_get_cHRM (Png)
        Image::PNG::Libpng Png
CODE:
#ifdef PNG_cHRM_SUPPORTED
        RETVAL = perl_png_get_cHRM (Png);
#else /* PNG_cHRM_SUPPORTED */
	RETVAL = & PL_sv_undef;
	UNSUPPORTED (cHRM);
#endif /* PNG_cHRM_SUPPORTED */
OUTPUT:
        RETVAL

void
perl_png_set_cHRM (Png, cHRM)
        Image::PNG::Libpng Png
        HV * cHRM
CODE:
#ifdef PNG_cHRM_SUPPORTED
        perl_png_set_cHRM (Png, cHRM);
#else /* PNG_cHRM_SUPPORTED */
	UNSUPPORTED (cHRM);
#endif /* PNG_cHRM_SUPPORTED */


SV *
perl_png_get_cHRM_XYZ (Png)
        Image::PNG::Libpng Png
CODE:
#ifdef PNG_cHRM_XYZ_SUPPORTED
        RETVAL = perl_png_get_cHRM_XYZ (Png);
#else /* PNG_cHRM_XYZ_SUPPORTED */
	RETVAL = & PL_sv_undef;
	UNSUPPORTED (cHRM_XYZ);
#endif /* PNG_cHRM_XYZ_SUPPORTED */
OUTPUT:
        RETVAL

void
perl_png_set_cHRM_XYZ (Png, cHRM_XYZ)
        Image::PNG::Libpng Png
        HV * cHRM_XYZ
CODE:
#ifdef PNG_cHRM_XYZ_SUPPORTED
        perl_png_set_cHRM_XYZ (Png, cHRM_XYZ);
#else /* PNG_cHRM_XYZ_SUPPORTED */
	UNSUPPORTED (cHRM_XYZ);
#endif /* PNG_cHRM_XYZ_SUPPORTED */


SV *
perl_png_get_eXIf (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_eXIf (Png);
OUTPUT:
        RETVAL

void
perl_png_set_eXIf (Png, eXIf)
        Image::PNG::Libpng Png
        SV * eXIf
CODE:
        perl_png_set_eXIf (Png, eXIf);


SV *
perl_png_get_gAMA (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_gAMA (Png);
OUTPUT:
        RETVAL

void
perl_png_set_gAMA (Png, gAMA)
        Image::PNG::Libpng Png
        double gAMA
CODE:
        perl_png_set_gAMA (Png, gAMA);


SV *
perl_png_get_hIST (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_hIST (Png);
OUTPUT:
        RETVAL

void
perl_png_set_hIST (Png, hIST)
        Image::PNG::Libpng Png
        AV * hIST
CODE:
        perl_png_set_hIST (Png, hIST);


SV *
perl_png_get_iCCP (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_iCCP (Png);
OUTPUT:
        RETVAL

void
perl_png_set_iCCP (Png, iCCP)
        Image::PNG::Libpng Png
        HV * iCCP
CODE:
        perl_png_set_iCCP (Png, iCCP);


SV *
perl_png_get_IHDR (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_IHDR (Png);
OUTPUT:
        RETVAL

void
perl_png_set_IHDR (Png, IHDR)
        Image::PNG::Libpng Png
        HV * IHDR
CODE:
        perl_png_set_IHDR (Png, IHDR);


SV *
perl_png_get_oFFs (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_oFFs (Png);
OUTPUT:
        RETVAL

void
perl_png_set_oFFs (Png, oFFs)
        Image::PNG::Libpng Png
        HV * oFFs
CODE:
        perl_png_set_oFFs (Png, oFFs);


SV *
perl_png_get_pCAL (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_pCAL (Png);
OUTPUT:
        RETVAL

void
perl_png_set_pCAL (Png, pCAL)
        Image::PNG::Libpng Png
        HV * pCAL
CODE:
        perl_png_set_pCAL (Png, pCAL);


SV *
perl_png_get_pHYs (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_pHYs (Png);
OUTPUT:
        RETVAL

void
perl_png_set_pHYs (Png, pHYs)
        Image::PNG::Libpng Png
        HV * pHYs
CODE:
        perl_png_set_pHYs (Png, pHYs);


SV *
perl_png_get_PLTE (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_PLTE (Png);
OUTPUT:
        RETVAL

void
perl_png_set_PLTE (Png, PLTE)
        Image::PNG::Libpng Png
        AV * PLTE
CODE:
        perl_png_set_PLTE (Png, PLTE);


SV *
perl_png_get_sBIT (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_sBIT (Png);
OUTPUT:
        RETVAL

void
perl_png_set_sBIT (Png, sBIT)
        Image::PNG::Libpng Png
        HV * sBIT
CODE:
        perl_png_set_sBIT (Png, sBIT);


SV *
perl_png_get_sCAL (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_sCAL (Png);
OUTPUT:
        RETVAL

void
perl_png_set_sCAL (Png, sCAL)
        Image::PNG::Libpng Png
        HV * sCAL
CODE:
        perl_png_set_sCAL (Png, sCAL);


SV *
perl_png_get_sPLT (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_sPLT (Png);
OUTPUT:
        RETVAL

void
perl_png_set_sPLT (Png, sPLT)
        Image::PNG::Libpng Png
        AV * sPLT
CODE:
        perl_png_set_sPLT (Png, sPLT);


SV *
perl_png_get_tIME (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_tIME (Png);
OUTPUT:
        RETVAL

void
perl_png_set_tIME (Png, tIME =  0)
        Image::PNG::Libpng Png
        SV * tIME
CODE:
        perl_png_set_tIME (Png, tIME);


SV *
perl_png_get_tRNS (Png)
        Image::PNG::Libpng Png
CODE:
        RETVAL = perl_png_get_tRNS (Png);
OUTPUT:
        RETVAL

void
perl_png_set_tRNS (Png, tRNS)
        Image::PNG::Libpng Png
        SV * tRNS
CODE:
        perl_png_set_tRNS (Png, tRNS);


