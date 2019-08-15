#include <stdarg.h>
#include <stdio.h>
#include <v8.h>
#include "pl_util.h"
#include "pl_console.h"

#define NEED_newRV_noinc_GLOBAL
#include "ppport.h"

#define CONSOLE_FLUSH         0x01
#define CONSOLE_TARGET_STDOUT 0x10
#define CONSOLE_TARGET_STDERR 0x20

static void save_msg(pTHX_ V8Context* ctx, const char* target, SV* message)
{
    STRLEN tlen = strlen(target);
    AV* data = 0;
    int top = 0;
    SV* pvalue = 0;
    SV** found = hv_fetch(ctx->msgs, target, tlen, 0);
    if (found) {
        SV* ref = SvRV(*found);
        /* value not a valid arrayref? bail out */
        if (SvTYPE(ref) != SVt_PVAV) {
            return;
        }
        data = (AV*) ref;
        top = av_top_index(data);
    } else {
        SV* ref = 0;
        data = newAV();
        ref = newRV_noinc((SV*) data);
        if (hv_store(ctx->msgs, target, tlen, ref, 0)) {
            SvREFCNT_inc(ref);
        }
        top = -1;
    }

    pvalue = sv_2mortal(message);
    if (av_store(data, ++top, pvalue)) {
        SvREFCNT_inc(pvalue);
    }
    else {
        croak("Could not store message in target %*.*s\n", (int) tlen, (int) tlen, target);
    }
}

static int console_output_line(pTHX_ V8Context* ctx, SV* message, unsigned int flags)
{
    STRLEN mlen = 0;
    char* mstr = SvPV(message, mlen);
    if (ctx->flags & V8_OPT_FLAG_SAVE_MESSAGES) {
        const char* target = (flags & CONSOLE_TARGET_STDERR) ? "stderr" : "stdout";
        save_msg(aTHX_ ctx, target, message);
    }
    else {
        PerlIO* fp = (flags & CONSOLE_TARGET_STDERR) ? PerlIO_stderr() : PerlIO_stdout();
        PerlIO_printf(fp, "%s\n", mstr);
        if (flags & CONSOLE_FLUSH) {
            PerlIO_flush(fp);
        }
    }
    return mlen;
}

static int console_output(const FunctionCallbackInfo<Value>& args, unsigned int flags, const char* preamble = 0, bool stack = false, int start = 0)
{
    dTHX;

    Isolate* isolate = args.GetIsolate();
    HandleScope handle_scope(isolate);
    Local<External> v8_val = Local<External>::Cast(args.Data());
    V8Context* ctx = (V8Context*) v8_val->Value();
    Local<Context> context = Local<Context>::New(isolate, *ctx->persistent_context);
    Context::Scope context_scope(context);

    SV* message = newSVpvs("");
    bool separate = false;
    if (preamble) {
        Perl_sv_catpv(aTHX_ message, preamble);
        Perl_sv_catpvf(aTHX_ message, ":");
        separate = true;
    }

    Local<Object> global = context->Global();
    Local<Name> to_str_nam = String::NewFromUtf8(isolate, "JSON_stringify_with_cycles", NewStringType::kNormal).ToLocalChecked();
    Local<Value> to_str_val = global->Get(to_str_nam);
    if (to_str_val->IsFunction()) {
        Local<Function> to_str_fun = Local<Function>::Cast(to_str_val);
        Local<Value> sargs[1];
        for (int j = start; j < args.Length(); j++) {
            /* add separator if necessary */
            if (separate) {
                Perl_sv_catpvf(aTHX_ message, " ");
            }
            separate = true;

            /* for non-objects, just get their value as string */
            if (!args[j]->IsObject()) {
                String::Utf8Value str(isolate, args[j]);
                Perl_sv_catpvf(aTHX_ message, "%s", *str);
                continue;
            }

            /* convert each object arg to JSON */
            sargs[0] = args[j];
            Local<Value> ret;
            if (!to_str_fun->Call(context, global, 1, sargs).ToLocal(&ret)) {
                continue;
            }
            Local<String> json = Local<String>::Cast(ret);
            String::Utf8Value str(isolate, json);
            Perl_sv_catpvf(aTHX_ message, "%s", *str);
        }
    }
    if (stack) {
#if 0
        /* TODO: generate a stack trace */
        v8_inspector::V8Inspector* inspector = new v8_inspector::V8InspectorImpl::V8InspectorImpl();
        inspector->captureStackTrace();
#endif
    }

    return console_output_line(aTHX_ ctx, message, flags);
}

static void console_assert(const FunctionCallbackInfo<Value>& args)
{
    if (args.Length() < 1) {
        return;
    }
    bool silent = args[0]->BooleanValue();
    if (silent) {
        return;
    }
    console_output(args, CONSOLE_TARGET_STDOUT | CONSOLE_FLUSH, "AssertionError", true, 1);
}

static void console_log(const FunctionCallbackInfo<Value>& args)
{
    console_output(args, CONSOLE_TARGET_STDOUT | CONSOLE_FLUSH);
}

static void console_debug(const FunctionCallbackInfo<Value>& args)
{
    console_output(args, CONSOLE_TARGET_STDOUT | CONSOLE_FLUSH);
}

static void console_trace(const FunctionCallbackInfo<Value>& args)
{
    console_output(args, CONSOLE_TARGET_STDOUT | CONSOLE_FLUSH, "Trace", true);
}

static void console_info(const FunctionCallbackInfo<Value>& args)
{
    console_output(args, CONSOLE_TARGET_STDOUT | CONSOLE_FLUSH);
}

static void console_warn(const FunctionCallbackInfo<Value>& args)
{
    console_output(args, CONSOLE_TARGET_STDERR | CONSOLE_FLUSH);
}

static void console_error(const FunctionCallbackInfo<Value>& args)
{
    console_output(args, CONSOLE_TARGET_STDERR | CONSOLE_FLUSH, "Error", true);
}

static void console_exception(const FunctionCallbackInfo<Value>& args)
{
    console_output(args, CONSOLE_TARGET_STDERR | CONSOLE_FLUSH, "Error", true);
}

static void console_dir(const FunctionCallbackInfo<Value>& args)
{
    console_output(args, CONSOLE_TARGET_STDERR | CONSOLE_FLUSH);
}

int pl_register_console_functions(V8Context* ctx)
{
    typedef void (*Handler)(const FunctionCallbackInfo<Value>& args);
    static struct Data {
        const char* name;
        Handler func;
    } data[] = {
        { "console.assert"   , console_assert    },
        { "console.log"      , console_log       },
        { "console.debug"    , console_debug     },
        { "console.trace"    , console_trace     },
        { "console.info"     , console_info      },
        { "console.warn"     , console_warn      },
        { "console.error"    , console_error     },
        { "console.exception", console_exception },
        { "console.dir"      , console_dir       },
    };
    HandleScope handle_scope(ctx->isolate);
    Local<Context> context = Local<Context>::New(ctx->isolate, *ctx->persistent_context);
    Context::Scope context_scope(context);
    Local<Value> v8_ctx = External::New(ctx->isolate, ctx);
    int n = sizeof(data) / sizeof(data[0]);
    for (int j = 0; j < n; ++j) {
        Local<Object> object;
        Local<Value> slot;
        bool found = find_parent(ctx, data[j].name, context, object, slot, true);
        if (!found) {
            pl_show_error(ctx, "could not create parent for %s", data[j].name);
            continue;
        }
        Local<FunctionTemplate> ft = FunctionTemplate::New(ctx->isolate, data[j].func, v8_ctx);
        Local<Function> v8_func = ft->GetFunction();
        object->Set(slot, v8_func);
    }
    return n;
}

int pl_show_error(V8Context* ctx, const char* fmt, ...)
{
    dTHX;

    SV* message = newSVpvs("");
    va_list ap;
    va_start(ap, fmt);
    Perl_sv_vcatpvf(aTHX_ message, fmt, &ap);
    va_end(ap);
    return console_output_line(aTHX_ ctx, message, CONSOLE_TARGET_STDERR | CONSOLE_FLUSH);
}
