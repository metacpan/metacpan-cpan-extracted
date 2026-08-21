/* hm_bus_perl.h - the Perl-side state and collector for the message bus.
 *
 * Separate from hm_bus.h because that header knows nothing about Perl and
 * should stay that way: it is the substrate an XS consumer reaches through
 * the ABI, and a consumer that is not Perl at all would still want it. This
 * is the thin layer that turns a drain into a list of pairs.
 *
 * Same arrangement as hm_workerhook_perl.h beside it.
 */

#ifndef HM_BUS_PERL_H
#define HM_BUS_PERL_H

#include "hm_bus.h"

/* The process-local FANOUT cursor.
 *
 * Process-local is the whole point: it is what makes fanout fanout, because
 * every subscriber keeps its own and so every subscriber reads every message.
 * A queue group's cursor lives in the arena instead, which is the entire
 * difference between the two delivery modes.
 *
 * It MUST NOT survive a fork. A worker that inherited the parent's would
 * replay what the parent already delivered, or skip what it has not, and
 * either way the bug looks like the bus losing messages. A worker resets it
 * at startup - the same discipline otel_tracer.h enforces with its owner_pid
 * check, for the same reason. */
static uint64_t hm_bus_perl_cursor = 1;   /* 0 would read a phantom */
static uint64_t hm_bus_perl_gaps   = 0;

/* Collect one message as [topic, payload]. The strings are copies: the
 * callback is handed a pointer into a scratch buffer that the next message
 * overwrites. */
static void hm_bus_perl_collect(void *ud, uint64_t seq, const char *topic,
                                uint32_t tlen, const char *payload,
                                uint32_t plen) {
    dTHX;
    AV *out = (AV *)ud;
    AV *one = newAV();
    (void)seq;
    av_push(one, newSVpvn(topic, tlen));
    av_push(one, newSVpvn(payload, plen));
    av_push(out, newRV_noinc((SV *)one));
}

/* ---- Perl subscriptions -------------------------------------------------- */
/*
 * A registration is a coderef held in this process. It cannot cross a fork,
 * which is why the shared thing is the ring and not the list of readers.
 */
static SV *hm_bus_perl_subs[HM_BUS_SUBS];

/* Deliver one message to one Perl subscriber.
 *
 * G_EVAL is not optional. This runs from the event loop, called out of an io
 * watcher with no Perl frame around it, and a die from a subscriber would
 * unwind through the loop and take the worker down - which for a chat server
 * means one bad handler silently removing a worker from the pool. A death
 * becomes a warning and the next subscriber still runs.
 */
static void hm_bus_perl_deliver(void *ud, uint64_t seq, const char *topic,
                                uint32_t tlen, const char *payload,
                                uint32_t plen) {
    dTHX;
    dSP;
    SV *cb = (SV *)ud;
    (void)seq;
    if (!cb || !SvOK(cb)) return;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSVpvn(topic, tlen)));
    PUSHs(sv_2mortal(newSVpvn(payload, plen)));
    PUTBACK;
    (void)call_sv(cb, G_VOID | G_DISCARD | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV))
        warn("Hyperman: bus subscriber died: %" SVf, SVfARG(ERRSV));
    PUTBACK;
    FREETMPS; LEAVE;
}

#endif /* HM_BUS_PERL_H */
