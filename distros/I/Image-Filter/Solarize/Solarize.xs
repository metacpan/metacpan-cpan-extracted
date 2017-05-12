#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "solarize.h"

MODULE = Image::Filter::Solarize PACKAGE = Image::Filter::Solarize

PROTOTYPES: DISABLE

gdImagePtr 
solarize (imageptr, seed = 128)
          gdImagePtr  imageptr
          int         seed