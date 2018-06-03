#include "pl_duk.h"

#define PL_GC_RUNS                2

static duk_ret_t perl_caller(duk_context* ctx);

SV* pl_duk_to_perl(pTHX_ duk_context* ctx, int pos)
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
            SvUTF8_on(ret); // yes, always
            break;
        }
        case DUK_TYPE_OBJECT: {
            if (duk_is_c_function(ctx, pos)) {
                // if the JS function has a slot with the Perl callback,
                // then we know we created it, so we return that
                if (duk_get_prop_lstring(ctx, pos, PL_SLOT_GENERIC_CALLBACK, sizeof(PL_SLOT_GENERIC_CALLBACK) - 1)) {
                    ret = (SV*) duk_get_pointer(ctx, pos);
                }
                duk_pop(ctx); // pop function / null pointer
            } else if (duk_is_array(ctx, pos)) {
                int array_top = duk_get_length(ctx, pos);
                AV* values = newAV();
                int j = 0;
                for (j = 0; j < array_top; ++j) {
                    if (!duk_get_prop_index(ctx, pos, j)) {
                        continue; // index doesn't exist => end of array
                    }
                    SV* nested = sv_2mortal(pl_duk_to_perl(aTHX_ ctx, -1));
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
                    SV* nested = sv_2mortal(pl_duk_to_perl(aTHX_ ctx, -1));
                    duk_pop_2(ctx); // key and value
                    if (!nested) {
                        croak("Could not create Perl SV for hash\n");
                    }
                    if (hv_store(values, kstr, -klen, nested, 0)) {
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

int pl_perl_to_duk(pTHX_ SV* value, duk_context* ctx)
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
                if (!pl_perl_to_duk(aTHX_ *elem, ctx)) {
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
                SV* key = 0;
                SV* value = 0;
                char* kstr = 0;
                STRLEN klen = 0;
                HE* entry = hv_iternext(values);
                if (!entry) {
                    break; // no more hash keys
                }
                key = hv_iterkeysv(entry);
                if (!key) {
                    continue; // invalid key
                }
                SvUTF8_on(key); // yes, always
                kstr = SvPV(key, klen);
                if (!kstr) {
                    continue; // invalid key
                }

                value = hv_iterval(values, entry);
                if (!value) {
                    continue; // invalid value
                }
                SvUTF8_on(value); // yes, always

                if (!pl_perl_to_duk(aTHX_ value, ctx)) {
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
            if (! duk_put_prop_lstring(ctx, -2, PL_SLOT_GENERIC_CALLBACK, sizeof(PL_SLOT_GENERIC_CALLBACK) - 1)) {
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
            label = "object";
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

    // prepare Perl environment for calling the CV
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    // pass in the stack each of the params we received
    duk_idx_t nargs = duk_get_top(ctx);
    for (j = 0; j < nargs; j++) {
        SV* val = pl_duk_to_perl(aTHX_ ctx, j);
        mXPUSHs(val);
    }

    // call actual Perl CV, passing all params
    PUTBACK;
    call_sv(func, G_SCALAR | G_EVAL);
    SPAGAIN;

    // get returned value from Perl and push its JS equivalent back in
    // duktape's stack
    SV* ret = POPs;
    pl_perl_to_duk(aTHX_ ret, ctx);

    // cleanup and return 1, indicating we are returning a value
    PUTBACK;
    FREETMPS;
    LEAVE;
    return 1;
}

static int find_last_dot(const char* name, int* len)
{
    int last_dot = -1;
    *len = 0;
    for (; name[*len] != '\0'; ++*len) {
        if (name[*len] == '.') {
            last_dot = *len;
        }
    }
    return last_dot;
}

static int find_global_or_property(duk_context* ctx, const char* name)
{
    int ret = 0;
    int len = 0;
    int last_dot = find_last_dot(name, &len);
    if (last_dot < 0) {
        if (duk_get_global_string(ctx, name)) {
            ret = 1;
        }
    } else {
        if (duk_peval_lstring(ctx, name, last_dot) == 0) {
            if (duk_get_prop_lstring(ctx, -1, name + last_dot + 1, len - last_dot - 1)) {
                ret = 1;
                duk_swap(ctx, -2, -1);
                duk_pop(ctx); // pop object, leave value
            } else {
                duk_pop_2(ctx); // pop object and value (which was undef)
            }
        } else {
        }
    }
    return ret;
}

SV* pl_exists_global_or_property(pTHX_ duk_context* ctx, const char* name)
{
    SV* ret = &PL_sv_no; // return false by default
    if (find_global_or_property(ctx, name)) {
        ret = &PL_sv_yes;
        duk_pop(ctx); // pop value
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
        duk_pop(ctx); // pop value
    }
    ret = newSVpv(cstr, clen);
    return ret;
}

SV* pl_instanceof_global_or_property(pTHX_ duk_context* ctx, const char* object, const char* class)
{
    SV* ret = &PL_sv_no; // return false by default
    if (find_global_or_property(ctx, object)) {
        if (find_global_or_property(ctx, class)) {
            if (duk_instanceof(ctx, -2, -1)) {
                ret = &PL_sv_yes;
            }
            duk_pop(ctx);
        }
        duk_pop(ctx);
    }
    return ret;
}

SV* pl_get_global_or_property(pTHX_ duk_context* ctx, const char* name)
{
    SV* ret = &PL_sv_undef; // return undef by default
    if (find_global_or_property(ctx, name)) {
        ret = pl_duk_to_perl(aTHX_ ctx, -1);
    }
    return ret;
}

int pl_set_global_or_property(pTHX_ duk_context* ctx, const char* name, SV* value)
{
    if (sv_isobject(value)) {
        SV* obj = newSVsv(value);
        duk_push_pointer(ctx, obj);
    } else if (!pl_perl_to_duk(aTHX_ value, ctx)) {
        return 0;
    }
    int len = 0;
    int last_dot = find_last_dot(name, &len);
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
        // Have [value, key, object], need [object, key, value], hence swap
        duk_swap(ctx, -3, -1);
        duk_put_prop(ctx, -3);
        duk_pop(ctx); // pop object
    }
    return 1;
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
        // DUK_GC_COMPACT: Force object property table compaction
        duk_gc(ctx, DUK_GC_COMPACT);
    }
    return PL_GC_RUNS;
}

static duk_ret_t perl_caller(duk_context* ctx)
{
    // get actual Perl CV stored as a function property
    duk_push_current_function(ctx);
    if (!duk_get_prop_lstring(ctx, -1, PL_SLOT_GENERIC_CALLBACK, sizeof(PL_SLOT_GENERIC_CALLBACK) - 1)) {
        croak("Calling Perl handler for a non-Perl function\n");
    }

    SV* func = (SV*) duk_get_pointer(ctx, -1);
    duk_pop_2(ctx);  /* pop pointer and function */
    if (func == 0) {
        croak("Could not get value for property %s\n", PL_SLOT_GENERIC_CALLBACK);
    }

    return pl_call_perl_sv(ctx, func);
}
