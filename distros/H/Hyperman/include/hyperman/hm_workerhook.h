/* hm_workerhook.h - the v4 on_worker_start registry.
 *
 * Split out and included before hm_core.h because the two halves sit on
 * opposite sides of the build: hm_core.h FIRES the callbacks, from inside
 * hm_worker, while hm_abi_impl.h REGISTERS them, and it is compiled after.
 * Only the storage and the two small functions are needed by both.
 *
 * Needs hm_abi.h (the hm_abi_worker_cb typedef) and nothing else.
 */

#ifndef HM_WORKERHOOK_H
#define HM_WORKERHOOK_H

#include "hm_abi.h"

static struct { hm_abi_worker_cb cb; void *ud; }
    HM_WORKER_CB[HM_ABI_MAX_WORKER_CB];
static int HM_WORKER_CB_N = 0;

static int hm_worker_hook_add(pTHX_ hm_abi_worker_cb cb, void *ud) {
    PERL_UNUSED_CONTEXT;
    if (!cb || HM_WORKER_CB_N >= HM_ABI_MAX_WORKER_CB) return 0;
    HM_WORKER_CB[HM_WORKER_CB_N].cb = cb;
    HM_WORKER_CB[HM_WORKER_CB_N].ud = ud;
    HM_WORKER_CB_N++;
    return 1;
}

/* Fire, in registration order, with this worker's loop. Called from
 * hm_worker once the loop exists and before it starts turning - which in a
 * prefork server is in the child, after the fork.
 *
 * Registration happens in the parent, before run(), and the array is plain
 * memory, so every child inherits the same list across fork() without any
 * work. That is the reason this is an array of C pointers and not anything
 * holding an SV: it has to survive a fork the consumer never sees. */
static void hm_worker_hook_fire(pTHX_ void *loop) {
    int i;
    for (i = 0; i < HM_WORKER_CB_N; i++)
        HM_WORKER_CB[i].cb(aTHX_ loop, HM_WORKER_CB[i].ud);
}

#endif /* HM_WORKERHOOK_H */
