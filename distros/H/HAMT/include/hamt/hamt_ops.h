#ifndef HAMT_OPS_H
#define HAMT_OPS_H

/* The function forms of the reads: hamt_map_get($m, $k) and its kin. Each is
 * an ordinary XSUB, and where perl has call checkers (5.14 on) a call to one
 * that is resolved at compile time is rewritten into a custom op, so the read
 * costs no sub call. Both routes run the bodies below. */

#ifndef PERL_VERSION_GE
#  define PERL_VERSION_GE(r,v,s) \
      (PERL_REVISION > (r) || (PERL_REVISION == (r) && \
       (PERL_VERSION > (v) || (PERL_VERSION == (v) && PERL_SUBVERSION >= (s)))))
#endif

#if PERL_VERSION_GE(5,14,0)
#  define HAMT_HAS_OPS 1
#else
#  define HAMT_HAS_OPS 0
#endif

/* Each function lives in, and is exported by, the class it reads. */
static const char *const hamt_fn_names[] = {
    "hamt_map_get", "hamt_map_exists", "hamt_map_count",
    "hamt_set_has", "hamt_set_count",
    "hamt_vector_get", "hamt_vector_count"
};
#define HAMT_FN_COUNT 7

typedef struct { const char *pkg; int from, to; } hamt_fn_group;
static const hamt_fn_group hamt_fn_groups[3] = {
    { "HAMT::Map",    0, 3 },
    { "HAMT::Set",    3, 5 },
    { "HAMT::Vector", 5, 7 }
};
#define HAMT_FN_MAP    0
#define HAMT_FN_SET    1
#define HAMT_FN_VECTOR 2

static const char *hamt_fn_pkg(int i) {
    return hamt_fn_groups[i < 3 ? 0 : i < 5 ? 1 : 2].pkg;
}

/* The stored scalar itself, mortal, or a fresh undef: as the methods. */
static SV *hamt_fn_map_get(pTHX_ SV *self, SV *key) {
    hamt_map *m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "hamt_map_get", "map");
    hamt_key k;
    hamt_entry *e;
    hamt_key_from_sv(aTHX_ key, &k);
    e = hamt_map_find(m->root, k.p, (size_t)k.len, k.utf8, k.hash);
    return (e && e->val) ? sv_2mortal(SvREFCNT_inc_simple_NN((SV *)e->val))
                         : sv_newmortal();
}

static SV *hamt_fn_map_exists(pTHX_ SV *self, SV *key) {
    hamt_map *m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "hamt_map_exists", "map");
    hamt_key k;
    hamt_key_from_sv(aTHX_ key, &k);
    return boolSV(hamt_map_find(m->root, k.p, (size_t)k.len, k.utf8, k.hash) != NULL);
}

static SV *hamt_fn_set_has(pTHX_ SV *self, SV *key) {
    hamt_map *m = hamt_handle(aTHX_ self, &hamt_set_vtbl, "hamt_set_has", "set");
    hamt_key k;
    hamt_key_from_sv(aTHX_ key, &k);
    return boolSV(hamt_map_find(m->root, k.p, (size_t)k.len, k.utf8, k.hash) != NULL);
}

static SV *hamt_fn_vector_get(pTHX_ SV *self, SV *index) {
    hamt_vec *v = hamt_vec_handle(aTHX_ self, "hamt_vector_get");
    size_t i;
    return hamt_xs_index(aTHX_ index, v->count, &i)
         ? sv_2mortal(SvREFCNT_inc_simple_NN((SV *)hamt_vec_get(v, i)))
         : sv_newmortal();
}

static UV hamt_fn_map_count(pTHX_ SV *self) {
    return (UV)hamt_handle(aTHX_ self, &hamt_map_vtbl, "hamt_map_count", "map")->count;
}

static UV hamt_fn_set_count(pTHX_ SV *self) {
    return (UV)hamt_handle(aTHX_ self, &hamt_set_vtbl, "hamt_set_count", "set")->count;
}

static UV hamt_fn_vector_count(pTHX_ SV *self) {
    return (UV)hamt_vec_handle(aTHX_ self, "hamt_vector_count")->count;
}

/* Into the caller's package, as a glob assignment of a code reference, which
 * is what marks the name imported. */
static void hamt_fn_export(pTHX_ HV *stash, int i) {
    const char *name = hamt_fn_names[i];
    CV *cv = get_cv(form("%s::%s", hamt_fn_pkg(i), name), 0);
    SV **svp;
    if (!cv) croak("HAMT: %s is not built", name);
    svp = hv_fetch(stash, name, (I32)strlen(name), 1);
    if (!svp) croak("HAMT: cannot export %s", name);
    if (SvTYPE(*svp) != SVt_PVGV)
        gv_init((GV *)*svp, stash, name, (I32)strlen(name), GV_ADDMULTI);
    sv_setsv(*svp, sv_2mortal(newRV_inc((SV *)cv)));
}

/* The names asked of one class, or ":all" for every one it has. */
static void hamt_fn_import(pTHX_ int group, SV **want, I32 n) {
    const hamt_fn_group *g = &hamt_fn_groups[group];
    HV *stash = CopSTASH(PL_curcop);
    I32 i;
    int j;

    for (i = 0; i < n; i++) {
        const char *w = SvPV_nolen(want[i]);
        if (strEQ(w, ":all")) {
            for (j = g->from; j < g->to; j++) hamt_fn_export(aTHX_ stash, j);
            continue;
        }
        for (j = g->from; j < g->to; j++)
            if (strEQ(w, hamt_fn_names[j])) break;
        if (j == g->to) croak("%s does not export \"%s\"", g->pkg, w);
        hamt_fn_export(aTHX_ stash, j);
    }
}

#if HAMT_HAS_OPS

#ifndef OpHAS_SIBLING
#  define OpHAS_SIBLING(o)         ((o)->op_sibling != NULL)
#endif
#ifndef OpSIBLING
#  define OpSIBLING(o)             ((o)->op_sibling)
#endif
#ifndef OpMORESIB_set
#  define OpMORESIB_set(o, sib)    ((o)->op_sibling = (sib))
#endif
#ifndef OpLASTSIB_set
#  define OpLASTSIB_set(o, parent) ((o)->op_sibling = NULL)
#endif

/* The key may be an object that stringifies by running Perl. perl runs
 * overloading and tie methods on a stack of their own, so this one does not
 * move; the pointer is put back and read again all the same, which costs
 * two moves and does not depend on that staying true. */
#define HAMT_PP_KEYED(pp, fn)                                             \
static OP *pp(pTHX) {                                                     \
    dSP;                                                                  \
    SV *key  = POPs;                                                      \
    SV *self = TOPs;                                                      \
    SV *r;                                                                \
    PUTBACK;                                                              \
    r = fn(aTHX_ self, key);                                              \
    SPAGAIN;                                                              \
    SETs(r);                                                              \
    RETURN;                                                               \
}

/* A count is written into a scalar the op owns where perl lets an extension
 * have one, and into a temporary where it does not. pad_alloc is not
 * exported by 5.14; 5.20 is the oldest perl this has been built on with it. */
#if PERL_VERSION_GE(5,20,0)
#  define HAMT_OP_TARG(o) ((o)->op_targ = pad_alloc(OP_CUSTOM, SVs_PADTMP))
#  define HAMT_PP_COUNT(pp, fn)                                           \
static OP *pp(pTHX) {                                                     \
    dSP;                                                                  \
    dTARGET;                                                              \
    SV *self = TOPs;                                                      \
    sv_setuv(TARG, fn(aTHX_ self));                                       \
    SvSETMAGIC(TARG);                                                     \
    SETs(TARG);                                                           \
    RETURN;                                                               \
}
#else
#  define HAMT_OP_TARG(o) ((void)0)
#  define HAMT_PP_COUNT(pp, fn)                                           \
static OP *pp(pTHX) {                                                     \
    dSP;                                                                  \
    SV *self = TOPs;                                                      \
    SETs(sv_2mortal(newSVuv(fn(aTHX_ self))));                            \
    RETURN;                                                               \
}
#endif

HAMT_PP_KEYED(hamt_pp_map_get,      hamt_fn_map_get)
HAMT_PP_KEYED(hamt_pp_map_exists,   hamt_fn_map_exists)
HAMT_PP_KEYED(hamt_pp_set_has,      hamt_fn_set_has)
HAMT_PP_KEYED(hamt_pp_vector_get,   hamt_fn_vector_get)
HAMT_PP_COUNT(hamt_pp_map_count,    hamt_fn_map_count)
HAMT_PP_COUNT(hamt_pp_set_count,    hamt_fn_set_count)
HAMT_PP_COUNT(hamt_pp_vector_count, hamt_fn_vector_count)

/* The prototype is applied first, so the arguments are counted and in scalar
 * context whatever they are. Then they are lifted out of the call and made
 * the children of the op. Anything not shaped as expected is left a call. */
static OP *hamt_ck_rewrite(pTHX_ OP *o, GV *namegv, SV *ckobj,
                           Perl_ppaddr_t pp, int nargs) {
    OP *pushop, *a, *b = NULL, *cvop, *newop;

    o = ck_entersub_args_proto(o, namegv, ckobj);
    pushop = cUNOPx(o)->op_first;
    if (!OpHAS_SIBLING(pushop)) pushop = cUNOPx(pushop)->op_first;
    a = OpSIBLING(pushop);
    if (!a || !OpHAS_SIBLING(a)) return o;
    if (nargs == 2) {
        b = OpSIBLING(a);
        if (!OpHAS_SIBLING(b)) return o;
        cvop = OpSIBLING(b);
    }
    else {
        cvop = OpSIBLING(a);
    }
    if (OpHAS_SIBLING(cvop)) return o;

    OpMORESIB_set(pushop, cvop);
    if (b) OpLASTSIB_set(b, NULL);
    OpLASTSIB_set(a, NULL);
    newop = b ? newBINOP(OP_NULL, 0, a, b) : newUNOP(OP_NULL, 0, a);
    newop->op_type   = OP_CUSTOM;
    newop->op_ppaddr = pp;
    if (!b) HAMT_OP_TARG(newop);
    op_free(o);
    return newop;
}

#define HAMT_CK(ck, pp, nargs)                                            \
static OP *ck(pTHX_ OP *o, GV *namegv, SV *ckobj) {                       \
    return hamt_ck_rewrite(aTHX_ o, namegv, ckobj, pp, nargs);            \
}

HAMT_CK(hamt_ck_map_get,      hamt_pp_map_get,      2)
HAMT_CK(hamt_ck_map_exists,   hamt_pp_map_exists,   2)
HAMT_CK(hamt_ck_set_has,      hamt_pp_set_has,      2)
HAMT_CK(hamt_ck_vector_get,   hamt_pp_vector_get,   2)
HAMT_CK(hamt_ck_map_count,    hamt_pp_map_count,    1)
HAMT_CK(hamt_ck_set_count,    hamt_pp_set_count,    1)
HAMT_CK(hamt_ck_vector_count, hamt_pp_vector_count, 1)

static XOP hamt_xop[HAMT_FN_COUNT];

static void hamt_ops_one(pTHX_ int i, Perl_ppaddr_t pp, Perl_call_checker ck, U32 cls) {
    CV *cv = get_cv(form("%s::%s", hamt_fn_pkg(i), hamt_fn_names[i]), 0);
    XopENTRY_set(&hamt_xop[i], xop_name, hamt_fn_names[i]);
    XopENTRY_set(&hamt_xop[i], xop_desc, hamt_fn_names[i]);
    XopENTRY_set(&hamt_xop[i], xop_class, cls);
    Perl_custom_op_register(aTHX_ pp, &hamt_xop[i]);
    if (cv) cv_set_call_checker(cv, ck, (SV *)cv);
}

#endif

/* Once, after the XSUBs exist. */
static void hamt_ops_boot(pTHX) {
#if HAMT_HAS_OPS
    hamt_ops_one(aTHX_ 0, hamt_pp_map_get,      hamt_ck_map_get,      OA_BINOP);
    hamt_ops_one(aTHX_ 1, hamt_pp_map_exists,   hamt_ck_map_exists,   OA_BINOP);
    hamt_ops_one(aTHX_ 2, hamt_pp_map_count,    hamt_ck_map_count,    OA_UNOP);
    hamt_ops_one(aTHX_ 3, hamt_pp_set_has,      hamt_ck_set_has,      OA_BINOP);
    hamt_ops_one(aTHX_ 4, hamt_pp_set_count,    hamt_ck_set_count,    OA_UNOP);
    hamt_ops_one(aTHX_ 5, hamt_pp_vector_get,   hamt_ck_vector_get,   OA_BINOP);
    hamt_ops_one(aTHX_ 6, hamt_pp_vector_count, hamt_ck_vector_count, OA_UNOP);
#else
    PERL_UNUSED_CONTEXT;
#endif
}

#endif
