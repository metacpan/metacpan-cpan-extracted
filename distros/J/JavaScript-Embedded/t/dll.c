#include "duk_perl.h"
#include <stdio.h>

static int add_number(duk_context *ctx) {
    int num = duk_get_int(ctx, 0);
    int num2 = duk_get_int(ctx, 1);
    duk_push_int(ctx, num+num2);
    return 1;
}

static const duk_function_list_entry my_funcs[] = {
    { "add_number", add_number, 2 },
    { NULL, NULL, 0 }
};

MODULE_EXPORT (ctx, filename) {
    duk_push_object(ctx);
    duk_put_function_list(ctx, -1, my_funcs);
}
