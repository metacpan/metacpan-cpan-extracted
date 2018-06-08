#define PERL_NO_GET_CONTEXT      /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/*
 * Duktape is an embeddable Javascript engine, with a focus on portability and
 * compact footprint.
 *
 * http://duktape.org/index.html
 */
#include "pl_duk.h"
#include "pl_stats.h"
#include "pl_module.h"
#include "pl_eventloop.h"
#include "pl_console.h"
#include "pl_native.h"
#include "pl_inlined.h"
#include "pl_sandbox.h"
#include "pl_util.h"

#define MAX_MEMORY_MINIMUM  (128 * 1024) /* 128 KB */
#define MAX_TIMEOUT_MINIMUM (500000)     /* 500_000 us = 500 ms = 0.5 s */

#define TIMEOUT_RESET(duk) \
    do { \
        if (duk->max_timeout_us > 0) { \
            duk->eval_start_us = now_us(); \
        } \
    } while (0) \

static void duk_fatal_error_handler(void* udata, const char* msg)
{
    /* Duk* duk = (Duk*) udata; */
    UNUSED_ARG(udata);
    dTHX;
    PerlIO_printf(PerlIO_stderr(), "duktape fatal error, aborting: %s\n", msg ? msg : "*NONE*");
    abort();
}

static Duk* create_duktape_object(pTHX_ HV* opt)
{
    Duk* duk = (Duk*) malloc(sizeof(Duk));
    memset(duk, 0, sizeof(Duk));

    duk->pagesize_bytes = getpagesize();

    duk->stats = newHV();
    duk->msgs = newHV();

    if (opt) {
        hv_iterinit(opt);
        while (1) {
            SV* value = 0;
            I32 klen = 0;
            char* kstr = 0;
            HE* entry = hv_iternext(opt);
            if (!entry) {
                break; // no more hash keys
            }
            kstr = hv_iterkey(entry, &klen);
            if (!kstr || klen < 0) {
                continue; // invalid key
            }
            value = hv_iterval(opt, entry);
            if (!value) {
                continue; // invalid value
            }
            if (memcmp(kstr, DUK_OPT_NAME_GATHER_STATS, klen) == 0) {
                duk->flags |= SvTRUE(value) ? DUK_OPT_FLAG_GATHER_STATS : 0;
                continue;
            }
            if (memcmp(kstr, DUK_OPT_NAME_SAVE_MESSAGES, klen) == 0) {
                duk->flags |= SvTRUE(value) ? DUK_OPT_FLAG_SAVE_MESSAGES : 0;
                continue;
            }
            if (memcmp(kstr, DUK_OPT_NAME_MAX_MEMORY_BYTES, klen) == 0) {
                int param = SvIV(value);
                duk->max_allocated_bytes = param > MAX_MEMORY_MINIMUM ? param : MAX_MEMORY_MINIMUM;
                continue;
            }
            if (memcmp(kstr, DUK_OPT_NAME_MAX_TIMEOUT_US, klen) == 0) {
                int param = SvIV(value);
                duk->max_timeout_us = param > MAX_TIMEOUT_MINIMUM ? param : MAX_TIMEOUT_MINIMUM;
                continue;
            }
            croak("Unknown option %*.*s\n", (int) klen, (int) klen, kstr);
        }
    }

    duk->ctx = duk_create_heap(pl_sandbox_alloc, pl_sandbox_realloc, pl_sandbox_free, duk, duk_fatal_error_handler);
    if (!duk->ctx) {
        croak("Could not create duk heap\n");
    }

    TIMEOUT_RESET(duk);

    // register a bunch of native functions
    pl_register_native_functions(duk);

    // initialize module handling functions
    pl_register_module_functions(duk);

    // register event loop dispatcher
    pl_register_eventloop(duk);

    // inline a bunch of JS functions
    pl_register_inlined_functions(duk);

    // initialize console object
    pl_console_init(duk);

    return duk;
}

static int session_dtor(pTHX_ SV* sv, MAGIC* mg)
{
    UNUSED_ARG(sv);
    Duk* duk = (Duk*) mg->mg_ptr;
    duk_destroy_heap(duk->ctx);
    return 0;
}

static MGVTBL session_magic_vtbl = { .svt_free = session_dtor };

MODULE = JavaScript::Duktape::XS       PACKAGE = JavaScript::Duktape::XS
PROTOTYPES: DISABLE

#################################################################

Duk*
new(char* CLASS, HV* opt = NULL)
  CODE:
    UNUSED_ARG(opt);
    RETVAL = create_duktape_object(aTHX_ opt);
  OUTPUT: RETVAL

HV*
get_stats(Duk* duk)
  CODE:
    RETVAL = duk->stats;
  OUTPUT: RETVAL

void
reset_stats(Duk* duk)
  PPCODE:
    duk->stats = newHV();

HV*
get_msgs(Duk* duk)
  CODE:
    RETVAL = duk->msgs;
  OUTPUT: RETVAL

void
reset_msgs(Duk* duk)
  PPCODE:
    duk->msgs = newHV();

SV*
get(Duk* duk, const char* name)
  PREINIT:
    duk_context* ctx = 0;
    Stats stats;
  CODE:
    TIMEOUT_RESET(duk);
    ctx = duk->ctx;
    pl_stats_start(aTHX_ duk, &stats);
    RETVAL = pl_get_global_or_property(aTHX_ ctx, name);
    pl_stats_stop(aTHX_ duk, &stats, "get");
  OUTPUT: RETVAL

SV*
exists(Duk* duk, const char* name)
  PREINIT:
    duk_context* ctx = 0;
    Stats stats;
  CODE:
    TIMEOUT_RESET(duk);
    ctx = duk->ctx;
    pl_stats_start(aTHX_ duk, &stats);
    RETVAL = pl_exists_global_or_property(aTHX_ ctx, name);
    pl_stats_stop(aTHX_ duk, &stats, "exists");
  OUTPUT: RETVAL

SV*
typeof(Duk* duk, const char* name)
  PREINIT:
    duk_context* ctx = 0;
    Stats stats;
  CODE:
    TIMEOUT_RESET(duk);
    ctx = duk->ctx;
    pl_stats_start(aTHX_ duk, &stats);
    RETVAL = pl_typeof_global_or_property(aTHX_ ctx, name);
    pl_stats_stop(aTHX_ duk, &stats, "typeof");
  OUTPUT: RETVAL

SV*
instanceof(Duk* duk, const char* object, const char* class)
  PREINIT:
    duk_context* ctx = 0;
    Stats stats;
  CODE:
    TIMEOUT_RESET(duk);
    ctx = duk->ctx;
    pl_stats_start(aTHX_ duk, &stats);
    RETVAL = pl_instanceof_global_or_property(aTHX_ ctx, object, class);
    pl_stats_stop(aTHX_ duk, &stats, "instanceof");
  OUTPUT: RETVAL

int
set(Duk* duk, const char* name, SV* value)
  PREINIT:
    duk_context* ctx = 0;
    Stats stats;
  CODE:
    TIMEOUT_RESET(duk);
    ctx = duk->ctx;
    pl_stats_start(aTHX_ duk, &stats);
    RETVAL = pl_set_global_or_property(aTHX_ ctx, name, value);
    pl_stats_stop(aTHX_ duk, &stats, "set");
  OUTPUT: RETVAL

SV*
eval(Duk* duk, const char* js, const char* file = 0)
  CODE:
    TIMEOUT_RESET(duk);
    RETVAL = pl_eval(aTHX_ duk, js, file);
  OUTPUT: RETVAL

SV*
dispatch_function_in_event_loop(Duk* duk, const char* func)
  PREINIT:
    Stats stats;
  CODE:
    TIMEOUT_RESET(duk);
    pl_stats_start(aTHX_ duk, &stats);
    RETVAL = newSViv(pl_run_function_in_event_loop(duk, func));
    pl_stats_stop(aTHX_ duk, &stats, "dispatch");
  OUTPUT: RETVAL

SV*
run_gc(Duk* duk)
  PREINIT:
    Stats stats;
  CODE:
    TIMEOUT_RESET(duk);
    pl_stats_start(aTHX_ duk, &stats);
    RETVAL = newSVnv(pl_run_gc(duk));
    pl_stats_stop(aTHX_ duk, &stats, "run_gc");
  OUTPUT: RETVAL
