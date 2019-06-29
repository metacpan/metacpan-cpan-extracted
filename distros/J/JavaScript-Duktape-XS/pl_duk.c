#include "duk_console.h"
#include "c_eventloop.h"
#include "pl_stats.h"
#include "pl_util.h"
#include "pl_duk.h"

#define NEED_sv_2pv_flags
#include "ppport.h"

#define PL_GC_RUNS 2

#define PL_JSON_CLASS                         "JSON::PP"
#define PL_JSON_BOOLEAN_CLASS  PL_JSON_CLASS  "::" "Boolean"
#define PL_JSON_BOOLEAN_TRUE   PL_JSON_CLASS  "::" "true"
#define PL_JSON_BOOLEAN_FALSE  PL_JSON_CLASS  "::" "false"

static duk_ret_t perl_caller(duk_context* ctx);

static HV* seen;

static SV* pl_duk_to_perl_impl(pTHX_ duk_context* ctx, int pos, HV* seen)
{
    SV* ret = &PL_sv_undef; /* return undef by default */
    switch (duk_get_type(ctx, pos)) {
        case DUK_TYPE_NONE:
        case DUK_TYPE_UNDEFINED:
        case DUK_TYPE_NULL: {
            break;
        }
        case DUK_TYPE_BOOLEAN: {
            duk_bool_t val = duk_get_boolean(ctx, pos);
            ret = get_sv(val ? PL_JSON_BOOLEAN_TRUE : PL_JSON_BOOLEAN_FALSE, 0);
            SvREFCNT_inc(ret);
            break;
        }
        case DUK_TYPE_NUMBER: {
            duk_double_t val = duk_get_number(ctx, pos);
            ret = newSVnv(val);  /* JS numbers are always doubles */
            break;
        }
        case DUK_TYPE_STRING: {
            duk_size_t clen = 0;
            const char* cstr = duk_get_lstring(ctx, pos, &clen);
            ret = newSVpvn(cstr, clen);
            SvUTF8_on(ret); /* yes, always */
            break;
        }
        case DUK_TYPE_OBJECT: {
            if (duk_is_c_function(ctx, pos)) {
                /* if the JS function has a slot with the Perl callback, */
                /* then we know we created it, so we return that */
                if (duk_get_prop_lstring(ctx, pos, PL_SLOT_GENERIC_CALLBACK, sizeof(PL_SLOT_GENERIC_CALLBACK) - 1)) {
                    ret = (SV*) duk_get_pointer(ctx, pos);
                }
                duk_pop(ctx); /* pop function / null pointer */
            } else if (duk_is_array(ctx, pos)) {
                void* ptr = duk_get_heapptr(ctx, pos);
                char kstr[100];
                int klen = sprintf(kstr, "%p", ptr);
                SV** answer = hv_fetch(seen, kstr, klen, 0);
                if (answer) {
                    /* TODO: weaken reference? */
                    ret = newRV_inc(*answer);
                } else {
                    int array_top = 0;
                    int j = 0;
                    AV* values_array = newAV();
                    SV* values = sv_2mortal((SV*) values_array);
                    if (hv_store(seen, kstr, klen, values, 0)) {
                        SvREFCNT_inc(values);
                    }
                    ret = newRV_inc(values);

                    array_top = duk_get_length(ctx, pos);
                    for (j = 0; j < array_top; ++j) {
                        SV* nested = 0;
                        if (!duk_get_prop_index(ctx, pos, j)) {
                            continue; /* index doesn't exist => end of array */
                        }
                        nested = sv_2mortal(pl_duk_to_perl_impl(aTHX_ ctx, -1, seen));
                        duk_pop(ctx); /* value in current pos */
                        if (!nested) {
                            croak("Could not create Perl SV for array\n");
                        }
                        if (av_store(values_array, j, nested)) {
                            SvREFCNT_inc(nested);
                        }
                    }
                }
            } else { /* if (duk_is_object(ctx, pos)) { */
                void* ptr = duk_get_heapptr(ctx, pos);
                char kstr[100];
                int klen = sprintf(kstr, "%p", ptr);
                SV** answer = hv_fetch(seen, kstr, klen, 0);
                if (answer) {
                    /* TODO: weaken reference? */
                    ret = newRV_inc(*answer);
                } else {
                    HV* values_hash = newHV();
                    SV* values = sv_2mortal((SV*) values_hash);
                    if (hv_store(seen, kstr, klen, values, 0)) {
                        SvREFCNT_inc(values);
                    }
                    ret = newRV_inc(values);

                    duk_enum(ctx, pos, 0);
                    while (duk_next(ctx, -1, 1)) { /* get key and value */
                        duk_size_t klen = 0;
                        const char* kstr = duk_get_lstring(ctx, -2, &klen);
                        SV* nested = sv_2mortal(pl_duk_to_perl_impl(aTHX_ ctx, -1, seen));
                        duk_pop_2(ctx); /* key and value */
                        if (!nested) {
                            croak("Could not create Perl SV for hash\n");
                        }
                        if (hv_store(values_hash, kstr, -klen, nested, 0)) {
                            SvREFCNT_inc(nested);
                        }
                    }
                    duk_pop(ctx);  /* iterator */
                }
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

static int pl_perl_to_duk_impl(pTHX_ SV* value, duk_context* ctx, HV* seen, int ref)
{
    int ret = 1;
    if (SvTYPE(value) >= SVt_PVMG) {
        /* any Perl SV that has magic (think tied objects) needs to have that
         * magic actually called to retrieve the value */
        mg_get(value);
    }
    if (!SvOK(value)) {
        duk_push_null(ctx);
    } else if (sv_isa(value, PL_JSON_BOOLEAN_CLASS)) {
        int val = SvTRUE(value);
        duk_push_boolean(ctx, val);
    } else if (SvPOK(value)) {
        STRLEN vlen = 0;
        const char* vstr = SvPV_const(value, vlen);
        duk_push_lstring(ctx, vstr, vlen);
    } else if (SvIOK(value)) {
        long val = SvIV(value);
        if (ref && (val == 0 || val == 1)) {
            duk_push_boolean(ctx, val);
        } else {
            duk_push_number(ctx, (duk_double_t) val);
        }
    } else if (SvNOK(value)) {
        double val = SvNV(value);
        duk_push_number(ctx, (duk_double_t) val);
    } else if (SvROK(value)) {
        SV* ref = SvRV(value);
        int type = SvTYPE(ref);
        if (type < SVt_PVAV) {
            if (!pl_perl_to_duk_impl(aTHX_ ref, ctx, seen, 1)) {
                croak("Could not create JS element for reference\n");
            }
        } else if (type == SVt_PVAV) {
            AV* values = (AV*) ref;
            char kstr[100];
            int klen = sprintf(kstr, "%p", values);
            SV** answer = hv_fetch(seen, kstr, klen, 0);
            if (answer) {
                void* ptr = (void*) SvUV(*answer);
                duk_push_heapptr(ctx, ptr);
            } else {
                int array_top = 0;
                int count = 0;
                int j = 0;
                duk_idx_t array_pos = duk_push_array(ctx);
                void* ptr = duk_get_heapptr(ctx, array_pos);
                SV* uptr = sv_2mortal(newSVuv(PTR2UV(ptr)));
                if (hv_store(seen, kstr, klen, uptr, 0)) {
                    SvREFCNT_inc(uptr);
                }

                array_top = av_len(values);
                for (j = 0; j <= array_top; ++j) { /* yes, [0, array_top] */
                    SV** elem = av_fetch(values, j, 0);
                    if (!elem || !*elem) {
                        break; /* could not get element */
                    }
                    if (!pl_perl_to_duk_impl(aTHX_ *elem, ctx, seen, 0)) {
                        croak("Could not create JS element for array\n");
                    }
                    if (!duk_put_prop_index(ctx, array_pos, count)) {
                        croak("Could not push JS element for array\n");
                    }
                    ++count;
                }
            }
        } else if (type == SVt_PVHV) {
            HV* values = (HV*) ref;
            char kstr[100];
            int klen = sprintf(kstr, "%p", values);
            SV** answer = hv_fetch(seen, kstr, klen, 0);
            if (answer) {
                void* ptr = (void*) SvUV(*answer);
                duk_push_heapptr(ctx, ptr);
            } else {
                duk_idx_t hash_pos = duk_push_object(ctx);
                void* ptr = duk_get_heapptr(ctx, hash_pos);
                SV* uptr = sv_2mortal(newSVuv(PTR2UV(ptr)));
                if (hv_store(seen, kstr, klen, uptr, 0)) {
                    SvREFCNT_inc(uptr);
                }

                hv_iterinit(values);
                while (1) {
                    SV* key = 0;
                    SV* value = 0;
                    char* kstr = 0;
                    STRLEN klen = 0;
                    HE* entry = hv_iternext(values);
                    if (!entry) {
                        break; /* no more hash keys */
                    }
                    key = hv_iterkeysv(entry);
                    if (!key) {
                        continue; /* invalid key */
                    }
                    SvUTF8_on(key); /* yes, always */
                    kstr = SvPV(key, klen);
                    if (!kstr) {
                        continue; /* invalid key */
                    }

                    value = hv_iterval(values, entry);
                    if (!value) {
                        continue; /* invalid value */
                    }
                    SvUTF8_on(value); /* yes, always */

                    if (!pl_perl_to_duk_impl(aTHX_ value, ctx, seen, 0)) {
                        croak("Could not create JS element for hash\n");
                    }
                    if (! duk_put_prop_lstring(ctx, hash_pos, kstr, klen)) {
                        croak("Could not push JS element for hash\n");
                    }
                }
            }
        } else if (type == SVt_PVCV) {
            /* use perl_caller as generic handler, but store the real callback */
            /* in a slot, from where we can later retrieve it */
            SV* func = newSVsv(value);
            duk_push_c_function(ctx, perl_caller, DUK_VARARGS);
            if (!func) {
                croak("Could not create copy of Perl callback\n");
            }
            duk_push_pointer(ctx, func);
            if (! duk_put_prop_lstring(ctx, -2, PL_SLOT_GENERIC_CALLBACK, sizeof(PL_SLOT_GENERIC_CALLBACK) - 1)) {
                croak("Could not associate C dispatcher and Perl callback\n");
            }
        } else {
            croak("Don't know how to deal with an undetermined Perl reference (type: %d)\n", type);
            ret = 0;
        }
    } else {
        croak("Don't know how to deal with an undetermined Perl object\n");
        ret = 0;
    }
    return ret;
}

SV* pl_duk_to_perl(pTHX_ duk_context* ctx, int pos)
{
    if (!seen) {
        seen = newHV();
    }
    SV* ret = pl_duk_to_perl_impl(aTHX_ ctx, pos, seen);
    hv_clear(seen);
    return ret;
}

int pl_perl_to_duk(pTHX_ SV* value, duk_context* ctx)
{
    if (!seen) {
        seen = newHV();
    }
    int ret = pl_perl_to_duk_impl(aTHX_ value, ctx, seen, 0);
    hv_clear(seen);
    return ret;
}

static const char* get_typeof(duk_context* ctx, int pos)
{
    const char* label = "undefined";
    switch (duk_get_type(ctx, pos)) {
        case DUK_TYPE_NONE:
        case DUK_TYPE_UNDEFINED:
            break;
        case DUK_TYPE_NULL:
            label = "null";
            break;
        case DUK_TYPE_BOOLEAN:
            label = "boolean";
            break;
        case DUK_TYPE_NUMBER:
            label = "number";
            break;
        case DUK_TYPE_STRING:
            label = "string";
            break;
        case DUK_TYPE_OBJECT:
            if (duk_is_array(ctx, pos)) {
                label = "array";
            }
            else if (duk_is_symbol(ctx, pos)) {
                label = "symbol";
            }
            else if (duk_is_pointer(ctx, pos)) {
                label = "pointer";
            }
            else if (duk_is_function(ctx, pos)) {
                label = "function";
            }
            else if (duk_is_c_function(ctx, pos)) {
                label = "c_function";
            }
            else if (duk_is_thread(ctx, pos)) {
                label = "thread";
            }
            else {
                label = "object";
            }
            break;
        case DUK_TYPE_POINTER:
            label = "pointer";
            break;
        case DUK_TYPE_BUFFER:
            label = "buffer";
            break;
        case DUK_TYPE_LIGHTFUNC:
            label = "lightfunc";
            break;
        default:
            croak("Don't know how to deal with an undetermined JS object\n");
            break;
    }
    return label;
}

int pl_call_perl_sv(duk_context* ctx, SV* func)
{
    duk_idx_t j = 0;
    duk_idx_t nargs = 0;
    SV* ret = 0;
    SV *err_tmp;

    /* prepare Perl environment for calling the CV */
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    /* pass in the stack each of the params we received */
    nargs = duk_get_top(ctx);
    for (j = 0; j < nargs; j++) {
        SV* val = pl_duk_to_perl(aTHX_ ctx, j);
        mXPUSHs(val);
    }

    /* you would think we need to pop off the args from duktape's stack, but
     * they get popped off somewhere else, probably by duktape itself */

    /* call actual Perl CV, passing all params */
    PUTBACK;
    call_sv(func, G_SCALAR | G_EVAL);
    SPAGAIN;

    err_tmp = ERRSV;
    if (SvTRUE(err_tmp)) {
        croak("Perl sub died with error: %s", SvPV_nolen(err_tmp));
    }

    /* get returned value from Perl and push its JS equivalent back in */
    /* duktape's stack */
    ret = POPs;
    pl_perl_to_duk(aTHX_ ret, ctx);

    /* cleanup and return 1, indicating we are returning a value */
    PUTBACK;
    FREETMPS;
    LEAVE;
    return 1;
}

static int find_last_dot(const char* name, int* len)
{
    int last_dot = -1;
    int l = 0;
    for (; name[l] != '\0'; ++l) {
        if (name[l] == '.') {
            last_dot = l;
        }
    }
    *len = l;
    return last_dot;
}

static int find_global_or_property(duk_context* ctx, const char* name)
{
    int ret = 0;
    int len = 0;
    int last_dot = find_last_dot(name, &len);
    if (last_dot < 0) {
        if (duk_get_global_string(ctx, name)) {
            /* that leaves global value in stack, for caller to deal with */
            ret = 1;
        } else {
            duk_pop(ctx); /* pop value (which was undef) */
        }
    } else {
        if (duk_peval_lstring(ctx, name, last_dot) == 0) {
            /* that leaves object containing value in stack */
            if (duk_get_prop_lstring(ctx, -1, name + last_dot + 1, len - last_dot - 1)) {
                /* that leaves value in stack */
                ret = 1;

                /* have [object, value], need just [value] */
                duk_swap(ctx, -2, -1); /* now have [value, object] */
                duk_pop(ctx); /* pop object, leave canoli... er, value */
            } else {
                duk_pop_2(ctx); /* pop object and value (which was undef) */
            }
        } else {
            duk_pop(ctx); /* pop error */
        }
    }
    return ret;
}

SV* pl_exists_global_or_property(pTHX_ duk_context* ctx, const char* name)
{
    SV* ret = &PL_sv_no; /* return false by default */
    if (find_global_or_property(ctx, name)) {
        ret = &PL_sv_yes;
        duk_pop(ctx); /* pop value */
    }
    return ret;
}

SV* pl_typeof_global_or_property(pTHX_ duk_context* ctx, const char* name)
{
    const char* cstr = "undefined";
    STRLEN clen = 0;
    SV* ret = 0;
    if (find_global_or_property(ctx, name)) {
        cstr = get_typeof(ctx, -1);
        duk_pop(ctx); /* pop value */
    }
    ret = newSVpv(cstr, clen);
    return ret;
}

SV* pl_instanceof_global_or_property(pTHX_ duk_context* ctx, const char* object, const char* class)
{
    SV* ret = &PL_sv_no; /* return false by default */
    if (find_global_or_property(ctx, object)) {
        if (find_global_or_property(ctx, class)) {
            if (duk_instanceof(ctx, -2, -1)) {
                ret = &PL_sv_yes;
            }
            duk_pop(ctx); /* pop class */
        }
        duk_pop(ctx); /* pop value */
    }
    return ret;
}

SV* pl_get_global_or_property(pTHX_ duk_context* ctx, const char* name)
{
    SV* ret = &PL_sv_undef; /* return undef by default */
    if (find_global_or_property(ctx, name)) {
        /* Convert found value to Perl and pop it off the stack */
        ret = pl_duk_to_perl(aTHX_ ctx, -1);
        duk_pop(ctx);
    }
    return ret;
}

int pl_set_global_or_property(pTHX_ duk_context* ctx, const char* name, SV* value)
{
    int len = 0;
    int last_dot = 0;

    /* fprintf(stderr, "STACK: %ld\n", (long) duk_get_top(ctx)); */

    if (pl_perl_to_duk(aTHX_ value, ctx)) {
        /* that put value in stack */
    } else {
        return 0;
    }
    last_dot = find_last_dot(name, &len);
    if (last_dot < 0) {
        if (duk_put_global_lstring(ctx, name, len)) {
            /* that consumed value that was in stack */
        } else {
            duk_pop(ctx); /* pop value */
            croak("Could not save duk value for %s\n", name);
        }
    } else {
        duk_push_lstring(ctx, name + last_dot + 1, len - last_dot - 1);
        /* that put key in stack */
        if (duk_peval_lstring(ctx, name, last_dot) == 0) {
            /* that put object in stack */
        } else {
            duk_pop_2(ctx);  /* object (error) and value */
            croak("Could not eval JS object %*.*s: %s\n",
                  last_dot, last_dot, name, duk_safe_to_string(ctx, -1));
        }
        /* Have [value, key, object], need [object, key, value], hence swap */
        duk_swap(ctx, -3, -1);

        duk_put_prop(ctx, -3); /* consumes key and value */
        duk_pop(ctx); /* pop object */
    }
    return 1;
}

int pl_del_global_or_property(pTHX_ duk_context* ctx, const char* name)
{
    int len = 0;
    int last_dot = find_last_dot(name, &len);
    if (last_dot < 0) {
        duk_push_global_object(ctx);
        duk_del_prop_lstring(ctx, -1, name, len);
    } else {
        if (duk_peval_lstring(ctx, name, last_dot) == 0) {
            /* that put object in stack */
        } else {
            duk_pop(ctx);  /* object (error) */
            croak("Could not eval JS object %*.*s: %s\n",
                  last_dot, last_dot, name, duk_safe_to_string(ctx, -1));
        }
        duk_del_prop_lstring(ctx, -1, name + last_dot + 1, len - last_dot - 1);
    }
    duk_pop(ctx); /* pop global or property object */
    return 1;
}

SV* pl_eval(pTHX_ Duk* duk, const char* js, const char* file)
{
    SV* ret = &PL_sv_undef; /* return undef by default */
    duk_context* ctx = duk->ctx;
    duk_int_t rc = 0;

    do {
        Stats stats;
        duk_uint_t flags = 0;

        /* flags |= DUK_COMPILE_STRICT; */

        pl_stats_start(aTHX_ duk, &stats);
        if (!file) {
            /* Compile the requested code without a reference to the file where it lives */
            rc = duk_pcompile_string(ctx, flags, js);
        }
        else {
            /* Compile the requested code referencing the file where it lives */
            duk_push_string(ctx, file);
            rc = duk_pcompile_string_filename(ctx, flags, js);
        }
        pl_stats_stop(aTHX_ duk, &stats, "compile");
        if (rc != DUK_EXEC_SUCCESS) {
            /* Only for an error this early we print something out and bail out */
            duk_console_log(DUK_CONSOLE_FLUSH | DUK_CONSOLE_TO_STDERR,
                            "JS could not compile code: %s\n",
                            duk_safe_to_string(ctx, -1));
            break;
        }

        /* Run the requested code and check for possible errors*/
        pl_stats_start(aTHX_ duk, &stats);
        rc = duk_pcall(ctx, 0);
        pl_stats_stop(aTHX_ duk, &stats, "run");
        check_duktape_call_for_errors(rc, ctx);

        /* Convert returned value to Perl and pop it off the stack */
        ret = pl_duk_to_perl(aTHX_ ctx, -1);
        duk_pop(ctx);

        /* Launch eventloop and check for errors again. */
        /* This call only returns after the eventloop terminates. */
        rc = duk_safe_call(ctx, eventloop_run, duk, 0 /*nargs*/, 1 /*nrets*/);
        check_duktape_call_for_errors(rc, ctx);

        duk_pop(ctx); /* pop return value from duk_safe_call */
    } while (0);

    return ret;
}

int pl_run_gc(Duk* duk)
{
    int j = 0;

    /*
     * From docs in http://duktape.org/api.html#duk_gc
     *
     * You may want to call this function twice to ensure even objects with
     * finalizers are collected.  Currently it takes two mark-and-sweep rounds
     * to collect such objects.  First round marks the object as finalizable
     * and runs the finalizer.  Second round ensures the object is still
     * unreachable after finalization and then frees the object.
     */
    duk_context* ctx = duk->ctx;
    for (j = 0; j < PL_GC_RUNS; ++j) {
        /* DUK_GC_COMPACT: Force object property table compaction */
        duk_gc(ctx, DUK_GC_COMPACT);
    }
    return PL_GC_RUNS;
}

SV* pl_global_objects(pTHX_ duk_context* ctx)
{
    int count = 0;
    AV* values = newAV();

    duk_push_global_object(ctx);
    duk_enum(ctx, -1, 0);
    while (duk_next(ctx, -1, 0)) { /* get keys only */
        duk_size_t klen = 0;
        const char* kstr = duk_get_lstring(ctx, -1, &klen);
        SV* name = sv_2mortal(newSVpvn(kstr, klen));
        SvUTF8_on(name); /* yes, always */
        if (av_store(values, count, name)) {
            SvREFCNT_inc(name);
            ++count;
        }
        duk_pop(ctx); /* key */
    }
    duk_pop_2(ctx);  /* iterator and global object */
    return newRV_inc((SV*) values);
}

static duk_ret_t perl_caller(duk_context* ctx)
{
    SV* func = 0;

    /* get actual Perl CV stored as a function property */
    duk_push_current_function(ctx);
    if (!duk_get_prop_lstring(ctx, -1, PL_SLOT_GENERIC_CALLBACK, sizeof(PL_SLOT_GENERIC_CALLBACK) - 1)) {
        croak("Calling Perl handler for a non-Perl function\n");
    }

    func = (SV*) duk_get_pointer(ctx, -1);
    duk_pop_2(ctx);  /* pop pointer and function */
    if (func == 0) {
        croak("Could not get value for property %s\n", PL_SLOT_GENERIC_CALLBACK);
    }

    return pl_call_perl_sv(ctx, func);
}
