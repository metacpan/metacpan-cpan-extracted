#ifndef _DUKPERL_H
#define _DUKPERL_H

#include "./lib/duktape.h"

void _duk_perl_init_module(duk_context *ctx, const char *filename);
void _duk_perl_module_export (duk_context *ctx, const char *filename);

const char *_DUKPERL_MODULE_PATH = "";

#ifdef __cplusplus
    #define EXTERNC extern "C"
#else
    #define EXTERNC
#endif

#define MODULE_EXPORT(ctx, filename) EXTERNC void _duk_perl_module_export (duk_context *ctx, const char *filename)
#define _DUKPERL_INIT void _duk_perl_init_module(duk_context *ctx, const char *filename)

#ifdef _WIN32
    #include <windows.h>
    #define dlsym(x, y) GetProcAddress((HMODULE)x, y)
    #define dlopen(x,y) (void*)LoadLibrary(x)
    #define dlclose(x) FreeLibrary((HMODULE)x)
    #define DUKPERL_MODULE_INIT(ctx, filename) EXTERNC __declspec(dllexport) _DUKPERL_INIT
#else
    #include <dlfcn.h>
    #define DUKPERL_MODULE_INIT(ctx, filename) EXTERNC _DUKPERL_INIT
#endif

#ifndef DUKTAPE_DONT_LOAD_SHARED
DUKPERL_MODULE_INIT (ctx, filename) {
    _DUKPERL_MODULE_PATH = filename;
    _duk_perl_module_export(ctx,filename);
}
#endif

#endif /*_DUKPERL_H*/
