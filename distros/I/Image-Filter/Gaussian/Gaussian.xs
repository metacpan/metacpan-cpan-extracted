#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "gaussian.h"

MODULE = Image::Filter::Gaussian PACKAGE = Image::Filter::Gaussian

PROTOTYPES: DISABLE

gdImagePtr 
gaussian (imageptr)
          gdImagePtr  imageptr
