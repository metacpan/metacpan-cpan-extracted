#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "oilify.h"

MODULE = Image::Filter::Oilify PACKAGE = Image::Filter::Oilify

PROTOTYPES: DISABLE

gdImagePtr 
oilify (imageptr, seed = 8)
          gdImagePtr  imageptr
          int         seed