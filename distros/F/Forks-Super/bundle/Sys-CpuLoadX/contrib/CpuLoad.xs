#ifdef __cplusplus
extern "C" {
#endif

#include <stdlib.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
}
#endif

MODULE = Sys::CpuLoadX		PACKAGE = Sys::CpuLoadX

void
xs_getbsdload()
    PREINIT:
        double loadavg[3];
    PPCODE:
#if defined(__FreeBSD__) || defined(__OpenBSD__)
        getloadavg(loadavg, 3);
#endif
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSVnv(loadavg[0])));
        PUSHs(sv_2mortal(newSVnv(loadavg[1])));
        PUSHs(sv_2mortal(newSVnv(loadavg[2])));

