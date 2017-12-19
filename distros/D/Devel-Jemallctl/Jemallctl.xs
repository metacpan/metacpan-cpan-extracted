#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <jemalloc/jemalloc.h>

#define NUM_KEYS 7
#define MALLCTL_OK 0
#define MY_CXT_KEY "Devel::Jemallctl::_stash" XS_VERSION

typedef struct {
    SV *sv;
    U32 hash;
} sv_with_hash;

typedef struct {
    int count;
    sv_with_hash keys[NUM_KEYS];
} my_cxt_t;

/* this is a special stats request that sets things up so following *
 * mallctl() calls get access to the right data (think threading)   */
void 
_setup_for_mallctl() {
    uint64_t epoch;
    size_t sz = sizeof(epoch);
    mallctl("epoch", &epoch, &sz, &epoch, sz);
}

void 
read_key_into_hv(pTHX_ const my_cxt_t *cxt, int i, HV* hash)
{
    size_t val;
    size_t sz = sizeof(val);
    int status;

    status = mallctl(SvPVX(cxt->keys[i].sv), &val, &sz, NULL, 0);
    
    if (status == MALLCTL_OK)
        hv_store_ent(hash, cxt->keys[i].sv, newSVuv(val), cxt->keys[i].hash);

}

void 
init_key(pTHX_ my_cxt_t *cxt, char *str, STRLEN len) {
    size_t val;
    size_t sz = sizeof(val);
    int status;

    assert(cxt->count < NUM_KEYS);

    status = mallctl(str, &val, &sz, NULL, 0);

    if (status == MALLCTL_OK) {
        cxt->keys[cxt->count].sv = newSVpvn(str, len);
        PERL_HASH(cxt->keys[cxt->count].hash,str,len);
        cxt->count++;
    }
}

#define INIT_KEY(str) init_key(aTHX_ &MY_CXT, (str ""), sizeof(str) - 1 )

START_MY_CXT
MODULE = Devel::Jemallctl PACKAGE = Devel::Jemallctl

BOOT:
{
    MY_CXT_INIT;
    MY_CXT.count= 0;

    _setup_for_mallctl();
    INIT_KEY("stats.active");
    INIT_KEY("stats.allocated");
    INIT_KEY("stats.mapped");
    INIT_KEY("stats.metadata");
    INIT_KEY("stats.resident");
    INIT_KEY("stats.retained");
}

void
print_stats()
  CODE:
    malloc_stats_print(NULL, NULL, NULL);

HV*
refresh_and_get_stats()
  PREINIT:
    dMY_CXT;

  CODE:
    int i;

    _setup_for_mallctl();
    RETVAL = newHV();
    hv_ksplit(RETVAL, MY_CXT.count);
    for(i = 0; i < MY_CXT.count; i++) 
        read_key_into_hv(aTHX_ &MY_CXT, i, RETVAL);

  OUTPUT:
    RETVAL
