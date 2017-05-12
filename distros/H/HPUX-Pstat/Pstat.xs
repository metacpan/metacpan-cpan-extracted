/* $Id: Pstat.xs,v 1.1 2003/03/31 17:42:16 deschwen Exp $ */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "pack.h"


MODULE = HPUX::Pstat		PACKAGE = HPUX::Pstat

pst_static*
getstatic()
CODE:
    RETVAL = (pst_static*)safemalloc(sizeof(pst_static));
    if (RETVAL == NULL) {
        warn("getstatic: unable to malloc");
        XSRETURN_UNDEF;
    }
    if (pstat_getstatic(RETVAL, sizeof(pst_static), 1, 0) == -1) {
        warn("getstatic: failed");
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL
CLEANUP:
    safefree(RETVAL);


pst_dynamic*
getdynamic()
CODE:
    RETVAL = (pst_dynamic*)safemalloc(sizeof(pst_dynamic));
    if (RETVAL == NULL) {
        warn("getdynamic: unable to malloc");
        XSRETURN_UNDEF;
    }
    if (pstat_getdynamic(RETVAL, sizeof(pst_dynamic), 1, 0) == -1) {
        warn("getdynamic: failed");
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL
CLEANUP:
    safefree(RETVAL);


pst_vminfo*
getvminfo()
CODE:
    RETVAL = (pst_vminfo*)safemalloc(sizeof(pst_vminfo));
    if (RETVAL == NULL) {
        warn("getvminfo: unable to malloc");
        XSRETURN_UNDEF;
    }
    if (pstat_getvminfo(RETVAL, sizeof(pst_vminfo), 1, 0) == -1) {
        warn("getvminfo: failed");
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL
CLEANUP:
    safefree(RETVAL);


my_swapinfo*
getswap(size = 1, first = 0)
int size;
int first;
PREINIT:
    static my_swapinfo foo;
CODE:
    RETVAL = &foo;
    foo.size = 0;
    foo.data = (pst_swapinfo*)safemalloc(size * sizeof(pst_swapinfo));
    if (foo.data == NULL) {
        warn("getswap: unable to malloc");
        XSRETURN_UNDEF;
    }
    if ((foo.size = pstat_getswap(foo.data, sizeof(pst_swapinfo), size, first)) == -1) {
        warn("getswap: failed");
        safefree(foo.data);
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL
CLEANUP:
    safefree(foo.data);


my_status*
getproc(size = 1, first = 0)
int size;
int first;
PREINIT:
    static my_status foo;
CODE:
    RETVAL = &foo;
    foo.size = 0;
    foo.data = (pst_status*)safemalloc(size * sizeof(pst_status));
    if (foo.data == NULL) {
        warn("getproc: unable to malloc");
        XSRETURN_UNDEF;
    }
    if ((foo.size = pstat_getproc(foo.data, sizeof(pst_status), size, first)) == -1) {
        warn("getproc: failed");
        safefree(foo.data);
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL
CLEANUP:
    safefree(foo.data);


my_processor*
getprocessor(size = 1, first = 0)
int size;
int first;
PREINIT:
    static my_processor foo;
CODE:
    RETVAL = &foo;
    foo.size = 0;
    foo.data = (pst_processor*)safemalloc(size * sizeof(pst_processor));
    if (foo.data == NULL) {
        warn("getprocessor: unable to malloc");
        XSRETURN_UNDEF;
    }
    if ((foo.size = pstat_getprocessor(foo.data, sizeof(pst_processor), size, first)) == -1) {
        warn("getprocessor: failed");
        safefree(foo.data);
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL
CLEANUP:
    safefree(foo.data);



