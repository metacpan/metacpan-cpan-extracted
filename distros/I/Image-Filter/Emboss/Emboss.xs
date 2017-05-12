#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "emboss.h"

MODULE = Image::Filter::Emboss PACKAGE = Image::Filter::Emboss 

PROTOTYPES: DISABLE

gdImagePtr 
emboss (imageptr)
        gdImagePtr  imageptr
