#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "twirl.h"

MODULE = Image::Filter::Twirl PACKAGE = Image::Filter::Twirl

PROTOTYPES: DISABLE

gdImagePtr 
twirl (imageptr)
          gdImagePtr  imageptr
