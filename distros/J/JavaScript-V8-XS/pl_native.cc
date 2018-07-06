#include <v8.h>
#include "pl_util.h"
#include "pl_native.h"

typedef void (*Handler)(const FunctionCallbackInfo<Value>& args);

// Extracts a C string from a V8 Utf8Value.
static const char* ToCString(const String::Utf8Value& value)
{
    return *value ? *value : "<string conversion failed>";
}

// Prints its arguments on stdout separated by spaces and ending with a
// newline.
static void native_print(const FunctionCallbackInfo<Value>& args)
{
    bool first = true;
    for (int i = 0; i < args.Length(); i++) {
        HandleScope handle_scope(args.GetIsolate());
        if (first) {
            first = false;
        } else {
            printf(" ");
        }
        String::Utf8Value str(args.GetIsolate(), args[i]);
        const char* cstr = ToCString(str);
        printf("%s", cstr);
    }
    printf("\n");
    fflush(stdout);
}

// Return a string with the current version for v8.
static void native_version(const FunctionCallbackInfo<Value>& args)
{
    args.GetReturnValue().Set(
            String::NewFromUtf8(args.GetIsolate(), V8::GetVersion(),
                NewStringType::kNormal).ToLocalChecked());
}

// Return a double with the current timestamp in ms.
static void native_now_ms(const FunctionCallbackInfo<Value>& args)
{
    double now = now_us() / 1000.0;
    args.GetReturnValue().Set(Local<Object>::Cast(Number::New(args.GetIsolate(), now)));
}

int pl_register_native_functions(V8Context* ctx, Local<ObjectTemplate>& object_template)
{
    static struct Data {
        const char* name;
        Handler func;
    } data[] = {
        { "print"       , native_print  },
        { "version"     , native_version },
        { "timestamp_ms", native_now_ms },
    };
    int n = sizeof(data) / sizeof(data[0]);
    for (int j = 0; j < n; ++j) {
        object_template->Set(
                String::NewFromUtf8(ctx->isolate, data[j].name, NewStringType::kNormal).ToLocalChecked(),
                FunctionTemplate::New(ctx->isolate, data[j].func));
    }
    return n;
}
