#include "duk_module_node.h"
#include "pl_module.h"

static duk_ret_t module_resolve(duk_context *ctx);
static duk_ret_t module_load(duk_context *ctx);

static duk_ret_t module_cb(duk_context *ctx, const char* func_name)
{
    if (!duk_get_global_string(ctx, func_name)) {
        // TODO: maybe do something else here
        croak("%s is not a Perl handler\n", func_name);
    }
    if (!duk_is_c_function(ctx, -1)) {
        // TODO: maybe do something else here
        croak("%s does not contain a C callback\n", func_name);
    }
    if (!duk_get_prop_lstring(ctx, -1, PL_SLOT_GENERIC_CALLBACK, sizeof(PL_SLOT_GENERIC_CALLBACK) - 1)) {
        croak("%s does not point to a Perl callback\n", func_name);
    }
    SV* func = (SV*) duk_get_pointer(ctx, -1);
    duk_pop_2(ctx);  /* pop pointer and function */
    if (!func) {
        croak("%s points to a void Perl callback\n", func_name);
    }
    return pl_call_perl_sv(ctx, func);
    // (void) duk_type_error(ctx, "cannot find module: %s", module_id);
}

static duk_ret_t module_resolve(duk_context *ctx)
{
    // Entry stack: [ requested_id parent_id ]

    return module_cb(ctx, "perl_module_resolve");
}

static duk_ret_t module_load(duk_context *ctx)
{
    // Entry stack: [ module_id exports module ]

    return module_cb(ctx, "perl_module_load");
}

void pl_register_module_functions(Duk* duk)
{
    duk_context* ctx = duk->ctx;
    duk_push_object(ctx);
    duk_push_c_function(ctx, module_resolve, DUK_VARARGS);
    duk_put_prop_string(ctx, -2, "resolve");
    duk_push_c_function(ctx, module_load, DUK_VARARGS);
    duk_put_prop_string(ctx, -2, "load");
    duk_module_node_init(ctx);
}

#if 0
int main(int argc, char* argv[])
{
    return 0;
}
#endif
