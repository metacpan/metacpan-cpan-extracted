#define NO_XSLOCKS
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <time.h>
#include <stdlib.h>

#define NEED_newRV_noinc
#define DUKTAPE_DONT_LOAD_SHARED


#include "./lib/duktape.c"
#include "./lib/module-duktape/duk_module_duktape.c"
#include "./lib/print-alert/duk_print_alert.c"
#include "duk_perl.h"

#ifndef Newx
#  define Newx(v,n,t) New(0,v,n,t)
#endif



typedef struct {
    /* The double value in the union is there to ensure alignment is
     * good for IEEE doubles too.  In many 32-bit environments 4 bytes
     * would be sufficiently aligned and the double value is unnecessary.
     */
    union {
        size_t sz;
        double d;
    } u;
} perlDukMemHdr;

typedef struct {
    int timeout;
    size_t max_memory;
    size_t total_allocated;
    duk_context *ctx;
} perlDuk;



/**
  * perl_duk_exec_timeout
******************************************************************************/
int perl_duk_exec_timeout( void *udata ) {
    perlDuk *duk = (perlDuk *) udata;
    int timeout = duk->timeout;

    if (timeout > 0){
        clock_t uptime = clock();
        int passed_time = (int)(uptime / CLOCKS_PER_SEC);
        if (passed_time > timeout){
            return 1;
        }
    }
    return 0;
}



/**
  * duk_sandbox_alloc
******************************************************************************/
static void *duk_sandbox_alloc(void *udata, duk_size_t size) {
    perlDuk *duk = (perlDuk *) udata;
    perlDukMemHdr *hdr;

    size_t max_memory = duk->max_memory;
    size_t total_allocated  = duk->total_allocated;

    if (size == 0) return NULL;

    if (total_allocated + size >= max_memory) {
        duk->total_allocated = 0;
        return NULL;
    }

    hdr = (perlDukMemHdr *) malloc(size + sizeof(perlDukMemHdr));
    if (!hdr) return NULL;

    hdr->u.sz = size;
    duk->total_allocated += size;
    return (void *) (hdr + 1);
}



/**
  * duk_sandbox_realloc
******************************************************************************/
static void *duk_sandbox_realloc(void *udata, void *ptr, duk_size_t size) {
    perlDukMemHdr *hdr;
    size_t old_size;
    void *t;

    perlDuk *duk = (perlDuk *) udata;
    size_t max_memory    = duk->max_memory;
    size_t total_allocated  = duk->total_allocated;

    if (ptr) {
        hdr = (perlDukMemHdr *) (((char *) ptr) - sizeof(perlDukMemHdr));
        old_size = hdr->u.sz;

        if (size == 0) {
            duk->total_allocated -= old_size;
            free((void *) hdr);
            return NULL;
        }

        if (total_allocated - old_size + size > max_memory) {
            duk->total_allocated = 0;
            return NULL;
        }

        t = realloc((void *) hdr, size + sizeof(perlDukMemHdr));
        if (!t) return NULL;

        hdr = (perlDukMemHdr *) t;
        duk->total_allocated -= old_size;
        duk->total_allocated += size;
        hdr->u.sz = size;
        return (void *) (hdr + 1);
    } else {
        if (size == 0) return NULL;

        if (total_allocated + size > max_memory) {
            duk->total_allocated = 0;
            return NULL;
        }

        hdr = (perlDukMemHdr *) malloc(size + sizeof(perlDukMemHdr));
        if (!hdr) return NULL;

        hdr->u.sz = size;
        duk->total_allocated += size;
        return (void *) (hdr + 1);
    }
}



/**
  * duk_sandbox_free
******************************************************************************/
static void duk_sandbox_free(void *udata, void *ptr) {
    perlDukMemHdr *hdr;

    perlDuk *duk = (perlDuk *) udata;

    if (!ptr) return;

    hdr = (perlDukMemHdr *) (((char *) ptr) - sizeof(perlDukMemHdr));
    duk->total_allocated -= hdr->u.sz;
    free((void *) hdr);
}



/**
  * get_user_data
******************************************************************************/
perlDuk *get_user_data (duk_context *ctx){
    duk_memory_functions funcs;
    duk_get_memory_functions(ctx, &funcs);
    return (perlDuk *)funcs.udata;
}



/**
  * fatal_handler
******************************************************************************/
void fatal_handler (void *udata, const char *msg) {
    croak(msg);
}



/**
  * new
******************************************************************************/
SV *perl_duk_new(const char *classname, size_t max_memory, int timeout) {
    duk_context *ctx;
    SV          *obj;
    SV          *obj_ref;

    perlDuk *duk = malloc(sizeof(*duk));
    duk->ctx = NULL;
    duk->timeout = timeout;
    duk->max_memory = max_memory;
    duk->total_allocated = 0;

    if (max_memory > 0){
        ctx = duk_create_heap(duk_sandbox_alloc, duk_sandbox_realloc, duk_sandbox_free, (void *)duk, fatal_handler);
    } else {
        ctx = duk_create_heap(NULL, NULL, NULL, (void *)duk, fatal_handler);
    }

    duk_module_duktape_init(ctx);
    duk_print_alert_init(ctx, 0);

    obj = newSViv((IV)ctx);
    obj_ref = newRV_noinc(obj);
    sv_bless(obj_ref, gv_stashpv(classname, GV_ADD));
    SvREADONLY_on(obj);

    duk->ctx = ctx;
    return obj_ref;
}



/**
  * perl_duk_set_timeout
******************************************************************************/
void perl_duk_set_timeout(duk_context *ctx, int timeout){
    perlDuk *duk = get_user_data(ctx);
    int current = 0;

    if (timeout > 0){
        timeout += (int)(clock() / CLOCKS_PER_SEC);
    }

    duk->timeout = current + timeout;
}



/**
  * perl_duk_resize_memory
******************************************************************************/
void perl_duk_resize_memory(duk_context *ctx, size_t max_memory){
    perlDuk *duk = get_user_data(ctx);
    duk->max_memory = max_memory;
}



/**
  * perl_duk_reset_top
  * quick helper function to reset stack top
******************************************************************************/
void perl_duk_reset_top(duk_context *ctx){
    duk_idx_t top = duk_get_top(ctx);
    duk_pop_n(ctx, top);
}



/**
  * is number
******************************************************************************/
int duk_sv_is_number(SV *sv) {
    if (SvIOK(sv) || SvNOK(sv)) return 1;
    return 0;
}



/**
  * call_safe_perl_sub
******************************************************************************/
int call_safe_perl_sub(duk_context *ctx, void *udata) {
    SV *sub = (SV *)udata;

    dSP;
    char *error = NULL;
    STRLEN error_len;
    SV    *sv;
    int count;
    int ret = 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    count = call_sv(sub, G_NOARGS | G_SCALAR);
    SPAGAIN;
    if( count > 0) {
        sv = POPs;
        if(SvIOK(sv)) {
            ret = SvIV(sv);
        }
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return ret;
}



/**
  * perl_duk_safe_call
******************************************************************************/
duk_int_t perl_duk_safe_call(duk_context *ctx, SV *func, duk_idx_t nargs, duk_idx_t nrets) {

    duk_int_t ret = 0;

    JMPENV *p = PL_top_env;
    ret = duk_safe_call(ctx, call_safe_perl_sub, (void *)func, nargs, nrets);
    if (ret == DUK_EXEC_ERROR){
        PL_top_env = p;
        croak("Duk::Error");
    }
    return ret;
}



/**
  * call_perl_function
******************************************************************************/
int call_perl_function(duk_context *ctx) {

    duk_push_current_function(ctx);
    duk_get_prop_string(ctx, -1, "_my_perl_sub");
    SV *sub = duk_require_pointer(ctx, -1);
    duk_pop_2(ctx);

    char *error = NULL;
    STRLEN error_len;

    dSP;
    SV    *sv;
    int count;
    int ret = 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    count = call_sv(sub, G_NOARGS | G_EVAL | G_SCALAR);
    SPAGAIN;
    if (SvTRUE(ERRSV)){
        POPs;
        error = SvPV( ERRSV, error_len);
    } else if( count > 0) {
        sv = POPs;
        if(SvIOK(sv)) {
            ret = SvIV(sv);
        }
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
    if (error){
        // reaching here duktape already pushed
        // error string so we just throw
        duk_throw(ctx);
    }

    return ret;
}



/**
  * perl_push_function
******************************************************************************/
duk_idx_t perl_push_function (duk_context *ctx, SV *sub, duk_idx_t nargs) {
    duk_idx_t n = duk_push_c_function(ctx, call_perl_function, nargs);
    duk_push_pointer(ctx, sub);
    duk_put_prop_string(ctx, -2, "_my_perl_sub");
    return n;
}



/**
  * perl_duk_require_context
******************************************************************************/
SV *perl_duk_require_context(duk_context *ctx, duk_idx_t index) {
    duk_context *ctx2;
    SV         *obj;
    SV         *obj_ref;

    ctx2 = duk_require_context(ctx, index);
    obj = newSViv((IV)ctx2);
    obj_ref = newRV_noinc(obj);
    sv_bless(obj_ref, gv_stashpv("JavaScript::Duktape::Vm", GV_ADD));
    SvREADONLY_on(obj);
    return obj_ref;
}



/**
  * perl_duk_get_utf8_string
******************************************************************************/
SV *perl_duk_get_utf8_string(duk_context *ctx, duk_idx_t index) {
    STRLEN slen;
    const char *str = duk_get_lstring(ctx, index, &slen);
    SV *src = newSVpv(str, slen);
    SvPV(src, slen);
    SvUTF8_on(src);
    return src;
}



/**
  * duktape_dlOpen
******************************************************************************/
void *duktape_dlOpen(duk_context *ctx, const char *ModuleName) {
    void *handle = dlopen(ModuleName, RTLD_LAZY);

    if (!handle){
        croak("Loading Module %s Aborted\n", ModuleName);
    }

    typedef void (*init_t)(duk_context *ctx, const char *ModuleName);
    init_t func = (init_t) dlsym(handle, "_duk_perl_init_module");

    if (!func){
        croak("Loading Module %s Aborted\n", ModuleName);
    }

    //init module
    func(ctx, ModuleName);
    return handle;
}



/**
  * duktape_dlClose
******************************************************************************/
int duktape_dlClose(duk_context *ctx, void *dlHandle){
    int ret = dlclose(dlHandle);
    #ifndef _WIN32
        if (ret == 0) ret = 1;
        else ret = 0;
    #endif

    duk_push_int(ctx, ret);
    return ret;
}



/**
  * destructions
******************************************************************************/
void free_perl_duk (duk_context *ctx){
    perlDuk *duk = get_user_data(ctx);
    if (duk != NULL) free(duk);
}


// not callabel
void DESTROY(duk_context *ctx) {
    perlDuk *duk = get_user_data(ctx);
    if (duk != NULL) free(duk);
    printf("Destroying %p\n", ctx);
}



/*
    Auto Generated C Code by parser.pl
    parser.pl reads duktape.h file and create both
    perl & C map code to Duktape API
*/


//void *duk_alloc(duk_context *ctx, duk_size_t size);
void *aperl_duk_alloc(duk_context *ctx, duk_size_t size) {
    void *ret = duk_alloc(ctx, size);
    return ret;
}

//void *duk_alloc_raw(duk_context *ctx, duk_size_t size);
void *aperl_duk_alloc_raw(duk_context *ctx, duk_size_t size) {
    void *ret = duk_alloc_raw(ctx, size);
    return ret;
}

//void duk_base64_decode(duk_context *ctx, duk_idx_t idx);
void aperl_duk_base64_decode(duk_context *ctx, duk_idx_t idx) {
    duk_base64_decode(ctx, idx);
}

//const char *duk_base64_encode(duk_context *ctx, duk_idx_t idx);
const char *aperl_duk_base64_encode(duk_context *ctx, duk_idx_t idx) {
    const char *ret = duk_base64_encode(ctx, idx);
    return ret;
}

//const char *duk_buffer_to_string(duk_context *ctx, duk_idx_t idx);
const char *aperl_duk_buffer_to_string(duk_context *ctx, duk_idx_t idx) {
    const char *ret = duk_buffer_to_string(ctx, idx);
    return ret;
}

//void duk_call(duk_context *ctx, duk_idx_t nargs);
void aperl_duk_call(duk_context *ctx, duk_idx_t nargs) {
    duk_call(ctx, nargs);
}

//void duk_call_method(duk_context *ctx, duk_idx_t nargs);
void aperl_duk_call_method(duk_context *ctx, duk_idx_t nargs) {
    duk_call_method(ctx, nargs);
}

//void duk_call_prop(duk_context *ctx, duk_idx_t obj_idx, duk_idx_t nargs);
void aperl_duk_call_prop(duk_context *ctx, duk_idx_t obj_idx, duk_idx_t nargs) {
    duk_call_prop(ctx, obj_idx, nargs);
}

//duk_codepoint_t duk_char_code_at(duk_context *ctx, duk_idx_t idx, duk_size_t char_offset);
duk_codepoint_t aperl_duk_char_code_at(duk_context *ctx, duk_idx_t idx, duk_size_t char_offset) {
    duk_codepoint_t ret = duk_char_code_at(ctx, idx, char_offset);
    return ret;
}

//duk_bool_t duk_check_stack(duk_context *ctx, duk_idx_t extra);
duk_bool_t aperl_duk_check_stack(duk_context *ctx, duk_idx_t extra) {
    duk_bool_t ret = duk_check_stack(ctx, extra);
    return ret;
}

//duk_bool_t duk_check_stack_top(duk_context *ctx, duk_idx_t top);
duk_bool_t aperl_duk_check_stack_top(duk_context *ctx, duk_idx_t top) {
    duk_bool_t ret = duk_check_stack_top(ctx, top);
    return ret;
}

//duk_bool_t duk_check_type(duk_context *ctx, duk_idx_t idx, duk_int_t type);
duk_bool_t aperl_duk_check_type(duk_context *ctx, duk_idx_t idx, duk_int_t type) {
    duk_bool_t ret = duk_check_type(ctx, idx, type);
    return ret;
}

//duk_bool_t duk_check_type_mask(duk_context *ctx, duk_idx_t idx, duk_uint_t mask);
duk_bool_t aperl_duk_check_type_mask(duk_context *ctx, duk_idx_t idx, duk_uint_t mask) {
    duk_bool_t ret = duk_check_type_mask(ctx, idx, mask);
    return ret;
}

//void duk_compact(duk_context *ctx, duk_idx_t obj_idx);
void aperl_duk_compact(duk_context *ctx, duk_idx_t obj_idx) {
    duk_compact(ctx, obj_idx);
}

//void duk_compile(duk_context *ctx, duk_uint_t flags);
void aperl_duk_compile(duk_context *ctx, duk_uint_t flags) {
    duk_compile(ctx, flags);
}

//void duk_compile_lstring(duk_context *ctx, duk_uint_t flags, const char *src, duk_size_t len);
void aperl_duk_compile_lstring(duk_context *ctx, duk_uint_t flags, const char *src, duk_size_t len) {
    duk_compile_lstring(ctx, flags, src, len);
}

//void duk_compile_lstring_filename(duk_context *ctx, duk_uint_t flags, const char *src, duk_size_t len);
void aperl_duk_compile_lstring_filename(duk_context *ctx, duk_uint_t flags, const char *src, duk_size_t len) {
    duk_compile_lstring_filename(ctx, flags, src, len);
}

//void duk_compile_string(duk_context *ctx, duk_uint_t flags, const char *src);
void aperl_duk_compile_string(duk_context *ctx, duk_uint_t flags, const char *src) {
    duk_compile_string(ctx, flags, src);
}

//void duk_compile_string_filename(duk_context *ctx, duk_uint_t flags, const char *src);
void aperl_duk_compile_string_filename(duk_context *ctx, duk_uint_t flags, const char *src) {
    duk_compile_string_filename(ctx, flags, src);
}

//duk_double_t duk_components_to_time(duk_context *ctx, duk_time_components *comp);
duk_double_t aperl_duk_components_to_time(duk_context *ctx, duk_time_components *comp) {
    duk_double_t ret = duk_components_to_time(ctx, comp);
    return ret;
}

//void duk_concat(duk_context *ctx, duk_idx_t count);
void aperl_duk_concat(duk_context *ctx, duk_idx_t count) {
    duk_concat(ctx, count);
}

//void duk_config_buffer(duk_context *ctx, duk_idx_t idx, void *ptr, duk_size_t len);
void aperl_duk_config_buffer(duk_context *ctx, duk_idx_t idx, void *ptr, duk_size_t len) {
    duk_config_buffer(ctx, idx, ptr, len);
}

//void duk_copy(duk_context *ctx, duk_idx_t from_idx, duk_idx_t to_idx);
void aperl_duk_copy(duk_context *ctx, duk_idx_t from_idx, duk_idx_t to_idx) {
    duk_copy(ctx, from_idx, to_idx);
}

//void duk_decode_string(duk_context *ctx, duk_idx_t idx, duk_decode_char_function callback, void *udata);
void aperl_duk_decode_string(duk_context *ctx, duk_idx_t idx, duk_decode_char_function callback, void *udata) {
    duk_decode_string(ctx, idx, callback, udata);
}

//void duk_def_prop(duk_context *ctx, duk_idx_t obj_idx, duk_uint_t flags);
void aperl_duk_def_prop(duk_context *ctx, duk_idx_t obj_idx, duk_uint_t flags) {
    duk_def_prop(ctx, obj_idx, flags);
}

//duk_bool_t duk_del_prop(duk_context *ctx, duk_idx_t obj_idx);
duk_bool_t aperl_duk_del_prop(duk_context *ctx, duk_idx_t obj_idx) {
    duk_bool_t ret = duk_del_prop(ctx, obj_idx);
    return ret;
}

//duk_bool_t duk_del_prop_heapptr(duk_context *ctx, duk_idx_t obj_idx, void *ptr);
duk_bool_t aperl_duk_del_prop_heapptr(duk_context *ctx, duk_idx_t obj_idx, void *ptr) {
    duk_bool_t ret = duk_del_prop_heapptr(ctx, obj_idx, ptr);
    return ret;
}

//duk_bool_t duk_del_prop_index(duk_context *ctx, duk_idx_t obj_idx, duk_uarridx_t arr_idx);
duk_bool_t aperl_duk_del_prop_index(duk_context *ctx, duk_idx_t obj_idx, duk_uarridx_t arr_idx) {
    duk_bool_t ret = duk_del_prop_index(ctx, obj_idx, arr_idx);
    return ret;
}

//duk_bool_t duk_del_prop_literal(duk_context *ctx, duk_idx_t obj_idx, const char *key_literal);
duk_bool_t aperl_duk_del_prop_literal(duk_context *ctx, duk_idx_t obj_idx, const char *key_literal) {
    duk_bool_t ret = duk_del_prop_literal(ctx, obj_idx, key_literal);
    return ret;
}

//duk_bool_t duk_del_prop_lstring(duk_context *ctx, duk_idx_t obj_idx, const char *key, duk_size_t key_len);
duk_bool_t aperl_duk_del_prop_lstring(duk_context *ctx, duk_idx_t obj_idx, const char *key, duk_size_t key_len) {
    duk_bool_t ret = duk_del_prop_lstring(ctx, obj_idx, key, key_len);
    return ret;
}

//duk_bool_t duk_del_prop_string(duk_context *ctx, duk_idx_t obj_idx, const char *key);
duk_bool_t aperl_duk_del_prop_string(duk_context *ctx, duk_idx_t obj_idx, const char *key) {
    duk_bool_t ret = duk_del_prop_string(ctx, obj_idx, key);
    return ret;
}

//void duk_destroy_heap(duk_context *ctx);
void aperl_duk_destroy_heap(duk_context *ctx) {
    duk_destroy_heap(ctx);
}

//void duk_dump_function(duk_context *ctx);
void aperl_duk_dump_function(duk_context *ctx) {
    duk_dump_function(ctx);
}

//void duk_dup(duk_context *ctx, duk_idx_t from_idx);
void aperl_duk_dup(duk_context *ctx, duk_idx_t from_idx) {
    duk_dup(ctx, from_idx);
}

//void duk_dup_top(duk_context *ctx);
void aperl_duk_dup_top(duk_context *ctx) {
    duk_dup_top(ctx);
}

//void duk_enum(duk_context *ctx, duk_idx_t obj_idx, duk_uint_t enum_flags);
void aperl_duk_enum(duk_context *ctx, duk_idx_t obj_idx, duk_uint_t enum_flags) {
    duk_enum(ctx, obj_idx, enum_flags);
}

//duk_bool_t duk_equals(duk_context *ctx, duk_idx_t idx1, duk_idx_t idx2);
duk_bool_t aperl_duk_equals(duk_context *ctx, duk_idx_t idx1, duk_idx_t idx2) {
    duk_bool_t ret = duk_equals(ctx, idx1, idx2);
    return ret;
}

//duk_ret_t duk_error_va(duk_context *ctx, duk_errcode_t err_code, const char *fmt, va_list ap);
duk_ret_t aperl_duk_error_va(duk_context *ctx, duk_errcode_t err_code, const char *fmt, va_list ap) {
    duk_ret_t ret = duk_error_va(ctx, err_code, fmt, ap);
    return ret;
}

//void duk_eval(duk_context *ctx);
void aperl_duk_eval(duk_context *ctx) {
    duk_eval(ctx);
}

//duk_ret_t duk_eval_error_va(duk_context *ctx, const char *fmt, va_list ap);
duk_ret_t aperl_duk_eval_error_va(duk_context *ctx, const char *fmt, va_list ap) {
    duk_ret_t ret = duk_eval_error_va(ctx, fmt, ap);
    return ret;
}

//void duk_eval_lstring(duk_context *ctx, const char *src, duk_size_t len);
void aperl_duk_eval_lstring(duk_context *ctx, const char *src, duk_size_t len) {
    duk_eval_lstring(ctx, src, len);
}

//void duk_eval_lstring_noresult(duk_context *ctx, const char *src, duk_size_t len);
void aperl_duk_eval_lstring_noresult(duk_context *ctx, const char *src, duk_size_t len) {
    duk_eval_lstring_noresult(ctx, src, len);
}

//void duk_eval_noresult(duk_context *ctx);
void aperl_duk_eval_noresult(duk_context *ctx) {
    duk_eval_noresult(ctx);
}

//void duk_eval_string(duk_context *ctx, const char *src);
void aperl_duk_eval_string(duk_context *ctx, const char *src) {
    duk_eval_string(ctx, src);
}

//void duk_eval_string_noresult(duk_context *ctx, const char *src);
void aperl_duk_eval_string_noresult(duk_context *ctx, const char *src) {
    duk_eval_string_noresult(ctx, src);
}

//duk_ret_t duk_fatal(duk_context *ctx, const char *err_msg);
duk_ret_t aperl_duk_fatal(duk_context *ctx, const char *err_msg) {
    duk_ret_t ret = duk_fatal(ctx, err_msg);
    return ret;
}

//void duk_free(duk_context *ctx, void *ptr);
void aperl_duk_free(duk_context *ctx, void *ptr) {
    duk_free(ctx, ptr);
}

//void duk_free_raw(duk_context *ctx, void *ptr);
void aperl_duk_free_raw(duk_context *ctx, void *ptr) {
    duk_free_raw(ctx, ptr);
}

//void duk_freeze(duk_context *ctx, duk_idx_t obj_idx);
void aperl_duk_freeze(duk_context *ctx, duk_idx_t obj_idx) {
    duk_freeze(ctx, obj_idx);
}

//void duk_gc(duk_context *ctx, duk_uint_t flags);
void aperl_duk_gc(duk_context *ctx, duk_uint_t flags) {
    duk_gc(ctx, flags);
}

//duk_ret_t duk_generic_error_va(duk_context *ctx, const char *fmt, va_list ap);
duk_ret_t aperl_duk_generic_error_va(duk_context *ctx, const char *fmt, va_list ap) {
    duk_ret_t ret = duk_generic_error_va(ctx, fmt, ap);
    return ret;
}

//duk_bool_t duk_get_boolean(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_get_boolean(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_get_boolean(ctx, idx);
    return ret;
}

//duk_bool_t duk_get_boolean_default(duk_context *ctx, duk_idx_t idx, duk_bool_t def_value);
duk_bool_t aperl_duk_get_boolean_default(duk_context *ctx, duk_idx_t idx, duk_bool_t def_value) {
    duk_bool_t ret = duk_get_boolean_default(ctx, idx, def_value);
    return ret;
}

//void *duk_get_buffer(duk_context *ctx, duk_idx_t idx, duk_size_t *out_size);
void *aperl_duk_get_buffer(duk_context *ctx, duk_idx_t idx, SV *out_len) {
    duk_size_t sz;
    void *ret = duk_get_buffer(ctx, idx, &sz);
    sv_setnv(out_len, sz);
    return ret;
}

//void *duk_get_buffer_data(duk_context *ctx, duk_idx_t idx, duk_size_t *out_size);
void *aperl_duk_get_buffer_data(duk_context *ctx, duk_idx_t idx, SV *out_len) {
    duk_size_t sz;
    void *ret = duk_get_buffer_data(ctx, idx, &sz);
    sv_setnv(out_len, sz);
    return ret;
}

//void *duk_get_buffer_data_default(duk_context *ctx, duk_idx_t idx, duk_size_t *out_size, void *def_ptr, duk_size_t def_len);
void *aperl_duk_get_buffer_data_default(duk_context *ctx, duk_idx_t idx, SV *out_len, void *def_ptr, duk_size_t def_len) {
    duk_size_t sz;
    void *ret = duk_get_buffer_data_default(ctx, idx, &sz, def_ptr, def_len);
    sv_setnv(out_len, sz);
    return ret;
}

//void *duk_get_buffer_default(duk_context *ctx, duk_idx_t idx, duk_size_t *out_size, void *def_ptr, duk_size_t def_len);
void *aperl_duk_get_buffer_default(duk_context *ctx, duk_idx_t idx, SV *out_len, void *def_ptr, duk_size_t def_len) {
    duk_size_t sz;
    void *ret = duk_get_buffer_default(ctx, idx, &sz, def_ptr, def_len);
    sv_setnv(out_len, sz);
    return ret;
}

//duk_c_function duk_get_c_function(duk_context *ctx, duk_idx_t idx);
duk_c_function aperl_duk_get_c_function(duk_context *ctx, duk_idx_t idx) {
    duk_c_function ret = duk_get_c_function(ctx, idx);
    return ret;
}

//duk_c_function duk_get_c_function_default(duk_context *ctx, duk_idx_t idx, duk_c_function def_value);
duk_c_function aperl_duk_get_c_function_default(duk_context *ctx, duk_idx_t idx, duk_c_function def_value) {
    duk_c_function ret = duk_get_c_function_default(ctx, idx, def_value);
    return ret;
}

//duk_context *duk_get_context(duk_context *ctx, duk_idx_t idx);
duk_context *aperl_duk_get_context(duk_context *ctx, duk_idx_t idx) {
    duk_context *ret = duk_get_context(ctx, idx);
    return ret;
}

//duk_context *duk_get_context_default(duk_context *ctx, duk_idx_t idx, duk_context *def_value);
duk_context *aperl_duk_get_context_default(duk_context *ctx, duk_idx_t idx, duk_context *def_value) {
    duk_context *ret = duk_get_context_default(ctx, idx, def_value);
    return ret;
}

//duk_int_t duk_get_current_magic(duk_context *ctx);
duk_int_t aperl_duk_get_current_magic(duk_context *ctx) {
    duk_int_t ret = duk_get_current_magic(ctx);
    return ret;
}

//duk_errcode_t duk_get_error_code(duk_context *ctx, duk_idx_t idx);
duk_errcode_t aperl_duk_get_error_code(duk_context *ctx, duk_idx_t idx) {
    duk_errcode_t ret = duk_get_error_code(ctx, idx);
    return ret;
}

//void duk_get_finalizer(duk_context *ctx, duk_idx_t idx);
void aperl_duk_get_finalizer(duk_context *ctx, duk_idx_t idx) {
    duk_get_finalizer(ctx, idx);
}

//duk_bool_t duk_get_global_heapptr(duk_context *ctx, void *ptr);
duk_bool_t aperl_duk_get_global_heapptr(duk_context *ctx, void *ptr) {
    duk_bool_t ret = duk_get_global_heapptr(ctx, ptr);
    return ret;
}

//duk_bool_t duk_get_global_literal(duk_context *ctx, const char *key_literal);
duk_bool_t aperl_duk_get_global_literal(duk_context *ctx, const char *key_literal) {
    duk_bool_t ret = duk_get_global_literal(ctx, key_literal);
    return ret;
}

//duk_bool_t duk_get_global_lstring(duk_context *ctx, const char *key, duk_size_t key_len);
duk_bool_t aperl_duk_get_global_lstring(duk_context *ctx, const char *key, duk_size_t key_len) {
    duk_bool_t ret = duk_get_global_lstring(ctx, key, key_len);
    return ret;
}

//duk_bool_t duk_get_global_string(duk_context *ctx, const char *key);
duk_bool_t aperl_duk_get_global_string(duk_context *ctx, const char *key) {
    duk_bool_t ret = duk_get_global_string(ctx, key);
    return ret;
}

//void *duk_get_heapptr(duk_context *ctx, duk_idx_t idx);
void *aperl_duk_get_heapptr(duk_context *ctx, duk_idx_t idx) {
    void *ret = duk_get_heapptr(ctx, idx);
    return ret;
}

//void *duk_get_heapptr_default(duk_context *ctx, duk_idx_t idx, void *def_value);
void *aperl_duk_get_heapptr_default(duk_context *ctx, duk_idx_t idx, void *def_value) {
    void *ret = duk_get_heapptr_default(ctx, idx, def_value);
    return ret;
}

//duk_int_t duk_get_int(duk_context *ctx, duk_idx_t idx);
duk_int_t aperl_duk_get_int(duk_context *ctx, duk_idx_t idx) {
    duk_int_t ret = duk_get_int(ctx, idx);
    return ret;
}

//duk_int_t duk_get_int_default(duk_context *ctx, duk_idx_t idx, duk_int_t def_value);
duk_int_t aperl_duk_get_int_default(duk_context *ctx, duk_idx_t idx, duk_int_t def_value) {
    duk_int_t ret = duk_get_int_default(ctx, idx, def_value);
    return ret;
}

//duk_size_t duk_get_length(duk_context *ctx, duk_idx_t idx);
duk_size_t aperl_duk_get_length(duk_context *ctx, duk_idx_t idx) {
    duk_size_t ret = duk_get_length(ctx, idx);
    return ret;
}

//const char *duk_get_lstring(duk_context *ctx, duk_idx_t idx, duk_size_t *out_len);
const char *aperl_duk_get_lstring(duk_context *ctx, duk_idx_t idx, SV *out_len) {
    duk_size_t sz;
    const char *ret = duk_get_lstring(ctx, idx, &sz);
    sv_setnv(out_len, sz);
    return ret;
}

//const char *duk_get_lstring_default(duk_context *ctx, duk_idx_t idx, duk_size_t *out_len, const char *def_ptr, duk_size_t def_len);
const char *aperl_duk_get_lstring_default(duk_context *ctx, duk_idx_t idx, SV *out_len, const char *def_ptr, duk_size_t def_len) {
    duk_size_t sz;
    const char *ret = duk_get_lstring_default(ctx, idx, &sz, def_ptr, def_len);
    sv_setnv(out_len, sz);
    return ret;
}

//duk_int_t duk_get_magic(duk_context *ctx, duk_idx_t idx);
duk_int_t aperl_duk_get_magic(duk_context *ctx, duk_idx_t idx) {
    duk_int_t ret = duk_get_magic(ctx, idx);
    return ret;
}

//void duk_get_memory_functions(duk_context *ctx, duk_memory_functions *out_funcs);
void aperl_duk_get_memory_functions(duk_context *ctx, duk_memory_functions *out_funcs) {
    duk_get_memory_functions(ctx, out_funcs);
}

//duk_double_t duk_get_now(duk_context *ctx);
duk_double_t aperl_duk_get_now(duk_context *ctx) {
    duk_double_t ret = duk_get_now(ctx);
    return ret;
}

//duk_double_t duk_get_number(duk_context *ctx, duk_idx_t idx);
duk_double_t aperl_duk_get_number(duk_context *ctx, duk_idx_t idx) {
    duk_double_t ret = duk_get_number(ctx, idx);
    return ret;
}

//duk_double_t duk_get_number_default(duk_context *ctx, duk_idx_t idx, duk_double_t def_value);
duk_double_t aperl_duk_get_number_default(duk_context *ctx, duk_idx_t idx, duk_double_t def_value) {
    duk_double_t ret = duk_get_number_default(ctx, idx, def_value);
    return ret;
}

//void *duk_get_pointer(duk_context *ctx, duk_idx_t idx);
void *aperl_duk_get_pointer(duk_context *ctx, duk_idx_t idx) {
    void *ret = duk_get_pointer(ctx, idx);
    return ret;
}

//void *duk_get_pointer_default(duk_context *ctx, duk_idx_t idx, void *def_value);
void *aperl_duk_get_pointer_default(duk_context *ctx, duk_idx_t idx, void *def_value) {
    void *ret = duk_get_pointer_default(ctx, idx, def_value);
    return ret;
}

//duk_bool_t duk_get_prop(duk_context *ctx, duk_idx_t obj_idx);
duk_bool_t aperl_duk_get_prop(duk_context *ctx, duk_idx_t obj_idx) {
    duk_bool_t ret = duk_get_prop(ctx, obj_idx);
    return ret;
}

//void duk_get_prop_desc(duk_context *ctx, duk_idx_t obj_idx, duk_uint_t flags);
void aperl_duk_get_prop_desc(duk_context *ctx, duk_idx_t obj_idx, duk_uint_t flags) {
    duk_get_prop_desc(ctx, obj_idx, flags);
}

//duk_bool_t duk_get_prop_heapptr(duk_context *ctx, duk_idx_t obj_idx, void *ptr);
duk_bool_t aperl_duk_get_prop_heapptr(duk_context *ctx, duk_idx_t obj_idx, void *ptr) {
    duk_bool_t ret = duk_get_prop_heapptr(ctx, obj_idx, ptr);
    return ret;
}

//duk_bool_t duk_get_prop_index(duk_context *ctx, duk_idx_t obj_idx, duk_uarridx_t arr_idx);
duk_bool_t aperl_duk_get_prop_index(duk_context *ctx, duk_idx_t obj_idx, duk_uarridx_t arr_idx) {
    duk_bool_t ret = duk_get_prop_index(ctx, obj_idx, arr_idx);
    return ret;
}

//duk_bool_t duk_get_prop_literal(duk_context *ctx, const char *key_literal);
duk_bool_t aperl_duk_get_prop_literal(duk_context *ctx, duk_idx_t obj_idx, const char *key_literal) {
    duk_bool_t ret = duk_get_prop_literal(ctx, obj_idx, key_literal);
    return ret;
}

//duk_bool_t duk_get_prop_lstring(duk_context *ctx, duk_idx_t obj_idx, const char *key, duk_size_t key_len);
duk_bool_t aperl_duk_get_prop_lstring(duk_context *ctx, duk_idx_t obj_idx, const char *key, duk_size_t key_len) {
    duk_bool_t ret = duk_get_prop_lstring(ctx, obj_idx, key, key_len);
    return ret;
}

//duk_bool_t duk_get_prop_string(duk_context *ctx, duk_idx_t obj_idx, const char *key);
duk_bool_t aperl_duk_get_prop_string(duk_context *ctx, duk_idx_t obj_idx, const char *key) {
    duk_bool_t ret = duk_get_prop_string(ctx, obj_idx, key);
    return ret;
}

//void duk_get_prototype(duk_context *ctx, duk_idx_t idx);
void aperl_duk_get_prototype(duk_context *ctx, duk_idx_t idx) {
    duk_get_prototype(ctx, idx);
}

//const char *duk_get_string(duk_context *ctx, duk_idx_t idx);
const char *aperl_duk_get_string(duk_context *ctx, duk_idx_t idx) {
    const char *ret = duk_get_string(ctx, idx);
    return ret;
}

//const char *duk_get_string_default(duk_context *ctx, duk_idx_t idx, const char *def_value);
const char *aperl_duk_get_string_default(duk_context *ctx, duk_idx_t idx, const char *def_value) {
    const char *ret = duk_get_string_default(ctx, idx, def_value);
    return ret;
}

//duk_idx_t duk_get_top(duk_context *ctx);
duk_idx_t aperl_duk_get_top(duk_context *ctx) {
    duk_idx_t ret = duk_get_top(ctx);
    return ret;
}

//duk_idx_t duk_get_top_index(duk_context *ctx);
duk_idx_t aperl_duk_get_top_index(duk_context *ctx) {
    duk_idx_t ret = duk_get_top_index(ctx);
    return ret;
}

//duk_int_t duk_get_type(duk_context *ctx, duk_idx_t idx);
duk_int_t aperl_duk_get_type(duk_context *ctx, duk_idx_t idx) {
    duk_int_t ret = duk_get_type(ctx, idx);
    return ret;
}

//duk_uint_t duk_get_type_mask(duk_context *ctx, duk_idx_t idx);
duk_uint_t aperl_duk_get_type_mask(duk_context *ctx, duk_idx_t idx) {
    duk_uint_t ret = duk_get_type_mask(ctx, idx);
    return ret;
}

//duk_uint_t duk_get_uint(duk_context *ctx, duk_idx_t idx);
duk_uint_t aperl_duk_get_uint(duk_context *ctx, duk_idx_t idx) {
    duk_uint_t ret = duk_get_uint(ctx, idx);
    return ret;
}

//duk_uint_t duk_get_uint_default(duk_context *ctx, duk_idx_t idx, duk_uint_t def_value);
duk_uint_t aperl_duk_get_uint_default(duk_context *ctx, duk_idx_t idx, duk_uint_t def_value) {
    duk_uint_t ret = duk_get_uint_default(ctx, idx, def_value);
    return ret;
}

//duk_bool_t duk_has_prop(duk_context *ctx, duk_idx_t obj_idx);
duk_bool_t aperl_duk_has_prop(duk_context *ctx, duk_idx_t obj_idx) {
    duk_bool_t ret = duk_has_prop(ctx, obj_idx);
    return ret;
}

//duk_bool_t duk_has_prop_heapptr(duk_context *ctx, duk_idx_t obj_idx, void *ptr);
duk_bool_t aperl_duk_has_prop_heapptr(duk_context *ctx, duk_idx_t obj_idx, void *ptr) {
    duk_bool_t ret = duk_has_prop_heapptr(ctx, obj_idx, ptr);
    return ret;
}

//duk_bool_t duk_has_prop_index(duk_context *ctx, duk_idx_t obj_idx, duk_uarridx_t arr_idx);
duk_bool_t aperl_duk_has_prop_index(duk_context *ctx, duk_idx_t obj_idx, duk_uarridx_t arr_idx) {
    duk_bool_t ret = duk_has_prop_index(ctx, obj_idx, arr_idx);
    return ret;
}

//duk_bool_t duk_has_prop_literal(duk_context *ctx, duk_idx_t obj_idx, const char *key_literal);
duk_bool_t aperl_duk_has_prop_literal(duk_context *ctx, duk_idx_t obj_idx, const char *key_literal) {
    duk_bool_t ret = duk_has_prop_literal(ctx, obj_idx, key_literal);
    return ret;
}

//duk_bool_t duk_has_prop_lstring(duk_context *ctx, duk_idx_t obj_idx, const char *key, duk_size_t key_len);
duk_bool_t aperl_duk_has_prop_lstring(duk_context *ctx, duk_idx_t obj_idx, const char *key, duk_size_t key_len) {
    duk_bool_t ret = duk_has_prop_lstring(ctx, obj_idx, key, key_len);
    return ret;
}

//duk_bool_t duk_has_prop_string(duk_context *ctx, duk_idx_t obj_idx, const char *key);
duk_bool_t aperl_duk_has_prop_string(duk_context *ctx, duk_idx_t obj_idx, const char *key) {
    duk_bool_t ret = duk_has_prop_string(ctx, obj_idx, key);
    return ret;
}

//void duk_hex_decode(duk_context *ctx, duk_idx_t idx);
void aperl_duk_hex_decode(duk_context *ctx, duk_idx_t idx) {
    duk_hex_decode(ctx, idx);
}

//const char *duk_hex_encode(duk_context *ctx, duk_idx_t idx);
const char *aperl_duk_hex_encode(duk_context *ctx, duk_idx_t idx) {
    const char *ret = duk_hex_encode(ctx, idx);
    return ret;
}

//void duk_insert(duk_context *ctx, duk_idx_t to_idx);
void aperl_duk_insert(duk_context *ctx, duk_idx_t to_idx) {
    duk_insert(ctx, to_idx);
}

//void duk_inspect_callstack_entry(duk_context *ctx, duk_int_t level);
void aperl_duk_inspect_callstack_entry(duk_context *ctx, duk_int_t level) {
    duk_inspect_callstack_entry(ctx, level);
}

//void duk_inspect_value(duk_context *ctx, duk_idx_t idx);
void aperl_duk_inspect_value(duk_context *ctx, duk_idx_t idx) {
    duk_inspect_value(ctx, idx);
}

//duk_bool_t duk_instanceof(duk_context *ctx, duk_idx_t idx1, duk_idx_t idx2);
duk_bool_t aperl_duk_instanceof(duk_context *ctx, duk_idx_t idx1, duk_idx_t idx2) {
    duk_bool_t ret = duk_instanceof(ctx, idx1, idx2);
    return ret;
}

//duk_bool_t duk_is_array(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_array(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_array(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_boolean(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_boolean(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_boolean(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_bound_function(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_bound_function(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_bound_function(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_buffer(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_buffer(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_buffer(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_buffer_data(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_buffer_data(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_buffer_data(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_c_function(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_c_function(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_c_function(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_callable(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_callable(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_callable(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_constructable(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_constructable(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_constructable(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_constructor_call(duk_context *ctx);
duk_bool_t aperl_duk_is_constructor_call(duk_context *ctx) {
    duk_bool_t ret = duk_is_constructor_call(ctx);
    return ret;
}

//duk_bool_t duk_is_dynamic_buffer(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_dynamic_buffer(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_dynamic_buffer(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_ecmascript_function(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_ecmascript_function(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_ecmascript_function(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_error(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_error(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_error(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_eval_error(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_eval_error(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_eval_error(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_fixed_buffer(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_fixed_buffer(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_fixed_buffer(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_function(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_function(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_function(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_lightfunc(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_lightfunc(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_lightfunc(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_nan(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_nan(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_nan(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_null(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_null(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_null(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_null_or_undefined(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_null_or_undefined(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_null_or_undefined(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_number(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_number(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_number(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_object(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_object(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_object(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_object_coercible(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_object_coercible(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_object_coercible(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_pointer(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_pointer(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_pointer(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_primitive(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_primitive(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_primitive(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_range_error(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_range_error(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_range_error(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_reference_error(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_reference_error(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_reference_error(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_strict_call(duk_context *ctx);
duk_bool_t aperl_duk_is_strict_call(duk_context *ctx) {
    duk_bool_t ret = duk_is_strict_call(ctx);
    return ret;
}

//duk_bool_t duk_is_string(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_string(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_string(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_symbol(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_symbol(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_symbol(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_syntax_error(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_syntax_error(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_syntax_error(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_thread(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_thread(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_thread(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_type_error(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_type_error(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_type_error(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_undefined(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_undefined(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_undefined(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_uri_error(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_uri_error(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_uri_error(ctx, idx);
    return ret;
}

//duk_bool_t duk_is_valid_index(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_is_valid_index(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_is_valid_index(ctx, idx);
    return ret;
}

//void duk_join(duk_context *ctx, duk_idx_t count);
void aperl_duk_join(duk_context *ctx, duk_idx_t count) {
    duk_join(ctx, count);
}

//void duk_json_decode(duk_context *ctx, duk_idx_t idx);
void aperl_duk_json_decode(duk_context *ctx, duk_idx_t idx) {
    duk_json_decode(ctx, idx);
}

//const char *duk_json_encode(duk_context *ctx, duk_idx_t idx);
const char *aperl_duk_json_encode(duk_context *ctx, duk_idx_t idx) {
    const char *ret = duk_json_encode(ctx, idx);
    return ret;
}

//void duk_load_function(duk_context *ctx);
void aperl_duk_load_function(duk_context *ctx) {
    duk_load_function(ctx);
}

//void duk_map_string(duk_context *ctx, duk_idx_t idx, duk_map_char_function callback, void *udata);
void aperl_duk_map_string(duk_context *ctx, duk_idx_t idx, duk_map_char_function callback, void *udata) {
    duk_map_string(ctx, idx, callback, udata);
}

//void duk_new(duk_context *ctx, duk_idx_t nargs);
void aperl_duk_new(duk_context *ctx, duk_idx_t nargs) {
    duk_new(ctx, nargs);
}

//duk_bool_t duk_next(duk_context *ctx, duk_idx_t enum_idx, duk_bool_t get_value);
duk_bool_t aperl_duk_next(duk_context *ctx, duk_idx_t enum_idx, duk_bool_t get_value) {
    duk_bool_t ret = duk_next(ctx, enum_idx, get_value);
    return ret;
}

//duk_idx_t duk_normalize_index(duk_context *ctx, duk_idx_t idx);
duk_idx_t aperl_duk_normalize_index(duk_context *ctx, duk_idx_t idx) {
    duk_idx_t ret = duk_normalize_index(ctx, idx);
    return ret;
}

//duk_bool_t duk_opt_boolean(duk_context *ctx, duk_idx_t idx, duk_bool_t def_value);
duk_bool_t aperl_duk_opt_boolean(duk_context *ctx, duk_idx_t idx, duk_bool_t def_value) {
    duk_bool_t ret = duk_opt_boolean(ctx, idx, def_value);
    return ret;
}

//void *duk_opt_buffer(duk_context *ctx, duk_idx_t idx, duk_size_t *out_size, void *def_ptr, duk_size_t def_len);
void *aperl_duk_opt_buffer(duk_context *ctx, duk_idx_t idx, SV *out_len, void *def_ptr, duk_size_t def_len) {
    duk_size_t sz;
    void *ret = duk_opt_buffer(ctx, idx, &sz, def_ptr, def_len);
    sv_setnv(out_len, sz);
    return ret;
}

//void *duk_opt_buffer_data(duk_context *ctx, duk_idx_t idx, duk_size_t *out_size, void *def_ptr, duk_size_t def_len);
void *aperl_duk_opt_buffer_data(duk_context *ctx, duk_idx_t idx, SV *out_len, void *def_ptr, duk_size_t def_len) {
    duk_size_t sz;
    void *ret = duk_opt_buffer_data(ctx, idx, &sz, def_ptr, def_len);
    sv_setnv(out_len, sz);
    return ret;
}

//duk_c_function duk_opt_c_function(duk_context *ctx, duk_idx_t idx, duk_c_function def_value);
duk_c_function aperl_duk_opt_c_function(duk_context *ctx, duk_idx_t idx, duk_c_function def_value) {
    duk_c_function ret = duk_opt_c_function(ctx, idx, def_value);
    return ret;
}

//duk_context *duk_opt_context(duk_context *ctx, duk_idx_t idx, duk_context *def_value);
duk_context *aperl_duk_opt_context(duk_context *ctx, duk_idx_t idx, duk_context *def_value) {
    duk_context *ret = duk_opt_context(ctx, idx, def_value);
    return ret;
}

//void *duk_opt_heapptr(duk_context *ctx, duk_idx_t idx, void *def_value);
void *aperl_duk_opt_heapptr(duk_context *ctx, duk_idx_t idx, void *def_value) {
    void *ret = duk_opt_heapptr(ctx, idx, def_value);
    return ret;
}

//duk_int_t duk_opt_int(duk_context *ctx, duk_idx_t idx, duk_int_t def_value);
duk_int_t aperl_duk_opt_int(duk_context *ctx, duk_idx_t idx, duk_int_t def_value) {
    duk_int_t ret = duk_opt_int(ctx, idx, def_value);
    return ret;
}

//const char *duk_opt_lstring(duk_context *ctx, duk_idx_t idx, duk_size_t *out_len, const char *def_ptr, duk_size_t def_len);
const char *aperl_duk_opt_lstring(duk_context *ctx, duk_idx_t idx, SV *out_len, const char *def_ptr, duk_size_t def_len) {
    duk_size_t sz;
    const char *ret = duk_opt_lstring(ctx, idx, &sz, def_ptr, def_len);
    sv_setnv(out_len, sz);
    return ret;
}

//duk_double_t duk_opt_number(duk_context *ctx, duk_idx_t idx, duk_double_t def_value);
duk_double_t aperl_duk_opt_number(duk_context *ctx, duk_idx_t idx, duk_double_t def_value) {
    duk_double_t ret = duk_opt_number(ctx, idx, def_value);
    return ret;
}

//void *duk_opt_pointer(duk_context *ctx, duk_idx_t idx, void *def_value);
void *aperl_duk_opt_pointer(duk_context *ctx, duk_idx_t idx, void *def_value) {
    void *ret = duk_opt_pointer(ctx, idx, def_value);
    return ret;
}

//const char *duk_opt_string(duk_context *ctx, duk_idx_t idx, const char *def_ptr);
const char *aperl_duk_opt_string(duk_context *ctx, duk_idx_t idx, const char *def_ptr) {
    const char *ret = duk_opt_string(ctx, idx, def_ptr);
    return ret;
}

//duk_uint_t duk_opt_uint(duk_context *ctx, duk_idx_t idx, duk_uint_t def_value);
duk_uint_t aperl_duk_opt_uint(duk_context *ctx, duk_idx_t idx, duk_uint_t def_value) {
    duk_uint_t ret = duk_opt_uint(ctx, idx, def_value);
    return ret;
}

//duk_int_t duk_pcall(duk_context *ctx, duk_idx_t nargs);
duk_int_t aperl_duk_pcall(duk_context *ctx, duk_idx_t nargs) {
    duk_int_t ret = duk_pcall(ctx, nargs);
    return ret;
}

//duk_int_t duk_pcall_method(duk_context *ctx, duk_idx_t nargs);
duk_int_t aperl_duk_pcall_method(duk_context *ctx, duk_idx_t nargs) {
    duk_int_t ret = duk_pcall_method(ctx, nargs);
    return ret;
}

//duk_int_t duk_pcall_prop(duk_context *ctx, duk_idx_t obj_idx, duk_idx_t nargs);
duk_int_t aperl_duk_pcall_prop(duk_context *ctx, duk_idx_t obj_idx, duk_idx_t nargs) {
    duk_int_t ret = duk_pcall_prop(ctx, obj_idx, nargs);
    return ret;
}

//duk_int_t duk_pcompile(duk_context *ctx, duk_uint_t flags);
duk_int_t aperl_duk_pcompile(duk_context *ctx, duk_uint_t flags) {
    duk_int_t ret = duk_pcompile(ctx, flags);
    return ret;
}

//duk_int_t duk_pcompile_lstring(duk_context *ctx, duk_uint_t flags, const char *src, duk_size_t len);
duk_int_t aperl_duk_pcompile_lstring(duk_context *ctx, duk_uint_t flags, const char *src, duk_size_t len) {
    duk_int_t ret = duk_pcompile_lstring(ctx, flags, src, len);
    return ret;
}

//duk_int_t duk_pcompile_lstring_filename(duk_context *ctx, duk_uint_t flags, const char *src, duk_size_t len);
duk_int_t aperl_duk_pcompile_lstring_filename(duk_context *ctx, duk_uint_t flags, const char *src, duk_size_t len) {
    duk_int_t ret = duk_pcompile_lstring_filename(ctx, flags, src, len);
    return ret;
}

//duk_int_t duk_pcompile_string(duk_context *ctx, duk_uint_t flags, const char *src);
duk_int_t aperl_duk_pcompile_string(duk_context *ctx, duk_uint_t flags, const char *src) {
    duk_int_t ret = duk_pcompile_string(ctx, flags, src);
    return ret;
}

//duk_int_t duk_pcompile_string_filename(duk_context *ctx, duk_uint_t flags, const char *src);
duk_int_t aperl_duk_pcompile_string_filename(duk_context *ctx, duk_uint_t flags, const char *src) {
    duk_int_t ret = duk_pcompile_string_filename(ctx, flags, src);
    return ret;
}

//duk_int_t duk_peval(duk_context *ctx);
duk_int_t aperl_duk_peval(duk_context *ctx) {
    duk_int_t ret = duk_peval(ctx);
    return ret;
}

//duk_int_t duk_peval_lstring(duk_context *ctx, const char *src, duk_size_t len);
duk_int_t aperl_duk_peval_lstring(duk_context *ctx, const char *src, duk_size_t len) {
    duk_int_t ret = duk_peval_lstring(ctx, src, len);
    return ret;
}

//duk_int_t duk_peval_lstring_noresult(duk_context *ctx, const char *src, duk_size_t len);
duk_int_t aperl_duk_peval_lstring_noresult(duk_context *ctx, const char *src, duk_size_t len) {
    duk_int_t ret = duk_peval_lstring_noresult(ctx, src, len);
    return ret;
}

//duk_int_t duk_peval_noresult(duk_context *ctx);
duk_int_t aperl_duk_peval_noresult(duk_context *ctx) {
    duk_int_t ret = duk_peval_noresult(ctx);
    return ret;
}

//duk_int_t duk_peval_string(duk_context *ctx, const char *src);
duk_int_t aperl_duk_peval_string(duk_context *ctx, const char *src) {
    duk_int_t ret = duk_peval_string(ctx, src);
    return ret;
}

//duk_int_t duk_peval_string_noresult(duk_context *ctx, const char *src);
duk_int_t aperl_duk_peval_string_noresult(duk_context *ctx, const char *src) {
    duk_int_t ret = duk_peval_string_noresult(ctx, src);
    return ret;
}

//duk_ret_t duk_pnew(duk_context *ctx, duk_idx_t nargs);
duk_ret_t aperl_duk_pnew(duk_context *ctx, duk_idx_t nargs) {
    duk_ret_t ret = duk_pnew(ctx, nargs);
    return ret;
}

//void duk_pop(duk_context *ctx);
void aperl_duk_pop(duk_context *ctx) {
    duk_pop(ctx);
}

//void duk_pop_2(duk_context *ctx);
void aperl_duk_pop_2(duk_context *ctx) {
    duk_pop_2(ctx);
}

//void duk_pop_3(duk_context *ctx);
void aperl_duk_pop_3(duk_context *ctx) {
    duk_pop_3(ctx);
}

//void duk_pop_n(duk_context *ctx, duk_idx_t count);
void aperl_duk_pop_n(duk_context *ctx, duk_idx_t count) {
    duk_pop_n(ctx, count);
}

//duk_idx_t duk_push_array(duk_context *ctx);
duk_idx_t aperl_duk_push_array(duk_context *ctx) {
    duk_idx_t ret = duk_push_array(ctx);
    return ret;
}

//duk_idx_t duk_push_bare_object(duk_context *ctx);
duk_idx_t aperl_duk_push_bare_object(duk_context *ctx) {
    duk_idx_t ret = duk_push_bare_object(ctx);
    return ret;
}

//void duk_push_boolean(duk_context *ctx, duk_bool_t val);
void aperl_duk_push_boolean(duk_context *ctx, duk_bool_t val) {
    duk_push_boolean(ctx, val);
}

//void *duk_push_buffer(duk_context *ctx, duk_size_t size, duk_bool_t dynamic);
void *aperl_duk_push_buffer(duk_context *ctx, duk_size_t size, duk_bool_t dynamic) {
    void *ret = duk_push_buffer(ctx, size, dynamic);
    return ret;
}

//void duk_push_buffer_object(duk_context *ctx, duk_idx_t idx_buffer, duk_size_t byte_offset, duk_size_t byte_length, duk_uint_t flags);
void aperl_duk_push_buffer_object(duk_context *ctx, duk_idx_t idx_buffer, duk_size_t byte_offset, duk_size_t byte_length, duk_uint_t flags) {
    duk_push_buffer_object(ctx, idx_buffer, byte_offset, byte_length, flags);
}

//duk_idx_t duk_push_c_function(duk_context *ctx, duk_c_function func, duk_idx_t nargs);
duk_idx_t aperl_duk_push_c_function(duk_context *ctx, duk_c_function func, duk_idx_t nargs) {
    duk_idx_t ret = duk_push_c_function(ctx, func, nargs);
    return ret;
}

//duk_idx_t duk_push_c_lightfunc(duk_context *ctx, duk_c_function func, duk_idx_t nargs, duk_idx_t length, duk_int_t magic);
duk_idx_t aperl_duk_push_c_lightfunc(duk_context *ctx, duk_c_function func, duk_idx_t nargs, duk_idx_t length, duk_int_t magic) {
    duk_idx_t ret = duk_push_c_lightfunc(ctx, func, nargs, length, magic);
    return ret;
}

//void duk_push_context_dump(duk_context *ctx);
void aperl_duk_push_context_dump(duk_context *ctx) {
    duk_push_context_dump(ctx);
}

//void duk_push_current_function(duk_context *ctx);
void aperl_duk_push_current_function(duk_context *ctx) {
    duk_push_current_function(ctx);
}

//void duk_push_current_thread(duk_context *ctx);
void aperl_duk_push_current_thread(duk_context *ctx) {
    duk_push_current_thread(ctx);
}

//void *duk_push_dynamic_buffer(duk_context *ctx, duk_size_t size);
void *aperl_duk_push_dynamic_buffer(duk_context *ctx, duk_size_t size) {
    void *ret = duk_push_dynamic_buffer(ctx, size);
    return ret;
}

//duk_idx_t duk_push_error_object_va(duk_context *ctx, duk_errcode_t err_code, const char *fmt, va_list ap);
duk_idx_t aperl_duk_push_error_object_va(duk_context *ctx, duk_errcode_t err_code, const char *fmt, va_list ap) {
    duk_idx_t ret = duk_push_error_object_va(ctx, err_code, fmt, ap);
    return ret;
}

//void duk_push_external_buffer(duk_context *ctx);
void aperl_duk_push_external_buffer(duk_context *ctx) {
    duk_push_external_buffer(ctx);
}

//void duk_push_false(duk_context *ctx);
void aperl_duk_push_false(duk_context *ctx) {
    duk_push_false(ctx);
}

//void *duk_push_fixed_buffer(duk_context *ctx, duk_size_t size);
void *aperl_duk_push_fixed_buffer(duk_context *ctx, duk_size_t size) {
    void *ret = duk_push_fixed_buffer(ctx, size);
    return ret;
}

//void duk_push_global_object(duk_context *ctx);
void aperl_duk_push_global_object(duk_context *ctx) {
    duk_push_global_object(ctx);
}

//void duk_push_global_stash(duk_context *ctx);
void aperl_duk_push_global_stash(duk_context *ctx) {
    duk_push_global_stash(ctx);
}

//void duk_push_heap_stash(duk_context *ctx);
void aperl_duk_push_heap_stash(duk_context *ctx) {
    duk_push_heap_stash(ctx);
}

//duk_idx_t duk_push_heapptr(duk_context *ctx, void *ptr);
duk_idx_t aperl_duk_push_heapptr(duk_context *ctx, void *ptr) {
    duk_idx_t ret = duk_push_heapptr(ctx, ptr);
    return ret;
}

//void duk_push_int(duk_context *ctx, duk_int_t val);
void aperl_duk_push_int(duk_context *ctx, duk_int_t val) {
    duk_push_int(ctx, val);
}

//const char *duk_push_literal(duk_context *ctx, const char *str_literal);
const char *aperl_duk_push_literal(duk_context *ctx, const char *str_literal) {
    const char *ret = duk_push_literal(ctx, str_literal);
    return ret;
}

//const char *duk_push_lstring(duk_context *ctx, const char *str, duk_size_t len);
const char *aperl_duk_push_lstring(duk_context *ctx, const char *str, duk_size_t len) {
    const char *ret = duk_push_lstring(ctx, str, len);
    return ret;
}

//void duk_push_nan(duk_context *ctx);
void aperl_duk_push_nan(duk_context *ctx) {
    duk_push_nan(ctx);
}

//void duk_push_new_target(duk_context *ctx);
void aperl_duk_push_new_target(duk_context *ctx) {
    duk_push_new_target(ctx);
}

//void duk_push_null(duk_context *ctx);
void aperl_duk_push_null(duk_context *ctx) {
    duk_push_null(ctx);
}

//void duk_push_number(duk_context *ctx, duk_double_t val);
void aperl_duk_push_number(duk_context *ctx, duk_double_t val) {
    duk_push_number(ctx, val);
}

//duk_idx_t duk_push_object(duk_context *ctx);
duk_idx_t aperl_duk_push_object(duk_context *ctx) {
    duk_idx_t ret = duk_push_object(ctx);
    return ret;
}

//void duk_push_pointer(duk_context *ctx, void *p);
void aperl_duk_push_pointer(duk_context *ctx, void *p) {
    duk_push_pointer(ctx, p);
}

//duk_idx_t duk_push_proxy(duk_context *ctx, duk_uint_t proxy_flags);
duk_idx_t aperl_duk_push_proxy(duk_context *ctx, duk_uint_t proxy_flags) {
    duk_idx_t ret = duk_push_proxy(ctx, proxy_flags);
    return ret;
}

//const char *duk_push_string(duk_context *ctx, const char *str);
const char *aperl_duk_push_string(duk_context *ctx, const char *str) {
    const char *ret = duk_push_string(ctx, str);
    return ret;
}

//void duk_push_this(duk_context *ctx);
void aperl_duk_push_this(duk_context *ctx) {
    duk_push_this(ctx);
}

//duk_idx_t duk_push_thread(duk_context *ctx);
duk_idx_t aperl_duk_push_thread(duk_context *ctx) {
    duk_idx_t ret = duk_push_thread(ctx);
    return ret;
}

//duk_idx_t duk_push_thread_new_globalenv(duk_context *ctx);
duk_idx_t aperl_duk_push_thread_new_globalenv(duk_context *ctx) {
    duk_idx_t ret = duk_push_thread_new_globalenv(ctx);
    return ret;
}

//void duk_push_thread_stash(duk_context *ctx, duk_context *target_ctx);
void aperl_duk_push_thread_stash(duk_context *ctx, duk_context *target_ctx) {
    duk_push_thread_stash(ctx, target_ctx);
}

//void duk_push_true(duk_context *ctx);
void aperl_duk_push_true(duk_context *ctx) {
    duk_push_true(ctx);
}

//void duk_push_uint(duk_context *ctx, duk_uint_t val);
void aperl_duk_push_uint(duk_context *ctx, duk_uint_t val) {
    duk_push_uint(ctx, val);
}

//void duk_push_undefined(duk_context *ctx);
void aperl_duk_push_undefined(duk_context *ctx) {
    duk_push_undefined(ctx);
}

//const char *duk_push_vsprintf(duk_context *ctx, const char *fmt, va_list ap);
const char *aperl_duk_push_vsprintf(duk_context *ctx, const char *fmt, va_list ap) {
    const char *ret = duk_push_vsprintf(ctx, fmt, ap);
    return ret;
}

//void duk_put_function_list(duk_context *ctx, duk_idx_t obj_idx, const duk_function_list_entry *funcs);
void aperl_duk_put_function_list(duk_context *ctx, duk_idx_t obj_idx, const duk_function_list_entry *funcs) {
    duk_put_function_list(ctx, obj_idx, funcs);
}

//duk_bool_t duk_put_global_heapptr(duk_context *ctx, void *ptr);
duk_bool_t aperl_duk_put_global_heapptr(duk_context *ctx, void *ptr) {
    duk_bool_t ret = duk_put_global_heapptr(ctx, ptr);
    return ret;
}

//duk_bool_t duk_put_global_literal(duk_context *ctx, const char *key_literal);
duk_bool_t aperl_duk_put_global_literal(duk_context *ctx, const char *key_literal) {
    duk_bool_t ret = duk_put_global_literal(ctx, key_literal);
    return ret;
}

//duk_bool_t duk_put_global_lstring(duk_context *ctx, const char *key, duk_size_t key_len);
duk_bool_t aperl_duk_put_global_lstring(duk_context *ctx, const char *key, duk_size_t key_len) {
    duk_bool_t ret = duk_put_global_lstring(ctx, key, key_len);
    return ret;
}

//duk_bool_t duk_put_global_string(duk_context *ctx, const char *key);
duk_bool_t aperl_duk_put_global_string(duk_context *ctx, const char *key) {
    duk_bool_t ret = duk_put_global_string(ctx, key);
    return ret;
}

//void duk_put_number_list(duk_context *ctx, duk_idx_t obj_idx, const duk_number_list_entry *numbers);
void aperl_duk_put_number_list(duk_context *ctx, duk_idx_t obj_idx, const duk_number_list_entry *numbers) {
    duk_put_number_list(ctx, obj_idx, numbers);
}

//duk_bool_t duk_put_prop(duk_context *ctx, duk_idx_t obj_idx);
duk_bool_t aperl_duk_put_prop(duk_context *ctx, duk_idx_t obj_idx) {
    duk_bool_t ret = duk_put_prop(ctx, obj_idx);
    return ret;
}

//duk_bool_t duk_put_prop_heapptr(duk_context *ctx, duk_idx_t obj_idx, void *ptr);
duk_bool_t aperl_duk_put_prop_heapptr(duk_context *ctx, duk_idx_t obj_idx, void *ptr) {
    duk_bool_t ret = duk_put_prop_heapptr(ctx, obj_idx, ptr);
    return ret;
}

//duk_bool_t duk_put_prop_index(duk_context *ctx, duk_idx_t obj_idx, duk_uarridx_t arr_idx);
duk_bool_t aperl_duk_put_prop_index(duk_context *ctx, duk_idx_t obj_idx, duk_uarridx_t arr_idx) {
    duk_bool_t ret = duk_put_prop_index(ctx, obj_idx, arr_idx);
    return ret;
}

//duk_bool_t duk_put_prop_literal(duk_context *ctx, duk_idx_t obj_idx, const char *key_literal);
duk_bool_t aperl_duk_put_prop_literal(duk_context *ctx, duk_idx_t obj_idx, const char *key_literal) {
    duk_bool_t ret = duk_put_prop_literal(ctx, obj_idx, key_literal);
    return ret;
}

//duk_bool_t duk_put_prop_lstring(duk_context *ctx, duk_idx_t obj_idx, const char *key, duk_size_t key_len);
duk_bool_t aperl_duk_put_prop_lstring(duk_context *ctx, duk_idx_t obj_idx, const char *key, duk_size_t key_len) {
    duk_bool_t ret = duk_put_prop_lstring(ctx, obj_idx, key, key_len);
    return ret;
}

//duk_bool_t duk_put_prop_string(duk_context *ctx, duk_idx_t obj_idx, const char *key);
duk_bool_t aperl_duk_put_prop_string(duk_context *ctx, duk_idx_t obj_idx, const char *key) {
    duk_bool_t ret = duk_put_prop_string(ctx, obj_idx, key);
    return ret;
}

//duk_double_t duk_random(duk_context *ctx);
duk_double_t aperl_duk_random(duk_context *ctx) {
    duk_double_t ret = duk_random(ctx);
    return ret;
}

//duk_ret_t duk_range_error_va(duk_context *ctx, const char *fmt, va_list ap);
duk_ret_t aperl_duk_range_error_va(duk_context *ctx, const char *fmt, va_list ap) {
    duk_ret_t ret = duk_range_error_va(ctx, fmt, ap);
    return ret;
}

//void *duk_realloc(duk_context *ctx, void *ptr, duk_size_t size);
void *aperl_duk_realloc(duk_context *ctx, void *ptr, duk_size_t size) {
    void *ret = duk_realloc(ctx, ptr, size);
    return ret;
}

//void *duk_realloc_raw(duk_context *ctx, void *ptr, duk_size_t size);
void *aperl_duk_realloc_raw(duk_context *ctx, void *ptr, duk_size_t size) {
    void *ret = duk_realloc_raw(ctx, ptr, size);
    return ret;
}

//duk_ret_t duk_reference_error_va(duk_context *ctx, const char *fmt, va_list ap);
duk_ret_t aperl_duk_reference_error_va(duk_context *ctx, const char *fmt, va_list ap) {
    duk_ret_t ret = duk_reference_error_va(ctx, fmt, ap);
    return ret;
}

//void duk_remove(duk_context *ctx, duk_idx_t idx);
void aperl_duk_remove(duk_context *ctx, duk_idx_t idx) {
    duk_remove(ctx, idx);
}

//void duk_replace(duk_context *ctx, duk_idx_t to_idx);
void aperl_duk_replace(duk_context *ctx, duk_idx_t to_idx) {
    duk_replace(ctx, to_idx);
}

//duk_bool_t duk_require_boolean(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_require_boolean(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_require_boolean(ctx, idx);
    return ret;
}

//void *duk_require_buffer(duk_context *ctx, duk_idx_t idx, duk_size_t *out_size);
void *aperl_duk_require_buffer(duk_context *ctx, duk_idx_t idx, SV *out_len) {
    duk_size_t sz;
    void *ret = duk_require_buffer(ctx, idx, &sz);
    sv_setnv(out_len, sz);
    return ret;
}

//void *duk_require_buffer_data(duk_context *ctx, duk_idx_t idx, duk_size_t *out_size);
void *aperl_duk_require_buffer_data(duk_context *ctx, duk_idx_t idx, SV *out_len) {
    duk_size_t sz;
    void *ret = duk_require_buffer_data(ctx, idx, &sz);
    sv_setnv(out_len, sz);
    return ret;
}

//duk_c_function duk_require_c_function(duk_context *ctx, duk_idx_t idx);
duk_c_function aperl_duk_require_c_function(duk_context *ctx, duk_idx_t idx) {
    duk_c_function ret = duk_require_c_function(ctx, idx);
    return ret;
}

//void duk_require_callable(duk_context *ctx, duk_idx_t idx);
void aperl_duk_require_callable(duk_context *ctx, duk_idx_t idx) {
    duk_require_callable(ctx, idx);
}

//duk_context *duk_require_context(duk_context *ctx, duk_idx_t idx);
duk_context *aperl_duk_require_context(duk_context *ctx, duk_idx_t idx) {
    duk_context *ret = duk_require_context(ctx, idx);
    return ret;
}

//void duk_require_function(duk_context *ctx, duk_idx_t idx);
void aperl_duk_require_function(duk_context *ctx, duk_idx_t idx) {
    duk_require_function(ctx, idx);
}

//void *duk_require_heapptr(duk_context *ctx, duk_idx_t idx);
void *aperl_duk_require_heapptr(duk_context *ctx, duk_idx_t idx) {
    void *ret = duk_require_heapptr(ctx, idx);
    return ret;
}

//duk_int_t duk_require_int(duk_context *ctx, duk_idx_t idx);
duk_int_t aperl_duk_require_int(duk_context *ctx, duk_idx_t idx) {
    duk_int_t ret = duk_require_int(ctx, idx);
    return ret;
}

//const char *duk_require_lstring(duk_context *ctx, duk_idx_t idx, duk_size_t *out_len);
const char *aperl_duk_require_lstring(duk_context *ctx, duk_idx_t idx, SV *out_len) {
    duk_size_t sz;
    const char *ret = duk_require_lstring(ctx, idx, &sz);
    sv_setnv(out_len, sz);
    return ret;
}

//duk_idx_t duk_require_normalize_index(duk_context *ctx, duk_idx_t idx);
duk_idx_t aperl_duk_require_normalize_index(duk_context *ctx, duk_idx_t idx) {
    duk_idx_t ret = duk_require_normalize_index(ctx, idx);
    return ret;
}

//void duk_require_null(duk_context *ctx, duk_idx_t idx);
void aperl_duk_require_null(duk_context *ctx, duk_idx_t idx) {
    duk_require_null(ctx, idx);
}

//duk_double_t duk_require_number(duk_context *ctx, duk_idx_t idx);
duk_double_t aperl_duk_require_number(duk_context *ctx, duk_idx_t idx) {
    duk_double_t ret = duk_require_number(ctx, idx);
    return ret;
}

//void duk_require_object(duk_context *ctx, duk_idx_t idx);
void aperl_duk_require_object(duk_context *ctx, duk_idx_t idx) {
    duk_require_object(ctx, idx);
}

//void duk_require_object_coercible(duk_context *ctx, duk_idx_t idx);
void aperl_duk_require_object_coercible(duk_context *ctx, duk_idx_t idx) {
    duk_require_object_coercible(ctx, idx);
}

//void *duk_require_pointer(duk_context *ctx, duk_idx_t idx);
void *aperl_duk_require_pointer(duk_context *ctx, duk_idx_t idx) {
    void *ret = duk_require_pointer(ctx, idx);
    return ret;
}

//void duk_require_stack(duk_context *ctx, duk_idx_t extra);
void aperl_duk_require_stack(duk_context *ctx, duk_idx_t extra) {
    duk_require_stack(ctx, extra);
}

//void duk_require_stack_top(duk_context *ctx, duk_idx_t top);
void aperl_duk_require_stack_top(duk_context *ctx, duk_idx_t top) {
    duk_require_stack_top(ctx, top);
}

//const char *duk_require_string(duk_context *ctx, duk_idx_t idx);
const char *aperl_duk_require_string(duk_context *ctx, duk_idx_t idx) {
    const char *ret = duk_require_string(ctx, idx);
    return ret;
}

//duk_idx_t duk_require_top_index(duk_context *ctx);
duk_idx_t aperl_duk_require_top_index(duk_context *ctx) {
    duk_idx_t ret = duk_require_top_index(ctx);
    return ret;
}

//void duk_require_type_mask(duk_context *ctx, duk_idx_t idx, duk_uint_t mask);
void aperl_duk_require_type_mask(duk_context *ctx, duk_idx_t idx, duk_uint_t mask) {
    duk_require_type_mask(ctx, idx, mask);
}

//duk_uint_t duk_require_uint(duk_context *ctx, duk_idx_t idx);
duk_uint_t aperl_duk_require_uint(duk_context *ctx, duk_idx_t idx) {
    duk_uint_t ret = duk_require_uint(ctx, idx);
    return ret;
}

//void duk_require_undefined(duk_context *ctx, duk_idx_t idx);
void aperl_duk_require_undefined(duk_context *ctx, duk_idx_t idx) {
    duk_require_undefined(ctx, idx);
}

//void duk_require_valid_index(duk_context *ctx, duk_idx_t idx);
void aperl_duk_require_valid_index(duk_context *ctx, duk_idx_t idx) {
    duk_require_valid_index(ctx, idx);
}

//void *duk_resize_buffer(duk_context *ctx, duk_idx_t idx, duk_size_t new_size);
void *aperl_duk_resize_buffer(duk_context *ctx, duk_idx_t idx, duk_size_t new_size) {
    void *ret = duk_resize_buffer(ctx, idx, new_size);
    return ret;
}

//void duk_resume(duk_context *ctx, const duk_thread_state *state);
void aperl_duk_resume(duk_context *ctx, const duk_thread_state *state) {
    duk_resume(ctx, state);
}

//duk_int_t duk_safe_call(duk_context *ctx, duk_safe_call_function func, void *udata, duk_idx_t nargs, duk_idx_t nrets);
duk_int_t aperl_duk_safe_call(duk_context *ctx, duk_safe_call_function func, void *udata, duk_idx_t nargs, duk_idx_t nrets) {
    duk_int_t ret = duk_safe_call(ctx, func, udata, nargs, nrets);
    return ret;
}

//const char *duk_safe_to_lstring(duk_context *ctx, duk_idx_t idx, duk_size_t *out_len);
const char *aperl_duk_safe_to_lstring(duk_context *ctx, duk_idx_t idx, SV *out_len) {
    duk_size_t sz;
    const char *ret = duk_safe_to_lstring(ctx, idx, &sz);
    sv_setnv(out_len, sz);
    return ret;
}

//const char *duk_safe_to_string(duk_context *ctx, duk_idx_t idx);
const char *aperl_duk_safe_to_string(duk_context *ctx, duk_idx_t idx) {
    const char *ret = duk_safe_to_string(ctx, idx);
    return ret;
}

//duk_bool_t duk_samevalue(duk_context *ctx, duk_idx_t idx1, duk_idx_t idx2);
duk_bool_t aperl_duk_samevalue(duk_context *ctx, duk_idx_t idx1, duk_idx_t idx2) {
    duk_bool_t ret = duk_samevalue(ctx, idx1, idx2);
    return ret;
}

//void duk_seal(duk_context *ctx, duk_idx_t obj_idx);
void aperl_duk_seal(duk_context *ctx, duk_idx_t obj_idx) {
    duk_seal(ctx, obj_idx);
}

//void duk_set_finalizer(duk_context *ctx, duk_idx_t idx);
void aperl_duk_set_finalizer(duk_context *ctx, duk_idx_t idx) {
    duk_set_finalizer(ctx, idx);
}

//void duk_set_global_object(duk_context *ctx);
void aperl_duk_set_global_object(duk_context *ctx) {
    duk_set_global_object(ctx);
}

//void duk_set_length(duk_context *ctx, duk_idx_t idx, duk_size_t len);
void aperl_duk_set_length(duk_context *ctx, duk_idx_t idx, duk_size_t len) {
    duk_set_length(ctx, idx, len);
}

//void duk_set_magic(duk_context *ctx, duk_idx_t idx, duk_int_t magic);
void aperl_duk_set_magic(duk_context *ctx, duk_idx_t idx, duk_int_t magic) {
    duk_set_magic(ctx, idx, magic);
}

//void duk_set_prototype(duk_context *ctx, duk_idx_t idx);
void aperl_duk_set_prototype(duk_context *ctx, duk_idx_t idx) {
    duk_set_prototype(ctx, idx);
}

//void duk_set_top(duk_context *ctx, duk_idx_t idx);
void aperl_duk_set_top(duk_context *ctx, duk_idx_t idx) {
    duk_set_top(ctx, idx);
}

//void *duk_steal_buffer(duk_context *ctx, duk_idx_t idx, duk_size_t *out_size);
void *aperl_duk_steal_buffer(duk_context *ctx, duk_idx_t idx, SV *out_len) {
    duk_size_t sz;
    void *ret = duk_steal_buffer(ctx, idx, &sz);
    sv_setnv(out_len, sz);
    return ret;
}

//duk_bool_t duk_strict_equals(duk_context *ctx, duk_idx_t idx1, duk_idx_t idx2);
duk_bool_t aperl_duk_strict_equals(duk_context *ctx, duk_idx_t idx1, duk_idx_t idx2) {
    duk_bool_t ret = duk_strict_equals(ctx, idx1, idx2);
    return ret;
}

//void duk_substring(duk_context *ctx, duk_idx_t idx, duk_size_t start_char_offset, duk_size_t end_char_offset);
void aperl_duk_substring(duk_context *ctx, duk_idx_t idx, duk_size_t start_char_offset, duk_size_t end_char_offset) {
    duk_substring(ctx, idx, start_char_offset, end_char_offset);
}

//void duk_suspend(duk_context *ctx, duk_thread_state *state);
void aperl_duk_suspend(duk_context *ctx, duk_thread_state *state) {
    duk_suspend(ctx, state);
}

//void duk_swap(duk_context *ctx, duk_idx_t idx1, duk_idx_t idx2);
void aperl_duk_swap(duk_context *ctx, duk_idx_t idx1, duk_idx_t idx2) {
    duk_swap(ctx, idx1, idx2);
}

//void duk_swap_top(duk_context *ctx, duk_idx_t idx);
void aperl_duk_swap_top(duk_context *ctx, duk_idx_t idx) {
    duk_swap_top(ctx, idx);
}

//duk_ret_t duk_syntax_error_va(duk_context *ctx, const char *fmt, va_list ap);
duk_ret_t aperl_duk_syntax_error_va(duk_context *ctx, const char *fmt, va_list ap) {
    duk_ret_t ret = duk_syntax_error_va(ctx, fmt, ap);
    return ret;
}

//duk_ret_t duk_throw(duk_context *ctx);
duk_ret_t aperl_duk_throw(duk_context *ctx) {
    duk_ret_t ret = duk_throw(ctx);
    return ret;
}

//void duk_time_to_components(duk_context *ctx, duk_double_t time, duk_time_components *comp);
void aperl_duk_time_to_components(duk_context *ctx, duk_double_t time, duk_time_components *comp) {
    duk_time_to_components(ctx, time, comp);
}

//duk_bool_t duk_to_boolean(duk_context *ctx, duk_idx_t idx);
duk_bool_t aperl_duk_to_boolean(duk_context *ctx, duk_idx_t idx) {
    duk_bool_t ret = duk_to_boolean(ctx, idx);
    return ret;
}

//void *duk_to_buffer(duk_context *ctx, duk_idx_t idx, duk_size_t *out_size);
void *aperl_duk_to_buffer(duk_context *ctx, duk_idx_t idx, SV *out_len) {
    duk_size_t sz;
    void *ret = duk_to_buffer(ctx, idx, &sz);
    sv_setnv(out_len, sz);
    return ret;
}

//void *duk_to_dynamic_buffer(duk_context *ctx, duk_idx_t idx, duk_size_t *out_size);
void *aperl_duk_to_dynamic_buffer(duk_context *ctx, duk_idx_t idx, SV *out_len) {
    duk_size_t sz;
    void *ret = duk_to_dynamic_buffer(ctx, idx, &sz);
    sv_setnv(out_len, sz);
    return ret;
}

//void *duk_to_fixed_buffer(duk_context *ctx, duk_idx_t idx, duk_size_t *out_size);
void *aperl_duk_to_fixed_buffer(duk_context *ctx, duk_idx_t idx, SV *out_len) {
    duk_size_t sz;
    void *ret = duk_to_fixed_buffer(ctx, idx, &sz);
    sv_setnv(out_len, sz);
    return ret;
}

//duk_int_t duk_to_int(duk_context *ctx, duk_int_t index);
duk_int_t aperl_duk_to_int(duk_context *ctx, duk_int_t index) {
    duk_int_t ret = duk_to_int(ctx, index);
    return ret;
}

//duk_int32_t duk_to_int32(duk_context *ctx, duk_idx_t idx);
duk_int32_t aperl_duk_to_int32(duk_context *ctx, duk_idx_t idx) {
    duk_int32_t ret = duk_to_int32(ctx, idx);
    return ret;
}

//const char *duk_to_lstring(duk_context *ctx, duk_idx_t idx, duk_size_t *out_len);
const char *aperl_duk_to_lstring(duk_context *ctx, duk_idx_t idx, SV *out_len) {
    duk_size_t sz;
    const char *ret = duk_to_lstring(ctx, idx, &sz);
    sv_setnv(out_len, sz);
    return ret;
}

//void duk_to_null(duk_context *ctx, duk_idx_t idx);
void aperl_duk_to_null(duk_context *ctx, duk_idx_t idx) {
    duk_to_null(ctx, idx);
}

//duk_double_t duk_to_number(duk_context *ctx, duk_idx_t idx);
duk_double_t aperl_duk_to_number(duk_context *ctx, duk_idx_t idx) {
    duk_double_t ret = duk_to_number(ctx, idx);
    return ret;
}

//void duk_to_object(duk_context *ctx, duk_idx_t idx);
void aperl_duk_to_object(duk_context *ctx, duk_idx_t idx) {
    duk_to_object(ctx, idx);
}

//void *duk_to_pointer(duk_context *ctx, duk_idx_t idx);
void *aperl_duk_to_pointer(duk_context *ctx, duk_idx_t idx) {
    void *ret = duk_to_pointer(ctx, idx);
    return ret;
}

//void duk_to_primitive(duk_context *ctx, duk_idx_t idx, duk_int_t hint);
void aperl_duk_to_primitive(duk_context *ctx, duk_idx_t idx, duk_int_t hint) {
    duk_to_primitive(ctx, idx, hint);
}

//const char *duk_to_string(duk_context *ctx, duk_idx_t idx);
const char *aperl_duk_to_string(duk_context *ctx, duk_idx_t idx) {
    const char *ret = duk_to_string(ctx, idx);
    return ret;
}

//duk_uint_t duk_to_uint(duk_context *ctx, duk_idx_t idx);
duk_uint_t aperl_duk_to_uint(duk_context *ctx, duk_idx_t idx) {
    duk_uint_t ret = duk_to_uint(ctx, idx);
    return ret;
}

//duk_uint16_t duk_to_uint16(duk_context *ctx, duk_idx_t idx);
duk_uint16_t aperl_duk_to_uint16(duk_context *ctx, duk_idx_t idx) {
    duk_uint16_t ret = duk_to_uint16(ctx, idx);
    return ret;
}

//duk_uint32_t duk_to_uint32(duk_context *ctx, duk_idx_t idx);
duk_uint32_t aperl_duk_to_uint32(duk_context *ctx, duk_idx_t idx) {
    duk_uint32_t ret = duk_to_uint32(ctx, idx);
    return ret;
}

//void duk_to_undefined(duk_context *ctx, duk_idx_t idx);
void aperl_duk_to_undefined(duk_context *ctx, duk_idx_t idx) {
    duk_to_undefined(ctx, idx);
}

//void duk_trim(duk_context *ctx, duk_idx_t idx);
void aperl_duk_trim(duk_context *ctx, duk_idx_t idx) {
    duk_trim(ctx, idx);
}

//duk_ret_t duk_type_error_va(duk_context *ctx, const char *fmt, va_list ap);
duk_ret_t aperl_duk_type_error_va(duk_context *ctx, const char *fmt, va_list ap) {
    duk_ret_t ret = duk_type_error_va(ctx, fmt, ap);
    return ret;
}

//duk_ret_t duk_uri_error_va(duk_context *ctx, const char *fmt, va_list ap);
duk_ret_t aperl_duk_uri_error_va(duk_context *ctx, const char *fmt, va_list ap) {
    duk_ret_t ret = duk_uri_error_va(ctx, fmt, ap);
    return ret;
}
