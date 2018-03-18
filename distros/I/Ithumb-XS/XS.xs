#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <Imlib2.h>

MODULE = Ithumb::XS		PACKAGE = Ithumb::XS

int
create_thumbnail(src_path, w=0, h=0, dst_path)
	const char *src_path
	const char *dst_path
	int w
	int h

	PROTOTYPE: $$$$

	CODE:
	{
	 float aspect;
	 int width=0, height=0, crop_x = 0, crop_y = 0, new_width = 0, new_height = 0;
	 Imlib_Load_Error err;
	 Imlib_Image src_img, scaled_img, croped_img;

	 src_img = imlib_load_image_with_error_return(src_path, &err);
	
	 if (err == IMLIB_LOAD_ERROR_FILE_DOES_NOT_EXIST) {
		 Perl_croak(aTHX_ "Ithumb::XS load error: File '%s' does not exist", src_path);
	 }

	 if (err == IMLIB_LOAD_ERROR_FILE_IS_DIRECTORY) {
		 Perl_croak(aTHX_ "Ithumb::XS load error: File '%s' is directory", src_path);
	 }

	 if (err == IMLIB_LOAD_ERROR_PERMISSION_DENIED_TO_READ) {
		 Perl_croak(aTHX_ "Ithumb::XS load error: Permission denied");
	 }

	 if (err == IMLIB_LOAD_ERROR_NO_LOADER_FOR_FILE_FORMAT) {
		 Perl_croak(aTHX_ "Ithumb::XS load error: No loader for file format");
	 }
	
	 imlib_context_set_image(src_img);

	 width  = imlib_image_get_width();
	 height = imlib_image_get_height();
	 aspect = (float)width / (float)height;

	 if ( aspect > 1 ) {
		 if ( w >= h ) {
			 new_height = h;
			 new_width = w * aspect;
			 crop_x = (new_width - w) / 2;
		 } else {
			 new_width = w;
			 new_height = h * aspect;
			 crop_y = (new_height - h) / 2;
		 }
	 }

	 scaled_img = imlib_create_cropped_scaled_image(0, 0, width, height, new_width,	new_height);

	 if (!scaled_img) {
		 Perl_croak(aTHX_ "Ithumb::XS error: image can not be scaled");
	 }

	 imlib_context_set_image(scaled_img);

	 croped_img = imlib_create_cropped_image(crop_x, crop_y, w, h);

	 if (!croped_img) {
		 Perl_croak(aTHX_ "Ithumb::XS error: image can not be croped");
	 }

	 imlib_context_set_image(croped_img);
	
	 imlib_save_image(dst_path);

	 RETVAL = 1;
	}
    OUTPUT:
        RETVAL
