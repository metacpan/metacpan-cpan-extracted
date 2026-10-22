#ifndef EX_OP_REG_H
#define EX_OP_REG_H

static void eo_arm(pTHX_ CV *cv, eo_op_t *e);
static bool eo_tail_dep(OP *o);

static int
eo_mg_free(pTHX_ SV *sv, MAGIC *mg)
{
    eo_op_t *e = (eo_op_t *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (e) {
        Safefree(e->params);
        Safefree(e->why);
        Safefree(e);
        mg->mg_ptr = NULL;
    }
    return 0;
}

#ifdef USE_ITHREADS
static int
eo_mg_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param)
{
    eo_op_t *from = (eo_op_t *)mg->mg_ptr;
    eo_op_t *to;
    PERL_UNUSED_ARG(param);
    if (!from)
        return 0;
    Newx(to, 1, eo_op_t);
    StructCopy(from, to, eo_op_t);
    to->params = NULL;
    if (from->nparams) {
        Newx(to->params, from->nparams, PADOFFSET);
        Copy(from->params, to->params, from->nparams, PADOFFSET);
    }
    to->why = from->why ? savepv(from->why) : NULL;
    mg->mg_ptr = (char *)to;
    return 0;
}
#endif

static MGVTBL eo_op_vtbl = {
    NULL, NULL, NULL, NULL, eo_mg_free, NULL,
#ifdef USE_ITHREADS
    eo_mg_dup,
#else
    NULL,
#endif
    NULL
};

static eo_op_t *
eo_op_find(pTHX_ CV *cv)
{
    MAGIC *mg = mg_findext((SV *)cv, PERL_MAGIC_ext, &eo_op_vtbl);
    return mg ? (eo_op_t *)mg->mg_ptr : NULL;
}

/* An op whose sub has been redefined in place, or undefined, has a body
 * that is no longer the one registration looked at. */
static eo_op_t *
eo_op_live(pTHX_ CV *cv)
{
    eo_op_t *e = eo_op_find(aTHX_ cv);
    if (!e || !e->accepted || CvISXSUB(cv) || CvROOT(cv) != e->root)
        return NULL;
    return e;
}

static OP *
eo_kid(OP *o)
{
    return (o && (o->op_flags & OPf_KIDS)) ? cUNOPx(o)->op_first : NULL;
}

static bool
eo_is_type(OP *o, OPCODE type)
{
    return o && (o->op_type == type || (o->op_type == OP_NULL && o->op_targ == type));
}

static bool
eo_is_defgv(pTHX_ OP *o)
{
    return o && o->op_type == OP_GV && cGVOPx_gv(o) == PL_defgv;
}

typedef struct {
    const char *why;
    U32         loops;
    U32         unwind;
    bool        has_return;
    bool        ret_dep;
    bool        warns;
    OP         *skip;
} eo_walk_t;

/* Whether a statement could raise an "uninitialized" warning, whose message
 * names the variable by looking in the running sub's pad. With no lexical
 * warnings it depends on $^W, which can change at any time. */
static bool
eo_cop_warns_uninit(pTHX_ COP *cop)
{
    bool on;
    COP *was;
    if (cop->cop_warnings == pWARN_STD)
        return TRUE;
    if (cop->cop_warnings == pWARN_NONE)
        return FALSE;
    was = PL_curcop;
    PL_curcop = cop;
    on = ckWARN(WARN_UNINITIALIZED) ? TRUE : FALSE;
    PL_curcop = was;
    return on;
}

static bool
eo_is_context_op(OP *o)
{
    switch (o->op_type) {
    case OP_LEAVELOOP:
    case OP_LEAVE:
    case OP_LEAVETRY:
    case OP_GREPWHILE:
    case OP_MAPWHILE:
    case OP_SORT:
    case OP_LEAVEGIVEN:
    case OP_LEAVEWHEN:
#if PERL_VERSION_GE(5,34,0)
    case OP_LEAVETRYCATCH:
#endif
#if PERL_VERSION_GE(5,36,0)
    case OP_PUSHDEFER:
#endif
        return TRUE;
    default:
        return FALSE;
    }
}

static void eo_walk_list(pTHX_ eo_walk_t *w, OP *o);

static void
eo_walk_one(pTHX_ eo_walk_t *w, OP *o)
{
    if (o == w->skip)
        return;

    if ((o->op_type == OP_NEXTSTATE || o->op_type == OP_DBSTATE) && !w->warns
        && eo_cop_warns_uninit(aTHX_ (COP *)o))
        w->warns = TRUE;

    switch (o->op_type) {
    case OP_WANTARRAY:
        w->why = "it calls wantarray";
        return;
    case OP_CALLER:
        w->why = "it calls caller";
        return;
    case OP_GOTO:
    case OP_DUMP:
        w->why = "it uses goto";
        return;
    case OP_ENTEREVAL:
        w->why = "it uses a string eval";
        return;
#if PERL_VERSION_GE(5,16,0)
    case OP_RUNCV:
        w->why = "it uses __SUB__";
        return;
#endif
#if PERL_VERSION_GE(5,26,0)
    case OP_ARGCHECK:
        w->why = "it has a signature";
        return;
#endif
    case OP_RV2AV:
        if (eo_is_defgv(aTHX_ eo_kid(o))) {
            w->why = "it reads @_ after its parameters";
            return;
        }
        break;
    case OP_ANONCODE: {
        /* A closure is cloned with find_runcv, which reads the context
         * stack, so a frameless call would hand it the caller's pad. */
        CV *proto = (CV *)PAD_SVl(o->op_targ);
        if (proto && SvTYPE((SV *)proto) == SVt_PVCV && CvCLONE(proto)) {
            w->why = "it makes a closure over its own variables";
            return;
        }
        break;
    }
#ifdef PMf_HAS_CV
    case OP_QR:
        if (cPMOPo->op_pmflags & PMf_HAS_CV) {
            w->why = "it makes a qr with a code block";
            return;
        }
        break;
#endif
    case OP_SHIFT:
    case OP_POP:
        if (!(o->op_flags & OPf_KIDS)) {
            w->why = "it reads @_ after its parameters";
            return;
        }
        break;
    case OP_RV2GV:
        if (eo_is_defgv(aTHX_ eo_kid(o))) {
            w->why = "it uses *_";
            return;
        }
        break;
    case OP_AELEMFAST:
#if !PERL_VERSION_GE(5,16,0)
        if (o->op_flags & OPf_SPECIAL)
            break;
#endif
        if (cGVOPx_gv(o) == PL_defgv) {
            w->why = "it reads @_ after its parameters";
            return;
        }
        break;
    case OP_ENTERSUB:
        if (!(o->op_flags & OPf_STACKED)) {
            w->why = "it calls a sub as &name; which passes on @_";
            return;
        }
        break;
    case OP_RETURN:
        if (w->unwind) {
            w->why = "it returns from inside a loop or a block";
            return;
        }
        w->has_return = TRUE;
        {
            OP *k;
            for (k = eo_kid(o); k; k = OpSIBLING(k))
                if (k->op_type != OP_PUSHMARK && eo_tail_dep(k))
                    w->ret_dep = TRUE;
        }
        break;
    case OP_NEXT:
    case OP_LAST:
    case OP_REDO:
        if (!(o->op_flags & OPf_SPECIAL) || !w->loops) {
            w->why = "it leaves a loop it is not inside";
            return;
        }
        break;
    default:
        break;
    }

    if (o->op_flags & OPf_KIDS) {
        bool ctx  = eo_is_context_op(o);
        bool loop = o->op_type == OP_LEAVELOOP;
        if (ctx)
            w->unwind++;
        if (loop)
            w->loops++;
        eo_walk_list(aTHX_ w, cUNOPo->op_first);
        if (ctx)
            w->unwind--;
        if (loop)
            w->loops--;
    }
}

static void
eo_walk_list(pTHX_ eo_walk_t *w, OP *o)
{
    for (; o && !w->why; o = OpSIBLING(o))
        eo_walk_one(aTHX_ w, o);
}

static bool
eo_is_stmt(OP *o)
{
    return eo_is_type(o, OP_NEXTSTATE) || eo_is_type(o, OP_DBSTATE);
}

/* Whether an op in tail position takes its context at run time. The last
 * statement of a sub has none of its own: an op there with no want flag
 * asks block_gimme, which reads the nearest sub context. A frameless call
 * has none of its own, so it lends the call's context to the one it
 * finds. */
static bool
eo_tail_dep(OP *o)
{
    OP *k, *last;

    if (!o || (o->op_flags & OPf_WANT))
        return FALSE;

    switch (o->op_type) {
    case OP_NEXTSTATE:
    case OP_DBSTATE:
    case OP_RETURN:
        return FALSE;
    case OP_LINESEQ:
    case OP_SCOPE:
    case OP_LEAVE:
        last = NULL;
        for (k = eo_kid(o); k; k = OpSIBLING(k))
            if (!eo_is_stmt(k) && k->op_type != OP_ENTER)
                last = k;
        return eo_tail_dep(last);
    case OP_NULL:
        if (o->op_targ == OP_LINESEQ || o->op_targ == OP_SCOPE || o->op_targ == OP_LEAVE) {
            last = NULL;
            for (k = eo_kid(o); k; k = OpSIBLING(k))
                if (!eo_is_stmt(k) && k->op_type != OP_ENTER)
                    last = k;
            return eo_tail_dep(last);
        }
        for (k = eo_kid(o); k; k = OpSIBLING(k))
            if (eo_tail_dep(k))
                return TRUE;
        return FALSE;
    case OP_AND:
    case OP_OR:
    case OP_DOR:
    case OP_COND_EXPR:
        for (k = eo_kid(o); k; k = OpSIBLING(k))
            if (eo_tail_dep(k))
                return TRUE;
        return FALSE;
    default:
        return TRUE;
    }
}

/* `my ($a, $b, ...) = @_;` as the first statement. The tree keeps its shape
 * when padrange rewrites the execution order (5.18 on), so the tree is read,
 * not the order. Returns the aassign, or NULL when the first statement is
 * something else. */
static OP *
eo_find_binding(pTHX_ OP *body, PADOFFSET **params, U16 *nparams, const char **why)
{
    OP *stmt, *aassign, *rhs, *lhs, *k;
    U16 n = 0;

    *params = NULL;
    *nparams = 0;

    stmt = eo_kid(body);
    while (stmt && (eo_is_type(stmt, OP_NEXTSTATE) || eo_is_type(stmt, OP_DBSTATE)))
        stmt = OpSIBLING(stmt);
    if (!stmt || stmt->op_type != OP_AASSIGN)
        return NULL;
    aassign = stmt;

    rhs = eo_kid(aassign);
    lhs = rhs ? OpSIBLING(rhs) : NULL;
    if (!eo_is_type(rhs, OP_LIST) || !eo_is_type(lhs, OP_LIST))
        return NULL;

    k = eo_kid(rhs);
    if (!k || !(k->op_type == OP_PUSHMARK
#if PERL_VERSION_GE(5,18,0)
                || k->op_type == OP_PADRANGE
#endif
       ))
        return NULL;
    k = OpSIBLING(k);
    if (!k || k->op_type != OP_RV2AV || !eo_is_defgv(aTHX_ eo_kid(k)) || OpSIBLING(k))
        return NULL;

    k = eo_kid(lhs);
    if (!k || k->op_type != OP_PUSHMARK)
        return NULL;
    for (k = OpSIBLING(k); k; k = OpSIBLING(k)) {
        if (k->op_type == OP_PADSV && (k->op_private & OPpLVAL_INTRO)
#ifdef OPpPAD_STATE
            && !(k->op_private & OPpPAD_STATE)
#endif
           ) {
            n++;
            continue;
        }
        if (k->op_type == OP_PADAV || k->op_type == OP_PADHV)
            *why = "its parameters end in an array or a hash";
        else
            *why = "its first statement assigns @_ to something other than new scalars";
        return NULL;
    }
    if (!n)
        return NULL;

    Newx(*params, n, PADOFFSET);
    n = 0;
    for (k = OpSIBLING(eo_kid(lhs)); k; k = OpSIBLING(k))
        (*params)[n++] = k->op_targ;
    *nparams = n;
    return aassign;
}

/* Registers a CV and says whether it can run as an op. The answer is kept
 * on the CV whichever it is, so why_not can give the reason. */
static eo_op_t *
eo_register(pTHX_ CV *cv)
{
    eo_op_t *e;
    MAGIC *mg = mg_findext((SV *)cv, PERL_MAGIC_ext, &eo_op_vtbl);
    const char *why = NULL;

    if (mg && mg->mg_ptr) {
        e = (eo_op_t *)mg->mg_ptr;
        Safefree(e->params);
        Safefree(e->why);
        Zero(e, 1, eo_op_t);
    }
    else {
        Newxz(e, 1, eo_op_t);
    }

    if (CvISXSUB(cv) || !CvROOT(cv))
        why = "it is not a Perl sub with a body";
    else if (CvLVALUE(cv))
        why = "it is an lvalue sub";
    else if (CvROOT(cv)->op_type != OP_LEAVESUB)
        why = "its body does not end in an ordinary sub return";

    if (!why) {
        OP *body = eo_kid(CvROOT(cv));
        OP *binding;
        eo_walk_t w;
        Zero(&w, 1, eo_walk_t);

        ENTER;
        SAVECOMPPAD();
        PAD_SET_CUR_NOSAVE(CvPADLIST(cv), 1);

        binding = eo_find_binding(aTHX_ body, &e->params, &e->nparams, &why);
        if (!why) {
            w.skip = binding ? eo_kid(binding) : NULL;
            eo_walk_list(aTHX_ &w, body);
            why = w.why;
        }

        LEAVE;

        if (!why) {
            e->root       = CvROOT(cv);
            e->entry      = binding ? binding->op_next : CvSTART(cv);
            e->has_return = w.has_return;
            e->ctx_dep    = eo_tail_dep(body) || w.ret_dep;
            e->need_runcv = w.warns;
            e->accepted   = TRUE;
            eo_arm(aTHX_ cv, e);
        }
    }

    if (why)
        e->why = savepv(why);

    if (!mg) {
        mg = sv_magicext((SV *)cv, NULL, PERL_MAGIC_ext, &eo_op_vtbl, (const char *)e, 0);
#ifdef USE_ITHREADS
        mg->mg_flags |= MGf_DUP;
#endif
    }
    return e;
}

static bool
eo_strict_on(pTHX)
{
#if PERL_VERSION_GE(5,13,7)
    SV *v = cop_hints_fetch_pvs(PL_curcop, EO_STRICT_KEY, 0);
    return v && v != &PL_sv_placeholder && SvTRUE(v);
#else
    HV *hh = GvHV(PL_hintgv);
    SV **v = hh ? hv_fetchs(hh, EO_STRICT_KEY, 0) : NULL;
    return v && SvTRUE(*v);
#endif
}

static CV *
eo_code_arg(pTHX_ SV *code, const char *who)
{
    SvGETMAGIC(code);
    if (!SvROK(code) || SvTYPE(SvRV(code)) != SVt_PVCV)
        Perl_croak(aTHX_ "%s needs a code reference", who);
    return (CV *)SvRV(code);
}

#endif
