#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "level.h"

MODULE = Image::Filter::Level PACKAGE = Image::Filter::Level

PROTOTYPES: DISABLE

gdImagePtr 
level (imageptr, inputlevel=0)
        gdImagePtr  imageptr
	int inputlevel
