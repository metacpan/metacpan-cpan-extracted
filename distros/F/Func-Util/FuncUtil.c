#define _GNU_SOURCE
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "funcutil_compat.h"
#include "multicall_compat.h"
#include <string.h>

/* Portable memmem - use system version if available, else our own */
#ifndef HAVE_MEMMEM
#if defined(__GLIBC__) || defined(__APPLE__) || defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__NetBSD__)
#define HAVE_MEMMEM 1
#endif
#endif

#if HAVE_MEMMEM
#define util_memmem memmem
#else
static void *util_memmem(const void *haystack, size_t haystacklen,
                         const void *needle, size_t needlelen) {
    if (needlelen == 0) return (void*)haystack;
    if (needlelen > haystacklen) return NULL;
    
    const char *h = (const char*)haystack;
    const char *n = (const char*)needle;
    const char *end = h + haystacklen - needlelen + 1;
    char first = *n;
    
    for (; h < end; h++) {
        if (*h == first && memcmp(h, n, needlelen) == 0) {
            return (void*)h;
        }
    }
    return NULL;
}
#endif

/* ============================================
   Custom op structures
   ============================================ */

static XOP identity_xop;
static XOP always_xop;
static XOP clamp_xop;
static XOP nvl_xop;
static XOP coalesce_xop;

/* Type predicate custom ops - blazing fast, single SV flag check */
static XOP is_ref_xop;
static XOP is_array_xop;
static XOP is_hash_xop;
static XOP is_code_xop;
static XOP is_defined_xop;

/* String predicate custom ops - direct SvPV/SvCUR access */
static XOP is_empty_xop;
static XOP starts_with_xop;
static XOP ends_with_xop;
/* Boolean/Truthiness custom ops - fast truth checks */
static XOP is_true_xop;
static XOP is_false_xop;
static XOP bool_xop;

/* Extended type predicate custom ops */
static XOP is_num_xop;
static XOP is_int_xop;
static XOP is_blessed_xop;
static XOP is_scalar_ref_xop;
static XOP is_regex_xop;
static XOP is_glob_xop;
static XOP is_string_xop;

/* Numeric predicate custom ops */
static XOP is_positive_xop;
static XOP is_negative_xop;
static XOP is_zero_xop;

/* Numeric utility custom ops */
static XOP is_even_xop;
static XOP is_odd_xop;
static XOP is_between_xop;

/* Collection custom ops - direct AvFILL/HvKEYS access */
static XOP is_empty_array_xop;
static XOP is_empty_hash_xop;
static XOP array_len_xop;
static XOP hash_size_xop;
static XOP array_first_xop;
static XOP array_last_xop;

/* String manipulation custom ops */
static XOP trim_xop;
static XOP ltrim_xop;
static XOP rtrim_xop;

/* Conditional custom ops */
static XOP maybe_xop;

/* Numeric custom ops */
static XOP sign_xop;
static XOP min2_xop;
static XOP max2_xop;

/* ============================================
   Memoization structures
   ============================================ */

typedef struct {
    SV *func;           /* Original coderef */
    HV *cache;          /* Result cache */
    IV hits;            /* Cache hits (stats) */
    IV misses;          /* Cache misses (stats) */
} MemoizedFunc;

static MemoizedFunc *g_memos = NULL;
static IV g_memo_size = 0;
static IV g_memo_count = 0;

/* ============================================
   Lazy evaluation structures
   ============================================ */

typedef struct {
    SV *thunk;          /* Deferred computation (coderef) */
    SV *value;          /* Cached result */
    bool forced;        /* Has been evaluated? */
} LazyValue;

static LazyValue *g_lazies = NULL;
static IV g_lazy_size = 0;
static IV g_lazy_count = 0;

/* ============================================
   Always (constant) structures
   ============================================ */

static SV **g_always_values = NULL;
static IV g_always_size = 0;
static IV g_always_count = 0;

/* ============================================
   Once (execute once) structures
   ============================================ */

typedef struct {
    SV *func;           /* Original function */
    SV *result;         /* Cached result */
    bool called;        /* Has been called? */
} OnceFunc;

static OnceFunc *g_onces = NULL;
static IV g_once_size = 0;
static IV g_once_count = 0;

/* ============================================
   Partial application structures
   ============================================ */

typedef struct {
    SV *func;           /* Original function */
    AV *bound_args;     /* Pre-bound arguments */
} PartialFunc;

static PartialFunc *g_partials = NULL;
static IV g_partial_size = 0;
static IV g_partial_count = 0;

/* ============================================
   Loop callback registry structures
   ============================================ */

/* Function pointer types for loop callbacks */
typedef bool (*UtilPredicateFunc)(pTHX_ SV *elem);
typedef SV*  (*UtilMapFunc)(pTHX_ SV *elem);
typedef SV*  (*UtilReduceFunc)(pTHX_ SV *accum, SV *elem);

/* Registered callback entry */
typedef struct {
    char *name;                     /* Callback name (e.g., ":is_positive") */
    UtilPredicateFunc predicate;    /* C function for predicates */
    UtilMapFunc mapper;             /* C function for map */
    UtilReduceFunc reducer;         /* C function for reduce */
    SV *perl_callback;              /* Fallback Perl callback */
} RegisteredCallback;

/* Global callback registry */
static HV *g_callback_registry = NULL;

/* ============================================
   Forward declarations
   ============================================ */

XS_INTERNAL(xs_memo_call);
XS_INTERNAL(xs_compose_call);
XS_INTERNAL(xs_always_call);
XS_INTERNAL(xs_negate_call);
XS_INTERNAL(xs_once_call);
XS_INTERNAL(xs_partial_call);

/* ============================================
   Magic destructor infrastructure
   ============================================ */

/* Magic free function for "once" wrappers */
static int util_once_free(pTHX_ SV *sv, MAGIC *mg) {
    PERL_UNUSED_ARG(sv);
    IV idx = mg->mg_len;
    if (idx >= 0 && idx < g_once_count) {
        OnceFunc *of = &g_onces[idx];
        if (of->func) {
            SvREFCNT_dec(of->func);
            of->func = NULL;
        }
        if (of->result) {
            SvREFCNT_dec(of->result);
            of->result = NULL;
        }
        of->called = FALSE;
    }
    return 0;
}

static MGVTBL util_once_vtbl = {
    NULL,           /* get */
    NULL,           /* set */
    NULL,           /* len */
    NULL,           /* clear */
    util_once_free, /* free */
    NULL,           /* copy */
    NULL,           /* dup */
    NULL            /* local */
};

/* Magic free function for "partial" wrappers */
static int util_partial_free(pTHX_ SV *sv, MAGIC *mg) {
    PERL_UNUSED_ARG(sv);
    IV idx = mg->mg_len;
    if (idx >= 0 && idx < g_partial_count) {
        PartialFunc *pf = &g_partials[idx];
        if (pf->func) {
            SvREFCNT_dec(pf->func);
            pf->func = NULL;
        }
        if (pf->bound_args) {
            SvREFCNT_dec((SV*)pf->bound_args);
            pf->bound_args = NULL;
        }
    }
    return 0;
}

static MGVTBL util_partial_vtbl = {
    NULL, NULL, NULL, NULL, util_partial_free, NULL, NULL, NULL
};

/* Magic free function for "memo" wrappers */
static int util_memo_free(pTHX_ SV *sv, MAGIC *mg) {
    PERL_UNUSED_ARG(sv);
    IV idx = mg->mg_len;
    if (idx >= 0 && idx < g_memo_count) {
        MemoizedFunc *mf = &g_memos[idx];
        if (mf->func) {
            SvREFCNT_dec(mf->func);
            mf->func = NULL;
        }
        if (mf->cache) {
            SvREFCNT_dec((SV*)mf->cache);
            mf->cache = NULL;
        }
        mf->hits = 0;
        mf->misses = 0;
    }
    return 0;
}

static MGVTBL util_memo_vtbl = {
    NULL, NULL, NULL, NULL, util_memo_free, NULL, NULL, NULL
};

/* Magic free function for "lazy" wrappers */
static int util_lazy_free(pTHX_ SV *sv, MAGIC *mg) {
    PERL_UNUSED_ARG(sv);
    IV idx = mg->mg_len;
    if (idx >= 0 && idx < g_lazy_count) {
        LazyValue *lv = &g_lazies[idx];
        if (lv->thunk) {
            SvREFCNT_dec(lv->thunk);
            lv->thunk = NULL;
        }
        if (lv->value) {
            SvREFCNT_dec(lv->value);
            lv->value = NULL;
        }
        lv->forced = FALSE;
    }
    return 0;
}

static MGVTBL util_lazy_vtbl = {
    NULL, NULL, NULL, NULL, util_lazy_free, NULL, NULL, NULL
};

/* Magic free function for "compose" wrappers */
static int util_compose_free(pTHX_ SV *sv, MAGIC *mg) {
    PERL_UNUSED_ARG(sv);
    AV *funcs = (AV*)mg->mg_ptr;
    if (funcs) {
        SvREFCNT_dec((SV*)funcs);
    }
    return 0;
}

static MGVTBL util_compose_vtbl = {
    NULL, NULL, NULL, NULL, util_compose_free, NULL, NULL, NULL
};

/* Magic free function for "always" wrappers */
static int util_always_free(pTHX_ SV *sv, MAGIC *mg) {
    PERL_UNUSED_ARG(sv);
    IV idx = mg->mg_len;
    if (idx >= 0 && idx < g_always_count && g_always_values[idx]) {
        SvREFCNT_dec(g_always_values[idx]);
        g_always_values[idx] = NULL;
    }
    return 0;
}

static MGVTBL util_always_vtbl = {
    NULL, NULL, NULL, NULL, util_always_free, NULL, NULL, NULL
};

/* ============================================
   Utility functions
   ============================================ */

static void ensure_memo_capacity(IV needed) {
    if (needed >= g_memo_size) {
        IV new_size = g_memo_size ? g_memo_size * 2 : 16;
        while (new_size <= needed) new_size *= 2;
        Renew(g_memos, new_size, MemoizedFunc);
        g_memo_size = new_size;
    }
}

static void ensure_lazy_capacity(IV needed) {
    if (needed >= g_lazy_size) {
        IV new_size = g_lazy_size ? g_lazy_size * 2 : 16;
        while (new_size <= needed) new_size *= 2;
        Renew(g_lazies, new_size, LazyValue);
        g_lazy_size = new_size;
    }
}

static void ensure_always_capacity(IV needed) {
    if (needed >= g_always_size) {
        IV new_size = g_always_size ? g_always_size * 2 : 16;
        while (new_size <= needed) new_size *= 2;
        Renew(g_always_values, new_size, SV*);
        g_always_size = new_size;
    }
}

static void ensure_once_capacity(IV needed) {
    if (needed >= g_once_size) {
        IV new_size = g_once_size ? g_once_size * 2 : 16;
        while (new_size <= needed) new_size *= 2;
        Renew(g_onces, new_size, OnceFunc);
        g_once_size = new_size;
    }
}

static void ensure_partial_capacity(IV needed) {
    if (needed >= g_partial_size) {
        IV new_size = g_partial_size ? g_partial_size * 2 : 16;
        while (new_size <= needed) new_size *= 2;
        Renew(g_partials, new_size, PartialFunc);
        g_partial_size = new_size;
    }
}

/* Build cache key from stack arguments */
static SV* build_cache_key(pTHX_ SV **args, IV count) {
    SV *key = newSVpvs("");
    IV i;
    for (i = 0; i < count; i++) {
        if (i > 0) sv_catpvs(key, "\x00");
        if (SvOK(args[i])) {
            STRLEN len;
            const char *pv = SvPV(args[i], len);
            sv_catpvn(key, pv, len);
        } else {
            sv_catpvs(key, "\x01UNDEF\x01");
        }
    }
    return key;
}

/* ============================================
   Built-in predicates for loop callbacks
   (prefixed with ':' for built-in names)
   ============================================ */

static bool builtin_is_defined(pTHX_ SV *elem) {
    return SvOK(elem) ? TRUE : FALSE;
}

static bool builtin_is_true(pTHX_ SV *elem) {
    return SvTRUE(elem) ? TRUE : FALSE;
}

static bool builtin_is_false(pTHX_ SV *elem) {
    return !SvTRUE(elem) ? TRUE : FALSE;
}

static bool builtin_is_ref(pTHX_ SV *elem) {
    return SvROK(elem) ? TRUE : FALSE;
}

static bool builtin_is_array(pTHX_ SV *elem) {
    return (SvROK(elem) && SvTYPE(SvRV(elem)) == SVt_PVAV) ? TRUE : FALSE;
}

static bool builtin_is_hash(pTHX_ SV *elem) {
    return (SvROK(elem) && SvTYPE(SvRV(elem)) == SVt_PVHV) ? TRUE : FALSE;
}

static bool builtin_is_code(pTHX_ SV *elem) {
    return (SvROK(elem) && SvTYPE(SvRV(elem)) == SVt_PVCV) ? TRUE : FALSE;
}

static bool builtin_is_positive(pTHX_ SV *elem) {
    if (SvIOK(elem)) return SvIV(elem) > 0;
    if (SvNOK(elem)) return SvNV(elem) > 0;
    if (SvPOK(elem) && looks_like_number(elem)) return SvNV(elem) > 0;
    return FALSE;
}

static bool builtin_is_negative(pTHX_ SV *elem) {
    if (SvIOK(elem)) return SvIV(elem) < 0;
    if (SvNOK(elem)) return SvNV(elem) < 0;
    if (SvPOK(elem) && looks_like_number(elem)) return SvNV(elem) < 0;
    return FALSE;
}

static bool builtin_is_zero(pTHX_ SV *elem) {
    if (SvIOK(elem)) return SvIV(elem) == 0;
    if (SvNOK(elem)) return SvNV(elem) == 0.0;
    if (SvPOK(elem) && looks_like_number(elem)) return SvNV(elem) == 0.0;
    return FALSE;
}

static bool builtin_is_even(pTHX_ SV *elem) {
    if (!SvIOK(elem) && !SvNOK(elem)) {
        if (!SvPOK(elem) || !looks_like_number(elem)) return FALSE;
    }
    IV val = SvIV(elem);
    return (val % 2) == 0;
}

static bool builtin_is_odd(pTHX_ SV *elem) {
    if (!SvIOK(elem) && !SvNOK(elem)) {
        if (!SvPOK(elem) || !looks_like_number(elem)) return FALSE;
    }
    IV val = SvIV(elem);
    return (val % 2) != 0;
}

static bool builtin_is_empty(pTHX_ SV *elem) {
    if (!SvOK(elem)) return TRUE;
    if (SvROK(elem)) {
        SV *rv = SvRV(elem);
        if (SvTYPE(rv) == SVt_PVAV) return AvFILL((AV*)rv) < 0;
        if (SvTYPE(rv) == SVt_PVHV) return HvKEYS((HV*)rv) == 0;
        return FALSE;
    }
    if (SvPOK(elem)) return SvCUR(elem) == 0;
    return FALSE;
}

static bool builtin_is_nonempty(pTHX_ SV *elem) {
    return !builtin_is_empty(aTHX_ elem);
}

static bool builtin_is_string(pTHX_ SV *elem) {
    return (SvPOK(elem) && !SvIOK(elem) && !SvNOK(elem) && !SvROK(elem)) ? TRUE : FALSE;
}

static bool builtin_is_number(pTHX_ SV *elem) {
    if (SvIOK(elem) || SvNOK(elem)) return TRUE;
    if (SvPOK(elem) && looks_like_number(elem)) return TRUE;
    return FALSE;
}

static bool builtin_is_integer(pTHX_ SV *elem) {
    if (SvIOK(elem) && !SvNOK(elem)) return TRUE;
    if (SvNOK(elem)) {
        NV val = SvNV(elem);
        return val == (NV)(IV)val;
    }
    if (SvPOK(elem) && looks_like_number(elem)) {
        NV val = SvNV(elem);
        return val == (NV)(IV)val;
    }
    return FALSE;
}

/* ============================================
   Callback registry functions
   ============================================ */

static void init_callback_registry(pTHX) {
    if (!g_callback_registry) {
        g_callback_registry = newHV();
    }
}

/* Cleanup callback registry during global destruction */
static void cleanup_callback_registry(pTHX_ void *data) {
    HE *entry;
    PERL_UNUSED_ARG(data);

    if (!g_callback_registry) return;

    /* During global destruction, just NULL out the registry pointer.
     * Perl will handle freeing the SVs. Trying to free them ourselves
     * can cause crashes due to destruction order issues. */
    if (PL_dirty) {
        g_callback_registry = NULL;
        return;
    }

    /* Normal cleanup (not during global destruction) */
    hv_iterinit(g_callback_registry);
    while ((entry = hv_iternext(g_callback_registry))) {
        SV *sv = HeVAL(entry);
        if (sv && SvOK(sv)) {
            RegisteredCallback *cb = (RegisteredCallback*)SvIVX(sv);
            if (cb) {
                if (cb->perl_callback) {
                    SvREFCNT_dec(cb->perl_callback);
                    cb->perl_callback = NULL;
                }
                if (cb->name) {
                    Safefree(cb->name);
                    cb->name = NULL;
                }
                Safefree(cb);
            }
        }
    }
    SvREFCNT_dec((SV*)g_callback_registry);
    g_callback_registry = NULL;
}

static RegisteredCallback* get_registered_callback(pTHX_ const char *name) {
    SV **svp;
    if (!g_callback_registry) return NULL;
    svp = hv_fetch(g_callback_registry, name, strlen(name), 0);
    if (!svp || !SvOK(*svp)) return NULL;
    return (RegisteredCallback*)SvIVX(*svp);
}

/* Register a built-in predicate */
static void register_builtin_predicate(pTHX_ const char *name, UtilPredicateFunc func) {
    RegisteredCallback *cb;
    SV *sv;

    init_callback_registry(aTHX);

    Newxz(cb, 1, RegisteredCallback);
    cb->name = savepv(name);
    cb->predicate = func;
    cb->mapper = NULL;
    cb->reducer = NULL;
    cb->perl_callback = NULL;

    sv = newSViv(PTR2IV(cb));
    hv_store(g_callback_registry, name, strlen(name), sv, 0);
}

/* Public API for XS modules to register predicates */
PERL_CALLCONV void funcutil_register_predicate_xs(pTHX_ const char *name,
                                               UtilPredicateFunc func) {
    RegisteredCallback *cb;
    SV *sv;

    init_callback_registry(aTHX);

    /* Check if already registered */
    if (get_registered_callback(aTHX_ name)) {
        croak("Callback '%s' is already registered", name);
    }

    Newxz(cb, 1, RegisteredCallback);
    cb->name = savepv(name);
    cb->predicate = func;
    cb->mapper = NULL;
    cb->reducer = NULL;
    cb->perl_callback = NULL;

    sv = newSViv(PTR2IV(cb));
    hv_store(g_callback_registry, name, strlen(name), sv, 0);
}

/* Public API for XS modules to register mappers */
PERL_CALLCONV void funcutil_register_mapper_xs(pTHX_ const char *name,
                                            UtilMapFunc func) {
    RegisteredCallback *cb;
    SV *sv;

    init_callback_registry(aTHX);

    if (get_registered_callback(aTHX_ name)) {
        croak("Callback '%s' is already registered", name);
    }

    Newxz(cb, 1, RegisteredCallback);
    cb->name = savepv(name);
    cb->predicate = NULL;
    cb->mapper = func;
    cb->reducer = NULL;
    cb->perl_callback = NULL;

    sv = newSViv(PTR2IV(cb));
    hv_store(g_callback_registry, name, strlen(name), sv, 0);
}

/* Public API for XS modules to register reducers */
PERL_CALLCONV void funcutil_register_reducer_xs(pTHX_ const char *name,
                                             UtilReduceFunc func) {
    RegisteredCallback *cb;
    SV *sv;

    init_callback_registry(aTHX);

    if (get_registered_callback(aTHX_ name)) {
        croak("Callback '%s' is already registered", name);
    }

    Newxz(cb, 1, RegisteredCallback);
    cb->name = savepv(name);
    cb->predicate = NULL;
    cb->mapper = NULL;
    cb->reducer = func;
    cb->perl_callback = NULL;

    sv = newSViv(PTR2IV(cb));
    hv_store(g_callback_registry, name, strlen(name), sv, 0);
}

/* Check if a callback exists */
static bool has_callback(pTHX_ const char *name) {
    return get_registered_callback(aTHX_ name) != NULL;
}

/* List all registered callbacks */
static AV* list_callbacks(pTHX) {
    AV *result;
    HE *entry;

    result = newAV();
    if (!g_callback_registry) return result;

    hv_iterinit(g_callback_registry);
    while ((entry = hv_iternext(g_callback_registry))) {
        I32 klen;
        char *key = hv_iterkey(entry, &klen);
        av_push(result, newSVpvn(key, klen));
    }
    return result;
}

/* Initialize built-in callbacks (called from BOOT) */
static void init_builtin_callbacks(pTHX) {
    register_builtin_predicate(aTHX_ ":is_defined", builtin_is_defined);
    register_builtin_predicate(aTHX_ ":is_true", builtin_is_true);
    register_builtin_predicate(aTHX_ ":is_false", builtin_is_false);
    register_builtin_predicate(aTHX_ ":is_ref", builtin_is_ref);
    register_builtin_predicate(aTHX_ ":is_array", builtin_is_array);
    register_builtin_predicate(aTHX_ ":is_hash", builtin_is_hash);
    register_builtin_predicate(aTHX_ ":is_code", builtin_is_code);
    register_builtin_predicate(aTHX_ ":is_positive", builtin_is_positive);
    register_builtin_predicate(aTHX_ ":is_negative", builtin_is_negative);
    register_builtin_predicate(aTHX_ ":is_zero", builtin_is_zero);
    register_builtin_predicate(aTHX_ ":is_even", builtin_is_even);
    register_builtin_predicate(aTHX_ ":is_odd", builtin_is_odd);
    register_builtin_predicate(aTHX_ ":is_empty", builtin_is_empty);
    register_builtin_predicate(aTHX_ ":is_nonempty", builtin_is_nonempty);
    register_builtin_predicate(aTHX_ ":is_string", builtin_is_string);
    register_builtin_predicate(aTHX_ ":is_number", builtin_is_number);
    register_builtin_predicate(aTHX_ ":is_integer", builtin_is_integer);
}

/* ============================================
   Custom OP implementations - fastest path
   ============================================ */

/* identity: just return the top of stack */
static OP* pp_identity(pTHX) {
    /* Value already on stack, nothing to do */
    return NORMAL;
}

/* always: push stored value from op_targ index */
static OP* pp_always(pTHX) {
    dSP;
    IV idx = PL_op->op_targ;
    XPUSHs(g_always_values[idx]);
    RETURN;
}

/* clamp: 3 values on stack, return clamped */
static OP* pp_clamp(pTHX) {
    dSP; dMARK; dORIGMARK;
    SV *val_sv, *min_sv, *max_sv;
    NV value, min, max, result;
    
    /* We get 3 args on stack after the mark */
    if (SP - MARK != 3) {
        /* Fallback: just use direct POPs if no mark context */
        SP = ORIGMARK;
        PUTBACK;
        /* Pop without mark - shouldn't happen in list context */
        dSP;
        max_sv = POPs;
        min_sv = POPs;
        val_sv = POPs;
    } else {
        val_sv = MARK[1];
        min_sv = MARK[2];
        max_sv = MARK[3];
        SP = ORIGMARK;  /* reset stack to before args */
    }

    value = SvNV(val_sv);
    min = SvNV(min_sv);
    max = SvNV(max_sv);

    if (value < min) {
        result = min;
    } else if (value > max) {
        result = max;
    } else {
        result = value;
    }
    
    PUSHs(sv_2mortal(newSVnv(result)));
    RETURN;
}

/* nvl: 2 values on stack, return first if defined */
static OP* pp_nvl(pTHX) {
    dSP;
    SV *def_sv = POPs;
    SV *val_sv = TOPs;

    if (!SvOK(val_sv)) {
        SETs(def_sv);
    }
    RETURN;
}

/* ============================================
   Type predicate custom ops - blazing fast!
   These are the fastest possible type checks:
   single SV flag check, no function call overhead
   ============================================ */

/* is_ref: check if value is a reference */
static OP* pp_is_ref(pTHX) {
    dSP;
    SV *sv = TOPs;
    SETs(SvROK(sv) ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

/* is_array: check if value is an arrayref */
static OP* pp_is_array(pTHX) {
    dSP;
    SV *sv = TOPs;
    SETs((SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

/* is_hash: check if value is a hashref */
static OP* pp_is_hash(pTHX) {
    dSP;
    SV *sv = TOPs;
    SETs((SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV) ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

/* is_code: check if value is a coderef */
static OP* pp_is_code(pTHX) {
    dSP;
    SV *sv = TOPs;
    SETs((SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV) ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

/* is_defined: check if value is defined */
static OP* pp_is_defined(pTHX) {
    dSP;
    SV *sv = TOPs;
    SETs(SvOK(sv) ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

/* ============================================
   String predicate custom ops - blazing fast!
   Direct SvPV/SvCUR access, no function overhead
   ============================================ */

/* is_empty: check if string is undefined or empty */
static OP* pp_is_empty(pTHX) {
    dSP;
    SV *sv = TOPs;
    /* Empty if: undefined OR length is 0 */
    if (!SvOK(sv)) {
        SETs(&PL_sv_yes);
    } else {
        STRLEN len;
        SvPV(sv, len);
        SETs(len == 0 ? &PL_sv_yes : &PL_sv_no);
    }
    RETURN;
}

/* starts_with: check if string starts with prefix */
static OP* pp_starts_with(pTHX) {
    dSP;
    SV *prefix_sv = POPs;
    SV *str_sv = TOPs;

    if (!SvOK(str_sv) || !SvOK(prefix_sv)) {
        SETs(&PL_sv_no);
        RETURN;
    }

    STRLEN str_len, prefix_len;
    const char *str = SvPV(str_sv, str_len);
    const char *prefix = SvPV(prefix_sv, prefix_len);

    if (prefix_len > str_len) {
        SETs(&PL_sv_no);
    } else if (prefix_len == 0) {
        SETs(&PL_sv_yes);  /* Empty prefix always matches */
    } else {
        SETs(memcmp(str, prefix, prefix_len) == 0 ? &PL_sv_yes : &PL_sv_no);
    }
    RETURN;
}

/* ends_with: check if string ends with suffix */
static OP* pp_ends_with(pTHX) {
    dSP;
    SV *suffix_sv = POPs;
    SV *str_sv = TOPs;

    if (!SvOK(str_sv) || !SvOK(suffix_sv)) {
        SETs(&PL_sv_no);
        RETURN;
    }

    STRLEN str_len, suffix_len;
    const char *str = SvPV(str_sv, str_len);
    const char *suffix = SvPV(suffix_sv, suffix_len);

    if (suffix_len > str_len) {
        SETs(&PL_sv_no);
    } else if (suffix_len == 0) {
        SETs(&PL_sv_yes);  /* Empty suffix always matches */
    } else {
        const char *str_end = str + str_len - suffix_len;
        SETs(memcmp(str_end, suffix, suffix_len) == 0 ? &PL_sv_yes : &PL_sv_no);
    }
    RETURN;
}

/* ============================================
   Boolean/Truthiness custom ops - blazing fast!
   Direct SvTRUE check, minimal overhead
   ============================================ */

/* is_true: check if value is truthy (Perl truth semantics) */
static OP* pp_is_true(pTHX) {
    dSP;
    SV *sv = TOPs;
    SETs(SvTRUE(sv) ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

/* is_false: check if value is falsy (Perl truth semantics) */
static OP* pp_is_false(pTHX) {
    dSP;
    SV *sv = TOPs;
    SETs(SvTRUE(sv) ? &PL_sv_no : &PL_sv_yes);
    RETURN;
}

/* bool: normalize to boolean (1 or empty string) */
static OP* pp_bool(pTHX) {
    dSP;
    SV *sv = TOPs;
    SETs(SvTRUE(sv) ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

/* ============================================
   Extended type predicate custom ops - blazing fast!
   ============================================ */

/* is_num: check if value is numeric (has numeric value or looks like number) */
static OP* pp_is_num(pTHX) {
    dSP;
    SV *sv = TOPs;
    /* SvNIOK: has numeric (NV or IV) value cached */
    /* Also check looks_like_number for strings that can be numbers */
    SETs((SvNIOK(sv) || looks_like_number(sv)) ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

/* is_int: check if value is an integer */
static OP* pp_is_int(pTHX) {
    dSP;
    SV *sv = TOPs;
    /* SvIOK: has integer value cached */
    if (SvIOK(sv)) {
        SETs(&PL_sv_yes);
    } else if (SvNOK(sv)) {
        /* It's a float - check if it's a whole number */
        NV nv = SvNV(sv);
        SETs((nv == (NV)(IV)nv) ? &PL_sv_yes : &PL_sv_no);
    } else if (looks_like_number(sv)) {
        /* String that looks like a number - check if integer */
        STRLEN len;
        const char *pv = SvPV(sv, len);
        /* Simple check: no decimal point or exponent */
        bool has_dot = FALSE;
        STRLEN i;
        for (i = 0; i < len; i++) {
            if (pv[i] == '.' || pv[i] == 'e' || pv[i] == 'E') {
                has_dot = TRUE;
                break;
            }
        }
        if (has_dot) {
            /* Has decimal - check if value is actually integer */
            NV nv = SvNV(sv);
            SETs((nv == (NV)(IV)nv) ? &PL_sv_yes : &PL_sv_no);
        } else {
            SETs(&PL_sv_yes);
        }
    } else {
        SETs(&PL_sv_no);
    }
    RETURN;
}

/* is_blessed: check if value is a blessed reference */
static OP* pp_is_blessed(pTHX) {
    dSP;
    SV *sv = TOPs;
    SETs(sv_isobject(sv) ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

/* is_scalar_ref: check if value is a scalar reference (not array/hash/code/etc) */
static OP* pp_is_scalar_ref(pTHX) {
    dSP;
    SV *sv = TOPs;
    if (SvROK(sv)) {
        SV *rv = SvRV(sv);
        svtype type = SvTYPE(rv);
        /* Scalar refs are < SVt_PVAV (array) */
        SETs((type < SVt_PVAV) ? &PL_sv_yes : &PL_sv_no);
    } else {
        SETs(&PL_sv_no);
    }
    RETURN;
}

/* is_regex: check if value is a compiled regex */
static OP* pp_is_regex(pTHX) {
    dSP;
    SV *sv = TOPs;
    /* SvRXOK: check if SV is a regex (qr//) - available since Perl 5.10 */
    SETs(SvRXOK(sv) ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

/* is_glob: check if value is a glob (*foo) */
static OP* pp_is_glob(pTHX) {
    dSP;
    SV *sv = TOPs;
    SETs((SvTYPE(sv) == SVt_PVGV) ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

/* is_string: check if value is a plain scalar (defined, not a reference) */
static OP* pp_is_string(pTHX) {
    dSP;
    SV *sv = TOPs;
    SETs((SvOK(sv) && !SvROK(sv)) ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

/* ============================================
   Numeric predicate custom ops - blazing fast!
   Direct SvNV comparison, minimal overhead
   ============================================ */

/* is_positive: check if value is > 0 */
static OP* pp_is_positive(pTHX) {
    dSP;
    SV *sv = TOPs;
    if (SvNIOK(sv) || looks_like_number(sv)) {
        NV nv = SvNV(sv);
        SETs((nv > 0) ? &PL_sv_yes : &PL_sv_no);
    } else {
        SETs(&PL_sv_no);
    }
    RETURN;
}

/* is_negative: check if value is < 0 */
static OP* pp_is_negative(pTHX) {
    dSP;
    SV *sv = TOPs;
    if (SvNIOK(sv) || looks_like_number(sv)) {
        NV nv = SvNV(sv);
        SETs((nv < 0) ? &PL_sv_yes : &PL_sv_no);
    } else {
        SETs(&PL_sv_no);
    }
    RETURN;
}

/* is_zero: check if value is == 0 */
static OP* pp_is_zero(pTHX) {
    dSP;
    SV *sv = TOPs;
    if (SvNIOK(sv) || looks_like_number(sv)) {
        NV nv = SvNV(sv);
        SETs((nv == 0) ? &PL_sv_yes : &PL_sv_no);
    } else {
        SETs(&PL_sv_no);
    }
    RETURN;
}

/* ============================================
   Numeric utility custom ops
   ============================================ */

/* is_even: check if integer is even (single bitwise AND) */
static OP* pp_is_even(pTHX) {
    dSP;
    SV *sv = TOPs;
    if (SvIOK(sv)) {
        SETs((SvIVX(sv) & 1) == 0 ? &PL_sv_yes : &PL_sv_no);
    } else if (SvNIOK(sv)) {
        NV nv = SvNV(sv);
        if (nv == (NV)(IV)nv) {
            SETs(((IV)nv & 1) == 0 ? &PL_sv_yes : &PL_sv_no);
        } else {
            SETs(&PL_sv_no);
        }
    } else if (looks_like_number(sv)) {
        SETs((SvIV(sv) & 1) == 0 ? &PL_sv_yes : &PL_sv_no);
    } else {
        SETs(&PL_sv_no);
    }
    RETURN;
}

/* is_odd: check if integer is odd (single bitwise AND) */
static OP* pp_is_odd(pTHX) {
    dSP;
    SV *sv = TOPs;
    if (SvIOK(sv)) {
        SETs((SvIVX(sv) & 1) == 1 ? &PL_sv_yes : &PL_sv_no);
    } else if (SvNIOK(sv)) {
        NV nv = SvNV(sv);
        if (nv == (NV)(IV)nv) {
            SETs(((IV)nv & 1) == 1 ? &PL_sv_yes : &PL_sv_no);
        } else {
            SETs(&PL_sv_no);
        }
    } else if (looks_like_number(sv)) {
        SETs((SvIV(sv) & 1) == 1 ? &PL_sv_yes : &PL_sv_no);
    } else {
        SETs(&PL_sv_no);
    }
    RETURN;
}

/* is_between: check if value is between min and max (inclusive) */
static OP* pp_is_between(pTHX) {
    dSP;
    SV *max_sv = POPs;
    SV *min_sv = POPs;
    SV *val_sv = TOPs;

    if (SvNIOK(val_sv) || looks_like_number(val_sv)) {
        NV val = SvNV(val_sv);
        NV min = SvNV(min_sv);
        NV max = SvNV(max_sv);
        SETs((val >= min && val <= max) ? &PL_sv_yes : &PL_sv_no);
    } else {
        SETs(&PL_sv_no);
    }
    RETURN;
}

/* ============================================
   Collection custom ops - direct AvFILL/HvKEYS access
   ============================================ */

/* is_empty_array: check if arrayref is empty - direct AvFILL */
static OP* pp_is_empty_array(pTHX) {
    dSP;
    SV *sv = TOPs;
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        AV *av = (AV*)SvRV(sv);
        SETs(AvFILL(av) < 0 ? &PL_sv_yes : &PL_sv_no);
    } else {
        SETs(&PL_sv_no);  /* Not an arrayref */
    }
    RETURN;
}

/* is_empty_hash: check if hashref is empty - direct HvKEYS */
static OP* pp_is_empty_hash(pTHX) {
    dSP;
    SV *sv = TOPs;
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV) {
        HV *hv = (HV*)SvRV(sv);
        SETs(HvKEYS(hv) == 0 ? &PL_sv_yes : &PL_sv_no);
    } else {
        SETs(&PL_sv_no);  /* Not a hashref */
    }
    RETURN;
}

/* array_len: get array length - direct AvFILL + 1 */
static OP* pp_array_len(pTHX) {
    dSP;
    SV *sv = TOPs;
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        AV *av = (AV*)SvRV(sv);
        SV *len = sv_2mortal(newSViv(AvFILL(av) + 1));
        SETs(len);
    } else {
        SETs(&PL_sv_undef);  /* Not an arrayref */
    }
    RETURN;
}

/* hash_size: get hash key count - direct HvKEYS */
static OP* pp_hash_size(pTHX) {
    dSP;
    SV *sv = TOPs;
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV) {
        HV *hv = (HV*)SvRV(sv);
        SV *size = sv_2mortal(newSViv(HvKEYS(hv)));
        SETs(size);
    } else {
        SETs(&PL_sv_undef);  /* Not a hashref */
    }
    RETURN;
}

/* array_first: get first element without slice overhead */
static OP* pp_array_first(pTHX) {
    dSP;
    SV *sv = TOPs;
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        AV *av = (AV*)SvRV(sv);
        if (AvFILL(av) >= 0) {
            SV **elem = av_fetch(av, 0, 0);
            SETs(elem ? *elem : &PL_sv_undef);
        } else {
            SETs(&PL_sv_undef);  /* Empty array */
        }
    } else {
        SETs(&PL_sv_undef);  /* Not an arrayref */
    }
    RETURN;
}

/* array_last: get last element without slice overhead */
static OP* pp_array_last(pTHX) {
    dSP;
    SV *sv = TOPs;
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        AV *av = (AV*)SvRV(sv);
        IV last_idx = AvFILL(av);
        if (last_idx >= 0) {
            SV **elem = av_fetch(av, last_idx, 0);
            SETs(elem ? *elem : &PL_sv_undef);
        } else {
            SETs(&PL_sv_undef);  /* Empty array */
        }
    } else {
        SETs(&PL_sv_undef);  /* Not an arrayref */
    }
    RETURN;
}


/* ============================================
   String manipulation custom ops
   ============================================ */

/* trim: remove leading/trailing whitespace */
static OP* pp_trim(pTHX) {
    dSP;
    SV *sv = TOPs;

    if (!SvOK(sv)) {
        SETs(&PL_sv_undef);
        RETURN;
    }

    STRLEN len;
    const char *str = SvPV(sv, len);
    const char *start = str;
    const char *end = str + len;

    /* Skip leading whitespace */
    while (start < end && isSPACE(*start)) {
        start++;
    }

    /* Skip trailing whitespace */
    while (end > start && isSPACE(*(end - 1))) {
        end--;
    }

    /* Create new SV with trimmed content */
    SV *result = sv_2mortal(newSVpvn(start, end - start));
    SETs(result);
    RETURN;
}

/* ltrim: remove leading whitespace only */
static OP* pp_ltrim(pTHX) {
    dSP;
    SV *sv = TOPs;

    if (!SvOK(sv)) {
        SETs(&PL_sv_undef);
        RETURN;
    }

    STRLEN len;
    const char *str = SvPV(sv, len);
    const char *start = str;
    const char *end = str + len;

    /* Skip leading whitespace */
    while (start < end && isSPACE(*start)) {
        start++;
    }

    SV *result = sv_2mortal(newSVpvn(start, end - start));
    SETs(result);
    RETURN;
}

/* rtrim: remove trailing whitespace only */
static OP* pp_rtrim(pTHX) {
    dSP;
    SV *sv = TOPs;

    if (!SvOK(sv)) {
        SETs(&PL_sv_undef);
        RETURN;
    }

    STRLEN len;
    const char *str = SvPV(sv, len);
    const char *end = str + len;

    /* Skip trailing whitespace */
    while (end > str && isSPACE(*(end - 1))) {
        end--;
    }

    SV *result = sv_2mortal(newSVpvn(str, end - str));
    SETs(result);
    RETURN;
}

/* ============================================
   Conditional custom ops
   ============================================ */

/* maybe: return $then if $val is defined, else undef */
static OP* pp_maybe(pTHX) {
    dSP;
    SV *then_sv = POPs;
    SV *val_sv = TOPs;

    if (SvOK(val_sv)) {
        SETs(then_sv);
    } else {
        SETs(&PL_sv_undef);
    }
    RETURN;
}

/* ============================================
   Numeric custom ops
   ============================================ */

/* sign: return -1, 0, or 1 based on value */
static OP* pp_sign(pTHX) {
    dSP;
    SV *sv = TOPs;

    if (!SvNIOK(sv) && !looks_like_number(sv)) {
        SETs(&PL_sv_undef);
        RETURN;
    }

    NV nv = SvNV(sv);
    if (nv > 0) {
        SETs(sv_2mortal(newSViv(1)));
    } else if (nv < 0) {
        SETs(sv_2mortal(newSViv(-1)));
    } else {
        SETs(sv_2mortal(newSViv(0)));
    }
    RETURN;
}

/* min2: return smaller of two values */
static OP* pp_min2(pTHX) {
    dSP;
    SV *b_sv = POPs;
    SV *a_sv = TOPs;

    NV a = SvNV(a_sv);
    NV b = SvNV(b_sv);

    SETs(a <= b ? a_sv : b_sv);
    RETURN;
}

/* max2: return larger of two values */
static OP* pp_max2(pTHX) {
    dSP;
    SV *b_sv = POPs;
    SV *a_sv = TOPs;

    NV a = SvNV(a_sv);
    NV b = SvNV(b_sv);

    SETs(a >= b ? a_sv : b_sv);
    RETURN;
}


/* ============================================
   Call checkers - replace function calls with custom ops
   ============================================ */

/* 
 * Check if an op is accessing $_ (the default variable).
 * Custom ops now properly handle list context with marks,
 * but we still fall back to XS for $_ because of how map/grep
 * set up the op tree with $_ - the argument evaluation is different.
 * Returns TRUE if we should fall back to XS.
 */
static bool op_is_dollar_underscore(pTHX_ OP *op) {
    if (!op) return FALSE;
    
    /* Check for $_ access: rv2sv -> gv for "_" */
    if (op->op_type == OP_RV2SV) {
        OP *gvop = cUNOPx(op)->op_first;
        if (gvop && gvop->op_type == OP_GV) {
            GV *gv = cGVOPx_gv(gvop);
            if (gv && GvNAMELEN(gv) == 1 && GvNAME(gv)[0] == '_') {
                return TRUE;
            }
        }
    }
    
    return FALSE;
}

/* identity call checker - replaces identity($x) with just $x */
static OP* identity_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    OP *pushop, *argop, *cvop;

    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);

    /* Get the argument list */
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) {
        pushop = cUNOPx(pushop)->op_first;
    }

    /* Find first real arg (skip pushmark) */
    argop = OpSIBLING(pushop);

    /* Find the cv op (last sibling) */
    cvop = argop;
    while (OpHAS_SIBLING(cvop)) {
        cvop = OpSIBLING(cvop);
    }

    /* Check for exactly one argument */
    if (argop != cvop && OpSIBLING(argop) == cvop) {
        /* Single arg - just return the arg itself */
        OP *arg = argop;

        /* If arg is $_, fall back to XS (map/grep context) */
        if (op_is_dollar_underscore(aTHX_ arg)) {
            return entersubop;
        }

        /* Detach arg from list */
        OpMORESIB_set(pushop, cvop);
        OpLASTSIB_set(arg, NULL);

        op_free(entersubop);
        return arg;  /* Just return the argument op directly! */
    }

    /* Fall through to XS for edge cases */
    return entersubop;
}

/* clamp call checker - replaces clamp($v, $min, $max) with custom op */
static OP* clamp_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    OP *pushop, *arg1, *arg2, *arg3, *cvop;
    OP *listop;

    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);

    /* Get the argument list */
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) {
        pushop = cUNOPx(pushop)->op_first;
    }

    /* Find args (skip pushmark) */
    arg1 = OpSIBLING(pushop);  /* value */
    if (!arg1) return entersubop;

    arg2 = OpSIBLING(arg1);    /* min */
    if (!arg2) return entersubop;

    arg3 = OpSIBLING(arg2);    /* max */
    if (!arg3) return entersubop;

    cvop = OpSIBLING(arg3);    /* cv op (should be last) */
    if (!cvop || OpHAS_SIBLING(cvop)) return entersubop;

    /* 
     * If arg1 is accessing $_, we're likely in map/grep.
     * The custom op doesn't work correctly in these contexts.
     * Fall back to XS.
     */
    if (op_is_dollar_underscore(aTHX_ arg1)) {
        return entersubop;
    }

    /* Detach args from the entersub tree */
    OpMORESIB_set(pushop, cvop);

    /* Chain arg1 -> arg2 -> arg3 */
    OpMORESIB_set(arg1, arg2);
    OpMORESIB_set(arg2, arg3);
    OpLASTSIB_set(arg3, NULL);

    /* 
     * Create a LISTOP with 3 children for clamp.
     * We use op_convert_list to properly set up a list context.
     */
    listop = op_convert_list(OP_LIST, OPf_STACKED, arg1);
    listop->op_type = OP_CUSTOM;
    listop->op_ppaddr = pp_clamp;
    listop->op_flags = (listop->op_flags & ~OPf_WANT) | OPf_WANT_SCALAR | OPf_STACKED;
    listop->op_targ = pad_alloc(OP_NULL, SVs_PADTMP);

    op_free(entersubop);
    return listop;
}

/* Generic call checker for single-arg type predicates */
static OP* type_predicate_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj, OP* (*pp_func)(pTHX)) {
    OP *pushop, *argop, *cvop;

    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);

    /* Get the argument list */
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) {
        pushop = cUNOPx(pushop)->op_first;
    }

    /* Find first real arg (skip pushmark) */
    argop = OpSIBLING(pushop);

    /* Find the cv op (last sibling) */
    cvop = argop;
    while (OpHAS_SIBLING(cvop)) {
        cvop = OpSIBLING(cvop);
    }

    /* Check for exactly one argument */
    if (argop != cvop && OpSIBLING(argop) == cvop) {
        OP *arg = argop;

        /* If arg is $_, fall back to XS (map/grep context) */
        if (op_is_dollar_underscore(aTHX_ arg)) {
            return entersubop;
        }

        /* Detach arg from list */
        OpMORESIB_set(pushop, cvop);
        OpLASTSIB_set(arg, NULL);

        /* Create unary custom op with arg as child.
           Build as OP_NULL first, then convert to OP_CUSTOM — calling
           newUNOP(OP_CUSTOM, ...) directly trips the
           Perl_newUNOP: Assertion `(PL_opargs[type] & OA_CLASS_MASK) == OA_UNOP'
           on -DDEBUGGING perls because OP_CUSTOM has no fixed class. */
        OP *newop = newUNOP(OP_NULL, 0, arg);
        newop->op_type   = OP_CUSTOM;
        newop->op_ppaddr = pp_func;

        op_free(entersubop);
        return newop;
    }

    /* Fall through to XS for edge cases */
    return entersubop;
}

/* Individual call checkers for each type predicate */
static OP* is_ref_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_ref);
}

static OP* is_array_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_array);
}

static OP* is_hash_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_hash);
}

static OP* is_code_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_code);
}

static OP* is_defined_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_defined);
}

/* String predicate call checkers */
static OP* is_empty_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_empty);
}

/* Generic two-arg string predicate call checker */
static OP* two_arg_string_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj, OP* (*pp_func)(pTHX)) {
    OP *pushop, *arg1, *arg2, *cvop;

    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);

    /* Get the argument list */
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) {
        pushop = cUNOPx(pushop)->op_first;
    }

    /* Find args (skip pushmark) */
    arg1 = OpSIBLING(pushop);  /* string */
    if (!arg1) return entersubop;

    arg2 = OpSIBLING(arg1);    /* prefix/suffix */
    if (!arg2) return entersubop;

    cvop = OpSIBLING(arg2);    /* cv op (should be last) */
    if (!cvop || OpHAS_SIBLING(cvop)) return entersubop;

    /* If arg1 is $_, fall back to XS (map/grep context) */
    if (op_is_dollar_underscore(aTHX_ arg1)) {
        return entersubop;
    }

    /* Detach args from the entersub tree */
    OpMORESIB_set(pushop, cvop);

    /* Chain arg1 -> arg2 */
    OpMORESIB_set(arg1, arg2);
    OpLASTSIB_set(arg2, NULL);

    /* 
     * Create a custom BINOP-style op.
     * Use newBINOP to create a proper binary op structure where
     * both arguments are children. The optimizer won't eliminate
     * children of an op that's going to use them.
     */
    OP *binop = newBINOP(OP_NULL, 0, arg1, arg2);
    binop->op_type = OP_CUSTOM;
    binop->op_ppaddr = pp_func;
    binop->op_flags = OPf_WANT_SCALAR | OPf_KIDS | OPf_STACKED;

    op_free(entersubop);
    return binop;
}

static OP* starts_with_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return two_arg_string_call_checker(aTHX_ entersubop, namegv, ckobj, pp_starts_with);
}

static OP* ends_with_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return two_arg_string_call_checker(aTHX_ entersubop, namegv, ckobj, pp_ends_with);
}

/* Boolean/Truthiness call checkers */
static OP* is_true_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_true);
}

static OP* is_false_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_false);
}

static OP* bool_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_bool);
}

/* Extended type predicate call checkers */
static OP* is_num_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_num);
}

static OP* is_int_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_int);
}

static OP* is_blessed_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_blessed);
}

static OP* is_scalar_ref_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_scalar_ref);
}

static OP* is_regex_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_regex);
}

static OP* is_glob_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_glob);
}

static OP* is_string_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_string);
}

/* Numeric predicate call checkers */
static OP* is_positive_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_positive);
}

static OP* is_negative_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_negative);
}

static OP* is_zero_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_zero);
}

/* Numeric utility call checkers */
static OP* is_even_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_even);
}

static OP* is_odd_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_odd);
}

/* is_between needs 3 args - use same pattern as clamp */
static OP* is_between_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    /* 3-arg ops are complex to optimize with custom ops.
     * Fall back to XS function for now. */
    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);
    return entersubop;
}

/* Collection call checkers */
static OP* is_empty_array_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_empty_array);
}

static OP* is_empty_hash_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_is_empty_hash);
}

static OP* array_len_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_array_len);
}

static OP* hash_size_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_hash_size);
}

static OP* array_first_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_array_first);
}

static OP* array_last_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_array_last);
}

/* trim uses single-arg pattern */
static OP* trim_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_trim);
}

static OP* ltrim_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_ltrim);
}

static OP* rtrim_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_rtrim);
}

/* maybe uses two-arg pattern */
static OP* maybe_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return two_arg_string_call_checker(aTHX_ entersubop, namegv, ckobj, pp_maybe);
}

/* Numeric ops */
static OP* sign_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return type_predicate_call_checker(aTHX_ entersubop, namegv, ckobj, pp_sign);
}

static OP* min2_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return two_arg_string_call_checker(aTHX_ entersubop, namegv, ckobj, pp_min2);
}

static OP* max2_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    return two_arg_string_call_checker(aTHX_ entersubop, namegv, ckobj, pp_max2);
}

/* ============================================
   Memo implementation
   ============================================ */

XS_INTERNAL(xs_memo) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::memo(\\&func)");

    SV *func = ST(0);
    if (!SvROK(func) || SvTYPE(SvRV(func)) != SVt_PVCV) {
        croak("Func::Util::memo requires a coderef");
    }

    /* Allocate memo slot */
    IV idx = g_memo_count++;
    ensure_memo_capacity(idx);

    MemoizedFunc *mf = &g_memos[idx];
    mf->func = SvREFCNT_inc_simple_NN(func);
    mf->cache = newHV();
    mf->hits = 0;
    mf->misses = 0;

    /* Create wrapper CV */
    CV *wrapper = newXS(NULL, xs_memo_call, __FILE__);
    CvXSUBANY(wrapper).any_iv = idx;

    /* Attach magic for cleanup when wrapper is freed */
    sv_magicext((SV*)wrapper, NULL, PERL_MAGIC_ext, &util_memo_vtbl, NULL, idx);

    ST(0) = sv_2mortal(newRV_noinc((SV*)wrapper));
    XSRETURN(1);
}

XS_INTERNAL(xs_memo_call) {
    dXSARGS;
    IV idx = CvXSUBANY(cv).any_iv;
    MemoizedFunc *mf = &g_memos[idx];

    /* Build cache key from arguments */
    SV *key = build_cache_key(aTHX_ &ST(0), items);
    STRLEN key_len;
    const char *key_pv = SvPV(key, key_len);

    /* Check cache */
    SV **cached = hv_fetch(mf->cache, key_pv, key_len, 0);
    if (cached && SvOK(*cached)) {
        mf->hits++;
        SvREFCNT_dec_NN(key);
        if (SvROK(*cached) && SvTYPE(SvRV(*cached)) == SVt_PVAV) {
            AV *av = (AV*)SvRV(*cached);
            IV len = av_len(av) + 1;
            IV i;
            EXTEND(SP, len);
            for (i = 0; i < len; i++) {
                SV **elem = av_fetch(av, i, 0);
                ST(i) = elem ? *elem : &PL_sv_undef;
            }
            XSRETURN(len);
        } else {
            ST(0) = *cached;
            XSRETURN(1);
        }
    }

    mf->misses++;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    IV i;
    EXTEND(SP, items);
    for (i = 0; i < items; i++) {
        PUSHs(ST(i));
    }
    PUTBACK;

    IV count = call_sv(mf->func, G_ARRAY);

    SPAGAIN;

    if (count == 1) {
        SV *result = SvREFCNT_inc(POPs);
        hv_store(mf->cache, key_pv, key_len, result, 0);
        PUTBACK;
        FREETMPS;
        LEAVE;
        SvREFCNT_dec_NN(key);
        ST(0) = result;
        XSRETURN(1);
    } else if (count > 0) {
        AV *av = newAV();
        av_extend(av, count - 1);
        for (i = count - 1; i >= 0; i--) {
            av_store(av, i, SvREFCNT_inc(POPs));
        }
        SV *result = newRV_noinc((SV*)av);
        hv_store(mf->cache, key_pv, key_len, result, 0);
        PUTBACK;
        FREETMPS;
        LEAVE;
        SvREFCNT_dec_NN(key);
        for (i = 0; i < count; i++) {
            SV **elem = av_fetch(av, i, 0);
            ST(i) = elem ? *elem : &PL_sv_undef;
        }
        XSRETURN(count);
    } else {
        hv_store(mf->cache, key_pv, key_len, &PL_sv_undef, 0);
        PUTBACK;
        FREETMPS;
        LEAVE;
        SvREFCNT_dec_NN(key);
        XSRETURN_EMPTY;
    }
}

/* ============================================
   Pipe/Compose implementation
   ============================================ */

XS_INTERNAL(xs_pipe) {
    dXSARGS;
    if (items < 2) croak("Usage: Func::Util::pipeline($value, \\&fn1, \\&fn2, ...)");

    SV *value = SvREFCNT_inc(ST(0));
    IV i;

    for (i = 1; i < items; i++) {
        SV *func = ST(i);
        if (!SvROK(func) || SvTYPE(SvRV(func)) != SVt_PVCV) {
            SvREFCNT_dec(value);
            croak("Func::Util::pipeline: argument %d is not a coderef", (int)i);
        }

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(value);
        PUTBACK;

        call_sv(func, G_SCALAR);

        SPAGAIN;
        SV *new_value = POPs;
        SvREFCNT_inc(new_value);
        PUTBACK;
        FREETMPS;
        LEAVE;

        SvREFCNT_dec(value);
        value = new_value;
    }

    ST(0) = sv_2mortal(value);
    XSRETURN(1);
}

XS_INTERNAL(xs_compose) {
    dXSARGS;
    if (items < 1) croak("Usage: Func::Util::compose(\\&fn1, \\&fn2, ...)");

    AV *funcs = newAV();
    av_extend(funcs, items - 1);
    IV i;
    for (i = 0; i < items; i++) {
        SV *func = ST(i);
        if (!SvROK(func) || SvTYPE(SvRV(func)) != SVt_PVCV) {
            croak("Func::Util::compose: argument %d is not a coderef", (int)(i+1));
        }
        av_store(funcs, i, SvREFCNT_inc_simple_NN(func));
    }

    CV *wrapper = newXS(NULL, xs_compose_call, __FILE__);
    CvXSUBANY(wrapper).any_ptr = (void*)funcs;

    /* Attach magic for cleanup when wrapper is freed - pass AV via mg_ptr */
    sv_magicext((SV*)wrapper, NULL, PERL_MAGIC_ext, &util_compose_vtbl, (char*)funcs, 0);

    ST(0) = sv_2mortal(newRV_noinc((SV*)wrapper));
    XSRETURN(1);
}

XS_INTERNAL(xs_compose_call) {
    dXSARGS;
    AV *funcs = (AV*)CvXSUBANY(cv).any_ptr;
    IV func_count = av_len(funcs) + 1;

    SV *value = NULL;

    IV i;
    for (i = func_count - 1; i >= 0; i--) {
        SV **func_ptr = av_fetch(funcs, i, 0);
        if (!func_ptr) continue;

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);

        if (i == func_count - 1) {
            IV j;
            EXTEND(SP, items);
            for (j = 0; j < items; j++) {
                PUSHs(ST(j));
            }
        } else {
            XPUSHs(value);
        }
        PUTBACK;

        call_sv(*func_ptr, G_SCALAR);

        SPAGAIN;
        SV *new_value = POPs;
        SvREFCNT_inc(new_value);
        PUTBACK;
        FREETMPS;
        LEAVE;

        if (value) SvREFCNT_dec(value);
        value = new_value;
    }

    ST(0) = value ? sv_2mortal(value) : &PL_sv_undef;
    XSRETURN(1);
}

/* ============================================
   Lazy evaluation implementation
   ============================================ */

XS_INTERNAL(xs_lazy) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::lazy(sub { ... })");

    SV *thunk = ST(0);
    if (!SvROK(thunk) || SvTYPE(SvRV(thunk)) != SVt_PVCV) {
        croak("Func::Util::lazy requires a coderef");
    }

    IV idx = g_lazy_count++;
    ensure_lazy_capacity(idx);

    LazyValue *lv = &g_lazies[idx];
    lv->thunk = SvREFCNT_inc_simple_NN(thunk);
    lv->value = NULL;
    lv->forced = FALSE;

    SV *obj = newSViv(idx);
    SV *ref = newRV_noinc(obj);
    sv_bless(ref, gv_stashpv("Func::Util::Lazy", GV_ADD));

    /* Attach magic for cleanup when lazy object is freed */
    sv_magicext(obj, NULL, PERL_MAGIC_ext, &util_lazy_vtbl, NULL, idx);

    ST(0) = sv_2mortal(ref);
    XSRETURN(1);
}

XS_INTERNAL(xs_force) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::force($lazy)");

    SV *lazy = ST(0);

    if (!SvROK(lazy) || !sv_derived_from(lazy, "Func::Util::Lazy")) {
        ST(0) = lazy;
        XSRETURN(1);
    }

    IV idx = SvIV(SvRV(lazy));
    if (idx < 0 || idx >= g_lazy_count) {
        croak("Func::Util::force: invalid lazy value");
    }

    LazyValue *lv = &g_lazies[idx];

    if (lv->forced) {
        ST(0) = lv->value;
        XSRETURN(1);
    }

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;

    call_sv(lv->thunk, G_SCALAR);

    SPAGAIN;
    lv->value = SvREFCNT_inc(POPs);
    lv->forced = TRUE;
    PUTBACK;
    FREETMPS;
    LEAVE;

    SvREFCNT_dec(lv->thunk);
    lv->thunk = NULL;

    ST(0) = lv->value;
    XSRETURN(1);
}

/* ============================================
   Safe navigation (dig) implementation
   ============================================ */

XS_INTERNAL(xs_dig) {
    dXSARGS;
    if (items < 2) croak("Usage: Func::Util::dig($hash, @keys)");

    SV *current = ST(0);
    IV i;

    for (i = 1; i < items; i++) {
        if (!SvROK(current) || SvTYPE(SvRV(current)) != SVt_PVHV) {
            XSRETURN_UNDEF;
        }

        HV *hv = (HV*)SvRV(current);
        SV *key = ST(i);
        STRLEN key_len;
        const char *key_pv = SvPV(key, key_len);

        SV **val = hv_fetch(hv, key_pv, key_len, 0);
        if (!val || !SvOK(*val)) {
            XSRETURN_UNDEF;
        }

        current = *val;
    }

    ST(0) = current;
    XSRETURN(1);
}

/* ============================================
   Tap implementation
   ============================================ */

XS_INTERNAL(xs_tap) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::tap(\\&block, $value)");

    SV *func = ST(0);
    SV *value = ST(1);

    if (!SvROK(func) || SvTYPE(SvRV(func)) != SVt_PVCV) {
        croak("Func::Util::tap: first argument must be a coderef");
    }

    ENTER;
    SAVETMPS;
    SAVE_DEFSV;
    DEFSV_set(value);

    PUSHMARK(SP);
    XPUSHs(value);
    PUTBACK;

    call_sv(func, G_DISCARD | G_VOID);

    SPAGAIN;
    FREETMPS;
    LEAVE;

    ST(0) = value;
    XSRETURN(1);
}

/* ============================================
   Clamp XS fallback
   ============================================ */

XS_INTERNAL(xs_clamp) {
    dXSARGS;
    NV value, min, max, result;
    if (items != 3) croak("Usage: Func::Util::clamp($value, $min, $max)");

    value = SvNV(ST(0));
    min = SvNV(ST(1));
    max = SvNV(ST(2));

    if (value < min) {
        result = min;
    } else if (value > max) {
        result = max;
    } else {
        result = value;
    }

    ST(0) = sv_2mortal(newSVnv(result));
    XSRETURN(1);
}

/* ============================================
   Identity XS fallback
   ============================================ */

XS_INTERNAL(xs_identity) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::identity($value)");
    XSRETURN(1);
}

/* ============================================
   Always implementation
   ============================================ */

XS_INTERNAL(xs_always) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::always($value)");

    IV idx = g_always_count++;
    ensure_always_capacity(idx);

    g_always_values[idx] = SvREFCNT_inc_simple_NN(ST(0));

    CV *wrapper = newXS(NULL, xs_always_call, __FILE__);
    CvXSUBANY(wrapper).any_iv = idx;

    /* Attach magic for cleanup when wrapper is freed */
    sv_magicext((SV*)wrapper, NULL, PERL_MAGIC_ext, &util_always_vtbl, NULL, idx);

    ST(0) = sv_2mortal(newRV_noinc((SV*)wrapper));
    XSRETURN(1);
}

XS_INTERNAL(xs_always_call) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    IV idx = CvXSUBANY(cv).any_iv;

    ST(0) = g_always_values[idx];
    XSRETURN(1);
}

/* ============================================
   Stub/noop functions - return constants
   ============================================ */

/* pp_noop - custom op that returns undef */
static OP* pp_noop(pTHX) {
    dSP;
    XPUSHs(&PL_sv_undef);
    RETURN;
}

/* noop call checker - replace with ultra-fast custom op */
static OP* noop_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    OP *newop;
    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);

    op_free(entersubop);

    NewOp(1101, newop, 1, OP);
    newop->op_type = OP_CUSTOM;
    newop->op_ppaddr = pp_noop;
    newop->op_flags = OPf_WANT_SCALAR;
    newop->op_next = newop;

    return newop;
}

/* noop() - does nothing, returns undef. Ignores all arguments. */
XS_INTERNAL(xs_noop) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    XSRETURN_UNDEF;
}

/* stub_true() - always returns true (1) */
XS_INTERNAL(xs_stub_true) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    XSRETURN_YES;
}

/* stub_false() - always returns false ('') */
XS_INTERNAL(xs_stub_false) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    XSRETURN_NO;
}

/* stub_array() - returns empty arrayref in scalar context, empty list in list context */
XS_INTERNAL(xs_stub_array) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    if (GIMME_V == G_ARRAY) {
        XSRETURN_EMPTY;
    }
    ST(0) = sv_2mortal(newRV_noinc((SV*)newAV()));
    XSRETURN(1);
}

/* stub_hash() - returns empty hashref in scalar context, empty list in list context */
XS_INTERNAL(xs_stub_hash) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    if (GIMME_V == G_ARRAY) {
        XSRETURN_EMPTY;
    }
    ST(0) = sv_2mortal(newRV_noinc((SV*)newHV()));
    XSRETURN(1);
}

/* stub_string() - always returns empty string '' */
XS_INTERNAL(xs_stub_string) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    /* Return shared empty string constant - XSRETURN_NO returns '' */
    XSRETURN_NO;
}

/* stub_zero() - always returns 0 */
XS_INTERNAL(xs_stub_zero) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    /* Return shared 0 SV */
    ST(0) = &PL_sv_zero;
    XSRETURN(1);
}

/* ============================================
   Functional combinators
   ============================================ */

/* negate(\&pred) - returns a function that returns the opposite */
XS_INTERNAL(xs_negate) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::negate(\\&predicate)");

    SV *pred = ST(0);
    if (!SvROK(pred) || SvTYPE(SvRV(pred)) != SVt_PVCV) {
        croak("Func::Util::negate: argument must be a coderef");
    }

    CV *wrapper = newXS(NULL, xs_negate_call, __FILE__);
    CvXSUBANY(wrapper).any_ptr = SvREFCNT_inc_simple_NN(pred);

    ST(0) = sv_2mortal(newRV_noinc((SV*)wrapper));
    XSRETURN(1);
}

XS_INTERNAL(xs_negate_call) {
    dXSARGS;
    SV *pred = (SV*)CvXSUBANY(cv).any_ptr;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    IV i;
    EXTEND(SP, items);
    for (i = 0; i < items; i++) {
        PUSHs(ST(i));
    }
    PUTBACK;

    call_sv(pred, G_SCALAR);

    SPAGAIN;
    SV *result = POPs;
    bool val = SvTRUE(result);
    PUTBACK;
    FREETMPS;
    LEAVE;

    ST(0) = val ? &PL_sv_no : &PL_sv_yes;
    XSRETURN(1);
}

/* once(\&f) - execute once, cache forever */
XS_INTERNAL(xs_once) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::once(\\&func)");

    SV *func = ST(0);
    if (!SvROK(func) || SvTYPE(SvRV(func)) != SVt_PVCV) {
        croak("Func::Util::once: argument must be a coderef");
    }

    IV idx = g_once_count++;
    ensure_once_capacity(idx);

    OnceFunc *of = &g_onces[idx];
    of->func = SvREFCNT_inc_simple_NN(func);
    of->result = NULL;
    of->called = FALSE;

    CV *wrapper = newXS(NULL, xs_once_call, __FILE__);
    CvXSUBANY(wrapper).any_iv = idx;

    /* Attach magic for cleanup when wrapper is freed */
    sv_magicext((SV*)wrapper, NULL, PERL_MAGIC_ext, &util_once_vtbl, NULL, idx);

    ST(0) = sv_2mortal(newRV_noinc((SV*)wrapper));
    XSRETURN(1);
}

XS_INTERNAL(xs_once_call) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    IV idx = CvXSUBANY(cv).any_iv;
    OnceFunc *of = &g_onces[idx];

    if (of->called) {
        ST(0) = of->result ? of->result : &PL_sv_undef;
        XSRETURN(1);
    }

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;

    call_sv(of->func, G_SCALAR);

    SPAGAIN;
    of->result = SvREFCNT_inc(POPs);
    of->called = TRUE;
    PUTBACK;
    FREETMPS;
    LEAVE;

    /* Free the original function, no longer needed */
    SvREFCNT_dec(of->func);
    of->func = NULL;

    ST(0) = of->result;
    XSRETURN(1);
}

/* partial(\&f, @bound) - bind first N args */
XS_INTERNAL(xs_partial) {
    dXSARGS;
    if (items < 1) croak("Usage: Func::Util::partial(\\&func, @bound_args)");

    SV *func = ST(0);
    if (!SvROK(func) || SvTYPE(SvRV(func)) != SVt_PVCV) {
        croak("Func::Util::partial: first argument must be a coderef");
    }

    IV idx = g_partial_count++;
    ensure_partial_capacity(idx);

    PartialFunc *pf = &g_partials[idx];
    pf->func = SvREFCNT_inc_simple_NN(func);
    pf->bound_args = newAV();

    /* Store bound arguments */
    IV i;
    for (i = 1; i < items; i++) {
        av_push(pf->bound_args, SvREFCNT_inc_simple_NN(ST(i)));
    }

    CV *wrapper = newXS(NULL, xs_partial_call, __FILE__);
    CvXSUBANY(wrapper).any_iv = idx;

    /* Attach magic for cleanup when wrapper is freed */
    sv_magicext((SV*)wrapper, NULL, PERL_MAGIC_ext, &util_partial_vtbl, NULL, idx);

    ST(0) = sv_2mortal(newRV_noinc((SV*)wrapper));
    XSRETURN(1);
}

XS_INTERNAL(xs_partial_call) {
    dXSARGS;
    IV idx = CvXSUBANY(cv).any_iv;
    PartialFunc *pf = &g_partials[idx];

    IV bound_count = av_len(pf->bound_args) + 1;
    IV total = bound_count + items;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    EXTEND(SP, total);

    /* Push bound args first */
    IV i;
    for (i = 0; i < bound_count; i++) {
        SV **elem = av_fetch(pf->bound_args, i, 0);
        PUSHs(elem ? *elem : &PL_sv_undef);
    }

    /* Push call-time args */
    for (i = 0; i < items; i++) {
        PUSHs(ST(i));
    }
    PUTBACK;

    IV count = call_sv(pf->func, G_SCALAR);

    SPAGAIN;
    SV *result = count > 0 ? POPs : &PL_sv_undef;
    SvREFCNT_inc(result);
    PUTBACK;
    FREETMPS;
    LEAVE;

    ST(0) = sv_2mortal(result);
    XSRETURN(1);
}

/* ============================================
   Data extraction functions
   ============================================ */

/* pick($hash, @keys) - extract subset of keys
 * Returns hashref in scalar context, flattened list in list context */
XS_INTERNAL(xs_pick) {
    dXSARGS;
    if (items < 1) croak("Usage: Func::Util::pick(\\%%hash, @keys)");

    SV *href = ST(0);
    if (!SvROK(href) || SvTYPE(SvRV(href)) != SVt_PVHV) {
        croak("Func::Util::pick: first argument must be a hashref");
    }

    HV *src = (HV*)SvRV(href);
    HV *dest = newHV();

    IV i;
    for (i = 1; i < items; i++) {
        SV *key = ST(i);
        STRLEN key_len;
        const char *key_pv = SvPV(key, key_len);

        SV **val = hv_fetch(src, key_pv, key_len, 0);
        if (val && SvOK(*val)) {
            hv_store(dest, key_pv, key_len, SvREFCNT_inc(*val), 0);
        }
    }

    /* Check calling context */
    if (GIMME_V == G_ARRAY) {
        /* List context - return flattened key-value pairs */
        IV n = HvUSEDKEYS(dest);
        SP -= items;  /* Reset stack pointer */
        EXTEND(SP, n * 2);

        hv_iterinit(dest);
        HE *he;
        while ((he = hv_iternext(dest)) != NULL) {
            STRLEN klen;
            const char *key = HePV(he, klen);
            mPUSHp(key, klen);
            mPUSHs(SvREFCNT_inc(HeVAL(he)));
        }
        SvREFCNT_dec((SV*)dest);  /* Free the temp hash */
        PUTBACK;
        return;
    }

    /* Scalar context - return hashref */
    ST(0) = sv_2mortal(newRV_noinc((SV*)dest));
    XSRETURN(1);
}

/* pluck(\@hashes, $field) - extract field from each hash */
XS_INTERNAL(xs_pluck) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::pluck(\\@array, $field)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::pluck: first argument must be an arrayref");
    }

    SV *field = ST(1);
    STRLEN field_len;
    const char *field_pv = SvPV(field, field_len);

    AV *src = (AV*)SvRV(aref);
    IV len = av_len(src) + 1;
    AV *dest = newAV();
    av_extend(dest, len - 1);

    IV i;
    for (i = 0; i < len; i++) {
        SV **elem = av_fetch(src, i, 0);
        if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
            HV *hv = (HV*)SvRV(*elem);
            SV **val = hv_fetch(hv, field_pv, field_len, 0);
            if (val && SvOK(*val)) {
                av_push(dest, SvREFCNT_inc(*val));
            } else {
                av_push(dest, &PL_sv_undef);
            }
        } else {
            av_push(dest, &PL_sv_undef);
        }
    }

    ST(0) = sv_2mortal(newRV_noinc((SV*)dest));
    XSRETURN(1);
}

/* omit($hash, @keys) - exclude subset of keys (inverse of pick)
 * Returns hashref in scalar context, flattened list in list context */
XS_INTERNAL(xs_omit) {
    dXSARGS;
    if (items < 1) croak("Usage: Func::Util::omit(\\%%hash, @keys)");

    SV *href = ST(0);
    if (!SvROK(href) || SvTYPE(SvRV(href)) != SVt_PVHV) {
        croak("Func::Util::omit: first argument must be a hashref");
    }

    HV *src = (HV*)SvRV(href);
    HV *dest = newHV();

    /* Build exclusion set for O(1) lookup */
    HV *exclude = newHV();
    IV i;
    for (i = 1; i < items; i++) {
        SV *key = ST(i);
        STRLEN key_len;
        const char *key_pv = SvPV(key, key_len);
        hv_store(exclude, key_pv, key_len, &PL_sv_yes, 0);
    }

    /* Iterate source, copy non-excluded keys */
    hv_iterinit(src);
    HE *entry;
    while ((entry = hv_iternext(src)) != NULL) {
        SV *key = hv_iterkeysv(entry);
        STRLEN key_len;
        const char *key_pv = SvPV(key, key_len);

        if (!hv_exists(exclude, key_pv, key_len)) {
            SV *val = hv_iterval(src, entry);
            if (SvOK(val)) {
                hv_store(dest, key_pv, key_len, SvREFCNT_inc(val), 0);
            }
        }
    }

    SvREFCNT_dec((SV*)exclude);

    /* Check calling context */
    if (GIMME_V == G_ARRAY) {
        /* List context - return flattened key-value pairs */
        IV n = HvUSEDKEYS(dest);
        SP -= items;  /* Reset stack pointer */
        EXTEND(SP, n * 2);

        hv_iterinit(dest);
        HE *he;
        while ((he = hv_iternext(dest)) != NULL) {
            STRLEN klen;
            const char *key = HePV(he, klen);
            mPUSHp(key, klen);
            mPUSHs(SvREFCNT_inc(HeVAL(he)));
        }
        SvREFCNT_dec((SV*)dest);  /* Free the temp hash */
        PUTBACK;
        return;
    }

    /* Scalar context - return hashref */
    ST(0) = sv_2mortal(newRV_noinc((SV*)dest));
    XSRETURN(1);
}

/* uniq(@list) - return unique elements (preserves order) */
XS_INTERNAL(xs_uniq) {
    dXSARGS;

    if (items == 0) {
        XSRETURN(0);
    }

    if (items == 1) {
        XSRETURN(1);
    }

    /* For small lists, use simple O(n^2) - faster due to no hash overhead */
    if (items <= 8) {
        IV out = 0;
        IV i, j;
        for (i = 0; i < items; i++) {
            SV *elem = ST(i);
            STRLEN len_i;
            const char *key_i = SvOK(elem) ? SvPV_const(elem, len_i) : "\x00UNDEF\x00";
            if (!SvOK(elem)) len_i = 7;
            
            bool dup = FALSE;
            for (j = 0; j < out; j++) {
                SV *prev = ST(j);
                STRLEN len_j;
                const char *key_j = SvOK(prev) ? SvPV_const(prev, len_j) : "\x00UNDEF\x00";
                if (!SvOK(prev)) len_j = 7;
                
                if (len_i == len_j && memcmp(key_i, key_j, len_i) == 0) {
                    dup = TRUE;
                    break;
                }
            }
            if (!dup) ST(out++) = elem;
        }
        XSRETURN(out);
    }

    HV *seen = newHV();
    IV out = 0;
    hv_ksplit(seen, items);

    IV i;
    for (i = 0; i < items; i++) {
        SV *elem = ST(i);
        STRLEN len;
        const char *key;
        U32 hash;

        key = SvOK(elem) ? SvPV_const(elem, len) : (len = 7, "\x00UNDEF\x00");

        PERL_HASH(hash, key, len);

        if (!hv_common(seen, NULL, key, len, 0, HV_FETCH_ISEXISTS, NULL, hash)) {
            hv_common(seen, NULL, key, len, 0, HV_FETCH_ISSTORE, &PL_sv_yes, hash);
            ST(out++) = elem;
        }
    }

    SvREFCNT_dec_NN((SV*)seen);
    XSRETURN(out);
}

/* partition(\&pred, @list) - split into [matches], [non-matches] */
XS_INTERNAL(xs_partition) {
    dXSARGS;
    if (items < 1) croak("Usage: Func::Util::partition(\\&block, @list)");

    SV *block = ST(0);
    if (!SvROK(block) || SvTYPE(SvRV(block)) != SVt_PVCV) {
        croak("Func::Util::partition: first argument must be a coderef");
    }

    IV list_len = items - 1;
    
    if (list_len == 0) {
        AV *pass = newAV();
        AV *fail = newAV();
        AV *outer = newAV();
        av_push(outer, newRV_noinc((SV*)pass));
        av_push(outer, newRV_noinc((SV*)fail));
        ST(0) = sv_2mortal(newRV_noinc((SV*)outer));
        XSRETURN(1);
    }

    AV *pass = newAV();
    AV *fail = newAV();
    av_extend(pass, list_len >> 1);
    av_extend(fail, list_len >> 1);

    SV *orig_defsv = DEFSV;

    IV i;
    for (i = 1; i < items; i++) {
        SV *elem = ST(i);

        DEFSV_set(elem);

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(elem);
        PUTBACK;

        call_sv(block, G_SCALAR);

        SPAGAIN;
        SV *result = POPs;
        bool matched = SvTRUE(result);
        PUTBACK;
        FREETMPS;
        LEAVE;

        if (matched) {
            av_push(pass, SvREFCNT_inc_simple_NN(elem));
        } else {
            av_push(fail, SvREFCNT_inc_simple_NN(elem));
        }
    }

    DEFSV_set(orig_defsv);

    AV *outer = newAV();
    av_push(outer, newRV_noinc((SV*)pass));
    av_push(outer, newRV_noinc((SV*)fail));

    ST(0) = sv_2mortal(newRV_noinc((SV*)outer));
    XSRETURN(1);
}

/* defaults($hash, $defaults) - fill in missing keys from defaults
 * Returns hashref in scalar context, flattened list in list context */
XS_INTERNAL(xs_defaults) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::defaults(\\%%hash, \\%%defaults)");

    SV *href = ST(0);
    SV *dref = ST(1);

    if (!SvROK(href) || SvTYPE(SvRV(href)) != SVt_PVHV) {
        croak("Func::Util::defaults: first argument must be a hashref");
    }
    if (!SvROK(dref) || SvTYPE(SvRV(dref)) != SVt_PVHV) {
        croak("Func::Util::defaults: second argument must be a hashref");
    }

    HV *src = (HV*)SvRV(href);
    HV *def = (HV*)SvRV(dref);

    /* Pre-size dest hash */
    IV src_keys = HvUSEDKEYS(src);
    IV def_keys = HvUSEDKEYS(def);
    HV *dest = newHV();
    hv_ksplit(dest, src_keys + def_keys);

    /* Copy all from source first */
    hv_iterinit(src);
    HE *entry;
    while ((entry = hv_iternext(src)) != NULL) {
        STRLEN key_len;
        const char *key_pv = HePV(entry, key_len);
        SV *val = HeVAL(entry);
        hv_store(dest, key_pv, key_len, SvREFCNT_inc_simple_NN(val), HeHASH(entry));
    }

    /* Fill in missing from defaults - use pre-computed hash */
    hv_iterinit(def);
    while ((entry = hv_iternext(def)) != NULL) {
        STRLEN key_len;
        const char *key_pv = HePV(entry, key_len);
        U32 hash = HeHASH(entry);

        /* Check if exists and is defined in dest */
        SV **existing = hv_fetch(dest, key_pv, key_len, 0);
        if (!existing || !SvOK(*existing)) {
            SV *val = HeVAL(entry);
            hv_store(dest, key_pv, key_len, SvREFCNT_inc_simple_NN(val), hash);
        }
    }

    /* Check calling context */
    if (GIMME_V == G_ARRAY) {
        /* List context - return flattened key-value pairs */
        IV n = HvUSEDKEYS(dest);
        SP -= items;  /* Reset stack pointer */
        EXTEND(SP, n * 2);

        hv_iterinit(dest);
        HE *he;
        while ((he = hv_iternext(dest)) != NULL) {
            STRLEN klen;
            const char *key = HePV(he, klen);
            mPUSHp(key, klen);
            mPUSHs(SvREFCNT_inc(HeVAL(he)));
        }
        SvREFCNT_dec((SV*)dest);  /* Free the temp hash */
        PUTBACK;
        return;
    }

    /* Scalar context - return hashref */
    ST(0) = sv_2mortal(newRV_noinc((SV*)dest));
    XSRETURN(1);
}

/* ============================================
   Null coalescing functions
   ============================================ */

/* nvl($x, $default) - return $x if defined, else $default */
XS_INTERNAL(xs_nvl) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::nvl($value, $default)");

    SV *val = ST(0);
    if (SvOK(val)) {
        XSRETURN(1);  /* Return first arg */
    }
    ST(0) = ST(1);
    XSRETURN(1);
}

/* coalesce($a, $b, ...) - return first defined value */
XS_INTERNAL(xs_coalesce) {
    dXSARGS;
    if (items < 1) croak("Usage: Func::Util::coalesce($val, ...)");

    IV i;
    for (i = 0; i < items; i++) {
        if (SvOK(ST(i))) {
            ST(0) = ST(i);
            XSRETURN(1);
        }
    }
    /* All undefined, return undef */
    ST(0) = &PL_sv_undef;
    XSRETURN(1);
}

/* ============================================
   List functions (first, any, all, none)

   These use MULTICALL for pure Perl subs which is significantly
   faster than call_sv() for repeated invocations.

   For XS subs, we fall back to call_sv().
   ============================================ */

/* Inline CALLRUNOPS - experimental optimization to skip function call overhead.
   Use cautiously - this inlines the runops loop directly. */
#define INLINE_RUNOPS() \
    STMT_START { \
        OP *_inline_op = PL_op; \
        while ((_inline_op = _inline_op->op_ppaddr(aTHX))) ; \
    } STMT_END

/* ============================================
   Specialized array predicates - pure C, no callback
   These are blazing fast because they avoid all Perl callback overhead
   ============================================ */

/* first_gt(\@array, $threshold) or first_gt(\@array, $key, $threshold)
   first element > threshold, pure C
   With key: first hash where hash->{key} > threshold */
XS_INTERNAL(xs_first_gt) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::first_gt(\\@array, $threshold) or first_gt(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::first_gt: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        /* Simple array of scalars */
        NV threshold = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) > threshold) {
                ST(0) = *elem;
                XSRETURN(1);
            }
        }
    } else {
        /* Array of hashes with key */
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) > threshold) {
                    ST(0) = *elem;
                    XSRETURN(1);
                }
            }
        }
    }

    XSRETURN_UNDEF;
}

/* first_lt(\@array, $threshold) or first_lt(\@array, $key, $threshold)
   first element < threshold, pure C */
XS_INTERNAL(xs_first_lt) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::first_lt(\\@array, $threshold) or first_lt(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::first_lt: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) < threshold) {
                ST(0) = *elem;
                XSRETURN(1);
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) < threshold) {
                    ST(0) = *elem;
                    XSRETURN(1);
                }
            }
        }
    }

    XSRETURN_UNDEF;
}

/* first_eq(\@array, $value) or first_eq(\@array, $key, $value)
   first element == value (numeric), pure C */
XS_INTERNAL(xs_first_eq) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::first_eq(\\@array, $value) or first_eq(\\@array, $key, $value)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::first_eq: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV target = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) == target) {
                ST(0) = *elem;
                XSRETURN(1);
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV target = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) == target) {
                    ST(0) = *elem;
                    XSRETURN(1);
                }
            }
        }
    }

    XSRETURN_UNDEF;
}

/* first_ge(\@array, $threshold) or first_ge(\@array, $key, $threshold)
   first element >= threshold, pure C */
XS_INTERNAL(xs_first_ge) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::first_ge(\\@array, $threshold) or first_ge(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::first_ge: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) >= threshold) {
                ST(0) = *elem;
                XSRETURN(1);
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) >= threshold) {
                    ST(0) = *elem;
                    XSRETURN(1);
                }
            }
        }
    }

    XSRETURN_UNDEF;
}

/* first_le(\@array, $threshold) or first_le(\@array, $key, $threshold)
   first element <= threshold, pure C */
XS_INTERNAL(xs_first_le) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::first_le(\\@array, $threshold) or first_le(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::first_le: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) <= threshold) {
                ST(0) = *elem;
                XSRETURN(1);
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) <= threshold) {
                    ST(0) = *elem;
                    XSRETURN(1);
                }
            }
        }
    }

    XSRETURN_UNDEF;
}

/* first_ne(\@array, $value) or first_ne(\@array, $key, $value)
   first element != value (numeric), pure C */
XS_INTERNAL(xs_first_ne) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::first_ne(\\@array, $value) or first_ne(\\@array, $key, $value)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::first_ne: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV target = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) != target) {
                ST(0) = *elem;
                XSRETURN(1);
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV target = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) != target) {
                    ST(0) = *elem;
                    XSRETURN(1);
                }
            }
        }
    }

    XSRETURN_UNDEF;
}

/* ============================================
   final_* - like first_* but iterates backwards
   ============================================ */

/* final_gt(\@array, $threshold) or final_gt(\@array, $key, $threshold)
   last element > threshold, pure C, backwards iteration */
XS_INTERNAL(xs_final_gt) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::final_gt(\\@array, $threshold) or final_gt(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::final_gt: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = len - 1; i >= 0; i--) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) > threshold) {
                ST(0) = *elem;
                XSRETURN(1);
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = len - 1; i >= 0; i--) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) > threshold) {
                    ST(0) = *elem;
                    XSRETURN(1);
                }
            }
        }
    }

    XSRETURN_UNDEF;
}

/* final_lt(\@array, $threshold) or final_lt(\@array, $key, $threshold) */
XS_INTERNAL(xs_final_lt) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::final_lt(\\@array, $threshold) or final_lt(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::final_lt: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = len - 1; i >= 0; i--) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) < threshold) {
                ST(0) = *elem;
                XSRETURN(1);
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = len - 1; i >= 0; i--) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) < threshold) {
                    ST(0) = *elem;
                    XSRETURN(1);
                }
            }
        }
    }

    XSRETURN_UNDEF;
}

/* final_ge(\@array, $threshold) or final_ge(\@array, $key, $threshold) */
XS_INTERNAL(xs_final_ge) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::final_ge(\\@array, $threshold) or final_ge(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::final_ge: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = len - 1; i >= 0; i--) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) >= threshold) {
                ST(0) = *elem;
                XSRETURN(1);
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = len - 1; i >= 0; i--) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) >= threshold) {
                    ST(0) = *elem;
                    XSRETURN(1);
                }
            }
        }
    }

    XSRETURN_UNDEF;
}

/* final_le(\@array, $threshold) or final_le(\@array, $key, $threshold) */
XS_INTERNAL(xs_final_le) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::final_le(\\@array, $threshold) or final_le(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::final_le: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = len - 1; i >= 0; i--) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) <= threshold) {
                ST(0) = *elem;
                XSRETURN(1);
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = len - 1; i >= 0; i--) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) <= threshold) {
                    ST(0) = *elem;
                    XSRETURN(1);
                }
            }
        }
    }

    XSRETURN_UNDEF;
}

/* final_eq(\@array, $value) or final_eq(\@array, $key, $value) */
XS_INTERNAL(xs_final_eq) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::final_eq(\\@array, $value) or final_eq(\\@array, $key, $value)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::final_eq: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV target = SvNV(ST(1));
        for (i = len - 1; i >= 0; i--) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) == target) {
                ST(0) = *elem;
                XSRETURN(1);
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV target = SvNV(ST(2));
        for (i = len - 1; i >= 0; i--) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) == target) {
                    ST(0) = *elem;
                    XSRETURN(1);
                }
            }
        }
    }

    XSRETURN_UNDEF;
}

/* final_ne(\@array, $value) or final_ne(\@array, $key, $value) */
XS_INTERNAL(xs_final_ne) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::final_ne(\\@array, $value) or final_ne(\\@array, $key, $value)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::final_ne: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV target = SvNV(ST(1));
        for (i = len - 1; i >= 0; i--) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) != target) {
                ST(0) = *elem;
                XSRETURN(1);
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV target = SvNV(ST(2));
        for (i = len - 1; i >= 0; i--) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) != target) {
                    ST(0) = *elem;
                    XSRETURN(1);
                }
            }
        }
    }

    XSRETURN_UNDEF;
}

/* any_gt(\@array, $threshold) or any_gt(\@array, $key, $threshold)
   true if any element > threshold, pure C */
XS_INTERNAL(xs_any_gt) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::any_gt(\\@array, $threshold) or any_gt(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::any_gt: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) > threshold) {
                XSRETURN_YES;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) > threshold) {
                    XSRETURN_YES;
                }
            }
        }
    }

    XSRETURN_NO;
}

/* any_lt(\@array, $threshold) or any_lt(\@array, $key, $threshold) */
XS_INTERNAL(xs_any_lt) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::any_lt(\\@array, $threshold) or any_lt(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::any_lt: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) < threshold) {
                XSRETURN_YES;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) < threshold) {
                    XSRETURN_YES;
                }
            }
        }
    }

    XSRETURN_NO;
}

/* any_ge(\@array, $threshold) or any_ge(\@array, $key, $threshold) */
XS_INTERNAL(xs_any_ge) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::any_ge(\\@array, $threshold) or any_ge(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::any_ge: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) >= threshold) {
                XSRETURN_YES;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) >= threshold) {
                    XSRETURN_YES;
                }
            }
        }
    }

    XSRETURN_NO;
}

/* any_le(\@array, $threshold) or any_le(\@array, $key, $threshold) */
XS_INTERNAL(xs_any_le) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::any_le(\\@array, $threshold) or any_le(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::any_le: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) <= threshold) {
                XSRETURN_YES;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) <= threshold) {
                    XSRETURN_YES;
                }
            }
        }
    }

    XSRETURN_NO;
}

/* any_eq(\@array, $value) or any_eq(\@array, $key, $value) */
XS_INTERNAL(xs_any_eq) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::any_eq(\\@array, $value) or any_eq(\\@array, $key, $value)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::any_eq: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV target = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) == target) {
                XSRETURN_YES;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV target = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) == target) {
                    XSRETURN_YES;
                }
            }
        }
    }

    XSRETURN_NO;
}

/* any_ne(\@array, $value) or any_ne(\@array, $key, $value) */
XS_INTERNAL(xs_any_ne) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::any_ne(\\@array, $value) or any_ne(\\@array, $key, $value)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::any_ne: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV target = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) != target) {
                XSRETURN_YES;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV target = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) != target) {
                    XSRETURN_YES;
                }
            }
        }
    }

    XSRETURN_NO;
}

/* all_gt(\@array, $n) - true if all elements > n, pure C */
/* all_gt(\@array, $threshold) or all_gt(\@array, $key, $threshold)
   true if all elements > threshold, pure C */
XS_INTERNAL(xs_all_gt) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::all_gt(\\@array, $threshold) or all_gt(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::all_gt: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (len == 0) XSRETURN_YES; /* vacuous truth */

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (!elem || SvNV(*elem) <= threshold) {
                XSRETURN_NO;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (!elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV) {
                XSRETURN_NO;
            }
            HV *hv = (HV *)SvRV(*elem);
            SV **val = hv_fetch(hv, key, strlen(key), 0);
            if (!val || SvNV(*val) <= threshold) {
                XSRETURN_NO;
            }
        }
    }

    XSRETURN_YES;
}

/* all_lt(\@array, $threshold) or all_lt(\@array, $key, $threshold) */
XS_INTERNAL(xs_all_lt) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::all_lt(\\@array, $threshold) or all_lt(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::all_lt: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (len == 0) XSRETURN_YES;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (!elem || SvNV(*elem) >= threshold) {
                XSRETURN_NO;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (!elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV) {
                XSRETURN_NO;
            }
            HV *hv = (HV *)SvRV(*elem);
            SV **val = hv_fetch(hv, key, strlen(key), 0);
            if (!val || SvNV(*val) >= threshold) {
                XSRETURN_NO;
            }
        }
    }

    XSRETURN_YES;
}

/* all_ge(\@array, $threshold) or all_ge(\@array, $key, $threshold) */
XS_INTERNAL(xs_all_ge) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::all_ge(\\@array, $threshold) or all_ge(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::all_ge: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (len == 0) XSRETURN_YES;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (!elem || SvNV(*elem) < threshold) {
                XSRETURN_NO;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (!elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV) {
                XSRETURN_NO;
            }
            HV *hv = (HV *)SvRV(*elem);
            SV **val = hv_fetch(hv, key, strlen(key), 0);
            if (!val || SvNV(*val) < threshold) {
                XSRETURN_NO;
            }
        }
    }

    XSRETURN_YES;
}

/* all_le(\@array, $threshold) or all_le(\@array, $key, $threshold) */
XS_INTERNAL(xs_all_le) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::all_le(\\@array, $threshold) or all_le(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::all_le: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (len == 0) XSRETURN_YES;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (!elem || SvNV(*elem) > threshold) {
                XSRETURN_NO;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (!elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV) {
                XSRETURN_NO;
            }
            HV *hv = (HV *)SvRV(*elem);
            SV **val = hv_fetch(hv, key, strlen(key), 0);
            if (!val || SvNV(*val) > threshold) {
                XSRETURN_NO;
            }
        }
    }

    XSRETURN_YES;
}

/* all_eq(\@array, $value) or all_eq(\@array, $key, $value) */
XS_INTERNAL(xs_all_eq) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::all_eq(\\@array, $value) or all_eq(\\@array, $key, $value)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::all_eq: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (len == 0) XSRETURN_YES;

    if (items == 2) {
        NV target = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (!elem || SvNV(*elem) != target) {
                XSRETURN_NO;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV target = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (!elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV) {
                XSRETURN_NO;
            }
            HV *hv = (HV *)SvRV(*elem);
            SV **val = hv_fetch(hv, key, strlen(key), 0);
            if (!val || SvNV(*val) != target) {
                XSRETURN_NO;
            }
        }
    }

    XSRETURN_YES;
}

/* all_ne(\@array, $value) or all_ne(\@array, $key, $value) */
XS_INTERNAL(xs_all_ne) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::all_ne(\\@array, $value) or all_ne(\\@array, $key, $value)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::all_ne: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (len == 0) XSRETURN_YES;

    if (items == 2) {
        NV target = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (!elem || SvNV(*elem) == target) {
                XSRETURN_NO;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV target = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (!elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV) {
                XSRETURN_NO;
            }
            HV *hv = (HV *)SvRV(*elem);
            SV **val = hv_fetch(hv, key, strlen(key), 0);
            if (!val || SvNV(*val) == target) {
                XSRETURN_NO;
            }
        }
    }

    XSRETURN_YES;
}

/* none_gt(\@array, $threshold) or none_gt(\@array, $key, $threshold)
   true if no element > threshold, pure C */
XS_INTERNAL(xs_none_gt) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::none_gt(\\@array, $threshold) or none_gt(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::none_gt: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) > threshold) {
                XSRETURN_NO;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) > threshold) {
                    XSRETURN_NO;
                }
            }
        }
    }

    XSRETURN_YES;
}

/* none_lt(\@array, $threshold) or none_lt(\@array, $key, $threshold) */
XS_INTERNAL(xs_none_lt) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::none_lt(\\@array, $threshold) or none_lt(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::none_lt: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) < threshold) {
                XSRETURN_NO;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) < threshold) {
                    XSRETURN_NO;
                }
            }
        }
    }

    XSRETURN_YES;
}

/* none_ge(\@array, $threshold) or none_ge(\@array, $key, $threshold) */
XS_INTERNAL(xs_none_ge) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::none_ge(\\@array, $threshold) or none_ge(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::none_ge: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) >= threshold) {
                XSRETURN_NO;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) >= threshold) {
                    XSRETURN_NO;
                }
            }
        }
    }

    XSRETURN_YES;
}

/* none_le(\@array, $threshold) or none_le(\@array, $key, $threshold) */
XS_INTERNAL(xs_none_le) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::none_le(\\@array, $threshold) or none_le(\\@array, $key, $threshold)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::none_le: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV threshold = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) <= threshold) {
                XSRETURN_NO;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV threshold = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) <= threshold) {
                    XSRETURN_NO;
                }
            }
        }
    }

    XSRETURN_YES;
}

/* none_eq(\@array, $value) or none_eq(\@array, $key, $value) */
XS_INTERNAL(xs_none_eq) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::none_eq(\\@array, $value) or none_eq(\\@array, $key, $value)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::none_eq: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV target = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) == target) {
                XSRETURN_NO;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV target = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) == target) {
                    XSRETURN_NO;
                }
            }
        }
    }

    XSRETURN_YES;
}

/* none_ne(\@array, $value) or none_ne(\@array, $key, $value) */
XS_INTERNAL(xs_none_ne) {
    dXSARGS;
    if (items < 2 || items > 3) croak("Usage: Func::Util::none_ne(\\@array, $value) or none_ne(\\@array, $key, $value)");

    SV *aref = ST(0);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::none_ne: first argument must be an arrayref");
    }

    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (items == 2) {
        NV target = SvNV(ST(1));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvNV(*elem) != target) {
                XSRETURN_NO;
            }
        }
    } else {
        char *key = SvPV_nolen(ST(1));
        NV target = SvNV(ST(2));
        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **val = hv_fetch(hv, key, strlen(key), 0);
                if (val && SvNV(*val) != target) {
                    XSRETURN_NO;
                }
            }
        }
    }

    XSRETURN_YES;
}

/* firstr(\&block, \@array) - first with arrayref, no stack flattening */
XS_INTERNAL(xs_firstr) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::firstr(\\&block, \\@array)");

    SV *block = ST(0);
    SV *aref = ST(1);

    if (!SvROK(block) || SvTYPE(SvRV(block)) != SVt_PVCV) {
        croak("Func::Util::firstr: first argument must be a coderef");
    }
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::firstr: second argument must be an arrayref");
    }

    CV *block_cv = (CV *)SvRV(block);
    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (len == 0) {
        XSRETURN_UNDEF;
    }

#ifdef dMULTICALL
    if (!CvISXSUB(block_cv)) {
        dMULTICALL;
        I32 gimme = G_SCALAR;

        SAVESPTR(GvSV(PL_defgv));
        PUSH_MULTICALL(block_cv);

        for (i = 0; i < len; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (!elem) continue;

            SV *def_sv = GvSV(PL_defgv) = *elem;
            SvTEMP_off(def_sv);

            MULTICALL;

            if (SvTRUE(*PL_stack_sp)) {
                POP_MULTICALL;
                ST(0) = *elem;
                XSRETURN(1);
            }
        }

        POP_MULTICALL;
        XSRETURN_UNDEF;
    }
#endif

    /* Fallback for XS subs */
    for (i = 0; i < len; i++) {
        SV **elem = av_fetch(av, i, 0);
        if (!elem) continue;

        dSP;
        GvSV(PL_defgv) = *elem;

        PUSHMARK(SP);
        call_sv((SV*)block_cv, G_SCALAR);

        if (SvTRUE(*PL_stack_sp)) {
            ST(0) = *elem;
            XSRETURN(1);
        }
    }

    XSRETURN_UNDEF;
}

/* final(\&block, \@array) - last element where block returns true (backwards iteration) */
XS_INTERNAL(xs_final) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::final(\\&block, \\@array)");

    SV *block = ST(0);
    SV *aref = ST(1);

    if (!SvROK(block) || SvTYPE(SvRV(block)) != SVt_PVCV) {
        croak("Func::Util::final: first argument must be a coderef");
    }
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) {
        croak("Func::Util::final: second argument must be an arrayref");
    }

    CV *block_cv = (CV *)SvRV(block);
    AV *av = (AV *)SvRV(aref);
    SSize_t len = av_len(av) + 1;
    SSize_t i;

    if (len == 0) {
        XSRETURN_UNDEF;
    }

#ifdef dMULTICALL
    if (!CvISXSUB(block_cv)) {
        dMULTICALL;
        I32 gimme = G_SCALAR;

        SAVESPTR(GvSV(PL_defgv));
        PUSH_MULTICALL(block_cv);

        /* Iterate backwards for speed */
        for (i = len - 1; i >= 0; i--) {
            SV **elem = av_fetch(av, i, 0);
            if (!elem) continue;

            SV *def_sv = GvSV(PL_defgv) = *elem;
            SvTEMP_off(def_sv);

            MULTICALL;

            if (SvTRUE(*PL_stack_sp)) {
                POP_MULTICALL;
                ST(0) = *elem;
                XSRETURN(1);
            }
        }

        POP_MULTICALL;
        XSRETURN_UNDEF;
    }
#endif

    /* Fallback for XS subs - backwards */
    for (i = len - 1; i >= 0; i--) {
        SV **elem = av_fetch(av, i, 0);
        if (!elem) continue;

        dSP;
        GvSV(PL_defgv) = *elem;

        PUSHMARK(SP);
        call_sv((SV*)block_cv, G_SCALAR);

        if (SvTRUE(*PL_stack_sp)) {
            ST(0) = *elem;
            XSRETURN(1);
        }
    }

    XSRETURN_UNDEF;
}

/* first { block } @list - return first element where block returns true */
XS_INTERNAL(xs_first) {
    dXSARGS;
    if (items < 1) croak("Usage: Func::Util::first(\\&block, @list)");

    SV *block = ST(0);
    if (!SvROK(block) || SvTYPE(SvRV(block)) != SVt_PVCV) {
        croak("Func::Util::first: first argument must be a coderef");
    }

    CV *block_cv = (CV *)SvRV(block);
    /* Store args from stack base before any stack manipulation */
    SV **args = &PL_stack_base[ax];
    IV index;

    /* Empty list - return undef */
    if (items <= 1) {
        XSRETURN_UNDEF;
    }

    /* Use MULTICALL for pure Perl subs - much faster than call_sv */
#ifdef dMULTICALL
    if (!CvISXSUB(block_cv)) {
        dMULTICALL;
        I32 gimme = G_SCALAR;

        SAVESPTR(GvSV(PL_defgv));
        PUSH_MULTICALL(block_cv);

        for (index = 1; index < items; index++) {
            SV *def_sv = GvSV(PL_defgv) = args[index];
            SvTEMP_off(def_sv);

            MULTICALL;

            if (SvTRUE(*PL_stack_sp)) {
                POP_MULTICALL;
                ST(0) = ST(index);
                XSRETURN(1);
            }
        }

        POP_MULTICALL;
        XSRETURN_UNDEF;
    }
#endif

    /* Fallback for XS subs */
    for (index = 1; index < items; index++) {
        dSP;
        GvSV(PL_defgv) = args[index];

        PUSHMARK(SP);
        call_sv((SV*)block_cv, G_SCALAR);

        if (SvTRUE(*PL_stack_sp)) {
            ST(0) = ST(index);
            XSRETURN(1);
        }
    }

    XSRETURN_UNDEF;
}

/* any { block } @list - return true if any element matches */
XS_INTERNAL(xs_any) {
    dXSARGS;
    if (items < 1) croak("Usage: Func::Util::any(\\&block, @list)");

    SV *block = ST(0);
    if (!SvROK(block) || SvTYPE(SvRV(block)) != SVt_PVCV) {
        croak("Func::Util::any: first argument must be a coderef");
    }

    CV *block_cv = (CV *)SvRV(block);
    SV **args = &PL_stack_base[ax];
    IV index;

    /* Empty list returns false */
    if (items <= 1) {
        XSRETURN_NO;
    }

#ifdef dMULTICALL
    if (!CvISXSUB(block_cv)) {
        dMULTICALL;
        I32 gimme = G_SCALAR;

        SAVESPTR(GvSV(PL_defgv));
        PUSH_MULTICALL(block_cv);

        for (index = 1; index < items; index++) {
            SV *def_sv = GvSV(PL_defgv) = args[index];
            SvTEMP_off(def_sv);

            MULTICALL;

            if (SvTRUE(*PL_stack_sp)) {
                POP_MULTICALL;
                XSRETURN_YES;
            }
        }

        POP_MULTICALL;
        XSRETURN_NO;
    }
#endif

    for (index = 1; index < items; index++) {
        dSP;
        GvSV(PL_defgv) = args[index];

        PUSHMARK(SP);
        call_sv((SV*)block_cv, G_SCALAR);

        if (SvTRUE(*PL_stack_sp)) {
            XSRETURN_YES;
        }
    }

    XSRETURN_NO;
}

/* all { block } @list - return true if all elements match */
XS_INTERNAL(xs_all) {
    dXSARGS;
    if (items < 1) croak("Usage: Func::Util::all(\\&block, @list)");

    SV *block = ST(0);
    if (!SvROK(block) || SvTYPE(SvRV(block)) != SVt_PVCV) {
        croak("Func::Util::all: first argument must be a coderef");
    }

    CV *block_cv = (CV *)SvRV(block);
    SV **args = &PL_stack_base[ax];
    IV index;

    /* Empty list returns true (vacuous truth) */
    if (items <= 1) {
        XSRETURN_YES;
    }

#ifdef dMULTICALL
    if (!CvISXSUB(block_cv)) {
        dMULTICALL;
        I32 gimme = G_SCALAR;

        SAVESPTR(GvSV(PL_defgv));
        PUSH_MULTICALL(block_cv);

        for (index = 1; index < items; index++) {
            SV *def_sv = GvSV(PL_defgv) = args[index];
            SvTEMP_off(def_sv);

            MULTICALL;

            if (!SvTRUE(*PL_stack_sp)) {
                POP_MULTICALL;
                XSRETURN_NO;
            }
        }

        POP_MULTICALL;
        XSRETURN_YES;
    }
#endif

    for (index = 1; index < items; index++) {
        dSP;
        GvSV(PL_defgv) = args[index];

        PUSHMARK(SP);
        call_sv((SV*)block_cv, G_SCALAR);

        if (!SvTRUE(*PL_stack_sp)) {
            XSRETURN_NO;
        }
    }

    XSRETURN_YES;
}

/* none { block } @list - return true if no elements match */
XS_INTERNAL(xs_none) {
    dXSARGS;
    if (items < 1) croak("Usage: Func::Util::none(\\&block, @list)");

    SV *block = ST(0);
    if (!SvROK(block) || SvTYPE(SvRV(block)) != SVt_PVCV) {
        croak("Func::Util::none: first argument must be a coderef");
    }

    CV *block_cv = (CV *)SvRV(block);
    SV **args = &PL_stack_base[ax];
    IV index;

    /* Empty list returns true (no elements match = vacuous truth) */
    if (items <= 1) {
        XSRETURN_YES;
    }

#ifdef dMULTICALL
    if (!CvISXSUB(block_cv)) {
        dMULTICALL;
        I32 gimme = G_SCALAR;

        SAVESPTR(GvSV(PL_defgv));
        PUSH_MULTICALL(block_cv);

        for (index = 1; index < items; index++) {
            SV *def_sv = GvSV(PL_defgv) = args[index];
            SvTEMP_off(def_sv);

            MULTICALL;

            if (SvTRUE(*PL_stack_sp)) {
                POP_MULTICALL;
                XSRETURN_NO;
            }
        }

        POP_MULTICALL;
        XSRETURN_YES;
    }
#endif

    for (index = 1; index < items; index++) {
        dSP;
        GvSV(PL_defgv) = args[index];

        PUSHMARK(SP);
        call_sv((SV*)block_cv, G_SCALAR);

        if (SvTRUE(*PL_stack_sp)) {
            XSRETURN_NO;
        }
    }

    XSRETURN_YES;
}

/* ============================================
   Experimental: Inlined MULTICALL versions for benchmarking

   These versions inline the runops loop to skip the CALLRUNOPS
   function call overhead. For testing only.
   ============================================ */

/* first_inline - experimental version with inlined runops loop
 * Requires MULTICALL API (5.11+) */
#ifdef dMULTICALL
XS_INTERNAL(xs_first_inline) {
    dXSARGS;
    if (items < 1) croak("Usage: Func::Util::first_inline(\\&block, @list)");

    SV *block = ST(0);
    if (!SvROK(block) || SvTYPE(SvRV(block)) != SVt_PVCV) {
        croak("Func::Util::first_inline: first argument must be a coderef");
    }

    CV *the_cv = (CV *)SvRV(block);

    if (items == 1) {
        XSRETURN_UNDEF;
    }

    /* Only works with pure Perl subs */
    if (CvISXSUB(the_cv)) {
        croak("Func::Util::first_inline: only works with pure Perl subs");
    }

    SV **args = &ST(1);
    IV num_args = items - 1;
    IV i;

    /* Use standard MULTICALL API for compatibility */
    dMULTICALL;
    I32 gimme = G_SCALAR;

    PUSH_MULTICALL(the_cv);

    /* Save and setup $_ */
    SAVESPTR(GvSV(PL_defgv));

    for (i = 0; i < num_args; i++) {
        SV *elem = args[i];
        GvSV(PL_defgv) = elem;
        SvTEMP_off(elem);

        MULTICALL;

        if (SvTRUE(*PL_stack_sp)) {
            /* Found it - cleanup and return */
            POP_MULTICALL;
            SPAGAIN;

            ST(0) = elem;
            XSRETURN(1);
        }
    }

    /* Cleanup */
    POP_MULTICALL;
    SPAGAIN;

    XSRETURN_UNDEF;
}
#endif /* dMULTICALL */


/* ============================================
   Type predicate XS fallbacks
   ============================================ */

XS_INTERNAL(xs_is_ref) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_ref($value)");
    ST(0) = SvROK(ST(0)) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_is_array) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_array($value)");
    SV *sv = ST(0);
    ST(0) = (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_is_hash) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_hash($value)");
    SV *sv = ST(0);
    ST(0) = (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_is_code) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_code($value)");
    SV *sv = ST(0);
    ST(0) = (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_is_defined) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_defined($value)");
    ST(0) = SvOK(ST(0)) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

/* ============================================
   String predicate XS fallbacks
   ============================================ */

XS_INTERNAL(xs_is_empty) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_empty($value)");
    SV *sv = ST(0);
    if (!SvOK(sv)) {
        ST(0) = &PL_sv_yes;
    } else {
        STRLEN len;
        SvPV(sv, len);
        ST(0) = len == 0 ? &PL_sv_yes : &PL_sv_no;
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_starts_with) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::starts_with($string, $prefix)");

    SV *str_sv = ST(0);
    SV *prefix_sv = ST(1);

    if (!SvOK(str_sv) || !SvOK(prefix_sv)) {
        ST(0) = &PL_sv_no;
        XSRETURN(1);
    }

    STRLEN str_len, prefix_len;
    const char *str = SvPV(str_sv, str_len);
    const char *prefix = SvPV(prefix_sv, prefix_len);

    if (prefix_len > str_len) {
        ST(0) = &PL_sv_no;
    } else if (prefix_len == 0) {
        ST(0) = &PL_sv_yes;
    } else {
        ST(0) = memcmp(str, prefix, prefix_len) == 0 ? &PL_sv_yes : &PL_sv_no;
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_ends_with) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::ends_with($string, $suffix)");

    SV *str_sv = ST(0);
    SV *suffix_sv = ST(1);

    if (!SvOK(str_sv) || !SvOK(suffix_sv)) {
        ST(0) = &PL_sv_no;
        XSRETURN(1);
    }

    STRLEN str_len, suffix_len;
    const char *str = SvPV(str_sv, str_len);
    const char *suffix = SvPV(suffix_sv, suffix_len);

    if (suffix_len > str_len) {
        ST(0) = &PL_sv_no;
    } else if (suffix_len == 0) {
        ST(0) = &PL_sv_yes;
    } else {
        const char *str_end = str + str_len - suffix_len;
        ST(0) = memcmp(str_end, suffix, suffix_len) == 0 ? &PL_sv_yes : &PL_sv_no;
    }
    XSRETURN(1);
}

/* count: count occurrences of substring using memmem */
XS_INTERNAL(xs_count) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::count($string, $substring)");

    SV *str_sv = ST(0);
    SV *needle_sv = ST(1);

    if (!SvOK(str_sv) || !SvOK(needle_sv)) {
        ST(0) = sv_2mortal(newSViv(0));
        XSRETURN(1);
    }

    STRLEN str_len, needle_len;
    const char *str = SvPV_const(str_sv, str_len);
    const char *needle = SvPV_const(needle_sv, needle_len);

    if (needle_len == 0 || needle_len > str_len) {
        ST(0) = sv_2mortal(newSViv(0));
        XSRETURN(1);
    }

    IV count = 0;
    const char *p = str;
    const char *end = str + str_len;
    STRLEN remaining = str_len;

    while (remaining >= needle_len) {
        const char *found = (const char *)util_memmem(p, remaining, needle, needle_len);
        if (!found) break;
        count++;
        /* Move past the match (non-overlapping) */
        p = found + needle_len;
        remaining = end - p;
    }

    ST(0) = sv_2mortal(newSViv(count));
    XSRETURN(1);
}

/* replace_all: replace all occurrences of old with new using memmem */
XS_INTERNAL(xs_replace_all) {
    dXSARGS;
    if (items != 3) croak("Usage: Func::Util::replace_all($string, $old, $new)");

    SV *str_sv = ST(0);
    SV *old_sv = ST(1);
    SV *new_sv = ST(2);

    /* Handle undef - return undef */
    if (!SvOK(str_sv)) {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

    STRLEN str_len, old_len, new_len;
    const char *str = SvPV_const(str_sv, str_len);
    const char *old = SvPV_const(old_sv, old_len);
    const char *replacement = SvPV_const(new_sv, new_len);

    /* Empty search string or not found - return original */
    if (old_len == 0 || old_len > str_len) {
        ST(0) = sv_2mortal(newSVpvn(str, str_len));
        XSRETURN(1);
    }

    /* First pass: count occurrences to pre-size buffer */
    IV count = 0;
    const char *p = str;
    const char *end = str + str_len;
    STRLEN remaining = str_len;

    while (remaining >= old_len) {
        const char *found = (const char *)util_memmem(p, remaining, old, old_len);
        if (!found) break;
        count++;
        p = found + old_len;
        remaining = end - p;
    }

    if (count == 0) {
        /* No matches - return copy of original */
        ST(0) = sv_2mortal(newSVpvn(str, str_len));
        XSRETURN(1);
    }

    /* Calculate result size and allocate */
    STRLEN result_len = str_len + count * (new_len - old_len);
    SV *result = sv_2mortal(newSV(result_len + 1));
    SvPOK_on(result);
    char *out = SvPVX(result);
    char *out_ptr = out;

    /* Second pass: build result */
    p = str;
    remaining = str_len;

    while (remaining >= old_len) {
        const char *found = (const char *)util_memmem(p, remaining, old, old_len);
        if (!found) break;

        /* Copy text before match */
        STRLEN before_len = found - p;
        if (before_len > 0) {
            memcpy(out_ptr, p, before_len);
            out_ptr += before_len;
        }

        /* Copy replacement */
        if (new_len > 0) {
            memcpy(out_ptr, replacement, new_len);
            out_ptr += new_len;
        }

        p = found + old_len;
        remaining = end - p;
    }

    /* Copy remaining text after last match */
    if (remaining > 0) {
        memcpy(out_ptr, p, remaining);
        out_ptr += remaining;
    }

    *out_ptr = '\0';
    SvCUR_set(result, out_ptr - out);

    ST(0) = result;
    XSRETURN(1);
}

/* before: get text before first occurrence of delimiter */
XS_INTERNAL(xs_before) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::before($string, $delimiter)");

    SV *str_sv = ST(0);
    SV *delim_sv = ST(1);

    if (!SvOK(str_sv)) {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

    STRLEN str_len, delim_len;
    const char *str = SvPV_const(str_sv, str_len);
    const char *delim = SvPV_const(delim_sv, delim_len);

    if (delim_len == 0 || delim_len > str_len) {
        ST(0) = sv_2mortal(newSVpvn(str, str_len));
        XSRETURN(1);
    }

    const char *found = (const char *)util_memmem(str, str_len, delim, delim_len);
    if (found) {
        ST(0) = sv_2mortal(newSVpvn(str, found - str));
    } else {
        ST(0) = sv_2mortal(newSVpvn(str, str_len));
    }
    XSRETURN(1);
}

/* after: get text after first occurrence of delimiter */
XS_INTERNAL(xs_after) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::after($string, $delimiter)");

    SV *str_sv = ST(0);
    SV *delim_sv = ST(1);

    if (!SvOK(str_sv)) {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

    STRLEN str_len, delim_len;
    const char *str = SvPV_const(str_sv, str_len);
    const char *delim = SvPV_const(delim_sv, delim_len);

    if (delim_len == 0 || delim_len > str_len) {
        ST(0) = sv_2mortal(newSVpvn("", 0));
        XSRETURN(1);
    }

    const char *found = (const char *)util_memmem(str, str_len, delim, delim_len);
    if (found) {
        const char *after_delim = found + delim_len;
        ST(0) = sv_2mortal(newSVpvn(after_delim, str + str_len - after_delim));
    } else {
        ST(0) = sv_2mortal(newSVpvn("", 0));
    }
    XSRETURN(1);
}

/* ============================================
   Boolean/Truthiness XS fallbacks
   ============================================ */

XS_INTERNAL(xs_is_true) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_true($value)");
    ST(0) = SvTRUE(ST(0)) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_is_false) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_false($value)");
    ST(0) = SvTRUE(ST(0)) ? &PL_sv_no : &PL_sv_yes;
    XSRETURN(1);
}

XS_INTERNAL(xs_bool) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::bool($value)");
    ST(0) = SvTRUE(ST(0)) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

/* ============================================
   Extended type predicate XS fallbacks
   ============================================ */

XS_INTERNAL(xs_is_num) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_num($value)");
    SV *sv = ST(0);
    ST(0) = (SvNIOK(sv) || looks_like_number(sv)) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_is_int) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_int($value)");
    SV *sv = ST(0);
    if (SvIOK(sv)) {
        ST(0) = &PL_sv_yes;
    } else if (SvNOK(sv)) {
        NV nv = SvNV(sv);
        ST(0) = (nv == (NV)(IV)nv) ? &PL_sv_yes : &PL_sv_no;
    } else if (looks_like_number(sv)) {
        STRLEN len;
        const char *pv = SvPV(sv, len);
        bool has_dot = FALSE;
        STRLEN i;
        for (i = 0; i < len; i++) {
            if (pv[i] == '.' || pv[i] == 'e' || pv[i] == 'E') {
                has_dot = TRUE;
                break;
            }
        }
        if (has_dot) {
            NV nv = SvNV(sv);
            ST(0) = (nv == (NV)(IV)nv) ? &PL_sv_yes : &PL_sv_no;
        } else {
            ST(0) = &PL_sv_yes;
        }
    } else {
        ST(0) = &PL_sv_no;
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_is_blessed) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_blessed($value)");
    ST(0) = sv_isobject(ST(0)) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_is_scalar_ref) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_scalar_ref($value)");
    SV *sv = ST(0);
    if (SvROK(sv)) {
        SV *rv = SvRV(sv);
        svtype type = SvTYPE(rv);
        ST(0) = (type < SVt_PVAV) ? &PL_sv_yes : &PL_sv_no;
    } else {
        ST(0) = &PL_sv_no;
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_is_regex) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_regex($value)");
    ST(0) = SvRXOK(ST(0)) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_is_glob) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_glob($value)");
    ST(0) = (SvTYPE(ST(0)) == SVt_PVGV) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_is_string) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_string($value)");
    SV *sv = ST(0);
    ST(0) = (SvOK(sv) && !SvROK(sv)) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

/* ============================================
   Numeric predicate XS fallbacks
   ============================================ */

XS_INTERNAL(xs_is_positive) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_positive($value)");
    SV *sv = ST(0);
    if (SvNIOK(sv) || looks_like_number(sv)) {
        NV nv = SvNV(sv);
        ST(0) = (nv > 0) ? &PL_sv_yes : &PL_sv_no;
    } else {
        ST(0) = &PL_sv_no;
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_is_negative) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_negative($value)");
    SV *sv = ST(0);
    if (SvNIOK(sv) || looks_like_number(sv)) {
        NV nv = SvNV(sv);
        ST(0) = (nv < 0) ? &PL_sv_yes : &PL_sv_no;
    } else {
        ST(0) = &PL_sv_no;
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_is_zero) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_zero($value)");
    SV *sv = ST(0);
    if (SvNIOK(sv) || looks_like_number(sv)) {
        NV nv = SvNV(sv);
        ST(0) = (nv == 0) ? &PL_sv_yes : &PL_sv_no;
    } else {
        ST(0) = &PL_sv_no;
    }
    XSRETURN(1);
}

/* ============================================
   Numeric utility XS fallbacks
   ============================================ */

XS_INTERNAL(xs_is_even) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_even($value)");
    SV *sv = ST(0);
    if (SvIOK(sv)) {
        ST(0) = (SvIVX(sv) & 1) == 0 ? &PL_sv_yes : &PL_sv_no;
    } else if (SvNIOK(sv)) {
        NV nv = SvNV(sv);
        if (nv == (NV)(IV)nv) {
            ST(0) = ((IV)nv & 1) == 0 ? &PL_sv_yes : &PL_sv_no;
        } else {
            ST(0) = &PL_sv_no;
        }
    } else if (looks_like_number(sv)) {
        ST(0) = (SvIV(sv) & 1) == 0 ? &PL_sv_yes : &PL_sv_no;
    } else {
        ST(0) = &PL_sv_no;
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_is_odd) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_odd($value)");
    SV *sv = ST(0);
    if (SvIOK(sv)) {
        ST(0) = (SvIVX(sv) & 1) == 1 ? &PL_sv_yes : &PL_sv_no;
    } else if (SvNIOK(sv)) {
        NV nv = SvNV(sv);
        if (nv == (NV)(IV)nv) {
            ST(0) = ((IV)nv & 1) == 1 ? &PL_sv_yes : &PL_sv_no;
        } else {
            ST(0) = &PL_sv_no;
        }
    } else if (looks_like_number(sv)) {
        ST(0) = (SvIV(sv) & 1) == 1 ? &PL_sv_yes : &PL_sv_no;
    } else {
        ST(0) = &PL_sv_no;
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_is_between) {
    dXSARGS;
    if (items != 3) croak("Usage: Func::Util::is_between($value, $min, $max)");
    SV *val_sv = ST(0);
    SV *min_sv = ST(1);
    SV *max_sv = ST(2);

    if (SvNIOK(val_sv) || looks_like_number(val_sv)) {
        NV val = SvNV(val_sv);
        NV min = SvNV(min_sv);
        NV max = SvNV(max_sv);
        ST(0) = (val >= min && val <= max) ? &PL_sv_yes : &PL_sv_no;
    } else {
        ST(0) = &PL_sv_no;
    }
    XSRETURN(1);
}

/* ============================================
   Collection XS fallbacks
   ============================================ */

XS_INTERNAL(xs_is_empty_array) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_empty_array($arrayref)");
    SV *sv = ST(0);
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        AV *av = (AV*)SvRV(sv);
        ST(0) = AvFILL(av) < 0 ? &PL_sv_yes : &PL_sv_no;
    } else {
        ST(0) = &PL_sv_no;
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_is_empty_hash) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::is_empty_hash($hashref)");
    SV *sv = ST(0);
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV) {
        HV *hv = (HV*)SvRV(sv);
        ST(0) = HvKEYS(hv) == 0 ? &PL_sv_yes : &PL_sv_no;
    } else {
        ST(0) = &PL_sv_no;
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_array_len) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::array_len($arrayref)");
    SV *sv = ST(0);
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        AV *av = (AV*)SvRV(sv);
        ST(0) = sv_2mortal(newSViv(AvFILL(av) + 1));
    } else {
        ST(0) = &PL_sv_undef;
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_hash_size) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::hash_size($hashref)");
    SV *sv = ST(0);
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV) {
        HV *hv = (HV*)SvRV(sv);
        ST(0) = sv_2mortal(newSViv(HvKEYS(hv)));
    } else {
        ST(0) = &PL_sv_undef;
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_array_first) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::array_first($arrayref)");
    SV *sv = ST(0);
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        AV *av = (AV*)SvRV(sv);
        if (AvFILL(av) >= 0) {
            SV **elem = av_fetch(av, 0, 0);
            ST(0) = elem ? *elem : &PL_sv_undef;
        } else {
            ST(0) = &PL_sv_undef;
        }
    } else {
        ST(0) = &PL_sv_undef;
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_array_last) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::array_last($arrayref)");
    SV *sv = ST(0);
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        AV *av = (AV*)SvRV(sv);
        IV last_idx = AvFILL(av);
        if (last_idx >= 0) {
            SV **elem = av_fetch(av, last_idx, 0);
            ST(0) = elem ? *elem : &PL_sv_undef;
        } else {
            ST(0) = &PL_sv_undef;
        }
    } else {
        ST(0) = &PL_sv_undef;
    }
    XSRETURN(1);
}

/* ============================================
   String manipulation XS fallbacks
   ============================================ */

XS_INTERNAL(xs_trim) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::trim($string)");

    SV *sv = ST(0);
    if (!SvOK(sv)) {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

    STRLEN len;
    const char *str = SvPV(sv, len);
    const char *start = str;
    const char *end = str + len;

    /* Skip leading whitespace */
    while (start < end && isSPACE(*start)) {
        start++;
    }

    /* Skip trailing whitespace */
    while (end > start && isSPACE(*(end - 1))) {
        end--;
    }

    ST(0) = sv_2mortal(newSVpvn(start, end - start));
    XSRETURN(1);
}

XS_INTERNAL(xs_ltrim) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::ltrim($string)");

    SV *sv = ST(0);
    if (!SvOK(sv)) {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

    STRLEN len;
    const char *str = SvPV(sv, len);
    const char *start = str;
    const char *end = str + len;

    while (start < end && isSPACE(*start)) {
        start++;
    }

    ST(0) = sv_2mortal(newSVpvn(start, end - start));
    XSRETURN(1);
}

XS_INTERNAL(xs_rtrim) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::rtrim($string)");

    SV *sv = ST(0);
    if (!SvOK(sv)) {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

    STRLEN len;
    const char *str = SvPV(sv, len);
    const char *end = str + len;

    while (end > str && isSPACE(*(end - 1))) {
        end--;
    }

    ST(0) = sv_2mortal(newSVpvn(str, end - str));
    XSRETURN(1);
}

/* ============================================
   Conditional XS fallbacks
   ============================================ */

XS_INTERNAL(xs_maybe) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::maybe($value, $then)");

    SV *val = ST(0);
    if (SvOK(val)) {
        ST(0) = ST(1);
    } else {
        ST(0) = &PL_sv_undef;
    }
    XSRETURN(1);
}

/* ============================================
   Numeric XS fallbacks
   ============================================ */

XS_INTERNAL(xs_sign) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::sign($number)");

    SV *sv = ST(0);
    if (!SvNIOK(sv) && !looks_like_number(sv)) {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

    NV nv = SvNV(sv);
    if (nv > 0) {
        ST(0) = sv_2mortal(newSViv(1));
    } else if (nv < 0) {
        ST(0) = sv_2mortal(newSViv(-1));
    } else {
        ST(0) = sv_2mortal(newSViv(0));
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_min2) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::min2($a, $b)");

    NV a = SvNV(ST(0));
    NV b = SvNV(ST(1));

    ST(0) = a <= b ? ST(0) : ST(1);
    XSRETURN(1);
}

XS_INTERNAL(xs_max2) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::max2($a, $b)");

    NV a = SvNV(ST(0));
    NV b = SvNV(ST(1));

    ST(0) = a >= b ? ST(0) : ST(1);
    XSRETURN(1);
}

/* ============================================
   Named callback loop functions
   These accept a callback name instead of coderef
   ============================================ */

/* any_cb(\@list, ':predicate') - true if any element matches */
XS_INTERNAL(xs_any_cb) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::any_cb(\\@list, $callback_name)");

    SV *list_sv = ST(0);
    if (!SvROK(list_sv) || SvTYPE(SvRV(list_sv)) != SVt_PVAV) {
        croak("Func::Util::any_cb: first argument must be an arrayref");
    }
    AV *list = (AV*)SvRV(list_sv);

    STRLEN name_len;
    const char *name = SvPV(ST(1), name_len);

    RegisteredCallback *cb = get_registered_callback(aTHX_ name);
    if (!cb) {
        croak("Func::Util::any_cb: unknown callback '%s'", name);
    }
    if (!cb->predicate && !cb->perl_callback) {
        croak("Func::Util::any_cb: callback '%s' is not a predicate", name);
    }

    IV len = av_len(list) + 1;
    IV i;

    if (cb->predicate) {
        /* Fast C path */
        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(list, i, 0);
            if (svp && cb->predicate(aTHX_ *svp)) {
                XSRETURN_YES;
            }
        }
    } else if (cb->perl_callback) {
        /* Perl callback fallback - use isolated stack scope */
        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(list, i, 0);
            if (!svp) continue;

            bool matches = FALSE;
            {
                dSP;
                int count;
                SV *result;

                ENTER;
                SAVETMPS;

                PUSHMARK(SP);
                XPUSHs(*svp);
                PUTBACK;

                count = call_sv(cb->perl_callback, G_SCALAR);

                SPAGAIN;
                if (count > 0) {
                    result = POPs;
                    matches = SvTRUE(result);
                }
                PUTBACK;

                FREETMPS;
                LEAVE;
            }

            if (matches) {
                XSRETURN_YES;
            }
        }
    }

    XSRETURN_NO;
}

/* all_cb(\@list, ':predicate') - true if all elements match */
XS_INTERNAL(xs_all_cb) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::all_cb(\\@list, $callback_name)");

    SV *list_sv = ST(0);
    if (!SvROK(list_sv) || SvTYPE(SvRV(list_sv)) != SVt_PVAV) {
        croak("Func::Util::all_cb: first argument must be an arrayref");
    }
    AV *list = (AV*)SvRV(list_sv);

    STRLEN name_len;
    const char *name = SvPV(ST(1), name_len);

    RegisteredCallback *cb = get_registered_callback(aTHX_ name);
    if (!cb) {
        croak("Func::Util::all_cb: unknown callback '%s'", name);
    }
    if (!cb->predicate && !cb->perl_callback) {
        croak("Func::Util::all_cb: callback '%s' is not a predicate", name);
    }

    IV len = av_len(list) + 1;
    IV i;

    /* Empty list returns true (vacuous truth) */
    if (len == 0) {
        XSRETURN_YES;
    }

    if (cb->predicate) {
        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(list, i, 0);
            if (!svp || !cb->predicate(aTHX_ *svp)) {
                XSRETURN_NO;
            }
        }
    } else if (cb->perl_callback) {
        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(list, i, 0);
            if (!svp) { XSRETURN_NO; }
            bool matches = FALSE;
            {
                dSP;
                int count;
                SV *result;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*svp);
                PUTBACK;
                count = call_sv(cb->perl_callback, G_SCALAR);
                SPAGAIN;
                if (count > 0) {
                    result = POPs;
                    matches = SvTRUE(result);
                }
                PUTBACK;
                FREETMPS; LEAVE;
            }
            if (!matches) {
                XSRETURN_NO;
            }
        }
    }

    XSRETURN_YES;
}

/* none_cb(\@list, ':predicate') - true if no elements match */
XS_INTERNAL(xs_none_cb) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::none_cb(\\@list, $callback_name)");

    SV *list_sv = ST(0);
    if (!SvROK(list_sv) || SvTYPE(SvRV(list_sv)) != SVt_PVAV) {
        croak("Func::Util::none_cb: first argument must be an arrayref");
    }
    AV *list = (AV*)SvRV(list_sv);

    STRLEN name_len;
    const char *name = SvPV(ST(1), name_len);

    RegisteredCallback *cb = get_registered_callback(aTHX_ name);
    if (!cb) {
        croak("Func::Util::none_cb: unknown callback '%s'", name);
    }
    if (!cb->predicate && !cb->perl_callback) {
        croak("Func::Util::none_cb: callback '%s' is not a predicate", name);
    }

    IV len = av_len(list) + 1;
    IV i;

    if (cb->predicate) {
        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(list, i, 0);
            if (svp && cb->predicate(aTHX_ *svp)) {
                XSRETURN_NO;
            }
        }
    } else if (cb->perl_callback) {
        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(list, i, 0);
            if (!svp) continue;
            bool matches = FALSE;
            {
                dSP;
                int count;
                SV *result;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*svp);
                PUTBACK;
                count = call_sv(cb->perl_callback, G_SCALAR);
                SPAGAIN;
                if (count > 0) {
                    result = POPs;
                    matches = SvTRUE(result);
                }
                PUTBACK;
                FREETMPS; LEAVE;
            }
            if (matches) {
                XSRETURN_NO;
            }
        }
    }

    XSRETURN_YES;
}

/* first_cb(\@list, ':predicate') - first matching element */
XS_INTERNAL(xs_first_cb) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::first_cb(\\@list, $callback_name)");

    SV *list_sv = ST(0);
    if (!SvROK(list_sv) || SvTYPE(SvRV(list_sv)) != SVt_PVAV) {
        croak("Func::Util::first_cb: first argument must be an arrayref");
    }
    AV *list = (AV*)SvRV(list_sv);

    STRLEN name_len;
    const char *name = SvPV(ST(1), name_len);

    RegisteredCallback *cb = get_registered_callback(aTHX_ name);
    if (!cb) {
        croak("Func::Util::first_cb: unknown callback '%s'", name);
    }
    if (!cb->predicate && !cb->perl_callback) {
        croak("Func::Util::first_cb: callback '%s' is not a predicate", name);
    }

    IV len = av_len(list) + 1;
    IV i;

    if (cb->predicate) {
        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(list, i, 0);
            if (svp && cb->predicate(aTHX_ *svp)) {
                ST(0) = *svp;
                XSRETURN(1);
            }
        }
    } else if (cb->perl_callback) {
        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(list, i, 0);
            if (!svp) continue;
            bool matches = FALSE;
            {
                dSP;
                int count;
                SV *result;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*svp);
                PUTBACK;
                count = call_sv(cb->perl_callback, G_SCALAR);
                SPAGAIN;
                if (count > 0) {
                    result = POPs;
                    matches = SvTRUE(result);
                }
                PUTBACK;
                FREETMPS; LEAVE;
            }
            if (matches) {
                ST(0) = *svp;
                XSRETURN(1);
            }
        }
    }

    XSRETURN_UNDEF;
}

/* grep_cb(\@list, ':predicate') - all matching elements */
XS_INTERNAL(xs_grep_cb) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::grep_cb(\\@list, $callback_name)");

    SV *list_sv = ST(0);
    if (!SvROK(list_sv) || SvTYPE(SvRV(list_sv)) != SVt_PVAV) {
        croak("Func::Util::grep_cb: first argument must be an arrayref");
    }
    AV *list = (AV*)SvRV(list_sv);

    STRLEN name_len;
    const char *name = SvPV(ST(1), name_len);

    RegisteredCallback *cb = get_registered_callback(aTHX_ name);
    if (!cb) {
        croak("Func::Util::grep_cb: unknown callback '%s'", name);
    }
    if (!cb->predicate && !cb->perl_callback) {
        croak("Func::Util::grep_cb: callback '%s' is not a predicate", name);
    }

    IV len = av_len(list) + 1;
    IV i;
    IV count = 0;

    /* Collect matching elements in a temporary array first */
    AV *results = newAV();
    sv_2mortal((SV*)results);

    if (cb->predicate) {
        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(list, i, 0);
            if (svp && cb->predicate(aTHX_ *svp)) {
                av_push(results, SvREFCNT_inc(*svp));
                count++;
            }
        }
    } else if (cb->perl_callback) {
        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(list, i, 0);
            if (!svp) continue;
            SV *elem = *svp;
            bool matches = FALSE;
            {
                dSP;
                int call_count;
                SV *result;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(elem);
                PUTBACK;
                call_count = call_sv(cb->perl_callback, G_SCALAR);
                SPAGAIN;
                if (call_count > 0) {
                    result = POPs;
                    matches = SvTRUE(result);
                }
                PUTBACK;
                FREETMPS; LEAVE;
            }
            if (matches) {
                av_push(results, SvREFCNT_inc(elem));
                count++;
            }
        }
    }

    /* Now push all results to the stack */
    SP -= items;
    for (i = 0; i < count; i++) {
        SV **svp = av_fetch(results, i, 0);
        if (svp) {
            XPUSHs(sv_2mortal(SvREFCNT_inc(*svp)));
        }
    }

    PUTBACK;
    XSRETURN(count);
}

/* count_cb(\@list, ':predicate') - count matching elements */
XS_INTERNAL(xs_count_cb) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::count_cb(\\@list, $callback_name)");

    SV *list_sv = ST(0);
    if (!SvROK(list_sv) || SvTYPE(SvRV(list_sv)) != SVt_PVAV) {
        croak("Func::Util::count_cb: first argument must be an arrayref");
    }
    AV *list = (AV*)SvRV(list_sv);

    STRLEN name_len;
    const char *name = SvPV(ST(1), name_len);

    RegisteredCallback *cb = get_registered_callback(aTHX_ name);
    if (!cb) {
        croak("Func::Util::count_cb: unknown callback '%s'", name);
    }
    if (!cb->predicate && !cb->perl_callback) {
        croak("Func::Util::count_cb: callback '%s' is not a predicate", name);
    }

    IV len = av_len(list) + 1;
    IV i;
    IV count = 0;

    if (cb->predicate) {
        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(list, i, 0);
            if (svp && cb->predicate(aTHX_ *svp)) {
                count++;
            }
        }
    } else if (cb->perl_callback) {
        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(list, i, 0);
            if (!svp) continue;
            bool matches = FALSE;
            {
                dSP;
                int call_count;
                SV *result;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*svp);
                PUTBACK;
                call_count = call_sv(cb->perl_callback, G_SCALAR);
                SPAGAIN;
                if (call_count > 0) {
                    result = POPs;
                    matches = SvTRUE(result);
                }
                PUTBACK;
                FREETMPS; LEAVE;
            }
            if (matches) {
                count++;
            }
        }
    }

    XSRETURN_IV(count);
}

/* partition_cb(\@list, ':predicate') - split into [matches], [non-matches] */
XS_INTERNAL(xs_partition_cb) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::partition_cb(\\@list, $callback_name)");

    SV *list_sv = ST(0);
    if (!SvROK(list_sv) || SvTYPE(SvRV(list_sv)) != SVt_PVAV) {
        croak("Func::Util::partition_cb: first argument must be an arrayref");
    }
    AV *list = (AV*)SvRV(list_sv);

    STRLEN name_len;
    const char *name = SvPV(ST(1), name_len);

    RegisteredCallback *cb = get_registered_callback(aTHX_ name);
    if (!cb) {
        croak("Func::Util::partition_cb: unknown callback '%s'", name);
    }
    if (!cb->predicate && !cb->perl_callback) {
        croak("Func::Util::partition_cb: callback '%s' is not a predicate", name);
    }

    IV len = av_len(list) + 1;
    AV *pass = newAV();
    AV *fail = newAV();
    av_extend(pass, len >> 1);
    av_extend(fail, len >> 1);

    IV i;
    if (cb->predicate) {
        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(list, i, 0);
            if (!svp) continue;
            if (cb->predicate(aTHX_ *svp)) {
                av_push(pass, SvREFCNT_inc_simple_NN(*svp));
            } else {
                av_push(fail, SvREFCNT_inc_simple_NN(*svp));
            }
        }
    } else if (cb->perl_callback) {
        for (i = 0; i < len; i++) {
            SV **svp = av_fetch(list, i, 0);
            if (!svp) continue;
            bool matches = FALSE;
            {
                dSP;
                int call_count;
                SV *result;

                ENTER;
                SAVETMPS;

                PUSHMARK(SP);
                XPUSHs(*svp);
                PUTBACK;

                call_count = call_sv(cb->perl_callback, G_SCALAR);

                SPAGAIN;
                if (call_count > 0) {
                    result = POPs;
                    matches = SvTRUE(result);
                }
                PUTBACK;

                FREETMPS;
                LEAVE;
            }
            if (matches) {
                av_push(pass, SvREFCNT_inc_simple_NN(*svp));
            } else {
                av_push(fail, SvREFCNT_inc_simple_NN(*svp));
            }
        }
    }

    /* Return list of two arrayrefs */
    ST(0) = sv_2mortal(newRV_noinc((SV*)pass));
    ST(1) = sv_2mortal(newRV_noinc((SV*)fail));
    XSRETURN(2);
}

/* final_cb(\@list, ':predicate') - find last matching element */
XS_INTERNAL(xs_final_cb) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::final_cb(\\@list, $callback_name)");

    SV *list_sv = ST(0);
    if (!SvROK(list_sv) || SvTYPE(SvRV(list_sv)) != SVt_PVAV) {
        croak("Func::Util::final_cb: first argument must be an arrayref");
    }
    AV *list = (AV*)SvRV(list_sv);

    STRLEN name_len;
    const char *name = SvPV(ST(1), name_len);

    RegisteredCallback *cb = get_registered_callback(aTHX_ name);
    if (!cb) {
        croak("Func::Util::final_cb: unknown callback '%s'", name);
    }
    if (!cb->predicate && !cb->perl_callback) {
        croak("Func::Util::final_cb: callback '%s' is not a predicate", name);
    }

    IV len = av_len(list) + 1;
    IV i;

    if (cb->predicate) {
        /* Search from end - C predicate path */
        for (i = len - 1; i >= 0; i--) {
            SV **svp = av_fetch(list, i, 0);
            if (svp && cb->predicate(aTHX_ *svp)) {
                ST(0) = *svp;
                XSRETURN(1);
            }
        }
    } else if (cb->perl_callback) {
        /* Search from end - Perl callback path */
        for (i = len - 1; i >= 0; i--) {
            SV **svp = av_fetch(list, i, 0);
            if (!svp) continue;
            bool matches = FALSE;
            {
                dSP;
                int count;
                SV *result;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(*svp);
                PUTBACK;
                count = call_sv(cb->perl_callback, G_SCALAR);
                SPAGAIN;
                if (count > 0) {
                    result = POPs;
                    matches = SvTRUE(result);
                }
                PUTBACK;
                FREETMPS; LEAVE;
            }
            if (matches) {
                ST(0) = *svp;
                XSRETURN(1);
            }
        }
    }

    XSRETURN_UNDEF;
}

/* Perl-level callback registration */
XS_INTERNAL(xs_register_callback) {
    dXSARGS;
    if (items != 2) croak("Usage: Func::Util::register_callback($name, \\&coderef)");

    STRLEN name_len;
    const char *name = SvPV(ST(0), name_len);

    SV *coderef = ST(1);
    if (!SvROK(coderef) || SvTYPE(SvRV(coderef)) != SVt_PVCV) {
        croak("Func::Util::register_callback: second argument must be a coderef");
    }

    RegisteredCallback *cb;
    SV *sv;

    init_callback_registry(aTHX);

    /* Check if already registered */
    if (get_registered_callback(aTHX_ name)) {
        croak("Callback '%s' is already registered", name);
    }

    Newxz(cb, 1, RegisteredCallback);
    cb->name = savepv(name);
    cb->predicate = NULL;
    cb->mapper = NULL;
    cb->reducer = NULL;
    /* Store a copy of the coderef (RV to CV) */
    cb->perl_callback = newSVsv(coderef);

    sv = newSViv(PTR2IV(cb));
    hv_store(g_callback_registry, name, name_len, sv, 0);

    XSRETURN_YES;
}

/* Check if callback exists */
XS_INTERNAL(xs_has_callback) {
    dXSARGS;
    if (items != 1) croak("Usage: Func::Util::has_callback($name)");

    STRLEN name_len;
    const char *name = SvPV(ST(0), name_len);

    if (has_callback(aTHX_ name)) {
        XSRETURN_YES;
    }
    XSRETURN_NO;
}

/* List all callbacks */
XS_INTERNAL(xs_list_callbacks) {
    dXSARGS;
    PERL_UNUSED_ARG(items);

    AV *result = list_callbacks(aTHX);
    ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    XSRETURN(1);
}

/* ============================================
   Import function - O(1) hash-based lookup
   ============================================ */

/* Export entry: supports XS functions, Perl coderefs, or both */
typedef struct {
    XSUBADDR_t xs_func;           /* XS function pointer (NULL for Perl-only) */
    Perl_call_checker call_checker; /* Optional call checker for XS */
    SV *perl_cv;                  /* Perl coderef (NULL for XS-only) */
} ExportEntry;

/* Global export hash - initialized at boot */
static HV *g_export_hash = NULL;

/* Register an XS export with optional call checker (internal) */
static void register_export(pTHX_ const char *name, XSUBADDR_t xs_func, Perl_call_checker checker) {
    ExportEntry *entry;
    Newx(entry, 1, ExportEntry);
    entry->xs_func = xs_func;
    entry->call_checker = checker;
    entry->perl_cv = NULL;
    (void)hv_store(g_export_hash, name, strlen(name), newSViv(PTR2IV(entry)), 0);
}

/* ============================================
   Public API: Register custom exports
   ============================================ */

/* Register a Perl coderef as an export - called from Perl */
XS_INTERNAL(xs_register_export) {
    dXSARGS;
    if (items != 2)
        croak("Usage: Func::Util::register_export($name, \\&coderef)");

    STRLEN name_len;
    char *name = SvPV(ST(0), name_len);
    SV *cv_sv = ST(1);

    /* Validate it's a coderef */
    if (!SvROK(cv_sv) || SvTYPE(SvRV(cv_sv)) != SVt_PVCV)
        croak("Func::Util::register_export: second argument must be a coderef");

    /* Check if name already exists */
    if (hv_exists(g_export_hash, name, name_len))
        croak("Func::Util::register_export: '%s' is already registered", name);

    /* Create entry for Perl coderef */
    ExportEntry *entry;
    Newx(entry, 1, ExportEntry);
    entry->xs_func = NULL;
    entry->call_checker = NULL;
    entry->perl_cv = SvREFCNT_inc(cv_sv);  /* Keep a reference */

    (void)hv_store(g_export_hash, name, name_len, newSViv(PTR2IV(entry)), 0);

    XSRETURN_YES;
}

/* Check if an export name is registered */
XS_INTERNAL(xs_has_export) {
    dXSARGS;
    if (items != 1)
        croak("Usage: Func::Util::has_export($name)");

    STRLEN name_len;
    char *name = SvPV(ST(0), name_len);

    if (hv_exists(g_export_hash, name, name_len)) {
        XSRETURN_YES;
    } else {
        XSRETURN_NO;
    }
}

/* List all registered export names */
XS_INTERNAL(xs_list_exports) {
    dXSARGS;
    PERL_UNUSED_ARG(items);

    AV *result = newAV();
    HE *entry;

    hv_iterinit(g_export_hash);
    while ((entry = hv_iternext(g_export_hash))) {
        SV *key = hv_iterkeysv(entry);
        av_push(result, SvREFCNT_inc(key));
    }

    ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    XSRETURN(1);
}

/* ============================================
   C API for XS modules to register exports
   ============================================ */

/*
 * Register an XS function as a util export.
 * Call this from your BOOT section:
 *   funcutil_register_export_xs(aTHX_ "my_func", xs_my_func);
 */
void funcutil_register_export_xs(pTHX_ const char *name, XSUBADDR_t xs_func) {
    if (!g_export_hash) {
        croak("funcutil_register_export_xs: Func::Util module not yet loaded");
    }

    STRLEN name_len = strlen(name);
    if (hv_exists(g_export_hash, name, name_len)) {
        croak("funcutil_register_export_xs: '%s' is already registered", name);
    }

    ExportEntry *entry;
    Newx(entry, 1, ExportEntry);
    entry->xs_func = xs_func;
    entry->call_checker = NULL;
    entry->perl_cv = NULL;

    (void)hv_store(g_export_hash, name, name_len, newSViv(PTR2IV(entry)), 0);
}

/* Initialize export hash at boot - called once */
static void init_export_hash(pTHX) {
    g_export_hash = newHV();

    /* Functional */
    register_export(aTHX_ "memo", xs_memo, NULL);
    register_export(aTHX_ "pipeline", xs_pipe, NULL);
    register_export(aTHX_ "compose", xs_compose, NULL);
    register_export(aTHX_ "lazy", xs_lazy, NULL);
    register_export(aTHX_ "force", xs_force, NULL);
    register_export(aTHX_ "dig", xs_dig, NULL);
    register_export(aTHX_ "clamp", xs_clamp, clamp_call_checker);
    register_export(aTHX_ "tap", xs_tap, NULL);
    register_export(aTHX_ "identity", xs_identity, identity_call_checker);
    register_export(aTHX_ "always", xs_always, NULL);
    register_export(aTHX_ "noop", xs_noop, noop_call_checker);
    register_export(aTHX_ "partial", xs_partial, NULL);
    register_export(aTHX_ "negate", xs_negate, NULL);
    register_export(aTHX_ "once", xs_once, NULL);

    /* Stubs */
    register_export(aTHX_ "stub_true", xs_stub_true, NULL);
    register_export(aTHX_ "stub_false", xs_stub_false, NULL);
    register_export(aTHX_ "stub_array", xs_stub_array, NULL);
    register_export(aTHX_ "stub_hash", xs_stub_hash, NULL);
    register_export(aTHX_ "stub_string", xs_stub_string, NULL);
    register_export(aTHX_ "stub_zero", xs_stub_zero, NULL);

    /* Null coalescing */
    register_export(aTHX_ "nvl", xs_nvl, NULL);
    register_export(aTHX_ "coalesce", xs_coalesce, NULL);

    /* List operations */
    register_export(aTHX_ "first", xs_first, NULL);
    register_export(aTHX_ "firstr", xs_firstr, NULL);
    register_export(aTHX_ "any", xs_any, NULL);
    register_export(aTHX_ "all", xs_all, NULL);
    register_export(aTHX_ "none", xs_none, NULL);
    register_export(aTHX_ "final", xs_final, NULL);
#ifdef dMULTICALL
    register_export(aTHX_ "first_inline", xs_first_inline, NULL);
#endif

    /* Callback-based loop functions */
    register_export(aTHX_ "any_cb", xs_any_cb, NULL);
    register_export(aTHX_ "all_cb", xs_all_cb, NULL);
    register_export(aTHX_ "none_cb", xs_none_cb, NULL);
    register_export(aTHX_ "first_cb", xs_first_cb, NULL);
    register_export(aTHX_ "grep_cb", xs_grep_cb, NULL);
    register_export(aTHX_ "count_cb", xs_count_cb, NULL);
    register_export(aTHX_ "partition_cb", xs_partition_cb, NULL);
    register_export(aTHX_ "final_cb", xs_final_cb, NULL);
    register_export(aTHX_ "register_callback", xs_register_callback, NULL);
    register_export(aTHX_ "has_callback", xs_has_callback, NULL);
    register_export(aTHX_ "list_callbacks", xs_list_callbacks, NULL);

    /* Specialized predicates - first_* */
    register_export(aTHX_ "first_gt", xs_first_gt, NULL);
    register_export(aTHX_ "first_lt", xs_first_lt, NULL);
    register_export(aTHX_ "first_ge", xs_first_ge, NULL);
    register_export(aTHX_ "first_le", xs_first_le, NULL);
    register_export(aTHX_ "first_eq", xs_first_eq, NULL);
    register_export(aTHX_ "first_ne", xs_first_ne, NULL);

    /* Specialized predicates - final_* */
    register_export(aTHX_ "final_gt", xs_final_gt, NULL);
    register_export(aTHX_ "final_lt", xs_final_lt, NULL);
    register_export(aTHX_ "final_ge", xs_final_ge, NULL);
    register_export(aTHX_ "final_le", xs_final_le, NULL);
    register_export(aTHX_ "final_eq", xs_final_eq, NULL);
    register_export(aTHX_ "final_ne", xs_final_ne, NULL);

    /* Specialized predicates - any_* */
    register_export(aTHX_ "any_gt", xs_any_gt, NULL);
    register_export(aTHX_ "any_lt", xs_any_lt, NULL);
    register_export(aTHX_ "any_ge", xs_any_ge, NULL);
    register_export(aTHX_ "any_le", xs_any_le, NULL);
    register_export(aTHX_ "any_eq", xs_any_eq, NULL);
    register_export(aTHX_ "any_ne", xs_any_ne, NULL);

    /* Specialized predicates - all_* */
    register_export(aTHX_ "all_gt", xs_all_gt, NULL);
    register_export(aTHX_ "all_lt", xs_all_lt, NULL);
    register_export(aTHX_ "all_ge", xs_all_ge, NULL);
    register_export(aTHX_ "all_le", xs_all_le, NULL);
    register_export(aTHX_ "all_eq", xs_all_eq, NULL);
    register_export(aTHX_ "all_ne", xs_all_ne, NULL);

    /* Specialized predicates - none_* */
    register_export(aTHX_ "none_gt", xs_none_gt, NULL);
    register_export(aTHX_ "none_lt", xs_none_lt, NULL);
    register_export(aTHX_ "none_ge", xs_none_ge, NULL);
    register_export(aTHX_ "none_le", xs_none_le, NULL);
    register_export(aTHX_ "none_eq", xs_none_eq, NULL);
    register_export(aTHX_ "none_ne", xs_none_ne, NULL);

    /* Collection functions */
    register_export(aTHX_ "pick", xs_pick, NULL);
    register_export(aTHX_ "pluck", xs_pluck, NULL);
    register_export(aTHX_ "omit", xs_omit, NULL);
    register_export(aTHX_ "uniq", xs_uniq, NULL);
    register_export(aTHX_ "partition", xs_partition, NULL);
    register_export(aTHX_ "defaults", xs_defaults, NULL);
    register_export(aTHX_ "count", xs_count, NULL);
    register_export(aTHX_ "replace_all", xs_replace_all, NULL);

    /* Type predicates */
    register_export(aTHX_ "is_ref", xs_is_ref, is_ref_call_checker);
    register_export(aTHX_ "is_array", xs_is_array, is_array_call_checker);
    register_export(aTHX_ "is_hash", xs_is_hash, is_hash_call_checker);
    register_export(aTHX_ "is_code", xs_is_code, is_code_call_checker);
    register_export(aTHX_ "is_defined", xs_is_defined, is_defined_call_checker);
    register_export(aTHX_ "is_string", xs_is_string, is_string_call_checker);

    /* String predicates */
    register_export(aTHX_ "is_empty", xs_is_empty, is_empty_call_checker);
    register_export(aTHX_ "starts_with", xs_starts_with, starts_with_call_checker);
    register_export(aTHX_ "ends_with", xs_ends_with, ends_with_call_checker);
    register_export(aTHX_ "trim", xs_trim, trim_call_checker);
    register_export(aTHX_ "ltrim", xs_ltrim, ltrim_call_checker);
    register_export(aTHX_ "rtrim", xs_rtrim, rtrim_call_checker);

    /* Boolean predicates */
    register_export(aTHX_ "is_true", xs_is_true, is_true_call_checker);
    register_export(aTHX_ "is_false", xs_is_false, is_false_call_checker);
    register_export(aTHX_ "bool", xs_bool, bool_call_checker);

    /* Extended type predicates */
    register_export(aTHX_ "is_num", xs_is_num, is_num_call_checker);
    register_export(aTHX_ "is_int", xs_is_int, is_int_call_checker);
    register_export(aTHX_ "is_blessed", xs_is_blessed, is_blessed_call_checker);
    register_export(aTHX_ "is_scalar_ref", xs_is_scalar_ref, is_scalar_ref_call_checker);
    register_export(aTHX_ "is_regex", xs_is_regex, is_regex_call_checker);
    register_export(aTHX_ "is_glob", xs_is_glob, is_glob_call_checker);

    /* Numeric predicates */
    register_export(aTHX_ "is_positive", xs_is_positive, is_positive_call_checker);
    register_export(aTHX_ "is_negative", xs_is_negative, is_negative_call_checker);
    register_export(aTHX_ "is_zero", xs_is_zero, is_zero_call_checker);
    register_export(aTHX_ "is_even", xs_is_even, is_even_call_checker);
    register_export(aTHX_ "is_odd", xs_is_odd, is_odd_call_checker);
    register_export(aTHX_ "is_between", xs_is_between, is_between_call_checker);

    /* Collection predicates */
    register_export(aTHX_ "is_empty_array", xs_is_empty_array, is_empty_array_call_checker);
    register_export(aTHX_ "is_empty_hash", xs_is_empty_hash, is_empty_hash_call_checker);
    register_export(aTHX_ "array_len", xs_array_len, array_len_call_checker);
    register_export(aTHX_ "hash_size", xs_hash_size, hash_size_call_checker);
    register_export(aTHX_ "array_first", xs_array_first, array_first_call_checker);
    register_export(aTHX_ "array_last", xs_array_last, array_last_call_checker);

    /* Conditional/numeric ops */
    register_export(aTHX_ "maybe", xs_maybe, maybe_call_checker);
    register_export(aTHX_ "sign", xs_sign, sign_call_checker);
    register_export(aTHX_ "min2", xs_min2, min2_call_checker);
    register_export(aTHX_ "max2", xs_max2, max2_call_checker);
}

static char* get_caller(pTHX) {
    return HvNAME((HV*)CopSTASH(PL_curcop));
}

/* Fast O(1) import using hash lookup */
XS_INTERNAL(xs_import) {
    dXSARGS;
    char *pkg = get_caller(aTHX);
    IV i;
    STRLEN name_len;
    char full[512];

    for (i = 1; i < items; i++) {
        char *name = SvPV(ST(i), name_len);
        SV **entry_sv = hv_fetch(g_export_hash, name, name_len, 0);

        if (!entry_sv || !*entry_sv) {
            croak("util: unknown export '%s'", name);
        }

        ExportEntry *entry = INT2PTR(ExportEntry*, SvIV(*entry_sv));
        snprintf(full, sizeof(full), "%s::%s", pkg, name);

        if (entry->xs_func) {
            /* XS function: create XS stub in caller's namespace.
             * Note: We intentionally do NOT install call checkers on exported
             * functions. Call checkers are compile-time optimizations that work
             * by transforming the op tree. They work on util::* functions because
             * those are installed at boot time before any user code compiles.
             * Users who want compile-time optimization should call util::func()
             * directly instead of importing. */
            CV *cv = newXS(full, entry->xs_func, __FILE__);
            PERL_UNUSED_VAR(cv);
        } else if (entry->perl_cv) {
            /* Perl coderef: create alias in caller's namespace */
            GV *gv = gv_fetchpv(full, GV_ADD, SVt_PVCV);
            if (gv) {
                /* Get the actual CV from the reference */
                CV *src_cv = (CV*)SvRV(entry->perl_cv);
                /* Assign the CV to the glob's CODE slot */
                SvREFCNT_inc((SV*)src_cv);
                GvCV_set(gv, src_cv);
            }
        }
    }

    XSRETURN_EMPTY;
}

/* ============================================
   Boot
   ============================================ */

XS_EXTERNAL(boot_Func__Util) {
    dXSBOOTARGSXSAPIVERCHK;
    PERL_UNUSED_VAR(items);

    /* Initialize built-in loop callbacks */
    init_builtin_callbacks(aTHX);

    /* Register custom ops */
    XopENTRY_set(&identity_xop, xop_name, "identity");
    XopENTRY_set(&identity_xop, xop_desc, "identity passthrough");
    Perl_custom_op_register(aTHX_ pp_identity, &identity_xop);

    XopENTRY_set(&always_xop, xop_name, "always");
    XopENTRY_set(&always_xop, xop_desc, "always return stored value");
    Perl_custom_op_register(aTHX_ pp_always, &always_xop);

    XopENTRY_set(&clamp_xop, xop_name, "clamp");
    XopENTRY_set(&clamp_xop, xop_desc, "clamp value between min and max");
    Perl_custom_op_register(aTHX_ pp_clamp, &clamp_xop);

    /* Register type predicate custom ops */
    XopENTRY_set(&is_ref_xop, xop_name, "is_ref");
    XopENTRY_set(&is_ref_xop, xop_desc, "check if value is a reference");
    Perl_custom_op_register(aTHX_ pp_is_ref, &is_ref_xop);

    XopENTRY_set(&is_array_xop, xop_name, "is_array");
    XopENTRY_set(&is_array_xop, xop_desc, "check if value is an arrayref");
    Perl_custom_op_register(aTHX_ pp_is_array, &is_array_xop);

    XopENTRY_set(&is_hash_xop, xop_name, "is_hash");
    XopENTRY_set(&is_hash_xop, xop_desc, "check if value is a hashref");
    Perl_custom_op_register(aTHX_ pp_is_hash, &is_hash_xop);

    XopENTRY_set(&is_code_xop, xop_name, "is_code");
    XopENTRY_set(&is_code_xop, xop_desc, "check if value is a coderef");
    Perl_custom_op_register(aTHX_ pp_is_code, &is_code_xop);

    XopENTRY_set(&is_defined_xop, xop_name, "is_defined");
    XopENTRY_set(&is_defined_xop, xop_desc, "check if value is defined");
    Perl_custom_op_register(aTHX_ pp_is_defined, &is_defined_xop);

    /* Register string predicate custom ops */
    XopENTRY_set(&is_empty_xop, xop_name, "is_empty");
    XopENTRY_set(&is_empty_xop, xop_desc, "check if string is empty");
    Perl_custom_op_register(aTHX_ pp_is_empty, &is_empty_xop);

    XopENTRY_set(&starts_with_xop, xop_name, "starts_with");
    XopENTRY_set(&starts_with_xop, xop_desc, "check if string starts with prefix");
    Perl_custom_op_register(aTHX_ pp_starts_with, &starts_with_xop);

    XopENTRY_set(&ends_with_xop, xop_name, "ends_with");
    XopENTRY_set(&ends_with_xop, xop_desc, "check if string ends with suffix");
    Perl_custom_op_register(aTHX_ pp_ends_with, &ends_with_xop);

    /* Register boolean/truthiness custom ops */
    XopENTRY_set(&is_true_xop, xop_name, "is_true");
    XopENTRY_set(&is_true_xop, xop_desc, "check if value is truthy");
    Perl_custom_op_register(aTHX_ pp_is_true, &is_true_xop);

    XopENTRY_set(&is_false_xop, xop_name, "is_false");
    XopENTRY_set(&is_false_xop, xop_desc, "check if value is falsy");
    Perl_custom_op_register(aTHX_ pp_is_false, &is_false_xop);

    XopENTRY_set(&bool_xop, xop_name, "bool");
    XopENTRY_set(&bool_xop, xop_desc, "normalize to boolean");
    Perl_custom_op_register(aTHX_ pp_bool, &bool_xop);

    /* Register extended type predicate custom ops */
    XopENTRY_set(&is_num_xop, xop_name, "is_num");
    XopENTRY_set(&is_num_xop, xop_desc, "check if value is numeric");
    Perl_custom_op_register(aTHX_ pp_is_num, &is_num_xop);

    XopENTRY_set(&is_int_xop, xop_name, "is_int");
    XopENTRY_set(&is_int_xop, xop_desc, "check if value is integer");
    Perl_custom_op_register(aTHX_ pp_is_int, &is_int_xop);

    XopENTRY_set(&is_blessed_xop, xop_name, "is_blessed");
    XopENTRY_set(&is_blessed_xop, xop_desc, "check if value is blessed");
    Perl_custom_op_register(aTHX_ pp_is_blessed, &is_blessed_xop);

    XopENTRY_set(&is_scalar_ref_xop, xop_name, "is_scalar_ref");
    XopENTRY_set(&is_scalar_ref_xop, xop_desc, "check if value is scalar reference");
    Perl_custom_op_register(aTHX_ pp_is_scalar_ref, &is_scalar_ref_xop);

    XopENTRY_set(&is_regex_xop, xop_name, "is_regex");
    XopENTRY_set(&is_regex_xop, xop_desc, "check if value is compiled regex");
    Perl_custom_op_register(aTHX_ pp_is_regex, &is_regex_xop);

    XopENTRY_set(&is_glob_xop, xop_name, "is_glob");
    XopENTRY_set(&is_glob_xop, xop_desc, "check if value is glob");
    Perl_custom_op_register(aTHX_ pp_is_glob, &is_glob_xop);

    XopENTRY_set(&is_string_xop, xop_name, "is_string");
    XopENTRY_set(&is_string_xop, xop_desc, "check if value is plain scalar");
    Perl_custom_op_register(aTHX_ pp_is_string, &is_string_xop);

    /* Register numeric predicate custom ops */
    XopENTRY_set(&is_positive_xop, xop_name, "is_positive");
    XopENTRY_set(&is_positive_xop, xop_desc, "check if value is positive");
    Perl_custom_op_register(aTHX_ pp_is_positive, &is_positive_xop);

    XopENTRY_set(&is_negative_xop, xop_name, "is_negative");
    XopENTRY_set(&is_negative_xop, xop_desc, "check if value is negative");
    Perl_custom_op_register(aTHX_ pp_is_negative, &is_negative_xop);

    XopENTRY_set(&is_zero_xop, xop_name, "is_zero");
    XopENTRY_set(&is_zero_xop, xop_desc, "check if value is zero");
    Perl_custom_op_register(aTHX_ pp_is_zero, &is_zero_xop);

    /* Register numeric utility custom ops */
    XopENTRY_set(&is_even_xop, xop_name, "is_even");
    XopENTRY_set(&is_even_xop, xop_desc, "check if integer is even");
    Perl_custom_op_register(aTHX_ pp_is_even, &is_even_xop);

    XopENTRY_set(&is_odd_xop, xop_name, "is_odd");
    XopENTRY_set(&is_odd_xop, xop_desc, "check if integer is odd");
    Perl_custom_op_register(aTHX_ pp_is_odd, &is_odd_xop);

    XopENTRY_set(&is_between_xop, xop_name, "is_between");
    XopENTRY_set(&is_between_xop, xop_desc, "check if value is between min and max");
    Perl_custom_op_register(aTHX_ pp_is_between, &is_between_xop);

    /* Register collection custom ops */
    XopENTRY_set(&is_empty_array_xop, xop_name, "is_empty_array");
    XopENTRY_set(&is_empty_array_xop, xop_desc, "check if arrayref is empty");
    Perl_custom_op_register(aTHX_ pp_is_empty_array, &is_empty_array_xop);

    XopENTRY_set(&is_empty_hash_xop, xop_name, "is_empty_hash");
    XopENTRY_set(&is_empty_hash_xop, xop_desc, "check if hashref is empty");
    Perl_custom_op_register(aTHX_ pp_is_empty_hash, &is_empty_hash_xop);

    XopENTRY_set(&array_len_xop, xop_name, "array_len");
    XopENTRY_set(&array_len_xop, xop_desc, "get array length");
    Perl_custom_op_register(aTHX_ pp_array_len, &array_len_xop);

    XopENTRY_set(&hash_size_xop, xop_name, "hash_size");
    XopENTRY_set(&hash_size_xop, xop_desc, "get hash key count");
    Perl_custom_op_register(aTHX_ pp_hash_size, &hash_size_xop);

    XopENTRY_set(&array_first_xop, xop_name, "array_first");
    XopENTRY_set(&array_first_xop, xop_desc, "get first array element");
    Perl_custom_op_register(aTHX_ pp_array_first, &array_first_xop);

    XopENTRY_set(&array_last_xop, xop_name, "array_last");
    XopENTRY_set(&array_last_xop, xop_desc, "get last array element");
    Perl_custom_op_register(aTHX_ pp_array_last, &array_last_xop);

    /* Register string manipulation custom ops */
    XopENTRY_set(&trim_xop, xop_name, "trim");
    XopENTRY_set(&trim_xop, xop_desc, "trim whitespace from string");
    Perl_custom_op_register(aTHX_ pp_trim, &trim_xop);

    XopENTRY_set(&ltrim_xop, xop_name, "ltrim");
    XopENTRY_set(&ltrim_xop, xop_desc, "trim leading whitespace");
    Perl_custom_op_register(aTHX_ pp_ltrim, &ltrim_xop);

    XopENTRY_set(&rtrim_xop, xop_name, "rtrim");
    XopENTRY_set(&rtrim_xop, xop_desc, "trim trailing whitespace");
    Perl_custom_op_register(aTHX_ pp_rtrim, &rtrim_xop);

    /* Register conditional custom ops */
    XopENTRY_set(&maybe_xop, xop_name, "maybe");
    XopENTRY_set(&maybe_xop, xop_desc, "return value if defined");
    Perl_custom_op_register(aTHX_ pp_maybe, &maybe_xop);

    /* Register numeric custom ops */
    XopENTRY_set(&sign_xop, xop_name, "sign");
    XopENTRY_set(&sign_xop, xop_desc, "return sign of number");
    Perl_custom_op_register(aTHX_ pp_sign, &sign_xop);

    XopENTRY_set(&min2_xop, xop_name, "min2");
    XopENTRY_set(&min2_xop, xop_desc, "return smaller of two values");
    Perl_custom_op_register(aTHX_ pp_min2, &min2_xop);

    XopENTRY_set(&max2_xop, xop_name, "max2");
    XopENTRY_set(&max2_xop, xop_desc, "return larger of two values");
    Perl_custom_op_register(aTHX_ pp_max2, &max2_xop);

    /* Initialize memo storage */
    g_memo_size = 16;
    Newxz(g_memos, g_memo_size, MemoizedFunc);

    /* Initialize lazy storage */
    g_lazy_size = 16;
    Newxz(g_lazies, g_lazy_size, LazyValue);

    /* Initialize always storage */
    g_always_size = 16;
    Newxz(g_always_values, g_always_size, SV*);

    /* Initialize once storage */
    g_once_size = 16;
    Newxz(g_onces, g_once_size, OnceFunc);

    /* Initialize partial storage */
    g_partial_size = 16;
    Newxz(g_partials, g_partial_size, PartialFunc);

    /* Initialize export hash for O(1) import lookup */
    init_export_hash(aTHX);

    /* Export functions */
    newXS("Func::Util::import", xs_import, __FILE__);

    /* Export registry API */
    newXS("Func::Util::register_export", xs_register_export, __FILE__);
    newXS("Func::Util::has_export", xs_has_export, __FILE__);
    newXS("Func::Util::list_exports", xs_list_exports, __FILE__);

    newXS("Func::Util::memo", xs_memo, __FILE__);
    newXS("Func::Util::pipeline", xs_pipe, __FILE__);
    newXS("Func::Util::compose", xs_compose, __FILE__);
    newXS("Func::Util::lazy", xs_lazy, __FILE__);
    newXS("Func::Util::force", xs_force, __FILE__);
    newXS("Func::Util::dig", xs_dig, __FILE__);
    
    {
        CV *cv = newXS("Func::Util::clamp", xs_clamp, __FILE__);
        cv_set_call_checker(cv, clamp_call_checker, (SV*)cv);
    }
    
    newXS("Func::Util::tap", xs_tap, __FILE__);

    {
        CV *cv = newXS("Func::Util::identity", xs_identity, __FILE__);
        cv_set_call_checker(cv, identity_call_checker, (SV*)cv);
    }

    newXS("Func::Util::always", xs_always, __FILE__);
    {
        CV *cv = newXS("Func::Util::noop", xs_noop, __FILE__);
        cv_set_call_checker(cv, noop_call_checker, (SV*)cv);
    }
    newXS("Func::Util::stub_true", xs_stub_true, __FILE__);
    newXS("Func::Util::stub_false", xs_stub_false, __FILE__);
    newXS("Func::Util::stub_array", xs_stub_array, __FILE__);
    newXS("Func::Util::stub_hash", xs_stub_hash, __FILE__);
    newXS("Func::Util::stub_string", xs_stub_string, __FILE__);
    newXS("Func::Util::stub_zero", xs_stub_zero, __FILE__);
    newXS("Func::Util::nvl", xs_nvl, __FILE__);
    newXS("Func::Util::coalesce", xs_coalesce, __FILE__);

    /* List functions */
    newXS("Func::Util::first", xs_first, __FILE__);
    newXS("Func::Util::firstr", xs_firstr, __FILE__);
    newXS("Func::Util::any", xs_any, __FILE__);
    newXS("Func::Util::all", xs_all, __FILE__);
    newXS("Func::Util::none", xs_none, __FILE__);
#ifdef dMULTICALL
    newXS("Func::Util::first_inline", xs_first_inline, __FILE__); /* experimental, 5.11+ only */
#endif

    /* Named callback loop functions */
    newXS("Func::Util::any_cb", xs_any_cb, __FILE__);
    newXS("Func::Util::all_cb", xs_all_cb, __FILE__);
    newXS("Func::Util::none_cb", xs_none_cb, __FILE__);
    newXS("Func::Util::first_cb", xs_first_cb, __FILE__);
    newXS("Func::Util::grep_cb", xs_grep_cb, __FILE__);
    newXS("Func::Util::count_cb", xs_count_cb, __FILE__);
    newXS("Func::Util::partition_cb", xs_partition_cb, __FILE__);
    newXS("Func::Util::final_cb", xs_final_cb, __FILE__);
    newXS("Func::Util::register_callback", xs_register_callback, __FILE__);
    newXS("Func::Util::has_callback", xs_has_callback, __FILE__);
    newXS("Func::Util::list_callbacks", xs_list_callbacks, __FILE__);

    /* Specialized array predicates - pure C, no callback */
    newXS("Func::Util::first_gt", xs_first_gt, __FILE__);
    newXS("Func::Util::first_lt", xs_first_lt, __FILE__);
    newXS("Func::Util::first_ge", xs_first_ge, __FILE__);
    newXS("Func::Util::first_le", xs_first_le, __FILE__);
    newXS("Func::Util::first_eq", xs_first_eq, __FILE__);
    newXS("Func::Util::first_ne", xs_first_ne, __FILE__);
    newXS("Func::Util::final", xs_final, __FILE__);
    newXS("Func::Util::final_gt", xs_final_gt, __FILE__);
    newXS("Func::Util::final_lt", xs_final_lt, __FILE__);
    newXS("Func::Util::final_ge", xs_final_ge, __FILE__);
    newXS("Func::Util::final_le", xs_final_le, __FILE__);
    newXS("Func::Util::final_eq", xs_final_eq, __FILE__);
    newXS("Func::Util::final_ne", xs_final_ne, __FILE__);
    newXS("Func::Util::any_gt", xs_any_gt, __FILE__);
    newXS("Func::Util::any_lt", xs_any_lt, __FILE__);
    newXS("Func::Util::any_ge", xs_any_ge, __FILE__);
    newXS("Func::Util::any_le", xs_any_le, __FILE__);
    newXS("Func::Util::any_eq", xs_any_eq, __FILE__);
    newXS("Func::Util::any_ne", xs_any_ne, __FILE__);
    newXS("Func::Util::all_gt", xs_all_gt, __FILE__);
    newXS("Func::Util::all_lt", xs_all_lt, __FILE__);
    newXS("Func::Util::all_ge", xs_all_ge, __FILE__);
    newXS("Func::Util::all_le", xs_all_le, __FILE__);
    newXS("Func::Util::all_eq", xs_all_eq, __FILE__);
    newXS("Func::Util::all_ne", xs_all_ne, __FILE__);
    newXS("Func::Util::none_gt", xs_none_gt, __FILE__);
    newXS("Func::Util::none_lt", xs_none_lt, __FILE__);
    newXS("Func::Util::none_ge", xs_none_ge, __FILE__);
    newXS("Func::Util::none_le", xs_none_le, __FILE__);
    newXS("Func::Util::none_eq", xs_none_eq, __FILE__);
    newXS("Func::Util::none_ne", xs_none_ne, __FILE__);

    /* Functional combinators */
    newXS("Func::Util::negate", xs_negate, __FILE__);
    newXS("Func::Util::once", xs_once, __FILE__);
    newXS("Func::Util::partial", xs_partial, __FILE__);

    /* Data extraction */
    newXS("Func::Util::pick", xs_pick, __FILE__);
    newXS("Func::Util::pluck", xs_pluck, __FILE__);
    newXS("Func::Util::omit", xs_omit, __FILE__);
    newXS("Func::Util::uniq", xs_uniq, __FILE__);
    newXS("Func::Util::partition", xs_partition, __FILE__);
    newXS("Func::Util::defaults", xs_defaults, __FILE__);

    /* Type predicates with call checkers */
    {
        CV *cv = newXS("Func::Util::is_ref", xs_is_ref, __FILE__);
        cv_set_call_checker(cv, is_ref_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::is_array", xs_is_array, __FILE__);
        cv_set_call_checker(cv, is_array_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::is_hash", xs_is_hash, __FILE__);
        cv_set_call_checker(cv, is_hash_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::is_code", xs_is_code, __FILE__);
        cv_set_call_checker(cv, is_code_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::is_defined", xs_is_defined, __FILE__);
        cv_set_call_checker(cv, is_defined_call_checker, (SV*)cv);
    }

    /* String predicates with call checkers */
    {
        CV *cv = newXS("Func::Util::is_empty", xs_is_empty, __FILE__);
        cv_set_call_checker(cv, is_empty_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::starts_with", xs_starts_with, __FILE__);
        cv_set_call_checker(cv, starts_with_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::ends_with", xs_ends_with, __FILE__);
        cv_set_call_checker(cv, ends_with_call_checker, (SV*)cv);
    }
    newXS("Func::Util::count", xs_count, __FILE__);
    newXS("Func::Util::replace_all", xs_replace_all, __FILE__);

    /* Boolean/Truthiness predicates with call checkers */
    {
        CV *cv = newXS("Func::Util::is_true", xs_is_true, __FILE__);
        cv_set_call_checker(cv, is_true_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::is_false", xs_is_false, __FILE__);
        cv_set_call_checker(cv, is_false_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::bool", xs_bool, __FILE__);
        cv_set_call_checker(cv, bool_call_checker, (SV*)cv);
    }

    /* Extended type predicates with call checkers */
    {
        CV *cv = newXS("Func::Util::is_num", xs_is_num, __FILE__);
        cv_set_call_checker(cv, is_num_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::is_int", xs_is_int, __FILE__);
        cv_set_call_checker(cv, is_int_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::is_blessed", xs_is_blessed, __FILE__);
        cv_set_call_checker(cv, is_blessed_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::is_scalar_ref", xs_is_scalar_ref, __FILE__);
        cv_set_call_checker(cv, is_scalar_ref_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::is_regex", xs_is_regex, __FILE__);
        cv_set_call_checker(cv, is_regex_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::is_glob", xs_is_glob, __FILE__);
        cv_set_call_checker(cv, is_glob_call_checker, (SV*)cv);
    }

    /* Numeric predicates with call checkers */
    {
        CV *cv = newXS("Func::Util::is_positive", xs_is_positive, __FILE__);
        cv_set_call_checker(cv, is_positive_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::is_negative", xs_is_negative, __FILE__);
        cv_set_call_checker(cv, is_negative_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::is_zero", xs_is_zero, __FILE__);
        cv_set_call_checker(cv, is_zero_call_checker, (SV*)cv);
    }

    /* Numeric utility ops with call checkers */
    {
        CV *cv = newXS("Func::Util::is_even", xs_is_even, __FILE__);
        cv_set_call_checker(cv, is_even_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::is_odd", xs_is_odd, __FILE__);
        cv_set_call_checker(cv, is_odd_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::is_between", xs_is_between, __FILE__);
        cv_set_call_checker(cv, is_between_call_checker, (SV*)cv);
    }

    /* Collection ops with call checkers */
    {
        CV *cv = newXS("Func::Util::is_empty_array", xs_is_empty_array, __FILE__);
        cv_set_call_checker(cv, is_empty_array_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::is_empty_hash", xs_is_empty_hash, __FILE__);
        cv_set_call_checker(cv, is_empty_hash_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::array_len", xs_array_len, __FILE__);
        cv_set_call_checker(cv, array_len_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::hash_size", xs_hash_size, __FILE__);
        cv_set_call_checker(cv, hash_size_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::array_first", xs_array_first, __FILE__);
        cv_set_call_checker(cv, array_first_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::array_last", xs_array_last, __FILE__);
        cv_set_call_checker(cv, array_last_call_checker, (SV*)cv);
    }

    /* String manipulation ops with call checkers */
    {
        CV *cv = newXS("Func::Util::trim", xs_trim, __FILE__);
        cv_set_call_checker(cv, trim_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::ltrim", xs_ltrim, __FILE__);
        cv_set_call_checker(cv, ltrim_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::rtrim", xs_rtrim, __FILE__);
        cv_set_call_checker(cv, rtrim_call_checker, (SV*)cv);
    }

    /* Conditional ops with call checkers */
    {
        CV *cv = newXS("Func::Util::maybe", xs_maybe, __FILE__);
        cv_set_call_checker(cv, maybe_call_checker, (SV*)cv);
    }

    /* Numeric ops with call checkers */
    {
        CV *cv = newXS("Func::Util::sign", xs_sign, __FILE__);
        cv_set_call_checker(cv, sign_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::min2", xs_min2, __FILE__);
        cv_set_call_checker(cv, min2_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Func::Util::max2", xs_max2, __FILE__);
        cv_set_call_checker(cv, max2_call_checker, (SV*)cv);
    }

    /* Register cleanup for global destruction */
    Perl_call_atexit(aTHX_ cleanup_callback_registry, NULL);

    Perl_xs_boot_epilog(aTHX_ ax);
}
