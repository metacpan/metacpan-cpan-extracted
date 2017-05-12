#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

#include "common/util.c"
#include "filecopy.c"


static int
xs_copy(char *src, char *dst, int maxbufsize, int preserve){
    OSErr err = filecopy(src, dst, maxbufsize, preserve);
    return seterr(err);
}

/* */

MODULE = MacOSX::File::Copy		PACKAGE = MacOSX::File::Copy

PROTOTYPES: ENABLE

int
xs_copy(src, dst, maxbufsize, preserve)
    char *src;
    char *dst;
    int maxbufsize;
    int preserve;
    CODE:
        RETVAL = xs_copy(src, dst, maxbufsize, preserve);
    OUTPUT:
	RETVAL
