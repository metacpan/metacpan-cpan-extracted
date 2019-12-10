#include <stdio.h>
#include <string.h>
#include <Imlib2.h>

#include "ithumb.h"


IErr get_error(int imlib_error_code) {
    IErr err;

    switch(imlib_error_code) {
    case IMLIB_LOAD_ERROR_NONE:
        break;
    case IMLIB_LOAD_ERROR_FILE_DOES_NOT_EXIST:
        err.msg = "[Ithumb::XS] imlib error: File does not exist";
        break;
    case IMLIB_LOAD_ERROR_FILE_IS_DIRECTORY:
        err.msg = "[Ithumb::XS] imlib error: File is directory";
        break;
    case IMLIB_LOAD_ERROR_PERMISSION_DENIED_TO_READ:
        err.msg = "[Ithumb::XS] imlib error: Permission denied";
        break;
    case IMLIB_LOAD_ERROR_NO_LOADER_FOR_FILE_FORMAT:
        err.msg = "[Ithumb::XS] imlib error: No loader for file format";
        break;
    case IMLIB_LOAD_ERROR_PATH_TOO_LONG:
        err.msg = "[Ithumb::XS] imlib error: Path too long";
        break;
    case IMLIB_LOAD_ERROR_PATH_COMPONENT_NON_EXISTANT:
        err.msg = "[Ithumb::XS] imlib error: Path component non existant";
        break;
    case IMLIB_LOAD_ERROR_PATH_COMPONENT_NOT_DIRECTORY:
        err.msg = "[Ithumb::XS] imlib error: Path component not directory";
        break;
    case IMLIB_LOAD_ERROR_PATH_POINTS_OUTSIDE_ADDRESS_SPACE:
        err.msg = "[Ithumb::XS] imlib error: Path points outside address space";
        break;
    case IMLIB_LOAD_ERROR_TOO_MANY_SYMBOLIC_LINKS:
        err.msg = "[Ithumb::XS] imlib error: Too many symbolic links";
        break;
    case IMLIB_LOAD_ERROR_OUT_OF_MEMORY:
        err.msg = "[Ithumb::XS] imlib error: Out of memory";
        break;
    case IMLIB_LOAD_ERROR_OUT_OF_FILE_DESCRIPTORS:
        err.msg = "[Ithumb::XS] imlib error: Out of file descriptors";
        break;
    case IMLIB_LOAD_ERROR_PERMISSION_DENIED_TO_WRITE:
        err.msg = "[Ithumb::XS] imlib error: Permission denied to write";
        break;
    case IMLIB_LOAD_ERROR_OUT_OF_DISK_SPACE:
        err.msg = "[Ithumb::XS] imlib error: Out of disk space";
        break;
    case IMLIB_LOAD_ERROR_UNKNOWN:
        err.msg = "[Ithumb::XS] imlib error: Unknown";
        break;
    case ITHUMB_REQUESTED_WIDTH_ERROR:
        err.msg = "[Ithumb::XS] error: invalid value of width (width must be a positive integer)";
        break;
    case ITHUMB_REQUESTED_HEIGHT_ERROR:
        err.msg = "[Ithumb::XS] error: invalid value of height (height must be a positive integer)";
        break;
    case ITHUMB_REQUESTED_SRC_ERROR:
        err.msg = "[Ithumb::XS] error: invalid value of source file path";
        break;
    case ITHUMB_REQUESTED_DST_ERROR:
        err.msg = "[Ithumb::XS] error: invalid value of destination file path";
        break;
    case ITHUMB_SCALE_FAILED_ERROR:
        err.msg = "[Ithumb::XS] error: image can't be a scaled";
        break;
    case ITHUMB_CROP_FAILED_ERROR:
        err.msg = "[Ithumb::XS] error: image can't be croped";
        break;
    default:
        break;
    }

    err.code = imlib_error_code;

    return err;
}

int resize_and_crop(Img *image) {
    float aspect_ration_orig, aspect_ratio_new;

    int width = 0, height = 0, crop_x = 0, crop_y = 0, new_width = 0, new_height = 0;

    Imlib_Load_Error err = IMLIB_LOAD_ERROR_NONE;
    Imlib_Image src_img, scaled_img, croped_img;

    if (image->w <= 0)
        return ITHUMB_REQUESTED_WIDTH_ERROR;

    if (image->h <= 0)
        return ITHUMB_REQUESTED_HEIGHT_ERROR;

    if (!strlen(image->src))
        return ITHUMB_REQUESTED_SRC_ERROR;

    if (!strlen(image->dst))
        return ITHUMB_REQUESTED_DST_ERROR;

    src_img = imlib_load_image_with_error_return(image->src, &err);

    if (err)
        return err;

    imlib_context_set_image(src_img);

    width  = imlib_image_get_width();
    height = imlib_image_get_height();
    aspect_ration_orig = (float)width / (float)height;
    aspect_ratio_new = (float)image->w / (float)image->h;

    if ( aspect_ratio_new > 1 ) {
        scaled_img = imlib_create_cropped_scaled_image(
            0, 0, width, height, (int)(image->h * aspect_ration_orig), image->h);
    } else {
        scaled_img = imlib_create_cropped_scaled_image(
            0, 0, width, height, (int)(image->h * aspect_ration_orig), image->h);
    }

    scaled_img = imlib_create_cropped_scaled_image(
        0, 0, width, height, 640, 360);

    if (!scaled_img)
        return ITHUMB_SCALE_FAILED_ERROR;

    imlib_context_set_image(scaled_img);

    croped_img = imlib_create_cropped_image(0, 0, image->w, 200);

    if (!croped_img)
        return ITHUMB_SCALE_FAILED_ERROR;

    imlib_context_set_image(croped_img);

    // TODO: try/catch for saving
    imlib_save_image(image->dst);

    return 0;
}
