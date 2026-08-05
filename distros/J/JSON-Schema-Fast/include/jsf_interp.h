#ifndef JSF_INTERP_H
#define JSF_INTERP_H

/* The validation engine. is_valid() runs with ctx->errors == NULL: fail-fast,
 * no instance-location bookkeeping, zero allocation on the valid path. validate()
 * / errors() run with a sink AV and a reused JSON-Pointer buffer (ctx->iloc),
 * collecting every error with instanceLocation / keyword / schemaLocation.
 * Combinators (anyOf/oneOf/not/if) probe their branches with a throwaway ctx so
 * a branch that is *allowed* to fail does not leak errors into the sink.
 *
 * Needs jsf_arena.h, jsf_ir.h, jsf_types.h, jsf_compiled.h, jsf_err.h + Perl. */

#include <math.h>

#define JSF_MAX_DEPTH 1024

static int jsf_validate(pTHX_ jsf_compiled_t *C, uint32_t off, SV *data, jsf_ctx_t *ctx);

/* ---- annotation collector for unevaluatedProperties/Items --------------- *
 * Per data-instance: the set of property names / item indices that some
 * keyword or successful in-place applicator has already evaluated. Only used
 * when the schema declares unevaluated* (C->has_unevaluated); NULL otherwise. */
typedef struct jsf_annot { HV *props; HV *items; int all_items; } jsf_annot;

static jsf_annot *jsf_annot_new(pTHX) {
    jsf_annot *a = (jsf_annot *)malloc(sizeof *a);
    if (!a) return NULL;
    a->props = newHV(); a->items = newHV(); a->all_items = 0;
    return a;
}
static void jsf_annot_free(pTHX_ jsf_annot *a) {
    if (!a) return;
    SvREFCNT_dec((SV *)a->props); SvREFCNT_dec((SV *)a->items); free(a);
}
static void jsf_annot_merge(pTHX_ jsf_annot *dst, jsf_annot *src) {
    HE *he;
    if (!dst || !src) return;
    hv_iterinit(src->props); while ((he = hv_iternext(src->props))) { STRLEN kl; char *k = HePV(he, kl); (void)hv_store(dst->props, k, kl, &PL_sv_yes, 0); }
    hv_iterinit(src->items); while ((he = hv_iternext(src->items))) { STRLEN kl; char *k = HePV(he, kl); (void)hv_store(dst->items, k, kl, &PL_sv_yes, 0); }
    dst->all_items |= src->all_items;
}
static void jsf_annot_add_key(pTHX_ jsf_annot *a, const char *k, STRLEN kl) {
    if (a) (void)hv_store(a->props, k, kl, &PL_sv_yes, 0);
}
static void jsf_annot_add_idx(pTHX_ jsf_annot *a, IV i) {
    if (a) { char b[24]; int n = (int)my_snprintf(b, sizeof b, "%" IVdf, i); (void)hv_store(a->items, b, n, &PL_sv_yes, 0); }
}
static int jsf_annot_has_idx(pTHX_ jsf_annot *a, IV i) {
    char b[24]; int n;
    if (!a) return 0;
    if (a->all_items) return 1;
    n = (int)my_snprintf(b, sizeof b, "%" IVdf, i);
    return hv_exists(a->items, b, n);
}

/* ---- JSON value equality (const/enum, uniqueItems) ---------------------- */
static int jsf_json_equal(pTHX_ SV *a, SV *b) {
    unsigned ta = jsf_classify_type(aTHX_ a);
    unsigned tb = jsf_classify_type(aTHX_ b);
    if ((ta & JSF_T_NUMBER) && (tb & JSF_T_NUMBER)) return SvNV(a) == SvNV(b);
    if ((ta & JSF_T_STRING) && (tb & JSF_T_STRING)) {
        STRLEN la, lb; const char *sa = SvPV_const(a, la); const char *sb = SvPV_const(b, lb);
        return la == lb && memcmp(sa, sb, la) == 0;
    }
    if ((ta & JSF_T_BOOLEAN) && (tb & JSF_T_BOOLEAN)) return (SvTRUE(a) ? 1 : 0) == (SvTRUE(b) ? 1 : 0);
    if ((ta & JSF_T_NULL) && (tb & JSF_T_NULL)) return 1;
    if ((ta & JSF_T_ARRAY) && (tb & JSF_T_ARRAY)) {
        AV *aa = (AV *)SvRV(a), *ab = (AV *)SvRV(b);
        SSize_t i, na = av_len(aa) + 1;
        if (na != av_len(ab) + 1) return 0;
        for (i = 0; i < na; i++) {
            SV **x = av_fetch(aa, i, 0), **y = av_fetch(ab, i, 0);
            if (!jsf_json_equal(aTHX_ x ? *x : &PL_sv_undef, y ? *y : &PL_sv_undef)) return 0;
        }
        return 1;
    }
    if ((ta & JSF_T_OBJECT) && (tb & JSF_T_OBJECT)) {
        HV *ha = (HV *)SvRV(a), *hb = (HV *)SvRV(b); HE *he;
        if (HvKEYS(ha) != HvKEYS(hb)) return 0;
        hv_iterinit(ha);
        while ((he = hv_iternext(ha))) {
            STRLEN kl; char *k = HePV(he, kl);
            SV **y = hv_fetch(hb, k, (I32)kl, 0);
            if (!y || !jsf_json_equal(aTHX_ HeVAL(he), *y)) return 0;
        }
        return 1;
    }
    return 0;
}

/* ---- pattern regex (compiled once, cached) ------------------------------ */
static REGEXP *jsf_get_regex(pTHX_ jsf_compiled_t *C, uint32_t pat_off) {
    int i; uint32_t len; const char *p; SV *pat; REGEXP *rx;
    for (i = 0; i < C->rxn; i++) if (C->rx[i].pat_off == pat_off) return C->rx[i].rx;
    p = jsf_str_bytes(C->arena, pat_off, &len);
    pat = sv_2mortal(newSVpvn(p, len));
    rx = pregcomp(pat, 0);
    if (C->rxn == C->rxcap) {
        int nc = C->rxcap ? C->rxcap * 2 : 8;
        jsf_rxent *nr = (jsf_rxent *)realloc(C->rx, nc * sizeof(jsf_rxent));
        if (!nr) return rx;
        C->rx = nr; C->rxcap = nc;
    }
    C->rx[C->rxn].pat_off = pat_off; C->rx[C->rxn].rx = rx; C->rxn++;
    return rx;
}

static int jsf_rx_match(pTHX_ REGEXP *rx, SV *sv) {
    STRLEN l; char *s;
    if (!rx) return 1;
    s = SvPV(sv, l);
    return pregexec(rx, s, s + l, s, 0, sv, 1) ? 1 : 0;
}

static int jsf_find_prop(jsf_proptab *pt, jsf_propent *en, char *base,
                         const char *k, STRLEN kl) {
    int lo = 0, hi = (int)pt->n - 1;
    while (lo <= hi) {
        int mid = (lo + hi) >> 1;
        const char *nm = base + en[mid].name_off + sizeof(jsf_str_t);
        uint32_t nl = en[mid].name_len, m = nl < (uint32_t)kl ? nl : (uint32_t)kl;
        int c = memcmp(k, nm, m);
        if (c == 0) c = ((uint32_t)kl < nl) ? -1 : ((uint32_t)kl > nl ? 1 : 0);
        if (c == 0) return mid;
        if (c < 0) hi = mid - 1; else lo = mid + 1;
    }
    return -1;
}

/* ---- instanceLocation buffer (JSON Pointer, RFC 6901 escaping) ---------- */
static STRLEN jsf_iloc_push_key(pTHX_ SV *iloc, const char *k, STRLEN kl) {
    STRLEN save = SvCUR(iloc), i; int special = 0;
    for (i = 0; i < kl; i++) if (k[i] == '~' || k[i] == '/') { special = 1; break; }
    sv_catpvn(iloc, "/", 1);
    if (!special) { sv_catpvn(iloc, k, kl); }
    else for (i = 0; i < kl; i++) {
        if      (k[i] == '~') sv_catpvn(iloc, "~0", 2);
        else if (k[i] == '/') sv_catpvn(iloc, "~1", 2);
        else                  sv_catpvn(iloc, k + i, 1);
    }
    return save;
}
static STRLEN jsf_iloc_push_idx(pTHX_ SV *iloc, IV idx) {
    STRLEN save = SvCUR(iloc);
    sv_catpvf(iloc, "/%" IVdf, idx);
    return save;
}
static void jsf_iloc_pop(SV *iloc, STRLEN save) {
    SvCUR_set(iloc, save);
    SvPVX(iloc)[save] = '\0';
}

/* ---- error push (cold path) --------------------------------------------- */
static void jsf_err_push(pTHX_ jsf_ctx_t *ctx, jsf_compiled_t *C, uint32_t off, const char *kw) {
    jsf_node_t *n = (jsf_node_t *)jsf_arena_ptr(C->arena, off);
    uint32_t sl; const char *sp = jsf_str_bytes(C->arena, n->schema_path_off, &sl);
    HV *e = newHV();
    SV *schemaLoc = newSVpvn(sp, sl);
    sv_catpvs(schemaLoc, "/");
    sv_catpv(schemaLoc, kw);
    (void)hv_stores(e, "instanceLocation", newSVsv(ctx->iloc));
    (void)hv_stores(e, "keyword",          newSVpv(kw, 0));
    (void)hv_stores(e, "schemaLocation",   schemaLoc);
    (void)hv_stores(e, "message",          newSVpvf("failed '%s' constraint", kw));
    av_push(ctx->errors, newRV_noinc((SV *)e));
}

/* coercion (opt-in): which type bits a string can stand in for */
static unsigned jsf_coerce_bits(pTHX_ uint32_t mask, SV *data, unsigned t) {
    STRLEN l; const char *s;
    if (!(t & JSF_T_STRING)) return 0;
    s = SvPV_const(data, l);
    if ((mask & (JSF_T_NUMBER | JSF_T_INTEGER)) && looks_like_number(data)) {
        NV nv = SvNV(data);
        int integral = (nv == (NV)(IV)nv);
        if (mask & JSF_T_NUMBER)  return (unsigned)(JSF_T_NUMBER | (integral ? JSF_T_INTEGER : 0));
        if ((mask & JSF_T_INTEGER) && integral) return JSF_T_NUMBER | JSF_T_INTEGER;
    }
    if (mask & JSF_T_BOOLEAN) {
        if ((l == 4 && memEQ(s, "true", 4)) || (l == 5 && memEQ(s, "false", 5))) return JSF_T_BOOLEAN;
    }
    return 0;
}

/* run a subschema as a boolean probe (no error leakage, no annotations) */
static int jsf_probe(pTHX_ jsf_compiled_t *C, uint32_t off, SV *data, jsf_ctx_t *parent) {
    jsf_ctx_t p;
    p.errors = NULL; p.iloc = NULL; p.collect = 0; p.depth = parent->depth; p.ann = NULL;
    p.dynscope = parent->dynscope;
    return jsf_validate(aTHX_ C, off, data, &p);
}

/* probe that collects annotations into `ann` (for in-place applicators whose
 * successful branches contribute to the parent's evaluated set) */
static int jsf_probe_ann(pTHX_ jsf_compiled_t *C, uint32_t off, SV *data, jsf_ctx_t *parent, jsf_annot *ann) {
    jsf_ctx_t p;
    p.errors = NULL; p.iloc = NULL; p.collect = 0; p.depth = parent->depth; p.ann = ann;
    p.dynscope = parent->dynscope;
    return jsf_validate(aTHX_ C, off, data, &p);
}

#define JSF_FAIL(kw) do { \
    if (ctx->errors) jsf_err_push(aTHX_ ctx, C, off, (kw)); \
    ok = 0; if (!ctx->collect) goto done; \
} while (0)

/* recurse into a data child (a new instance): keep the instanceLocation in sync
 * and give the child its own annotation collector. */
#define JSF_CHILD(coff, cdata, pushexpr) do { \
    STRLEN _sav = 0; int _r; jsf_annot *_oa = ctx->ann; \
    if (ctx->errors) _sav = (pushexpr); \
    ctx->ann = C->has_unevaluated ? jsf_annot_new(aTHX) : NULL; \
    _r = jsf_validate(aTHX_ C, (coff), (cdata), ctx); \
    if (ctx->ann) jsf_annot_free(aTHX_ ctx->ann); \
    ctx->ann = _oa; \
    if (ctx->errors) jsf_iloc_pop(ctx->iloc, _sav); \
    if (!_r) { ok = 0; if (!ctx->collect) goto done; } \
} while (0)

static int jsf_validate(pTHX_ jsf_compiled_t *C, uint32_t off, SV *data, jsf_ctx_t *ctx) {
    jsf_arena_t *a = C->arena;
    jsf_node_t *n = (jsf_node_t *)jsf_arena_ptr(a, off);
    unsigned t;
    int ok = 1;
    HV *filled = NULL;   /* apply_defaults working copy (freed at done) */
    jsf_annot *sink = NULL, *local = NULL;   /* evaluated-set (unevaluated*) */
    int pushed_dyn = 0;  /* pushed this resource's base onto the dynamic scope */

    if (n->tag == JSF_TAG_TRUE)  return 1;
    if (n->tag == JSF_TAG_FALSE) { if (ctx->errors) jsf_err_push(aTHX_ ctx, C, off, "false"); return 0; }
    if (++ctx->depth > JSF_MAX_DEPTH) { ctx->depth--; return 0; }

    /* This frame collects its own evaluated set (from its keywords and its
     * in-place applicators); on success it merges into the caller's set (sink).
     * A sibling ("cousin") subschema therefore does not see it. */
    sink = ctx->ann;
    if (C->has_unevaluated) { local = jsf_annot_new(aTHX); ctx->ann = local; }

    /* track the dynamic scope: push this node's resource base when it differs
     * from the current innermost, so $dynamicRef can search it. */
    if (C->has_dynamic && ctx->dynscope) {
        uint32_t bl2; const char *bp2 = jsf_str_bytes(a, n->base_off, &bl2);
        SSize_t top = av_len(ctx->dynscope); int same = 0;
        if (top >= 0) { SV **tp = av_fetch(ctx->dynscope, top, 0);
            if (tp && *tp) { STRLEN tl; const char *ts = SvPV_const(*tp, tl); if (tl == bl2 && memEQ(ts, bp2, bl2)) same = 1; } }
        if (!same) { av_push(ctx->dynscope, newSVpvn(bp2, bl2)); pushed_dyn = 1; }
    }

    if ((n->present & JSF_HAS_REF) && n->ref_off) {
        if (!jsf_validate(aTHX_ C, n->ref_off, data, ctx)) { ok = 0; if (!ctx->collect) goto done; }
    }
    /* $dynamicRef: outermost matching $dynamicAnchor in the dynamic scope wins;
     * otherwise fall back to the lexical target (ref_off). */
    if (n->present & JSF_HAS_DYNREF) {
        uint32_t target = n->ref_off;
        if (ctx->dynscope && n->dynref_name_off) {
            uint32_t nml; const char *nm = jsf_str_bytes(a, n->dynref_name_off, &nml);
            SSize_t i, top = av_len(ctx->dynscope);
            for (i = 0; i <= top; i++) {
                SV **b = av_fetch(ctx->dynscope, i, 0);
                SV *key; STRLEN kl; const char *kp; SV **te;
                if (!b || !*b) continue;
                key = sv_2mortal(newSVsv(*b)); sv_catpvs(key, "#"); sv_catpvn(key, nm, nml);
                kp = SvPV_const(key, kl);
                te = hv_fetch(C->dynmap, kp, (I32)kl, 0);
                if (te && *te && SvIOK(*te)) { target = (uint32_t)SvIV(*te); break; }
            }
        }
        if (target && !jsf_validate(aTHX_ C, target, data, ctx)) { ok = 0; if (!ctx->collect) goto done; }
    }

    t = jsf_classify_type(aTHX_ data);
    if (C->coerce && (n->present & JSF_HAS_TYPE) && !(t & n->type_mask))
        t |= jsf_coerce_bits(aTHX_ n->type_mask, data, t);

    /* the validation vocabulary (type/const/enum, the numeric/string/count
     * keywords) is skipped when a custom $schema metaschema disables it. */
    if (!C->no_validation_vocab) {

    if ((n->present & JSF_HAS_TYPE) && !(t & n->type_mask)) JSF_FAIL("type");

    if (n->present & JSF_HAS_CONST) {
        SV **cv = av_fetch(C->keep, n->const_keep, 0);
        if (!cv || !jsf_json_equal(aTHX_ data, *cv)) JSF_FAIL("const");
    }
    if (n->present & JSF_HAS_ENUM) {
        int found = 0; uint32_t i;
        for (i = 0; i < n->enum_n; i++) {
            SV **ev = av_fetch(C->keep, n->enum_keep + i, 0);
            if (ev && jsf_json_equal(aTHX_ data, *ev)) { found = 1; break; }
        }
        if (!found) JSF_FAIL("enum");
    }

    if (t & JSF_T_NUMBER) {
        NV x = SvNV(data);
        if ((n->present & JSF_HAS_MIN)   && x <  n->minimum) JSF_FAIL("minimum");
        if ((n->present & JSF_HAS_MAX)   && x >  n->maximum) JSF_FAIL("maximum");
        if ((n->present & JSF_HAS_EXMIN) && x <= n->exmin)   JSF_FAIL("exclusiveMinimum");
        if ((n->present & JSF_HAS_EXMAX) && x >= n->exmax)   JSF_FAIL("exclusiveMaximum");
        if (n->present & JSF_HAS_MULOF) {
            NV m = n->mulof;
            if (m != 0.0) {
                NV eps = 1e-9 * (fabs(m) > 1.0 ? fabs(m) : 1.0), r = fmod(x, m);
                if (fabs(r) > eps && fabs(fabs(r) - fabs(m)) > eps) JSF_FAIL("multipleOf");
            }
        }
    }

    if (t & JSF_T_STRING) {
        if (n->present & (JSF_HAS_MINLEN | JSF_HAS_MAXLEN)) {
            UV len = (UV)sv_len_utf8(data);
            if ((n->present & JSF_HAS_MINLEN) && len < n->min_length) JSF_FAIL("minLength");
            if ((n->present & JSF_HAS_MAXLEN) && len > n->max_length) JSF_FAIL("maxLength");
        }
        if ((n->present & JSF_HAS_PATTERN) &&
            !jsf_rx_match(aTHX_ jsf_get_regex(aTHX_ C, n->pattern_off), data)) JSF_FAIL("pattern");
    }

    }   /* end validation-vocabulary scalar keywords */

    if (t & JSF_T_ARRAY) {
        AV *av = (AV *)SvRV(data);
        SSize_t i, cnt = av_len(av) + 1;
        uint32_t prefn = 0;
        if ((n->present & JSF_HAS_MINITEMS) && (UV)cnt < n->min_items) JSF_FAIL("minItems");
        if ((n->present & JSF_HAS_MAXITEMS) && (UV)cnt > n->max_items) JSF_FAIL("maxItems");
        if (n->present & JSF_HAS_PREFIX) {
            jsf_offlist *ol = (jsf_offlist *)jsf_arena_ptr(a, n->prefix_off);
            uint32_t *offs = (uint32_t *)((char *)ol + sizeof(jsf_offlist));
            prefn = ol->n;
            for (i = 0; i < cnt && (uint32_t)i < prefn; i++) {
                SV **el = av_fetch(av, i, 0);
                jsf_annot_add_idx(aTHX_ ctx->ann, i);
                if (el) JSF_CHILD(offs[i], *el, jsf_iloc_push_idx(aTHX_ ctx->iloc, i));
            }
        }
        if (n->present & JSF_HAS_ITEMS) {
            for (i = (SSize_t)prefn; i < cnt; i++) {
                SV **el = av_fetch(av, i, 0);
                if (el) JSF_CHILD(n->items_off, *el, jsf_iloc_push_idx(aTHX_ ctx->iloc, i));
            }
            if (ctx->ann && cnt > (SSize_t)prefn) ctx->ann->all_items = 1;  /* items covers the tail */
        }
        if (n->unique) {
            for (i = 0; i < cnt; i++) {
                SSize_t j; SV **ei = av_fetch(av, i, 0);
                for (j = i + 1; j < cnt; j++) {
                    SV **ej = av_fetch(av, j, 0);
                    if (ei && ej && jsf_json_equal(aTHX_ *ei, *ej)) { JSF_FAIL("uniqueItems"); }
                }
            }
        }
        if (n->present & JSF_HAS_CONTAINS) {
            UV matched = 0, minc = (n->present & JSF_HAS_MINCONT) ? n->min_contains : 1;
            for (i = 0; i < cnt; i++) {
                SV **el = av_fetch(av, i, 0);
                if (el && jsf_probe(aTHX_ C, n->contains_off, *el, ctx)) { matched++; jsf_annot_add_idx(aTHX_ ctx->ann, i); }
            }
            if (matched < minc) JSF_FAIL("contains");
            if ((n->present & JSF_HAS_MAXCONT) && matched > n->max_contains) JSF_FAIL("maxContains");
        }
    }

    if (t & JSF_T_OBJECT) {
        HV *hv = (HV *)SvRV(data);
        jsf_proptab *pt = NULL; jsf_propent *en = NULL; char *base = a->base;

        /* apply_defaults: fill missing properties that have a `default` into a
         * shallow working copy (never the caller's data). Only allocates when
         * a defaulted property is actually absent. */
        if (C->apply_defaults && (n->present & JSF_HAS_PROPS)) {
            jsf_proptab *dpt = (jsf_proptab *)jsf_arena_ptr(a, n->props_off);
            jsf_propent *den = (jsf_propent *)((char *)dpt + sizeof(jsf_proptab));
            uint32_t p; int need = 0;
            for (p = 0; p < dpt->n && !need; p++) {
                jsf_node_t *ch = (jsf_node_t *)jsf_arena_ptr(a, den[p].child_off);
                if (ch->present & JSF_HAS_DEFAULT) {
                    uint32_t nl; const char *nm = jsf_str_bytes(a, den[p].name_off, &nl);
                    if (!hv_exists(hv, nm, (I32)nl)) need = 1;
                }
            }
            if (need) {
                for (p = 0; p < dpt->n; p++) {
                    jsf_node_t *ch = (jsf_node_t *)jsf_arena_ptr(a, den[p].child_off);
                    if (ch->present & JSF_HAS_DEFAULT) {
                        uint32_t nl; const char *nm = jsf_str_bytes(a, den[p].name_off, &nl);
                        if (!hv_exists(hv, nm, (I32)nl)) {
                            SV **dv = av_fetch(C->keep, ch->default_keep, 0);
                            (void)hv_store(hv, nm, (I32)nl, newSVsv(dv ? *dv : &PL_sv_undef), 0);
                        }
                    }
                }
            }
        }

        if (n->present & JSF_HAS_PROPS) {
            uint32_t p;
            pt = (jsf_proptab *)jsf_arena_ptr(a, n->props_off);
            en = (jsf_propent *)((char *)pt + sizeof(jsf_proptab));
            for (p = 0; p < pt->n; p++) {
                uint32_t nl; const char *nm = jsf_str_bytes(a, en[p].name_off, &nl);
                SV **vp = (SV **)hv_common(hv, NULL, nm, nl, 0, HV_FETCH_JUST_SV, NULL, en[p].hash);
                if (vp && *vp) {
                    jsf_annot_add_key(aTHX_ ctx->ann, nm, nl);
                    JSF_CHILD(en[p].child_off, *vp, jsf_iloc_push_key(aTHX_ ctx->iloc, nm, nl));
                }
            }
        }
        if (n->present & (JSF_HAS_PATPROPS | JSF_HAS_ADDPROPS | JSF_HAS_PROPNAMES)) {
            HE *he; hv_iterinit(hv);
            while ((he = hv_iternext(hv))) {
                STRLEN kl; char *k = HePV(he, kl); SV *val = HeVAL(he);
                int matched = 0;
                if ((n->present & JSF_HAS_PROPS) && jsf_find_prop(pt, en, base, k, kl) >= 0) matched = 1;
                if (n->present & JSF_HAS_PATPROPS) {
                    jsf_pattab *qt = (jsf_pattab *)jsf_arena_ptr(a, n->patprops_off);
                    jsf_patent *pe = (jsf_patent *)((char *)qt + sizeof(jsf_pattab));
                    SV *ksv = sv_2mortal(newSVpvn(k, kl)); uint32_t q;
                    for (q = 0; q < qt->n; q++) {
                        if (jsf_rx_match(aTHX_ jsf_get_regex(aTHX_ C, pe[q].pat_off), ksv)) {
                            matched = 1;
                            jsf_annot_add_key(aTHX_ ctx->ann, k, kl);
                            JSF_CHILD(pe[q].child_off, val, jsf_iloc_push_key(aTHX_ ctx->iloc, k, kl));
                        }
                    }
                }
                if ((n->present & JSF_HAS_ADDPROPS) && !matched) {
                    if (n->addprops_off == JSF_NULL_OFF) {
                        STRLEN sav = 0;
                        if (ctx->errors) sav = jsf_iloc_push_key(aTHX_ ctx->iloc, k, kl);
                        JSF_FAIL("additionalProperties");
                        if (ctx->errors) jsf_iloc_pop(ctx->iloc, sav);
                    } else {
                        jsf_annot_add_key(aTHX_ ctx->ann, k, kl);
                        JSF_CHILD(n->addprops_off, val, jsf_iloc_push_key(aTHX_ ctx->iloc, k, kl));
                    }
                }
                if (n->present & JSF_HAS_PROPNAMES) {
                    SV *ksv = sv_2mortal(newSVpvn(k, kl));
                    if (!jsf_probe(aTHX_ C, n->propnames_off, ksv, ctx)) {
                        STRLEN sav = 0;
                        if (ctx->errors) sav = jsf_iloc_push_key(aTHX_ ctx->iloc, k, kl);
                        JSF_FAIL("propertyNames");
                        if (ctx->errors) jsf_iloc_pop(ctx->iloc, sav);
                    }
                }
            }
        }
        if ((n->present & JSF_HAS_MINPROPS) && (UV)HvKEYS(hv) < n->min_props) JSF_FAIL("minProperties");
        if ((n->present & JSF_HAS_MAXPROPS) && (UV)HvKEYS(hv) > n->max_props) JSF_FAIL("maxProperties");
        if (n->present & JSF_HAS_REQUIRED) {
            jsf_reqset *rs = (jsf_reqset *)jsf_arena_ptr(a, n->required_off);
            jsf_reqent *re = (jsf_reqent *)((char *)rs + sizeof(jsf_reqset));
            uint32_t r;
            for (r = 0; r < rs->n; r++) {
                uint32_t nl; const char *nm = jsf_str_bytes(a, re[r].name_off, &nl);
                if (!hv_exists(hv, nm, (I32)nl)) JSF_FAIL("required");
            }
        }
        if (n->present & JSF_HAS_DEPREQ) {
            jsf_deptab *dt = (jsf_deptab *)jsf_arena_ptr(a, n->depreq_off);
            jsf_depent *de = (jsf_depent *)((char *)dt + sizeof(jsf_deptab));
            uint32_t di;
            for (di = 0; di < dt->n; di++) {
                uint32_t nl; const char *nm = jsf_str_bytes(a, de[di].name_off, &nl);
                if (hv_exists(hv, nm, (I32)nl) && de[di].names_off) {
                    jsf_offlist *ol = (jsf_offlist *)jsf_arena_ptr(a, de[di].names_off);
                    uint32_t *offs = (uint32_t *)((char *)ol + sizeof(jsf_offlist)); uint32_t z;
                    for (z = 0; z < ol->n; z++) {
                        uint32_t rl; const char *rn = jsf_str_bytes(a, offs[z], &rl);
                        if (!hv_exists(hv, rn, (I32)rl)) JSF_FAIL("dependentRequired");
                    }
                }
            }
        }
        if (n->present & JSF_HAS_DEPSCHEMAS) {
            jsf_dstab *dt = (jsf_dstab *)jsf_arena_ptr(a, n->depsch_off);
            jsf_dsent *de = (jsf_dsent *)((char *)dt + sizeof(jsf_dstab));
            uint32_t di;
            for (di = 0; di < dt->n; di++) {
                uint32_t nl; const char *nm = jsf_str_bytes(a, de[di].name_off, &nl);
                if (hv_exists(hv, nm, (I32)nl) &&
                    !jsf_validate(aTHX_ C, de[di].sch_off, data, ctx)) { ok = 0; if (!ctx->collect) goto done; }
            }
        }
    }

    if (n->present & JSF_HAS_ALLOF) {
        jsf_offlist *ol = (jsf_offlist *)jsf_arena_ptr(a, n->allof_off);
        uint32_t *offs = (uint32_t *)((char *)ol + sizeof(jsf_offlist)); uint32_t i;
        for (i = 0; i < ol->n; i++)
            if (!jsf_validate(aTHX_ C, offs[i], data, ctx)) { ok = 0; if (!ctx->collect) goto done; }
    }
    /* anyOf: probe EVERY branch (no break); each successful branch merges its
     * evaluated set into this frame's set (jsf_probe_ann's frame merges into
     * ctx->ann on success). Collecting from all matches is required by spec. */
    if (n->present & JSF_HAS_ANYOF) {
        jsf_offlist *ol = (jsf_offlist *)jsf_arena_ptr(a, n->anyof_off);
        uint32_t *offs = (uint32_t *)((char *)ol + sizeof(jsf_offlist)); uint32_t i; int any = 0;
        for (i = 0; i < ol->n; i++)
            if (jsf_probe_ann(aTHX_ C, offs[i], data, ctx, ctx->ann)) any = 1;
        if (!any) JSF_FAIL("anyOf");
    }
    if (n->present & JSF_HAS_ONEOF) {
        jsf_offlist *ol = (jsf_offlist *)jsf_arena_ptr(a, n->oneof_off);
        uint32_t *offs = (uint32_t *)((char *)ol + sizeof(jsf_offlist)); uint32_t i, c2 = 0;
        for (i = 0; i < ol->n; i++)
            if (jsf_probe_ann(aTHX_ C, offs[i], data, ctx, ctx->ann)) c2++;
        if (c2 != 1) JSF_FAIL("oneOf");
    }
    if (n->present & JSF_HAS_NOT) {
        /* `not` discards its own annotations, but its internal unevaluated* must
         * still apply - jsf_probe gives it its own frame with no sink. */
        if (jsf_probe(aTHX_ C, n->not_off, data, ctx)) JSF_FAIL("not");
    }
    if (n->present & JSF_HAS_IF) {
        int branchok = 1;
        if (jsf_probe_ann(aTHX_ C, n->if_off, data, ctx, ctx->ann)) {
            if (n->then_off) branchok = jsf_validate(aTHX_ C, n->then_off, data, ctx);
        } else {
            if (n->else_off) branchok = jsf_validate(aTHX_ C, n->else_off, data, ctx);
        }
        if (!branchok) { ok = 0; if (!ctx->collect) goto done; }
    }

    /* unevaluated*: after every other keyword and in-place applicator, apply to
     * any property / item not in this instance's evaluated set. */
    if ((n->present & JSF_HAS_UNEVALPROPS) && (t & JSF_T_OBJECT)) {
        HV *hv = (HV *)SvRV(data); HE *he;
        hv_iterinit(hv);
        while ((he = hv_iternext(hv))) {
            STRLEN kl; char *k = HePV(he, kl); SV *val = HeVAL(he);
            if (ctx->ann && hv_exists(ctx->ann->props, k, kl)) continue;
            jsf_annot_add_key(aTHX_ ctx->ann, k, kl);
            JSF_CHILD(n->unevalprops_off, val, jsf_iloc_push_key(aTHX_ ctx->iloc, k, kl));
        }
    }
    if ((n->present & JSF_HAS_UNEVALITEMS) && (t & JSF_T_ARRAY)) {
        AV *av = (AV *)SvRV(data); SSize_t i, cnt = av_len(av) + 1;
        for (i = 0; i < cnt; i++) {
            SV **el;
            if (jsf_annot_has_idx(aTHX_ ctx->ann, i)) continue;
            el = av_fetch(av, i, 0);
            jsf_annot_add_idx(aTHX_ ctx->ann, i);
            if (el) JSF_CHILD(n->unevalitems_off, *el, jsf_iloc_push_idx(aTHX_ ctx->iloc, i));
        }
    }

done:
    if (filled) SvREFCNT_dec((SV *)filled);
    if (pushed_dyn) { SV *x = av_pop(ctx->dynscope); if (x) SvREFCNT_dec(x); }
    ctx->ann = sink;                                        /* restore caller's set */
    if (ok && sink && local) jsf_annot_merge(aTHX_ sink, local);
    if (local) jsf_annot_free(aTHX_ local);
    ctx->depth--;
    return ok;
}

#undef JSF_FAIL
#undef JSF_CHILD

static int jsf_run(pTHX_ jsf_compiled_t *C, SV *data, AV *errors) {
    jsf_ctx_t ctx;
    ctx.errors  = errors;
    ctx.collect = errors ? 1 : 0;
    ctx.depth   = 0;
    ctx.iloc    = errors ? sv_2mortal(newSVpvs("")) : NULL;
    ctx.ann     = NULL;   /* the root frame creates its own collector */
    ctx.dynscope = C->has_dynamic ? (AV *)sv_2mortal((SV *)newAV()) : NULL;
    return jsf_validate(aTHX_ C, C->root, data, &ctx);
}

static int jsf_is_valid(pTHX_ jsf_compiled_t *C, SV *data) {
    return jsf_run(aTHX_ C, data, NULL);
}

#endif /* JSF_INTERP_H */
