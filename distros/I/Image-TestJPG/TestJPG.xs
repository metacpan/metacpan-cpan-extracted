#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <setjmp.h>
#include <jpeglib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

MODULE = Image::TestJPG		PACKAGE = Image::TestJPG
PROTOTYPES: ENABLE

int
testJPG(inBuffer, buflen)
		char* inBuffer
		int		buflen
	CODE:

	struct my_error_mgr {
  	struct jpeg_error_mgr pub;
  	jmp_buf setjmp_buffer;
	};

	typedef struct my_error_mgr * my_error_ptr;

	// definitions
	extern void my_output_message(j_common_ptr cinfo);
  extern void jpeg_my_src(j_decompress_ptr cinfo, char *mybuffer, 
		size_t length);

	struct jpeg_decompress_struct cinfo;
	struct my_error_mgr jerr;
	
		// this buffer is for libjpeg
	JSAMPARRAY buffer;
		// other crap used by libjpeg
	int row_stride;
		// allocate and initiliaze a JPEG decompression object
	cinfo.err = jpeg_std_error(&jerr.pub);
		// set our callback for error messages
	jerr.pub.output_message = my_output_message;

		// Establish the setjmp return context for my_output_message to use.
	if(setjmp(jerr.setjmp_buffer)) {
    	// If we get here, the JPEG code has signaled an error.
    	// We need to clean up the JPEG object, close the input file, and return.
    jpeg_destroy_decompress(&cinfo);
		RETVAL = 0;
		XSRETURN_UNDEF;
  }

		// uhh create decompresion context
	jpeg_create_decompress(&cinfo);
		// fire up our source manager
	jpeg_my_src(&cinfo, inBuffer, buflen);
		// Call jpeg_read_header() to obtain image info
	jpeg_read_header(&cinfo, TRUE);
		// do jpeg_start_decompress
	jpeg_start_decompress(&cinfo);

		// allocate memory for the buffer
	row_stride = cinfo.output_width * cinfo.output_components;
	buffer = (*cinfo.mem->alloc_sarray)
		((j_common_ptr) &cinfo, JPOOL_IMAGE, row_stride, cinfo.output_height);

		// read in the data and copy it into imgbuf
	while (cinfo.output_scanline < cinfo.output_height) {
		(void) jpeg_read_scanlines(&cinfo, buffer, 1);
	}

		// call jpeg_finish_decompress
	jpeg_finish_decompress(&cinfo);

		// release the JPEG decompression object
	jpeg_destroy_decompress(&cinfo);

	RETVAL = 1;

	OUTPUT:
		RETVAL
