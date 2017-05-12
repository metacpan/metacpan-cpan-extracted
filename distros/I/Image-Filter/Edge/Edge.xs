#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "edge.h"

MODULE = Image::Filter::Edge PACKAGE = Image::Filter::Edge 

PROTOTYPES: DISABLE

gdImagePtr 
edge (imageptr)
        gdImagePtr  imageptr
