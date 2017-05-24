#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <jemalloc/jemalloc.h>

int read_sizet_into_hv(pTHX_ const char *mallkey, HV* hash)
{
    size_t read, sz;
    int success;

    sz = sizeof(read);
    success = mallctl(mallkey, &read, &sz, NULL, 0);

    if (success == 0) {
        hv_store(hash, mallkey, strlen(mallkey), newSVuv(read), 0);
    }

    return success;
}

MODULE = Devel::Jemallctl PACKAGE = Devel::Jemallctl

void
print_stats()
  CODE:
    malloc_stats_print(NULL, NULL, NULL);

HV*
refresh_and_get_stats()
  CODE:
    uint64_t epoch;
    size_t sz = sizeof(epoch);
    mallctl("epoch", &epoch, &sz, &epoch, sz);

    RETVAL = newHV();
    read_sizet_into_hv(aTHX_ "stats.active", RETVAL);
    read_sizet_into_hv(aTHX_ "stats.allocated", RETVAL);
    read_sizet_into_hv(aTHX_ "stats.cactive", RETVAL);
    read_sizet_into_hv(aTHX_ "stats.mapped", RETVAL);
    read_sizet_into_hv(aTHX_ "stats.metadata", RETVAL);
    read_sizet_into_hv(aTHX_ "stats.resident", RETVAL);
    read_sizet_into_hv(aTHX_ "stats.retained", RETVAL);

  OUTPUT:
    RETVAL
