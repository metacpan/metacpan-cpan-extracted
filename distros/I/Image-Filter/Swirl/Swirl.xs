#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "swirl.h"

MODULE = Image::Filter::Swirl PACKAGE = Image::Filter::Swirl

PROTOTYPES: DISABLE

gdImagePtr 
swirl (imageptr)
          gdImagePtr  imageptr
