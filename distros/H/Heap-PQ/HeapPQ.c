/*
 * heap.c - Ultra-fast binary heap (priority queue)
 *
 * Three API levels for different speed/convenience tradeoffs:
 *
 * 1. RAW ARRAY API (fastest - matches Array::Heap speed)
 *    push_heap_min(\@array, $val)
 *    pop_heap_min(\@array)
 *    make_heap_min(\@array)  # O(n) Floyd's heapify
 *
 * 2. NUMERIC HEAP (very fast - stores NV directly, no SV overhead)
 *    my $h = heap::new_nv('min');
 *    $h->push(3.14);  # No SV allocation
 *    $h->pop;         # Returns NV directly
 *
 * 3. OO HEAP (convenient - stores any Perl values)
 *    my $h = heap::new('min');
 *    $h->push($anything);
 *
 * Optimizations:
 * - Custom ops bypass method dispatch
 * - Inlined comparison for min/max heaps
 * - Floyd's O(n) heapify for bulk operations
 * - Zero-copy returns where possible
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "heap_compat.h"

/* ============================================
   Heap type enum
   ============================================ */
typedef enum {
    HEAP_MIN = 0,
    HEAP_MAX = 1
} HeapType;

/* ============================================
   Standard Heap structure (stores SV*)
   ============================================ */
typedef struct Heap_s Heap;
typedef void (*heap_sift_fn)(pTHX_ Heap*, IV);

struct Heap_s {
    SV **data;
    NV *priorities;
    IV size;
    IV capacity;
    HeapType type;
    SV *comparator;
    GV *gv_a;
    GV *gv_b;
    char **key_path;
    STRLEN *key_lens;
    IV key_depth;
    heap_sift_fn sift_up;
    heap_sift_fn sift_down;
};

/* ============================================
   Numeric Heap structure (stores NV directly)
   ============================================ */
typedef struct {
    NV *data;
    IV size;
    IV capacity;
    HeapType type;
} NumericHeap;

/* ============================================
   Custom op declarations
   ============================================ */
static XOP heap_func_push_xop;
static XOP heap_func_pop_xop;
static XOP heap_func_peek_xop;
static XOP heap_func_size_xop;

/* Raw array ops */
static XOP push_heap_min_xop;
static XOP pop_heap_min_xop;
static XOP push_heap_max_xop;
static XOP pop_heap_max_xop;
static XOP make_heap_min_xop;
static XOP make_heap_max_xop;

/* Numeric heap ops */
static XOP nv_push_xop;
static XOP nv_pop_xop;
static XOP nv_peek_xop;
static XOP nv_size_xop;
static XOP nv_peek_n_xop;

/* peek_n ops */
static XOP heap_func_peek_n_xop;

/* is_empty/clear/type ops */
static XOP heap_func_is_empty_xop;
static XOP heap_func_clear_xop;
static XOP heap_func_type_xop;
static XOP nv_is_empty_xop;
static XOP nv_clear_xop;

/* search/delete ops */
static XOP heap_func_search_xop;
static XOP heap_func_delete_xop;
static XOP nv_search_xop;
static XOP nv_delete_xop;

/* ============================================
   Magic vtables
   ============================================ */
static int heap_free(pTHX_ SV *sv, MAGIC *mg);
static int numeric_heap_free(pTHX_ SV *sv, MAGIC *mg);

static MGVTBL heap_vtbl = {
    NULL, NULL, NULL, NULL,
    heap_free,
    NULL, NULL, NULL
};

static MGVTBL numeric_heap_vtbl = {
    NULL, NULL, NULL, NULL,
    numeric_heap_free,
    NULL, NULL, NULL
};

/* ============================================
   Unified heap lookup (single magic walk)
   ============================================ */
typedef enum { MAGIC_NONE, MAGIC_HEAP, MAGIC_NUMERIC } HeapMagicType;

typedef struct {
    HeapMagicType type;
    union {
        Heap *heap;
        NumericHeap *nheap;
    } ptr;
} HeapLookup;

PERL_STATIC_INLINE HeapLookup find_heap(pTHX_ SV *obj) {
    HeapLookup result;
    MAGIC *mg;
    result.type = MAGIC_NONE;
    result.ptr.heap = NULL;
    if (!SvROK(obj)) return result;
    mg = mg_find(SvRV(obj), PERL_MAGIC_ext);
    while (mg) {
        if (mg->mg_virtual == &heap_vtbl) {
            result.type = MAGIC_HEAP;
            result.ptr.heap = (Heap*)mg->mg_ptr;
            return result;
        }
        if (mg->mg_virtual == &numeric_heap_vtbl) {
            result.type = MAGIC_NUMERIC;
            result.ptr.nheap = (NumericHeap*)mg->mg_ptr;
            return result;
        }
        mg = mg->mg_moremagic;
    }
    return result;
}

/* ============================================
   Get structures from blessed SV
   ============================================ */
/* Fast path: OO methods always receive a valid blessed ref.
   Our magic is always the first PERL_MAGIC_ext on the SV. */
#define HEAP_FAST(sv)    ((Heap*)mg_find(SvRV(sv), PERL_MAGIC_ext)->mg_ptr)
#define NV_HEAP_FAST(sv) ((NumericHeap*)mg_find(SvRV(sv), PERL_MAGIC_ext)->mg_ptr)

#define GET_HEAP_MAGIC(obj) mg_find(SvRV(obj), PERL_MAGIC_ext)

PERL_STATIC_INLINE Heap* get_heap(pTHX_ SV *obj) {
    MAGIC *mg;
    if (!SvROK(obj)) croak("Not a reference");
    mg = mg_find(SvRV(obj), PERL_MAGIC_ext);
    while (mg) {
        if (mg->mg_virtual == &heap_vtbl) {
            return (Heap*)mg->mg_ptr;
        }
        mg = mg->mg_moremagic;
    }
    croak("Not a heap object");
    return NULL;
}

PERL_STATIC_INLINE NumericHeap* get_numeric_heap(pTHX_ SV *obj) {
    MAGIC *mg;
    if (!SvROK(obj)) croak("Not a reference");
    mg = mg_find(SvRV(obj), PERL_MAGIC_ext);
    while (mg) {
        if (mg->mg_virtual == &numeric_heap_vtbl) {
            return (NumericHeap*)mg->mg_ptr;
        }
        mg = mg->mg_moremagic;
    }
    croak("Not a numeric heap object");
    return NULL;
}

/* ============================================
   PART 1: RAW ARRAY API (fastest)
   Operates directly on Perl arrays
   ============================================ */

/* Sift up for raw array - min heap */
static void raw_sift_up_min(pTHX_ AV *av, IV idx) {
    SV **arr = AvARRAY(av);
    SV *val = arr[idx];
    NV val_nv = SvNV(val);

    while (idx > 0) {
        IV parent = (idx - 1) >> 1;
        NV parent_nv = SvNV(arr[parent]);
        if (val_nv < parent_nv) {
            arr[idx] = arr[parent];
            idx = parent;
        } else {
            break;
        }
    }
    arr[idx] = val;
}

/* Sift up for raw array - max heap */
static void raw_sift_up_max(pTHX_ AV *av, IV idx) {
    SV **arr = AvARRAY(av);
    SV *val = arr[idx];
    NV val_nv = SvNV(val);

    while (idx > 0) {
        IV parent = (idx - 1) >> 1;
        NV parent_nv = SvNV(arr[parent]);
        if (val_nv > parent_nv) {
            arr[idx] = arr[parent];
            idx = parent;
        } else {
            break;
        }
    }
    arr[idx] = val;
}

/* Sift down for raw array - min heap */
static void raw_sift_down_min(pTHX_ AV *av, IV idx, IV size) {
    SV **arr = AvARRAY(av);
    SV *val = arr[idx];
    NV val_nv = SvNV(val);
    IV half = size >> 1;

    while (idx < half) {
        IV left = (idx << 1) + 1;
        IV right = left + 1;
        IV best = left;
        NV best_nv = SvNV(arr[left]);

        if (right < size) {
            NV right_nv = SvNV(arr[right]);
            if (right_nv < best_nv) {
                best = right;
                best_nv = right_nv;
            }
        }

        if (best_nv < val_nv) {
            arr[idx] = arr[best];
            idx = best;
        } else {
            break;
        }
    }
    arr[idx] = val;
}

/* Sift down for raw array - max heap */
static void raw_sift_down_max(pTHX_ AV *av, IV idx, IV size) {
    SV **arr = AvARRAY(av);
    SV *val = arr[idx];
    NV val_nv = SvNV(val);
    IV half = size >> 1;

    while (idx < half) {
        IV left = (idx << 1) + 1;
        IV right = left + 1;
        IV best = left;
        NV best_nv = SvNV(arr[left]);

        if (right < size) {
            NV right_nv = SvNV(arr[right]);
            if (right_nv > best_nv) {
                best = right;
                best_nv = right_nv;
            }
        }

        if (best_nv > val_nv) {
            arr[idx] = arr[best];
            idx = best;
        } else {
            break;
        }
    }
    arr[idx] = val;
}

/* push_heap_min(\@array, $value) */
XS_EXTERNAL(XS_push_heap_min) {
    dXSARGS;
    AV *av;
    SV *val;
    IV size;

    if (items != 2) croak("Usage: push_heap_min(\\@array, $value)");
    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV) {
        croak("First argument must be an array reference");
    }

    av = (AV*)SvRV(ST(0));
    val = newSVsv(ST(1));

    av_push(av, val);
    size = av_len(av) + 1;
    raw_sift_up_min(aTHX_ av, size - 1);

    XSRETURN_EMPTY;
}

/* push_heap_max(\@array, $value) */
XS_EXTERNAL(XS_push_heap_max) {
    dXSARGS;
    AV *av;
    SV *val;
    IV size;

    if (items != 2) croak("Usage: push_heap_max(\\@array, $value)");
    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV) {
        croak("First argument must be an array reference");
    }

    av = (AV*)SvRV(ST(0));
    val = newSVsv(ST(1));

    av_push(av, val);
    size = av_len(av) + 1;
    raw_sift_up_max(aTHX_ av, size - 1);

    XSRETURN_EMPTY;
}

/* pop_heap_min(\@array) */
XS_EXTERNAL(XS_pop_heap_min) {
    dXSARGS;
    AV *av;
    IV size;
    SV *result;
    SV **arr;

    if (items != 1) croak("Usage: pop_heap_min(\\@array)");
    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV) {
        croak("First argument must be an array reference");
    }

    av = (AV*)SvRV(ST(0));
    size = av_len(av) + 1;

    if (size == 0) XSRETURN_UNDEF;

    arr = AvARRAY(av);
    result = arr[0];

    if (size > 1) {
        arr[0] = arr[size - 1];
        AvFILLp(av) = size - 2;
        raw_sift_down_min(aTHX_ av, 0, size - 1);
    } else {
        AvFILLp(av) = -1;
    }

    ST(0) = sv_2mortal(result);
    XSRETURN(1);
}

/* pop_heap_max(\@array) */
XS_EXTERNAL(XS_pop_heap_max) {
    dXSARGS;
    AV *av;
    IV size;
    SV *result;
    SV **arr;

    if (items != 1) croak("Usage: pop_heap_max(\\@array)");
    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV) {
        croak("First argument must be an array reference");
    }

    av = (AV*)SvRV(ST(0));
    size = av_len(av) + 1;

    if (size == 0) XSRETURN_UNDEF;

    arr = AvARRAY(av);
    result = arr[0];

    if (size > 1) {
        arr[0] = arr[size - 1];
        AvFILLp(av) = size - 2;
        raw_sift_down_max(aTHX_ av, 0, size - 1);
    } else {
        AvFILLp(av) = -1;
    }

    ST(0) = sv_2mortal(result);
    XSRETURN(1);
}

/* make_heap_min(\@array) - Floyd's O(n) heapify */
XS_EXTERNAL(XS_make_heap_min) {
    dXSARGS;
    AV *av;
    IV size, i;

    if (items != 1) croak("Usage: make_heap_min(\\@array)");
    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV) {
        croak("First argument must be an array reference");
    }

    av = (AV*)SvRV(ST(0));
    size = av_len(av) + 1;

    /* Floyd's algorithm: sift down from middle to root */
    for (i = (size >> 1) - 1; i >= 0; i--) {
        raw_sift_down_min(aTHX_ av, i, size);
    }

    XSRETURN_EMPTY;
}

/* make_heap_max(\@array) - Floyd's O(n) heapify */
XS_EXTERNAL(XS_make_heap_max) {
    dXSARGS;
    AV *av;
    IV size, i;

    if (items != 1) croak("Usage: make_heap_max(\\@array)");
    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV) {
        croak("First argument must be an array reference");
    }

    av = (AV*)SvRV(ST(0));
    size = av_len(av) + 1;

    for (i = (size >> 1) - 1; i >= 0; i--) {
        raw_sift_down_max(aTHX_ av, i, size);
    }

    XSRETURN_EMPTY;
}

/* ============================================
   Raw array custom ops
   ============================================ */

/* pp_push_heap_min: BINOP(\@array, $value) */
static OP* pp_push_heap_min(pTHX) {
    dSP;
    SV *val_sv = TOPs;
    SV *aref = TOPm1s;
    AV *av;
    SV *val;
    IV size;

    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV)
        croak("First argument must be an array reference");

    av = (AV*)SvRV(aref);
    val = newSVsv(val_sv);
    av_push(av, val);
    size = av_len(av) + 1;
    raw_sift_up_min(aTHX_ av, size - 1);

    SP--;
    SETs(&PL_sv_undef);
    RETURN;
}

/* pp_push_heap_max: BINOP(\@array, $value) */
static OP* pp_push_heap_max(pTHX) {
    dSP;
    SV *val_sv = TOPs;
    SV *aref = TOPm1s;
    AV *av;
    SV *val;
    IV size;

    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV)
        croak("First argument must be an array reference");

    av = (AV*)SvRV(aref);
    val = newSVsv(val_sv);
    av_push(av, val);
    size = av_len(av) + 1;
    raw_sift_up_max(aTHX_ av, size - 1);

    SP--;
    SETs(&PL_sv_undef);
    RETURN;
}

/* pp_pop_heap_min: UNOP(\@array) */
static OP* pp_pop_heap_min(pTHX) {
    dSP;
    SV *aref = TOPs;
    AV *av;
    IV size;
    SV *result;
    SV **arr;

    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV)
        croak("First argument must be an array reference");

    av = (AV*)SvRV(aref);
    size = av_len(av) + 1;

    if (size == 0) {
        SETs(&PL_sv_undef);
        RETURN;
    }

    arr = AvARRAY(av);
    result = arr[0];

    if (size > 1) {
        arr[0] = arr[size - 1];
        AvFILLp(av) = size - 2;
        raw_sift_down_min(aTHX_ av, 0, size - 1);
    } else {
        AvFILLp(av) = -1;
    }

    SETs(sv_2mortal(result));
    RETURN;
}

/* pp_pop_heap_max: UNOP(\@array) */
static OP* pp_pop_heap_max(pTHX) {
    dSP;
    SV *aref = TOPs;
    AV *av;
    IV size;
    SV *result;
    SV **arr;

    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV)
        croak("First argument must be an array reference");

    av = (AV*)SvRV(aref);
    size = av_len(av) + 1;

    if (size == 0) {
        SETs(&PL_sv_undef);
        RETURN;
    }

    arr = AvARRAY(av);
    result = arr[0];

    if (size > 1) {
        arr[0] = arr[size - 1];
        AvFILLp(av) = size - 2;
        raw_sift_down_max(aTHX_ av, 0, size - 1);
    } else {
        AvFILLp(av) = -1;
    }

    SETs(sv_2mortal(result));
    RETURN;
}

/* pp_make_heap_min: UNOP(\@array) */
static OP* pp_make_heap_min(pTHX) {
    dSP;
    SV *aref = TOPs;
    AV *av;
    IV size, i;

    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV)
        croak("First argument must be an array reference");

    av = (AV*)SvRV(aref);
    size = av_len(av) + 1;

    for (i = (size >> 1) - 1; i >= 0; i--) {
        raw_sift_down_min(aTHX_ av, i, size);
    }

    SETs(&PL_sv_undef);
    RETURN;
}

/* pp_make_heap_max: UNOP(\@array) */
static OP* pp_make_heap_max(pTHX) {
    dSP;
    SV *aref = TOPs;
    AV *av;
    IV size, i;

    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV)
        croak("First argument must be an array reference");

    av = (AV*)SvRV(aref);
    size = av_len(av) + 1;

    for (i = (size >> 1) - 1; i >= 0; i--) {
        raw_sift_down_max(aTHX_ av, i, size);
    }

    SETs(&PL_sv_undef);
    RETURN;
}

/* ============================================
   PART 2: NUMERIC HEAP (stores NV directly)
   ============================================ */

PERL_STATIC_INLINE void nv_ensure_capacity(NumericHeap *h, IV needed) {
    if (needed > h->capacity) {
        IV new_cap = h->capacity ? h->capacity * 2 : 16;
        while (new_cap < needed) new_cap *= 2;
        Renew(h->data, new_cap, NV);
        h->capacity = new_cap;
    }
}

/* Sift up for NV min-heap */
static void nv_sift_up_min(NumericHeap *h, IV idx) {
    NV *data = h->data;
    NV val = data[idx];

    while (idx > 0) {
        IV parent = (idx - 1) >> 1;
        if (val < data[parent]) {
            data[idx] = data[parent];
            idx = parent;
        } else {
            break;
        }
    }
    data[idx] = val;
}

/* Sift up for NV max-heap */
static void nv_sift_up_max(NumericHeap *h, IV idx) {
    NV *data = h->data;
    NV val = data[idx];

    while (idx > 0) {
        IV parent = (idx - 1) >> 1;
        if (val > data[parent]) {
            data[idx] = data[parent];
            idx = parent;
        } else {
            break;
        }
    }
    data[idx] = val;
}

/* Sift down for NV min-heap */
static void nv_sift_down_min(NumericHeap *h, IV idx) {
    NV *data = h->data;
    IV size = h->size;
    NV val = data[idx];
    IV half = size >> 1;

    while (idx < half) {
        IV left = (idx << 1) + 1;
        IV right = left + 1;
        IV best = left;
        NV best_nv = data[left];

        if (right < size && data[right] < best_nv) {
            best = right;
            best_nv = data[right];
        }

        if (best_nv < val) {
            data[idx] = data[best];
            idx = best;
        } else {
            break;
        }
    }
    data[idx] = val;
}

/* Sift down for NV max-heap */
static void nv_sift_down_max(NumericHeap *h, IV idx) {
    NV *data = h->data;
    IV size = h->size;
    NV val = data[idx];
    IV half = size >> 1;

    while (idx < half) {
        IV left = (idx << 1) + 1;
        IV right = left + 1;
        IV best = left;
        NV best_nv = data[left];

        if (right < size && data[right] > best_nv) {
            best = right;
            best_nv = data[right];
        }

        if (best_nv > val) {
            data[idx] = data[best];
            idx = best;
        } else {
            break;
        }
    }
    data[idx] = val;
}

static int numeric_heap_free(pTHX_ SV *sv, MAGIC *mg) {
    NumericHeap *h = (NumericHeap*)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (h->data) Safefree(h->data);
    Safefree(h);
    return 0;
}

/* heap::new_nv($type) - create numeric heap */
XS_EXTERNAL(XS_heap_new_nv) {
    dXSARGS;
    NumericHeap *h;
    SV *obj_sv, *rv;
    HV *stash;
    HeapType type = HEAP_MIN;
    int arg_offset = 0;

    if (items >= 1 && SvPOK(ST(0))) {
        STRLEN len;
        const char *str = SvPV(ST(0), len);
        if (len == 8 && strEQ(str, "Heap::PQ")) {
            arg_offset = 1;
        } else if (len == 3 && (strEQ(str, "min") || strEQ(str, "max"))) {
            arg_offset = 0;
        } else {
            arg_offset = 1;
        }
    }

    if (items > arg_offset) {
        STRLEN len;
        const char *type_str = SvPV(ST(arg_offset), len);
        if (len == 3 && strEQ(type_str, "max")) {
            type = HEAP_MAX;
        }
    }

    Newxz(h, 1, NumericHeap);
    h->type = type;
    h->size = 0;
    h->capacity = 16;
    Newx(h->data, 16, NV);

    obj_sv = newSV(0);
    sv_magicext(obj_sv, NULL, PERL_MAGIC_ext, &numeric_heap_vtbl, (char*)h, 0);

    rv = newRV_noinc(obj_sv);
    stash = gv_stashpvn("Heap::PQ::nv", 12, GV_ADD);
    sv_bless(rv, stash);

    ST(0) = sv_2mortal(rv);
    XSRETURN(1);
}

/* $nv_heap->push($value) */
XS_EXTERNAL(XS_nv_push) {
    dXSARGS;
    NumericHeap *h;
    NV val;

    if (items != 2) croak("Usage: $heap->push($value)");

    h = NV_HEAP_FAST(ST(0));
    val = SvNV(ST(1));

    nv_ensure_capacity(h, h->size + 1);
    h->data[h->size] = val;
    h->size++;

    if (h->type == HEAP_MIN) {
        nv_sift_up_min(h, h->size - 1);
    } else {
        nv_sift_up_max(h, h->size - 1);
    }

    ST(0) = ST(0);
    XSRETURN(1);
}

/* $nv_heap->push_all(@values) - with Floyd's heapify */
XS_EXTERNAL(XS_nv_push_all) {
    dXSARGS;
    NumericHeap *h;
    int i;
    IV start_size;

    if (items < 1) croak("Usage: $heap->push_all(@values)");

    h = NV_HEAP_FAST(ST(0));
    start_size = h->size;

    nv_ensure_capacity(h, h->size + items - 1);

    /* Add all values first */
    for (i = 1; i < items; i++) {
        h->data[h->size++] = SvNV(ST(i));
    }

    /* Floyd's heapify on the new portion if significant */
    if (items - 1 > 10) {
        /* Full Floyd's heapify */
        IV j;
        for (j = (h->size >> 1) - 1; j >= 0; j--) {
            if (h->type == HEAP_MIN) {
                nv_sift_down_min(h, j);
            } else {
                nv_sift_down_max(h, j);
            }
        }
    } else {
        /* Just sift up each new element */
        for (i = start_size; i < h->size; i++) {
            if (h->type == HEAP_MIN) {
                nv_sift_up_min(h, i);
            } else {
                nv_sift_up_max(h, i);
            }
        }
    }

    ST(0) = ST(0);
    XSRETURN(1);
}

/* $nv_heap->pop() */
XS_EXTERNAL(XS_nv_pop) {
    dXSARGS;
    NumericHeap *h;
    NV result;

    if (items != 1) croak("Usage: $heap->pop()");

    h = NV_HEAP_FAST(ST(0));

    if (h->size == 0) XSRETURN_UNDEF;

    result = h->data[0];
    h->size--;

    if (h->size > 0) {
        h->data[0] = h->data[h->size];
        if (h->type == HEAP_MIN) {
            nv_sift_down_min(h, 0);
        } else {
            nv_sift_down_max(h, 0);
        }
    }

    ST(0) = sv_2mortal(newSVnv(result));
    XSRETURN(1);
}

/* $nv_heap->peek() */
XS_EXTERNAL(XS_nv_peek) {
    dXSARGS;
    NumericHeap *h;

    if (items != 1) croak("Usage: $heap->peek()");

    h = NV_HEAP_FAST(ST(0));

    if (h->size == 0) XSRETURN_UNDEF;

    ST(0) = sv_2mortal(newSVnv(h->data[0]));
    XSRETURN(1);
}

/* $nv_heap->size() */
XS_EXTERNAL(XS_nv_size) {
    dXSARGS;
    NumericHeap *h;

    if (items != 1) croak("Usage: $heap->size()");

    h = NV_HEAP_FAST(ST(0));
    XSRETURN_IV(h->size);
}

/* $nv_heap->is_empty() */
XS_EXTERNAL(XS_nv_is_empty) {
    dXSARGS;
    NumericHeap *h;

    if (items != 1) croak("Usage: $heap->is_empty()");

    h = NV_HEAP_FAST(ST(0));

    if (h->size == 0) XSRETURN_YES;
    XSRETURN_NO;
}

/* $nv_heap->clear() */
XS_EXTERNAL(XS_nv_clear) {
    dXSARGS;
    NumericHeap *h;

    if (items != 1) croak("Usage: $heap->clear()");

    h = NV_HEAP_FAST(ST(0));
    h->size = 0;

    XSRETURN_EMPTY;
}

/* $nv_heap->peek_n($n) - return top N elements in sorted order without removing */
XS_EXTERNAL(XS_nv_peek_n) {
    dXSARGS;
    NumericHeap *h;
    IV n, i, count;
    NV *saved;

    if (items != 2) croak("Usage: $heap->peek_n($n)");

    h = NV_HEAP_FAST(ST(0));
    n = SvIV(ST(1));

    if (n <= 0 || h->size == 0) XSRETURN_EMPTY;
    if (n > h->size) n = h->size;

    /* Save the original state */
    Newx(saved, h->size, NV);
    Copy(h->data, saved, h->size, NV);
    IV saved_size = h->size;

    /* Pop n elements */
    EXTEND(SP, n);
    for (i = 0; i < n; i++) {
        NV val = h->data[0];
        h->size--;
        if (h->size > 0) {
            h->data[0] = h->data[h->size];
            if (h->type == HEAP_MIN)
                nv_sift_down_min(h, 0);
            else
                nv_sift_down_max(h, 0);
        }
        ST(i) = sv_2mortal(newSVnv(val));
    }
    count = n;

    /* Restore original state */
    Copy(saved, h->data, saved_size, NV);
    h->size = saved_size;
    Safefree(saved);

    XSRETURN(count);
}

/* $nv_heap->search(sub { ... }) - find NV elements matching condition */
XS_EXTERNAL(XS_nv_search) {
    dXSARGS;
    NumericHeap *h;
    IV i, found = 0;
    SV *callback;
    NV *results;

    if (items != 2) croak("Usage: $heap->search(sub { ... })");

    h = NV_HEAP_FAST(ST(0));
    callback = ST(1);

    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("search requires a code reference");

    if (h->size == 0) XSRETURN_EMPTY;

    Newx(results, h->size, NV);

    for (i = 0; i < h->size; i++) {
        dSP;
        SV *elem = sv_2mortal(newSVnv(h->data[i]));
        IV result;
        int count;

        ENTER; SAVETMPS;
        SAVE_DEFSV;
        DEFSV_set(elem);

        PUSHMARK(SP);
        XPUSHs(elem);
        PUTBACK;

        count = call_sv(callback, G_SCALAR);
        SPAGAIN;
        result = count > 0 ? SvTRUE(TOPs) : 0;
        if (count > 0) POPs;
        PUTBACK;
        FREETMPS; LEAVE;

        if (result) {
            results[found++] = h->data[i];
        }
    }

    EXTEND(SP, found);
    for (i = 0; i < found; i++) {
        ST(i) = sv_2mortal(newSVnv(results[i]));
    }
    Safefree(results);
    XSRETURN(found);
}

/* $nv_heap->delete(sub { ... }) - remove matching NV elements, returns count */
XS_EXTERNAL(XS_nv_delete) {
    dXSARGS;
    NumericHeap *h;
    IV i, write_pos = 0, deleted = 0;
    SV *callback;

    if (items != 2) croak("Usage: $heap->delete(sub { ... })");

    h = NV_HEAP_FAST(ST(0));
    callback = ST(1);

    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("delete requires a code reference");

    for (i = 0; i < h->size; i++) {
        dSP;
        SV *elem = sv_2mortal(newSVnv(h->data[i]));
        IV result;
        int count;

        ENTER; SAVETMPS;
        SAVE_DEFSV;
        DEFSV_set(elem);

        PUSHMARK(SP);
        XPUSHs(elem);
        PUTBACK;

        count = call_sv(callback, G_SCALAR);
        SPAGAIN;
        result = count > 0 ? SvTRUE(TOPs) : 0;
        if (count > 0) POPs;
        PUTBACK;
        FREETMPS; LEAVE;

        if (result) {
            deleted++;
        } else {
            if (write_pos != i) {
                h->data[write_pos] = h->data[i];
            }
            write_pos++;
        }
    }

    h->size = write_pos;

    /* Rebuild heap with Floyd's heapify */
    if (deleted > 0 && h->size > 1) {
        IV j;
        for (j = (h->size >> 1) - 1; j >= 0; j--) {
            if (h->type == HEAP_MIN)
                nv_sift_down_min(h, j);
            else
                nv_sift_down_max(h, j);
        }
    }

    XSRETURN_IV(deleted);
}

/* ============================================
   PART 3: STANDARD HEAP (original OO API)
   ============================================ */

PERL_STATIC_INLINE void heap_ensure_capacity(Heap *h, IV needed) {
    if (needed > h->capacity) {
        IV new_cap = h->capacity ? h->capacity * 2 : 16;
        while (new_cap < needed) new_cap *= 2;
        Renew(h->data, new_cap, SV*);
        Renew(h->priorities, new_cap, NV);
        h->capacity = new_cap;
    }
}

/* Sift functions for standard heap */
static void heap_sift_up_min(pTHX_ Heap *h, IV idx) {
    SV **data = h->data;
    NV *prio = h->priorities;
    SV *val = data[idx];
    NV val_nv = prio[idx];
    PERL_UNUSED_CONTEXT;

    while (idx > 0) {
        IV parent = (idx - 1) >> 1;
        if (val_nv < prio[parent]) {
            data[idx] = data[parent];
            prio[idx] = prio[parent];
            idx = parent;
        } else {
            break;
        }
    }
    data[idx] = val;
    prio[idx] = val_nv;
}

static void heap_sift_up_max(pTHX_ Heap *h, IV idx) {
    SV **data = h->data;
    NV *prio = h->priorities;
    SV *val = data[idx];
    NV val_nv = prio[idx];
    PERL_UNUSED_CONTEXT;

    while (idx > 0) {
        IV parent = (idx - 1) >> 1;
        if (val_nv > prio[parent]) {
            data[idx] = data[parent];
            prio[idx] = prio[parent];
            idx = parent;
        } else {
            break;
        }
    }
    data[idx] = val;
    prio[idx] = val_nv;
}

static void heap_sift_down_min(pTHX_ Heap *h, IV idx) {
    SV **data = h->data;
    NV *prio = h->priorities;
    IV size = h->size;
    SV *val = data[idx];
    NV val_nv = prio[idx];
    IV half = size >> 1;
    PERL_UNUSED_CONTEXT;

    while (idx < half) {
        IV left = (idx << 1) + 1;
        IV right = left + 1;
        IV best = left;
        NV best_nv = prio[left];

        if (right < size) {
            NV right_nv = prio[right];
            if (right_nv < best_nv) {
                best = right;
                best_nv = right_nv;
            }
        }

        if (best_nv < val_nv) {
            data[idx] = data[best];
            prio[idx] = prio[best];
            idx = best;
        } else {
            break;
        }
    }
    data[idx] = val;
    prio[idx] = val_nv;
}

static void heap_sift_down_max(pTHX_ Heap *h, IV idx) {
    SV **data = h->data;
    NV *prio = h->priorities;
    IV size = h->size;
    SV *val = data[idx];
    NV val_nv = prio[idx];
    IV half = size >> 1;
    PERL_UNUSED_CONTEXT;

    while (idx < half) {
        IV left = (idx << 1) + 1;
        IV right = left + 1;
        IV best = left;
        NV best_nv = prio[left];

        if (right < size) {
            NV right_nv = prio[right];
            if (right_nv > best_nv) {
                best = right;
                best_nv = right_nv;
            }
        }

        if (best_nv > val_nv) {
            data[idx] = data[best];
            prio[idx] = prio[best];
            idx = best;
        } else {
            break;
        }
    }
    data[idx] = val;
    prio[idx] = val_nv;
}

/* Key-path sift operations — pure C hash traversal, no Perl callbacks */

static NV heap_extract_key_nv(pTHX_ SV *sv, char **path, STRLEN *lens, IV depth) {
    IV i;
    SV *cur = sv;
    for (i = 0; i < depth; i++) {
        HV *hv;
        SV **val;
        if (!SvROK(cur)) croak("Key path: expected hash reference at depth %d", (int)i);
        hv = (HV*)SvRV(cur);
        if (SvTYPE((SV*)hv) != SVt_PVHV) croak("Key path: not a hash at depth %d", (int)i);
        val = hv_fetch(hv, path[i], lens[i], 0);
        if (!val || !*val) croak("Key path: key '%s' not found at depth %d", path[i], (int)i);
        cur = *val;
    }
    return SvNV(cur);
}

static void heap_sift_up_keypath_min(pTHX_ Heap *h, IV idx) {
    SV **data = h->data;
    char **path = h->key_path;
    STRLEN *lens = h->key_lens;
    IV depth = h->key_depth;
    SV *val = data[idx];
    NV val_nv = heap_extract_key_nv(aTHX_ val, path, lens, depth);

    while (idx > 0) {
        IV parent = (idx - 1) >> 1;
        NV parent_nv = heap_extract_key_nv(aTHX_ data[parent], path, lens, depth);
        if (val_nv < parent_nv) {
            data[idx] = data[parent];
            idx = parent;
        } else {
            break;
        }
    }
    data[idx] = val;
}

static void heap_sift_up_keypath_max(pTHX_ Heap *h, IV idx) {
    SV **data = h->data;
    char **path = h->key_path;
    STRLEN *lens = h->key_lens;
    IV depth = h->key_depth;
    SV *val = data[idx];
    NV val_nv = heap_extract_key_nv(aTHX_ val, path, lens, depth);

    while (idx > 0) {
        IV parent = (idx - 1) >> 1;
        NV parent_nv = heap_extract_key_nv(aTHX_ data[parent], path, lens, depth);
        if (val_nv > parent_nv) {
            data[idx] = data[parent];
            idx = parent;
        } else {
            break;
        }
    }
    data[idx] = val;
}

static void heap_sift_down_keypath_min(pTHX_ Heap *h, IV idx) {
    SV **data = h->data;
    IV size = h->size;
    char **path = h->key_path;
    STRLEN *lens = h->key_lens;
    IV depth = h->key_depth;
    SV *val = data[idx];
    NV val_nv = heap_extract_key_nv(aTHX_ val, path, lens, depth);
    IV half = size >> 1;

    while (idx < half) {
        IV left = (idx << 1) + 1;
        IV right = left + 1;
        IV best = left;
        NV best_nv = heap_extract_key_nv(aTHX_ data[left], path, lens, depth);

        if (right < size) {
            NV right_nv = heap_extract_key_nv(aTHX_ data[right], path, lens, depth);
            if (right_nv < best_nv) {
                best = right;
                best_nv = right_nv;
            }
        }

        if (best_nv < val_nv) {
            data[idx] = data[best];
            idx = best;
        } else {
            break;
        }
    }
    data[idx] = val;
}

static void heap_sift_down_keypath_max(pTHX_ Heap *h, IV idx) {
    SV **data = h->data;
    IV size = h->size;
    char **path = h->key_path;
    STRLEN *lens = h->key_lens;
    IV depth = h->key_depth;
    SV *val = data[idx];
    NV val_nv = heap_extract_key_nv(aTHX_ val, path, lens, depth);
    IV half = size >> 1;

    while (idx < half) {
        IV left = (idx << 1) + 1;
        IV right = left + 1;
        IV best = left;
        NV best_nv = heap_extract_key_nv(aTHX_ data[left], path, lens, depth);

        if (right < size) {
            NV right_nv = heap_extract_key_nv(aTHX_ data[right], path, lens, depth);
            if (right_nv > best_nv) {
                best = right;
                best_nv = right_nv;
            }
        }

        if (best_nv > val_nv) {
            data[idx] = data[best];
            idx = best;
        } else {
            break;
        }
    }
    data[idx] = val;
}

/* Custom comparator sift operations using MULTICALL for minimal per-call overhead */

/* Inline compare helper - must be called within a MULTICALL block.
   Uses SvIVX (no type check) since <=> and cmp always return an integer. */
#define HEAP_CMP_CUSTOM(h, sv_a, sv_b, result_var) \
    STMT_START { \
        GvSV((h)->gv_a) = (sv_a); \
        GvSV((h)->gv_b) = (sv_b); \
        MULTICALL; \
        (result_var) = SvIVX(*PL_stack_sp); \
    } STMT_END

static void heap_sift_up_custom(pTHX_ Heap *h, IV idx) {
    dSP;
    IV cmp_result;

    if (idx <= 0) return;

    {
        dMULTICALL;
        I32 gimme = G_SCALAR;
        CV *cv = (CV*)SvRV(h->comparator);

        assert(cv != NULL);
        PUSH_MULTICALL(cv);

        while (idx > 0) {
            IV parent = (idx - 1) >> 1;
            HEAP_CMP_CUSTOM(h, h->data[idx], h->data[parent], cmp_result);
            if (h->type == HEAP_MIN ? cmp_result < 0 : cmp_result > 0) {
                SV *tmp = h->data[idx];
                h->data[idx] = h->data[parent];
                h->data[parent] = tmp;
                idx = parent;
            } else {
                break;
            }
        }

        POP_MULTICALL;
    }
}

static void heap_sift_down_custom(pTHX_ Heap *h, IV idx) {
    dSP;
    IV cmp_result;

    if (h->size <= 1) return;

    {
        dMULTICALL;
        I32 gimme = G_SCALAR;
        CV *cv = (CV*)SvRV(h->comparator);

        assert(cv != NULL);
        PUSH_MULTICALL(cv);

        while (1) {
            IV left = (idx << 1) + 1;
            IV right = left + 1;
            IV best = idx;

            if (left < h->size) {
                HEAP_CMP_CUSTOM(h, h->data[left], h->data[best], cmp_result);
                if (h->type == HEAP_MIN ? cmp_result < 0 : cmp_result > 0) {
                    best = left;
                }
            }
            if (right < h->size) {
                HEAP_CMP_CUSTOM(h, h->data[right], h->data[best], cmp_result);
                if (h->type == HEAP_MIN ? cmp_result < 0 : cmp_result > 0) {
                    best = right;
                }
            }

            if (best != idx) {
                SV *tmp = h->data[idx];
                h->data[idx] = h->data[best];
                h->data[best] = tmp;
                idx = best;
            } else {
                break;
            }
        }

        POP_MULTICALL;
    }
}

static int heap_free(pTHX_ SV *sv, MAGIC *mg) {
    Heap *h = (Heap*)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);

    if (!PL_dirty) {
        IV i;
        for (i = 0; i < h->size; i++) {
            if (h->data[i]) SvREFCNT_dec(h->data[i]);
        }
        if (h->comparator) SvREFCNT_dec(h->comparator);
    }
    if (h->data) Safefree(h->data);
    if (h->priorities) Safefree(h->priorities);
    if (h->key_path) {
        IV i;
        for (i = 0; i < h->key_depth; i++) {
            Safefree(h->key_path[i]);
        }
        Safefree(h->key_path);
        Safefree(h->key_lens);
    }
    Safefree(h);
    return 0;
}

/* Function-style custom ops */

/* Dedicated NV heap custom ops - no find_heap, no SV allocation */
static OP* pp_nv_push(pTHX) {
    dSP;
    NV val = SvNV(TOPs);
    SV *heap_sv = TOPm1s;
    NumericHeap *nh = NV_HEAP_FAST(heap_sv);

    nv_ensure_capacity(nh, nh->size + 1);
    nh->data[nh->size] = val;
    nh->size++;
    if (nh->type == HEAP_MIN) {
        nv_sift_up_min(nh, nh->size - 1);
    } else {
        nv_sift_up_max(nh, nh->size - 1);
    }
    SP--;
    SETs(heap_sv);
    RETURN;
}

static OP* pp_nv_pop(pTHX) {
    dSP;
    dTARGET;
    NumericHeap *nh = NV_HEAP_FAST(TOPs);

    if (nh->size == 0) {
        SETs(&PL_sv_undef);
        RETURN;
    }
    NV result = nh->data[0];
    nh->size--;
    if (nh->size > 0) {
        nh->data[0] = nh->data[nh->size];
        if (nh->type == HEAP_MIN) {
            nv_sift_down_min(nh, 0);
        } else {
            nv_sift_down_max(nh, 0);
        }
    }
    SETn(result);
    RETURN;
}

static OP* pp_nv_peek(pTHX) {
    dSP;
    dTARGET;
    NumericHeap *nh = NV_HEAP_FAST(TOPs);

    if (nh->size == 0) {
        SETs(&PL_sv_undef);
        RETURN;
    }
    SETn(nh->data[0]);
    RETURN;
}

static OP* pp_nv_size(pTHX) {
    dSP;
    dTARGET;
    NumericHeap *nh = NV_HEAP_FAST(TOPs);
    SETi(nh->size);
    RETURN;
}

static OP* pp_nv_is_empty(pTHX) {
    dSP;
    NumericHeap *nh = NV_HEAP_FAST(TOPs);
    if (nh->size == 0) { SETs(&PL_sv_yes); }
    else { SETs(&PL_sv_no); }
    RETURN;
}

static OP* pp_nv_clear(pTHX) {
    dSP;
    NumericHeap *nh = NV_HEAP_FAST(TOPs);
    nh->size = 0;
    SETs(&PL_sv_undef);
    RETURN;
}

static OP* pp_nv_peek_n(pTHX) {
    dSP;
    IV n = SvIV(TOPs);
    NumericHeap *nh = NV_HEAP_FAST(TOPm1s);
    IV i;

    SP -= 2;

    if (n <= 0 || nh->size == 0) RETURN;
    if (n > nh->size) n = nh->size;

    {
        NV *saved;
        IV saved_size = nh->size;
        Newx(saved, saved_size, NV);
        Copy(nh->data, saved, saved_size, NV);

        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            NV val = nh->data[0];
            nh->size--;
            if (nh->size > 0) {
                nh->data[0] = nh->data[nh->size];
                if (nh->type == HEAP_MIN) nv_sift_down_min(nh, 0);
                else nv_sift_down_max(nh, 0);
            }
            PUSHs(sv_2mortal(newSVnv(val)));
        }

        Copy(saved, nh->data, saved_size, NV);
        nh->size = saved_size;
        Safefree(saved);
    }
    RETURN;
}

static OP* pp_heap_func_peek_n(pTHX) {
    dSP;
    IV n = SvIV(TOPs);
    SV *heap_sv = TOPm1s;
    HeapLookup lookup = find_heap(aTHX_ heap_sv);
    IV i;

    SP -= 2;

    if (lookup.type == MAGIC_NUMERIC) {
        NumericHeap *nh = lookup.ptr.nheap;
        if (n <= 0 || nh->size == 0) RETURN;
        if (n > nh->size) n = nh->size;

        {
            NV *saved;
            IV saved_size = nh->size;
            Newx(saved, saved_size, NV);
            Copy(nh->data, saved, saved_size, NV);

            EXTEND(SP, n);
            for (i = 0; i < n; i++) {
                NV val = nh->data[0];
                nh->size--;
                if (nh->size > 0) {
                    nh->data[0] = nh->data[nh->size];
                    if (nh->type == HEAP_MIN) nv_sift_down_min(nh, 0);
                    else nv_sift_down_max(nh, 0);
                }
                PUSHs(sv_2mortal(newSVnv(val)));
            }

            Copy(saved, nh->data, saved_size, NV);
            nh->size = saved_size;
            Safefree(saved);
        }
        RETURN;
    }

    if (lookup.type == MAGIC_HEAP) {
        Heap *h = lookup.ptr.heap;
        if (n <= 0 || h->size == 0) RETURN;
        if (n > h->size) n = h->size;

        {
            SV **saved_data;
            NV *saved_pri;
            IV saved_size = h->size;
            Newx(saved_data, saved_size, SV*);
            Newx(saved_pri, saved_size, NV);
            Copy(h->data, saved_data, saved_size, SV*);
            Copy(h->priorities, saved_pri, saved_size, NV);

            EXTEND(SP, n);
            for (i = 0; i < n; i++) {
                PUSHs(h->data[0]);
                h->size--;
                if (h->size > 0) {
                    h->data[0] = h->data[h->size];
                    h->priorities[0] = h->priorities[h->size];
                    h->sift_down(aTHX_ h, 0);
                }
            }

            Copy(saved_data, h->data, saved_size, SV*);
            Copy(saved_pri, h->priorities, saved_size, NV);
            h->size = saved_size;
            Safefree(saved_data);
            Safefree(saved_pri);
        }
        RETURN;
    }

    croak("Not a heap object");
    RETURN;
}

/* Dedicated NV search custom op */
static OP* pp_nv_search(pTHX) {
    dSP;
    SV *callback = TOPs;
    SV *heap_sv = TOPm1s;
    NumericHeap *nh = NV_HEAP_FAST(heap_sv);
    IV i, found = 0;
    NV *results;

    SP -= 2;
    PUTBACK;

    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("search requires a code reference");

    if (nh->size == 0) RETURN;

    Newx(results, nh->size, NV);

    for (i = 0; i < nh->size; i++) {
        dSP;
        SV *elem = sv_2mortal(newSVnv(nh->data[i]));
        IV result;
        int count;

        ENTER; SAVETMPS;
        SAVE_DEFSV;
        DEFSV_set(elem);

        PUSHMARK(SP);
        XPUSHs(elem);
        PUTBACK;

        count = call_sv(callback, G_SCALAR);
        SPAGAIN;
        result = count > 0 ? SvTRUE(TOPs) : 0;
        if (count > 0) POPs;
        PUTBACK;
        FREETMPS; LEAVE;

        if (result) {
            results[found++] = nh->data[i];
        }
    }

    SPAGAIN;
    EXTEND(SP, found);
    for (i = 0; i < found; i++) {
        PUSHs(sv_2mortal(newSVnv(results[i])));
    }
    Safefree(results);
    RETURN;
}

/* Dedicated NV delete custom op */
static OP* pp_nv_delete(pTHX) {
    dSP;
    SV *callback = TOPs;
    SV *heap_sv = TOPm1s;
    NumericHeap *nh = NV_HEAP_FAST(heap_sv);
    IV i, write_pos = 0, deleted = 0;
    dTARGET;

    SP -= 2;
    PUTBACK;

    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("delete requires a code reference");

    for (i = 0; i < nh->size; i++) {
        dSP;
        SV *elem = sv_2mortal(newSVnv(nh->data[i]));
        IV result;
        int count;

        ENTER; SAVETMPS;
        SAVE_DEFSV;
        DEFSV_set(elem);

        PUSHMARK(SP);
        XPUSHs(elem);
        PUTBACK;

        count = call_sv(callback, G_SCALAR);
        SPAGAIN;
        result = count > 0 ? SvTRUE(TOPs) : 0;
        if (count > 0) POPs;
        PUTBACK;
        FREETMPS; LEAVE;

        if (result) {
            deleted++;
        } else {
            if (write_pos != i) {
                nh->data[write_pos] = nh->data[i];
            }
            write_pos++;
        }
    }

    nh->size = write_pos;

    if (deleted > 0 && nh->size > 1) {
        IV j;
        for (j = (nh->size >> 1) - 1; j >= 0; j--) {
            if (nh->type == HEAP_MIN)
                nv_sift_down_min(nh, j);
            else
                nv_sift_down_max(nh, j);
        }
    }

    SPAGAIN;
    SETi(deleted);
    RETURN;
}

/* Generic search custom op - dispatches to both heap types */
static OP* pp_heap_func_search(pTHX) {
    dSP;
    SV *callback = TOPs;
    SV *heap_sv = TOPm1s;
    HeapLookup lookup = find_heap(aTHX_ heap_sv);
    IV i, found = 0;

    SP -= 2;
    PUTBACK;

    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("search requires a code reference");

    if (lookup.type == MAGIC_NUMERIC) {
        NumericHeap *nh = lookup.ptr.nheap;
        NV *results;

        if (nh->size == 0) RETURN;

        Newx(results, nh->size, NV);

        for (i = 0; i < nh->size; i++) {
            dSP;
            SV *elem = sv_2mortal(newSVnv(nh->data[i]));
            IV result;
            int count;

            ENTER; SAVETMPS;
            SAVE_DEFSV;
            DEFSV_set(elem);

            PUSHMARK(SP);
            XPUSHs(elem);
            PUTBACK;

            count = call_sv(callback, G_SCALAR);
            SPAGAIN;
            result = count > 0 ? SvTRUE(TOPs) : 0;
            if (count > 0) POPs;
            PUTBACK;
            FREETMPS; LEAVE;

            if (result) {
                results[found++] = nh->data[i];
            }
        }

        SPAGAIN;
        EXTEND(SP, found);
        for (i = 0; i < found; i++) {
            PUSHs(sv_2mortal(newSVnv(results[i])));
        }
        Safefree(results);
        RETURN;
    }

    if (lookup.type == MAGIC_HEAP) {
        Heap *h = lookup.ptr.heap;
        SV **results;

        if (h->size == 0) RETURN;

        Newx(results, h->size, SV*);

        for (i = 0; i < h->size; i++) {
            dSP;
            IV result;
            int count;

            ENTER; SAVETMPS;
            SAVE_DEFSV;
            DEFSV_set(h->data[i]);

            PUSHMARK(SP);
            XPUSHs(h->data[i]);
            PUTBACK;

            count = call_sv(callback, G_SCALAR);
            SPAGAIN;
            result = count > 0 ? SvTRUE(TOPs) : 0;
            if (count > 0) POPs;
            PUTBACK;
            FREETMPS; LEAVE;

            if (result) {
                results[found++] = h->data[i];
            }
        }

        SPAGAIN;
        EXTEND(SP, found);
        for (i = 0; i < found; i++) {
            PUSHs(results[i]);
        }
        Safefree(results);
        RETURN;
    }

    croak("Not a heap object");
    RETURN;
}

/* Generic delete custom op - dispatches to both heap types */
static OP* pp_heap_func_delete(pTHX) {
    dSP;
    SV *callback = TOPs;
    SV *heap_sv = TOPm1s;
    HeapLookup lookup = find_heap(aTHX_ heap_sv);
    IV i, write_pos = 0, deleted = 0;
    dTARGET;

    SP -= 2;
    PUTBACK;

    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("delete requires a code reference");

    if (lookup.type == MAGIC_NUMERIC) {
        NumericHeap *nh = lookup.ptr.nheap;

        for (i = 0; i < nh->size; i++) {
            dSP;
            SV *elem = sv_2mortal(newSVnv(nh->data[i]));
            IV result;
            int count;

            ENTER; SAVETMPS;
            SAVE_DEFSV;
            DEFSV_set(elem);

            PUSHMARK(SP);
            XPUSHs(elem);
            PUTBACK;

            count = call_sv(callback, G_SCALAR);
            SPAGAIN;
            result = count > 0 ? SvTRUE(TOPs) : 0;
            if (count > 0) POPs;
            PUTBACK;
            FREETMPS; LEAVE;

            if (result) {
                deleted++;
            } else {
                if (write_pos != i) {
                    nh->data[write_pos] = nh->data[i];
                }
                write_pos++;
            }
        }

        nh->size = write_pos;

        if (deleted > 0 && nh->size > 1) {
            IV j;
            for (j = (nh->size >> 1) - 1; j >= 0; j--) {
                if (nh->type == HEAP_MIN)
                    nv_sift_down_min(nh, j);
                else
                    nv_sift_down_max(nh, j);
            }
        }

        SPAGAIN;
        PUSHi(deleted);
        RETURN;
    }

    if (lookup.type == MAGIC_HEAP) {
        Heap *h = lookup.ptr.heap;

        for (i = 0; i < h->size; i++) {
            dSP;
            IV result;
            int count;

            ENTER; SAVETMPS;
            SAVE_DEFSV;
            DEFSV_set(h->data[i]);

            PUSHMARK(SP);
            XPUSHs(h->data[i]);
            PUTBACK;

            count = call_sv(callback, G_SCALAR);
            SPAGAIN;
            result = count > 0 ? SvTRUE(TOPs) : 0;
            if (count > 0) POPs;
            PUTBACK;
            FREETMPS; LEAVE;

            if (result) {
                SvREFCNT_dec(h->data[i]);
                deleted++;
            } else {
                if (write_pos != i) {
                    h->data[write_pos] = h->data[i];
                    h->priorities[write_pos] = h->priorities[i];
                }
                write_pos++;
            }
        }

        h->size = write_pos;

        if (deleted > 0 && h->size > 1) {
            IV j;
            for (j = (h->size >> 1) - 1; j >= 0; j--) {
                h->sift_down(aTHX_ h, j);
            }
        }

        SPAGAIN;
        PUSHi(deleted);
        RETURN;
    }

    croak("Not a heap object");
    RETURN;
}

static OP* pp_heap_func_push(pTHX) {
    dSP;
    SV *val_sv = TOPs;
    SV *heap_sv = TOPm1s;
    HeapLookup lookup = find_heap(aTHX_ heap_sv);

    if (lookup.type == MAGIC_NUMERIC) {
        NumericHeap *nh = lookup.ptr.nheap;
        NV val = SvNV(val_sv);
        nv_ensure_capacity(nh, nh->size + 1);
        nh->data[nh->size] = val;
        nh->size++;
        if (nh->type == HEAP_MIN) {
            nv_sift_up_min(nh, nh->size - 1);
        } else {
            nv_sift_up_max(nh, nh->size - 1);
        }
        SP--;
        SETs(heap_sv);
        RETURN;
    }

    if (lookup.type == MAGIC_HEAP) {
        Heap *h = lookup.ptr.heap;
        SV *value;

        heap_ensure_capacity(h, h->size + 1);
        if (h->comparator) {
            value = newSVsv(val_sv);
            h->data[h->size] = value;
        } else if (h->key_path) {
            value = newSVsv(val_sv);
            h->data[h->size] = value;
            h->priorities[h->size] = heap_extract_key_nv(aTHX_ value, h->key_path, h->key_lens, h->key_depth);
        } else {
            NV prio = SvNV(val_sv);
            value = newSVsv(val_sv);
            h->data[h->size] = value;
            h->priorities[h->size] = prio;
        }
        h->size++;
        h->sift_up(aTHX_ h, h->size - 1);

        SP--;
        SETs(heap_sv);
        RETURN;
    }

    croak("Not a heap object");
    RETURN;
}

static OP* pp_heap_func_pop(pTHX) {
    dSP;
    SV *heap_sv = TOPs;
    HeapLookup lookup = find_heap(aTHX_ heap_sv);

    if (lookup.type == MAGIC_NUMERIC) {
        NumericHeap *nh = lookup.ptr.nheap;
        if (nh->size == 0) {
            SETs(&PL_sv_undef);
            RETURN;
        }
        NV result = nh->data[0];
        nh->size--;
        if (nh->size > 0) {
            nh->data[0] = nh->data[nh->size];
            if (nh->type == HEAP_MIN) {
                nv_sift_down_min(nh, 0);
            } else {
                nv_sift_down_max(nh, 0);
            }
        }
        SETs(sv_2mortal(newSVnv(result)));
        RETURN;
    }

    if (lookup.type == MAGIC_HEAP) {
        Heap *h = lookup.ptr.heap;
        if (h->size == 0) {
            SETs(&PL_sv_undef);
            RETURN;
        }
        SV *result = sv_2mortal(h->data[0]);
        h->size--;
        if (h->size > 0) {
            h->data[0] = h->data[h->size];
            h->priorities[0] = h->priorities[h->size];
            h->sift_down(aTHX_ h, 0);
        }
        SETs(result);
        RETURN;
    }

    croak("Not a heap object");
    RETURN;
}

static OP* pp_heap_func_peek(pTHX) {
    dSP;
    SV *heap_sv = TOPs;
    HeapLookup lookup = find_heap(aTHX_ heap_sv);

    if (lookup.type == MAGIC_NUMERIC) {
        NumericHeap *nh = lookup.ptr.nheap;
        SETs(nh->size > 0 ? sv_2mortal(newSVnv(nh->data[0])) : &PL_sv_undef);
        RETURN;
    }

    if (lookup.type == MAGIC_HEAP) {
        Heap *h = lookup.ptr.heap;
        SETs(h->size > 0 ? h->data[0] : &PL_sv_undef);
        RETURN;
    }

    croak("Not a heap object");
    RETURN;
}

static OP* pp_heap_func_size(pTHX) {
    dSP;
    SV *heap_sv = TOPs;
    HeapLookup lookup = find_heap(aTHX_ heap_sv);

    if (lookup.type == MAGIC_NUMERIC) {
        SETs(sv_2mortal(newSViv(lookup.ptr.nheap->size)));
        RETURN;
    }

    if (lookup.type == MAGIC_HEAP) {
        SETs(sv_2mortal(newSViv(lookup.ptr.heap->size)));
        RETURN;
    }

    croak("Not a heap object");
    RETURN;
}

static OP* pp_heap_func_is_empty(pTHX) {
    dSP;
    SV *heap_sv = TOPs;
    HeapLookup lookup = find_heap(aTHX_ heap_sv);

    if (lookup.type == MAGIC_NUMERIC) {
        if (lookup.ptr.nheap->size == 0) { SETs(&PL_sv_yes); }
        else { SETs(&PL_sv_no); }
        RETURN;
    }

    if (lookup.type == MAGIC_HEAP) {
        if (lookup.ptr.heap->size == 0) { SETs(&PL_sv_yes); }
        else { SETs(&PL_sv_no); }
        RETURN;
    }

    croak("Not a heap object");
    RETURN;
}

static OP* pp_heap_func_clear(pTHX) {
    dSP;
    SV *heap_sv = TOPs;
    HeapLookup lookup = find_heap(aTHX_ heap_sv);

    if (lookup.type == MAGIC_NUMERIC) {
        lookup.ptr.nheap->size = 0;
        SETs(&PL_sv_undef);
        RETURN;
    }

    if (lookup.type == MAGIC_HEAP) {
        Heap *h = lookup.ptr.heap;
        IV i;
        for (i = 0; i < h->size; i++) {
            if (h->data[i]) SvREFCNT_dec(h->data[i]);
        }
        h->size = 0;
        SETs(&PL_sv_undef);
        RETURN;
    }

    croak("Not a heap object");
    RETURN;
}

static OP* pp_heap_func_type(pTHX) {
    dSP;
    SV *heap_sv = TOPs;
    HeapLookup lookup = find_heap(aTHX_ heap_sv);

    if (lookup.type == MAGIC_NUMERIC) {
        if (lookup.ptr.nheap->type == HEAP_MIN)
            SETs(sv_2mortal(newSVpvn("min", 3)));
        else
            SETs(sv_2mortal(newSVpvn("max", 3)));
        RETURN;
    }

    if (lookup.type == MAGIC_HEAP) {
        if (lookup.ptr.heap->type == HEAP_MIN)
            SETs(sv_2mortal(newSVpvn("min", 3)));
        else
            SETs(sv_2mortal(newSVpvn("max", 3)));
        RETURN;
    }

    croak("Not a heap object");
    RETURN;
}

/* Call checkers for function-style calls (Heap::PQ::push($h,$v) and imported heap_push($h,$v)) */
typedef OP* (*heap_ppfunc)(pTHX);

static OP* heap_call_checker_1arg(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    heap_ppfunc ppfunc = (heap_ppfunc)SvIVX(ckobj);
    OP *pushop, *cvop, *heapop;
    OP *newop;

    PERL_UNUSED_ARG(namegv);

    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) pushop = cUNOPx(pushop)->op_first;

    heapop = OpSIBLING(pushop);
    if (!heapop) return entersubop;

    cvop = OpSIBLING(heapop);
    if (!cvop) return entersubop;
    if (OpSIBLING(heapop) != cvop) return entersubop;

    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(heapop, NULL);

    newop = newUNOP(OP_NULL, 0, heapop);
    newop->op_type   = OP_CUSTOM;
    newop->op_ppaddr = ppfunc;
    newop->op_targ = pad_alloc(OP_CUSTOM, SVs_PADTMP);

    op_free(entersubop);
    return newop;
}

static OP* heap_call_checker_2arg(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    heap_ppfunc ppfunc = (heap_ppfunc)SvIVX(ckobj);
    OP *pushop, *cvop, *heapop, *valop;
    OP *newop;

    PERL_UNUSED_ARG(namegv);

    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) pushop = cUNOPx(pushop)->op_first;

    heapop = OpSIBLING(pushop);
    if (!heapop) return entersubop;

    valop = OpSIBLING(heapop);
    if (!valop) return entersubop;

    cvop = OpSIBLING(valop);
    if (!cvop) return entersubop;
    if (OpSIBLING(valop) != cvop) return entersubop;

    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(valop, NULL);
    OpLASTSIB_set(heapop, NULL);

    newop = newBINOP(OP_NULL, 0, heapop, valop);
    newop->op_type   = OP_CUSTOM;
    newop->op_ppaddr = ppfunc;
    newop->op_targ = pad_alloc(OP_CUSTOM, SVs_PADTMP);

    op_free(entersubop);
    return newop;
}

/* XS Functions */
XS_EXTERNAL(XS_heap_new) {
    dXSARGS;
    Heap *h;
    SV *obj_sv, *rv;
    HV *stash;
    HeapType type = HEAP_MIN;
    SV *comparator = NULL;
    char *key_path_str = NULL;
    int arg_offset = 0;

    if (items >= 1 && SvPOK(ST(0))) {
        STRLEN len;
        const char *str = SvPV(ST(0), len);
        if (len == 8 && strEQ(str, "Heap::PQ")) {
            arg_offset = 1;
        } else if (len == 3 && (strEQ(str, "min") || strEQ(str, "max"))) {
            arg_offset = 0;
        } else {
            arg_offset = 1;
        }
    }

    if (items > arg_offset) {
        STRLEN len;
        const char *type_str = SvPV(ST(arg_offset), len);
        if (len == 3 && strEQ(type_str, "max")) {
            type = HEAP_MAX;
        } else if (len == 3 && strEQ(type_str, "min")) {
            type = HEAP_MIN;
        } else {
            croak("heap type must be 'min' or 'max'");
        }
    }

    if (items > arg_offset + 1) {
        SV *cmp_arg = ST(arg_offset + 1);
        if (SvROK(cmp_arg) && SvTYPE(SvRV(cmp_arg)) == SVt_PVCV) {
            comparator = newSVsv(cmp_arg);
        } else if (SvPOK(cmp_arg)) {
            /* String key path — parse "key.subkey.subsubkey" into segments */
            const char *raw = SvPV_nolen(cmp_arg);
            key_path_str = savepv(raw);
        } else if (SvOK(cmp_arg)) {
            croak("Comparator must be a code reference or a key path string");
        }
    }

    Newxz(h, 1, Heap);
    h->type = type;
    h->size = 0;
    h->capacity = 16;
    Newx(h->data, 16, SV*);
    Newx(h->priorities, 16, NV);
    h->comparator = comparator;
    h->gv_a = NULL;
    h->gv_b = NULL;
    h->key_path = NULL;
    h->key_lens = NULL;
    h->key_depth = 0;

    if (key_path_str) {
        /* Parse "key.subkey.deep" into segments */
        char *p, *seg;
        IV depth = 0, cap = 4;
        Newx(h->key_path, cap, char*);
        Newx(h->key_lens, cap, STRLEN);

        p = key_path_str;
        while (*p) {
            seg = p;
            while (*p && *p != '.') p++;
            if (depth >= cap) {
                cap *= 2;
                Renew(h->key_path, cap, char*);
                Renew(h->key_lens, cap, STRLEN);
            }
            h->key_lens[depth] = p - seg;
            h->key_path[depth] = savepvn(seg, p - seg);
            depth++;
            if (*p == '.') p++;
        }
        Safefree(key_path_str);
        h->key_depth = depth;

        if (type == HEAP_MIN) {
            h->sift_up = heap_sift_up_min;
            h->sift_down = heap_sift_down_min;
        } else {
            h->sift_up = heap_sift_up_max;
            h->sift_down = heap_sift_down_max;
        }
    } else if (comparator) {
        const char *pkg = CopSTASHPV(PL_curcop);
        if (!pkg) pkg = "main";
        h->gv_a = gv_fetchpv(Perl_form(aTHX_ "%s::a", pkg), GV_ADD, SVt_PV);
        h->gv_b = gv_fetchpv(Perl_form(aTHX_ "%s::b", pkg), GV_ADD, SVt_PV);
        GvMULTI_on(h->gv_a);
        GvMULTI_on(h->gv_b);
        h->sift_up = heap_sift_up_custom;
        h->sift_down = heap_sift_down_custom;
    } else if (type == HEAP_MIN) {
        h->sift_up = heap_sift_up_min;
        h->sift_down = heap_sift_down_min;
    } else {
        h->sift_up = heap_sift_up_max;
        h->sift_down = heap_sift_down_max;
    }

    obj_sv = newSV(0);
    sv_magicext(obj_sv, NULL, PERL_MAGIC_ext, &heap_vtbl, (char*)h, 0);

    rv = newRV_noinc(obj_sv);
    stash = gv_stashpvn("Heap::PQ", 8, GV_ADD);
    sv_bless(rv, stash);

    ST(0) = sv_2mortal(rv);
    XSRETURN(1);
}

XS_EXTERNAL(XS_heap_push) {
    dXSARGS;
    HeapLookup hl;

    if (items != 2) croak("Usage: $heap->push($value)");

    hl = find_heap(aTHX_ ST(0));

    if (hl.type == MAGIC_NUMERIC) {
        NumericHeap *nh = hl.ptr.nheap;
        NV val = SvNV(ST(1));
        nv_ensure_capacity(nh, nh->size + 1);
        nh->data[nh->size] = val;
        nh->size++;
        if (nh->type == HEAP_MIN)
            nv_sift_up_min(nh, nh->size - 1);
        else
            nv_sift_up_max(nh, nh->size - 1);
        ST(0) = ST(0);
        XSRETURN(1);
    }

    {
        Heap *h = hl.ptr.heap;
        SV *val_sv = ST(1);
        SV *value;

        heap_ensure_capacity(h, h->size + 1);
        if (h->comparator) {
            value = newSVsv(val_sv);
            h->data[h->size] = value;
        } else if (h->key_path) {
            value = newSVsv(val_sv);
            h->data[h->size] = value;
            h->priorities[h->size] = heap_extract_key_nv(aTHX_ value, h->key_path, h->key_lens, h->key_depth);
        } else {
            NV prio = SvNV(val_sv);
            value = newSVsv(val_sv);
            h->data[h->size] = value;
            h->priorities[h->size] = prio;
        }
        h->size++;
        h->sift_up(aTHX_ h, h->size - 1);

        ST(0) = ST(0);
        XSRETURN(1);
    }
}

XS_EXTERNAL(XS_heap_push_all) {
    dXSARGS;
    Heap *h;
    int i;
    IV start_size;

    if (items < 1) croak("Usage: $heap->push_all(@values)");

    h = get_heap(aTHX_ ST(0));
    start_size = h->size;

    heap_ensure_capacity(h, h->size + items - 1);

    /* Add all values first */
    for (i = 1; i < items; i++) {
        SV *val = newSVsv(ST(i));
        h->data[h->size] = val;
        if (h->key_path) {
            h->priorities[h->size] = heap_extract_key_nv(aTHX_ val, h->key_path, h->key_lens, h->key_depth);
        } else if (!h->comparator) {
            h->priorities[h->size] = SvNV(ST(i));
        }
        h->size++;
    }

    /* Floyd's heapify if adding many elements */
    if (items - 1 > 10) {
        IV j;
        for (j = (h->size >> 1) - 1; j >= 0; j--) {
            h->sift_down(aTHX_ h, j);
        }
    } else {
        for (i = start_size; i < h->size; i++) {
            h->sift_up(aTHX_ h, i);
        }
    }

    ST(0) = ST(0);
    XSRETURN(1);
}

XS_EXTERNAL(XS_heap_pop) {
    dXSARGS;
    HeapLookup hl;

    if (items != 1) croak("Usage: $heap->pop()");

    hl = find_heap(aTHX_ ST(0));

    if (hl.type == MAGIC_NUMERIC) {
        NumericHeap *nh = hl.ptr.nheap;
        NV result;
        if (nh->size == 0) XSRETURN_UNDEF;
        result = nh->data[0];
        nh->size--;
        if (nh->size > 0) {
            nh->data[0] = nh->data[nh->size];
            if (nh->type == HEAP_MIN)
                nv_sift_down_min(nh, 0);
            else
                nv_sift_down_max(nh, 0);
        }
        ST(0) = sv_2mortal(newSVnv(result));
        XSRETURN(1);
    }

    {
        Heap *h = hl.ptr.heap;
        SV *result;

        if (h->size == 0) XSRETURN_UNDEF;

        result = sv_2mortal(h->data[0]);

        h->size--;
        if (h->size > 0) {
            h->data[0] = h->data[h->size];
            h->priorities[0] = h->priorities[h->size];
            h->sift_down(aTHX_ h, 0);
        }

        ST(0) = result;
        XSRETURN(1);
    }
}

XS_EXTERNAL(XS_heap_peek) {
    dXSARGS;
    HeapLookup hl;

    if (items != 1) croak("Usage: $heap->peek()");

    hl = find_heap(aTHX_ ST(0));

    if (hl.type == MAGIC_NUMERIC) {
        NumericHeap *nh = hl.ptr.nheap;
        if (nh->size == 0) XSRETURN_UNDEF;
        ST(0) = sv_2mortal(newSVnv(nh->data[0]));
        XSRETURN(1);
    }

    {
        Heap *h = hl.ptr.heap;
        if (h->size == 0) XSRETURN_UNDEF;
        ST(0) = h->data[0];
        XSRETURN(1);
    }
}

XS_EXTERNAL(XS_heap_size) {
    dXSARGS;
    HeapLookup hl;

    if (items != 1) croak("Usage: $heap->size()");

    hl = find_heap(aTHX_ ST(0));

    if (hl.type == MAGIC_NUMERIC)
        XSRETURN_IV(hl.ptr.nheap->size);

    XSRETURN_IV(hl.ptr.heap->size);
}

XS_EXTERNAL(XS_heap_is_empty) {
    dXSARGS;
    HeapLookup lookup;

    if (items != 1) croak("Usage: $heap->is_empty()");

    lookup = find_heap(aTHX_ ST(0));

    if (lookup.type == MAGIC_NUMERIC) {
        if (lookup.ptr.nheap->size == 0) XSRETURN_YES;
        XSRETURN_NO;
    }
    if (lookup.type == MAGIC_HEAP) {
        if (lookup.ptr.heap->size == 0) XSRETURN_YES;
        XSRETURN_NO;
    }
    croak("Not a heap object");
}

XS_EXTERNAL(XS_heap_clear) {
    dXSARGS;
    HeapLookup lookup;

    if (items != 1) croak("Usage: $heap->clear()");

    lookup = find_heap(aTHX_ ST(0));

    if (lookup.type == MAGIC_NUMERIC) {
        lookup.ptr.nheap->size = 0;
        XSRETURN_EMPTY;
    }
    if (lookup.type == MAGIC_HEAP) {
        Heap *h = lookup.ptr.heap;
        IV i;
        for (i = 0; i < h->size; i++) {
            if (h->data[i]) SvREFCNT_dec(h->data[i]);
        }
        h->size = 0;
        XSRETURN_EMPTY;
    }
    croak("Not a heap object");
}

XS_EXTERNAL(XS_heap_type) {
    dXSARGS;
    HeapLookup lookup;
    HeapType type;

    if (items != 1) croak("Usage: $heap->type()");

    lookup = find_heap(aTHX_ ST(0));

    if (lookup.type == MAGIC_NUMERIC) {
        type = lookup.ptr.nheap->type;
    } else if (lookup.type == MAGIC_HEAP) {
        type = lookup.ptr.heap->type;
    } else {
        croak("Not a heap object");
    }

    if (type == HEAP_MIN) {
        ST(0) = sv_2mortal(newSVpvn("min", 3));
    } else {
        ST(0) = sv_2mortal(newSVpvn("max", 3));
    }
    XSRETURN(1);
}

/* $heap->peek_n($n) - return top N elements in sorted order without removing */
XS_EXTERNAL(XS_heap_peek_n) {
    dXSARGS;
    HeapLookup hl;
    IV n, i, count;

    if (items != 2) croak("Usage: $heap->peek_n($n)");

    hl = find_heap(aTHX_ ST(0));
    n = SvIV(ST(1));

    if (hl.type == MAGIC_NUMERIC) {
        NumericHeap *nh = hl.ptr.nheap;
        NV *saved;
        IV saved_size;

        if (n <= 0 || nh->size == 0) XSRETURN_EMPTY;
        if (n > nh->size) n = nh->size;

        Newx(saved, nh->size, NV);
        Copy(nh->data, saved, nh->size, NV);
        saved_size = nh->size;

        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            NV val = nh->data[0];
            nh->size--;
            if (nh->size > 0) {
                nh->data[0] = nh->data[nh->size];
                if (nh->type == HEAP_MIN)
                    nv_sift_down_min(nh, 0);
                else
                    nv_sift_down_max(nh, 0);
            }
            ST(i) = sv_2mortal(newSVnv(val));
        }
        count = n;

        Copy(saved, nh->data, saved_size, NV);
        nh->size = saved_size;
        Safefree(saved);
        XSRETURN(count);
    }

    {
        Heap *h = hl.ptr.heap;
        SV **saved_data;
        NV *saved_pri;
        IV saved_size;

        if (n <= 0 || h->size == 0) XSRETURN_EMPTY;
        if (n > h->size) n = h->size;

        Newx(saved_data, h->size, SV*);
        Newx(saved_pri, h->size, NV);
        Copy(h->data, saved_data, h->size, SV*);
        Copy(h->priorities, saved_pri, h->size, NV);
        saved_size = h->size;

        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            ST(i) = h->data[0];
            h->size--;
            if (h->size > 0) {
                h->data[0] = h->data[h->size];
                h->priorities[0] = h->priorities[h->size];
                h->sift_down(aTHX_ h, 0);
            }
        }
        count = n;

        Copy(saved_data, h->data, saved_size, SV*);
        Copy(saved_pri, h->priorities, saved_size, NV);
        h->size = saved_size;
        Safefree(saved_data);
        Safefree(saved_pri);
        XSRETURN(count);
    }
}

/* $heap->search(sub { ... }) - find elements matching condition */
XS_EXTERNAL(XS_heap_search) {
    dXSARGS;
    HeapLookup hl;
    IV i, found = 0;
    SV *callback;

    if (items != 2) croak("Usage: $heap->search(sub { ... })");

    hl = find_heap(aTHX_ ST(0));
    callback = ST(1);

    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("search requires a code reference");

    if (hl.type == MAGIC_NUMERIC) {
        NumericHeap *nh = hl.ptr.nheap;
        NV *results;

        if (nh->size == 0) XSRETURN_EMPTY;

        Newx(results, nh->size, NV);

        for (i = 0; i < nh->size; i++) {
            dSP;
            SV *elem = sv_2mortal(newSVnv(nh->data[i]));
            IV result;
            int count;

            ENTER; SAVETMPS;
            SAVE_DEFSV;
            DEFSV_set(elem);

            PUSHMARK(SP);
            XPUSHs(elem);
            PUTBACK;

            count = call_sv(callback, G_SCALAR);
            SPAGAIN;
            result = count > 0 ? SvTRUE(TOPs) : 0;
            if (count > 0) POPs;
            PUTBACK;
            FREETMPS; LEAVE;

            if (result) {
                results[found++] = nh->data[i];
            }
        }

        EXTEND(SP, found);
        for (i = 0; i < found; i++) {
            ST(i) = sv_2mortal(newSVnv(results[i]));
        }
        Safefree(results);
        XSRETURN(found);
    }

    {
        Heap *h = hl.ptr.heap;
        SV **results;

        if (h->size == 0) XSRETURN_EMPTY;

        Newx(results, h->size, SV*);

        for (i = 0; i < h->size; i++) {
            dSP;
            IV result;
            int count;

            ENTER; SAVETMPS;
            SAVE_DEFSV;
            DEFSV_set(h->data[i]);

            PUSHMARK(SP);
            XPUSHs(h->data[i]);
            PUTBACK;

            count = call_sv(callback, G_SCALAR);
            SPAGAIN;
            result = count > 0 ? SvTRUE(TOPs) : 0;
            if (count > 0) POPs;
            PUTBACK;
            FREETMPS; LEAVE;

            if (result) {
                results[found++] = h->data[i];
            }
        }

        EXTEND(SP, found);
        for (i = 0; i < found; i++) {
            ST(i) = results[i];
        }
        Safefree(results);
        XSRETURN(found);
    }
}

/* $heap->delete(sub { ... }) - remove matching elements, returns count */
XS_EXTERNAL(XS_heap_delete) {
    dXSARGS;
    HeapLookup hl;
    IV i, write_pos = 0, deleted = 0;
    SV *callback;

    if (items != 2) croak("Usage: $heap->delete(sub { ... })");

    hl = find_heap(aTHX_ ST(0));
    callback = ST(1);

    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("delete requires a code reference");

    if (hl.type == MAGIC_NUMERIC) {
        NumericHeap *nh = hl.ptr.nheap;

        for (i = 0; i < nh->size; i++) {
            dSP;
            SV *elem = sv_2mortal(newSVnv(nh->data[i]));
            IV result;
            int count;

            ENTER; SAVETMPS;
            SAVE_DEFSV;
            DEFSV_set(elem);

            PUSHMARK(SP);
            XPUSHs(elem);
            PUTBACK;

            count = call_sv(callback, G_SCALAR);
            SPAGAIN;
            result = count > 0 ? SvTRUE(TOPs) : 0;
            if (count > 0) POPs;
            PUTBACK;
            FREETMPS; LEAVE;

            if (result) {
                deleted++;
            } else {
                if (write_pos != i) {
                    nh->data[write_pos] = nh->data[i];
                }
                write_pos++;
            }
        }

        nh->size = write_pos;

        if (deleted > 0 && nh->size > 1) {
            IV j;
            for (j = (nh->size >> 1) - 1; j >= 0; j--) {
                if (nh->type == HEAP_MIN)
                    nv_sift_down_min(nh, j);
                else
                    nv_sift_down_max(nh, j);
            }
        }

        XSRETURN_IV(deleted);
    }

    {
        Heap *h = hl.ptr.heap;

        for (i = 0; i < h->size; i++) {
            dSP;
            IV result;
            int count;

            ENTER; SAVETMPS;
            SAVE_DEFSV;
            DEFSV_set(h->data[i]);

            PUSHMARK(SP);
            XPUSHs(h->data[i]);
            PUTBACK;

            count = call_sv(callback, G_SCALAR);
            SPAGAIN;
            result = count > 0 ? SvTRUE(TOPs) : 0;
            if (count > 0) POPs;
            PUTBACK;
            FREETMPS; LEAVE;

            if (result) {
                SvREFCNT_dec(h->data[i]);
                deleted++;
            } else {
                if (write_pos != i) {
                    h->data[write_pos] = h->data[i];
                    h->priorities[write_pos] = h->priorities[i];
                }
                write_pos++;
            }
        }

        h->size = write_pos;

        if (deleted > 0 && h->size > 1) {
            IV j;
            for (j = (h->size >> 1) - 1; j >= 0; j--) {
                h->sift_down(aTHX_ h, j);
            }
        }

        XSRETURN_IV(deleted);
    }
}

/* Import functions */
static void install_heap_func_1arg(pTHX_ const char *pkg, const char *name,
                                    XSUBADDR_t xsub, heap_ppfunc ppfunc) {
    char full_name[256];
    CV *cv;
    SV *ckobj;

    snprintf(full_name, sizeof(full_name), "%s::%s", pkg, name);
    cv = newXS(full_name, xsub, __FILE__);
    ckobj = newSViv(PTR2IV(ppfunc));
    cv_set_call_checker(cv, heap_call_checker_1arg, ckobj);
}

static void install_heap_func_2arg(pTHX_ const char *pkg, const char *name,
                                    XSUBADDR_t xsub, heap_ppfunc ppfunc) {
    char full_name[256];
    CV *cv;
    SV *ckobj;

    snprintf(full_name, sizeof(full_name), "%s::%s", pkg, name);
    cv = newXS(full_name, xsub, __FILE__);
    ckobj = newSViv(PTR2IV(ppfunc));
    cv_set_call_checker(cv, heap_call_checker_2arg, ckobj);
}

XS_EXTERNAL(XS_heap_import) {
    dXSARGS;
    const char *pkg;
    int i;
    bool want_import = FALSE;
    bool want_raw = FALSE;

    pkg = CopSTASHPV(PL_curcop);

    for (i = 1; i < items; i++) {
        STRLEN len;
        const char *arg = SvPV(ST(i), len);
        if (len == 6 && strEQ(arg, "import")) {
            want_import = TRUE;
        } else if (len == 3 && strEQ(arg, "raw")) {
            want_raw = TRUE;
        }
    }

    if (want_import) {
        install_heap_func_2arg(aTHX_ pkg, "heap_push", XS_heap_push, pp_heap_func_push);
        install_heap_func_1arg(aTHX_ pkg, "heap_pop", XS_heap_pop, pp_heap_func_pop);
        install_heap_func_1arg(aTHX_ pkg, "heap_peek", XS_heap_peek, pp_heap_func_peek);
        install_heap_func_1arg(aTHX_ pkg, "heap_size", XS_heap_size, pp_heap_func_size);
        install_heap_func_2arg(aTHX_ pkg, "heap_peek_n", XS_heap_peek_n, pp_heap_func_peek_n);
        install_heap_func_2arg(aTHX_ pkg, "heap_search", XS_heap_search, pp_heap_func_search);
        install_heap_func_2arg(aTHX_ pkg, "heap_delete", XS_heap_delete, pp_heap_func_delete);
        install_heap_func_1arg(aTHX_ pkg, "heap_is_empty", XS_heap_is_empty, pp_heap_func_is_empty);
        install_heap_func_1arg(aTHX_ pkg, "heap_clear", XS_heap_clear, pp_heap_func_clear);
        install_heap_func_1arg(aTHX_ pkg, "heap_type", XS_heap_type, pp_heap_func_type);
    }

    if (want_raw) {
        /* Install raw array functions with custom ops */
        install_heap_func_2arg(aTHX_ pkg, "push_heap_min", XS_push_heap_min, pp_push_heap_min);
        install_heap_func_1arg(aTHX_ pkg, "pop_heap_min", XS_pop_heap_min, pp_pop_heap_min);
        install_heap_func_2arg(aTHX_ pkg, "push_heap_max", XS_push_heap_max, pp_push_heap_max);
        install_heap_func_1arg(aTHX_ pkg, "pop_heap_max", XS_pop_heap_max, pp_pop_heap_max);
        install_heap_func_1arg(aTHX_ pkg, "make_heap_min", XS_make_heap_min, pp_make_heap_min);
        install_heap_func_1arg(aTHX_ pkg, "make_heap_max", XS_make_heap_max, pp_make_heap_max);
    }

    /* Mark $a and $b as multi-use in the caller's package to suppress
       "used only once" warnings when they appear in comparator subs */
    {
        GV *gv_a = gv_fetchpv(Perl_form(aTHX_ "%s::a", pkg), GV_ADD, SVt_PV);
        GV *gv_b = gv_fetchpv(Perl_form(aTHX_ "%s::b", pkg), GV_ADD, SVt_PV);
        GvMULTI_on(gv_a);
        GvMULTI_on(gv_b);
    }

    XSRETURN_EMPTY;
}

/* ============================================
   Boot function
   ============================================ */

XS_EXTERNAL(boot_Heap__PQ) {
    dXSBOOTARGSXSAPIVERCHK;
    PERL_UNUSED_VAR(items);

    /* Register custom ops */
    XopENTRY_set(&heap_func_push_xop, xop_name, "heap_func_push");
    XopENTRY_set(&heap_func_push_xop, xop_desc, "heap function push");
    Perl_custom_op_register(aTHX_ pp_heap_func_push, &heap_func_push_xop);

    XopENTRY_set(&heap_func_pop_xop, xop_name, "heap_func_pop");
    XopENTRY_set(&heap_func_pop_xop, xop_desc, "heap function pop");
    Perl_custom_op_register(aTHX_ pp_heap_func_pop, &heap_func_pop_xop);

    XopENTRY_set(&heap_func_peek_xop, xop_name, "heap_func_peek");
    XopENTRY_set(&heap_func_peek_xop, xop_desc, "heap function peek");
    Perl_custom_op_register(aTHX_ pp_heap_func_peek, &heap_func_peek_xop);

    XopENTRY_set(&heap_func_size_xop, xop_name, "heap_func_size");
    XopENTRY_set(&heap_func_size_xop, xop_desc, "heap function size");
    Perl_custom_op_register(aTHX_ pp_heap_func_size, &heap_func_size_xop);

    /* Dedicated NV heap custom ops */
    XopENTRY_set(&nv_push_xop, xop_name, "nv_push");
    XopENTRY_set(&nv_push_xop, xop_desc, "nv heap push");
    Perl_custom_op_register(aTHX_ pp_nv_push, &nv_push_xop);

    /* Raw array custom ops */
    XopENTRY_set(&push_heap_min_xop, xop_name, "push_heap_min");
    XopENTRY_set(&push_heap_min_xop, xop_desc, "raw array push min");
    Perl_custom_op_register(aTHX_ pp_push_heap_min, &push_heap_min_xop);

    XopENTRY_set(&push_heap_max_xop, xop_name, "push_heap_max");
    XopENTRY_set(&push_heap_max_xop, xop_desc, "raw array push max");
    Perl_custom_op_register(aTHX_ pp_push_heap_max, &push_heap_max_xop);

    XopENTRY_set(&pop_heap_min_xop, xop_name, "pop_heap_min");
    XopENTRY_set(&pop_heap_min_xop, xop_desc, "raw array pop min");
    Perl_custom_op_register(aTHX_ pp_pop_heap_min, &pop_heap_min_xop);

    XopENTRY_set(&pop_heap_max_xop, xop_name, "pop_heap_max");
    XopENTRY_set(&pop_heap_max_xop, xop_desc, "raw array pop max");
    Perl_custom_op_register(aTHX_ pp_pop_heap_max, &pop_heap_max_xop);

    XopENTRY_set(&make_heap_min_xop, xop_name, "make_heap_min");
    XopENTRY_set(&make_heap_min_xop, xop_desc, "raw array make min");
    Perl_custom_op_register(aTHX_ pp_make_heap_min, &make_heap_min_xop);

    XopENTRY_set(&make_heap_max_xop, xop_name, "make_heap_max");
    XopENTRY_set(&make_heap_max_xop, xop_desc, "raw array make max");
    Perl_custom_op_register(aTHX_ pp_make_heap_max, &make_heap_max_xop);

    XopENTRY_set(&nv_pop_xop, xop_name, "nv_pop");
    XopENTRY_set(&nv_pop_xop, xop_desc, "nv heap pop");
    Perl_custom_op_register(aTHX_ pp_nv_pop, &nv_pop_xop);

    XopENTRY_set(&nv_peek_xop, xop_name, "nv_peek");
    XopENTRY_set(&nv_peek_xop, xop_desc, "nv heap peek");
    Perl_custom_op_register(aTHX_ pp_nv_peek, &nv_peek_xop);

    XopENTRY_set(&nv_size_xop, xop_name, "nv_size");
    XopENTRY_set(&nv_size_xop, xop_desc, "nv heap size");
    Perl_custom_op_register(aTHX_ pp_nv_size, &nv_size_xop);

    XopENTRY_set(&nv_peek_n_xop, xop_name, "nv_peek_n");
    XopENTRY_set(&nv_peek_n_xop, xop_desc, "nv heap peek_n");
    Perl_custom_op_register(aTHX_ pp_nv_peek_n, &nv_peek_n_xop);

    XopENTRY_set(&heap_func_peek_n_xop, xop_name, "heap_func_peek_n");
    XopENTRY_set(&heap_func_peek_n_xop, xop_desc, "heap function peek_n");
    Perl_custom_op_register(aTHX_ pp_heap_func_peek_n, &heap_func_peek_n_xop);

    XopENTRY_set(&heap_func_search_xop, xop_name, "heap_func_search");
    XopENTRY_set(&heap_func_search_xop, xop_desc, "heap function search");
    Perl_custom_op_register(aTHX_ pp_heap_func_search, &heap_func_search_xop);

    XopENTRY_set(&heap_func_delete_xop, xop_name, "heap_func_delete");
    XopENTRY_set(&heap_func_delete_xop, xop_desc, "heap function delete");
    Perl_custom_op_register(aTHX_ pp_heap_func_delete, &heap_func_delete_xop);

    XopENTRY_set(&nv_search_xop, xop_name, "nv_search");
    XopENTRY_set(&nv_search_xop, xop_desc, "nv heap search");
    Perl_custom_op_register(aTHX_ pp_nv_search, &nv_search_xop);

    XopENTRY_set(&nv_delete_xop, xop_name, "nv_delete");
    XopENTRY_set(&nv_delete_xop, xop_desc, "nv heap delete");
    Perl_custom_op_register(aTHX_ pp_nv_delete, &nv_delete_xop);

    XopENTRY_set(&heap_func_is_empty_xop, xop_name, "heap_func_is_empty");
    XopENTRY_set(&heap_func_is_empty_xop, xop_desc, "heap function is_empty");
    Perl_custom_op_register(aTHX_ pp_heap_func_is_empty, &heap_func_is_empty_xop);

    XopENTRY_set(&heap_func_clear_xop, xop_name, "heap_func_clear");
    XopENTRY_set(&heap_func_clear_xop, xop_desc, "heap function clear");
    Perl_custom_op_register(aTHX_ pp_heap_func_clear, &heap_func_clear_xop);

    XopENTRY_set(&heap_func_type_xop, xop_name, "heap_func_type");
    XopENTRY_set(&heap_func_type_xop, xop_desc, "heap function type");
    Perl_custom_op_register(aTHX_ pp_heap_func_type, &heap_func_type_xop);

    XopENTRY_set(&nv_is_empty_xop, xop_name, "nv_is_empty");
    XopENTRY_set(&nv_is_empty_xop, xop_desc, "nv heap is_empty");
    Perl_custom_op_register(aTHX_ pp_nv_is_empty, &nv_is_empty_xop);

    XopENTRY_set(&nv_clear_xop, xop_name, "nv_clear");
    XopENTRY_set(&nv_clear_xop, xop_desc, "nv heap clear");
    Perl_custom_op_register(aTHX_ pp_nv_clear, &nv_clear_xop);

    /* Register XS subs with call checkers */
    {
        CV *cv;
        SV *ckobj;

        /* Standard heap */
        newXS("Heap::PQ::new", XS_heap_new, __FILE__);

        cv = newXS("Heap::PQ::push", XS_heap_push, __FILE__);
        ckobj = newSViv(PTR2IV(pp_heap_func_push));
        cv_set_call_checker(cv, heap_call_checker_2arg, ckobj);

        newXS("Heap::PQ::push_all", XS_heap_push_all, __FILE__);

        cv = newXS("Heap::PQ::pop", XS_heap_pop, __FILE__);
        ckobj = newSViv(PTR2IV(pp_heap_func_pop));
        cv_set_call_checker(cv, heap_call_checker_1arg, ckobj);

        cv = newXS("Heap::PQ::peek", XS_heap_peek, __FILE__);
        ckobj = newSViv(PTR2IV(pp_heap_func_peek));
        cv_set_call_checker(cv, heap_call_checker_1arg, ckobj);

        cv = newXS("Heap::PQ::size", XS_heap_size, __FILE__);
        ckobj = newSViv(PTR2IV(pp_heap_func_size));
        cv_set_call_checker(cv, heap_call_checker_1arg, ckobj);

        cv = newXS("Heap::PQ::is_empty", XS_heap_is_empty, __FILE__);
        ckobj = newSViv(PTR2IV(pp_heap_func_is_empty));
        cv_set_call_checker(cv, heap_call_checker_1arg, ckobj);

        cv = newXS("Heap::PQ::clear", XS_heap_clear, __FILE__);
        ckobj = newSViv(PTR2IV(pp_heap_func_clear));
        cv_set_call_checker(cv, heap_call_checker_1arg, ckobj);

        cv = newXS("Heap::PQ::type", XS_heap_type, __FILE__);
        ckobj = newSViv(PTR2IV(pp_heap_func_type));
        cv_set_call_checker(cv, heap_call_checker_1arg, ckobj);

        cv = newXS("Heap::PQ::peek_n", XS_heap_peek_n, __FILE__);
        ckobj = newSViv(PTR2IV(pp_heap_func_peek_n));
        cv_set_call_checker(cv, heap_call_checker_2arg, ckobj);

        cv = newXS("Heap::PQ::search", XS_heap_search, __FILE__);
        ckobj = newSViv(PTR2IV(pp_heap_func_search));
        cv_set_call_checker(cv, heap_call_checker_2arg, ckobj);

        cv = newXS("Heap::PQ::delete", XS_heap_delete, __FILE__);
        ckobj = newSViv(PTR2IV(pp_heap_func_delete));
        cv_set_call_checker(cv, heap_call_checker_2arg, ckobj);

        newXS("Heap::PQ::import", XS_heap_import, __FILE__);

        /* Numeric heap */
        newXS("Heap::PQ::new_nv", XS_heap_new_nv, __FILE__);

        cv = newXS("Heap::PQ::nv::push", XS_nv_push, __FILE__);
        ckobj = newSViv(PTR2IV(pp_nv_push));
        cv_set_call_checker(cv, heap_call_checker_2arg, ckobj);

        newXS("Heap::PQ::nv::push_all", XS_nv_push_all, __FILE__);

        cv = newXS("Heap::PQ::nv::pop", XS_nv_pop, __FILE__);
        ckobj = newSViv(PTR2IV(pp_nv_pop));
        cv_set_call_checker(cv, heap_call_checker_1arg, ckobj);

        cv = newXS("Heap::PQ::nv::peek", XS_nv_peek, __FILE__);
        ckobj = newSViv(PTR2IV(pp_nv_peek));
        cv_set_call_checker(cv, heap_call_checker_1arg, ckobj);

        cv = newXS("Heap::PQ::nv::size", XS_nv_size, __FILE__);
        ckobj = newSViv(PTR2IV(pp_nv_size));
        cv_set_call_checker(cv, heap_call_checker_1arg, ckobj);

        cv = newXS("Heap::PQ::nv::is_empty", XS_nv_is_empty, __FILE__);
        ckobj = newSViv(PTR2IV(pp_nv_is_empty));
        cv_set_call_checker(cv, heap_call_checker_1arg, ckobj);

        cv = newXS("Heap::PQ::nv::clear", XS_nv_clear, __FILE__);
        ckobj = newSViv(PTR2IV(pp_nv_clear));
        cv_set_call_checker(cv, heap_call_checker_1arg, ckobj);

        cv = newXS("Heap::PQ::nv::peek_n", XS_nv_peek_n, __FILE__);
        ckobj = newSViv(PTR2IV(pp_nv_peek_n));
        cv_set_call_checker(cv, heap_call_checker_2arg, ckobj);

        cv = newXS("Heap::PQ::nv::search", XS_nv_search, __FILE__);
        ckobj = newSViv(PTR2IV(pp_nv_search));
        cv_set_call_checker(cv, heap_call_checker_2arg, ckobj);

        cv = newXS("Heap::PQ::nv::delete", XS_nv_delete, __FILE__);
        ckobj = newSViv(PTR2IV(pp_nv_delete));
        cv_set_call_checker(cv, heap_call_checker_2arg, ckobj);

        /* Raw array functions */
        cv = newXS("Heap::PQ::push_heap_min", XS_push_heap_min, __FILE__);
        ckobj = newSViv(PTR2IV(pp_push_heap_min));
        cv_set_call_checker(cv, heap_call_checker_2arg, ckobj);

        cv = newXS("Heap::PQ::pop_heap_min", XS_pop_heap_min, __FILE__);
        ckobj = newSViv(PTR2IV(pp_pop_heap_min));
        cv_set_call_checker(cv, heap_call_checker_1arg, ckobj);

        cv = newXS("Heap::PQ::push_heap_max", XS_push_heap_max, __FILE__);
        ckobj = newSViv(PTR2IV(pp_push_heap_max));
        cv_set_call_checker(cv, heap_call_checker_2arg, ckobj);

        cv = newXS("Heap::PQ::pop_heap_max", XS_pop_heap_max, __FILE__);
        ckobj = newSViv(PTR2IV(pp_pop_heap_max));
        cv_set_call_checker(cv, heap_call_checker_1arg, ckobj);

        cv = newXS("Heap::PQ::make_heap_min", XS_make_heap_min, __FILE__);
        ckobj = newSViv(PTR2IV(pp_make_heap_min));
        cv_set_call_checker(cv, heap_call_checker_1arg, ckobj);

        cv = newXS("Heap::PQ::make_heap_max", XS_make_heap_max, __FILE__);
        ckobj = newSViv(PTR2IV(pp_make_heap_max));
        cv_set_call_checker(cv, heap_call_checker_1arg, ckobj);
    }

#if PERL_VERSION_GE(5,22,0)
    Perl_xs_boot_epilog(aTHX_ ax);
#else
    XSRETURN_YES;
#endif
}