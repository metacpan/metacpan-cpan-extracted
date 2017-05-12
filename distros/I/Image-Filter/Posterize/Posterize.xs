#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "posterize.h"

MODULE = Image::Filter::Posterize PACKAGE = Image::Filter::Posterize 

PROTOTYPES: DISABLE

gdImagePtr 
posterize (imageptr)
        gdImagePtr  imageptr
