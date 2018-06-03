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
#include "pl_util.h"

static void duk_fatal_error_handler(void* data, const char* msg)
{
    UNUSED_ARG(data);
    dTHX;
    PerlIO_printf(PerlIO_stderr(), "duktape fatal error, aborting: %s\n", msg ? msg : "*NONE*");
    abort();
}

static Duk* create_duktape_object(pTHX_ HV* opt)
{
    Duk* duk = (Duk*) malloc(sizeof(Duk));
    memset(duk, 0, sizeof(Duk));

    duk->pagesize = getpagesize();
    duk->stats = newHV();
    duk->msgs = newHV();

    duk->ctx = duk_create_heap(0, 0, 0, 0, duk_fatal_error_handler);
    if (!duk->ctx) {
        croak("Could not create duk heap\n");
    }

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
            croak("Unknown option %*.*s\n", (int) klen, (int) klen, kstr);
        }
    }

    // register a bunch of native functions
    pl_register_native_functions(duk);

    // initialize module handling functions
    pl_register_module_functions(duk);

    // register event loop dispatcher
    pl_register_eventloop(duk);

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
    ctx = duk->ctx;
    pl_stats_start(aTHX_ duk, &stats);
    RETVAL = pl_set_global_or_property(aTHX_ ctx, name, value);
    pl_stats_stop(aTHX_ duk, &stats, "set");
  OUTPUT: RETVAL

SV*
eval(Duk* duk, const char* js, const char* file = 0)
  PREINIT:
    duk_context* ctx = 0;
    Stats stats;
    duk_uint_t flags = 0;
    duk_int_t rc = 0;
  CODE:
    ctx = duk->ctx;

    /* flags |= DUK_COMPILE_STRICT; */

    pl_stats_start(aTHX_ duk, &stats);
    if (!file) {
        rc = duk_pcompile_string(ctx, flags, js);
    }
    else {
        duk_push_string(ctx, file);
        rc = duk_pcompile_string_filename(ctx, flags, js);
    }
    pl_stats_stop(aTHX_ duk, &stats, "compile");

    if (rc != DUK_EXEC_SUCCESS) {
        croak("JS could not compile code: %s\n", duk_safe_to_string(ctx, -1));
    }

    pl_stats_start(aTHX_ duk, &stats);
    rc = duk_pcall(ctx, 0);
    pl_stats_stop(aTHX_ duk, &stats, "run");
    check_duktape_call_for_errors(rc, ctx);

    RETVAL = pl_duk_to_perl(aTHX_ ctx, -1);
    duk_pop(ctx);
  OUTPUT: RETVAL

SV*
dispatch_function_in_event_loop(Duk* duk, const char* func)
  PREINIT:
    Stats stats;
  CODE:
    pl_stats_start(aTHX_ duk, &stats);
    RETVAL = newSViv(pl_run_function_in_event_loop(duk, func));
    pl_stats_stop(aTHX_ duk, &stats, "dispatch");
  OUTPUT: RETVAL

SV*
run_gc(Duk* duk)
  PREINIT:
    Stats stats;
  CODE:
    pl_stats_start(aTHX_ duk, &stats);
    RETVAL = newSVnv(pl_run_gc(duk));
    pl_stats_stop(aTHX_ duk, &stats, "run_gc");
  OUTPUT: RETVAL
