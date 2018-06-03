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

#if 1
    return module_cb(ctx, "perl_module_resolve");
#else
    const char* module_id = duk_require_string(ctx, 0);
    const char* parent_id = duk_require_string(ctx, 1);
    duk_push_sprintf(ctx, "%s.js", module_id);
    fprintf(stderr, "resolve_cb: id='%s', parent-id='%s', resolve-to='%s'\n",
            module_id, parent_id, duk_get_string(ctx, -1));
    return 1;
#endif
}

static duk_ret_t module_load(duk_context *ctx)
{
    // Entry stack: [ module_id exports module ]

#if 1
#if 0
    duk_require_stack(ctx, 1000);
#elif 0
    duk_check_stack(ctx, 1000);
#endif

    // duk_get_prop_string(ctx, 2, "filename");
    // Entry stack: [ module_id exports module filename ]

    return module_cb(ctx, "perl_module_load");

#else

    const char* module_id = duk_require_string(ctx, 0);
    duk_get_prop_string(ctx, 2, "filename");
    const char* filename = duk_require_string(ctx, -1);

    fprintf(stderr, "load_cb: id='%s', filename='%s'\n", module_id, filename);

    if (strcmp(module_id, "pig.js") == 0) {
        duk_push_sprintf(ctx, "module.exports = 'you\\'re about to get eaten by %s';",
                module_id);
    } else if (strcmp(module_id, "cow.js") == 0) {
        duk_push_string(ctx, "module.exports = require('pig');");
    } else if (strcmp(module_id, "ape.js") == 0) {
        duk_push_string(ctx, "module.exports = { module: module, __filename: __filename, wasLoaded: module.loaded };");
    } else if (strcmp(module_id, "badger.js") == 0) {
        duk_push_string(ctx, "exports.foo = 123; exports.bar = 234;");
    } else if (strcmp(module_id, "comment.js") == 0) {
        duk_push_string(ctx, "exports.foo = 123; exports.bar = 234; // comment");
    } else if (strcmp(module_id, "shebang.js") == 0) {
        duk_push_string(ctx, "#!ignored\nexports.foo = 123; exports.bar = 234;");
    } else {
        (void) duk_type_error(ctx, "cannot find module: %s", module_id);
    }

    return 1;
#endif
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
