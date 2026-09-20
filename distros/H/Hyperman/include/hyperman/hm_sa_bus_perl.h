/* hm_sa_bus_perl.h - the Perl-side state and collector for the message bus.
 *
 * Separate from hm_sa_bus.h because that header knows nothing about Perl and
 * should stay that way: it is the substrate an XS consumer reaches through
 * the ABI, and the benchmark harness drives it with no interpreter. This is
 * the thin layer that turns a drain into a list of pairs and a record into a
 * call of a coderef.
 */

#ifndef HM_SA_BUS_PERL_H
#define HM_SA_BUS_PERL_H

#include "hm_sa_bus.h"

/* Collect one message as [topic, payload]. The strings are copies: the
 * callback is handed pointers into the cursor's scratch, which the next
 * record overwrites. */
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

/* A registration is a coderef held in this process. It cannot cross a fork,
 * which is why the shared thing is the ring and not the list of readers. */
static SV *hm_bus_perl_subs[HM_BUS_SUBS];

/* Deliver one message to one Perl subscriber.
 *
 * G_EVAL is not optional. This runs from the event loop, called out of an io
 * watcher with no Perl frame around it, and a die from a subscriber would
 * unwind through the loop and take the worker down - which for a chat server
 * means one bad handler silently removing a worker from the pool. A death
 * becomes a warning and the next subscriber still runs. */
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

#endif /* HM_SA_BUS_PERL_H */
