#include <map>
#include "pl_stats.h"
#include "pl_console.h"
#include "pl_v8.h"

#define NEED_sv_2pv_flags_GLOBAL
#include "ppport.h"

#define PL_GC_RUNS 2

#define PL_JSON_CLASS                         "JSON::PP"
#define PL_JSON_BOOLEAN_CLASS  PL_JSON_CLASS  "::" "Boolean"
#define PL_JSON_BOOLEAN_TRUE   PL_JSON_CLASS  "::" "true"
#define PL_JSON_BOOLEAN_FALSE  PL_JSON_CLASS  "::" "false"

using namespace v8;

/*
 * A way to compare Local<Object> instances via operator<, which is what a
 * std::map requires for its keys.
 *
 * Notice that we define operator(), NOT operator<.
 */
struct LocalObjectCompare
{
    bool operator() (const Local<Object>& lhs, const Local<Object>& rhs) const
    {
        if (lhs == rhs) return 0;
        return *lhs < *rhs;
    }
};

/* maps from Perl to JavaScript -- SV* to Local<Object> */
typedef std::map<void*, Local<Object>> MapP2J;

/* maps from JavaScript to Perl -- Object* to SV* */
typedef std::map<Local<Object>, void*, LocalObjectCompare> MapJ2P;

struct FuncData {
    FuncData(V8Context* ctx, SV* func) :
        ctx(ctx), func(newSVsv(func)) {}

    V8Context* ctx;
    SV* func;
};

static const char* get_typeof(const Local<Object>& object);

static void perl_caller(const FunctionCallbackInfo<Value>& args)
{
    Isolate* isolate = args.GetIsolate();
#if 1
    HandleScope handle_scope(isolate);
#endif

#if 1
    Local<External> v8_val = Local<External>::Cast(args.Data());
#else
    /*
     * If args.This() returned the same bject as GetFunction() on the function
     * template we used to create the function, this would work; alas, it
     * doesn't work, so we have to pass the data we want so that args.Data()
     * can return it.
     */
    Local<Name> v8_key = String::NewFromUtf8(isolate, "__perl_callback", NewStringType::kNormal).ToLocalChecked();
    Local<Function> v8_func = Local<Function>::Cast(args.This());
    Local<External> v8_val = Local<External>::Cast(v8_func->Get(v8_key));
#endif
    FuncData* data = (FuncData*) v8_val->Value();

    SV* ret = 0;
    SV *err_tmp;

    /* prepare Perl environment for calling the CV */
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    /* pass in the stack each of the params we received */
    int nargs = args.Length();
    for (int j = 0; j < nargs; j++) {
        Local<Value> arg = Local<Value>::Cast(args[j]);
        Local<Object> object = Local<Object>::Cast(arg);
        SV* val = pl_v8_to_perl(aTHX_ data->ctx, object);
        mXPUSHs(val);
    }

    /* call actual Perl CV, passing all params */
    PUTBACK;
    call_sv(data->func, G_SCALAR | G_EVAL);
    SPAGAIN;

    err_tmp = ERRSV;
    if (SvTRUE(err_tmp)) {
        croak("Perl sub died with error: %s", SvPV_nolen(err_tmp));
    }

    /* get returned value from Perl and return it */
    ret = POPs;
    Local<Object> object = pl_perl_to_v8(aTHX_ ret, data->ctx);

    args.GetReturnValue().Set(object);

    /* cleanup */
    PUTBACK;
    FREETMPS;
    LEAVE;
}

static SV* pl_v8_to_perl_impl(pTHX_ V8Context* ctx, const Local<Object>& object, MapJ2P& seen)
{
    SV* ret = &PL_sv_undef; /* return undef by default */
    if (object->IsUndefined()) {
    }
    else if (object->IsNull()) {
    }
    else if (object->IsBoolean()) {
        bool val = object->BooleanValue();
        ret = get_sv(val ? PL_JSON_BOOLEAN_TRUE : PL_JSON_BOOLEAN_FALSE, 0);
        SvREFCNT_inc(ret);
    }
    else if (object->IsNumber()) {
        double val = object->NumberValue();
        ret = newSVnv(val);  /* JS numbers are always doubles */
    }
    else if (object->IsString()) {
        String::Utf8Value val(ctx->isolate, object);
        ret = newSVpvn(*val, val.length());
        SvUTF8_on(ret); /* yes, always */
    }
    else if (object->IsFunction()) {
        Local<Name> v8_key = String::NewFromUtf8(ctx->isolate, "__perl_callback", NewStringType::kNormal).ToLocalChecked();
        Local<External> v8_val = Local<External>::Cast(object->Get(v8_key));
        FuncData* data = (FuncData*) v8_val->Value();
        if (data && data->func) {
            ret = data->func;
        }
    }
    else if (object->IsArray()) {
        MapJ2P::iterator k = seen.find(object);
        if (k != seen.end()) {
            SV* values = (SV*) k->second;
            /* TODO: weaken reference? */
            ret = newRV_inc(values);
        } else {
            AV* values_array = newAV();
            SV* values = sv_2mortal((SV*) values_array);
            ret = newRV_inc(values);
            seen[object] = values;

            Local<Array> array = Local<Array>::Cast(object);
            int array_top = array->Length();
            for (int j = 0; j < array_top; ++j) {
                Local<Value> value = array->Get(j);
                /* TODO: check we got a valid value */
                Local<Object> elem = Local<Object>::Cast(value);
                /* TODO: check we got a valid element */

                SV* nested = sv_2mortal(pl_v8_to_perl_impl(aTHX_ ctx, elem, seen));
                if (!nested) {
                    croak("Could not create Perl SV for array\n");
                }
                if (av_store(values_array, j, nested)) {
                    SvREFCNT_inc(nested);
                }
            }
        }
    }
    else if (object->IsObject()) {
        MapJ2P::iterator k = seen.find(object);
        if (k != seen.end()) {
            SV* values = (SV*) k->second;
            /* TODO: weaken reference? */
            ret = newRV_inc(values);
        } else {
            HV* values_hash = newHV();
            SV* values = sv_2mortal((SV*) values_hash);
            ret = newRV_inc(values);
            seen[object] = values;

            Local<Array> property_names = object->GetOwnPropertyNames();
            int hash_top = property_names->Length();
            for (int j = 0; j < hash_top; ++j) {
                Local<Value> v8_key = property_names->Get(j);
                /* TODO: check we got a valid key */

                String::Utf8Value key(ctx->isolate, v8_key->ToString());
                Local<Value> value = object->Get(v8_key);
                /* TODO: check we got a valid value */

                Local<Object> obj = Local<Object>::Cast(value);
                /* TODO: check we got a valid object */

                SV* nested = sv_2mortal(pl_v8_to_perl_impl(aTHX_ ctx, obj, seen));
                if (!nested) {
                    croak("Could not create Perl SV for hash\n");
                }
                SV* pkey = newSVpvn(*key, key.length());
                SvUTF8_on(pkey); /* yes, always */
                STRLEN klen = 0;
                const char* kstr = SvPV_const(pkey, klen);
                if (hv_store(values_hash, kstr, -klen, nested, 0)) {
                    SvREFCNT_inc(nested);
                }
            }
        }
    }
    else {
        croak("Don't know how to deal with this thing\n");
    }
    return ret;
}

static const Local<Object> pl_perl_to_v8_impl(pTHX_ SV* value, V8Context* ctx, MapP2J& seen, int ref)
{
    Local<Object> ret = Local<Object>::Cast(Null(ctx->isolate));
    if (SvTYPE(value) >= SVt_PVMG) {
        /*
         * any Perl SV that has magic (think tied objects) needs to have that
         * magic actually called to retrieve the value
         */
        mg_get(value);
    }
    if (!SvOK(value)) {
    } else if (sv_isa(value, PL_JSON_BOOLEAN_CLASS)) {
        int val = SvTRUE(value);
        ret = Local<Object>::Cast(Boolean::New(ctx->isolate, val));
    } else if (SvPOK(value)) {
        STRLEN vlen = 0;
        const char* vstr = SvPV_const(value, vlen);
        ret = Local<Object>::Cast(String::NewFromUtf8(ctx->isolate, vstr, NewStringType::kNormal).ToLocalChecked());
    } else if (SvIOK(value)) {
        long val = SvIV(value);
        if (ref && (val == 0 || val == 1)) {
            ret = Local<Object>::Cast(Boolean::New(ctx->isolate, val));
        } else {
            ret = Local<Object>::Cast(Number::New(ctx->isolate, val));
        }
    } else if (SvNOK(value)) {
        double val = SvNV(value);
        ret = Local<Object>::Cast(Number::New(ctx->isolate, val));
    } else if (SvROK(value)) {
        SV* ref = SvRV(value);
        int type = SvTYPE(ref);
        if (type < SVt_PVAV) {
            ret = pl_perl_to_v8_impl(aTHX_ ref, ctx, seen, 1);
        } else if (type == SVt_PVAV) {
            AV* values = (AV*) ref;
            MapP2J::iterator k = seen.find(values);
            if (k != seen.end()) {
                ret = k->second;
            } else {
                int array_top = av_top_index(values) + 1;
                Local<Array> array = Array::New(ctx->isolate);
                ret = Local<Object>::Cast(array);
                seen[values] = ret;

                for (int j = 0; j < array_top; ++j) {
                    SV** elem = av_fetch(values, j, 0);
                    if (!elem || !*elem) {
                        break; /* could not get element */
                    }
                    const Local<Object> nested = pl_perl_to_v8_impl(aTHX_ *elem, ctx, seen, 0);
                    /* TODO: check for validity */
                    /*  croak("Could not create JS element for array\n"); */
                    array->Set(j, nested);
                }
            }
        } else if (type == SVt_PVHV) {
            HV* values = (HV*) ref;
            MapP2J::iterator k = seen.find(values);
            if (k != seen.end()) {
                ret = k->second;
            } else {
                Local<Object> object = Object::New(ctx->isolate);
                ret = Local<Object>::Cast(object);
                seen[values] = ret;

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
                    SvUTF8_on(value); /* yes, always */ /* TODO: only for strings? */

                    const Local<Object> nested = pl_perl_to_v8_impl(aTHX_ value, ctx, seen, 0);
                    /* TODO: check for validity */
                    /*  croak("Could not create JS element for hash\n"); */

                    Local<Value> v8_key = String::NewFromUtf8(ctx->isolate, kstr, NewStringType::kNormal).ToLocalChecked();
                    object->Set(v8_key, nested);
                }
            }
        } else if (type == SVt_PVCV) {
            FuncData* data = new FuncData(ctx, value);
            Local<Value> val = External::New(ctx->isolate, data);
            Local<FunctionTemplate> ft = FunctionTemplate::New(ctx->isolate, perl_caller, val);
            Local<Name> v8_key = String::NewFromUtf8(ctx->isolate, "__perl_callback", NewStringType::kNormal).ToLocalChecked();
            Local<Function> v8_func = ft->GetFunction();
            v8_func->Set(v8_key, val);
            ret = Local<Object>::Cast(v8_func);
        } else {
            croak("Don't know how to deal with an undetermined Perl reference\n");
        }
    } else {
        croak("Don't know how to deal with an undetermined Perl object\n");
    }
    return ret;
}

SV* pl_v8_to_perl(pTHX_ V8Context* ctx, const Local<Object>& object)
{
    MapJ2P seen;
    SV* ret = pl_v8_to_perl_impl(aTHX_ ctx, object, seen);
    return ret;
}

const Local<Object> pl_perl_to_v8(pTHX_ SV* value, V8Context* ctx)
{
    MapP2J seen;
    Local<Object> ret = pl_perl_to_v8_impl(aTHX_ value, ctx, seen, 0);
    return ret;
}

SV* pl_get_global_or_property(pTHX_ V8Context* ctx, const char* name)
{
    SV* ret = &PL_sv_undef; /* return undef by default */

    HandleScope handle_scope(ctx->isolate);
    Local<Context> context = Local<Context>::New(ctx->isolate, *ctx->persistent_context);
    Context::Scope context_scope(context);

    Local<Object> object;
    bool found = find_object(ctx, name, context, object);
    if (found) {
        ret = pl_v8_to_perl(aTHX_ ctx, object);
    }

    return ret;
}

int pl_set_global_or_property(pTHX_ V8Context* ctx, const char* name, SV* value)
{
    int ret = 0;

    HandleScope handle_scope(ctx->isolate);
    Local<Context> context = Local<Context>::New(ctx->isolate, *ctx->persistent_context);
    Context::Scope context_scope(context);

    Local<Object> parent;
    Local<Value> slot;
    bool found = find_parent(ctx, name, context, parent, slot);
    if (found) {
        Local<Object> object = pl_perl_to_v8(aTHX_ value, ctx);
        parent->Set(slot, object);
        ret = 1;
    }

    return ret;
}

int pl_del_global_or_property(pTHX_ V8Context* ctx, const char* name)
{
    int ret = 0;

    HandleScope handle_scope(ctx->isolate);
    Local<Context> context = Local<Context>::New(ctx->isolate, *ctx->persistent_context);
    Context::Scope context_scope(context);

    Local<Object> parent;
    Local<Value> slot;
    bool found = find_parent(ctx, name, context, parent, slot);
    if (found) {
        parent->Delete(slot);
        ret = 1;
    }

    return ret;
}

SV* pl_exists_global_or_property(pTHX_ V8Context* ctx, const char* name)
{
    SV* ret = &PL_sv_no; /* return false by default */

    HandleScope handle_scope(ctx->isolate);
    Local<Context> context = Local<Context>::New(ctx->isolate, *ctx->persistent_context);
    Context::Scope context_scope(context);

    Local<Object> object;
    bool found = find_object(ctx, name, context, object);
    if (found) {
        ret = &PL_sv_yes;
    }

    return ret;
}

SV* pl_typeof_global_or_property(pTHX_ V8Context* ctx, const char* name)
{
    const char* cstr = "undefined";

    HandleScope handle_scope(ctx->isolate);
    Local<Context> context = Local<Context>::New(ctx->isolate, *ctx->persistent_context);
    Context::Scope context_scope(context);

    Local<Object> object;
    bool found = find_object(ctx, name, context, object);
    if (found) {
        cstr = get_typeof(object);
    }

    STRLEN clen = 0;
    SV* ret = newSVpv(cstr, clen);
    return ret;
}

SV* pl_instanceof_global_or_property(pTHX_ V8Context* ctx, const char* oname, const char* cname)
{
    SV* ret = &PL_sv_no; /* return false by default */

    HandleScope handle_scope(ctx->isolate);
    Local<Context> context = Local<Context>::New(ctx->isolate, *ctx->persistent_context);
    Context::Scope context_scope(context);

    Local<Object> oobject;
    bool found = find_object(ctx, oname, context, oobject); /* look up object */
    if (found) {
        Local<Object> cobject;
        found = find_object(ctx, cname, context, cobject); /* look up class */
        if (found) {
            Maybe<bool> ok = oobject->InstanceOf(context, cobject);
            if (ok.ToChecked()) { /* check if object instanceof class */
                ret = &PL_sv_yes;
            }
        }
    }

    return ret;
}

SV* pl_global_objects(pTHX_ V8Context* ctx)
{
    HandleScope handle_scope(ctx->isolate);
    Local<Context> context = Local<Context>::New(ctx->isolate, *ctx->persistent_context);
    Context::Scope context_scope(context);

    Local<Object> global = context->Global();
    Local<Array> property_names = global->GetOwnPropertyNames();
    int count = 0;
    AV* values = newAV();
    for (uint32_t j = 0; j < property_names->Length(); ++j) {
        Local<Value> v8_key = property_names->Get(j);
        /* TODO: check we got a valid key */
        String::Utf8Value key(ctx->isolate, v8_key->ToString());
        SV* name = sv_2mortal(newSVpvn(*key, key.length()));
        if (av_store(values, count, name)) {
            SvREFCNT_inc(name);
            ++count;
        }
    }
    return newRV_inc((SV*) values);
}
int pl_run_gc(V8Context* ctx)
{
    /* Run PL_GC_RUNS GC rounds */
    for (int j = 0; j < PL_GC_RUNS; ++j) {
        ctx->isolate->LowMemoryNotification();
    }
    return PL_GC_RUNS;
}

bool find_parent(V8Context* ctx, const char* name, Local<Context>& context, Local<Object>& parent, Local<Value>& slot, int create)
{
    int start = 0;
    parent = context->Global();
    bool found = false;
    while (1) {
        int pos = start;
        while (name[pos] != '\0' && name[pos] != '.') {
            ++pos;
        }
        int length = pos - start;
        if (length <= 0) {
            /* invalid name */
            break;
        }
        slot = String::NewFromUtf8(ctx->isolate, name + start, NewStringType::kNormal, length).ToLocalChecked();
        if (name[pos] == '\0') {
            /* final element, we are done */
            found = true;
            break;
        }
        Local<Value> child;
        if (parent->Has(slot)) {
            /* parent has a slot with that name */
            child = parent->Get(slot);
        }
        else if (!create) {
            /* we must not create the missing slot, we are done */
            break;
        }
        else {
            /* create the missing slot and go on */
            child = Object::New(ctx->isolate);
            parent->Set(slot, child);
        }
        parent = Local<Object>::Cast(child);
        if (!child->IsObject()) {
            /* child in slot is not an object */
            break;
        }
        start = pos + 1;
    }

    return found;
}

bool find_object(V8Context* ctx, const char* name, Local<Context>& context, Local<Object>& object)
{
    Local<Object> parent;
    Local<Value> slot;
    if (!find_parent(ctx, name, context, parent, slot)) {
        /* could not find parent */
        return false;
    }
    if (!parent->Has(slot)) {
        /* parent doesn't have a slot with that name */
        return false;
    }
    Local<Value> child = parent->Get(slot);
    object = Local<Object>::Cast(child);
    return true;
}

static const char* get_typeof(const Local<Object>& object)
{
    const char* label = "undefined";

    if (object->IsUndefined()) {
    }
    else if (object->IsNull()) {
        label = "null";
    }
    else if (object->IsBoolean()) {
        label = "boolean";
    }
    else if (object->IsNumber()) {
        label = "number";
    }
    else if (object->IsString()) {
        label = "string";
    }
    else if (object->IsArray()) {
        label = "array";
    }
    else if (object->IsSymbol()) {
        label = "symbol";
    }
    else if (object->IsExternal()) {
        label = "pointer";
    }
    else if (object->IsFunction()) {
        label = "function";
    }
    else if (object->IsObject()) {
        label = "object";
    }

    return label;

#if 0
    if (v->IsArgumentsObject()  ) result |= 0x0000000000000001;
    if (v->IsArrayBuffer()      ) result |= 0x0000000000000002;
    if (v->IsArrayBufferView()  ) result |= 0x0000000000000004;
    if (v->IsBooleanObject()    ) result |= 0x0000000000000010;
    if (v->IsDataView()         ) result |= 0x0000000000000040;
    if (v->IsDate()             ) result |= 0x0000000000000080;
    if (v->IsFalse()            ) result |= 0x0000000000000200;
    if (v->IsFloat32Array()     ) result |= 0x0000000000000400;
    if (v->IsFloat64Array()     ) result |= 0x0000000000000800;
    if (v->IsGeneratorFunction()) result |= 0x0000000000002000;
    if (v->IsGeneratorObject()  ) result |= 0x0000000000004000;
    if (v->IsInt16Array()       ) result |= 0x0000000000008000;
    if (v->IsInt32Array()       ) result |= 0x0000000000010000;
    if (v->IsInt32()            ) result |= 0x0000000000020000;
    if (v->IsInt8Array()        ) result |= 0x0000000000040000;
    if (v->IsMapIterator()      ) result |= 0x0000000000080000;
    if (v->IsMap()              ) result |= 0x0000000000100000;
    if (v->IsName()             ) result |= 0x0000000000200000;
    if (v->IsNativeError()      ) result |= 0x0000000000400000;
    if (v->IsNumberObject()     ) result |= 0x0000000001000000;
    if (v->IsPromise()          ) result |= 0x0000000008000000;
    if (v->IsRegExp()           ) result |= 0x0000000010000000;
    if (v->IsSetIterator()      ) result |= 0x0000000020000000;
    if (v->IsSet()              ) result |= 0x0000000040000000;
    if (v->IsStringObject()     ) result |= 0x0000000080000000;
    if (v->IsSymbolObject()     ) result |= 0x0000000200000000;
    if (v->IsTrue()             ) result |= 0x0000000800000000;
    if (v->IsTypedArray()       ) result |= 0x0000001000000000;
    if (v->IsUint16Array()      ) result |= 0x0000002000000000;
    if (v->IsUint32Array()      ) result |= 0x0000004000000000;
    if (v->IsUint32()           ) result |= 0x0000008000000000;
    if (v->IsUint8Array()       ) result |= 0x0000010000000000;
    if (v->IsUint8ClampedArray()) result |= 0x0000020000000000;
    if (v->IsWeakMap()          ) result |= 0x0000080000000000;
    if (v->IsWeakSet()          ) result |= 0x0000100000000000;
#endif
}
