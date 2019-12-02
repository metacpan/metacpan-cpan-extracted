#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <string.h>
#include <Imlib2.h>


typedef struct img_t {
    int width;
    int height;
    char *src_path;
    char *dst_path;
} Image;

typedef struct err_t {
    unsigned short int code;
    char *msg;
} IError;

IError error_t;

int get_imlib_error(int imlib_error_code) {
    switch(imlib_error_code) {
    case IMLIB_LOAD_ERROR_NONE:
        break;
    case IMLIB_LOAD_ERROR_FILE_DOES_NOT_EXIST:
        error_t.msg = "[Ithumb::XS] imlib error: File does not exist";
        break;
    case IMLIB_LOAD_ERROR_FILE_IS_DIRECTORY:
        error_t.msg = "[Ithumb::XS] imlib error: File is directory";
        break;
    case IMLIB_LOAD_ERROR_PERMISSION_DENIED_TO_READ:
        error_t.msg = "[Ithumb::XS] imlib error: Permission denied";
        break;
    case IMLIB_LOAD_ERROR_NO_LOADER_FOR_FILE_FORMAT:
        error_t.msg = "[Ithumb::XS] imlib error: No loader for file format";
        break;
    case IMLIB_LOAD_ERROR_PATH_TOO_LONG:
        error_t.msg = "[Ithumb::XS] imlib error: Path too long";
        break;
    case IMLIB_LOAD_ERROR_PATH_COMPONENT_NON_EXISTANT:
        error_t.msg = "[Ithumb::XS] imlib error: Path component non existant";
        break;
    case IMLIB_LOAD_ERROR_PATH_COMPONENT_NOT_DIRECTORY:
        error_t.msg = "[Ithumb::XS] imlib error: Path component not directory";
        break;
    case IMLIB_LOAD_ERROR_PATH_POINTS_OUTSIDE_ADDRESS_SPACE:
        error_t.msg = "[Ithumb::XS] imlib error: Path points outside address space";
        break;
    case IMLIB_LOAD_ERROR_TOO_MANY_SYMBOLIC_LINKS:
        error_t.msg = "[Ithumb::XS] imlib error: Too many symbolic links";
        break;
    case IMLIB_LOAD_ERROR_OUT_OF_MEMORY:
        error_t.msg = "[Ithumb::XS] imlib error: Out of memory";
        break;
    case IMLIB_LOAD_ERROR_OUT_OF_FILE_DESCRIPTORS:
        error_t.msg = "[Ithumb::XS] imlib error: Out of file descriptors";
        break;
    case IMLIB_LOAD_ERROR_PERMISSION_DENIED_TO_WRITE:
        error_t.msg = "[Ithumb::XS] imlib error: Permission denied to write";
        break;
    case IMLIB_LOAD_ERROR_OUT_OF_DISK_SPACE:
        error_t.msg = "[Ithumb::XS] imlib error: Out of disk space";
        break;
    case IMLIB_LOAD_ERROR_UNKNOWN:
        error_t.msg = "[Ithumb::XS] imlib error: Unknown";
        break;
    default:
        break;
    }

    error_t.code = imlib_error_code;

    return imlib_error_code;
}


static int _create_thumbnail(Image *image_t) {
    int result = 0;
    float aspect_ration_orig, aspect_ratio_new;

    int width = 0, height = 0, crop_x = 0, crop_y = 0, new_width = 0, new_height = 0;

    Imlib_Load_Error err = IMLIB_LOAD_ERROR_NONE;
    Imlib_Image src_img, scaled_img, croped_img;

    if (image_t->width <= 0) {
        error_t.msg = "[Ithumb::XS] error: invalid value of width (width must be a positive integer)";
        error_t.code = 101;
        return error_t.code;
    }

    if (image_t->height <= 0) {
        error_t.msg = "[Ithumb::XS] error: invalid value of height (height must be a positive integer)";
        error_t.code = 102;
        return error_t.code;
    }

    if (!strlen(image_t->src_path)) {
        error_t.msg = "[Ithumb::XS] error: invalid value of source file path";
        error_t.code = 103;
        return error_t.code;
    }

    if (!strlen(image_t->dst_path)) {
        error_t.msg = "[Ithumb::XS] error: invalid value of destination file path";
        error_t.code = 104;
        return error_t.code;
    }

    src_img = imlib_load_image_with_error_return(image_t->src_path, &err);

    if (err)
        return get_imlib_error(err);

    imlib_context_set_image(src_img);

    width  = imlib_image_get_width();
    height = imlib_image_get_height();
    aspect_ration_orig = (float)width / (float)height;
    aspect_ratio_new = (float)image_t->width / (float)image_t->height;

    if ( aspect_ratio_new > 1 ) {
        scaled_img = imlib_create_cropped_scaled_image(
            0, 0, width, height, (int)(image_t->height * aspect_ration_orig), image_t->height);
    } else {
        scaled_img = imlib_create_cropped_scaled_image(
            0, 0, width, height, (int)(image_t->height * aspect_ration_orig), image_t->height);
    }

    scaled_img = imlib_create_cropped_scaled_image(
        0, 0, width, height, 640, 360);

    if (!scaled_img) {
        error_t.msg = "[Ithumb::XS] error: image can't be a scaled";
        error_t.code = 105;
        return error_t.code;
    }

    imlib_context_set_image(scaled_img);

    croped_img = imlib_create_cropped_image(
        0,
        0, image_t->width, 200);

    if (!croped_img) {
        error_t.msg = "[Ithumb::XS] error: image can't be croped";
        error_t.code = 106;
        return error_t.code;
    }

    imlib_context_set_image(croped_img);

    // TODO: try/catch for saving
    imlib_save_image(image_t->dst_path);

    return result;
}

MODULE = Ithumb::XS		PACKAGE = Ithumb::XS
PROTOTYPES: ENABLE

SV *
new(const char *class)
    CODE:
        /* Create a hash */
        HV* hash = newHV();
        /* Create a reference to the hash */
        SV *const self = newRV_noinc( (SV *)hash );
        /* bless into the proper package */
        RETVAL = sv_bless( self, gv_stashpv( class, 0 ) );
    OUTPUT: RETVAL

int
convert(SV *self, SV *thumb_params)
	CODE:
        SV **svp;
        unsigned long keylen;
        HV *h_thumb_params = (HV*) SvRV(thumb_params);

        if (!hv_exists(h_thumb_params, "width", 5))
            Perl_croak(aTHX_ "'width' parameter is required");

        if (!hv_exists(h_thumb_params, "height", 6))
            Perl_croak(aTHX_ "'height' parameter is required");

        if (!hv_exists(h_thumb_params, "src_image", 9))
            Perl_croak(aTHX_ "'src_image' (source file path) parameter is required");

        if (!hv_exists(h_thumb_params, "dst_image", 9))
            Perl_croak(aTHX_ "'dst_image' (destionation file path) parameter is required");

        long width, height;
        char *src_path, *dst_path;

        svp = hv_fetch(h_thumb_params, "width", 5, 0);
        width = SvIV(*svp);
        svp = hv_fetch(h_thumb_params, "height", 6, 0);
        height = SvIV(*svp);
        svp = hv_fetch(h_thumb_params, "src_image", 9, 0);
        src_path = SvPV(*svp, keylen);
        svp = hv_fetch(h_thumb_params, "dst_image", 9, 0);
        dst_path = SvPV(*svp, keylen);

        Image image_t = { (unsigned short)width, (unsigned short)height, src_path, dst_path };

        if (_create_thumbnail(&image_t))
            Perl_croak(aTHX_ "%s", error_t.msg);

        RETVAL = 1;
    OUTPUT:
        RETVAL

int
convert_image(SV *thumb_params)
	CODE:
        SV **svp;
        unsigned long keylen;
        HV *h_thumb_params = (HV*) SvRV(thumb_params);

        if (!hv_exists(h_thumb_params, "width", 5))
            Perl_croak(aTHX_ "'width' parameter is required");

        if (!hv_exists(h_thumb_params, "height", 6))
            Perl_croak(aTHX_ "'height' parameter is required");

        if (!hv_exists(h_thumb_params, "src_image", 9))
            Perl_croak(aTHX_ "'src_image' (source file path) parameter is required");

        if (!hv_exists(h_thumb_params, "dst_image", 9))
            Perl_croak(aTHX_ "'dst_image' (destionation file path) parameter is required");

        long width, height;
        char *src_path, *dst_path;

        svp = hv_fetch(h_thumb_params, "width", 5, 0);
        width = SvIV(*svp);
        svp = hv_fetch(h_thumb_params, "height", 6, 0);
        height = SvIV(*svp);
        svp = hv_fetch(h_thumb_params, "src_image", 9, 0);
        src_path = SvPV(*svp, keylen);
        svp = hv_fetch(h_thumb_params, "dst_image", 9, 0);
        dst_path = SvPV(*svp, keylen);

        Image image_t = { width, height, src_path, dst_path };

        if (_create_thumbnail(&image_t))
            Perl_croak(aTHX_ "%s", error_t.msg);

        RETVAL = 1;
    OUTPUT:
        RETVAL
