/*
 * morpher_jit.c - JIT compilation backends for morpher formula expressions
 *
 * Backend priority:
 *   1. TCC (libtcc) - full C compiler, native -O0 speed
 *   2. Hand-rolled x86-64 - walks tinyexpr tree, emits SSE2
 *   3. NULL (caller falls back to tinyexpr interpretation)
 */

#include "morpher_jit.h"
#include "tinyexpr.h"
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <math.h>

/* ================================================================== */
/*  TCC backend (loaded via dlopen at runtime)                         */
/* ================================================================== */

#if defined(__unix__) || defined(__APPLE__)
#include <dlfcn.h>
#include <unistd.h>

/* TCC API types (from libtcc.h) */
typedef struct TCCState TCCState;
#define TCC_OUTPUT_MEMORY 1
#define TCC_RELOCATE_AUTO ((void*)1)

/* Function pointer types for TCC API */
typedef TCCState *(*tcc_new_fn)(void);
typedef void (*tcc_delete_fn)(TCCState *);
typedef void (*tcc_set_error_func_fn)(TCCState *, void *, void (*)(void *, const char *));
typedef int (*tcc_set_output_type_fn)(TCCState *, int);
typedef int (*tcc_compile_string_fn)(TCCState *, const char *);
typedef int (*tcc_add_symbol_fn)(TCCState *, const char *, const void *);
typedef int (*tcc_relocate_fn)(TCCState *, void *);
typedef void *(*tcc_get_symbol_fn)(TCCState *, const char *);
typedef void (*tcc_set_lib_path_fn)(TCCState *, const char *);

static struct {
    void *handle;
    int loaded;
    int available;
    tcc_new_fn             new;
    tcc_delete_fn          delete;
    tcc_set_error_func_fn  set_error_func;
    tcc_set_output_type_fn set_output_type;
    tcc_compile_string_fn  compile_string;
    tcc_add_symbol_fn      add_symbol;
    tcc_relocate_fn        relocate;
    tcc_get_symbol_fn      get_symbol;
    tcc_set_lib_path_fn    set_lib_path;
} tcc_api = {0};

static void tcc_load(void) {
    if (tcc_api.loaded) return;
    tcc_api.loaded = 1;

    tcc_api.handle = dlopen("libtcc.so", RTLD_LAZY);
    if (!tcc_api.handle) tcc_api.handle = dlopen("libtcc.so.0", RTLD_LAZY);
    if (!tcc_api.handle) tcc_api.handle = dlopen("libtcc.so.1", RTLD_LAZY);
    if (!tcc_api.handle) tcc_api.handle = dlopen("libtcc.dylib", RTLD_LAZY);
    if (!tcc_api.handle) return;

    tcc_api.new             = (tcc_new_fn)dlsym(tcc_api.handle, "tcc_new");
    tcc_api.delete          = (tcc_delete_fn)dlsym(tcc_api.handle, "tcc_delete");
    tcc_api.set_error_func  = (tcc_set_error_func_fn)dlsym(tcc_api.handle, "tcc_set_error_func");
    tcc_api.set_output_type = (tcc_set_output_type_fn)dlsym(tcc_api.handle, "tcc_set_output_type");
    tcc_api.compile_string  = (tcc_compile_string_fn)dlsym(tcc_api.handle, "tcc_compile_string");
    tcc_api.add_symbol      = (tcc_add_symbol_fn)dlsym(tcc_api.handle, "tcc_add_symbol");
    tcc_api.relocate        = (tcc_relocate_fn)dlsym(tcc_api.handle, "tcc_relocate");
    tcc_api.get_symbol      = (tcc_get_symbol_fn)dlsym(tcc_api.handle, "tcc_get_symbol");
    tcc_api.set_lib_path    = (tcc_set_lib_path_fn)dlsym(tcc_api.handle, "tcc_set_lib_path");

    tcc_api.available = tcc_api.new && tcc_api.delete && tcc_api.compile_string
                     && tcc_api.add_symbol && tcc_api.relocate && tcc_api.get_symbol
                     && tcc_api.set_output_type;
}

static void tcc_error_cb(void *opaque, const char *msg) {
    (void)opaque; (void)msg;
}

static jit_morpher *jit_compile_tcc(const char *formula) {
    TCCState *s;
    jit_morpher *jit;
    char src[2048];
    int len;
    double dummy_t = 0;
    te_variable vars[] = {{"t", &dummy_t, TE_VARIABLE, NULL}};
    int err;
    te_expr *validation;

    tcc_load();
    if (!tcc_api.available) return NULL;

    /* Validate formula through tinyexpr first to prevent code injection.
     * TCC compiles arbitrary C, so we must ensure the formula is a pure
     * math expression before embedding it in generated source code. */
    validation = te_compile(formula, vars, 1, &err);
    if (!validation) return NULL;
    te_free(validation);

    len = snprintf(src, sizeof(src),
        "double sin(double); double cos(double); double tan(double);\n"
        "double asin(double); double acos(double); double atan(double);\n"
        "double atan2(double,double);\n"
        "double sinh(double); double cosh(double); double tanh(double);\n"
        "double exp(double); double log(double); double log10(double); double log2(double);\n"
        "double pow(double,double); double sqrt(double); double fabs(double);\n"
        "double ceil(double); double floor(double); double fmod(double,double);\n"
        "double round(double); double cbrt(double); double hypot(double,double);\n"
        "double morpher(double t) { return (%s); }\n",
        formula);
    if (len < 0 || (size_t)len >= sizeof(src))
        return NULL;

    s = tcc_api.new();
    if (!s) return NULL;

    if (tcc_api.set_error_func)
        tcc_api.set_error_func(s, NULL, tcc_error_cb);

    /* Probe for libtcc1.a in common locations */
    if (tcc_api.set_lib_path) {
        static const char *probe_paths[] = {
            "/usr/lib/x86_64-linux-gnu/tcc",
            "/usr/lib/tcc",
            "/usr/local/lib/tcc",
            "/usr/lib64/tcc",
            NULL
        };
        int i;
        for (i = 0; probe_paths[i]; i++) {
            char buf[256];
            snprintf(buf, sizeof(buf), "%s/libtcc1.a", probe_paths[i]);
            if (access(buf, R_OK) == 0) {
                tcc_api.set_lib_path(s, probe_paths[i]);
                break;
            }
        }
    }

    tcc_api.set_output_type(s, TCC_OUTPUT_MEMORY);

    /* Provide math symbols so TCC doesn't need libc headers */
    tcc_api.add_symbol(s, "sin", (const void *)sin);
    tcc_api.add_symbol(s, "cos", (const void *)cos);
    tcc_api.add_symbol(s, "tan", (const void *)tan);
    tcc_api.add_symbol(s, "asin", (const void *)asin);
    tcc_api.add_symbol(s, "acos", (const void *)acos);
    tcc_api.add_symbol(s, "atan", (const void *)atan);
    tcc_api.add_symbol(s, "atan2", (const void *)atan2);
    tcc_api.add_symbol(s, "sinh", (const void *)sinh);
    tcc_api.add_symbol(s, "cosh", (const void *)cosh);
    tcc_api.add_symbol(s, "tanh", (const void *)tanh);
    tcc_api.add_symbol(s, "exp", (const void *)exp);
    tcc_api.add_symbol(s, "log", (const void *)log);
    tcc_api.add_symbol(s, "log10", (const void *)log10);
    tcc_api.add_symbol(s, "log2", (const void *)log2);
    tcc_api.add_symbol(s, "pow", (const void *)pow);
    tcc_api.add_symbol(s, "sqrt", (const void *)sqrt);
    tcc_api.add_symbol(s, "fabs", (const void *)fabs);
    tcc_api.add_symbol(s, "ceil", (const void *)ceil);
    tcc_api.add_symbol(s, "floor", (const void *)floor);
    tcc_api.add_symbol(s, "fmod", (const void *)fmod);
    tcc_api.add_symbol(s, "round", (const void *)round);
    tcc_api.add_symbol(s, "cbrt", (const void *)cbrt);
    tcc_api.add_symbol(s, "hypot", (const void *)hypot);

    if (tcc_api.compile_string(s, src) == -1) {
        tcc_api.delete(s);
        return NULL;
    }

    if (tcc_api.relocate(s, TCC_RELOCATE_AUTO) == -1) {
        tcc_api.delete(s);
        return NULL;
    }

    jit = (jit_morpher *)malloc(sizeof(jit_morpher));
    if (!jit) { tcc_api.delete(s); return NULL; }

    jit->fn = (jit_morpher_fn)(uintptr_t)tcc_api.get_symbol(s, "morpher");
    if (!jit->fn) {
        tcc_api.delete(s);
        free(jit);
        return NULL;
    }

    jit->backend = JIT_BACKEND_TCC;
    jit->state = s;
    jit->state_size = 0;
    return jit;
}

#endif /* unix/apple */

/* ================================================================== */
/*  x86-64 hand-rolled JIT backend                                     */
/* ================================================================== */

#if defined(__x86_64__) || defined(_M_X64)

#include <sys/mman.h>
#include <stdint.h>

#ifndef MAP_ANONYMOUS
#define MAP_ANONYMOUS MAP_ANON
#endif

#define JIT_PAGE 4096

typedef struct {
    uint8_t *buf;
    size_t   pos;
    size_t   cap;
    int      stack_depth;
    int      ok;
} jit_ctx;

static void jb(jit_ctx *j, uint8_t b) {
    if (j->pos < j->cap) j->buf[j->pos] = b;
    else j->ok = 0;
    j->pos++;
}

static void jbs(jit_ctx *j, const uint8_t *b, int n) {
    int i;
    for (i = 0; i < n; i++) jb(j, b[i]);
}

static void ju32(jit_ctx *j, uint32_t v) {
    jb(j,v); jb(j,v>>8); jb(j,v>>16); jb(j,v>>24);
}

static void ju64(jit_ctx *j, uint64_t v) {
    ju32(j,(uint32_t)v); ju32(j,(uint32_t)(v>>32));
}

/* mov rax, imm64 */
static void j_mov_rax(jit_ctx *j, uint64_t val) {
    jb(j,0x48); jb(j,0xb8); ju64(j,val);
}

/* movq xmm0, rax */
static void j_movq_xmm0_rax(jit_ctx *j) {
    static const uint8_t c[]={0x66,0x48,0x0f,0x6e,0xc0}; jbs(j,c,5);
}

/* Load double constant into xmm0 */
static void j_load_const(jit_ctx *j, double val) {
    uint64_t bits;
    if (val == 0.0 && !signbit(val)) {
        static const uint8_t c[]={0x66,0x0f,0x57,0xc0}; jbs(j,c,4); /* xorpd xmm0,xmm0 */
        return;
    }
    memcpy(&bits, &val, 8);
    j_mov_rax(j, bits);
    j_movq_xmm0_rax(j);
}

/* movsd xmm0, [rbp-8] */
static void j_load_t(jit_ctx *j) {
    static const uint8_t c[]={0xf2,0x0f,0x10,0x45,0xf8}; jbs(j,c,5);
}

/* push xmm0 to stack */
static void j_push_xmm0(jit_ctx *j) {
    static const uint8_t s[]={0x48,0x83,0xec,0x08};       jbs(j,s,4);
    static const uint8_t m[]={0xf2,0x0f,0x11,0x04,0x24};  jbs(j,m,5);
    j->stack_depth += 8;
}

/* pop stack to xmm0 */
static void j_pop_xmm0(jit_ctx *j) {
    static const uint8_t m[]={0xf2,0x0f,0x10,0x04,0x24};  jbs(j,m,5);
    static const uint8_t a[]={0x48,0x83,0xc4,0x08};       jbs(j,a,4);
    j->stack_depth -= 8;
}

/* movsd xmm1, xmm0 */
static void j_xmm1_from_xmm0(jit_ctx *j) {
    static const uint8_t c[]={0xf2,0x0f,0x10,0xc8}; jbs(j,c,4);
}

static void j_addsd(jit_ctx *j) { static const uint8_t c[]={0xf2,0x0f,0x58,0xc1}; jbs(j,c,4); }
static void j_subsd(jit_ctx *j) { static const uint8_t c[]={0xf2,0x0f,0x5c,0xc1}; jbs(j,c,4); }
static void j_mulsd(jit_ctx *j) { static const uint8_t c[]={0xf2,0x0f,0x59,0xc1}; jbs(j,c,4); }
static void j_divsd(jit_ctx *j) { static const uint8_t c[]={0xf2,0x0f,0x5e,0xc1}; jbs(j,c,4); }

/* Negate xmm0 via sign-bit flip */
static void j_negate(jit_ctx *j) {
    j_mov_rax(j, 0x8000000000000000ULL);
    { static const uint8_t c[]={0x66,0x48,0x0f,0x6e,0xc8}; jbs(j,c,5); } /* movq xmm1,rax */
    { static const uint8_t c[]={0x66,0x0f,0x57,0xc1};      jbs(j,c,4); } /* xorpd xmm0,xmm1 */
}

/* Call function with 16-byte stack alignment */
static void j_call(jit_ctx *j, const void *fn) {
    int pad = (j->stack_depth % 16) != 0;
    if (pad) { static const uint8_t s[]={0x48,0x83,0xec,0x08}; jbs(j,s,4); j->stack_depth+=8; }
    j_mov_rax(j, (uint64_t)(uintptr_t)fn);
    jb(j, 0xff); jb(j, 0xd0);
    if (pad) { static const uint8_t a[]={0x48,0x83,0xc4,0x08}; jbs(j,a,4); j->stack_depth-=8; }
}

/* Recursive tree walker */
static void j_emit(jit_ctx *j, const te_expr *n) {
    int type, arity, op;
    if (!j->ok || !n) { j->ok = 0; return; }

    type  = n->type & 0x1f;
    arity = (type & (8|16)) ? (type & 7) : 0;

    if (type == 1) { j_load_const(j, n->value); return; }      /* TE_CONSTANT */
    if (type == 0) { j_load_t(j); return; }                     /* TE_VARIABLE */

    if (arity == 0) { j_call(j, n->function); return; }         /* TE_FUNCTION0 */

    if (arity == 1) {
        op = te_identify_fn(n->function);
        j_emit(j, n->parameters[0]);
        if (!j->ok) return;
        if (op == TE_OP_NEGATE) j_negate(j);
        else j_call(j, n->function);
        return;
    }

    if (arity == 2) {
        op = te_identify_fn(n->function);
        j_emit(j, n->parameters[0]);
        if (!j->ok) return;
        j_push_xmm0(j);
        j_emit(j, n->parameters[1]);
        if (!j->ok) return;
        j_xmm1_from_xmm0(j);
        j_pop_xmm0(j);
        switch (op) {
        case TE_OP_ADD: j_addsd(j); break;
        case TE_OP_SUB: j_subsd(j); break;
        case TE_OP_MUL: j_mulsd(j); break;
        case TE_OP_DIV: j_divsd(j); break;
        default: j_call(j, n->function); break;
        }
        return;
    }

    j->ok = 0; /* arity 3+ unsupported */
}

static jit_morpher *jit_compile_x86(const char *formula) {
    double dummy_t = 0;
    te_variable vars[] = {{"t", &dummy_t, TE_VARIABLE, NULL}};
    int err;
    te_expr *expr;
    jit_ctx j;
    void *code;
    jit_morpher *jit;

    expr = te_compile(formula, vars, 1, &err);
    if (!expr) return NULL;

    code = mmap(NULL, JIT_PAGE, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
    if (code == MAP_FAILED) { te_free(expr); return NULL; }

    j.buf = (uint8_t *)code;
    j.pos = 0;
    j.cap = JIT_PAGE;
    j.stack_depth = 0;
    j.ok = 1;

    /* prologue */
    jb(&j, 0x55);                                                         /* push rbp */
    { static const uint8_t c[]={0x48,0x89,0xe5};          jbs(&j,c,3); } /* mov rbp,rsp */
    { static const uint8_t c[]={0x48,0x83,0xec,0x10};     jbs(&j,c,4); } /* sub rsp,16 */
    { static const uint8_t c[]={0xf2,0x0f,0x11,0x45,0xf8};jbs(&j,c,5); } /* movsd [rbp-8],xmm0 */

    j_emit(&j, expr);

    /* epilogue */
    jb(&j, 0xc9); /* leave */
    jb(&j, 0xc3); /* ret */

    te_free(expr);

    if (!j.ok || j.pos > JIT_PAGE) { munmap(code, JIT_PAGE); return NULL; }
    if (mprotect(code, JIT_PAGE, PROT_READ|PROT_EXEC) != 0) { munmap(code, JIT_PAGE); return NULL; }

    jit = (jit_morpher *)malloc(sizeof(jit_morpher));
    if (!jit) { munmap(code, JIT_PAGE); return NULL; }

    jit->fn = (jit_morpher_fn)code;
    jit->backend = JIT_BACKEND_X86;
    jit->state = code;
    jit->state_size = JIT_PAGE;
    return jit;
}

#endif /* x86-64 */

/* ================================================================== */
/*  Public API                                                         */
/* ================================================================== */

jit_morpher *jit_morpher_compile(const char *formula) {
    jit_morpher *jit = NULL;

#if defined(__unix__) || defined(__APPLE__)
    jit = jit_compile_tcc(formula);
    if (jit) return jit;
#endif

#if defined(__x86_64__) || defined(_M_X64)
    jit = jit_compile_x86(formula);
    if (jit) return jit;
#endif

    (void)formula;
    return NULL;
}

void jit_morpher_free(jit_morpher *jit) {
    if (!jit) return;
    switch (jit->backend) {
    case JIT_BACKEND_TCC:
#if defined(__unix__) || defined(__APPLE__)
        if (jit->state && tcc_api.available)
            tcc_api.delete((TCCState *)jit->state);
#endif
        break;
#if defined(__x86_64__) || defined(_M_X64)
    case JIT_BACKEND_X86:
        if (jit->state) munmap(jit->state, jit->state_size);
        break;
#endif
    default:
        break;
    }
    free(jit);
}

const char *jit_backend_name(const jit_morpher *jit) {
    if (!jit) return "none";
    switch (jit->backend) {
    case JIT_BACKEND_TCC: return "tcc";
    case JIT_BACKEND_X86: return "x86";
    default: return "none";
    }
}
