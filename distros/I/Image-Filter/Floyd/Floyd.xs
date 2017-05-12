#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "floyd.h"

MODULE = Image::Filter::Floyd PACKAGE = Image::Filter::Floyd 

PROTOTYPES: DISABLE

gdImagePtr 
floyd (imageptr, limit=128)
        gdImagePtr  imageptr
        int  limit