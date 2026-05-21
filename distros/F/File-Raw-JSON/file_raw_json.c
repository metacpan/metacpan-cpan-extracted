/*
 * file_raw_json.c - File::Raw::JSON value-mapping + JSONL brace-balancer
 */

#include "file_raw_json.h"

#include <string.h>
#include <stdio.h>
#include <math.h>
#include <limits.h>
#include "tie_orderedhash.h"

/* ============================================================
 * Defaults
 * ============================================================ */

void
json_options_defaults(json_options_t *o)
{
    o->mode          = JSON_MODE_DOCUMENT;
    o->pretty        = 0;
    o->indent        = 2;
    o->sort_keys     = 0;
    o->canonical     = 0;
    o->utf8          = 1;
    o->relaxed       = 0;
    o->allow_nonref  = 1;
    o->allow_nan_inf = 0;
    o->ordered       = 0;
    o->max_depth     = 512;
    o->eol[0]        = '\n';
    o->eol[1]        = '\0';
    o->eol_len       = 1;
}

/* ============================================================
 * JSONL brace-balancer
 *
 * Walk a buffer, find the byte range of the next balanced top-level
 * JSON value (object or array). Skip leading whitespace; track string
 * state and escape state; bail on truncation with NEED_MORE; bail on
 * a non-opener with NO_OPENER.
 *
 * Equivalent to JSON::Lines's recursive Perl regex but:
 *   - O(n) byte scan with no backtracking
 *   - no PCRE2 dep
 *   - resumable: caller can retry with a longer buffer after NEED_MORE
 * ============================================================ */

jsonl_scan_t
json_jsonl_next(const char *buf, STRLEN len,
                STRLEN *out_start, STRLEN *out_end, STRLEN *next_pos)
{
    STRLEN i = 0;
    int depth = 0;
    int in_string = 0;
    int prev_backslash = 0;
    char c;

    /* Skip ASCII whitespace before the value. */
    while (i < len) {
        c = buf[i];
        if (c != ' ' && c != '\t' && c != '\n' && c != '\r') break;
        i++;
    }
    if (i >= len) {
        *out_start = i;
        *out_end   = i;
        *next_pos  = i;
        return JSONL_NO_OPENER;     /* only whitespace */
    }

    c = buf[i];
    if (c != '[' && c != '{') {
        /* Non-opener: caller decides whether to skip or croak. */
        *out_start = i;
        *out_end   = i;
        *next_pos  = i;
        return JSONL_NO_OPENER;
    }

    *out_start = i;
    depth = 1;
    i++;

    while (i < len) {
        c = buf[i];
        if (in_string) {
            if (prev_backslash) {
                prev_backslash = 0;
            } else if (c == '\\') {
                prev_backslash = 1;
            } else if (c == '"') {
                in_string = 0;
            }
            i++;
            continue;
        }
        switch (c) {
            case '[': case '{':
                depth++;
                break;
            case ']': case '}':
                depth--;
                if (depth == 0) {
                    *out_end = i + 1;
                    /* Skip trailing whitespace so next_pos points at the
                     * next value (or end of buffer). */
                    i++;
                    while (i < len) {
                        char w = buf[i];
                        if (w != ' ' && w != '\t' && w != '\n' && w != '\r')
                            break;
                        i++;
                    }
                    *next_pos = i;
                    return JSONL_FOUND;
                }
                break;
            case '"':
                in_string = 1;
                break;
            default:
                /* literal data */
                break;
        }
        i++;
    }

    /* Hit EOF mid-value: caller must buffer the tail and retry. */
    return JSONL_NEED_MORE;
}

/* ============================================================
 * Value mapping: yyjson_val -> Perl SV
 *
 * Recursive walker. Caller owns the returned SV (refcount 1).
 * boolean_stash, if non-NULL, is the HV* of the class to bless
 * true/false sentinels into.
 * ============================================================ */

static SV *make_bool_sv(pTHX_ int truth, HV *stash);
static HV *make_ordered_hv(pTHX);
static void ordered_hv_set(pTHX_ HV *hv, const char *key, STRLEN klen, SV *val);

/* Internal recursive walker.  Threads `depth` so we can enforce
 * `max_depth` (the public option) without yyjson cooperation. */
static SV *
sv_from_yyjson_d(pTHX_ yyjson_val *val, HV *boolean_stash,
                 int ordered, int depth, int max_depth)
{
    yyjson_type t;
    yyjson_subtype st;

    if (!val) return newSV(0);

    t  = yyjson_get_type(val);
    st = yyjson_get_subtype(val);

    /* Depth check fires when we *enter* a container, so primitives
     * one level past the cap still parse - matches what callers
     * intuitively expect from "max_depth = N nested levels". */
    if ((t == YYJSON_TYPE_ARR || t == YYJSON_TYPE_OBJ) && depth >= max_depth) {
        croak("File::Raw::JSON: max_depth (%d) exceeded during decode",
              max_depth);
    }

    switch (t) {
        case YYJSON_TYPE_NULL:
            return newSV(0);

        case YYJSON_TYPE_BOOL: {
            /* Inline fast path for the default boolean class (~99% of
             * decodes): pointer-compare the stash and bump the pre-
             * built singleton's refcount.  Saves a function call to
             * make_bool_sv per boolean. */
            int truth = yyjson_get_bool(val);
            if (boolean_stash == g_frj_default_stash) {
                SV *s = truth ? g_frj_true_sv : g_frj_false_sv;
                if (s) {
                    SvREFCNT_inc_simple_void_NN(s);
                    return s;
                }
            }
            return make_bool_sv(aTHX_ truth, boolean_stash);
        }

        case YYJSON_TYPE_NUM:
            switch (st) {
                case YYJSON_SUBTYPE_UINT: {
                    uint64_t u = yyjson_get_uint(val);
                    if (u <= (uint64_t)IV_MAX) return newSViv((IV)u);
                    return newSVuv((UV)u);
                }
                case YYJSON_SUBTYPE_SINT:
                    return newSViv((IV)yyjson_get_sint(val));
                case YYJSON_SUBTYPE_REAL:
                    return newSVnv(yyjson_get_real(val));
                default:
                    return newSV(0);
            }

        case YYJSON_TYPE_STR: {
            const char *s = yyjson_get_str(val);
            size_t      n = yyjson_get_len(val);
            SV *out = newSVpvn(s, n);
            sv_utf8_decode(out);
            return out;
        }

        case YYJSON_TYPE_ARR: {
            size_t n = yyjson_arr_size(val);
            AV *av = newAV();
            /* Empty-array fast path: skip iter setup. */
            if (n == 0) return newRV_noinc((SV *)av);
            {
                yyjson_val *elem;
                yyjson_arr_iter it;
                av_extend(av, (SSize_t)n);
                yyjson_arr_iter_init(val, &it);
                while ((elem = yyjson_arr_iter_next(&it))) {
                    av_push(av, sv_from_yyjson_d(aTHX_ elem, boolean_stash,
                                                 ordered, depth + 1,
                                                 max_depth));
                }
            }
            return newRV_noinc((SV *)av);
        }

        case YYJSON_TYPE_OBJ: {
            /* Tied OrderedHash when ordered=>1 (each insert dispatches
             * tie_oh_store so insertion order is preserved); plain HV
             * with hv_store otherwise. */
            size_t n = yyjson_obj_size(val);
            HV *hv = ordered ? make_ordered_hv(aTHX) : newHV();
            /* Empty-object fast path. */
            if (n == 0) return newRV_noinc((SV *)hv);
            /* Pre-size the bucket table for the non-ordered case so
             * hv_store doesn't trigger 2-3 splits + rehashes for any
             * object with more than 8 keys. */
            if (!ordered && n > 8) hv_ksplit(hv, (IV)n);
            {
                yyjson_val *key, *vv;
                yyjson_obj_iter it;
                yyjson_obj_iter_init(val, &it);
                while ((key = yyjson_obj_iter_next(&it))) {
                    vv = yyjson_obj_iter_get_val(key);
                    const char *kp = yyjson_get_str(key);
                    size_t      kl = yyjson_get_len(key);
                    SV *child = sv_from_yyjson_d(aTHX_ vv, boolean_stash,
                                                 ordered, depth + 1,
                                                 max_depth);
                    if (ordered) {
                        ordered_hv_set(aTHX_ hv, kp, kl, child);
                    } else {
                        /* Negative klen tells hv_store the bytes are
                         * UTF-8 - so wide-char Perl literals (eg
                         * "\x{00e9}") match keys decoded from yyjson's
                         * native UTF-8 byte stream. */
                        if (!hv_store(hv, kp, -(I32)kl, child, 0)) {
                            SvREFCNT_dec(child);
                        }
                    }
                }
            }
            return newRV_noinc((SV *)hv);
        }

        default:
            return newSV(0);
    }
}

SV *
json_sv_from_yyjson(pTHX_ yyjson_val *val, HV *boolean_stash,
                    int ordered, int max_depth)
{
    return sv_from_yyjson_d(aTHX_ val, boolean_stash, ordered, 0, max_depth);
}

static HV *
make_ordered_hv(pTHX)
{
    HV *hv = newHV();
    SV *tied = tie_oh_new(aTHX);                /* refcount=1, owned */
    sv_magic((SV *)hv, tied, PERL_MAGIC_tied, NULL, 0);
    SvREFCNT_dec(tied);                         /* sv_magic took its own */
    return hv;
}

/* Insert (key, val) into the tied HV.  Detects our impl object and
 * calls tie_oh_store directly (no method dispatch).  For foreign tie
 * classes - if a caller hands us an HV tied to something we don't
 * recognise - fall back to call_method("STORE") so the contract still
 * holds. */
static void
ordered_hv_set(pTHX_ HV *hv, const char *key, STRLEN klen, SV *val)
{
    MAGIC *mg = mg_find((SV *)hv, PERL_MAGIC_tied);
    SV *tied_obj;
    dSP;

    if (!mg || !mg->mg_obj) {
        /* No tie magic.  Plain hv_store is fine. */
        if (!hv_store(hv, key, (I32)klen, val, 0)) {
            SvREFCNT_dec(val);
        }
        return;
    }
    tied_obj = mg->mg_obj;

    /* Fast path: our own class.  tie_oh_store takes ownership of val,
     * so no SvREFCNT bookkeeping needed. */
    if (tie_oh_is_instance(aTHX_ tied_obj)) {
        tie_oh_store(aTHX_ tied_obj, key, klen, val);
        return;
    }

    /* Slow path: foreign tie class.  Dispatch STORE via call_method,
     * mortalising the value so it gets cleaned up after the call. */
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(tied_obj);
    XPUSHs(sv_2mortal(newSVpvn(key, klen)));
    XPUSHs(sv_2mortal(val));
    PUTBACK;
    call_method("STORE", G_DISCARD);
    SPAGAIN;
    PUTBACK;
    FREETMPS; LEAVE;
}

static SV *
make_bool_sv(pTHX_ int truth, HV *stash)
{
    if (!stash) {
        return newSVsv(truth ? &PL_sv_yes : &PL_sv_no);
    }
    /* Hot path: default class returns the pre-built read-only
     * singleton. Caller's SvREFCNT_dec balances our SvREFCNT_inc. */
    if (g_frj_default_stash && stash == g_frj_default_stash) {
        SV *s = truth ? g_frj_true_sv : g_frj_false_sv;
        if (s) {
            SvREFCNT_inc_simple_void(s);
            return s;
        }
        /* Singletons not initialised yet (eg called from BOOT order
         * race). Fall through to per-call allocation. */
    }
    {
        SV *inner = newSViv(truth ? 1 : 0);
        SV *rv = newRV_noinc(inner);
        sv_bless(rv, stash);
        return rv;
    }
}

/* ============================================================
 * Value mapping: Perl SV -> yyjson_mut_val (for encode)
 * ============================================================ */

static int sv_is_known_boolean_class(pTHX_ SV *sv);

/* Cycle detection.
 *
 * Cycles can only form when a value points back to one of its
 * ancestors on the current descent path.  Sibling subtrees can
 * never form cycles with each other - they're disjoint by the time
 * we visit them.  So we only need to track the *active path*, not
 * everything ever visited.  For real-world JSON-shaped data the
 * path is typically 3-10 deep; a linear scan of a small SV* array
 * is dramatically cheaper than HV insert / lookup / delete.
 *
 * If a structure exceeds VISITED_STACK_MAX (rare; we'd croak under
 * default max_depth=512 long before then), we fall back to an HV
 * for the overflow.  Combined with the inline stack the worst case
 * stays correct without slowing the common case. */
#define VISITED_STACK_MAX 64

typedef struct {
    SV  *stack[VISITED_STACK_MAX];
    int  depth;
    HV  *overflow;          /* lazy; created only when stack is full */
} visited_t;

PERL_STATIC_INLINE int
visited_seen(pTHX_ visited_t *v, SV *target)
{
    int i;
    /* Linear scan from top of stack (most recently entered first -
     * cycles tend to point near where we just were). */
    for (i = v->depth - 1; i >= 0; i--) {
        if (v->stack[i] == target) return 1;
    }
    if (v->overflow) {
        return hv_exists(v->overflow, (const char *)&target, sizeof(SV *));
    }
    return 0;
}

PERL_STATIC_INLINE void
visited_enter(pTHX_ visited_t *v, SV *target)
{
    if (v->depth < VISITED_STACK_MAX) {
        v->stack[v->depth++] = target;
        return;
    }
    /* Stack full - spill to HV. */
    if (!v->overflow) v->overflow = newHV();
    SvREFCNT_inc_simple_void_NN(&PL_sv_undef);
    if (!hv_store(v->overflow, (const char *)&target, sizeof(SV *),
                  &PL_sv_undef, 0))
        SvREFCNT_dec(&PL_sv_undef);
}

PERL_STATIC_INLINE void
visited_leave(pTHX_ visited_t *v, SV *target)
{
    /* Stack is LIFO - the last visited_enter must match this leave.
     * Defensive: walk back if not at top (shouldn't happen). */
    if (v->depth > 0 && v->stack[v->depth - 1] == target) {
        v->depth--;
        return;
    }
    if (v->overflow) {
        hv_delete(v->overflow, (const char *)&target, sizeof(SV *),
                  G_DISCARD);
    }
}

static yyjson_mut_val *sv_to_yyjson_v(pTHX_ SV *sv, yyjson_mut_doc *doc,
                                      const json_options_t *opts,
                                      visited_t *visited);

yyjson_mut_val *
json_sv_to_yyjson(pTHX_ SV *sv, yyjson_mut_doc *doc,
                  const json_options_t *opts)
{
    visited_t visited;
    yyjson_mut_val *r;
    visited.depth = 0;
    visited.overflow = NULL;
    r = sv_to_yyjson_v(aTHX_ sv, doc, opts, &visited);
    if (visited.overflow) SvREFCNT_dec((SV *)visited.overflow);
    return r;
}

static yyjson_mut_val *
sv_to_yyjson_v(pTHX_ SV *sv, yyjson_mut_doc *doc,
               const json_options_t *opts, visited_t *visited)
{
    PERL_UNUSED_ARG(opts);

    if (!sv || !SvOK(sv)) return yyjson_mut_null(doc);

    if (SvROK(sv)) {
        SV *target = SvRV(sv);
        if (SvOBJECT(target) && sv_is_known_boolean_class(aTHX_ sv)) {
            int truth = SvTRUE(target) ? 1 : 0;
            return yyjson_mut_bool(doc, truth);
        }
        if (SvTYPE(target) == SVt_PVAV) {
            AV *av = (AV *)target;
            yyjson_mut_val *arr;
            SV **arr_ptr;
            SSize_t i, n;
            if (visited_seen(aTHX_ visited, target)) {
                croak("File::Raw::JSON: circular reference detected "
                      "(array references itself)");
            }
            visited_enter(aTHX_ visited, target);
            arr = yyjson_mut_arr(doc);
            n = av_len(av) + 1;
            /* Direct AvARRAY access skips av_fetch's bounds + magic
             * check per element.  Holes (sparse arrays) come back as
             * NULL pointers; we substitute &PL_sv_undef. */
            arr_ptr = AvARRAY(av);
            for (i = 0; i < n; i++) {
                SV *ep = arr_ptr[i];
                yyjson_mut_val *child =
                    sv_to_yyjson_v(aTHX_ ep ? ep : &PL_sv_undef,
                                   doc, opts, visited);
                yyjson_mut_arr_append(arr, child);
            }
            visited_leave(aTHX_ visited, target);
            return arr;
        }
        if (SvTYPE(target) == SVt_PVHV) {
            /* Three dispatches:
             *   - Tie::OrderedHash: walk via the public C ABI
             *     tie_oh_iter_* (no method dispatch).
             *   - Other tied HVs: walk via hv_iternext (which goes
             *     through tied FIRSTKEY/NEXTKEY) and dispatch FETCH
             *     per key via call_method.
             *   - Untied HVs: walk via hv_iternext + hv_iterval.
             *
             * sort_keys / canonical: collect (key, val) pairs first,
             * sort, emit.  Default: walk and emit in one pass - no
             * collection buffer alloc.  HvUSEDKEYS returns 0 for tied
             * HVs (their bucket storage is empty), so we can't use it
             * to pre-size or short-circuit; the live walks above
             * handle tied HVs correctly. */
            HV *hv = (HV *)target;
            yyjson_mut_val *obj;
            HE *he;
            MAGIC *tied_mg;
            int do_sort = opts->sort_keys || opts->canonical;

            if (visited_seen(aTHX_ visited, target)) {
                croak("File::Raw::JSON: circular reference detected "
                      "(hash references itself)");
            }
            visited_enter(aTHX_ visited, target);
            obj = yyjson_mut_obj(doc);
            tied_mg = mg_find((SV *)hv, PERL_MAGIC_tied);

            if (do_sort) {
                /* Collect-sort-emit.  Most JSON objects have <32
                 * keys; stack-allocate the buffers for that case to
                 * skip the malloc/free pair (significant when
                 * sort_keys is set on a large array of small
                 * objects - was the dominant cost on the
                 * sort_keys+pretty bench at medium size). */
#define FRJ_SORT_STACK_SIZE 32
                SV  *stack_keys[FRJ_SORT_STACK_SIZE];
                SV  *stack_vals[FRJ_SORT_STACK_SIZE];
                SV **keys_buf = stack_keys;
                SV **vals_buf = stack_vals;
                SSize_t count = 0;
                SSize_t cap = FRJ_SORT_STACK_SIZE;
                int      on_heap = 0;
                SSize_t  i;

#define FRJ_PUSH_PAIR(KSV, VSV) STMT_START {                       \
    if (count >= cap) {                                            \
        SSize_t new_cap = cap * 2;                                 \
        if (on_heap) {                                             \
            Renew(keys_buf, new_cap, SV *);                        \
            Renew(vals_buf, new_cap, SV *);                        \
        } else {                                                   \
            SV **nk, **nv;                                         \
            Newx(nk, new_cap, SV *);                               \
            Newx(nv, new_cap, SV *);                               \
            memcpy(nk, keys_buf, sizeof(SV *) * (size_t)count);    \
            memcpy(nv, vals_buf, sizeof(SV *) * (size_t)count);    \
            keys_buf = nk;                                         \
            vals_buf = nv;                                         \
            on_heap = 1;                                           \
        }                                                          \
        cap = new_cap;                                             \
    }                                                              \
    keys_buf[count] = (KSV);                                       \
    vals_buf[count] = (VSV);                                       \
    count++;                                                       \
} STMT_END

                if (tied_mg && tied_mg->mg_obj
                    && tie_oh_is_instance(aTHX_ tied_mg->mg_obj))
                {
                    SV *self = tied_mg->mg_obj;
                    tie_oh_iter_t it;
                    const char *key;
                    STRLEN klen;
                    SV *vsv;
                    tie_oh_iter_init(aTHX_ self, &it);
                    while (tie_oh_iter_next(aTHX_ self, &it,
                                            &key, &klen, &vsv)) {
                        SV *ksv = sv_2mortal(newSVpvn(key, klen));
                        FRJ_PUSH_PAIR(ksv, vsv);
                    }
                } else if (tied_mg && tied_mg->mg_obj) {
                    hv_iterinit(hv);
                    while ((he = hv_iternext(hv))) {
                        I32 klen;
                        const char *key = hv_iterkey(he, &klen);
                        SV *fetched, *copy, *ksv;
                        int rc;
                        dSP;
                        ENTER; SAVETMPS;
                        PUSHMARK(SP);
                        XPUSHs(tied_mg->mg_obj);
                        XPUSHs(sv_2mortal(newSVpvn(key, klen)));
                        PUTBACK;
                        rc = call_method("FETCH", G_SCALAR);
                        SPAGAIN;
                        fetched = rc > 0 ? POPs : &PL_sv_undef;
                        copy = newSVsv(fetched);
                        PUTBACK;
                        FREETMPS; LEAVE;
                        ksv = sv_2mortal(newSVpvn(key, klen));
                        FRJ_PUSH_PAIR(ksv, sv_2mortal(copy));
                    }
                } else {
                    /* Untied HV: HeVAL(he) is direct, no tie-magic
                     * re-check (hv_iterval would do that since it's
                     * the polymorphic accessor). */
                    hv_iterinit(hv);
                    while ((he = hv_iternext(hv))) {
                        FRJ_PUSH_PAIR(hv_iterkeysv(he), HeVAL(he));
                    }
                }

#undef FRJ_PUSH_PAIR

                /* Insertion sort: small n typical, no comparator
                 * indirection. */
                {
                    SSize_t a, b;
                    for (a = 1; a < count; a++) {
                        SV *kcur = keys_buf[a];
                        SV *vcur = vals_buf[a];
                        STRLEN clen;
                        const char *cpv = SvPV(kcur, clen);
                        b = a - 1;
                        while (b >= 0) {
                            STRLEN plen;
                            const char *ppv = SvPV(keys_buf[b], plen);
                            STRLEN cmplen = clen < plen ? clen : plen;
                            int rc = memcmp(cpv, ppv, cmplen);
                            if (rc < 0 || (rc == 0 && clen < plen)) {
                                keys_buf[b + 1] = keys_buf[b];
                                vals_buf[b + 1] = vals_buf[b];
                                b--;
                            } else break;
                        }
                        keys_buf[b + 1] = kcur;
                        vals_buf[b + 1] = vcur;
                    }
                }

                for (i = 0; i < count; i++) {
                    STRLEN klen;
                    const char *kp = SvPV(keys_buf[i], klen);
                    yyjson_mut_val *kval = yyjson_mut_strn(doc, kp, (size_t)klen);
                    yyjson_mut_val *vval = sv_to_yyjson_v(aTHX_ vals_buf[i],
                                                         doc, opts, visited);
                    yyjson_mut_obj_add(obj, kval, vval);
                }

                if (on_heap) {
                    Safefree(keys_buf);
                    Safefree(vals_buf);
                }
#undef FRJ_SORT_STACK_SIZE
            }
            else if (tied_mg && tied_mg->mg_obj
                     && tie_oh_is_instance(aTHX_ tied_mg->mg_obj))
            {
                /* Single-pass: tie_oh_iter_* + emit. */
                SV *self = tied_mg->mg_obj;
                tie_oh_iter_t it;
                const char *key;
                STRLEN klen;
                SV *vsv;
                tie_oh_iter_init(aTHX_ self, &it);
                while (tie_oh_iter_next(aTHX_ self, &it,
                                        &key, &klen, &vsv)) {
                    yyjson_mut_val *kval = yyjson_mut_strn(
                        doc, key, (size_t)klen);
                    yyjson_mut_val *vval = sv_to_yyjson_v(
                        aTHX_ vsv, doc, opts, visited);
                    yyjson_mut_obj_add(obj, kval, vval);
                }
            }
            else if (tied_mg && tied_mg->mg_obj) {
                /* Single-pass: hv_iternext + per-key call_method FETCH. */
                hv_iterinit(hv);
                while ((he = hv_iternext(hv))) {
                    I32 klen;
                    const char *key = hv_iterkey(he, &klen);
                    SV *fetched, *copy, *vsv;
                    yyjson_mut_val *kval, *vval;
                    int rc;
                    dSP;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(tied_mg->mg_obj);
                    XPUSHs(sv_2mortal(newSVpvn(key, klen)));
                    PUTBACK;
                    rc = call_method("FETCH", G_SCALAR);
                    SPAGAIN;
                    fetched = rc > 0 ? POPs : &PL_sv_undef;
                    copy = newSVsv(fetched);
                    PUTBACK;
                    FREETMPS; LEAVE;
                    vsv = sv_2mortal(copy);

                    kval = yyjson_mut_strn(doc, key, (size_t)klen);
                    vval = sv_to_yyjson_v(aTHX_ vsv, doc, opts, visited);
                    yyjson_mut_obj_add(obj, kval, vval);
                }
            }
            else {
                /* Untied HV: HeVAL(he) is direct.  hv_iterval is the
                 * tie-aware polymorphic accessor and would re-check
                 * magic per key; we already know we're not tied here. */
                hv_iterinit(hv);
                while ((he = hv_iternext(hv))) {
                    I32 klen;
                    const char *key = hv_iterkey(he, &klen);
                    yyjson_mut_val *kval = yyjson_mut_strn(
                        doc, key, (size_t)klen);
                    yyjson_mut_val *vval = sv_to_yyjson_v(
                        aTHX_ HeVAL(he), doc, opts, visited);
                    yyjson_mut_obj_add(obj, kval, vval);
                }
            }

            visited_leave(aTHX_ visited, target);
            return obj;
        }
        /* Reject things that have no sane JSON encoding. */
        {
            svtype tt = SvTYPE(target);
            if (tt == SVt_PVCV) {
                croak("File::Raw::JSON: cannot encode CODE reference as JSON");
            }
            if (tt == SVt_PVGV) {
                croak("File::Raw::JSON: cannot encode GLOB reference as JSON");
            }
            /* SvRXOK is the portable regex check - handles SVt_REGEXP
             * and the older magic-attached form. */
            if (SvRXOK(sv) || SvRXOK(target)) {
                croak("File::Raw::JSON: cannot encode Regexp reference as JSON");
            }
        }
        /* Non-blessed scalar refs are treated as JSON booleans by
         * truthiness, matching JSON::XS / Cpanel::JSON::XS / JSON::PP:
         *   \1   -> true
         *   \0   -> false
         *   \""  -> false
         *   \"x" -> true
         * Lets callers express booleans without loading a sentinel
         * class. */
        if (!SvOBJECT(target)) {
            return yyjson_mut_bool(doc, SvTRUE(target) ? 1 : 0);
        }
        /* Blessed non-recognised refs (eg bless \1, 'My::Class' that
         * isn't a known boolean class) fall through to SvPV which
         * emits the stringified form ("My::Class=SCALAR(0x...)"). */
        {
            STRLEN len;
            const char *s = SvPV(sv, len);
            return yyjson_mut_strn(doc, s, (size_t)len);
        }
    }

    if (SvIOK(sv) && !SvNOK(sv)) {
        if (SvIsUV(sv)) return yyjson_mut_uint(doc, (uint64_t)SvUV(sv));
        return yyjson_mut_sint(doc, (int64_t)SvIV(sv));
    }
    if (SvNOK(sv)) {
        return yyjson_mut_real(doc, SvNV(sv));
    }
    {
        STRLEN len;
        const char *s = SvPV(sv, len);
        return yyjson_mut_strn(doc, s, (size_t)len);
    }
}

/* Recognise known boolean sentinel classes.
 *
 * Hot path: pointer-compare against g_frj_default_stash (cached at
 * BOOT for File::Raw::JSON::Boolean).  ~99% of decoded booleans
 * come back blessed into this class, so a single pointer comparison
 * resolves them without touching the stash name.  Foreign classes
 * fall through to the HvNAME_get + strEQ chain. */
static int
sv_is_known_boolean_class(pTHX_ SV *sv)
{
    HV *stash;
    const char *name;
    if (!SvROK(sv)) return 0;
    if (!SvOBJECT(SvRV(sv))) return 0;
    stash = SvSTASH(SvRV(sv));
    if (!stash) return 0;
    /* Hot path: our default class. */
    if (g_frj_default_stash && stash == g_frj_default_stash) return 1;
    /* Cold path: foreign boolean sentinels. */
    name = HvNAME_get(stash);
    if (!name) return 0;
    if (strEQ(name, "JSON::PP::Boolean"))           return 1;
    if (strEQ(name, "Types::Serialiser::Boolean"))  return 1;
    if (strEQ(name, "Cpanel::JSON::XS::Boolean"))   return 1;
    if (strEQ(name, "JSON::XS::Boolean"))           return 1;
    if (strEQ(name, "boolean"))                     return 1;
    /* Last: name-compare File::Raw::JSON::Boolean for the case where
     * the stash pointer drifted (eg multiple interpreter contexts). */
    return strEQ(name, "File::Raw::JSON::Boolean");
}

/* ============================================================
 * Decode entry points
 * ============================================================ */

static void
croak_yyjson_read(pTHX_ const yyjson_read_err *err,
                  const char *bytes, STRLEN len)
{
    STRLEN ctx_off = err->pos > 16 ? err->pos - 16 : 0;
    STRLEN ctx_end = err->pos + 16 < len ? err->pos + 16 : len;
    STRLEN ctx_len = ctx_end - ctx_off;
    SV *ctx = sv_2mortal(newSVpvn(bytes + ctx_off, ctx_len));
    char *p = SvPVX(ctx);
    STRLEN i;
    for (i = 0; i < ctx_len; i++) {
        if (p[i] == '\n' || p[i] == '\r' || p[i] == '\t') p[i] = ' ';
    }
    croak("File::Raw::JSON: %s at byte offset %lu near \"%.*s\"",
          err->msg ? err->msg : "parse error",
          (unsigned long)err->pos, (int)ctx_len, p);
}

static yyjson_read_flag
build_read_flags(const json_options_t *opts)
{
    yyjson_read_flag f = 0;
    if (opts->relaxed) {
        f |= YYJSON_READ_ALLOW_COMMENTS;
        f |= YYJSON_READ_ALLOW_TRAILING_COMMAS;
    }
    if (opts->allow_nan_inf) f |= YYJSON_READ_ALLOW_INF_AND_NAN;
    return f;
}

/* Hybrid bump-then-malloc allocator for yyjson read.
 *
 * yyjson allocates one ~16-byte mut_val per JSON value via its
 * configured allocator (default: malloc).  For small/medium docs
 * those allocations are pure overhead - we'd rather slice them off
 * a pre-allocated stack buffer.
 *
 * This allocator does exactly that: serves from a stack-resident
 * pool by bump pointer until exhausted, then falls back to malloc
 * for individual oversize requests.  free() is a no-op for in-pool
 * pointers, real free() for malloc'd ones.
 *
 * Why hybrid (rather than just yyjson_alc_pool_init): the built-in
 * pool init returns NULL on overflow, which fails the parse.  We
 * want graceful fallback so any doc parses, with the small/medium
 * fast path getting the perf win. */
typedef struct {
    char  *pool;
    size_t pool_size;
    size_t pool_used;
} frj_alc_ctx_t;

static void *
frj_alc_malloc(void *ctx, size_t size)
{
    frj_alc_ctx_t *c = (frj_alc_ctx_t *)ctx;
    /* 16-byte aligned bump (yyjson values are typically 16-byte). */
    size_t aligned = (c->pool_used + 15) & ~(size_t)15;
    if (aligned + size <= c->pool_size) {
        c->pool_used = aligned + size;
        return c->pool + aligned;
    }
    return malloc(size);
}

static void *
frj_alc_realloc(void *ctx, void *ptr, size_t old_size, size_t size)
{
    frj_alc_ctx_t *c = (frj_alc_ctx_t *)ctx;
    if (ptr >= (void *)c->pool && ptr < (void *)(c->pool + c->pool_size)) {
        /* In-pool memory: allocate fresh, copy, leave the old block
         * in the pool (will be reclaimed when the pool is reset). */
        void *new_ptr = frj_alc_malloc(ctx, size);
        if (new_ptr && old_size > 0) {
            memcpy(new_ptr, ptr, old_size < size ? old_size : size);
        }
        return new_ptr;
    }
    return realloc(ptr, size);
}

static void
frj_alc_free(void *ctx, void *ptr)
{
    frj_alc_ctx_t *c = (frj_alc_ctx_t *)ctx;
    if (ptr >= (void *)c->pool && ptr < (void *)(c->pool + c->pool_size)) {
        return;     /* No-op for pool memory; reset on caller exit */
    }
    free(ptr);
}

#define FRJ_READ_POOL_BYTES (16 * 1024)

SV *
json_decode_document(pTHX_ const char *bytes, STRLEN len,
                     const json_options_t *opts, HV *boolean_stash)
{
    char pool_buf[FRJ_READ_POOL_BYTES];
    frj_alc_ctx_t alc_ctx;
    yyjson_alc alc;
    yyjson_read_err err;
    yyjson_doc *doc;
    SV *out;
    yyjson_val *root;

    alc_ctx.pool      = pool_buf;
    alc_ctx.pool_size = sizeof pool_buf;
    alc_ctx.pool_used = 0;
    alc.malloc        = frj_alc_malloc;
    alc.realloc       = frj_alc_realloc;
    alc.free          = frj_alc_free;
    alc.ctx           = &alc_ctx;

    doc = yyjson_read_opts((char *)bytes, (size_t)len,
                           build_read_flags(opts), &alc, &err);

    if (!doc) {
        croak_yyjson_read(aTHX_ &err, bytes, len);
        /* NOTREACHED */
    }
    root = yyjson_doc_get_root(doc);
    if (!opts->allow_nonref && root) {
        yyjson_type t = yyjson_get_type(root);
        if (t != YYJSON_TYPE_ARR && t != YYJSON_TYPE_OBJ) {
            yyjson_doc_free(doc);
            croak("File::Raw::JSON: top-level value is not an object/array "
                  "and allow_nonref is false");
        }
    }
    out = json_sv_from_yyjson(aTHX_ root, boolean_stash,
                              opts->ordered, opts->max_depth);
    yyjson_doc_free(doc);
    return out;
}

AV *
json_decode_lines(pTHX_ const char *bytes, STRLEN len,
                  const json_options_t *opts, HV *boolean_stash)
{
    AV *result = newAV();
    STRLEN cursor = 0;
    /* Per-line pool: reused across all lines.  Reset to empty after
     * each parse (the doc is freed before next parse, so all in-pool
     * memory is logically reclaimed). */
    char pool_buf[FRJ_READ_POOL_BYTES];
    frj_alc_ctx_t alc_ctx;
    yyjson_alc alc;
    alc_ctx.pool      = pool_buf;
    alc_ctx.pool_size = sizeof pool_buf;
    alc.malloc        = frj_alc_malloc;
    alc.realloc       = frj_alc_realloc;
    alc.free          = frj_alc_free;
    alc.ctx           = &alc_ctx;

    while (cursor < len) {
        STRLEN s, e, np;
        jsonl_scan_t rc =
            json_jsonl_next(bytes + cursor, len - cursor, &s, &e, &np);
        if (rc == JSONL_FOUND) {
            yyjson_read_err err;
            yyjson_doc *doc;
            alc_ctx.pool_used = 0;     /* reset pool for next line */
            doc = yyjson_read_opts(
                (char *)bytes + cursor + s, (size_t)(e - s),
                build_read_flags(opts), &alc, &err);
            if (!doc) {
                err.pos += cursor + s;
                SvREFCNT_dec((SV *)result);
                croak_yyjson_read(aTHX_ &err, bytes, len);
            }
            av_push(result,
                    json_sv_from_yyjson(aTHX_ yyjson_doc_get_root(doc),
                                        boolean_stash, opts->ordered,
                                        opts->max_depth));
            yyjson_doc_free(doc);
            cursor += np;
            continue;
        }
        if (rc == JSONL_NEED_MORE) {
            SvREFCNT_dec((SV *)result);
            croak("File::Raw::JSON: truncated JSON value at byte offset %lu",
                  (unsigned long)(cursor + s));
        }
        /* JSONL_NO_OPENER: lenient = skip; strict = croak. */
        if (s >= len - cursor) break;        /* trailing whitespace */
        if (opts->relaxed) { cursor += s + 1; continue; }
        SvREFCNT_dec((SV *)result);
        croak("File::Raw::JSON: unexpected byte at offset %lu "
              "(expected '{' or '[' to start a JSONL value)",
              (unsigned long)(cursor + s));
    }
    return result;
}

/* ============================================================
 * Encode entry points
 * ============================================================ */

static yyjson_write_flag
build_write_flags(const json_options_t *opts)
{
    yyjson_write_flag f = 0;
    if (opts->pretty && !opts->canonical) {
        if (opts->indent == 4) {
            f |= YYJSON_WRITE_PRETTY;        /* 4 spaces */
        } else {
            f |= YYJSON_WRITE_PRETTY_TWO_SPACES;
        }
    }
    if (!opts->utf8) f |= YYJSON_WRITE_ESCAPE_UNICODE;
    if (opts->allow_nan_inf) f |= YYJSON_WRITE_ALLOW_INF_AND_NAN;
    return f;
}

SV *
json_encode_document(pTHX_ SV *value, const json_options_t *opts)
{
    yyjson_mut_doc *doc = yyjson_mut_doc_new(NULL);
    yyjson_mut_val *root;
    yyjson_write_err err;
    char *out;
    size_t out_len;
    SV *result;

    if (!doc) croak("File::Raw::JSON: out of memory (mut_doc_new)");

    root = json_sv_to_yyjson(aTHX_ value, doc, opts);
    yyjson_mut_doc_set_root(doc, root);

    out = yyjson_mut_write_opts(doc, build_write_flags(opts), NULL,
                                &out_len, &err);
    if (!out) {
        yyjson_mut_doc_free(doc);
        croak("File::Raw::JSON: encode failed: %s",
              err.msg ? err.msg : "unknown error");
    }
    result = newSVpvn(out, out_len);
    free(out);
    yyjson_mut_doc_free(doc);
    return result;
}

SV *
json_encode_lines(pTHX_ SV *payload, const json_options_t *opts)
{
    AV *av;
    SSize_t i, n;
    SV *out;

    if (!payload || !SvROK(payload) || SvTYPE(SvRV(payload)) != SVt_PVAV)
        croak("File::Raw::JSON: jsonl write expects an arrayref of records");

    av = (AV *)SvRV(payload);
    n  = av_len(av) + 1;
    out = newSVpvn("", 0);

    for (i = 0; i < n; i++) {
        SV **ep = av_fetch(av, i, 0);
        SV *rec_bytes;
        STRLEN blen;
        const char *bp;
        rec_bytes = json_encode_document(aTHX_
                        (ep && *ep) ? *ep : &PL_sv_undef, opts);
        bp = SvPV(rec_bytes, blen);
        sv_catpvn(out, bp, blen);
        sv_catpvn(out, opts->eol, opts->eol_len);
        SvREFCNT_dec(rec_bytes);
    }
    return out;
}
