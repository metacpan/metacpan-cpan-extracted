/* hm_sa.h - Hyperman as a CONSUMER of Shared::Arena's C ABI.
 *
 * One arena per server process, created from Perl before the workers fork so
 * every worker inherits the same mapping, and driven from C through the
 * versioned table Shared::Arena::_abi_ptr hands out. The object is created
 * from Perl rather than through the table's `create` so that Hyperman->arena
 * is a real Shared::Arena with every tenant available to Perl, and the C side
 * reaches the same region through `_region_ptr`. One owner, one lifetime: the
 * object is held for the life of the process and never released while the
 * server runs.
 *
 * Perl-facing on purpose - it calls into the interpreter to resolve the table
 * and to make the object - which is why it lives beside hm_abi_impl.h and not
 * among the perl-free headers.
 *
 * EVERYTHING FAILS OPEN. A NULL table (Shared::Arena absent, too old, or
 * HYPERMAN_NO_SA_ABI set) or a NULL region (create refused) leaves every door
 * that would use them answering exactly what it answers today with no arena.
 * A missing provider is a missing optimisation, never a broken server.
 */

#ifndef HM_SA_H
#define HM_SA_H

#include "sa_abi.h"

static const sa_abi *HM_SA = NULL;          /* the table, or NULL: fail open */
static sa_region    *hm_sa_region = NULL;   /* the arena, or NULL: fail open */
static SV           *hm_sa_arena_sv = NULL; /* the Shared::Arena object, held */

/* At BOOT, once. The VALUE eval_pv returns, not the top of the stack: eval_pv
 * has already popped what it evaluated (sa_abi.h spells out the trap). */
static void hm_sa_resolve(pTHX) {
    SV *sv, *err;
    if (HM_SA) return;
    if (getenv("HYPERMAN_NO_SA_ABI")) return;
    sv  = eval_pv("require Shared::Arena; Shared::Arena::_abi_ptr()", 0);
    err = get_sv("@", 0);
    if (!sv || !SvOK(sv) || (err && SvTRUE(err))) return;
    {
        const sa_abi *t = INT2PTR(const sa_abi *, SvUV(sv));
        if (t && t->abi_version >= SA_ABI_VERSION) HM_SA = t;
    }
}

/* How big an arena the server needs: the sum of every tenant the later
 * phases carve, from the same numbers those tenants are sized with, plus
 * headroom. Generous by design - a slot's exact bytes are the provider's
 * business - and a carve that does not fit is refused by Shared::Arena and
 * that tenant fails open with a warning naming the shortfall. */
static UV hm_sa_bytes(unsigned deny_cap, unsigned rate_cap,
                      unsigned bus_slots, unsigned bus_slot_size) {
    UV b = 0;
    if (!deny_cap)      deny_cap      = 1024;
    if (!rate_cap)      rate_cap      = 4096;
    if (!bus_slots)     bus_slots     = 2048;
    if (!bus_slot_size) bus_slot_size = 2048;
    b += (UV)deny_cap * 96 + 4096;             /* hm_sa_abuse.h: the denylist */
    b += (UV)rate_cap * 64 + 4096;             /* hm_sa_abuse.h: the window   */
    b += (UV)bus_slots * (bus_slot_size + 64)   /* hm_sa_bus.h: the ring, its  */
       + 64 * 128 + 4096;                       /* slot 64 wider, plus groups  */
    b += 256 * 256 + 4096;                      /* phase 06: the scoreboard    */
    b += 16384 + 4096 + 4096;                   /* phase 06: HLL p=14, leases  */
    b += 65536;                                 /* headroom                    */
    return b;
}

/* Create the arena FROM PERL, before the fork. Idempotent: one arena per
 * process. `name` NULL or empty is anonymous; a name that already exists is
 * attached, not recreated, which is what a restart wants. */
static void hm_sa_open(pTHX_ const char *name, STRLEN nlen, UV bytes) {
    dSP;
    int count;
    SV *ret = NULL;

    if (!HM_SA || hm_sa_arena_sv) return;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 5);
    mPUSHp("Shared::Arena", 13);
    mPUSHp("size", 4);
    mPUSHu(bytes);
    if (name && nlen) { mPUSHp("name", 4); mPUSHp(name, nlen); }
    PUTBACK;
    count = call_method("create", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (count == 1) ret = POPs;
    if (SvTRUE(ERRSV) || !ret || !SvROK(ret)) {
        warn("Hyperman: Shared::Arena->create failed (%s); running without "
             "an arena", SvTRUE(ERRSV) ? SvPV_nolen(ERRSV) : "no object");
        PUTBACK; FREETMPS; LEAVE;
        return;
    }
    hm_sa_arena_sv = newSVsv(ret);
    PUTBACK; FREETMPS; LEAVE;

    /* The region behind the object, for the C side. */
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(hm_sa_arena_sv);
    PUTBACK;
    count = call_method("_region_ptr", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (count == 1 && !SvTRUE(ERRSV)) {
        SV *p = POPs;
        hm_sa_region = INT2PTR(sa_region *, SvUV(p));
    }
    else {
        warn("Hyperman: Shared::Arena::_region_ptr failed (%s); the arena is "
             "reachable from Perl only", SvTRUE(ERRSV) ? SvPV_nolen(ERRSV) : "?");
    }
    PUTBACK; FREETMPS; LEAVE;
}

/* After the fork, once per worker: a peer slot of this worker's own, so a
 * record it leaves unfinished can be attributed to it. */
static void hm_sa_worker_join(void) {
    if (HM_SA && hm_sa_region) (void)HM_SA->join(hm_sa_region);
}

#endif /* HM_SA_H */
