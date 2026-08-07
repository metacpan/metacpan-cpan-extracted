#ifndef JSF_PARSE_H
#define JSF_PARSE_H

/* Schema SV -> arena IR. One jsf_node_t per subschema; children built into
 * local offset variables (never a held node pointer across an arena alloc,
 * per principle 9), then written into the parent by re-fetching it. $ref is
 * collected during the walk and resolved same-document in a second pass.
 *
 * Needs jsf_arena.h, jsf_ir.h, jsf_types.h, jsf_compiled.h + the Perl API. */

typedef struct jsf_pctx {
    jsf_compiled_t *C;
    HV             *path2off;   /* full URI string -> IV node offset */
    AV             *refreqs;    /* flat triples: node_off(IV), ref(PV), base(PV) */
    SV             *base;       /* current base URI (from the nearest $id scope) */
    SV             *resolver;   /* coderef: uri -> schema ref (remote docs), or undef */
    HV             *loaded;     /* document URIs already fetched */
    int             auto_fetch; /* fetch remote docs via Fetch when no resolver */
} jsf_pctx;

static uint32_t jsf_parse_schema(pTHX_ jsf_pctx *P, SV *schema, SV *path);

/* ---- small helpers ------------------------------------------------------ */

static uint32_t jsf__type_bit(pTHX_ SV *s) {
    STRLEN l; const char *p = SvPV_const(s, l);
    switch (l) {
        case 4: if (memEQ(p, "null", 4))    return JSF_T_NULL;    break;
        case 5: if (memEQ(p, "array", 5))   return JSF_T_ARRAY;   break;
        case 6: if (memEQ(p, "object", 6))  return JSF_T_OBJECT;
                if (memEQ(p, "string", 6))  return JSF_T_STRING;
                if (memEQ(p, "number", 6))  return JSF_T_NUMBER;  break;
        case 7: if (memEQ(p, "boolean", 7)) return JSF_T_BOOLEAN;
                if (memEQ(p, "integer", 7)) return JSF_T_INTEGER; break;
    }
    return 0;   /* unknown type name: ignored */
}

static uint32_t jsf__type_mask(pTHX_ SV *tv) {
    uint32_t m = 0;
    if (SvROK(tv) && SvTYPE(SvRV(tv)) == SVt_PVAV) {
        AV *av = (AV *)SvRV(tv);
        SSize_t i, n = av_len(av) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            if (e && *e) m |= jsf__type_bit(aTHX_ *e);
        }
    } else {
        m = jsf__type_bit(aTHX_ tv);
    }
    return m;
}

/* a JSON boolean object, or a bare truthy/falsey scalar used as a schema */
static int jsf__schema_is_bool(pTHX_ SV *s, int *val) {
    if (SvROK(s)) {
        if (SvOBJECT(SvRV(s)) && jsf__is_bool_class(aTHX_ s)) { *val = SvTRUE(s) ? 1 : 0; return 1; }
        return 0;   /* a ref (hash/array) is not a boolean schema */
    }
    *val = SvTRUE(s) ? 1 : 0;
    return 1;       /* bare scalar schema -> boolean by truthiness */
}

/* is this an object keyword we handle, or a benign annotation? otherwise it is
 * "unsupported" (recorded for the conformance skip list). */
static int jsf__recognised(const char *k, STRLEN l) {
    static const char *const ok[] = {
        /* matrix */
        "type","enum","const","minimum","maximum","exclusiveMinimum",
        "exclusiveMaximum","multipleOf","minLength","maxLength","pattern",
        "format","items","prefixItems","minItems","maxItems","uniqueItems",
        "contains","minContains","maxContains","properties","patternProperties",
        "additionalProperties","required","minProperties","maxProperties",
        "propertyNames","dependentRequired","dependentSchemas","allOf","anyOf",
        "oneOf","not","if","then","else","$ref","$defs",
        "unevaluatedProperties","unevaluatedItems","$dynamicRef","$dynamicAnchor",
        /* benign annotations / identifiers */
        "$schema","$id","$anchor","$comment","$vocabulary","title","description",
        "default","examples","deprecated","readOnly","writeOnly","example",
        "contentMediaType","contentEncoding","contentSchema","definitions",
        NULL
    };
    int i;
    for (i = 0; ok[i]; i++)
        if ((STRLEN)strlen(ok[i]) == l && memEQ(k, ok[i], l)) return 1;
    return 0;
}

static int jsf__cmp_propent(char *base, const jsf_propent *a, const jsf_propent *b) {
    const char *sa = base + a->name_off + sizeof(jsf_str_t);
    const char *sb = base + b->name_off + sizeof(jsf_str_t);
    uint32_t la = a->name_len, lb = b->name_len, m = la < lb ? la : lb;
    int c = memcmp(sa, sb, m);
    if (c) return c;
    return la < lb ? -1 : (la > lb ? 1 : 0);
}

/* child path = parent + "/" + seg (+ optional "/" + name). No pointer escaping
 * in v0.01 (names with '/' or '~' are a documented limitation). */
static SV *jsf__child_path(pTHX_ SV *path, const char *seg, const char *name, STRLEN nlen) {
    SV *cp = sv_2mortal(newSVsv(path));
    sv_catpvs(cp, "/");
    sv_catpv(cp, seg);
    if (name) { sv_catpvs(cp, "/"); sv_catpvn(cp, name, nlen); }
    return cp;
}

/* ---- block builders (each returns an arena offset) ---------------------- */

static uint32_t jsf__build_props(pTHX_ jsf_pctx *P, SV *pv, SV *path) {
    jsf_arena_t *a = P->C->arena;
    HV *h = (HV *)SvRV(pv);
    I32 nk = hv_iterinit(h);
    jsf_propent *tmp = (jsf_propent *)malloc(sizeof(jsf_propent) * (nk > 0 ? nk : 1));
    uint32_t cnt = 0, off, i, j;
    jsf_proptab *pt;
    HE *he;
    char *base;
    jsf_propent key;
    if (!tmp) croak("oom");
    while ((he = hv_iternext(h))) {
        STRLEN kl; char *k = HePV(he, kl);
        SV *cpath = jsf__child_path(aTHX_ path, "properties", k, kl);
        uint32_t child_off = jsf_parse_schema(aTHX_ P, HeVAL(he), cpath);
        uint32_t name_off  = jsf_arena_intern(a, k, (uint32_t)kl);
        U32 hh; PERL_HASH(hh, k, kl);
        tmp[cnt].name_off = name_off; tmp[cnt].child_off = child_off;
        tmp[cnt].hash = hh; tmp[cnt].name_len = (uint32_t)kl;
        cnt++;
    }
    /* insertion sort by name (deterministic order + bsearch); base is stable
     * here because interning is done and we alloc the block afterwards. */
    base = a->base;
    for (i = 1; i < cnt; i++) {
        key = tmp[i]; j = i;
        while (j > 0 && jsf__cmp_propent(base, &tmp[j - 1], &key) > 0) { tmp[j] = tmp[j - 1]; j--; }
        tmp[j] = key;
    }
    off = jsf_arena_alloc(a, (uint32_t)(sizeof(jsf_proptab) + cnt * sizeof(jsf_propent)), JSF_ALIGNOF(jsf_propent));
    pt = (jsf_proptab *)jsf_arena_ptr(a, off);
    pt->n = cnt;
    if (cnt) memcpy((char *)pt + sizeof(jsf_proptab), tmp, cnt * sizeof(jsf_propent));
    free(tmp);
    return off;
}

static uint32_t jsf__build_reqset(pTHX_ jsf_pctx *P, SV *rv, uint32_t props_off) {
    jsf_arena_t *a = P->C->arena;
    AV *av = (AV *)SvRV(rv);
    SSize_t i, n = av_len(av) + 1;
    jsf_reqent *tmp = (jsf_reqent *)malloc(sizeof(jsf_reqent) * (n > 0 ? n : 1));
    uint32_t off; jsf_reqset *rs;
    if (!tmp) croak("oom");
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        STRLEN kl; const char *k = (e && *e) ? SvPV_const(*e, kl) : "";
        uint32_t name_off = jsf_arena_intern(a, k, (uint32_t)(e && *e ? kl : 0));
        uint32_t idx = JSF_NO_IDX;
        if (props_off != JSF_NULL_OFF) {
            jsf_proptab *pt = (jsf_proptab *)jsf_arena_ptr(a, props_off);
            jsf_propent *en = (jsf_propent *)((char *)pt + sizeof(jsf_proptab));
            uint32_t p;
            for (p = 0; p < pt->n; p++) if (en[p].name_off == name_off) { idx = p; break; }
        }
        tmp[i].name_off = name_off; tmp[i].prop_idx = idx;
    }
    off = jsf_arena_alloc(a, (uint32_t)(sizeof(jsf_reqset) + n * sizeof(jsf_reqent)), JSF_ALIGNOF(jsf_reqent));
    rs = (jsf_reqset *)jsf_arena_ptr(a, off);
    rs->n = (uint32_t)n;
    if (n) memcpy((char *)rs + sizeof(jsf_reqset), tmp, n * sizeof(jsf_reqent));
    free(tmp);
    return off;
}

static uint32_t jsf__build_offlist(pTHX_ jsf_pctx *P, SV *av_sv, SV *path, const char *seg) {
    jsf_arena_t *a = P->C->arena;
    AV *av = (AV *)SvRV(av_sv);
    SSize_t i, n = av_len(av) + 1;
    uint32_t *tmp = (uint32_t *)malloc(sizeof(uint32_t) * (n > 0 ? n : 1));
    uint32_t off; jsf_offlist *ol;
    if (!tmp) croak("oom");
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        SV *cp = sv_2mortal(newSVsv(path));
        sv_catpvs(cp, "/"); sv_catpv(cp, seg);
        sv_catpvf(cp, "/%d", (int)i);
        tmp[i] = (e && *e) ? jsf_parse_schema(aTHX_ P, *e, cp) : JSF_NULL_OFF;
    }
    off = jsf_arena_alloc(a, (uint32_t)(sizeof(jsf_offlist) + n * sizeof(uint32_t)), JSF_ALIGNOF(uint32_t));
    ol = (jsf_offlist *)jsf_arena_ptr(a, off);
    ol->n = (uint32_t)n;
    if (n) memcpy((char *)ol + sizeof(jsf_offlist), tmp, n * sizeof(uint32_t));
    free(tmp);
    return off;
}

static uint32_t jsf__build_pattab(pTHX_ jsf_pctx *P, SV *pv, SV *path) {
    jsf_arena_t *a = P->C->arena;
    HV *h = (HV *)SvRV(pv);
    I32 nk = hv_iterinit(h);
    jsf_patent *tmp = (jsf_patent *)malloc(sizeof(jsf_patent) * (nk > 0 ? nk : 1));
    uint32_t cnt = 0, off; jsf_pattab *pt; HE *he;
    if (!tmp) croak("oom");
    while ((he = hv_iternext(h))) {
        STRLEN kl; char *k = HePV(he, kl);
        SV *cpath = jsf__child_path(aTHX_ path, "patternProperties", k, kl);
        uint32_t child_off = jsf_parse_schema(aTHX_ P, HeVAL(he), cpath);
        uint32_t pat_off   = jsf_arena_intern(a, k, (uint32_t)kl);
        tmp[cnt].pat_off = pat_off; tmp[cnt].child_off = child_off; cnt++;
    }
    off = jsf_arena_alloc(a, (uint32_t)(sizeof(jsf_pattab) + cnt * sizeof(jsf_patent)), JSF_ALIGNOF(jsf_patent));
    pt = (jsf_pattab *)jsf_arena_ptr(a, off);
    pt->n = cnt;
    if (cnt) memcpy((char *)pt + sizeof(jsf_pattab), tmp, cnt * sizeof(jsf_patent));
    free(tmp);
    return off;
}

/* a bare list of interned name offsets (for dependentRequired values) */
static uint32_t jsf__build_namelist(pTHX_ jsf_pctx *P, SV *av_sv) {
    jsf_arena_t *a = P->C->arena;
    AV *av = (AV *)SvRV(av_sv);
    SSize_t i, n = av_len(av) + 1;
    uint32_t *tmp = (uint32_t *)malloc(sizeof(uint32_t) * (n > 0 ? n : 1));
    uint32_t off; jsf_offlist *ol;
    if (!tmp) croak("oom");
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        STRLEN kl; const char *k = (e && *e) ? SvPV_const(*e, kl) : "";
        tmp[i] = jsf_arena_intern(a, k, (uint32_t)(e && *e ? kl : 0));
    }
    off = jsf_arena_alloc(a, (uint32_t)(sizeof(jsf_offlist) + n * sizeof(uint32_t)), JSF_ALIGNOF(uint32_t));
    ol = (jsf_offlist *)jsf_arena_ptr(a, off);
    ol->n = (uint32_t)n;
    if (n) memcpy((char *)ol + sizeof(jsf_offlist), tmp, n * sizeof(uint32_t));
    free(tmp);
    return off;
}

static uint32_t jsf__build_depsch(pTHX_ jsf_pctx *P, SV *pv, SV *path) {
    jsf_arena_t *a = P->C->arena;
    HV *h = (HV *)SvRV(pv);
    I32 nk = hv_iterinit(h);
    jsf_dsent *tmp = (jsf_dsent *)malloc(sizeof(jsf_dsent) * (nk > 0 ? nk : 1));
    uint32_t cnt = 0, off; jsf_dstab *dt; HE *he;
    if (!tmp) croak("oom");
    while ((he = hv_iternext(h))) {
        STRLEN kl; char *k = HePV(he, kl);
        SV *cpath = jsf__child_path(aTHX_ path, "dependentSchemas", k, kl);
        uint32_t sch = jsf_parse_schema(aTHX_ P, HeVAL(he), cpath);
        uint32_t name_off = jsf_arena_intern(a, k, (uint32_t)kl);
        tmp[cnt].name_off = name_off; tmp[cnt].sch_off = sch; cnt++;
    }
    off = jsf_arena_alloc(a, (uint32_t)(sizeof(jsf_dstab) + cnt * sizeof(jsf_dsent)), JSF_ALIGNOF(jsf_dsent));
    dt = (jsf_dstab *)jsf_arena_ptr(a, off);
    dt->n = cnt;
    if (cnt) memcpy((char *)dt + sizeof(jsf_dstab), tmp, cnt * sizeof(jsf_dsent));
    free(tmp);
    return off;
}

static uint32_t jsf__build_deptab(pTHX_ jsf_pctx *P, SV *pv) {
    jsf_arena_t *a = P->C->arena;
    HV *h = (HV *)SvRV(pv);
    I32 nk = hv_iterinit(h);
    jsf_depent *tmp = (jsf_depent *)malloc(sizeof(jsf_depent) * (nk > 0 ? nk : 1));
    uint32_t cnt = 0, off; jsf_deptab *dt; HE *he;
    if (!tmp) croak("oom");
    while ((he = hv_iternext(h))) {
        STRLEN kl; char *k = HePV(he, kl);
        SV *val = HeVAL(he);
        uint32_t names_off = (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV)
                             ? jsf__build_namelist(aTHX_ P, val) : JSF_NULL_OFF;
        uint32_t name_off  = jsf_arena_intern(a, k, (uint32_t)kl);
        tmp[cnt].name_off = name_off; tmp[cnt].names_off = names_off; cnt++;
    }
    off = jsf_arena_alloc(a, (uint32_t)(sizeof(jsf_deptab) + cnt * sizeof(jsf_depent)), JSF_ALIGNOF(jsf_depent));
    dt = (jsf_deptab *)jsf_arena_ptr(a, off);
    dt->n = cnt;
    if (cnt) memcpy((char *)dt + sizeof(jsf_deptab), tmp, cnt * sizeof(jsf_depent));
    free(tmp);
    return off;
}

/* ---- the node parser ---------------------------------------------------- */

static uint32_t jsf_parse_schema(pTHX_ jsf_pctx *P, SV *schema, SV *path) {
    jsf_arena_t *a = P->C->arena;
    uint32_t off = jsf_arena_alloc(a, (uint32_t)sizeof(jsf_node_t), JSF_ALIGNOF(jsf_node_t));
    HV *h;
    uint64_t present = 0;
    uint32_t type_mask = 0;
    uint8_t  unique = 0;
    /* local field accumulators */
    uint32_t enum_keep = 0, enum_n = 0, const_keep = 0, default_keep = 0;
    NV minimum=0, maximum=0, exmin=0, exmax=0, mulof=0;
    UV min_length=0, max_length=0, min_items=0, max_items=0;
    UV min_contains=0, max_contains=0, min_props=0, max_props=0;
    uint32_t pattern_off=0, format_off=0, items_off=0, prefix_off=0, contains_off=0;
    uint32_t props_off=0, patprops_off=0, addprops_off=0, required_off=0;
    uint32_t propnames_off=0, depreq_off=0, depsch_off=0;
    uint32_t allof_off=0, anyof_off=0, oneof_off=0, not_off=0;
    uint32_t if_off=0, then_off=0, else_off=0;
    uint32_t unevalprops_off=0, unevalitems_off=0;
    uint32_t dynref_name_off=0;
    uint8_t  tag = JSF_TAG_NORMAL;
    int bval;
    jsf_node_t *n;
    SV **e;
    SV *saved_base = NULL;   /* restored on the way out if $id opened a scope */

    if (off == JSF_NULL_OFF) croak("JSON::Schema::Fast: out of memory");

    /* $id opens a new base-URI scope (reset the base-relative pointer to "#" and
     * register the node under its bare $id); $anchor registers a named location;
     * every node is registered under its canonical URI (base + pointer). */
    if (SvROK(schema) && SvTYPE(SvRV(schema)) == SVt_PVHV) {
        HV *hh = (HV *)SvRV(schema);
        SV **idv = hv_fetchs(hh, "$id", 0), **anv;
        if (idv && *idv && SvPOK(*idv) && SvCUR(*idv)) {
            SV *resolved = jsf_uri_resolve(aTHX_ P->base, *idv);
            saved_base = P->base;
            P->base = jsf_uri_base_of(aTHX_ resolved);
            path = sv_2mortal(newSVpvs("#"));
            { SV *k = sv_2mortal(newSVsv(P->base)); (void)hv_store_ent(P->path2off, k, newSViv((IV)off), 0); }
        }
        { SV *k = sv_2mortal(newSVsv(P->base)); sv_catsv(k, path); (void)hv_store_ent(P->path2off, k, newSViv((IV)off), 0); }
        if ((anv = hv_fetchs(hh, "$anchor", 0)) && *anv && SvPOK(*anv)) {
            SV *k = sv_2mortal(newSVsv(P->base)); sv_catpvs(k, "#"); sv_catsv(k, *anv);
            (void)hv_store_ent(P->path2off, k, newSViv((IV)off), 0);
        }
        /* $dynamicAnchor registers as a plain anchor AND in the dynamic map */
        if ((anv = hv_fetchs(hh, "$dynamicAnchor", 0)) && *anv && SvPOK(*anv)) {
            SV *k1 = sv_2mortal(newSVsv(P->base)); sv_catpvs(k1, "#"); sv_catsv(k1, *anv);
            (void)hv_store_ent(P->path2off, k1, newSViv((IV)off), 0);
            { SV *k2 = sv_2mortal(newSVsv(P->base)); sv_catpvs(k2, "#"); sv_catsv(k2, *anv);
              (void)hv_store_ent(P->C->dynmap, k2, newSViv((IV)off), 0); }
            P->C->has_dynamic = 1;
        }
    } else {
        SV *k = sv_2mortal(newSVsv(P->base)); sv_catsv(k, path);
        (void)hv_store_ent(P->path2off, k, newSViv((IV)off), 0);
    }

    /* schemaLocation pointer (base-relative), minus the leading '#'. */
    {
        STRLEN pl; const char *pp = SvPV_const(path, pl);
        uint32_t sp = jsf_arena_intern(a, pl > 0 ? pp + 1 : pp,
                                       (uint32_t)(pl > 0 ? pl - 1 : 0));
        jsf_node_t *nn = (jsf_node_t *)jsf_arena_ptr(a, off);
        nn->schema_path_off = sp;
    }

    /* boolean / non-object schema */
    if (!(SvROK(schema) && SvTYPE(SvRV(schema)) == SVt_PVHV)) {
        if (jsf__schema_is_bool(aTHX_ schema, &bval)) {
            n = (jsf_node_t *)jsf_arena_ptr(a, off);
            n->tag = bval ? JSF_TAG_TRUE : JSF_TAG_FALSE;
            return off;
        }
        croak("JSON::Schema::Fast: schema must be a hashref or boolean");
    }

    h = (HV *)SvRV(schema);
    if (HvKEYS(h) == 0) {   /* {} == true */
        n = (jsf_node_t *)jsf_arena_ptr(a, off);
        n->tag = JSF_TAG_TRUE;
        return off;
    }

    /* count unsupported (out-of-matrix, non-annotation) keys */
    {
        HE *he; hv_iterinit(h);
        while ((he = hv_iternext(h))) {
            STRLEN kl; char *k = HePV(he, kl);
            if (!jsf__recognised(k, kl)) P->C->unsupported++;
        }
    }

    /* $defs first: build the definition subschemas so $ref can resolve them. */
    if ((e = hv_fetchs(h, "$defs", 0)) && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV) {
        HV *d = (HV *)SvRV(*e); HE *he; hv_iterinit(d);
        while ((he = hv_iternext(d))) {
            STRLEN kl; char *k = HePV(he, kl);
            SV *cp = jsf__child_path(aTHX_ path, "$defs", k, kl);
            (void)jsf_parse_schema(aTHX_ P, HeVAL(he), cp);
        }
    }

    if ((e = hv_fetchs(h, "type", 0)) && *e)        { type_mask = jsf__type_mask(aTHX_ *e); present |= JSF_HAS_TYPE; }
    if ((e = hv_fetchs(h, "enum", 0)) && *e && SvROK(*e) && SvTYPE(SvRV(*e))==SVt_PVAV) {
        AV *av = (AV *)SvRV(*e); SSize_t i, cnt = av_len(av) + 1;
        enum_n = (uint32_t)cnt; enum_keep = 0;
        for (i = 0; i < cnt; i++) {
            SV **v = av_fetch(av, i, 0);
            uint32_t idx = jsf_keep_push(aTHX_ P->C, (v && *v) ? *v : &PL_sv_undef);
            if (i == 0) enum_keep = idx;
        }
        present |= JSF_HAS_ENUM;
    }
    if ((e = hv_fetchs(h, "const", 0)) && *e)       { const_keep = jsf_keep_push(aTHX_ P->C, *e); present |= JSF_HAS_CONST; }
    if ((e = hv_fetchs(h, "default", 0)) && *e)     { default_keep = jsf_keep_push(aTHX_ P->C, *e); present |= JSF_HAS_DEFAULT; }

    if ((e = hv_fetchs(h, "minimum", 0)) && *e)          { minimum = SvNV(*e); present |= JSF_HAS_MIN; }
    if ((e = hv_fetchs(h, "maximum", 0)) && *e)          { maximum = SvNV(*e); present |= JSF_HAS_MAX; }
    if ((e = hv_fetchs(h, "exclusiveMinimum", 0)) && *e) { exmin = SvNV(*e); present |= JSF_HAS_EXMIN; }
    if ((e = hv_fetchs(h, "exclusiveMaximum", 0)) && *e) { exmax = SvNV(*e); present |= JSF_HAS_EXMAX; }
    if ((e = hv_fetchs(h, "multipleOf", 0)) && *e)       { mulof = SvNV(*e); present |= JSF_HAS_MULOF; }

    if ((e = hv_fetchs(h, "minLength", 0)) && *e) { min_length = SvUV(*e); present |= JSF_HAS_MINLEN; }
    if ((e = hv_fetchs(h, "maxLength", 0)) && *e) { max_length = SvUV(*e); present |= JSF_HAS_MAXLEN; }
    if ((e = hv_fetchs(h, "pattern", 0)) && *e)   { STRLEN l; const char *p = SvPV_const(*e, l); pattern_off = jsf_arena_intern(a, p, (uint32_t)l); present |= JSF_HAS_PATTERN; }
    if ((e = hv_fetchs(h, "format", 0)) && *e)    { STRLEN l; const char *p = SvPV_const(*e, l); format_off  = jsf_arena_intern(a, p, (uint32_t)l); present |= JSF_HAS_FORMAT; }

    if ((e = hv_fetchs(h, "items", 0)) && *e)      { items_off = jsf_parse_schema(aTHX_ P, *e, jsf__child_path(aTHX_ path, "items", NULL, 0)); present |= JSF_HAS_ITEMS; }
    if ((e = hv_fetchs(h, "prefixItems", 0)) && *e && SvROK(*e) && SvTYPE(SvRV(*e))==SVt_PVAV) { prefix_off = jsf__build_offlist(aTHX_ P, *e, path, "prefixItems"); present |= JSF_HAS_PREFIX; }
    if ((e = hv_fetchs(h, "minItems", 0)) && *e)   { min_items = SvUV(*e); present |= JSF_HAS_MINITEMS; }
    if ((e = hv_fetchs(h, "maxItems", 0)) && *e)   { max_items = SvUV(*e); present |= JSF_HAS_MAXITEMS; }
    if ((e = hv_fetchs(h, "uniqueItems", 0)) && *e && SvTRUE(*e)) { unique = 1; present |= JSF_HAS_UNIQUE; }
    if ((e = hv_fetchs(h, "contains", 0)) && *e)   { contains_off = jsf_parse_schema(aTHX_ P, *e, jsf__child_path(aTHX_ path, "contains", NULL, 0)); present |= JSF_HAS_CONTAINS; }
    if ((e = hv_fetchs(h, "minContains", 0)) && *e){ min_contains = SvUV(*e); present |= JSF_HAS_MINCONT; }
    if ((e = hv_fetchs(h, "maxContains", 0)) && *e){ max_contains = SvUV(*e); present |= JSF_HAS_MAXCONT; }

    if ((e = hv_fetchs(h, "properties", 0)) && *e && SvROK(*e) && SvTYPE(SvRV(*e))==SVt_PVHV) { props_off = jsf__build_props(aTHX_ P, *e, path); present |= JSF_HAS_PROPS; }
    if ((e = hv_fetchs(h, "patternProperties", 0)) && *e && SvROK(*e) && SvTYPE(SvRV(*e))==SVt_PVHV) { patprops_off = jsf__build_pattab(aTHX_ P, *e, path); present |= JSF_HAS_PATPROPS; }
    if ((e = hv_fetchs(h, "additionalProperties", 0)) && *e) {
        SV *ap = *e; int is_false = 0, b2;
        if (jsf__schema_is_bool(aTHX_ ap, &b2) && !SvROK(ap)) is_false = !b2;
        else if (SvROK(ap) && SvOBJECT(SvRV(ap)) && jsf__is_bool_class(aTHX_ ap)) is_false = !SvTRUE(ap);
        if (is_false) addprops_off = JSF_NULL_OFF;
        else          addprops_off = jsf_parse_schema(aTHX_ P, ap, jsf__child_path(aTHX_ path, "additionalProperties", NULL, 0));
        present |= JSF_HAS_ADDPROPS;
    }
    if ((e = hv_fetchs(h, "required", 0)) && *e && SvROK(*e) && SvTYPE(SvRV(*e))==SVt_PVAV) { required_off = jsf__build_reqset(aTHX_ P, *e, props_off); present |= JSF_HAS_REQUIRED; }
    if ((e = hv_fetchs(h, "minProperties", 0)) && *e) { min_props = SvUV(*e); present |= JSF_HAS_MINPROPS; }
    if ((e = hv_fetchs(h, "maxProperties", 0)) && *e) { max_props = SvUV(*e); present |= JSF_HAS_MAXPROPS; }
    if ((e = hv_fetchs(h, "propertyNames", 0)) && *e)  { propnames_off = jsf_parse_schema(aTHX_ P, *e, jsf__child_path(aTHX_ path, "propertyNames", NULL, 0)); present |= JSF_HAS_PROPNAMES; }
    if ((e = hv_fetchs(h, "dependentRequired", 0)) && *e && SvROK(*e) && SvTYPE(SvRV(*e))==SVt_PVHV) { depreq_off = jsf__build_deptab(aTHX_ P, *e); present |= JSF_HAS_DEPREQ; }
    if ((e = hv_fetchs(h, "dependentSchemas", 0)) && *e && SvROK(*e) && SvTYPE(SvRV(*e))==SVt_PVHV) { depsch_off = jsf__build_depsch(aTHX_ P, *e, path); present |= JSF_HAS_DEPSCHEMAS; }

    if ((e = hv_fetchs(h, "allOf", 0)) && *e && SvROK(*e) && SvTYPE(SvRV(*e))==SVt_PVAV) { allof_off = jsf__build_offlist(aTHX_ P, *e, path, "allOf"); present |= JSF_HAS_ALLOF; }
    if ((e = hv_fetchs(h, "anyOf", 0)) && *e && SvROK(*e) && SvTYPE(SvRV(*e))==SVt_PVAV) { anyof_off = jsf__build_offlist(aTHX_ P, *e, path, "anyOf"); present |= JSF_HAS_ANYOF; }
    if ((e = hv_fetchs(h, "oneOf", 0)) && *e && SvROK(*e) && SvTYPE(SvRV(*e))==SVt_PVAV) { oneof_off = jsf__build_offlist(aTHX_ P, *e, path, "oneOf"); present |= JSF_HAS_ONEOF; }
    if ((e = hv_fetchs(h, "unevaluatedProperties", 0)) && *e) { unevalprops_off = jsf_parse_schema(aTHX_ P, *e, jsf__child_path(aTHX_ path, "unevaluatedProperties", NULL, 0)); present |= JSF_HAS_UNEVALPROPS; P->C->has_unevaluated = 1; }
    if ((e = hv_fetchs(h, "unevaluatedItems", 0)) && *e)      { unevalitems_off = jsf_parse_schema(aTHX_ P, *e, jsf__child_path(aTHX_ path, "unevaluatedItems", NULL, 0)); present |= JSF_HAS_UNEVALITEMS; P->C->has_unevaluated = 1; }
    if ((e = hv_fetchs(h, "not", 0)) && *e)   { not_off = jsf_parse_schema(aTHX_ P, *e, jsf__child_path(aTHX_ path, "not", NULL, 0)); present |= JSF_HAS_NOT; }
    if ((e = hv_fetchs(h, "if", 0)) && *e)    { if_off = jsf_parse_schema(aTHX_ P, *e, jsf__child_path(aTHX_ path, "if", NULL, 0)); present |= JSF_HAS_IF; }
    if ((e = hv_fetchs(h, "then", 0)) && *e)  { then_off = jsf_parse_schema(aTHX_ P, *e, jsf__child_path(aTHX_ path, "then", NULL, 0)); }
    if ((e = hv_fetchs(h, "else", 0)) && *e)  { else_off = jsf_parse_schema(aTHX_ P, *e, jsf__child_path(aTHX_ path, "else", NULL, 0)); }

    if ((e = hv_fetchs(h, "$ref", 0)) && *e && SvPOK(*e)) {
        av_push(P->refreqs, newSViv((IV)off));
        av_push(P->refreqs, newSVsv(*e));
        av_push(P->refreqs, newSVsv(P->base));
        present |= JSF_HAS_REF;
    }
    /* $dynamicRef: lexical fallback resolves like $ref (into ref_off); the
     * fragment name drives the runtime dynamic-scope search. */
    if ((e = hv_fetchs(h, "$dynamicRef", 0)) && *e && SvPOK(*e)) {
        STRLEN dl; const char *dp = SvPV_const(*e, dl);
        const char *hh2 = (const char *)memchr(dp, '#', dl);
        av_push(P->refreqs, newSViv((IV)off));
        av_push(P->refreqs, newSVsv(*e));
        av_push(P->refreqs, newSVsv(P->base));
        if (hh2 && dp + dl - (hh2 + 1) > 0)
            dynref_name_off = jsf_arena_intern(a, hh2 + 1, (uint32_t)(dp + dl - (hh2 + 1)));
        present |= JSF_HAS_DYNREF;
        P->C->has_dynamic = 1;
    }

    /* fast-path tag */
    if      (present == 0)             tag = JSF_TAG_TRUE;
    else if (present == JSF_HAS_TYPE)  tag = JSF_TAG_TYPE_LEAF;
    else if (present == JSF_HAS_CONST) tag = JSF_TAG_CONST_LEAF;
    else if (present == JSF_HAS_ENUM)  tag = JSF_TAG_ENUM_LEAF;

    /* commit: fetch the node fresh (arena may have moved) and write it once.
     * intern the resource base URI first (interning may move the arena). */
    {
        uint32_t base_off = jsf_arena_intern(a, SvPVX(P->base), (uint32_t)SvCUR(P->base));
        n = (jsf_node_t *)jsf_arena_ptr(a, off);
        n->base_off = base_off;
        n->dynref_name_off = dynref_name_off;
    }
    n->present = present; n->type_mask = type_mask; n->tag = tag; n->unique = unique;
    n->enum_keep = enum_keep; n->enum_n = enum_n; n->const_keep = const_keep;
    n->default_keep = default_keep;
    n->minimum = minimum; n->maximum = maximum; n->exmin = exmin; n->exmax = exmax; n->mulof = mulof;
    n->min_length = min_length; n->max_length = max_length;
    n->pattern_off = pattern_off; n->format_off = format_off;
    n->items_off = items_off; n->prefix_off = prefix_off;
    n->min_items = min_items; n->max_items = max_items;
    n->contains_off = contains_off; n->min_contains = min_contains; n->max_contains = max_contains;
    n->props_off = props_off; n->patprops_off = patprops_off; n->addprops_off = addprops_off;
    n->required_off = required_off; n->min_props = min_props; n->max_props = max_props;
    n->propnames_off = propnames_off; n->depreq_off = depreq_off;
    n->depsch_off = depsch_off;
    n->allof_off = allof_off; n->anyof_off = anyof_off; n->oneof_off = oneof_off; n->not_off = not_off;
    n->if_off = if_off; n->then_off = then_off; n->else_off = else_off;
    n->unevalprops_off = unevalprops_off; n->unevalitems_off = unevalitems_off;
    if (saved_base) P->base = saved_base;   /* leave the $id scope */
    return off;
}

/* ---- $ref resolution (same-document) ------------------------------------ */

/* Decode a $ref fragment into the raw form path2off is keyed by: percent-decode
 * (URI fragment), then JSON Pointer unescape (~1 -> '/', ~0 -> '~'). Leaves a
 * plain "#/$defs/Foo" untouched. */
static int jsf__hexval(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}
static SV *jsf_ptr_decode(pTHX_ const char *s, STRLEN len) {
    SV *p1 = sv_2mortal(newSVpvn("", 0));
    SV *p2 = sv_2mortal(newSVpvn("", 0));
    STRLEN i, l2; const char *q;
    for (i = 0; i < len; ) {
        if (s[i] == '%' && i + 2 < len && jsf__hexval(s[i+1]) >= 0 && jsf__hexval(s[i+2]) >= 0) {
            char b = (char)((jsf__hexval(s[i+1]) << 4) | jsf__hexval(s[i+2]));
            sv_catpvn(p1, &b, 1); i += 3;
        } else { sv_catpvn(p1, s + i, 1); i++; }
    }
    q = SvPV_const(p1, l2);
    for (i = 0; i < l2; ) {
        if (q[i] == '~' && i + 1 < l2 && (q[i+1] == '0' || q[i+1] == '1')) {
            sv_catpvn(p2, q[i+1] == '1' ? "/" : "~", 1); i += 2;
        } else { sv_catpvn(p2, q + i, 1); i++; }
    }
    return p2;
}

/* Ask the resolver coderef for the schema document at `uri`; a returned ref is
 * used, anything else (undef) means "not available". Result is mortal. */
static SV *jsf_call_resolver(pTHX_ SV *resolver, const char *uri, STRLEN ulen) {
    dSP; int count; SV *ret = NULL;
    if (!resolver || !SvOK(resolver)) return NULL;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvn(uri, ulen)));
    PUTBACK;
    count = call_sv(resolver, G_SCALAR);
    SPAGAIN;
    if (count > 0) { SV *r = POPs; if (SvROK(r)) ret = newSVsv(r); }
    PUTBACK; FREETMPS; LEAVE;
    return ret ? sv_2mortal(ret) : NULL;
}

/* Resolve each $ref against its base URI (fragment percent/~-decoded), looking
 * the canonical URI up in the registry. When the target document has not been
 * loaded, fetch it via the resolver, parse it into the same arena (which may
 * append further refs), and retry. The refreqs array grows as documents load;
 * the loop consumes it to the end. */
static void jsf_resolve_refs(pTHX_ jsf_pctx *P) {
    SSize_t idx = 0;
    while (idx + 2 <= av_len(P->refreqs)) {
        SV **oe = av_fetch(P->refreqs, idx, 0);
        SV **pe = av_fetch(P->refreqs, idx + 1, 0);
        SV **be = av_fetch(P->refreqs, idx + 2, 0);
        uint32_t node_off = (uint32_t)SvIV(*oe);
        SV *ref_copy = sv_2mortal(newSVsv(*pe));           /* survives re-parse */
        SV *abs = jsf_uri_resolve(aTHX_ *be, *pe);
        STRLEN al; const char *ap = SvPV_const(abs, al);
        const char *hash = (const char *)memchr(ap, '#', al);
        SV *doc = sv_2mortal(newSVpvn(ap, hash ? (STRLEN)(hash - ap) : al));
        SV *key;
        SV **te;
        STRLEN kl; const char *kp;
        idx += 3;

        if (hash) {
            SV *frag = jsf_ptr_decode(aTHX_ hash + 1, al - (hash - ap) - 1);
            key = sv_2mortal(newSVpvn(ap, hash - ap));
            sv_catpvs(key, "#"); sv_catsv(key, frag);
        } else {
            key = sv_2mortal(newSVsv(abs));
        }
        kp = SvPV_const(key, kl);
        te = hv_fetch(P->path2off, kp, (I32)kl, 0);

        if (!(te && *te && SvIOK(*te))) {
            STRLEN dl; const char *dp = SvPV_const(doc, dl);
            if (dl && !hv_exists(P->loaded, dp, (I32)dl)) {
                SV *sub = NULL;
                (void)hv_store(P->loaded, dp, (I32)dl, &PL_sv_yes, 0);
                if (P->resolver) sub = jsf_call_resolver(aTHX_ P->resolver, dp, dl);
                if (!sub && P->auto_fetch) sub = jsf_fetch_uri(aTHX_ dp, dl);
                if (sub) {
                    SV *saved = P->base;
                    uint32_t root2;
                    P->base = sv_2mortal(newSVsv(doc));
                    root2 = jsf_parse_schema(aTHX_ P, sub, sv_2mortal(newSVpvs("#")));
                    P->base = saved;
                    /* register the retrieval URI (in case $id is absent/differs) */
                    { SV *k1 = sv_2mortal(newSVsv(doc)); (void)hv_store_ent(P->path2off, k1, newSViv((IV)root2), 0);
                      SV *k2 = sv_2mortal(newSVsv(doc)); sv_catpvs(k2, "#"); (void)hv_store_ent(P->path2off, k2, newSViv((IV)root2), 0); }
                    kp = SvPV_const(key, kl);                 /* key SV unchanged */
                    te = hv_fetch(P->path2off, kp, (I32)kl, 0);
                }
            }
        }

        if (te && *te && SvIOK(*te)) {
            jsf_node_t *nd = (jsf_node_t *)jsf_arena_ptr(P->C->arena, node_off);
            nd->ref_off = (uint32_t)SvIV(*te);
            /* $dynamicRef "bookend": the dynamic-scope search only applies when
             * the lexical target is itself the matching $dynamicAnchor; else it
             * is a plain $ref (clear the dynamic name so runtime uses ref_off). */
            if ((nd->present & JSF_HAS_DYNREF) && nd->dynref_name_off) {
                jsf_node_t *tgt = (jsf_node_t *)jsf_arena_ptr(P->C->arena, nd->ref_off);
                uint32_t nml; const char *nm = jsf_str_bytes(P->C->arena, nd->dynref_name_off, &nml);
                uint32_t tbl; const char *tb = jsf_str_bytes(P->C->arena, tgt->base_off, &tbl);
                SV *dk = sv_2mortal(newSVpvn(tb, tbl)); STRLEN dkl; const char *dkp;
                SV **de;
                sv_catpvs(dk, "#"); sv_catpvn(dk, nm, nml);
                dkp = SvPV_const(dk, dkl);
                de = hv_fetch(P->C->dynmap, dkp, (I32)dkl, 0);
                if (!(de && *de && SvIOK(*de) && (uint32_t)SvIV(*de) == nd->ref_off))
                    nd->dynref_name_off = 0;
            }
        } else {
            STRLEN rl; const char *rp = SvPV_const(ref_copy, rl);
            croak("JSON::Schema::Fast: cannot resolve $ref '%.*s'", (int)rl, rp);
        }
    }
}

/* ---- top-level compile -------------------------------------------------- */

static jsf_compiled_t *jsf_compile_sv(pTHX_ SV *schema, SV *resolver, int auto_fetch) {
    jsf_compiled_t *C = jsf_compiled_new(aTHX);
    jsf_pctx P;
    SV *root_path;
    if (!C) croak("JSON::Schema::Fast: out of memory");
    P.C = C;
    P.path2off = (HV *)sv_2mortal((SV *)newHV());
    P.refreqs  = (AV *)sv_2mortal((SV *)newAV());
    P.base     = sv_2mortal(newSVpvs(""));   /* default base URI */
    P.resolver = (resolver && SvOK(resolver)) ? resolver : NULL;
    P.loaded   = (HV *)sv_2mortal((SV *)newHV());
    P.auto_fetch = auto_fetch;
    root_path  = sv_2mortal(newSVpvs("#"));
    C->root = jsf_parse_schema(aTHX_ &P, schema, root_path);
    jsf_resolve_refs(aTHX_ &P);

    /* $schema: a custom metaschema whose $vocabulary omits (or disables) the
     * validation vocabulary turns the validation keywords into annotations. */
    if (SvROK(schema) && SvTYPE(SvRV(schema)) == SVt_PVHV) {
        SV **sc = hv_fetchs((HV *)SvRV(schema), "$schema", 0);
        if (sc && *sc && SvPOK(*sc)) {
            STRLEN sl; const char *sp = SvPV_const(*sc, sl);
            static const char *STD = "https://json-schema.org/draft/2020-12/schema";
            if (P.resolver && !(sl == strlen(STD) && memEQ(sp, STD, sl))) {
                SV *meta = jsf_call_resolver(aTHX_ P.resolver, sp, sl);
                if (meta && SvROK(meta) && SvTYPE(SvRV(meta)) == SVt_PVHV) {
                    SV **vv = hv_fetchs((HV *)SvRV(meta), "$vocabulary", 0);
                    if (vv && *vv && SvROK(*vv) && SvTYPE(SvRV(*vv)) == SVt_PVHV) {
                        static const char *VV = "https://json-schema.org/draft/2020-12/vocab/validation";
                        SV **val = hv_fetch((HV *)SvRV(*vv), VV, (I32)strlen(VV), 0);
                        if (!val || !*val || !SvTRUE(*val)) C->no_validation_vocab = 1;
                    }
                }
            }
        }
    }
    return C;
}

#endif /* JSF_PARSE_H */
