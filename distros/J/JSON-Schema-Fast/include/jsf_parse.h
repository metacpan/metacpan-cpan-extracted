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
    HV             *path2off;   /* JSON Pointer string -> IV node offset */
    AV             *refreqs;    /* flat: node_off(IV), pointer(PV), ... */
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
    off = jsf_arena_alloc(a, (uint32_t)(sizeof(jsf_proptab) + cnt * sizeof(jsf_propent)), 8);
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
    off = jsf_arena_alloc(a, (uint32_t)(sizeof(jsf_reqset) + n * sizeof(jsf_reqent)), 4);
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
    off = jsf_arena_alloc(a, (uint32_t)(sizeof(jsf_offlist) + n * sizeof(uint32_t)), 4);
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
    off = jsf_arena_alloc(a, (uint32_t)(sizeof(jsf_pattab) + cnt * sizeof(jsf_patent)), 4);
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
    off = jsf_arena_alloc(a, (uint32_t)(sizeof(jsf_offlist) + n * sizeof(uint32_t)), 4);
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
    off = jsf_arena_alloc(a, (uint32_t)(sizeof(jsf_dstab) + cnt * sizeof(jsf_dsent)), 4);
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
    off = jsf_arena_alloc(a, (uint32_t)(sizeof(jsf_deptab) + cnt * sizeof(jsf_depent)), 4);
    dt = (jsf_deptab *)jsf_arena_ptr(a, off);
    dt->n = cnt;
    if (cnt) memcpy((char *)dt + sizeof(jsf_deptab), tmp, cnt * sizeof(jsf_depent));
    free(tmp);
    return off;
}

/* ---- the node parser ---------------------------------------------------- */

static uint32_t jsf_parse_schema(pTHX_ jsf_pctx *P, SV *schema, SV *path) {
    jsf_arena_t *a = P->C->arena;
    uint32_t off = jsf_arena_alloc(a, (uint32_t)sizeof(jsf_node_t), 8);
    HV *h;
    U64 present = 0;
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
    uint8_t  tag = JSF_TAG_NORMAL;
    int bval;
    jsf_node_t *n;
    SV **e;

    if (off == JSF_NULL_OFF) croak("JSON::Schema::Fast: out of memory");
    (void)hv_store_ent(P->path2off, path, newSViv((IV)off), 0);

    /* remember this subschema's JSON Pointer (minus the leading '#') for the
     * schemaLocation of any error it raises. */
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
    if ((e = hv_fetchs(h, "not", 0)) && *e)   { not_off = jsf_parse_schema(aTHX_ P, *e, jsf__child_path(aTHX_ path, "not", NULL, 0)); present |= JSF_HAS_NOT; }
    if ((e = hv_fetchs(h, "if", 0)) && *e)    { if_off = jsf_parse_schema(aTHX_ P, *e, jsf__child_path(aTHX_ path, "if", NULL, 0)); present |= JSF_HAS_IF; }
    if ((e = hv_fetchs(h, "then", 0)) && *e)  { then_off = jsf_parse_schema(aTHX_ P, *e, jsf__child_path(aTHX_ path, "then", NULL, 0)); }
    if ((e = hv_fetchs(h, "else", 0)) && *e)  { else_off = jsf_parse_schema(aTHX_ P, *e, jsf__child_path(aTHX_ path, "else", NULL, 0)); }

    if ((e = hv_fetchs(h, "$ref", 0)) && *e && SvPOK(*e)) {
        av_push(P->refreqs, newSViv((IV)off));
        av_push(P->refreqs, newSVsv(*e));
        present |= JSF_HAS_REF;
    }

    /* fast-path tag */
    if      (present == 0)             tag = JSF_TAG_TRUE;
    else if (present == JSF_HAS_TYPE)  tag = JSF_TAG_TYPE_LEAF;
    else if (present == JSF_HAS_CONST) tag = JSF_TAG_CONST_LEAF;
    else if (present == JSF_HAS_ENUM)  tag = JSF_TAG_ENUM_LEAF;

    /* commit: fetch the node fresh (arena may have moved) and write it once */
    n = (jsf_node_t *)jsf_arena_ptr(a, off);
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

static void jsf_resolve_refs(pTHX_ jsf_pctx *P) {
    SSize_t i, n = av_len(P->refreqs) + 1;
    for (i = 0; i + 1 < n; i += 2) {
        SV **oe = av_fetch(P->refreqs, i, 0);
        SV **pe = av_fetch(P->refreqs, i + 1, 0);
        uint32_t node_off = (uint32_t)SvIV(*oe);
        STRLEN pl; const char *ptr = SvPV_const(*pe, pl);
        SV *dec = jsf_ptr_decode(aTHX_ ptr, pl);
        STRLEN dl; const char *dp = SvPV_const(dec, dl);
        SV **te = hv_fetch(P->path2off, dp, (I32)dl, 0);
        if (te && *te && SvIOK(*te)) {
            jsf_node_t *n = (jsf_node_t *)jsf_arena_ptr(P->C->arena, node_off);
            n->ref_off = (uint32_t)SvIV(*te);
        } else if (pl && ptr[0] == '#') {
            croak("JSON::Schema::Fast: unresolved $ref '%.*s'", (int)pl, ptr);
        } else {
            croak("JSON::Schema::Fast: remote $ref not supported in v0.01: '%.*s'", (int)pl, ptr);
        }
    }
}

/* ---- top-level compile -------------------------------------------------- */

static jsf_compiled_t *jsf_compile_sv(pTHX_ SV *schema) {
    jsf_compiled_t *C = jsf_compiled_new(aTHX);
    jsf_pctx P;
    SV *root_path;
    if (!C) croak("JSON::Schema::Fast: out of memory");
    P.C = C;
    P.path2off = (HV *)sv_2mortal((SV *)newHV());
    P.refreqs  = (AV *)sv_2mortal((SV *)newAV());
    root_path  = sv_2mortal(newSVpvs("#"));
    C->root = jsf_parse_schema(aTHX_ &P, schema, root_path);
    jsf_resolve_refs(aTHX_ &P);
    return C;
}

#endif /* JSF_PARSE_H */
