#include "pl_util.h"
#include "pl_native.h"

/*
 * Native print callable from JS
 */
static duk_ret_t native_print(duk_context* ctx)
{
    duk_push_lstring(ctx, " ", 1);
    duk_insert(ctx, 0);
    duk_join(ctx, duk_get_top(ctx) - 1);
    PerlIO_stdoutf("%s\n", duk_safe_to_string(ctx, -1));
    return 0; /* no return value */
}

/*
 * Get JS compatible 'now' timestamp (millisecs since 1970).
 */
static duk_ret_t native_now_ms(duk_context* ctx)
{
    duk_push_number(ctx, (duk_double_t) (now_us() / 1000.0));
    return 1; /*  return value at top */
}

int pl_register_native_functions(Duk* duk)
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
