#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "ripple.h"

MODULE = Image::Filter::Ripple PACKAGE = Image::Filter::Ripple

PROTOTYPES: DISABLE

gdImagePtr 
ripple (imageptr, numwaves = 10)
          gdImagePtr  imageptr
          int         numwaves
