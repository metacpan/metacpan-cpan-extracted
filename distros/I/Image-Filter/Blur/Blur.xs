#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "blur.h"

MODULE = Image::Filter::Blur PACKAGE = Image::Filter::Blur 

PROTOTYPES: DISABLE

gdImagePtr 
blur (imageptr,type=0)
        gdImagePtr  imageptr
        int type