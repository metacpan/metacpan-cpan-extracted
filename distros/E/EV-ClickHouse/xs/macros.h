/* Common idioms used across the XS — kept here so the main translation
 * unit and the file-local-to-the-TU includes can share them without
 * duplicating definitions.
 *
 * IS_KEEPALIVE_CB depends on `keepalive_noop_cb` which is defined later
 * in the .xs; this header only declares the macro so the dependency is
 * resolved at expansion time, not at parse time. */

#ifndef EV_CH_MACROS_H
#define EV_CH_MACROS_H

/* Drop an owned C string and reset the slot to NULL. */
#define CLEAR_STR(p) do { if (p) { Safefree(p); (p) = NULL; } } while (0)

/* Drop a refcounted SV and reset the slot to NULL. */
#define CLEAR_SV(p)  do { if (p) { SvREFCNT_dec((SV*)(p)); (p) = NULL; } } while (0)

/* call_sv a stored handler SV, pinned across the call so the callback may
 * clear its own handler (e.g. $ch->on_error(undef)) without freeing the CV
 * mid-call. Args must already be pushed. */
#define PINNED_CALL_SV(handler, flags) \
    STMT_START { SV *_pin = (handler); SvREFCNT_inc_simple_void_NN(_pin); \
                 call_sv(_pin, (flags)); SvREFCNT_dec(_pin); } STMT_END

/* Discard the pending two-phase INSERT payload (text or AV form). Does
 * not touch insert_err — caller decides whether to clear it. */
#define CLEAR_INSERT(s) do { \
    CLEAR_STR((s)->insert_data); (s)->insert_data_len = 0; \
    CLEAR_SV((s)->insert_av); \
} while (0)

/* Post G_EVAL idiom: warn-and-clear ERRSV when an untrusted user
 * callback threw. Use only at sites that must continue work after the
 * call (e.g. still need SPAGAIN/FREETMPS or further dispatches); helpers
 * that return immediately can omit the clear. */
#define WARN_AND_CLEAR_ERRSV(label) do { \
    if (SvTRUE(ERRSV)) { \
        warn("EV::ClickHouse: exception in " label ": %s", SvPV_nolen(ERRSV)); \
        sv_setsv(ERRSV, &PL_sv_undef); \
    } \
} while (0)

/* HTTP keepalive uses keepalive_noop_cb as a sentinel — suppress the
 * on_query_complete (and on_query_start) fire for it so observers don't
 * see spurious zero-row "completions" they didn't initiate. The native
 * keepalive path bypasses cb_queue entirely, so this only matters for
 * HTTP. The sentinel is defined later in the .xs; this macro just
 * forward-references it. */
#define IS_KEEPALIVE_CB(cb) ((cb) && (cb) == keepalive_noop_cb)

#endif /* EV_CH_MACROS_H */
