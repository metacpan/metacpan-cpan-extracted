#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "sharpen.h"

MODULE = Image::Filter::Sharpen PACKAGE = Image::Filter::Sharpen 

PROTOTYPES: DISABLE

gdImagePtr 
sharpen (imageptr)
        gdImagePtr  imageptr
