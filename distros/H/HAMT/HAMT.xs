#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "hamt/hamt_sv.h"
#include "hamt/hamt_compat.h"
#include "hamt/hamt_val.h"
#include "hamt/hamt_alloc.h"
#include "hamt/hamt_hash.h"
#include "hamt/hamt_entry.h"
#include "hamt/hamt_node.h"
#include "hamt/hamt_map.h"
#include "hamt/hamt_mut.h"
#include "hamt/hamt_iter.h"
#include "hamt/hamt_algebra.h"
#include "hamt/hamt_vec.h"
#include "hamt/hamt_check.h"
#include "hamt/hamt_xs.h"
#include "hamt/hamt_ops.h"

#include "hamt_abi.h"
#include "hamt/hamt_abi_impl.h"
#include "hamt/hamt_abi_selftest.h"

/* A seed nobody outside the process can compute. perl's own hash of a fixed
 * string carries perl's per-process seed where it has one; the address of a
 * local and the clock cover a perl built without. */
static uint64_t hamt_boot_seed(pTHX) {
    static const char salt[] = "HAMT::seed";
    U32 ph;
    uint64_t s;
    PERL_HASH(ph, salt, sizeof(salt) - 1);
    s  = (uint64_t)ph * HAMT_M1;
    s ^= (uint64_t)PTR2UV(&ph) * HAMT_M2;
    s ^= (uint64_t)PerlProc_getpid() << 32;
    s ^= (uint64_t)time(NULL) * HAMT_M3;
    s ^= s >> 29;
    return s;
}

#ifndef HAMT_NO_POOL
static void hamt_pool_atexit(pTHX_ void *arg) {
    PERL_UNUSED_ARG(arg);
    if (hamt_pool_owner == HAMT_CX) hamt_pool_close(&hamt_pool_one);
}
#endif

/* The first interpreter to load the library has the pool. */
static void hamt_pool_boot(pTHX) {
#ifndef HAMT_NO_POOL
    if (hamt_pool_one.open) return;
    hamt_pool_open(&hamt_pool_one);
    hamt_pool_owner = HAMT_CX;
    Perl_call_atexit(aTHX_ hamt_pool_atexit, NULL);
#else
    PERL_UNUSED_CONTEXT;
#endif
}

MODULE = HAMT    PACKAGE = HAMT

PROTOTYPES: DISABLE

BOOT:
    hamt_seed = hamt_boot_seed(aTHX);
    hamt_pool_boot(aTHX);

# The warning filter a walk puts in $SIG{__WARN__}: see hamt_xs_walk_enter.
void
_warn_filter(...)
    PREINIT:
        SV *msg, *prev;
        STRLEN len;
        const char *p;
    PPCODE:
        msg = items ? ST(0) : &PL_sv_undef;
        if (!SvROK(msg)) {
            p = SvPV(msg, len);
            if (len >= 17 && memEQ(p, "Exiting eval via ", 17)) XSRETURN_EMPTY;
        }
        prev = get_sv("HAMT::_warn_prev", 0);
        if (prev && SvOK(prev)) {
            PUSHMARK(SP);
            XPUSHs(msg);
            PUTBACK;
            call_sv(prev, G_DISCARD);
        }
        else {
            Perl_warn(aTHX_ "%" SVf, SVfARG(msg));
        }
        XSRETURN_EMPTY;

INCLUDE: xs/map.xs
INCLUDE: xs/map_transient.xs
INCLUDE: xs/set.xs
INCLUDE: xs/set_transient.xs
INCLUDE: xs/vector.xs
INCLUDE: xs/vector_transient.xs
INCLUDE: xs/test.xs
INCLUDE: xs/abi.xs
INCLUDE: xs/ops.xs
