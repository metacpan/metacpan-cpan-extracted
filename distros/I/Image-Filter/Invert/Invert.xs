#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "invert.h"

MODULE = Image::Filter::Invert PACKAGE = Image::Filter::Invert

PROTOTYPES: DISABLE

gdImagePtr invertize (imageptr)
        gdImagePtr  imageptr
