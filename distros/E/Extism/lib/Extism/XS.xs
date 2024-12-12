#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <stdint.h>
#include <stdbool.h>
#include <extism.h>

static void host_function_caller (ExtismCurrentPlugin *plugin,
                                   const ExtismVal *inputs,
                                   ExtismSize n_inputs,
                                   ExtismVal *outputs,
                                   ExtismSize n_outputs,
                                   void *data) {
    dTHX;
    dSP;

	ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 6);
    PUSHs(sv_2mortal(newSVuv((UV)plugin)));
    PUSHs(sv_2mortal(newSVuv((UV)inputs)));
    PUSHs(sv_2mortal(newSVuv(n_inputs)));
    PUSHs(sv_2mortal(newSVuv((UV)outputs)));
    PUSHs(sv_2mortal(newSVuv(n_outputs)));
    PUSHs(data);
    PUTBACK;

    call_pv("Extism::Function::host_function_caller_perl", G_DISCARD);

    FREETMPS;
    LEAVE;
}

static void host_function_caller_cleanup(void *data) {
    dTHX;
    sv_2mortal(data);
}

static void log_drain_caller(const char *data, ExtismSize size) {
    dTHX;
    dSP;

	ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSVpvn(data, size)));
    PUTBACK;

    call_pv("Extism::active_log_drain_func", G_DISCARD);

    FREETMPS;
    LEAVE;
}

typedef const void * PV;

MODULE = Extism::XS		PACKAGE = Extism::XS

PROTOTYPES: DISABLE

TYPEMAP: <<HERE
ExtismPlugin * T_PTR
const ExtismPlugin * T_PTR
const uint8_t * T_PV
ExtismSize T_UV
const ExtismFunction ** T_PTR
ExtismFunction ** T_PTR
char ** T_PTR
int32_t T_IV
const void * T_PTR
ExtismFunction * T_PTR
const ExtismValType * T_PTR
ExtismCurrentPlugin * T_PTR
ExtismMemoryHandle T_UV
const ExtismCancelHandle * T_PTR
PV T_PV
uint64_t T_UV
ExtismCompiledPlugin * T_PTR
const ExtismCompiledPlugin * T_PTR
HERE

const char *
version()
    CODE:
        RETVAL = extism_version();
    OUTPUT:
        RETVAL

ExtismCompiledPlugin *
compiled_plugin_new(wasm, wasm_size, functions, n_functions, with_wasi, errmsg)
    const uint8_t *wasm
    ExtismSize wasm_size
    const ExtismFunction **functions
    ExtismSize n_functions
    bool with_wasi
    char **errmsg
    CODE:
        RETVAL = extism_compiled_plugin_new(wasm, wasm_size, functions, n_functions, with_wasi, errmsg);
    OUTPUT:
        RETVAL

void
compiled_plugin_free(compiled_plugin)
    ExtismCompiledPlugin *compiled_plugin
    CODE:
        extism_compiled_plugin_free(compiled_plugin);

ExtismPlugin *
plugin_new_from_compiled(compiled_plugin, errmsg)
    const ExtismCompiledPlugin *compiled_plugin
    char **errmsg
    CODE:
        RETVAL = extism_plugin_new_from_compiled(compiled_plugin, errmsg);
    OUTPUT:
        RETVAL

ExtismPlugin *
plugin_new(wasm, wasm_size, functions, n_functions, with_wasi, errmsg)
    const uint8_t *wasm
    ExtismSize wasm_size
    const ExtismFunction **functions
    ExtismSize n_functions
    bool with_wasi
    char **errmsg
    CODE:
        RETVAL = extism_plugin_new(wasm, wasm_size, functions, n_functions, with_wasi, errmsg);
    OUTPUT:
        RETVAL

ExtismPlugin *
plugin_new_with_fuel_limit(wasm, wasm_size, functions, n_functions, with_wasi, fuel_limit, errmsg)
    const uint8_t *wasm
    ExtismSize wasm_size
    const ExtismFunction **functions
    ExtismSize n_functions
    bool with_wasi
    uint64_t fuel_limit
    char **errmsg
    CODE:
        RETVAL = extism_plugin_new_with_fuel_limit(wasm, wasm_size, functions, n_functions, with_wasi, fuel_limit, errmsg);
    OUTPUT:
        RETVAL

void
plugin_allow_http_response_headers(plugin)
    ExtismPlugin *plugin
    CODE:
        extism_plugin_allow_http_response_headers(plugin);

void
plugin_new_error_free(err)
    void *err
    CODE:
        extism_plugin_new_error_free(err);

int32_t
plugin_call(plugin, func_name, data, data_len, host_context=&PL_sv_undef)
    ExtismPlugin *plugin
    const char *func_name
    const uint8_t *data
    ExtismSize data_len
    SV *host_context
    CODE:
        RETVAL = extism_plugin_call_with_host_context(plugin, func_name, data, data_len, host_context);
    OUTPUT:
        RETVAL

const char *
plugin_error(plugin)
    ExtismPlugin *plugin
    CODE:
        RETVAL = extism_plugin_error(plugin);
    OUTPUT:
        RETVAL

ExtismSize
plugin_output_length(plugin)
    ExtismPlugin *plugin
    CODE:
        RETVAL = extism_plugin_output_length(plugin);
    OUTPUT:
        RETVAL

const void *
plugin_output_data(plugin)
    ExtismPlugin *plugin
    CODE:
        RETVAL = extism_plugin_output_data(plugin);
    OUTPUT:
        RETVAL

void
plugin_free(plugin)
    ExtismPlugin *plugin
    CODE:
        extism_plugin_free(plugin);

bool
plugin_reset(plugin)
    ExtismPlugin *plugin
    CODE:
        RETVAL = extism_plugin_reset(plugin);
    OUTPUT:
        RETVAL

const void *
plugin_id(plugin)
    ExtismPlugin *plugin
    CODE:
        RETVAL = extism_plugin_id(plugin);
    OUTPUT:
        RETVAL

bool
plugin_function_exists(plugin, func_name)
    ExtismPlugin *plugin
    const char *func_name
    CODE:
        RETVAL = extism_plugin_function_exists(plugin, func_name);
    OUTPUT:
        RETVAL

bool
plugin_config(plugin, sv_json)
    ExtismPlugin *plugin
    SV *sv_json
    CODE:
        STRLEN json_len;
        char *json = SvPV(sv_json, json_len);
        RETVAL = extism_plugin_config(plugin, json, json_len);
    OUTPUT:
        RETVAL

const ExtismCancelHandle *
plugin_cancel_handle(plugin)
    const ExtismPlugin *plugin
    CODE:
        RETVAL = extism_plugin_cancel_handle(plugin);
    OUTPUT:
        RETVAL

bool
plugin_cancel(cancel_handle)
    const ExtismCancelHandle *cancel_handle
    CODE:
        RETVAL = extism_plugin_cancel(cancel_handle);
    OUTPUT:
        RETVAL

ExtismFunction *
function_new(name, inputs, n_inputs, outputs, n_outputs, data)
    const char *name
    const ExtismValType *inputs
    ExtismSize n_inputs
    const ExtismValType *outputs
    ExtismSize n_outputs
    SV *data
    CODE:
        RETVAL = extism_function_new(name, inputs, n_inputs, outputs, n_outputs, &host_function_caller, SvREFCNT_inc(data), &host_function_caller_cleanup);
    OUTPUT:
        RETVAL

void
function_free(f)
    ExtismFunction *f
    CODE:
        extism_function_free(f);

void
function_set_namespace(ptr, namespace_)
    ExtismFunction *ptr
    const char *namespace_
    CODE:
        extism_function_set_namespace(ptr, namespace_);

void *
current_plugin_memory(plugin)
    ExtismCurrentPlugin *plugin
    CODE:
        RETVAL = extism_current_plugin_memory(plugin);
    OUTPUT:
        RETVAL

ExtismMemoryHandle
current_plugin_memory_alloc(plugin, n)
    ExtismCurrentPlugin *plugin
    ExtismSize n
    CODE:
        RETVAL = extism_current_plugin_memory_alloc(plugin, n);
    OUTPUT:
        RETVAL

ExtismSize
current_plugin_memory_length(plugin, handle)
    ExtismCurrentPlugin *plugin
    ExtismMemoryHandle handle
    CODE:
        RETVAL = extism_current_plugin_memory_length(plugin, handle);
    OUTPUT:
        RETVAL


void
current_plugin_memory_free(plugin, handle)
    ExtismCurrentPlugin *plugin
    ExtismMemoryHandle handle
    CODE:
        extism_current_plugin_memory_free(plugin, handle);

SV *
current_plugin_host_context(plugin)
    ExtismCurrentPlugin *plugin
    CODE:
        RETVAL = extism_current_plugin_host_context(plugin);
        if (RETVAL != &PL_sv_undef) {
            SvREFCNT_inc_simple_NN(RETVAL);
        }
    OUTPUT:
        RETVAL

void
log_file(filename, log_level)
    const char *filename
    const char *log_level
    CODE:
        extism_log_file(filename, log_level);

bool
log_custom(log_level)
    const char *log_level
    CODE:
        RETVAL = extism_log_custom(log_level);
    OUTPUT:
        RETVAL

void
log_drain()
    CODE:
        extism_log_drain(&log_drain_caller);

void
CopyToPtr(src, dest, n)
    PV src
    void *dest
    size_t n
    CODE:
        Copy(src, dest, n, uint8_t);
