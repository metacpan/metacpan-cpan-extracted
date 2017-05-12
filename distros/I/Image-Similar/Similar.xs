#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "similar-image.h"

#define SIMAGE_CALL(x) {						\
	simage_status_t status;						\
	status = x;							\
	if (status != simage_ok) {					\
	    croak ("error %d from similar-image library", status);	\
	}								\
    }

typedef simage_t * Image__Similar__Image;

/* This defines "Image::Similar::Image", which is a part of an
   Image::Similar object, labelled like $is->{image}. */

MODULE=Image::Similar PACKAGE=Image::Similar::Image

PROTOTYPES: DISABLE

Image::Similar::Image
isnew (width, height);
	int width;
	int height;
CODE:
	Newxz (RETVAL, 1, simage_t);
	SIMAGE_CALL (simage_init (RETVAL, width, height));
OUTPUT:
	RETVAL

void
DESTROY (image)
	Image::Similar::Image image;
CODE:
	SIMAGE_CALL (simage_free (image));
	Safefree (image);

void
set_pixel (image, x, y, grey)
	Image::Similar::Image image
	int x
	int y
	unsigned char grey
CODE:
	//printf ("%d %d\n", x, y);
	SIMAGE_CALL (simage_set_pixel (image, x, y, grey));

AV *
get_rows (image)
	Image::Similar::Image image
PREINIT:
	int y;
CODE:
	RETVAL = newAV ();
	for (y = 0; y < image->height; y++) {
	    //printf ("%d\n", y);
	    av_push (RETVAL, newSVpv ((const char *) image->data + y * image->width, image->width));
	}
OUTPUT:
	RETVAL

void
fill_grid (image)
	Image::Similar::Image image
CODE:
	SIMAGE_CALL (simage_fill_grid (image));

Image::Similar::Image
fill_from_sig (sig)
	SV * sig;
PREINIT:
	char * signature;
	STRLEN signature_length;
CODE:
	Newxz (RETVAL, 1, simage_t);
	signature = SvPV (sig, signature_length);
	SIMAGE_CALL (simage_fill_from_signature (RETVAL, signature,
						 (int) signature_length));
OUTPUT:
	RETVAL

double
image_diff (image1, image2)
	Image::Similar::Image image1
	Image::Similar::Image image2
CODE:
	SIMAGE_CALL (simage_diff (image1, image2, & RETVAL));
OUTPUT:
	RETVAL

SV *
signature (image)
	Image::Similar::Image image
CODE:
	SIMAGE_CALL (simage_signature (image));
	RETVAL = newSVpv (image->signature, (STRLEN) image->signature_length);
OUTPUT:
	RETVAL

SV *
valid_image (image)
	Image::Similar::Image image
CODE:
	if (image->valid_image) {
		RETVAL = & PL_sv_yes;
	}
	else {
		RETVAL = & PL_sv_no;
	}
OUTPUT:
	RETVAL

