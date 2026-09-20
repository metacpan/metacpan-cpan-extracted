MODULE = Hyperman    PACKAGE = Hyperman

PROTOTYPES: DISABLE

# The cross-worker message bus, on a ring in the Shared::Arena.
#
# Class methods, matching deny_add / ratelimit_hit next door: the ring is
# process-global, so there is nothing to hold an object over, and an
# application that is not an XS module should not have to become one to reach
# it.
#
# TWO DELIVERY MODES, ONE MECHANISM. A message is published once; what differs
# is where the cursor lives. A FANOUT reader keeps its cursor in its own
# process, so every reader sees every message. A QUEUE GROUP keeps one cursor
# in the arena, advanced with a compare-and-swap, so exactly one member of the
# pool sees each message.

# bus_init(slots => N, slot_size => N, groups => N, wakers => N) -> 1 if
# there is a ring
#
# run() does this before it forks, which is the only place it can be done: a
# ring created after the fork is one ring per worker, which is a bus that
# delivers to nobody. This is here for a script or a test that forks by hand
# and needs the same guarantee. Idempotent - the first call wins, so calling
# it after the server has started changes nothing. With no arena yet, the
# default one is created first. `groups` is accepted and ignored: the ring's
# group table is fixed at 64.
IV
bus_init(class, ...)
        SV *class
    CODE:
    {
        UV slots = 0, slot_size = 0, groups = 0, wakers = 0;
        int i, err = 0;
        PERL_UNUSED_VAR(class);
        for (i = 1; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            if      (strEQ(k, "slots"))     slots     = SvUV(ST(i + 1));
            else if (strEQ(k, "slot_size")) slot_size = SvUV(ST(i + 1));
            else if (strEQ(k, "groups"))    groups    = SvUV(ST(i + 1));
            else if (strEQ(k, "wakers"))    wakers    = SvUV(ST(i + 1));
        }
        PERL_UNUSED_VAR(groups);
        hm_sa_open(aTHX_ NULL, 0,
                   hm_sa_bytes(0, 0, (unsigned)slots, (unsigned)slot_size));
        (void)hm_sa_bus_open((uint32_t)slots, (uint32_t)slot_size, &err);
        /* The wakeup descriptors go with the ring and for the same reason:
         * made before any fork, or a worker's poke reaches nobody. run()
         * sizes this from the worker count. */
        (void)hm_sa_bus_wake_init((uint32_t)(wakers ? wakers : 8));
        RETVAL = hm_sa_bus_live() ? 1 : 0;
    }
    OUTPUT:
        RETVAL

# Is there a shared ring at all?
#
# Ask before assuming the pool can hear you. With no ring - Shared::Arena
# absent, a compiler without atomics, or simply not running under Hyperman -
# publish reaches this process only. That is a supported configuration and
# the tested path, not a broken one.
IV
bus_live(class = &PL_sv_undef)
        SV *class
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = hm_sa_bus_live() ? 1 : 0;
    OUTPUT:
        RETVAL

# publish($topic, $payload)
#
#    1  on the ring, and the whole pool will see it
#    0  LOCAL ONLY - there is no ring, so nobody else will
#   -1  refused: too big for a slot
#
# Three outcomes rather than true/false, because "sent to the pool" and "sent
# to myself" are different things and a caller that cannot tell them apart
# cannot diagnose anything.
#
# An oversize message is REFUSED, never truncated. A truncated WebSocket frame
# is a protocol violation delivered to every member of a room, which is worse
# than a publish that failed where the caller can see it. Raise bus_slot_size
# when the messages are genuinely that big.
IV
publish(class, topic, payload)
        SV *class
        SV *topic
        SV *payload
    CODE:
    {
        STRLEN tl, pl;
        const char *t = SvPV_const(topic, tl);
        const char *p = SvPV_const(payload, pl);
        int r = hm_sa_bus_publish(t, (uint32_t)tl, p, (uint32_t)pl);
        PERL_UNUSED_VAR(class);
        RETVAL = (r == HM_BUS_OK) ? 1 : (r == HM_BUS_LOCAL) ? 0 : -1;
    }
    OUTPUT:
        RETVAL

# bus_reset() -> the sequence it reset to
#
# Point this process's fanout cursors at "from now on". A WORKER MUST CALL
# THIS AFTER A FORK: a cursor inherited from the parent either replays what
# the parent already delivered or skips what it has not, and both look like
# the bus being broken. on_worker_start is the place.
#
# BOTH cursors. There are two - one for receive(), one for the subscription
# dispatcher - because two readers in one process must not consume each
# other's messages. But a caller saying "from now on" means the process, not
# one of its two halves, and resetting only one leaves the other replaying.
IV
bus_reset(class = &PL_sv_undef)
        SV *class
    CODE:
        PERL_UNUSED_VAR(class);
        hm_sa_bus_reset_cursors();
        RETVAL = (IV)hm_sa_bus_seq();
    OUTPUT:
        RETVAL

# receive() -> ( [topic, payload], ... )
#
# Everything published since this process last asked. FANOUT: the cursor is
# this process's own, so every reader gets every message.
#
# Returns the empty list when there is nothing, which is the common case and
# costs one atomic load.
void
receive(class = &PL_sv_undef)
        SV *class
    PPCODE:
    {
        AV *out = (AV *)sv_2mortal((SV *)newAV());
        SSize_t i, n;
        PERL_UNUSED_VAR(class);
        (void)hm_sa_bus_drain(&hm_sa_recv_cur, hm_bus_perl_collect, out);
        n = av_len(out) + 1;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(out, i, 0);
            PUSHs(e && *e ? sv_2mortal(newSVsv(*e)) : &PL_sv_undef);
        }
    }

# How many messages this process MISSED, because it did not read them before
# the ring wrapped past them, or because a publisher died leaving a hole.
#
# Reporting this is not optional. A silently short chat room is
# indistinguishable from a quiet one; a gap with a number beside it is a
# diagnosis. If this is climbing, the reader is too slow or bus_slots is too
# small.
#
# BOTH cursors, because this answers a question about the PROCESS. There are
# two readers - receive() has its own cursor, the dispatcher that feeds
# subscribe() has another - and this used to report only receive()'s. Under a
# server nothing calls receive(), so the number was always zero however much
# the dispatcher dropped: the one place a short count had to be explained was
# the one place the counter could not see.
IV
bus_gaps(class = &PL_sv_undef)
        SV *class
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = (IV)(hm_sa_bus_gaps_of(hm_sa_recv_cur)
                    + hm_sa_bus_gaps_of(hm_sa_disp_cur));
    OUTPUT:
        RETVAL

# claim($topic, $group) -> ( [topic, payload], ... )
#
# A QUEUE GROUP: whatever nobody else in the pool has taken. One
# compare-and-swap on the group's shared cursor hands each message to exactly
# one caller, in one process, across every worker.
#
# Balancing is not implemented, it is a consequence: a worker that is busy is
# not in this call, so it does not claim, so the free workers take the
# traffic. There is no scheduler and nothing to tune.
#
# AT-MOST-ONCE. A worker that claims a message and then dies loses it, and the
# loss is counted rather than retried. If losing it matters, this is the wrong
# tool and Punk::Queue is the right one.
#
# The group is created on first use and starts at the current sequence:
# joining means "from now on", not "replay everything".
#
# A group is bound to its TOPIC, and the identity is the pair. Without that a
# group would claim every message on the ring whatever its topic, mark it
# handled, and the intended reader would never see it. $group defaults to the
# topic, which is what a single group per topic wants.
void
claim(class, topic, group = &PL_sv_undef)
        SV *class
        SV *topic
        SV *group
    PPCODE:
    {
        AV *out = (AV *)sv_2mortal((SV *)newAV());
        STRLEN tl, gl;
        const char *t = SvPV_const(topic, tl);
        const char *g = SvOK(group) ? SvPV_const(group, gl) : (gl = tl, t);
        sa_group_h *gh = hm_sa_bus_group(t, (uint32_t)tl, g, (uint32_t)gl);
        SSize_t i, n;
        PERL_UNUSED_VAR(class);
        if (!gh) XSRETURN_EMPTY;           /* no ring, or the table is full */
        (void)hm_sa_bus_claim(gh, hm_bus_perl_collect, out);
        n = av_len(out) + 1;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(out, i, 0);
            PUSHs(e && *e ? sv_2mortal(newSVsv(*e)) : &PL_sv_undef);
        }
    }

# subscribe($topic, $cb, group => $name) -> an id, or -1
#
# The callback is invoked as $cb->($topic, $payload) from the worker's event
# loop, as soon as a publish from any worker pokes this one. No polling, and
# no Perl frame on the publishing side.
#
# `group` is the ONLY difference between the two delivery modes. Without it
# this process sees every message on the topic. With it, this process competes
# with every other member of that group and exactly one of them sees each
# message - load balanced, with no scheduler, because a busy worker is not in
# the loop to claim.
#
# A subscriber that dies gets its death turned into a warning: it runs from the
# event loop with nothing to unwind into, and one bad handler must not remove a
# worker from the pool.
IV
subscribe(class, topic, cb, ...)
        SV *class
        SV *topic
        SV *cb
    CODE:
    {
        STRLEN tl, gl = 0;
        const char *t = SvPV_const(topic, tl);
        const char *g = NULL;
        int i, id;
        PERL_UNUSED_VAR(class);
        if (!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV))
            croak("Hyperman->subscribe: need a code reference");
        for (i = 3; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            if (strEQ(k, "group") && SvOK(ST(i + 1)))
                g = SvPV_const(ST(i + 1), gl);
        }
        id = hm_sa_bus_subscribe(t, (uint32_t)tl, g, (uint32_t)gl,
                                 hm_bus_perl_deliver, NULL);
        if (id < 0) XSRETURN_IV(-1);
        if (hm_bus_perl_subs[id]) SvREFCNT_dec(hm_bus_perl_subs[id]);
        hm_bus_perl_subs[id] = newSVsv(cb);
        hm_bus_subs[id].ud   = (void *)hm_bus_perl_subs[id];
        RETVAL = id;
    }
    OUTPUT:
        RETVAL

IV
unsubscribe(class, id)
        SV *class
        IV id
    CODE:
    {
        PERL_UNUSED_VAR(class);
        if (id >= 0 && id < HM_BUS_SUBS && hm_bus_perl_subs[id]) {
            SvREFCNT_dec(hm_bus_perl_subs[id]);
            hm_bus_perl_subs[id] = NULL;
        }
        RETVAL = hm_sa_bus_unsubscribe((int)id);
    }
    OUTPUT:
        RETVAL

# dispatch() -> how many were delivered
#
# Runs the subscriptions by hand. Under a Hyperman worker the wakeup does this
# and a caller never needs to; outside one - a script, a test, a server that is
# not Hyperman - this is the poll that stands in for it. It never blocks: a
# record still being written is left for the next call.
IV
dispatch(class = &PL_sv_undef)
        SV *class
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = (IV)hm_sa_bus_dispatch();
    OUTPUT:
        RETVAL

# bus_waker_take($index) -> this process's wakeup descriptor, or -1
#
# A worker calls this after the fork, with its own worker number, so no two
# workers share a descriptor. Under a Hyperman server the server does it; this
# is here for a process that forks by hand, and for the tests, which have to
# be able to block on the descriptor the way an event loop does.
IV
bus_waker_take(class, idx)
        SV *class
        IV idx
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = hm_sa_bus_waker_take((int)idx);
    OUTPUT:
        RETVAL

# Empty the poke and clear the coalescing flag. Called before dispatching, so
# a publish that lands DURING the dispatch pokes again rather than being folded
# into a wakeup that has already been handled.
void
bus_waker_drained(class = &PL_sv_undef)
        SV *class
    CODE:
        PERL_UNUSED_VAR(class);
        hm_sa_bus_waker_drained();

# bus_stats() -> ( published => N, gaps => N, group_gaps => N )
#
# `gaps` is this process's; `group_gaps` belongs to the named group and is
# shared, because a message lapped before anybody claimed it was lost by the
# group rather than by whichever member noticed. The group is the one
# claim($group) without a topic would use: named after its topic.
void
bus_stats(class, group = &PL_sv_undef)
        SV *class
        SV *group
    PPCODE:
    {
        PERL_UNUSED_VAR(class);
        EXTEND(SP, 6);
        mPUSHp("published", 9); mPUSHu((UV)hm_sa_bus_published());
        /* Both cursors, for the reason bus_gaps says. */
        mPUSHp("gaps", 4);      mPUSHu((UV)(hm_sa_bus_gaps_of(hm_sa_recv_cur)
                                            + hm_sa_bus_gaps_of(hm_sa_disp_cur)));
        if (SvOK(group)) {
            STRLEN gl;
            const char *g = SvPV_const(group, gl);
            sa_group_h *gh = hm_sa_bus_group(g, (uint32_t)gl, g, (uint32_t)gl);
            mPUSHp("group_gaps", 10);
            mPUSHu(gh ? (UV)hm_sa_bus_group_gaps(gh) : 0);
        }
    }
