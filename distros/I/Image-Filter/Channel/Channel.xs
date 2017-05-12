#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "channel.h"

MODULE = Image::Filter::Channel PACKAGE = Image::Filter::Channel 

PROTOTYPES: DISABLE

gdImagePtr 
channel (imageptr, chan = 3)
        gdImagePtr imageptr
        int chan
