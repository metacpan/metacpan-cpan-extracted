#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define PNG_SKIP_SETJMP_CHECK
#include <png.h>

#include "qrencode.h"
#include "qrpng.h"

#include "image-png-qrcode-perl.c"

MODULE=Image::PNG::QRCode PACKAGE=Image::PNG::QRCode

PROTOTYPES: DISABLE

BOOT:
	/* Image__PNG__QRCode_error_handler = perl_error_handler; */

void
qrpng_internal (options)
	HV * options;
