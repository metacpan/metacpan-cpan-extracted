#ifndef EX_OP_CALL_H
#define EX_OP_CALL_H

/* Needs MY_CXT, so it is included after START_MY_CXT. */

static XOP eo_xop_call;

static CV *
eo_cv_on_stack(pTHX_ SV *sv)
{
    if (SvTYPE(sv) == SVt_PVGV)
        return GvCVu((GV *)sv);
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV)
        return (CV *)SvRV(sv);
    if (SvTYPE(sv) == SVt_PVCV)
        return (CV *)sv;
    return NULL;
}

static I32
eo_ret_push(pTHX_ my_cxt_t *cxt)
{
    if (cxt->ret_top >= cxt->ret_max) {
        cxt->ret_max = cxt->ret_max ? cxt->ret_max * 2 : 16;
        Renew(cxt->ret, cxt->ret_max, eo_ret_t);
    }
    return cxt->ret_top++;
}

/* The nearest context block_gimme would read: a sub, an eval or a format,
 * on the current context stack. */
static I32
eo_gimme_cx(pTHX)
{
    I32 i;
    for (i = cxstack_ix; i >= 0; i--) {
        switch (CxTYPE(&cxstack[i])) {
        case CXt_SUB:
        case CXt_EVAL:
        case CXt_FORMAT:
            return i;
        default:
            break;
        }
    }
    return -1;
}

/* The context find_runcv would return the sub of: the first sub or format
 * that is not a regex code block, or a string eval. -1 when it is an eval or
 * there is none, and the call is then an ordinary one. */
static I32
eo_runcv_cx(pTHX)
{
    I32 i;
    for (i = cxstack_ix; i >= 0; i--) {
        const PERL_CONTEXT *cx = &cxstack[i];
        switch (CxTYPE(cx)) {
        case CXt_SUB:
        case CXt_FORMAT:
#ifdef CXp_SUB_RE
            if (cx->cx_type & CXp_SUB_RE)
                continue;
#endif
            return i;
        case CXt_EVAL:
            if (!CxTRYBLOCK(cx))
                return -1;
            break;
        default:
            break;
        }
    }
    return -1;
}

/* A parameter goes back to the state `my` leaves it in at the end of a
 * scope: emptied, or replaced when something else holds it. */
static void
eo_clear_param(pTHX_ SV **slot)
{
    SV *sv = *slot;
    if (SvREFCNT(sv) > 1 || SvMAGICAL(sv) || SvREADONLY(sv) || SvTYPE(sv) > SVt_PVMG) {
        SvREFCNT_dec(sv);
        *slot = newSV(0);
        SvPADMY_on(*slot);
    }
    else if (SvROK(sv)) {
        sv_unref_flags(sv, 0);
    }
    /* A plain value only the op can see is overwritten by the next call,
     * and clearing it would keep its string buffer anyway. */
}

/* Everything a sub frame would restore, in one save-stack entry. It runs
 * at the leave op's leave_scope, or when a die unwinds past the call. */
static void
eo_unwind(pTHX_ void *p)
{
    dMY_CXT;
    const I32 ri = (I32)PTR2IV(p);
    const eo_op_t *e = MY_CXT.ret[ri].e;
    eo_ret_t *rp;
    U16 i;

    for (i = 0; i < e->nparams; i++)
        eo_clear_param(aTHX_ &PL_curpad[e->params[i]]);

    /* A DESTROY run by clearing a parameter can call another op and grow
     * the records, which moves them: the record is taken again, by index. */
    rp = &MY_CXT.ret[ri];

    /* A context the call changed is put back only while it is still the
     * same one. Before 5.24 a die pops contexts before the save stack is
     * run, and its slot may be gone by now. */
    if (rp->cxix >= 0 && rp->cxix <= cxstack_ix)
        cxstack[rp->cxix].blk_gimme = rp->oldgimme;
    if (rp->spcx <= cxstack_ix)
        cxstack[rp->spcx].blk_oldsp = rp->oldsp;
    if (rp->runcx >= 0 && rp->runcx <= cxstack_ix
#if PERL_VERSION_GE(5,20,0) && !PERL_VERSION_GE(5,24,0)
        /* 5.20 and 5.22 run the save stack inside POPSUB, after it has read
         * the cv: the context is as good as popped. */
        && !(cxstack[rp->runcx].blk_u16 & CxPOPSUB_DONE)
#endif
        ) {
        cxstack[rp->runcx].blk_sub.cv = rp->oldruncv;
    }
#if !PERL_VERSION_GE(5,24,0)
    else if (rp->runcx >= 0) {
        /* Before 5.24 a die pops a sub context with POPSUB, and it popped
         * this one holding the op: it set the op's depth and released the
         * op instead of the caller, which was not in the sub already. */
        CvDEPTH(rp->oldruncv) = 0;
        SvREFCNT_inc_simple_void_NN(rp->cv);
        SvREFCNT_dec(rp->oldruncv);
    }
#endif
    PL_comppad    = rp->oldpad;
    PL_curpad     = rp->oldpad ? AvARRAY(rp->oldpad) : NULL;
    PL_curcop     = rp->oldcop;
    PL_curpm      = rp->oldpm;
    PL_tmps_floor = rp->oldfloor;
    CvDEPTH(rp->cv) = 0;
    MY_CXT.ret_top = ri;
    SvREFCNT_dec(rp->cv);
}

/* The call. The ops below it have pushed a mark, the arguments and the
 * sub, exactly as for entersub, so anything the fast path does not take
 * goes to pp_entersub with the stack as it found it. */
static OP *
eo_pp_call(pTHX)
{
    dSP;
    dMY_CXT;
    CV *cv = eo_cv_on_stack(aTHX_ TOPs);
    eo_op_t *e;
    eo_ret_t *r;
    I32 ri, markix, nargs, cxix = -1, runcx;
    bool top_is_sub;
    U8 gimme;
    U16 i;

    if (!cv || CvDEPTH(cv) || !(e = eo_op_live(aTHX_ cv))
        || (PERLDB_SUB && PL_DBsub))
        return PL_ppaddr[OP_ENTERSUB](aTHX);

    gimme = GIMME_V;

    if (cxstack_ix < 0)
        return PL_ppaddr[OP_ENTERSUB](aTHX);

    /* The usual caller is a plain sub: then it is the context both searches
     * below would find, and it is not an eval. */
    top_is_sub = CxTYPE(&cxstack[cxstack_ix]) == CXt_SUB
#ifdef CXp_SUB_RE
              && !(cxstack[cxstack_ix].cx_type & CXp_SUB_RE)
#endif
              ;

    /* An eval reads its stack base and context in die_unwind before it
     * runs the save stack, so a call must not change an eval's. */
    if (!top_is_sub && CxTYPE(&cxstack[cxstack_ix]) == CXt_EVAL)
        return PL_ppaddr[OP_ENTERSUB](aTHX);

    if (e->ctx_dep) {
        cxix = top_is_sub ? cxstack_ix : eo_gimme_cx(aTHX);
        if (cxix < 0 || CxTYPE(&cxstack[cxix]) == CXt_EVAL)
            return PL_ppaddr[OP_ENTERSUB](aTHX);
    }

    /* find_runcv names the variables in an uninitialised warning, and would
     * find the caller: for a body that could warn, the call lends it the op. */
    runcx = -1;
    if (e->need_runcv) {
        runcx = top_is_sub ? cxstack_ix : eo_runcv_cx(aTHX);
        if (runcx < 0)
            return PL_ppaddr[OP_ENTERSUB](aTHX);
#if !PERL_VERSION_GE(5,24,0)
        /* Before 5.24 a die pops a format, or a sub called again inside
         * itself, by the op it holds, and its depth cannot be put back. */
        if (CxTYPE(&cxstack[runcx]) != CXt_SUB || cxstack[runcx].blk_sub.olddepth)
            return PL_ppaddr[OP_ENTERSUB](aTHX);
#endif
    }

    markix = POPMARK;
    nargs = (I32)(SP - (PL_stack_base + markix + 1));

    ri = eo_ret_push(aTHX_ &MY_CXT);
    r = &MY_CXT.ret[ri];
    r->next      = PL_op->op_next;
    r->cv        = cv;
    r->e         = e;
    r->oldcop    = PL_curcop;
    r->oldpm     = PL_curpm;
    r->oldpad    = PL_comppad;
    r->oldfloor  = PL_tmps_floor;
    r->markix    = markix;
    r->gimme     = gimme;
    r->cxix      = cxix;
    r->targ      = PL_op->op_targ;
    if (cxix >= 0) {
        r->oldgimme = cxstack[cxix].blk_gimme;
        cxstack[cxix].blk_gimme = (cxstack[cxix].blk_gimme & ~G_WANT) | gimme;
    }
    r->runcx = runcx;
    if (runcx >= 0) {
        r->oldruncv = cxstack[runcx].blk_sub.cv;
        cxstack[runcx].blk_sub.cv = cv;
    }
    r->spcx  = cxstack_ix;
    r->oldsp = (I32)cxstack[cxstack_ix].blk_oldsp;
    cxstack[cxstack_ix].blk_oldsp = markix;

    SvREFCNT_inc_simple_void_NN(cv);
    CvDEPTH(cv) = 1;
    r->oldsaveix = PL_savestack_ix;
    SAVEDESTRUCTOR_X(eo_unwind, INT2PTR(void *, (IV)ri));
    r->afterix = PL_savestack_ix;
    PL_tmps_floor = PL_tmps_ix;

    PAD_SET_CUR_NOSAVE(CvPADLIST(cv), 1);
    /* A tied argument's FETCH may move the Perl stack: by index. */
    for (i = 0; i < e->nparams; i++)
        sv_setsv(PL_curpad[e->params[i]],
                 (I32)i < nargs ? PL_stack_base[markix + 1 + i] : &PL_sv_undef);

    SP = PL_stack_base + markix;
    PUTBACK;
    return e->entry;
}

/* The record of the frameless call this leave or return ends, or NULL for
 * a real call. A leave or a return in an op runs at the body's top level
 * (a return inside a loop or a block is declined), where the innermost
 * context is the one the call found. A real call has pushed its own. */
static eo_ret_t *
eo_frameless(pTHX_ my_cxt_t *cxt)
{
    eo_ret_t *r;
    if (!cxt->ret_top)
        return NULL;
    r = &cxt->ret[cxt->ret_top - 1];
    return cxstack_ix == r->spcx ? r : NULL;
}

static bool
eo_passes(SV *sv)
{
    return SvTEMP(sv) && SvREFCNT(sv) == 1 && !SvMAGICAL(sv);
}

/* Leave the call's scope. When the body left nothing on the save stack
 * above the call's own entry, that entry is taken off and run here, which
 * is what leave_scope would do, without the dispatch. */
static void
eo_leave_call(pTHX_ I32 ri, I32 saveix, I32 afterix)
{
    if (PL_savestack_ix == afterix) {
        PL_savestack_ix = saveix;
        eo_unwind(aTHX_ INT2PTR(void *, (IV)ri));
    }
    else {
        leave_scope(saveix);
    }
}

/* The end of a frameless call, with its values from the call's mark up to
 * sp, copied as leavesub copies them. Anything that runs during
 * leave_scope (a DESTROY) may move the Perl stack and the records, so
 * after it only indexes are used. */
static OP *
eo_finish(pTHX_ eo_ret_t *r, I32 ri, SV **sp)
{
    const I32 markix  = r->markix;
    const I32 saveix  = r->oldsaveix;
    const I32 afterix = r->afterix;
    const U8 gimme   = r->gimme;
    OP *next         = r->next;
    SV **mark        = PL_stack_base + markix;

    if (gimme == G_SCALAR) {
        SV *sv = sp > mark ? *sp : &PL_sv_undef;
        SV *result;
        bool in_targ = FALSE;

        if (SvIMMORTAL(sv)) {
            result = sv;
            FREETMPS;
        }
        else if (r->targ && !SvROK(sv) && SvTYPE(sv) <= SVt_PVMG && !eo_passes(sv)) {
            result = AvARRAY(r->oldpad)[r->targ];
            sv_setsv(result, sv);
            SvPADTMP_on(result);
            in_targ = TRUE;
            FREETMPS;
        }
        else {
            SvREFCNT_inc_simple_void_NN(sv);
            FREETMPS;
            if (eo_passes(sv)) {
                result = sv;
            }
            else {
                result = newSVsv(sv);
                SvREFCNT_dec(sv);
            }
        }

        PL_stack_sp = mark;
        eo_leave_call(aTHX_ ri, saveix, afterix);

        if (!in_targ && !SvIMMORTAL(result))
            sv_2mortal(result);
        sp = PL_stack_sp;
        EXTEND(sp, 1);
        *++sp = result;
        PL_stack_sp = sp;
    }
    else if (gimme == G_LIST) {
        const SSize_t n = sp - mark;
        SSize_t i;

        /* FREETMPS, a copy of a tied value and leave_scope can all run Perl
         * code that moves the stack, so the values are found by index. */
        PL_stack_sp = mark + n;
        for (i = 1; i <= n; i++)
            if (!SvIMMORTAL(PL_stack_base[markix + i]))
                SvREFCNT_inc_simple_void_NN(PL_stack_base[markix + i]);
        FREETMPS;
        for (i = 1; i <= n; i++) {
            SV *sv = PL_stack_base[markix + i];
            SV *copy;
            if (SvIMMORTAL(sv) || eo_passes(sv))
                continue;
            copy = newSVsv(sv);
            PL_stack_base[markix + i] = copy;
            SvREFCNT_dec(sv);
        }

        PL_stack_sp = PL_stack_base + markix + n;
        eo_leave_call(aTHX_ ri, saveix, afterix);

        for (i = 1; i <= n; i++)
            if (!SvIMMORTAL(PL_stack_base[markix + i]))
                sv_2mortal(PL_stack_base[markix + i]);
        PL_stack_sp = PL_stack_base + markix + n;
    }
    else {
        PL_stack_sp = mark;
        FREETMPS;
        eo_leave_call(aTHX_ ri, saveix, afterix);
        PL_stack_sp = PL_stack_base + markix;
    }

    return next;
}

/* The op's leavesub. */
static OP *
eo_pp_leave(pTHX)
{
    dMY_CXT;
    eo_ret_t *r = eo_frameless(aTHX_ &MY_CXT);

    if (!r || CvROOT(r->cv) != PL_op)
        return PL_ppaddr[OP_LEAVESUB](aTHX);
    return eo_finish(aTHX_ r, MY_CXT.ret_top - 1, PL_stack_sp);
}

/* A return in an op's body. Its values are above its own mark, and move
 * down to the call's. */
static OP *
eo_pp_return(pTHX)
{
    dMY_CXT;
    eo_ret_t *r = eo_frameless(aTHX_ &MY_CXT);
    SV **from, **to, **sp;

    if (!r)
        return PL_ppaddr[OP_RETURN](aTHX);

    from = PL_stack_base + POPMARK;
    to   = PL_stack_base + r->markix;
    sp   = PL_stack_sp;
    if (from != to) {
        while (from < sp)
            *++to = *++from;
        sp = to;
    }
    return eo_finish(aTHX_ r, MY_CXT.ret_top - 1, sp);
}

static void
eo_arm_returns(pTHX_ OP *o)
{
    for (; o; o = OpSIBLING(o)) {
        if (o->op_type == OP_RETURN)
            o->op_ppaddr = eo_pp_return;
        if (o->op_flags & OPf_KIDS)
            eo_arm_returns(aTHX_ cUNOPo->op_first);
    }
}

/* An entersub to a live op becomes the call op. Its kids are kept, so it
 * still pushes the sub, and any fallback is pp_entersub itself. */
static OP *
eo_convert_call(pTHX_ OP *o, CV *cv)
{
    if (o->op_type == OP_ENTERSUB
        && !(o->op_private & OPpENTERSUB_AMPER)
        && cv && eo_op_live(aTHX_ cv)) {
        o->op_type   = OP_CUSTOM;
        o->op_ppaddr = eo_pp_call;
#if PERL_VERSION_GE(5,16,0)
        if (!o->op_targ)
            o->op_targ = pad_alloc(OP_ENTERSUB, SVs_PADTMP);
#endif
    }
    return o;
}

#if !EO_CHECK_WRAP
static OP *
eo_ck_call(pTHX_ OP *o, GV *namegv, SV *ckobj)
{
    o = ck_entersub_args_proto_or_list(o, namegv, ckobj);
    return eo_convert_call(aTHX_ o, (CV *)ckobj);
}
#else
/* Before 5.14 there are no call checkers: entersub's own check is wrapped,
 * once for the process, and each call to a sub that is an op is found by
 * the sub its gv names. The wrapped check runs first, so core has applied
 * the prototype by then. */
static Perl_check_t eo_next_ck_entersub;

static CV *
eo_call_target(pTHX_ OP *o)
{
    OP *aop, *cvop = NULL, *k;
    SV *sv;

    if (!(o->op_flags & OPf_KIDS))
        return NULL;
    aop = cUNOPo->op_first;
    if (aop->op_type == OP_NULL && (aop->op_flags & OPf_KIDS) && !OpHAS_SIBLING(aop))
        aop = cUNOPx(aop)->op_first;
    for (k = aop; k; k = OpSIBLING(k))
        cvop = k;
    if (!cvop || !(cvop->op_type == OP_RV2CV || (cvop->op_type == OP_NULL && cvop->op_targ == OP_RV2CV))
        || !(cvop->op_flags & OPf_KIDS))
        return NULL;
    k = cUNOPx(cvop)->op_first;
    if (!k || k->op_type != OP_GV)
        return NULL;
    sv = (SV *)cGVOPx_gv(k);
    if (!sv)
        return NULL;
    if (isGV_with_GP(sv))
        return GvCVu((GV *)sv);
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV)
        return (CV *)SvRV(sv);
    return NULL;
}

static OP *
eo_ck_entersub(pTHX_ OP *o)
{
    o = eo_next_ck_entersub(aTHX_ o);
    return eo_convert_call(aTHX_ o, eo_call_target(aTHX_ o));
}

#  ifdef EO_TEST_HOOKS
static Perl_check_t eo_test_next_ck;
static IV eo_test_seen;
static OP *
eo_test_ck(pTHX_ OP *o)
{
    eo_test_seen++;
    return eo_test_next_ck(aTHX_ o);
}
#  endif
#endif

/* Called when registration accepts a sub. */
static void
eo_arm(pTHX_ CV *cv, eo_op_t *e)
{
    e->root->op_ppaddr = eo_pp_leave;
    if (e->has_return)
        eo_arm_returns(aTHX_ cUNOPx(e->root)->op_first);
#if !EO_CHECK_WRAP
    cv_set_call_checker(cv, eo_ck_call, (SV *)cv);
#else
    PERL_UNUSED_ARG(cv);
#endif
}

static void
eo_boot_ops(pTHX)
{
    XopENTRY_set(&eo_xop_call, xop_name,  "exop_call");
    XopENTRY_set(&eo_xop_call, xop_desc,  "Ex::Op call");
    XopENTRY_set(&eo_xop_call, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ eo_pp_call, &eo_xop_call);
#if EO_CHECK_WRAP
    if (!eo_next_ck_entersub)
        eo_wrap_check(OP_ENTERSUB, eo_ck_entersub, &eo_next_ck_entersub);
#endif
}

#endif
