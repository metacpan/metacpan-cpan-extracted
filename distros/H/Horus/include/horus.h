#ifndef HORUS_H
#define HORUS_H

/*
 * horus.h - Perl XS wrapper for the Horus UUID library
 *
 * This header sets up Perl-specific error handling, includes the
 * pure C core library, and defines the MY_CXT thread-safe state.
 *
 * For reuse from OTHER XS modules without Perl overhead, include
 * horus_core.h directly instead (see that header for usage).
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* Route fatal errors through Perl's croak() */
#define HORUS_FATAL(msg) croak("%s", (msg))

/* Pull in the entire pure-C UUID library */
#include "horus_core.h"

/* ── MY_CXT for thread-safe state (Perl-specific) ──────────────── */

#define MY_CXT_KEY "Horus::_guts" XS_VERSION

typedef struct {
    horus_v1_state_t v1_state;   /* shared by v1, v2, v6 */
    horus_v6_state_t v6_state;   /* monotonic state for v6 */
    horus_v7_state_t v7_state;   /* monotonic state for v7 */
} my_cxt_t;

START_MY_CXT

#endif /* HORUS_H */
