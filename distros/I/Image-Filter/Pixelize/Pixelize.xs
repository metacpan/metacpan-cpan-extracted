#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "pixelize.h"

MODULE = Image::Filter::Pixelize PACKAGE = Image::Filter::Pixelize 

PROTOTYPES: DISABLE

gdImagePtr 
pixelize (imageptr)
        gdImagePtr  imageptr
