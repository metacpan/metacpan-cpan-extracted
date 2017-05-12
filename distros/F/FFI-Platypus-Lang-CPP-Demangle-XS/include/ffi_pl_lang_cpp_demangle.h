#ifndef FFI_PL_LANG_CPP_DEMANGLE_H
#define FFI_PL_LANG_CPP_DEMANGLE_H
#ifdef __cplusplus
extern "C" {
#endif

extern int
ffi_pl_lang_cpp_demangle_status;

const char *
ffi_pl_lang_cpp_demangle(const char *c_symbol);

#ifdef __cplusplus
}
#endif
#endif
