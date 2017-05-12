#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <valgrind/memcheck.h>

MODULE = Devel::Valgrind::Client     PACKAGE = Devel::Valgrind::Client

PROTOTYPES: ENABLE

SV*
is_in_memcheck()
  CODE:
    RETVAL = 0 != VALGRIND_GET_VBITS(0, 0, 0) ? &PL_sv_yes : &PL_sv_no;
  OUTPUT:
    RETVAL

void
do_leak_check()
  CODE:
    VALGRIND_DO_LEAK_CHECK

void
do_quick_leak_check()
  CODE:
    VALGRIND_DO_QUICK_LEAK_CHECK

SV*
count_leaks()
  INIT:
    unsigned long leaked, dubious, reachable, suppressed;
    HV* h = (HV*)sv_2mortal((SV*)newHV());

  CODE:
    VALGRIND_COUNT_LEAKS(leaked, dubious, reachable, suppressed);

    hv_stores(h, "leaked",     newSVnv(leaked));
    hv_stores(h, "dubious",    newSVnv(dubious));
    hv_stores(h, "reachable",  newSVnv(reachable));
    hv_stores(h, "suppressed", newSVnv(suppressed));

    RETVAL = newRV((SV*)h);
  OUTPUT:
    RETVAL

