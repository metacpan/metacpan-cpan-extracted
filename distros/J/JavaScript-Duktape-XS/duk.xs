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
#include "util.h"
#include "duktape.h"
#include "c_eventloop.h"
#include "duk_console.h"

#define DUK_SLOT_CALLBACK "_perl_.callback"

#define DUK_OPT_NAME_GATHER_STATS "gather_stats"
#define DUK_OPT_NAME_SAVE_MESSAGES "save_messages"

#define DUK_OPT_FLAG_GATHER_STATS 0x01
#define DUK_OPT_FLAG_SAVE_MESSAGES 0x02

/*
 * This is our internal data structure.  For now it only contains a pointer to
 * a duktape context.  We will add other stuff here.
 */
typedef struct Duk {
    duk_context* ctx;
    int pagesize;
    unsigned long flags;
    HV* stats;
    HV* msgs;
} Duk;

typedef struct Stats {
    double t0, t1;
    double m0, m1;
} Stats;

/*
 * We use these two functions to convert back and forth between the Perl
 * representation of an object and the JS one.
 *
 * Because data in Perl and JS can be nested (array of hashes of arrays of...),
 * the functions are recursive.
 *
 * duk_to_perl: takes a JS value from a given position in the duktape stack,
 * and creates the equivalent Perl value.
 *
 * perl_to_duk: takes a Perl value and leaves the equivalent JS value at the
 * top of the duktape stack.
 */
static SV* duk_to_perl(pTHX_ duk_context* ctx, int pos);
static int perl_to_duk(pTHX_ SV* value, duk_context* ctx);

/*
 * Native print callable from JS
 */
static duk_ret_t native_print(duk_context* ctx)
{
    duk_push_lstring(ctx, " ", 1);
    duk_insert(ctx, 0);
    duk_join(ctx, duk_get_top(ctx) - 1);
    PerlIO_stdoutf("%s\n", duk_safe_to_string(ctx, -1));
    return 0; // no return value
}

/*
 * Get JS compatible 'now' timestamp (millisecs since 1970).
 */
static duk_ret_t native_now_ms(duk_context* ctx)
{
    duk_push_number(ctx, (duk_double_t) (now_us() / 1000.0));
    return 1; //  return value at top
}

static void save_stat(pTHX_ Duk* duk, const char* category, const char* name, double value)
{
    STRLEN clen = strlen(category);
    STRLEN nlen = strlen(name);
    HV* data = 0;
    SV** found = hv_fetch(duk->stats, category, clen, 0);
    if (found) {
        SV* ref = SvRV(*found);
        /* value not a valid hashref? bail out */
        if (SvTYPE(ref) != SVt_PVHV) {
            return;
        }
        data = (HV*) ref;
    } else {
        data = newHV();
        SV* ref = newRV_noinc((SV*) data);
        if (hv_store(duk->stats, category, clen, ref, 0)) {
            SvREFCNT_inc(ref);
        }
    }

    SV* pvalue = sv_2mortal(newSVnv(value));
    if (hv_store(data, name, nlen, pvalue, 0)) {
        SvREFCNT_inc(pvalue);
    }
}

static void save_msg(pTHX_ Duk* duk, const char* target, const char* message)
{
    STRLEN tlen = strlen(target);
    STRLEN mlen = strlen(message);
    AV* data = 0;
    int top = 0;
    SV** found = hv_fetch(duk->msgs, target, tlen, 0);
    if (found) {
        SV* ref = SvRV(*found);
        /* value not a valid arrayref? bail out */
        if (SvTYPE(ref) != SVt_PVAV) {
            return;
        }
        data = (AV*) ref;
        top = av_top_index(data);
    } else {
        data = newAV();
        SV* ref = newRV_noinc((SV*) data);
        if (hv_store(duk->msgs, target, tlen, ref, 0)) {
            SvREFCNT_inc(ref);
        }
        top = -1;
    }

    SV* pvalue = sv_2mortal(newSVpvn(message, mlen));
    if (av_store(data, ++top, pvalue)) {
        SvREFCNT_inc(pvalue);
    }
    else {
        croak("Could not store message in target %*.*s\n", (int) tlen, (int) tlen, target);
    }
}

/*
 * This is a generic dispatcher that allows calling any Perl function from JS,
 * after it has been registered under a name in JS.
 */
static duk_ret_t perl_caller(duk_context* ctx)
{
    duk_idx_t j = 0;

    // get actual Perl CV stored as a function property
    duk_push_current_function(ctx);
    if (!duk_get_prop_lstring(ctx, -1, DUK_SLOT_CALLBACK, sizeof(DUK_SLOT_CALLBACK) - 1)) {
        croak("Calling Perl handler for a non-Perl function\n");
    }
    SV* func = (SV*) duk_get_pointer(ctx, -1);
    duk_pop_2(ctx);  /* pop pointer and function */
    if (func == 0) {
        croak("Could not get value for property %s\n", DUK_SLOT_CALLBACK);
    }

    // prepare Perl environment for calling the CV
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    // pass in the stack each of the params we received
    duk_idx_t nargs = duk_get_top(ctx);
    for (j = 0; j < nargs; j++) {
        SV* val = duk_to_perl(aTHX_ ctx, j);
        mXPUSHs(val);
    }

    // call actual Perl CV, passing all params
    PUTBACK;
    call_sv(func, G_SCALAR | G_EVAL);
    SPAGAIN;

    // get returned value from Perl and push its JS equivalent back in
    // duktape's stack
    SV* ret = POPs;
    perl_to_duk(aTHX_ ret, ctx);

    // cleanup and return 1, indicating we are returning a value
    PUTBACK;
    FREETMPS;
    LEAVE;
    return 1;
}

static SV* duk_to_perl(pTHX_ duk_context* ctx, int pos)
{
    SV* ret = &PL_sv_undef; // return undef by default
    switch (duk_get_type(ctx, pos)) {
        case DUK_TYPE_NONE:
        case DUK_TYPE_UNDEFINED:
        case DUK_TYPE_NULL: {
            break;
        }
        case DUK_TYPE_BOOLEAN: {
            duk_bool_t val = duk_get_boolean(ctx, pos);
            ret = newSViv(val);
            break;
        }
        case DUK_TYPE_NUMBER: {
            duk_double_t val = duk_get_number(ctx, pos);
            ret = newSVnv(val);  // JS numbers are always doubles
            break;
        }
        case DUK_TYPE_STRING: {
            duk_size_t clen = 0;
            const char* cstr = duk_get_lstring(ctx, pos, &clen);
            ret = newSVpvn(cstr, clen);
            break;
        }
        case DUK_TYPE_OBJECT: {
            if (duk_is_c_function(ctx, pos)) {
                // if the JS function has a slot with the Perl callback,
                // then we know we created it, so we return that
                if (!duk_get_prop_lstring(ctx, -1, DUK_SLOT_CALLBACK, sizeof(DUK_SLOT_CALLBACK) - 1)) {
                    croak("JS object is an unrecognized function\n");
                }
                ret = (SV*) duk_get_pointer(ctx, -1);
                duk_pop(ctx); // pop function
            } else if (duk_is_array(ctx, pos)) {
                int array_top = duk_get_length(ctx, pos);
                AV* values = newAV();
                int j = 0;
                for (j = 0; j < array_top; ++j) {
                    if (!duk_get_prop_index(ctx, pos, j)) {
                        continue; // index doesn't exist => end of array
                    }
                    SV* nested = sv_2mortal(duk_to_perl(aTHX_ ctx, -1));
                    duk_pop(ctx); // value in current pos
                    if (!nested) {
                        croak("Could not create Perl SV for array\n");
                    }
                    if (av_store(values, j, nested)) {
                        SvREFCNT_inc(nested);
                    }
                }
                ret = newRV_noinc((SV*) values);
            } else if (duk_is_object(ctx, pos)) {
                HV* values = newHV();
                duk_enum(ctx, pos, 0);
                while (duk_next(ctx, -1, 1)) { // get key and value
                    duk_size_t klen = 0;
                    const char* kstr = duk_get_lstring(ctx, -2, &klen);
                    SV* nested = sv_2mortal(duk_to_perl(aTHX_ ctx, -1));
                    duk_pop_2(ctx); // key and value
                    if (!nested) {
                        croak("Could not create Perl SV for hash\n");
                    }
                    if (hv_store(values, kstr, klen, nested, 0)) {
                        SvREFCNT_inc(nested);
                    }
                }
                duk_pop(ctx);  // iterator
                ret = newRV_noinc((SV*) values);
            } else {
                croak("JS object with an unrecognized type\n");
            }
            break;
        }
        case DUK_TYPE_POINTER: {
            ret = (SV*) duk_get_pointer(ctx, -1);
            break;
        }
        case DUK_TYPE_BUFFER: {
            croak("Don't know how to deal with a JS buffer\n");
            break;
        }
        case DUK_TYPE_LIGHTFUNC: {
            croak("Don't know how to deal with a JS lightfunc\n");
            break;
        }
        default:
            croak("Don't know how to deal with an undetermined JS object\n");
            break;
    }
    return ret;
}

static int perl_to_duk(pTHX_ SV* value, duk_context* ctx)
{
    int ret = 1;
    if (!SvOK(value)) {
        duk_push_null(ctx);
    } else if (SvIOK(value)) {
        int val = SvIV(value);
        duk_push_int(ctx, val);
    } else if (SvNOK(value)) {
        double val = SvNV(value);
        duk_push_number(ctx, val);
    } else if (SvPOK(value)) {
        STRLEN vlen = 0;
        const char* vstr = SvPV_const(value, vlen);
        duk_push_lstring(ctx, vstr, vlen);
    } else if (SvROK(value)) {
        SV* ref = SvRV(value);
        if (SvTYPE(ref) == SVt_PVAV) {
            AV* values = (AV*) ref;
            duk_idx_t array_pos = duk_push_array(ctx);
            int array_top = av_top_index(values);
            int count = 0;
            int j = 0;
            for (j = 0; j <= array_top; ++j) { // yes, [0, array_top]
                SV** elem = av_fetch(values, j, 0);
                if (!elem || !*elem) {
                    break; // could not get element
                }
                if (!perl_to_duk(aTHX_ *elem, ctx)) {
                    croak("Could not create JS element for array\n");
                }
                if (!duk_put_prop_index(ctx, array_pos, count)) {
                    croak("Could not push JS element for array\n");
                }
                ++count;
            }
        } else if (SvTYPE(ref) == SVt_PVHV) {
            HV* values = (HV*) ref;
            duk_idx_t hash_pos = duk_push_object(ctx);
            hv_iterinit(values);
            while (1) {
                SV* value = 0;
                I32 klen = 0;
                char* kstr = 0;
                HE* entry = hv_iternext(values);
                if (!entry) {
                    break; // no more hash keys
                }
                kstr = hv_iterkey(entry, &klen);
                if (!kstr || klen < 0) {
                    continue; // invalid key
                }
                value = hv_iterval(values, entry);
                if (!value) {
                    continue; // invalid value
                }
                if (!perl_to_duk(aTHX_ value, ctx)) {
                    croak("Could not create JS element for hash\n");
                }
                if (! duk_put_prop_lstring(ctx, hash_pos, kstr, klen)) {
                    croak("Could not push JS element for hash\n");
                }
            }
        } else if (SvTYPE(ref) == SVt_PVCV) {
            // use perl_caller as generic handler, but store the real callback
            // in a slot, from where we can later retrieve it
            duk_push_c_function(ctx, perl_caller, DUK_VARARGS);
            SV* func = newSVsv(value);
            if (!func) {
                croak("Could not create copy of Perl callback\n");
            }
            duk_push_pointer(ctx, func);
            if (! duk_put_prop_lstring(ctx, -2, DUK_SLOT_CALLBACK, sizeof(DUK_SLOT_CALLBACK) - 1)) {
                croak("Could not associate C dispatcher and Perl callback\n");
            }
        } else {
            croak("Don't know how to deal with an undetermined Perl reference\n");
            ret = 0;
        }
    } else {
        croak("Don't know how to deal with an undetermined Perl object\n");
        ret = 0;
    }
    return ret;
}

static int set_global_or_property(pTHX_ duk_context* ctx, const char* name, SV* value)
{
    if (sv_isobject(value)) {
        SV* obj = newSVsv(value);
        duk_push_pointer(ctx, obj);
    } else if (!perl_to_duk(aTHX_ value, ctx)) {
        return 0;
    }
    int last_dot = -1;
    int len = 0;
    for (; name[len] != '\0'; ++len) {
        if (name[len] == '.') {
            last_dot = len;
        }
    }
    if (last_dot < 0) {
        if (!duk_put_global_lstring(ctx, name, len)) {
            croak("Could not save duk value for %s\n", name);
        }
    } else {
        duk_push_lstring(ctx, name + last_dot + 1, len - last_dot - 1);
        if (duk_peval_lstring(ctx, name, last_dot) != 0) {
            croak("Could not eval JS object %*.*s: %s\n",
                  last_dot, last_dot, name, duk_safe_to_string(ctx, -1));
        }
#if 0
        duk_enum(ctx, -1, 0);
        while (duk_next(ctx, -1, 0)) {
            fprintf(stderr, "KEY [%s]\n", duk_get_string(ctx, -1));
            duk_pop(ctx);  /* pop_key */
        }
#endif
         // Have [value, key, object], need [object, key, value], hence swap
        duk_swap(ctx, -3, -1);
        duk_put_prop(ctx, -3);
        duk_pop(ctx); // pop object
    }
    return 1;
}

static int session_dtor(pTHX_ SV* sv, MAGIC* mg)
{
    UNUSED_ARG(sv);
    Duk* duk = (Duk*) mg->mg_ptr;
    duk_destroy_heap(duk->ctx);
    return 0;
}

static void duk_fatal_error_handler(void* data, const char* msg)
{
    UNUSED_ARG(data);
    dTHX;
    PerlIO_printf(PerlIO_stderr(), "duktape fatal error, aborting: %s\n", msg ? msg : "*NONE*");
    abort();
}

static int register_native_functions(Duk* duk)
{
    static struct Data {
        const char* name;
        duk_c_function func;
    } data[] = {
        { "print"       , native_print  },
        { "timestamp_ms", native_now_ms },
    };
    duk_context* ctx = duk->ctx;
    int n = sizeof(data) / sizeof(data[0]);
    int j = 0;
    for (j = 0; j < n; ++j) {
        duk_push_c_function(ctx, data[j].func, DUK_VARARGS);
        if (!duk_put_global_string(ctx, data[j].name)) {
            croak("Could not register native function %s\n", data[j].name);
        }
    }
    return n;
}
static int print_console_messages(duk_uint_t flags, void* data,
                                  const char* fmt, va_list ap)
{
    dTHX;

    UNUSED_ARG(data);
    PerlIO* fp = (flags & DUK_CONSOLE_TO_STDERR) ? PerlIO_stderr() : PerlIO_stdout();
    int ret = PerlIO_vprintf(fp, fmt, ap);
    if (flags & DUK_CONSOLE_FLUSH) {
        PerlIO_flush(fp);
    }
    return ret;
}


static int save_console_messages(duk_uint_t flags, void* data,
                                 const char* fmt, va_list ap)
{
    dTHX;
    Duk* duk = (Duk*) data;
    char message[1024];
    int ret = vsprintf(message, fmt, ap);
    const char* target = (flags & DUK_CONSOLE_TO_STDERR) ? "stderr" : "stdout";

    save_msg(aTHX_ duk, target, message);
    return ret;
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

    register_native_functions(duk);

    // Register our event loop dispatcher, otherwise calls to
    // dispatch_function_in_event_loop will not work.
    eventloop_register(duk->ctx);

    // initialize console object
    duk_console_init(duk->ctx, DUK_CONSOLE_PROXY_WRAPPER | DUK_CONSOLE_FLUSH);

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

    if (duk->flags & DUK_OPT_FLAG_SAVE_MESSAGES) {
        duk_console_register_handler(save_console_messages, duk);
    }
    else {
        duk_console_register_handler(print_console_messages, duk);
    }

    return duk;
}

static void stats_start(pTHX_ Duk* duk, Stats* stats)
{
    if (!(duk->flags & DUK_OPT_FLAG_GATHER_STATS)) {
        return;
    }
    stats->t0 = now_us();
    stats->m0 = total_memory_pages() * duk->pagesize;
}

static void stats_stop(pTHX_ Duk* duk, Stats* stats, const char* name)
{
    if (!(duk->flags & DUK_OPT_FLAG_GATHER_STATS)) {
        return;
    }
    stats->t1 = now_us();
    stats->m1 = total_memory_pages() * duk->pagesize;

    save_stat(aTHX_ duk, name, "elapsed_us", stats->t1 - stats->t0);
    save_stat(aTHX_ duk, name, "memory_bytes", stats->m1 - stats->m0);
}

static int run_function_in_event_loop(Duk* duk, const char* func)
{
    duk_context* ctx = duk->ctx;

    // Start a zero timer which will call our function from the event loop.
    duk_int_t rc = 0;
    char js[256];
    int len = sprintf(js, "setTimeout(function() { %s(); }, 0);", func);
    rc = duk_peval_lstring(ctx, js, len);
    if (rc != DUK_EXEC_SUCCESS) {
        croak("Could not eval JS event loop dispatcher %*.*s: %d - %s\n",
              len, len, js, rc, duk_safe_to_string(ctx, -1));
    }
    duk_pop(ctx);

    // Launch eventloop; this call only returns after the eventloop terminates.
    rc = duk_safe_call(ctx, eventloop_run, duk, 0 /*nargs*/, 1 /*nrets*/);
    if (rc != DUK_EXEC_SUCCESS) {
        croak("JS event loop run failed: %d - %s\n",
              rc, duk_safe_to_string(ctx, -1));
    }
    duk_pop(ctx);

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

HV*
get_msgs(Duk* duk)
  CODE:
    RETVAL = duk->msgs;
  OUTPUT: RETVAL

SV*
get(Duk* duk, const char* name)
  PREINIT:
    duk_context* ctx = 0;
    Stats stats;
  CODE:
    ctx = duk->ctx;
    RETVAL = &PL_sv_undef; // return undef by default
    stats_start(aTHX_ duk, &stats);
    if (duk_get_global_string(ctx, name)) {
        RETVAL = duk_to_perl(aTHX_ ctx, -1);
        duk_pop(ctx);
    }
    stats_stop(aTHX_ duk, &stats, "get");
  OUTPUT: RETVAL

int
set(Duk* duk, const char* name, SV* value)
  PREINIT:
    duk_context* ctx = 0;
    Stats stats;
  CODE:
    ctx = duk->ctx;
    stats_start(aTHX_ duk, &stats);
    RETVAL = set_global_or_property(aTHX_ ctx, name, value);
    stats_stop(aTHX_ duk, &stats, "set");
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

    stats_start(aTHX_ duk, &stats);
    if (!file) {
        rc = duk_pcompile_string(ctx, flags, js);
    }
    else {
        duk_push_string(ctx, file);
        rc = duk_pcompile_string_filename(ctx, flags, js);
    }
    stats_stop(aTHX_ duk, &stats, "compile");

    if (rc != DUK_EXEC_SUCCESS) {
        croak("JS could not compile code: %s\n", duk_safe_to_string(ctx, -1));
    }

    stats_start(aTHX_ duk, &stats);
    rc = duk_pcall(ctx, 0);
    stats_stop(aTHX_ duk, &stats, "run");

    if (rc != DUK_EXEC_SUCCESS) {
        if (duk_is_error(ctx, -1)) {
            /* Accessing .stack might cause an error to be thrown, so wrap this
             * access in a duk_safe_call() if it matters.
             */
            duk_get_prop_string(ctx, -1, "stack");
            duk_console_log(DUK_CONSOLE_FLUSH | DUK_CONSOLE_TO_STDERR,
                            "error: %s\n", duk_safe_to_string(ctx, -1));
            duk_pop(ctx);
        } else {
            /* Non-Error value, coerce safely to string. */
            duk_console_log(DUK_CONSOLE_FLUSH | DUK_CONSOLE_TO_STDERR,
                            "error: %s\n", duk_safe_to_string(ctx, -1));
        }
    }

    RETVAL = duk_to_perl(aTHX_ ctx, -1);
    duk_pop(ctx);
  OUTPUT: RETVAL

SV*
dispatch_function_in_event_loop(Duk* duk, const char* func)
  PREINIT:
    Stats stats;
  CODE:
    stats_start(aTHX_ duk, &stats);
    RETVAL = newSViv(run_function_in_event_loop(duk, func));
    stats_stop(aTHX_ duk, &stats, "dispatch");
  OUTPUT: RETVAL
