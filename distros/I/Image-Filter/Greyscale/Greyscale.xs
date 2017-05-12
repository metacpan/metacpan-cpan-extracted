#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "greyscale.h"

MODULE = Image::Filter::Greyscale PACKAGE = Image::Filter::Greyscale

PROTOTYPES: DISABLE

gdImagePtr greyscale (imageptr)
        gdImagePtr  imageptr
