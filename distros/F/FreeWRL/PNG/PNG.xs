/* 
 * Copyright(C) 1998 Tuomas J. Lukka
 * DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
 * See the GNU General Library Public License (the file COPYING in the FreeWRL
 * distribution) for details.
 */

#include "zlib.h"
#include "pngconf.h"
#include "png.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/fcntl.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include <stdio.h>

#define RETVAL XXX_RETVAL

#define HDNO 8
static char header[HDNO+10];

#include <setjmp.h>


/* Return 1 on success, 0 on failure */

MODULE = VRML::PNG	PACKAGE = VRML::PNG
PROTOTYPES: ENABLE

int
read_file(filename,sv,dep,hei,wi)
	char *filename
	SV *sv
	int dep
	int hei
	int wi
CODE:
   png_bytep *row_pointers;

	png_uint_32 width,height;
	int bit_depth;
 	int color_type;
	int is_png;
    png_structp png_ptr ;
    png_infop end_info ;
    png_infop info_ptr ;
    int number_of_passes;
    int rowbytes;
    int len;
    int i;
for(;;) {
    int fd = open(filename,O_RDONLY);
    FILE *fp;
    if (fd<0)
    {
        RETVAL=0; break;
    }
    read(fd, header, HDNO);
    is_png = png_check_sig(header, HDNO);
    if (!is_png)
    {
        RETVAL=0; break;
    }

    png_ptr = png_create_read_struct
       (PNG_LIBPNG_VER_STRING, NULL,
        NULL,NULL
	);
    if (!png_ptr){
        RETVAL=0; break;
    }

    info_ptr = png_create_info_struct(png_ptr);
    if (!info_ptr)
    {
        png_destroy_read_struct(&png_ptr,
           (png_infopp)NULL, (png_infopp)NULL);
        RETVAL=0; break;
    }

    end_info = png_create_info_struct(png_ptr);
    if (!end_info)
    {
        png_destroy_read_struct(&png_ptr, &info_ptr,
          (png_infopp)NULL);
        RETVAL=0; break;
    }

    if (setjmp(png_ptr->jmpbuf))
    {
        png_destroy_read_struct(&png_ptr, &info_ptr,
           &end_info);
        close(fd);
        RETVAL=0; break;
    }

    fp = fdopen(fd,"rb");
    png_init_io(png_ptr, fp);

    png_set_sig_bytes(png_ptr, HDNO);

    png_read_info(png_ptr, info_ptr);

    png_get_IHDR(png_ptr, info_ptr, &width, &height,
       &bit_depth, &color_type, NULL,
	NULL,NULL);


    if (color_type == PNG_COLOR_TYPE_PALETTE &&
        bit_depth <= 8) png_set_expand(png_ptr);

    if (color_type == PNG_COLOR_TYPE_GRAY &&
        bit_depth < 8) png_set_expand(png_ptr);

    if (png_get_valid(png_ptr, info_ptr,
        PNG_INFO_tRNS)) png_set_expand(png_ptr);


    if (bit_depth == 16)
        png_set_strip_16(png_ptr);

    if (bit_depth < 8)
        png_set_packing(png_ptr);

    number_of_passes = png_set_interlace_handling(png_ptr);
    png_read_update_info(png_ptr, info_ptr);

    rowbytes = png_get_rowbytes(png_ptr, info_ptr);
    height = png_get_image_height(png_ptr, info_ptr);
    dep = png_get_bit_depth(png_ptr,info_ptr);
  
  len = rowbytes * height;
    
  SvGROW(sv, len);
  SvCUR_set(sv, len);

   row_pointers = malloc(sizeof(*row_pointers)*height);
   for(i=0; i<height; i++) {
	row_pointers[i] = SvPV(sv,na) + rowbytes * i;
   }

   png_read_image(png_ptr, row_pointers);
   free(row_pointers);

   hei = height;
   wi = rowbytes/dep;


	RETVAL=1; break;
}
OUTPUT:
	RETVAL
	dep
	hei
	wi
