#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <unistd.h>
#include <sys/attr.h>

#define DECLARE(name) hv_store(RETVAL, #name, sizeof #name-1, newSVuv(name), 0)

typedef int sysret;

MODULE = MacOSX::File::Exchange		PACKAGE = MacOSX::File::Exchange

PROTOTYPES: DISABLE

HV *
_make_constants()
CODE:
    RETVAL = newHV();
    sv_2mortal((SV *)RETVAL);
    DECLARE(FSOPT_NOFOLLOW);
OUTPUT:
    RETVAL

sysret
exchangedata(file1, file2, flags = 0)
    char const *file1;
    char const *file2;
    uint32_t flags;

