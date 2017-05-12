#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "eraseline.h"

MODULE = Image::Filter::Eraseline PACKAGE = Image::Filter::Eraseline

PROTOTYPES: DISABLE

gdImagePtr 
eraseline (imageptr, thickness = 1, orientation = 1, newr = 0, newg = 0, newb = 0)
        gdImagePtr  imageptr
	int thickness
	int orientation 
	int newr
	int newg
	int newb
