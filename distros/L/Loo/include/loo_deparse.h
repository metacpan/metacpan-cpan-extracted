#ifndef LOO_DEPARSE_H
#define LOO_DEPARSE_H

/* ── Backward-compat macros for older Perls ───────────────────── */

/* Padlist API: became a separate struct in 5.18; was an AV before.
   PadlistARRAY and PadlistNAMES are provided by perl from 5.18+. */
#ifndef PadlistARRAY
#  define PadlistARRAY(pl)   ((PAD **)AvARRAY((AV *)(pl)))
#endif
#ifndef PadlistNAMES
#  define PadlistNAMES(pl)   ((PADNAMELIST *)AvARRAY((AV *)(pl))[0])
#endif

/* PADNAMELIST / PADNAME: pre-5.18 these were plain AVs / SVs.
   The PadnamelistARRAY / PadnamelistMAX / PadnamePV / PadnameLEN
   macros appeared in 5.18; define compat versions for older Perls. */
#ifndef PadnamelistARRAY
#  define PadnamelistARRAY(pnl) AvARRAY((AV *)(pnl))
#endif
#ifndef PadnamelistMAX
#  define PadnamelistMAX(pnl)   AvFILLp((AV *)(pnl))
#endif

#if PERL_VERSION < 18
   typedef AV PADNAMELIST;
#endif

/* PADNAME was introduced in 5.22 as a struct; before that it was SV */
#ifndef PadnamePV
#  define PadnamePV(pn)  SvPVX((SV *)(pn))
#endif
#ifndef PadnameLEN
#  define PadnameLEN(pn) SvCUR((SV *)(pn))
#endif

/* PADNAME type: typedef'd as SV from 5.20; became a struct in 5.22 */
#if PERL_VERSION < 20
   typedef SV PADNAME;
#endif

/* OPpPADRANGE_COUNTMASK appeared in 5.18 */
#ifndef OPpPADRANGE_COUNTMASK
#  define OPpPADRANGE_COUNTMASK 127
#endif

/* ── Precedence levels ────────────────────────────────────────── */

typedef enum {
    LOO_PREC_LOWEST = 0,
    LOO_PREC_OR,
    LOO_PREC_AND,
    LOO_PREC_NOT,
    LOO_PREC_ASSIGN,
    LOO_PREC_TERNARY,
    LOO_PREC_OROR,
    LOO_PREC_ANDAND,
    LOO_PREC_BITOR,
    LOO_PREC_BITAND,
    LOO_PREC_EQUALITY,
    LOO_PREC_COMPARE,
    LOO_PREC_SHIFT,
    LOO_PREC_ADD,
    LOO_PREC_MUL,
    LOO_PREC_MATCH,
    LOO_PREC_UNARY,
    LOO_PREC_POW,
    LOO_PREC_PREFIX,
    LOO_PREC_ARROW,
    LOO_PREC_HIGHEST
} loo_prec_t;

/* ── Deparse context ──────────────────────────────────────────── */

typedef struct {
    DDCStyle   *style;
    SV         *out;
    int         indent;
    loo_prec_t  prec;
    CV         *cv;
    PADNAMELIST *padnames;
    int         last_was_block;
} DDCDeparse;

/* ── Forward declarations ─────────────────────────────────────── */

static void ddc_deparse_op(pTHX_ OP *o, DDCDeparse *ctx);

/* ── Helper: emit coloured tokens ─────────────────────────────── */

static void
ddc_emit_keyword(pTHX_ DDCDeparse *ctx, const char *kw, STRLEN len)
{
    if (ctx->style->use_colour) {
        ddc_colour_wrap(aTHX_ ctx->out,
            ctx->style->c_keyword_fg, ctx->style->c_keyword_bg,
            ctx->style->c_reset, kw, len);
    } else {
        sv_catpvn(ctx->out, kw, len);
    }
}

static void
ddc_emit_operator(pTHX_ DDCDeparse *ctx, const char *op, STRLEN len)
{
    if (ctx->style->use_colour) {
        ddc_colour_wrap(aTHX_ ctx->out,
            ctx->style->c_operator_fg, ctx->style->c_operator_bg,
            ctx->style->c_reset, op, len);
    } else {
        sv_catpvn(ctx->out, op, len);
    }
}

static void
ddc_emit_variable(pTHX_ DDCDeparse *ctx, const char *var, STRLEN len)
{
    if (ctx->style->use_colour) {
        ddc_colour_wrap(aTHX_ ctx->out,
            ctx->style->c_variable_fg, ctx->style->c_variable_bg,
            ctx->style->c_reset, var, len);
    } else {
        sv_catpvn(ctx->out, var, len);
    }
}

static void
ddc_emit_dep_string(pTHX_ DDCDeparse *ctx, const char *str, STRLEN len)
{
    if (ctx->style->use_colour) {
        ddc_colour_wrap(aTHX_ ctx->out,
            ctx->style->c_string_fg, ctx->style->c_string_bg,
            ctx->style->c_reset, str, len);
    } else {
        sv_catpvn(ctx->out, str, len);
    }
}

static void
ddc_emit_dep_number(pTHX_ DDCDeparse *ctx, const char *num, STRLEN len)
{
    if (ctx->style->use_colour) {
        ddc_colour_wrap(aTHX_ ctx->out,
            ctx->style->c_number_fg, ctx->style->c_number_bg,
            ctx->style->c_reset, num, len);
    } else {
        sv_catpvn(ctx->out, num, len);
    }
}

/* ── Indent helper ────────────────────────────────────────────── */

static void
ddc_deparse_indent(pTHX_ DDCDeparse *ctx)
{
    int i, j;
    int width = (ctx->style && ctx->style->indent_width > 0)
                ? ctx->style->indent_width : 2;
    char ch   = (ctx->style && ctx->style->indent_char)
                ? ctx->style->indent_char : ' ';
    char buf[16];
    int blen = width > (int)sizeof(buf) ? (int)sizeof(buf) : width;
    for (j = 0; j < blen; j++)
        buf[j] = ch;
    for (i = 0; i < ctx->indent; i++)
        sv_catpvn(ctx->out, buf, blen);
}

/* ── Pad name lookup ──────────────────────────────────────────── */

static const char *
ddc_padname_for_targ(pTHX_ DDCDeparse *ctx, PADOFFSET targ)
{
    PADNAME *pn;
    if (!ctx->padnames || targ == 0)
        return NULL;

    if ((IV)targ > PadnamelistMAX(ctx->padnames))
        return NULL;

    pn = PadnamelistARRAY(ctx->padnames)[targ];
    if (pn && PadnameLEN(pn) > 0)
        return PadnamePV(pn);
    return NULL;
}

/* ── GV name lookup ───────────────────────────────────────────── */

static SV *
ddc_gv_from_op_cv(pTHX_ OP *o, CV *cv)
{
    GV *gv = NULL;

    if (o->op_type == OP_GV || o->op_type == OP_GVSV ||
        o->op_type == OP_AELEMFAST) {
#ifdef USE_ITHREADS
        /* On ithreads, GV is in the CV's pad, not the current pad */
        if (cv) {
            PADLIST *pl = CvPADLIST(cv);
            if (pl) {
                PAD *pad = PadlistARRAY(pl)[1];
                PADOFFSET ix = cPADOPx(o)->op_padix;
                if (pad && (IV)ix <= AvFILLp(pad)) {
                    SV *sv = AvARRAY(pad)[ix];
                    if (sv && SvTYPE(sv) == SVt_PVGV)
                        gv = (GV *)sv;
                    /* On ithreads, CV refs are stored as RVs
                       pointing to the CV (e.g. \&func) */
                    else if (sv && SvROK(sv) &&
                             SvTYPE(SvRV(sv)) == SVt_PVCV)
                        gv = CvGV((CV *)SvRV(sv));
                }
            }
        }
        if (!gv) {
            SV *sv = PAD_SVl(cPADOPx(o)->op_padix);
            if (sv && SvTYPE(sv) == SVt_PVGV)
                gv = (GV *)sv;
            else if (sv && SvROK(sv) &&
                     SvTYPE(SvRV(sv)) == SVt_PVCV)
                gv = CvGV((CV *)SvRV(sv));
        }
#else
        /* On non-ithreads, op_sv may be a real GV or an RV to CV
           (Perl's "sub-only GV" optimisation stores an RV to the CV
           instead of a full GV when only the CV slot is used). */
        {
            SV *sv = cSVOPx_sv(o);
            if (sv && SvTYPE(sv) == SVt_PVGV)
                gv = (GV *)sv;
            else if (sv && SvROK(sv) &&
                     SvTYPE(SvRV(sv)) == SVt_PVCV)
                gv = CvGV((CV *)SvRV(sv));
            else if (sv && SvTYPE(sv) == SVt_PVCV)
                gv = CvGV((CV *)sv);
        }
#endif
    }

    if (gv) {
        const char *name = GvNAME(gv);
        HV *stash = GvSTASH(gv);
        const char *pkg = stash ? HvNAME(stash) : "";

        if (pkg && *pkg && strNE(pkg, "main"))
            return newSVpvf("%s::%s", pkg, name);
        else
            return newSVpv(name, 0);
    }
    return newSVpvs("???");
}

/* ── Aux item SV lookup (handles ithreads) ───────────────────── */

#if PERL_VERSION >= 22  /* UNOP_AUX_item exists from Perl 5.22+ */
static SV *
ddc_aux_item_sv(pTHX_ UNOP_AUX_item *item, CV *cv)
{
#ifdef USE_ITHREADS
    PADOFFSET off = item->pad_offset;
    if (cv) {
        PADLIST *pl = CvPADLIST(cv);
        if (pl) {
            PAD *pad = PadlistARRAY(pl)[1];
            if (pad && (IV)off <= AvFILLp(pad))
                return AvARRAY(pad)[off];
        }
    }
    return &PL_sv_undef;
#else
    return item->sv;
#endif
}
#endif /* PERL_VERSION >= 22 */

/* ── Const op SV lookup (handles ithreads) ───────────────────── */

static SV *
ddc_const_sv(pTHX_ OP *o, CV *cv)
{
#ifdef USE_ITHREADS
    if (!cSVOPx(o)->op_sv && o->op_targ > 0 && cv) {
        PADLIST *pl = CvPADLIST(cv);
        if (pl) {
            PAD *pad = PadlistARRAY(pl)[1];
            if (pad && (IV)o->op_targ <= AvFILLp(pad))
                return AvARRAY(pad)[(PADOFFSET)o->op_targ];
        }
        return &PL_sv_undef;
    }
    return cSVOPx_sv(o);
#else
    /* On non-ithreads, op_sv may also be NULL when the SV was
       moved to the pad (Perl 5.20+ pad-temp optimisation). */
    if (!cSVOPx(o)->op_sv && o->op_targ > 0 && cv) {
        PADLIST *pl = CvPADLIST(cv);
        if (pl) {
            PAD *pad = PadlistARRAY(pl)[1];
            if (pad && (IV)o->op_targ <= AvFILLp(pad))
                return AvARRAY(pad)[(PADOFFSET)o->op_targ];
        }
        return &PL_sv_undef;
    }
    return cSVOPx_sv(o);
#endif
}

/* ── Binary op symbol mapping ─────────────────────────────────── */

static const char *
ddc_op_symbol(U16 op_type)
{
    switch (op_type) {
        case OP_ADD:         return "+";
        case OP_SUBTRACT:    return "-";
        case OP_MULTIPLY:    return "*";
        case OP_DIVIDE:      return "/";
        case OP_MODULO:      return "%";
        case OP_CONCAT:      return ".";
        case OP_LEFT_SHIFT:  return "<<";
        case OP_RIGHT_SHIFT: return ">>";
        case OP_LT:     return "<";
        case OP_GT:     return ">";
        case OP_LE:     return "<=";
        case OP_GE:     return ">=";
        case OP_EQ:     return "==";
        case OP_NE:     return "!=";
        case OP_NCMP:   return "<=>";
        case OP_SLT:    return "lt";
        case OP_SGT:    return "gt";
        case OP_SLE:    return "le";
        case OP_SGE:    return "ge";
        case OP_SEQ:    return "eq";
        case OP_SNE:    return "ne";
        case OP_SCMP:   return "cmp";
        case OP_BIT_AND:   return "&";
        case OP_BIT_OR:    return "|";
        case OP_BIT_XOR:   return "^";
        case OP_POW:       return "**";
        case OP_REPEAT:    return "x";
        case OP_RANGE:     return "..";
        default: return NULL;
    }
}

/* ── Precedence of an op ──────────────────────────────────────── */

static loo_prec_t
ddc_op_precedence(U16 op_type)
{
    switch (op_type) {
        case OP_OR: case OP_DOR:   return LOO_PREC_OROR;
        case OP_AND:               return LOO_PREC_ANDAND;
        case OP_BIT_OR: case OP_BIT_XOR: return LOO_PREC_BITOR;
        case OP_BIT_AND:           return LOO_PREC_BITAND;
        case OP_EQ: case OP_NE: case OP_NCMP:
        case OP_SEQ: case OP_SNE: case OP_SCMP:
            return LOO_PREC_EQUALITY;
        case OP_LT: case OP_GT: case OP_LE: case OP_GE:
        case OP_SLT: case OP_SGT: case OP_SLE: case OP_SGE:
            return LOO_PREC_COMPARE;
        case OP_LEFT_SHIFT: case OP_RIGHT_SHIFT:
            return LOO_PREC_SHIFT;
        case OP_ADD: case OP_SUBTRACT: case OP_CONCAT:
            return LOO_PREC_ADD;
        case OP_MULTIPLY: case OP_DIVIDE: case OP_MODULO: case OP_REPEAT:
            return LOO_PREC_MUL;
        case OP_POW:       return LOO_PREC_POW;
        case OP_NEGATE: case OP_NOT: case OP_COMPLEMENT:
            return LOO_PREC_UNARY;
        case OP_SASSIGN: case OP_AASSIGN:
            return LOO_PREC_ASSIGN;
        case OP_COND_EXPR: return LOO_PREC_TERNARY;
        case OP_RANGE:     return LOO_PREC_OROR;
        default:           return LOO_PREC_HIGHEST;
    }
}

/* ── Binary op helper ─────────────────────────────────────────── */

static void
ddc_deparse_binop(pTHX_ OP *o, DDCDeparse *ctx)
{
    const char *sym = ddc_op_symbol(o->op_type);
    loo_prec_t saved = ctx->prec;
    OP *left, *right;
    /* OPf_STACKED means compound assignment (e.g. +=, .=).
       But for OP_CONCAT on pre-5.28 perls, chained concat like
       a . " " . b is compiled as two concats where the second
       has OPf_STACKED but is NOT a user-written .= — it's the
       compiler's temp-target optimisation.  Only treat STACKED
       concat as compound when the left operand is NOT another
       concat (i.e. the user wrote $x .= expr, not a . b . c). */
    int is_compound = (o->op_flags & OPf_STACKED) ? 1 : 0;
    loo_prec_t my_prec;
    int need_parens;
    char compound_sym[16];

    if (!sym) sym = "??";

    left = cBINOPo->op_first;
    right = OpSIBLING(left);

    if (is_compound && o->op_type == OP_CONCAT) {
        /* If the left operand is also a concat, this is a chain,
           not a compound assignment. */
        if (left && (left->op_type == OP_CONCAT ||
                     (left->op_type == OP_NULL &&
                      left->op_targ == OP_CONCAT)))
            is_compound = 0;
    }

    my_prec = is_compound ? LOO_PREC_ASSIGN
                          : ddc_op_precedence(o->op_type);
    need_parens = (my_prec < saved);

    if (is_compound) {
        snprintf(compound_sym, sizeof(compound_sym), "%s=", sym);
        sym = compound_sym;
    }

    if (need_parens) sv_catpvn(ctx->out, "(", 1);

    ctx->prec = my_prec;
    ddc_deparse_op(aTHX_ left, ctx);
    sv_catpvn(ctx->out, " ", 1);
    ddc_emit_operator(aTHX_ ctx, sym, strlen(sym));
    sv_catpvn(ctx->out, " ", 1);
    if (right)
        ddc_deparse_op(aTHX_ right, ctx);

    if (need_parens) sv_catpvn(ctx->out, ")", 1);
    ctx->prec = saved;
}

/* Helper: check if an op is a NEXTSTATE-like (statement boundary) */
static int
ddc_is_nextstate(OP *o)
{
    if (!o) return 0;
    if (o->op_type == OP_NEXTSTATE || o->op_type == OP_DBSTATE)
        return 1;
    if (o->op_type == OP_NULL &&
        (o->op_targ == OP_NEXTSTATE || o->op_targ == OP_DBSTATE))
        return 1;
    return 0;
}

/* Helper: check if next significant sibling is also a NEXTSTATE.
   Skips PUSHMARK, ENTER, UNSTACK ops when peeking ahead.
   Used to suppress blank lines from extra NEXTSTATE ops on
   older Perls (5.10, 5.12). */
static int
ddc_next_sibling_is_nextstate(OP *kid)
{
    OP *nxt = OpSIBLING(kid);
    while (nxt && (nxt->op_type == OP_PUSHMARK ||
                   nxt->op_type == OP_ENTER ||
                   nxt->op_type == OP_UNSTACK))
        nxt = OpSIBLING(nxt);
    return ddc_is_nextstate(nxt);
}

/* ── Statement sequence ───────────────────────────────────────── */

static void
ddc_deparse_stmts(pTHX_ OP *o, DDCDeparse *ctx)
{
    OP *kid;
    int first = 1;
    U16 ktype;

    if (!o) return;

    if (o->op_flags & OPf_KIDS) {
        for (kid = cUNOPo->op_first; kid; kid = OpSIBLING(kid)) {
            if (kid->op_type == OP_PUSHMARK ||
                kid->op_type == OP_ENTER ||
                kid->op_type == OP_UNSTACK)
                continue;

            if (ddc_is_nextstate(kid)) {
                /* Skip NEXTSTATE followed by another NEXTSTATE to
                   avoid blank lines on older Perls (5.10, 5.12) */
                if (ddc_next_sibling_is_nextstate(kid))
                    continue;
                if (!first)
                    sv_catpvn(ctx->out, "\n", 1);
                first = 0;
                ddc_deparse_indent(aTHX_ ctx);
                continue;
            }

            /* ── C-style for detection ─────────────────────── */
            /* Pattern: INIT, unstack, leaveloop(enterloop, ...) */
            {
                OP *next1 = OpSIBLING(kid);
                OP *next2 = next1 ? OpSIBLING(next1) : NULL;
                OP *loop_op = NULL;
                OP *skip_to_top = NULL;
                if (next1 && next1->op_type == OP_UNSTACK &&
                    next2 && next2->op_type == OP_LEAVELOOP &&
                    cBINOPx(next2)->op_first &&
                    cBINOPx(next2)->op_first->op_type == OP_ENTERLOOP) {
                    loop_op = next2; skip_to_top = next2;
                }
                else if (next1 && next1->op_type == OP_LEAVELOOP &&
                         cBINOPx(next1)->op_first &&
                         cBINOPx(next1)->op_first->op_type == OP_ENTERLOOP) {
                    loop_op = next1; skip_to_top = next1;
                }
                /* 5.10: sassign → lineseq(nextstate, leaveloop) */
                else if (next1 && next1->op_type == OP_LINESEQ &&
                         (next1->op_flags & OPf_KIDS)) {
                    OP *ls_kid;
                    for (ls_kid = cUNOPx(next1)->op_first; ls_kid;
                         ls_kid = OpSIBLING(ls_kid)) {
                        if (ls_kid->op_type == OP_LEAVELOOP &&
                            cBINOPx(ls_kid)->op_first &&
                            cBINOPx(ls_kid)->op_first->op_type == OP_ENTERLOOP) {
                            loop_op = ls_kid;
                            skip_to_top = next1;
                            break;
                        }
                    }
                }

                if (loop_op)
                {
                    /* Extract cond and step from the leaveloop */
                    OP *body_null = OpSIBLING(cBINOPx(loop_op)->op_first);
                    OP *logic = NULL;
                    OP *cond_op = NULL;
                    OP *body_lineseq = NULL;
                    OP *step_op = NULL;
                    OP *stmt;
                    int bfirst = 1;
                    int i;

                    if (body_null && body_null->op_type == OP_NULL &&
                        (body_null->op_flags & OPf_KIDS))
                        logic = cUNOPx(body_null)->op_first;

                    if (logic && logic->op_type == OP_AND) {
                        cond_op = cLOGOPx(logic)->op_first;
                        body_lineseq = OpSIBLING(cond_op);
                    }

                    /* Find the step op: last non-unstack child
                       of body_lineseq */
                    if (body_lineseq &&
                        (body_lineseq->op_flags & OPf_KIDS)) {
                        OP *prev = NULL;
                        for (stmt = cUNOPx(body_lineseq)->op_first;
                             stmt; stmt = OpSIBLING(stmt)) {
                            if (stmt->op_type == OP_UNSTACK) break;
                            prev = stmt;
                        }
                        if (prev && prev->op_type != OP_NEXTSTATE &&
                            prev->op_type != OP_DBSTATE &&
                            prev->op_type != OP_SCOPE &&
                            prev->op_type != OP_LEAVE)
                            step_op = prev;
                    }

                    /* Emit: for (INIT; COND; STEP) { */
                    ddc_emit_keyword(aTHX_ ctx, "for", 3);
                    sv_catpvn(ctx->out, " (", 2);
                    ctx->prec = LOO_PREC_LOWEST;
                    ddc_deparse_op(aTHX_ kid, ctx);  /* INIT */
                    sv_catpvn(ctx->out, "; ", 2);
                    if (cond_op) ddc_deparse_op(aTHX_ cond_op, ctx);
                    sv_catpvn(ctx->out, "; ", 2);
                    if (step_op) ddc_deparse_op(aTHX_ step_op, ctx);
                    sv_catpvn(ctx->out, ") {\n", 4);

                    /* Deparse body (skip step_op and unstack) */
                    ctx->indent++;
                    if (body_lineseq &&
                        (body_lineseq->op_flags & OPf_KIDS)) {
                        for (stmt = cUNOPx(body_lineseq)->op_first;
                             stmt; stmt = OpSIBLING(stmt))
                        {
                            U16 stype = stmt->op_type;
                            if (stype == OP_UNSTACK) continue;
                            if (stmt == step_op) continue;
                            if (stype == OP_PUSHMARK ||
                                stype == OP_ENTER) continue;
                            if (ddc_is_nextstate(stmt)) {
                                if (ddc_next_sibling_is_nextstate(stmt))
                                    continue;
                                if (!bfirst)
                                    sv_catpvn(ctx->out, "\n", 1);
                                bfirst = 0;
                                ddc_deparse_indent(aTHX_ ctx);
                                continue;
                            }
                            ctx->prec = LOO_PREC_LOWEST;
                            ddc_deparse_op(aTHX_ stmt, ctx);
                            if (stype != OP_LINESEQ &&
                                stype != OP_SCOPE &&
                                stype != OP_LEAVE &&
                                stype != OP_LEAVELOOP)
                                sv_catpvn(ctx->out, ";", 1);
                        }
                    }
                    ctx->indent--;

                    sv_catpvn(ctx->out, "\n", 1);
                    for (i = 0; i < ctx->indent; i++)
                        sv_catpvn(ctx->out, "  ", 2);
                    sv_catpvn(ctx->out, "}", 1);

                    /* Skip past loop components */
                    kid = skip_to_top;
                    continue;
                }
            }

            ctx->prec = LOO_PREC_LOWEST;
            ctx->last_was_block = 0;
            ddc_deparse_op(aTHX_ kid, ctx);
            /* Don't add semicolon after scope/block ops
               (they produce their own statements internally) */
            if (ctx->last_was_block)
                continue;
            ktype = kid->op_type;
            if (ktype == OP_LINESEQ || ktype == OP_SCOPE ||
                ktype == OP_LEAVE || ktype == OP_LEAVESUB ||
                ktype == OP_LEAVELOOP || ktype == OP_ENTERTRY)
                continue;
            /* OP_NULL wrapping a single scope/leave (e.g. do{})
               also produces its own semicolons */
            if (ktype == OP_NULL && (kid->op_flags & OPf_KIDS)) {
                OP *inner = cUNOPx(kid)->op_first;
                if (inner && !OpSIBLING(inner)) {
                    U16 itype = inner->op_type;
                    if (itype == OP_LEAVE || itype == OP_SCOPE ||
                        itype == OP_LINESEQ)
                        continue;
                }
            }
            sv_catpvn(ctx->out, ";", 1);
        }
    }
}

/* ══════════════════════════════════════════════════════════════ */
/* ── Main op dispatcher ───────────────────────────────────────── */
/* ══════════════════════════════════════════════════════════════ */

static void
ddc_deparse_op(pTHX_ OP *o, DDCDeparse *ctx)
{
    U16 type;

    if (!o) return;

    type = o->op_type;

    /* OP_NULL: optimised away — look at original type in op_targ */
    if (type == OP_NULL) {
        U16 was = o->op_targ;

        /* Optimised-away sassign */
        if (was == OP_SASSIGN || was == OP_AASSIGN) {
            if (o->op_flags & OPf_KIDS) {
                OP *left = cBINOPo->op_first;
                OP *right = OpSIBLING(left);
                if (right) {
                    ddc_deparse_op(aTHX_ right, ctx);
                    sv_catpvn(ctx->out, " ", 1);
                    ddc_emit_operator(aTHX_ ctx, "=", 1);
                    sv_catpvn(ctx->out, " ", 1);
                    ddc_deparse_op(aTHX_ left, ctx);
                    return;
                }
            }
        }

        /* Optimised-away padsv_store (5.38+): my $x = expr or $x = expr
           The peephole converts sassign(rhs, padsv) → padsv_store(rhs)
           and a later pass may null it. */
#if PERL_VERSION >= 38
        if (was == OP_PADSV_STORE) {
            const char *name = ddc_padname_for_targ(aTHX_ ctx, o->op_targ);
            if (o->op_private & OPpLVAL_INTRO)
                ddc_emit_keyword(aTHX_ ctx, "my ", 3);
            if (name) {
                ddc_emit_variable(aTHX_ ctx, name, strlen(name));
            } else {
                sv_catpvf(ctx->out, "$pad_%d", (int)o->op_targ);
            }
            sv_catpvn(ctx->out, " ", 1);
            ddc_emit_operator(aTHX_ ctx, "=", 1);
            sv_catpvn(ctx->out, " ", 1);
            if (o->op_flags & OPf_KIDS)
                ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
            return;
        }
#endif

        /* Optimised-away aelemfastlex_store (5.40+): $arr[N] = expr */
#if PERL_VERSION >= 40
        if (was == OP_AELEMFASTLEX_STORE) {
            const char *name = ddc_padname_for_targ(aTHX_ ctx, o->op_targ);
            if (name) {
                SV *var = newSVpvf("$%s", name + 1);
                STRLEN vlen;
                const char *vpv = SvPV(var, vlen);
                ddc_emit_variable(aTHX_ ctx, vpv, vlen);
                SvREFCNT_dec(var);
            } else {
                sv_catpvf(ctx->out, "$pad_%d", (int)o->op_targ);
            }
            sv_catpvf(ctx->out, "[%d]", (int)o->op_private);
            sv_catpvn(ctx->out, " ", 1);
            ddc_emit_operator(aTHX_ ctx, "=", 1);
            sv_catpvn(ctx->out, " ", 1);
            if (o->op_flags & OPf_KIDS)
                ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
            return;
        }
#endif

        /* Optimised-away return */
        if (was == OP_RETURN) {
            OP *kid;
            int first = 1;
            ddc_emit_keyword(aTHX_ ctx, "return", 6);
            if (o->op_flags & OPf_KIDS) {
                for (kid = cUNOPo->op_first; kid; kid = OpSIBLING(kid)) {
                    if (kid->op_type == OP_PUSHMARK) continue;
                    if (!first) sv_catpvn(ctx->out, ", ", 2);
                    sv_catpvn(ctx->out, " ", 1);
                    ddc_deparse_op(aTHX_ kid, ctx);
                    first = 0;
#if PERL_VERSION >= 18
                    if (kid->op_type == OP_PADRANGE) {
                        int skip = (int)(kid->op_private & OPpPADRANGE_COUNTMASK);
                        while (skip-- > 0 && OpSIBLING(kid)) kid = OpSIBLING(kid);
                    }
#endif
                }
            }
            return;
        }

        /* Optimised-away helem/aelem (e.g. inside exists/delete
           on pre-5.22 where there is no multideref).
           Only dispatch when the children are genuine hash/array + key
           ops.  Skip when aelemfast already handles the access
           (aelemfast may be the direct first child or wrapped in an
           ex-rv2av null). */
        if (was == OP_HELEM || was == OP_AELEM) {
            if (o->op_flags & OPf_KIDS) {
                OP *first = cBINOPo->op_first;
                int has_aelemfast = 0;
                if (first) {
                    if (first->op_type == OP_AELEMFAST
#if PERL_VERSION >= 18
                        || first->op_type == OP_AELEMFAST_LEX
#endif
                    )
                        has_aelemfast = 1;
                    else if (first->op_type == OP_NULL &&
                             (first->op_flags & OPf_KIDS) &&
                             cUNOPx(first)->op_first &&
                             cUNOPx(first)->op_first->op_type
                                 == OP_AELEMFAST)
                        has_aelemfast = 1;
                }
                if (!has_aelemfast && first) {
                    OP *second = OpSIBLING(first);
                    if (second) {
                        o->op_type = was;
                        ddc_deparse_op(aTHX_ o, ctx);
                        o->op_type = OP_NULL;
                        return;
                    }
                }
            }
        }

        /* Optimised-away OP_EMPTYAVHV (5.36+): the peephole may null
           the empty hash/array constructor.  Emit {} or []. */
#if PERL_VERSION >= 36
        if (was == OP_EMPTYAVHV) {
#ifdef OPpEMPTYAVHV_IS_HV
            if (o->op_private & OPpEMPTYAVHV_IS_HV)
                sv_catpvn(ctx->out, "{}", 2);
            else
                sv_catpvn(ctx->out, "[]", 2);
#else
            if (o->op_flags & OPf_SPECIAL)
                sv_catpvn(ctx->out, "{}", 2);
            else
                sv_catpvn(ctx->out, "[]", 2);
#endif
            return;
        }
#endif

        /* Optimised-away list/scope/other — recurse into children */
        if (o->op_flags & OPf_KIDS) {
            OP *kid = cUNOPo->op_first;
            if (kid && !OpSIBLING(kid)) {
                /* do { BLOCK } — null wrapping a leave (with enter)
                   or a scope */
                if ((kid->op_type == OP_LEAVE &&
                     (kid->op_flags & OPf_KIDS) &&
                     cUNOPx(kid)->op_first &&
                     cUNOPx(kid)->op_first->op_type == OP_ENTER)
                    || kid->op_type == OP_SCOPE)
                {
                    int i;
                    ddc_emit_keyword(aTHX_ ctx, "do", 2);
                    sv_catpvn(ctx->out, " {\n", 3);
                    ctx->indent++;
                    ddc_deparse_stmts(aTHX_ kid, ctx);
                    ctx->indent--;
                    sv_catpvn(ctx->out, "\n", 1);
                    for (i = 0; i < ctx->indent; i++)
                        sv_catpvn(ctx->out, "  ", 2);
                    sv_catpvn(ctx->out, "}", 1);
                    return;
                }
                ddc_deparse_op(aTHX_ kid, ctx);
                return;
            }
            /* Multiple kids: skip pushmark and vestigial null nodes */
            {
                int first = 1;
                for (; kid; kid = OpSIBLING(kid)) {
                    if (kid->op_type == OP_PUSHMARK) continue;
                    /* Skip vestigial null ops with no children */
                    if (kid->op_type == OP_NULL &&
                        !(kid->op_flags & OPf_KIDS))
                        continue;
                    if (!first) sv_catpvn(ctx->out, ", ", 2);
                    ddc_deparse_op(aTHX_ kid, ctx);
                    first = 0;
                    /* padrange covers the next N sibling pad ops */
#if PERL_VERSION >= 18
                    if (kid->op_type == OP_PADRANGE) {
                        int skip = (int)(kid->op_private
                                         & OPpPADRANGE_COUNTMASK);
                        while (skip-- > 0 && OpSIBLING(kid))
                            kid = OpSIBLING(kid);
                    }
#endif
                }
            }
        }
        return;
    }

    /* ── OPpTARGET_MY: the peephole optimiser absorbed a sassign into
       this op, storing the result directly into a pad slot (5.20+,
       expanded in 5.36+).  Emit "[my] $var = " before the value.
       Skip OP_NULL (targ = original type), OP_CONST (bit 0x10 =
       OPpCONST_ENTERED), OP_MULTICONCAT (handles TARGET_MY itself),
       and pad ops (bit 0x10 = OPpDEREF). ──────────────────────── */
    if (type != OP_NULL && type != OP_CONST
#if PERL_VERSION >= 28
        && type != OP_MULTICONCAT
#endif
        && type != OP_PADSV && type != OP_PADAV && type != OP_PADHV
#if PERL_VERSION >= 38
        && type != OP_PADSV_STORE
#endif
#if PERL_VERSION >= 40
        && type != OP_AELEMFASTLEX_STORE
#endif
        && (o->op_private & OPpTARGET_MY)
        && o->op_targ > 0)
    {
        const char *name = ddc_padname_for_targ(aTHX_ ctx, o->op_targ);
        if (name && (*name == '$' || *name == '@' || *name == '%')) {
            if (o->op_private & OPpLVAL_INTRO)
                ddc_emit_keyword(aTHX_ ctx, "my ", 3);
            ddc_emit_variable(aTHX_ ctx, name, strlen(name));
            sv_catpvn(ctx->out, " ", 1);
            ddc_emit_operator(aTHX_ ctx, "=", 1);
            sv_catpvn(ctx->out, " ", 1);
        }
        /* Fall through to the switch to emit the expression value */
    }

    switch (type) {

    /* ── Constants ────────────────────────────────────────────── */
    case OP_CONST: {
        SV *sv;
#ifdef USE_ITHREADS
        /* On ithreads, cSVOPx_sv uses PAD_SVl which accesses the
           currently-executing pad, not the CV we're deparsing.
           We must look in the CV's own pad for the constant. */
        if (!cSVOPx(o)->op_sv && o->op_targ > 0 && ctx->cv) {
            PADLIST *pl = CvPADLIST(ctx->cv);
            if (pl) {
                PAD *pad = PadlistARRAY(pl)[1];
                if (pad && (IV)o->op_targ <= AvFILLp(pad))
                    sv = AvARRAY(pad)[(PADOFFSET)o->op_targ];
                else
                    sv = &PL_sv_undef;
            } else {
                sv = &PL_sv_undef;
            }
        } else {
            sv = cSVOPx_sv(o);
        }
#else
        sv = cSVOPx_sv(o);
#endif
        if (!SvOK(sv)) {
            ddc_emit_keyword(aTHX_ ctx, "undef", 5);
        } else if (SvIOK(sv) || SvNOK(sv)) {
            SV *num = ddc_format_number(aTHX_ sv);
            STRLEN len;
            const char *pv = SvPV(num, len);
            ddc_emit_dep_number(aTHX_ ctx, pv, len);
            SvREFCNT_dec(num);
        } else {
            STRLEN len;
            const char *pv = SvPV(sv, len);
            SV *esc = ddc_escape_string(aTHX_ pv, len, 0, SvUTF8(sv) ? 1 : 0);
            STRLEN elen;
            const char *epv = SvPV(esc, elen);
            sv_catpvn(ctx->out, "'", 1);
            ddc_emit_dep_string(aTHX_ ctx, epv, elen);
            sv_catpvn(ctx->out, "'", 1);
            SvREFCNT_dec(esc);
        }
        break;
    }

    /* ── Pad variables ($x, @a, %h) ──────────────────────────── */
    case OP_PADSV: case OP_PADAV: case OP_PADHV: {
        const char *name = ddc_padname_for_targ(aTHX_ ctx, o->op_targ);
        if (o->op_private & OPpLVAL_INTRO)
            ddc_emit_keyword(aTHX_ ctx, "my ", 3);
        if (name) {
            ddc_emit_variable(aTHX_ ctx, name, strlen(name));
        } else {
            sv_catpvf(ctx->out, "$pad_%d", (int)o->op_targ);
        }
        break;
    }

    /* ── OP_PADSV_STORE: combined assign-to-pad (5.38+) ──────── */
#if PERL_VERSION >= 38
    case OP_PADSV_STORE: {
        const char *name = ddc_padname_for_targ(aTHX_ ctx, o->op_targ);
        if (o->op_private & OPpLVAL_INTRO)
            ddc_emit_keyword(aTHX_ ctx, "my ", 3);
        if (name) {
            ddc_emit_variable(aTHX_ ctx, name, strlen(name));
        } else {
            sv_catpvf(ctx->out, "$pad_%d", (int)o->op_targ);
        }
        sv_catpvn(ctx->out, " ", 1);
        ddc_emit_operator(aTHX_ ctx, "=", 1);
        sv_catpvn(ctx->out, " ", 1);
        if (o->op_flags & OPf_KIDS)
            ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
        break;
    }
#endif

    /* ── OP_AELEMFASTLEX_STORE: combined $arr[N] = expr (5.40+) ── */
#if PERL_VERSION >= 40
    case OP_AELEMFASTLEX_STORE: {
        const char *name = ddc_padname_for_targ(aTHX_ ctx, o->op_targ);
        if (name) {
            SV *var = newSVpvf("$%s", name + 1);
            STRLEN vlen;
            const char *vpv = SvPV(var, vlen);
            ddc_emit_variable(aTHX_ ctx, vpv, vlen);
            SvREFCNT_dec(var);
        } else {
            sv_catpvf(ctx->out, "$pad_%d", (int)o->op_targ);
        }
        sv_catpvf(ctx->out, "[%d]", (int)o->op_private);
        sv_catpvn(ctx->out, " ", 1);
        ddc_emit_operator(aTHX_ ctx, "=", 1);
        sv_catpvn(ctx->out, " ", 1);
        if (o->op_flags & OPf_KIDS)
            ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
        break;
    }
#endif

    /* ── OP_EMPTYAVHV: empty anon hash/array {} or [] (5.36+) ── */
#if PERL_VERSION >= 36
    case OP_EMPTYAVHV: {
#ifdef OPpEMPTYAVHV_IS_HV
        if (o->op_private & OPpEMPTYAVHV_IS_HV)
            sv_catpvn(ctx->out, "{}", 2);
        else
            sv_catpvn(ctx->out, "[]", 2);
#else
        /* fallback: check op_flags OPf_SPECIAL for hash vs array */
        if (o->op_flags & OPf_SPECIAL)
            sv_catpvn(ctx->out, "{}", 2);
        else
            sv_catpvn(ctx->out, "[]", 2);
#endif
        break;
    }
#endif

    /* ── Fast array element ($_[0], $a[N]) ────────────────────── */
#if PERL_VERSION >= 18
    case OP_AELEMFAST_LEX: {
        /* Lexical array: pad variable + constant index */
        const char *name = ddc_padname_for_targ(aTHX_ ctx, o->op_targ);
        if (name) {
            /* name is like "@arr", emit as $arr[N] */
            SV *var = newSVpvf("$%s", name + 1);
            STRLEN vlen;
            const char *vpv = SvPV(var, vlen);
            ddc_emit_variable(aTHX_ ctx, vpv, vlen);
            SvREFCNT_dec(var);
        } else {
            sv_catpvf(ctx->out, "$pad_%d", (int)o->op_targ);
        }
        sv_catpvf(ctx->out, "[%d]", (int)o->op_private);
        break;
    }
#endif
    case OP_AELEMFAST: {
        /* Global array: GV + constant index  e.g. $_[0]
           Pre-5.18: also used for lexical arrays (check op_targ) */
#if PERL_VERSION < 18
        if (o->op_targ) {
            /* Lexical array: same as AELEMFAST_LEX */
            const char *name = ddc_padname_for_targ(aTHX_ ctx, o->op_targ);
            if (name) {
                SV *var = newSVpvf("$%s", name + 1);
                STRLEN vlen;
                const char *vpv = SvPV(var, vlen);
                ddc_emit_variable(aTHX_ ctx, vpv, vlen);
                SvREFCNT_dec(var);
            } else {
                sv_catpvf(ctx->out, "$pad_%d", (int)o->op_targ);
            }
            sv_catpvf(ctx->out, "[%d]", (int)o->op_private);
            break;
        }
#endif
        {
        SV *name = ddc_gv_from_op_cv(aTHX_ o, ctx->cv);
        const char *pv = SvPV_nolen(name);
        SV *var;
        STRLEN vlen;
        const char *vpv;
        if (strEQ(pv, "_"))
            var = newSVpvs("$_");
        else
            var = newSVpvf("$%s", pv);
        vpv = SvPV(var, vlen);
        ddc_emit_variable(aTHX_ ctx, vpv, vlen);
        sv_catpvf(ctx->out, "[%d]", (int)o->op_private);
        SvREFCNT_dec(name);
        SvREFCNT_dec(var);
        break;
        }
    }

    /* ── Package variables ────────────────────────────────────── */
    case OP_GVSV: {
        SV *name = ddc_gv_from_op_cv(aTHX_ o, ctx->cv);
        STRLEN len;
        const char *pv = SvPV(name, len);
        if (o->op_private & OPpLVAL_INTRO)
            ddc_emit_keyword(aTHX_ ctx, "local ", 6);
        sv_catpvn(ctx->out, "$", 1);
        ddc_emit_variable(aTHX_ ctx, pv, len);
        SvREFCNT_dec(name);
        break;
    }

    case OP_GV: {
        SV *name = ddc_gv_from_op_cv(aTHX_ o, ctx->cv);
        STRLEN len;
        const char *pv = SvPV(name, len);
        ddc_emit_variable(aTHX_ ctx, pv, len);
        SvREFCNT_dec(name);
        break;
    }

    /* ── Binary arithmetic/string/comparison ops ──────────────── */
    case OP_ADD: case OP_SUBTRACT: case OP_MULTIPLY: case OP_DIVIDE:
    case OP_MODULO: case OP_CONCAT: case OP_LEFT_SHIFT: case OP_RIGHT_SHIFT:
    case OP_LT: case OP_GT: case OP_LE: case OP_GE:
    case OP_EQ: case OP_NE: case OP_NCMP:
    case OP_SLT: case OP_SGT: case OP_SLE: case OP_SGE:
    case OP_SEQ: case OP_SNE: case OP_SCMP:
    case OP_BIT_AND: case OP_BIT_OR: case OP_BIT_XOR:
    case OP_POW: case OP_REPEAT: case OP_RANGE:
        ddc_deparse_binop(aTHX_ o, ctx);
        break;

    /* ── Logical ops ──────────────────────────────────────────── */
    case OP_AND: {
        loo_prec_t saved = ctx->prec;
        loo_prec_t my_prec = ddc_op_precedence(type);
        int need_parens = (my_prec < saved);
        OP *left = cLOGOPo->op_first;
        OP *right = OpSIBLING(left);
        int is_block = 0;
        if (right) {
            U16 rt = right->op_type;
            if (rt == OP_SCOPE || rt == OP_LEAVE || rt == OP_LINESEQ)
                is_block = 1;
            if (rt == OP_NULL && (right->op_flags & OPf_KIDS)) {
                OP *inner = cUNOPx(right)->op_first;
                if (inner && (inner->op_type == OP_SCOPE ||
                              inner->op_type == OP_LEAVE))
                    is_block = 1;
            }
        }
        if (is_block) {
            int i;
            ddc_emit_keyword(aTHX_ ctx, "if", 2);
            sv_catpvn(ctx->out, " (", 2);
            ddc_deparse_op(aTHX_ left, ctx);
            sv_catpvn(ctx->out, ") {\n", 4);
            ctx->indent++;
            ddc_deparse_stmts(aTHX_ right, ctx);
            ctx->indent--;
            sv_catpvn(ctx->out, "\n", 1);
            for (i = 0; i < ctx->indent; i++)
                sv_catpvn(ctx->out, "  ", 2);
            sv_catpvn(ctx->out, "}", 1);
            ctx->last_was_block = 1;
        } else {
            if (right && right->op_type == OP_NEXT) {
                ddc_deparse_op(aTHX_ right, ctx);
                sv_catpvn(ctx->out, " ", 1);
                ddc_emit_keyword(aTHX_ ctx, "if", 2);
                sv_catpvn(ctx->out, " ", 1);
                ddc_deparse_op(aTHX_ left, ctx);
            } else {
                if (need_parens) sv_catpvn(ctx->out, "(", 1);
                ctx->prec = my_prec;
                ddc_deparse_op(aTHX_ left, ctx);
                sv_catpvn(ctx->out, " ", 1);
                ddc_emit_operator(aTHX_ ctx, "&&", 2);
                sv_catpvn(ctx->out, " ", 1);
                if (right) ddc_deparse_op(aTHX_ right, ctx);
                if (need_parens) sv_catpvn(ctx->out, ")", 1);
                ctx->prec = saved;
            }
        }
        break;
    }
    case OP_OR: {
        loo_prec_t saved = ctx->prec;
        loo_prec_t my_prec = ddc_op_precedence(type);
        int need_parens = (my_prec < saved);
        OP *left = cLOGOPo->op_first;
        OP *right = OpSIBLING(left);
        int is_block = 0;
        if (right) {
            U16 rt = right->op_type;
            if (rt == OP_SCOPE || rt == OP_LEAVE || rt == OP_LINESEQ)
                is_block = 1;
            if (rt == OP_NULL && (right->op_flags & OPf_KIDS)) {
                OP *inner = cUNOPx(right)->op_first;
                if (inner && (inner->op_type == OP_SCOPE ||
                              inner->op_type == OP_LEAVE))
                    is_block = 1;
            }
        }
        if (is_block) {
            int i;
            ddc_emit_keyword(aTHX_ ctx, "unless", 6);
            sv_catpvn(ctx->out, " (", 2);
            ddc_deparse_op(aTHX_ left, ctx);
            sv_catpvn(ctx->out, ") {\n", 4);
            ctx->indent++;
            ddc_deparse_stmts(aTHX_ right, ctx);
            ctx->indent--;
            sv_catpvn(ctx->out, "\n", 1);
            for (i = 0; i < ctx->indent; i++)
                sv_catpvn(ctx->out, "  ", 2);
            sv_catpvn(ctx->out, "}", 1);
            ctx->last_was_block = 1;
        } else {
            if (need_parens) sv_catpvn(ctx->out, "(", 1);
            ctx->prec = my_prec;
            ddc_deparse_op(aTHX_ left, ctx);
            sv_catpvn(ctx->out, " ", 1);
            ddc_emit_operator(aTHX_ ctx, "||", 2);
            sv_catpvn(ctx->out, " ", 1);
            if (right) ddc_deparse_op(aTHX_ right, ctx);
            if (need_parens) sv_catpvn(ctx->out, ")", 1);
            ctx->prec = saved;
        }
        break;
    }
    case OP_DOR: {
        loo_prec_t saved = ctx->prec;
        loo_prec_t my_prec = ddc_op_precedence(type);
        int need_parens = (my_prec < saved);
        OP *left = cLOGOPo->op_first;
        OP *right = OpSIBLING(left);
        if (need_parens) sv_catpvn(ctx->out, "(", 1);
        ctx->prec = my_prec;
        ddc_deparse_op(aTHX_ left, ctx);
        sv_catpvn(ctx->out, " ", 1);
        ddc_emit_operator(aTHX_ ctx, "//", 2);
        sv_catpvn(ctx->out, " ", 1);
        if (right) ddc_deparse_op(aTHX_ right, ctx);
        if (need_parens) sv_catpvn(ctx->out, ")", 1);
        ctx->prec = saved;
        break;
    }

    /* ── Compound logical assignment (&&=, ||=, //=) ─────────── */
    case OP_ANDASSIGN: case OP_ORASSIGN: case OP_DORASSIGN: {
        const char *sym;
        OP *left = cLOGOPo->op_first;
        OP *right = OpSIBLING(left);
        switch (type) {
            case OP_ANDASSIGN: sym = "&&="; break;
            case OP_ORASSIGN:  sym = "||="; break;
            default:           sym = "//="; break;
        }
        ddc_deparse_op(aTHX_ left, ctx);
        sv_catpvn(ctx->out, " ", 1);
        ddc_emit_operator(aTHX_ ctx, sym, strlen(sym));
        sv_catpvn(ctx->out, " ", 1);
        /* The right child is a sassign; deparse its first child (the value) */
        if (right && right->op_type == OP_SASSIGN &&
            (right->op_flags & OPf_KIDS))
            ddc_deparse_op(aTHX_ cBINOPx(right)->op_first, ctx);
        else if (right)
            ddc_deparse_op(aTHX_ right, ctx);
        break;
    }
    case OP_NOT:
        ddc_emit_operator(aTHX_ ctx, "!", 1);
        if (cUNOPo->op_first)
            ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
        break;

    /* ── Unary ops ────────────────────────────────────────────── */
    case OP_NEGATE:
        ddc_emit_operator(aTHX_ ctx, "-", 1);
        if (cUNOPo->op_first)
            ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
        break;
    case OP_COMPLEMENT:
        ddc_emit_operator(aTHX_ ctx, "~", 1);
        if (cUNOPo->op_first)
            ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
        break;

    /* ── Assignment ───────────────────────────────────────────── */
    case OP_SASSIGN: {
        OP *right = cBINOPo->op_first;
        OP *left = OpSIBLING(right);
        if (left) ddc_deparse_op(aTHX_ left, ctx);
        sv_catpvn(ctx->out, " ", 1);
        ddc_emit_operator(aTHX_ ctx, "=", 1);
        sv_catpvn(ctx->out, " ", 1);
        ddc_deparse_op(aTHX_ right, ctx);
        break;
    }
    case OP_AASSIGN: {
        OP *right = cBINOPo->op_first;
        OP *left = OpSIBLING(right);
        int rhs_list = 0;

        /* Check for padrange-in-RHS optimisation: when the first
           ex-list starts with padrange(LVINTRO), the padrange IS
           the LHS and remaining siblings are the actual RHS.
           e.g.  my ($a, $b) = @_  →  aassign(ex-list(padrange,rv2av), ex-list(pushmark,padsv*)) */
        if (right && right->op_type == OP_NULL &&
            (right->op_flags & OPf_KIDS))
        {
            OP *rk = cUNOPx(right)->op_first;
            if (rk && rk->op_type ==
#if PERL_VERSION >= 18
                OP_PADRANGE
#else
                0xFFFF  /* never matches on < 5.18 */
#endif
                &&
                (rk->op_private & OPpLVAL_INTRO))
            {
                OP *rhs_kid;
                int first_rhs = 1;
                /* Emit padrange as LHS: my ($a, $b) */
                ddc_deparse_op(aTHX_ rk, ctx);
                sv_catpvn(ctx->out, " ", 1);
                ddc_emit_operator(aTHX_ ctx, "=", 1);
                sv_catpvn(ctx->out, " ", 1);
                /* Emit remaining siblings as RHS */
                for (rhs_kid = OpSIBLING(rk); rhs_kid;
                     rhs_kid = OpSIBLING(rhs_kid)) {
                    if (!first_rhs) sv_catpvn(ctx->out, ", ", 2);
                    ddc_deparse_op(aTHX_ rhs_kid, ctx);
                    first_rhs = 0;
                }
                break;
            }
        }

        if (left) ddc_deparse_op(aTHX_ left, ctx);
        sv_catpvn(ctx->out, " ", 1);
        ddc_emit_operator(aTHX_ ctx, "=", 1);
        sv_catpvn(ctx->out, " ", 1);
        /* Detect multi-element RHS list: ex-list(pushmark, a, b, ...) */
        if (right->op_type == OP_NULL && (right->op_flags & OPf_KIDS)) {
            OP *rk = cUNOPx(right)->op_first;
            if (rk && rk->op_type == OP_PUSHMARK) {
                OP *r2 = OpSIBLING(rk);
                if (r2 && OpSIBLING(r2))
                    rhs_list = 1;
            }
        }
        if (rhs_list) sv_catpvn(ctx->out, "(", 1);
        ddc_deparse_op(aTHX_ right, ctx);
        if (rhs_list) sv_catpvn(ctx->out, ")", 1);
        break;
    }

    /* ── Ternary / if-else ────────────────────────────────────── */
    case OP_COND_EXPR: {
        OP *cond = cLOGOPo->op_first;
        OP *then_op = OpSIBLING(cond);
        OP *else_op = then_op ? OpSIBLING(then_op) : NULL;
        int is_block = 0;

        /* If cond is lineseq (elsif optimisation), extract the real
           condition which is the last child (after ex-nextstate) */
        if (cond && cond->op_type == OP_LINESEQ &&
            (cond->op_flags & OPf_KIDS))
        {
            OP *ls_kid;
            OP *last_cond = NULL;
            for (ls_kid = cUNOPx(cond)->op_first; ls_kid;
                 ls_kid = OpSIBLING(ls_kid)) {
                if (ls_kid->op_type != OP_NULL &&
                    ls_kid->op_type != OP_NEXTSTATE)
                    last_cond = ls_kid;
            }
            if (last_cond)
                cond = last_cond;
        }

        /* Detect block-style if/else vs inline ternary */
        if (then_op) {
            U16 tt = then_op->op_type;
            if (tt == OP_SCOPE || tt == OP_LEAVE || tt == OP_LINESEQ)
                is_block = 1;
            if (tt == OP_NULL && (then_op->op_flags & OPf_KIDS)) {
                OP *inner = cUNOPx(then_op)->op_first;
                if (inner && (inner->op_type == OP_SCOPE ||
                              inner->op_type == OP_LEAVE))
                    is_block = 1;
            }
        }

        if (is_block) {
            int i;
            ddc_emit_keyword(aTHX_ ctx, "if", 2);
            sv_catpvn(ctx->out, " (", 2);
            ddc_deparse_op(aTHX_ cond, ctx);
            sv_catpvn(ctx->out, ") {\n", 4);
            ctx->indent++;
            ddc_deparse_stmts(aTHX_ then_op, ctx);
            ctx->indent--;
            sv_catpvn(ctx->out, "\n", 1);
            for (i = 0; i < ctx->indent; i++)
                sv_catpvn(ctx->out, "  ", 2);
            sv_catpvn(ctx->out, "}", 1);

            if (else_op) {
                /* Check if else branch is another cond_expr (elsif).
                   May be wrapped in a null. */
                OP *inner_cond = else_op;
                if (inner_cond->op_type == OP_NULL &&
                    (inner_cond->op_flags & OPf_KIDS))
                    inner_cond = cUNOPx(inner_cond)->op_first;
                if (inner_cond && inner_cond->op_type == OP_COND_EXPR) {
                    sv_catpvn(ctx->out, " els", 4);
                    ddc_deparse_op(aTHX_ inner_cond, ctx);
                } else {
                    sv_catpvn(ctx->out, " ", 1);
                    ddc_emit_keyword(aTHX_ ctx, "else", 4);
                    sv_catpvn(ctx->out, " {\n", 3);
                    ctx->indent++;
                    ddc_deparse_stmts(aTHX_ else_op, ctx);
                    ctx->indent--;
                    sv_catpvn(ctx->out, "\n", 1);
                    for (i = 0; i < ctx->indent; i++)
                        sv_catpvn(ctx->out, "  ", 2);
                    sv_catpvn(ctx->out, "}", 1);
                }
            }
            ctx->last_was_block = 1;
        } else {
            int then_is_list = 0;
            ddc_deparse_op(aTHX_ cond, ctx);
            sv_catpvn(ctx->out, " ", 1);
            ddc_emit_operator(aTHX_ ctx, "?", 1);
            sv_catpvn(ctx->out, " ", 1);
            if (then_op && then_op->op_type == OP_LIST)
                then_is_list = 1;
            else if (then_op && then_op->op_type == OP_NULL &&
                (then_op->op_flags & OPf_KIDS)) {
                OP *tk;
                int count = 0;
                for (tk = cUNOPx(then_op)->op_first; tk;
                     tk = OpSIBLING(tk)) {
                    if (tk->op_type == OP_PUSHMARK) continue;
                    if (tk->op_type == OP_NULL && !(tk->op_flags & OPf_KIDS))
                        continue;
                    count++;
                }
                if (count > 1) then_is_list = 1;
            }
            if (then_is_list) sv_catpvn(ctx->out, "(", 1);
            if (then_op) ddc_deparse_op(aTHX_ then_op, ctx);
            if (then_is_list) sv_catpvn(ctx->out, ")", 1);
            sv_catpvn(ctx->out, " ", 1);
            ddc_emit_operator(aTHX_ ctx, ":", 1);
            sv_catpvn(ctx->out, " ", 1);
            if (else_op) ddc_deparse_op(aTHX_ else_op, ctx);
        }
        break;
    }

    /* ── return ───────────────────────────────────────────────── */
    case OP_RETURN: {
        OP *kid;
        int first = 1;
        ddc_emit_keyword(aTHX_ ctx, "return", 6);
        if (o->op_flags & OPf_KIDS) {
            for (kid = cUNOPo->op_first; kid; kid = OpSIBLING(kid)) {
                if (kid->op_type == OP_PUSHMARK) continue;
                if (!first) sv_catpvn(ctx->out, ", ", 2);
                sv_catpvn(ctx->out, " ", 1);
                ddc_deparse_op(aTHX_ kid, ctx);
                first = 0;
#if PERL_VERSION >= 18
                if (kid->op_type == OP_PADRANGE) {
                    int skip = (int)(kid->op_private & OPpPADRANGE_COUNTMASK);
                    while (skip-- > 0 && OpSIBLING(kid)) kid = OpSIBLING(kid);
                }
#endif
            }
        }
        break;
    }

    /* ── my (padrange: Perl 5.18+ optimises consecutive my()) ── */
#if PERL_VERSION >= 18
    case OP_PADRANGE: {
        PADOFFSET base = o->op_targ;
        int count = (int)(o->op_private & OPpPADRANGE_COUNTMASK);
        int is_intro = (o->op_private & OPpLVAL_INTRO) ? 1 : 0;
        int i;
        if (is_intro) {
            ddc_emit_keyword(aTHX_ ctx, "my", 2);
            sv_catpvn(ctx->out, " ", 1);
        }
        if (count > 1) sv_catpvn(ctx->out, "(", 1);
        for (i = 0; i < count; i++) {
            const char *name = ddc_padname_for_targ(aTHX_ ctx, base + i);
            if (i > 0) sv_catpvn(ctx->out, ", ", 2);
            if (name)
                ddc_emit_variable(aTHX_ ctx, name, strlen(name));
            else
                sv_catpvf(ctx->out, "$pad_%d", (int)(base + i));
        }
        if (count > 1) sv_catpvn(ctx->out, ")", 1);
        break;
    }
#endif /* PERL_VERSION >= 18 */

    /* ── Stringify (string context) ───────────────────────────── */
    case OP_STRINGIFY:
        if (o->op_flags & OPf_KIDS)
            ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
        break;

    /* ── Array/hash element access ────────────────────────────── */
    case OP_AELEM: {
        OP *av_op = cBINOPo->op_first;
        OP *idx_op = OpSIBLING(av_op);
        /* rv2av(gv) should emit $name not @name for element access */
        if (av_op->op_type == OP_RV2AV && (av_op->op_flags & OPf_KIDS)) {
            OP *inner = cUNOPx(av_op)->op_first;
            if (inner && inner->op_type == OP_GV) {
                SV *name = ddc_gv_from_op_cv(aTHX_ inner, ctx->cv);
                const char *pv = SvPV_nolen(name);
                SV *var = strEQ(pv, "_") ? newSVpvs("$_")
                                         : newSVpvf("$%s", pv);
                STRLEN vlen;
                const char *vpv = SvPV(var, vlen);
                ddc_emit_variable(aTHX_ ctx, vpv, vlen);
                SvREFCNT_dec(name);
                SvREFCNT_dec(var);
            } else {
                ddc_deparse_op(aTHX_ av_op, ctx);
            }
        } else if (av_op->op_type == OP_PADAV) {
            const char *name = ddc_padname_for_targ(aTHX_ ctx,
                                                     av_op->op_targ);
            if (name) {
                SV *var = newSVpvf("$%s", name + 1);
                STRLEN vlen;
                const char *vpv = SvPV(var, vlen);
                ddc_emit_variable(aTHX_ ctx, vpv, vlen);
                SvREFCNT_dec(var);
            } else {
                ddc_deparse_op(aTHX_ av_op, ctx);
            }
        } else {
            ddc_deparse_op(aTHX_ av_op, ctx);
        }
        sv_catpvn(ctx->out, "[", 1);
        if (idx_op) ddc_deparse_op(aTHX_ idx_op, ctx);
        sv_catpvn(ctx->out, "]", 1);
        break;
    }
    case OP_HELEM: {
        OP *hv_op = cBINOPo->op_first;
        OP *key_op = OpSIBLING(hv_op);
        int need_arrow = 0;
        /* rv2hv(gv) should emit $name not %name for element access;
           rv2hv(padsv/rv2sv/helem/aelem/...) means arrow-deref. */
        if (hv_op->op_type == OP_RV2HV && (hv_op->op_flags & OPf_KIDS)) {
            OP *inner = cUNOPx(hv_op)->op_first;
            if (inner && inner->op_type == OP_GV) {
                SV *name = ddc_gv_from_op_cv(aTHX_ inner, ctx->cv);
                SV *var = newSVpvf("$%s", SvPV_nolen(name));
                STRLEN vlen;
                const char *vpv = SvPV(var, vlen);
                ddc_emit_variable(aTHX_ ctx, vpv, vlen);
                SvREFCNT_dec(name);
                SvREFCNT_dec(var);
            } else if (inner && (inner->op_type == OP_PADSV
                                 || inner->op_type == OP_RV2SV)) {
                /* $h->{key} — hashref deref via scalar */
                ddc_deparse_op(aTHX_ inner, ctx);
                need_arrow = 1;
            } else if (inner && (inner->op_type == OP_HELEM
                                 || inner->op_type == OP_AELEM)) {
                /* $h->{a}{b} or $a->[0]{key} — chained deref,
                   no arrow needed between consecutive subscripts */
                ddc_deparse_op(aTHX_ inner, ctx);
            } else {
                /* Fallback: other deref expression, use arrow */
                if (inner) {
                    ddc_deparse_op(aTHX_ inner, ctx);
                    need_arrow = 1;
                } else {
                    ddc_deparse_op(aTHX_ hv_op, ctx);
                }
            }
        } else if (hv_op->op_type == OP_PADHV) {
            const char *name = ddc_padname_for_targ(aTHX_ ctx,
                                                     hv_op->op_targ);
            if (name) {
                SV *var = newSVpvf("$%s", name + 1);
                STRLEN vlen;
                const char *vpv = SvPV(var, vlen);
                ddc_emit_variable(aTHX_ ctx, vpv, vlen);
                SvREFCNT_dec(var);
            } else {
                ddc_deparse_op(aTHX_ hv_op, ctx);
            }
        } else {
            ddc_deparse_op(aTHX_ hv_op, ctx);
        }
        if (need_arrow)
            sv_catpvn(ctx->out, "->", 2);
        sv_catpvn(ctx->out, "{", 1);
        if (key_op) ddc_deparse_op(aTHX_ key_op, ctx);
        sv_catpvn(ctx->out, "}", 1);
        break;
    }
    case OP_ASLICE: {
        OP *av_op = NULL;
        OP *idx_op = NULL;
        OP *k;

        for (k = cLISTOPo->op_first; k; k = OpSIBLING(k)) {
            if (k->op_type == OP_PUSHMARK) continue;
            if (k->op_type == OP_NULL && !(k->op_flags & OPf_KIDS)) continue;
            if (!av_op) av_op = k;
            else { idx_op = k; break; }
        }

        /* Some optrees present indices first and array second */
        if (av_op && idx_op) {
            int av_is_list = (av_op->op_type == OP_LIST ||
                              (av_op->op_type == OP_NULL &&
                               av_op->op_targ == OP_LIST));
            int idx_is_array = (idx_op->op_type == OP_RV2AV ||
                                idx_op->op_type == OP_PADAV);
            if (av_is_list && idx_is_array) {
                OP *tmp = av_op;
                av_op = idx_op;
                idx_op = tmp;
            }
        }

        if (av_op && av_op->op_type == OP_RV2AV && (av_op->op_flags & OPf_KIDS)) {
            OP *inner = cUNOPx(av_op)->op_first;
            if (inner && inner->op_type == OP_GV) {
                SV *name = ddc_gv_from_op_cv(aTHX_ inner, ctx->cv);
                STRLEN nlen;
                const char *npv = SvPV(name, nlen);
                if (strEQ(npv, "_")) {
                    ddc_emit_variable(aTHX_ ctx, "@_", 2);
                } else {
                    SV *var = newSVpvf("@%s", npv);
                    STRLEN vlen;
                    const char *vpv = SvPV(var, vlen);
                    ddc_emit_variable(aTHX_ ctx, vpv, vlen);
                    SvREFCNT_dec(var);
                }
                SvREFCNT_dec(name);
            } else {
                ddc_deparse_op(aTHX_ av_op, ctx);
            }
        } else if (av_op && av_op->op_type == OP_PADAV) {
            const char *name = ddc_padname_for_targ(aTHX_ ctx, av_op->op_targ);
            if (name)
                ddc_emit_variable(aTHX_ ctx, name, strlen(name));
            else
                ddc_deparse_op(aTHX_ av_op, ctx);
        } else if (av_op) {
            ddc_deparse_op(aTHX_ av_op, ctx);
        }

        sv_catpvn(ctx->out, "[", 1);
        if (idx_op) ddc_deparse_op(aTHX_ idx_op, ctx);
        sv_catpvn(ctx->out, "]", 1);
        break;
    }
    case OP_HSLICE: {
        OP *hv_op = NULL;
        OP *key_op = NULL;
        OP *k;

        for (k = cLISTOPo->op_first; k; k = OpSIBLING(k)) {
            if (k->op_type == OP_PUSHMARK) continue;
            if (k->op_type == OP_NULL && !(k->op_flags & OPf_KIDS)) continue;
            if (!hv_op) hv_op = k;
            else { key_op = k; break; }
        }

        /* Some optrees present keys first and hash second */
        if (hv_op && key_op) {
            int hv_is_list = (hv_op->op_type == OP_LIST ||
                              (hv_op->op_type == OP_NULL &&
                               hv_op->op_targ == OP_LIST));
            int key_is_hash = (key_op->op_type == OP_RV2HV ||
                               key_op->op_type == OP_PADHV);
            if (hv_is_list && key_is_hash) {
                OP *tmp = hv_op;
                hv_op = key_op;
                key_op = tmp;
            }
        }

        if (hv_op && hv_op->op_type == OP_RV2HV && (hv_op->op_flags & OPf_KIDS)) {
            OP *inner = cUNOPx(hv_op)->op_first;
            if (inner && inner->op_type == OP_GV) {
                SV *name = ddc_gv_from_op_cv(aTHX_ inner, ctx->cv);
                STRLEN nlen;
                const char *npv = SvPV(name, nlen);
                SV *var = newSVpvf("@%s", npv);
                STRLEN vlen;
                const char *vpv = SvPV(var, vlen);
                ddc_emit_variable(aTHX_ ctx, vpv, vlen);
                SvREFCNT_dec(var);
                SvREFCNT_dec(name);
            } else {
                ddc_deparse_op(aTHX_ hv_op, ctx);
            }
        } else if (hv_op && hv_op->op_type == OP_PADHV) {
            const char *name = ddc_padname_for_targ(aTHX_ ctx, hv_op->op_targ);
            if (name) {
                SV *var = newSVpvf("@%s", name + 1);
                STRLEN vlen;
                const char *vpv = SvPV(var, vlen);
                ddc_emit_variable(aTHX_ ctx, vpv, vlen);
                SvREFCNT_dec(var);
            } else {
                ddc_deparse_op(aTHX_ hv_op, ctx);
            }
        } else if (hv_op) {
            ddc_deparse_op(aTHX_ hv_op, ctx);
        }

        sv_catpvn(ctx->out, "{", 1);
        if (key_op) ddc_deparse_op(aTHX_ key_op, ctx);
        sv_catpvn(ctx->out, "}", 1);
        break;
    }

    /* ── Multideref (optimised chained deref, Perl 5.22+) ────── */
#if PERL_VERSION >= 22
    case OP_MULTIDEREF: {
        UNOP_AUX_item *items = cUNOP_AUXo->op_aux;
        UV actions = items[0].uv;
        int idx = 1;
        int is_hash, derefs = 0;
        int has_exists = 0, has_delete = 0;

#ifdef OPpMULTIDEREF_EXISTS
        has_exists = (o->op_private & OPpMULTIDEREF_EXISTS) ? 1 : 0;
#endif
#ifdef OPpMULTIDEREF_DELETE
        has_delete = (o->op_private & OPpMULTIDEREF_DELETE) ? 1 : 0;
#endif
        if (has_exists) {
            ddc_emit_keyword(aTHX_ ctx, "exists", 6);
            sv_catpvn(ctx->out, "(", 1);
        } else if (has_delete) {
            ddc_emit_keyword(aTHX_ ctx, "delete", 6);
            sv_catpvn(ctx->out, "(", 1);
        }

        /* initial expression if present */
        if (o->op_flags & OPf_KIDS) {
            OP *first = cUNOPo->op_first;
            if (first && first->op_type != OP_NULL)
                ddc_deparse_op(aTHX_ first, ctx);
        }

        while (1) {
            UV action = actions & MDEREF_ACTION_MASK;
            UV index_type;

            if (action == MDEREF_reload) {
                actions = items[idx++].uv;
                continue;
            }

            is_hash = (action == MDEREF_HV_pop_rv2hv_helem
                    || action == MDEREF_HV_gvsv_vivify_rv2hv_helem
                    || action == MDEREF_HV_padsv_vivify_rv2hv_helem
                    || action == MDEREF_HV_vivify_rv2hv_helem
                    || action == MDEREF_HV_padhv_helem
                    || action == MDEREF_HV_gvhv_helem);

            switch (action) {
            case MDEREF_AV_padav_aelem:
            case MDEREF_HV_padhv_helem: {
                PADOFFSET po = items[idx++].pad_offset;
                const char *name = ddc_padname_for_targ(aTHX_ ctx, po);
                if (name) {
                    SV *var = newSVpvf("$%s", name + 1);
                    STRLEN vlen;
                    const char *vpv = SvPV(var, vlen);
                    ddc_emit_variable(aTHX_ ctx, vpv, vlen);
                    SvREFCNT_dec(var);
                }
                derefs = 1;
                break;
            }
            case MDEREF_AV_gvav_aelem:
            case MDEREF_HV_gvhv_helem: {
                SV *namesv = ddc_aux_item_sv(aTHX_ &items[idx++], ctx->cv);
                if (namesv && SvTYPE(namesv) == SVt_PVGV) {
                    const char *name = GvNAME((GV*)namesv);
                    if (strEQ(name, "_")) {
                        ddc_emit_variable(aTHX_ ctx,
                            is_hash ? "%_" : "$_",
                            2);
                    } else {
                        SV *var = newSVpvf("%c%s",
                            is_hash ? '%' : '$', name);
                        STRLEN vlen;
                        const char *vpv = SvPV(var, vlen);
                        ddc_emit_variable(aTHX_ ctx, vpv, vlen);
                        SvREFCNT_dec(var);
                    }
                }
                derefs = 1;
                break;
            }
            case MDEREF_AV_padsv_vivify_rv2av_aelem:
            case MDEREF_HV_padsv_vivify_rv2hv_helem: {
                PADOFFSET po = items[idx++].pad_offset;
                const char *name = ddc_padname_for_targ(aTHX_ ctx, po);
                if (name)
                    ddc_emit_variable(aTHX_ ctx, name, strlen(name));
                if (!derefs++) sv_catpvn(ctx->out, "->", 2);
                break;
            }
            case MDEREF_AV_gvsv_vivify_rv2av_aelem:
            case MDEREF_HV_gvsv_vivify_rv2hv_helem: {
                SV *namesv = ddc_aux_item_sv(aTHX_ &items[idx++], ctx->cv);
                if (namesv && SvTYPE(namesv) == SVt_PVGV) {
                    const char *name = GvNAME((GV*)namesv);
                    SV *var = newSVpvf("$%s", name);
                    STRLEN vlen;
                    const char *vpv = SvPV(var, vlen);
                    ddc_emit_variable(aTHX_ ctx, vpv, vlen);
                    SvREFCNT_dec(var);
                }
                if (!derefs++) sv_catpvn(ctx->out, "->", 2);
                break;
            }
            case MDEREF_AV_pop_rv2av_aelem:
            case MDEREF_HV_pop_rv2hv_helem:
                if (!derefs++) sv_catpvn(ctx->out, "->", 2);
                break;
            case MDEREF_AV_vivify_rv2av_aelem:
            case MDEREF_HV_vivify_rv2hv_helem:
                if (!derefs++) sv_catpvn(ctx->out, "->", 2);
                break;
            default:
                break;
            }

            index_type = actions & MDEREF_INDEX_MASK;
            if (index_type == MDEREF_INDEX_none)
                break;

            sv_catpvn(ctx->out, is_hash ? "{" : "[", 1);

            if (index_type == MDEREF_INDEX_const) {
                if (is_hash) {
                    SV *key = ddc_aux_item_sv(aTHX_ &items[idx++], ctx->cv);
                    if (key) {
                        STRLEN klen;
                        const char *kpv = SvPV(key, klen);
                        sv_catpvn(ctx->out, "'", 1);
                        ddc_emit_dep_string(aTHX_ ctx, kpv, klen);
                        sv_catpvn(ctx->out, "'", 1);
                    }
                } else {
                    IV ival = items[idx++].iv;
                    sv_catpvf(ctx->out, "%" IVdf, ival);
                }
            } else if (index_type == MDEREF_INDEX_padsv) {
                PADOFFSET po = items[idx++].pad_offset;
                const char *name = ddc_padname_for_targ(aTHX_ ctx, po);
                if (name)
                    ddc_emit_variable(aTHX_ ctx, name, strlen(name));
            } else if (index_type == MDEREF_INDEX_gvsv) {
                SV *namesv = ddc_aux_item_sv(aTHX_ &items[idx++], ctx->cv);
                if (namesv && SvTYPE(namesv) == SVt_PVGV) {
                    const char *name = GvNAME((GV*)namesv);
                    SV *var = newSVpvf("$%s", name);
                    STRLEN vlen;
                    const char *vpv = SvPV(var, vlen);
                    ddc_emit_variable(aTHX_ ctx, vpv, vlen);
                    SvREFCNT_dec(var);
                }
            }

            sv_catpvn(ctx->out, is_hash ? "}" : "]", 1);

            if (actions & MDEREF_FLAG_last)
                break;
            actions >>= MDEREF_SHIFT;
        }
        if (has_exists || has_delete)
            sv_catpvn(ctx->out, ")", 1);
        break;
    }
#endif /* PERL_VERSION >= 22 */

    /* ── Function/method call ─────────────────────────────────── */
    case OP_ENTERSUB: {
        OP *kid = cUNOPo->op_first;
        OP *start_kid;
        OP *last = NULL;
        int first_arg = 1;
        int is_method = 0;
        OP *method_op = NULL;
        OP *actual_method_op = NULL;

        /* Unwrap ex-list: entersub often has a single null(ex-list)
           child containing pushmark, args, and the function/method */
        if (kid && kid->op_type == OP_NULL && !OpSIBLING(kid) &&
            (kid->op_flags & OPf_KIDS))
            kid = cUNOPx(kid)->op_first;

        start_kid = kid;
        for (; kid; kid = OpSIBLING(kid))
            last = kid;

        /* Detect method call — last op is OP_METHOD_NAMED
           (including wrapped forms) */
        if (last) {
            if (last->op_type == OP_METHOD_NAMED) {
                is_method = 1;
                actual_method_op = last;
            } else if (last->op_type == OP_NULL &&
                     last->op_targ == OP_METHOD_NAMED) {
                is_method = 1;
                /* Find the actual method_named inside the null wrapper */
                if (last->op_flags & OPf_KIDS) {
                    OP *mk;
                    for (mk = cUNOPx(last)->op_first; mk; mk = OpSIBLING(mk)) {
                        if (mk->op_type == OP_METHOD_NAMED) {
                            actual_method_op = mk;
                            break;
                        }
                    }
                    if (!actual_method_op)
                        actual_method_op = cUNOPx(last)->op_first;
                } else {
                    actual_method_op = last;
                }
            }
        }

        if (is_method && actual_method_op) {
            /* Method call: invocant->method(args) */
            SV *meth_name = ddc_const_sv(aTHX_ actual_method_op, ctx->cv);
            OP *invocant = NULL;
            method_op = last;

            for (kid = start_kid; kid && kid != method_op;
                 kid = OpSIBLING(kid)) {
                if (kid->op_type == OP_PUSHMARK ||
                    kid->op_type == OP_NULL)
                    continue;
                if (!invocant) {
                    invocant = kid;
                } else {
                    break;
                }
            }
            /* Emit invocant->method(args) */
            if (invocant)
                ddc_deparse_op(aTHX_ invocant, ctx);
            sv_catpvn(ctx->out, "->", 2);
            if (meth_name && SvOK(meth_name)) {
                if (SvTYPE(meth_name) == SVt_PVGV) {
                    const char *mpv = GvNAME((GV *)meth_name);
                    if (mpv)
                        ddc_emit_keyword(aTHX_ ctx, mpv, strlen(mpv));
                } else {
                    STRLEN mlen;
                    const char *mpv = SvPV(meth_name, mlen);
                    ddc_emit_keyword(aTHX_ ctx, mpv, mlen);
                }
            }
            sv_catpvn(ctx->out, "(", 1);
            /* Args after invocant */
            first_arg = 1;
            for (kid = start_kid; kid && kid != method_op;
                 kid = OpSIBLING(kid)) {
                if (kid->op_type == OP_PUSHMARK ||
                    kid->op_type == OP_NULL)
                    continue;
                if (kid == invocant) {
#if PERL_VERSION >= 18
                    if (kid->op_type == OP_PADRANGE) {
                        int skip = (int)(kid->op_private & OPpPADRANGE_COUNTMASK);
                        while (skip-- > 0 && OpSIBLING(kid)) kid = OpSIBLING(kid);
                    }
#endif
                    continue;
                }
                if (!first_arg) sv_catpvn(ctx->out, ", ", 2);
                ddc_deparse_op(aTHX_ kid, ctx);
                first_arg = 0;
#if PERL_VERSION >= 18
                if (kid->op_type == OP_PADRANGE) {
                    int skip = (int)(kid->op_private & OPpPADRANGE_COUNTMASK);
                    while (skip-- > 0 && OpSIBLING(kid)) kid = OpSIBLING(kid);
                }
#endif
            }
            sv_catpvn(ctx->out, ")", 1);
        } else {
            /* Regular function call: last child is the function
               (ex-rv2cv or gv), preceding kids are args */
            OP *call_op = last;
            int coderef_like = 1;

            if (call_op && call_op->op_type == OP_NULL &&
                (call_op->op_flags & OPf_KIDS)) {
                OP *first_call_kid = NULL;
                OP *ck;
                int call_kids = 0;
                for (ck = cUNOPx(call_op)->op_first; ck; ck = OpSIBLING(ck)) {
                    if (ck->op_type == OP_PUSHMARK) continue;
                    if (ck->op_type == OP_NULL && !(ck->op_flags & OPf_KIDS)) continue;
                    if (!first_call_kid) first_call_kid = ck;
                    call_kids++;
                }
                if (first_call_kid && call_kids == 1)
                    call_op = first_call_kid;
            }

            if (call_op && (call_op->op_type == OP_GV ||
                            call_op->op_type == OP_RV2CV))
                coderef_like = 0;
            if (last)
                ddc_deparse_op(aTHX_ last, ctx);
            if (coderef_like)
                sv_catpvn(ctx->out, "->(", 3);
            else
                sv_catpvn(ctx->out, "(", 1);

            for (kid = start_kid; kid && kid != last;
                 kid = OpSIBLING(kid)) {
                if (kid->op_type == OP_PUSHMARK)
                    continue;
                if (!first_arg) sv_catpvn(ctx->out, ", ", 2);
                ddc_deparse_op(aTHX_ kid, ctx);
                first_arg = 0;
#if PERL_VERSION >= 18
                if (kid->op_type == OP_PADRANGE) {
                    int skip = (int)(kid->op_private & OPpPADRANGE_COUNTMASK);
                    while (skip-- > 0 && OpSIBLING(kid)) kid = OpSIBLING(kid);
                }
#endif
            }
            sv_catpvn(ctx->out, ")", 1);
        }
        break;
    }

    /* ── Block/scope wrappers ─────────────────────────────────── */
    case OP_LINESEQ:
    case OP_SCOPE:
    case OP_LEAVE:
    case OP_LEAVESUB:
        ddc_deparse_stmts(aTHX_ o, ctx);
        break;

    /* ── Loops ────────────────────────────────────────────────── */
    case OP_LEAVELOOP: {
        OP *enter = cBINOPo->op_first;
        OP *body_null = OpSIBLING(enter);   /* null wrapping and/or */
        OP *cond_op = NULL;
        OP *body_seq = NULL;
        OP *logic = NULL;
        int is_foreach = 0;
        int is_until = 0;
        int i;

        if (body_null && body_null->op_type == OP_NULL &&
            (body_null->op_flags & OPf_KIDS))
            logic = cUNOPx(body_null)->op_first;

        if (enter->op_type == OP_ENTERITER) {
            /* ── foreach my $var (LIST) { ... } ──────────── */
            OP *list_kid;
            const char *varname;
            is_foreach = 1;

            ddc_emit_keyword(aTHX_ ctx, "for", 3);
            /* Iterator variable from enteriter targ */
            varname = ddc_padname_for_targ(aTHX_ ctx, enter->op_targ);
            if (varname) {
                sv_catpvn(ctx->out, " ", 1);
                if (enter->op_private & OPpLVAL_INTRO)
                    ddc_emit_keyword(aTHX_ ctx, "my ", 3);
                ddc_emit_variable(aTHX_ ctx, varname, strlen(varname));
            }
            sv_catpvn(ctx->out, " (", 2);
            /* The list is in enteriter's children, usually
               inside an ex-list wrapper.  OPf_STACKED on
               enteriter means it is an optimised range. */
            if (enter->op_flags & OPf_KIDS) {
                int first_item = 1;
                int is_range = (enter->op_flags & OPf_STACKED) ? 1 : 0;
                OP *list_root = cLISTOPx(enter)->op_first;
                /* Find the ex-list (OP_NULL with kids) that
                   wraps the actual list items */
                for (; list_root; list_root = OpSIBLING(list_root)) {
                    if (list_root->op_type == OP_NULL &&
                        (list_root->op_flags & OPf_KIDS))
                        break;
                }
                if (list_root) {
                    for (list_kid = cUNOPx(list_root)->op_first;
                         list_kid; list_kid = OpSIBLING(list_kid))
                    {
                        if (list_kid->op_type == OP_PUSHMARK) continue;
                        if (list_kid->op_type == OP_NULL &&
                            !(list_kid->op_flags & OPf_KIDS))
                            continue;
                        if (!first_item) {
                            if (is_range) {
                                sv_catpvn(ctx->out, " ", 1);
                                ddc_emit_operator(aTHX_ ctx, "..", 2);
                                sv_catpvn(ctx->out, " ", 1);
                            } else {
                                sv_catpvn(ctx->out, ", ", 2);
                            }
                        }
                        ddc_deparse_op(aTHX_ list_kid, ctx);
                        first_item = 0;
                    }
                }
            }
            sv_catpvn(ctx->out, ") {\n", 4);

            /* Body: inside the and(iter, lineseq) */
            if (logic && logic->op_type == OP_AND) {
                body_seq = OpSIBLING(cLOGOPx(logic)->op_first);
            }
        } else {
            /* ── while/until (COND) { ... } ──────────────── */
            if (logic) {
                if (logic->op_type == OP_AND) {
                    is_until = 0;
                    cond_op = cLOGOPx(logic)->op_first;
                    body_seq = OpSIBLING(cond_op);
                } else if (logic->op_type == OP_OR) {
                    is_until = 1;
                    cond_op = cLOGOPx(logic)->op_first;
                    body_seq = OpSIBLING(cond_op);
                }
            }

            ddc_emit_keyword(aTHX_ ctx,
                is_until ? "until" : "while",
                is_until ? 5 : 5);
            sv_catpvn(ctx->out, " (", 2);
            if (cond_op) ddc_deparse_op(aTHX_ cond_op, ctx);
            sv_catpvn(ctx->out, ") {\n", 4);
        }

        /* Deparse body */
        if (body_seq) {
            OP *stmt;
            int bfirst = 1;
            ctx->indent++;
            if (body_seq->op_flags & OPf_KIDS) {
                for (stmt = cUNOPx(body_seq)->op_first; stmt;
                     stmt = OpSIBLING(stmt))
                {
                    U16 stype = stmt->op_type;
                    /* Skip unstack (loop internal) */
                    if (stype == OP_UNSTACK) continue;
                    /* Skip pushmark / enter */
                    if (stype == OP_PUSHMARK || stype == OP_ENTER)
                        continue;
                    if (ddc_is_nextstate(stmt)) {
                        if (ddc_next_sibling_is_nextstate(stmt))
                            continue;
                        if (!bfirst) sv_catpvn(ctx->out, "\n", 1);
                        bfirst = 0;
                        ddc_deparse_indent(aTHX_ ctx);
                        continue;
                    }

                    /* ── C-style for detection inside loop body ── */
                    {
                        OP *n1 = OpSIBLING(stmt);
                        OP *n2 = n1 ? OpSIBLING(n1) : NULL;
                        OP *lop = NULL;
                        OP *skip_to = NULL;  /* sibling to skip to after for */
                        if (n1 && n1->op_type == OP_UNSTACK &&
                            n2 && n2->op_type == OP_LEAVELOOP &&
                            cBINOPx(n2)->op_first &&
                            cBINOPx(n2)->op_first->op_type == OP_ENTERLOOP) {
                            lop = n2; skip_to = n2;
                        }
                        else if (n1 && n1->op_type == OP_LEAVELOOP &&
                                 cBINOPx(n1)->op_first &&
                                 cBINOPx(n1)->op_first->op_type == OP_ENTERLOOP) {
                            lop = n1; skip_to = n1;
                        }
                        /* 5.10: init → lineseq(nextstate, leaveloop) */
                        else if (n1 && n1->op_type == OP_LINESEQ &&
                                 (n1->op_flags & OPf_KIDS)) {
                            OP *ls_kid;
                            for (ls_kid = cUNOPx(n1)->op_first; ls_kid;
                                 ls_kid = OpSIBLING(ls_kid)) {
                                if (ls_kid->op_type == OP_LEAVELOOP &&
                                    cBINOPx(ls_kid)->op_first &&
                                    cBINOPx(ls_kid)->op_first->op_type == OP_ENTERLOOP) {
                                    lop = ls_kid;
                                    skip_to = n1;
                                    break;
                                }
                            }
                        }

                        if (lop) {
                            OP *body_null2 = OpSIBLING(cBINOPx(lop)->op_first);
                            OP *logic2 = NULL;
                            OP *cond2 = NULL;
                            OP *bseq2 = NULL;
                            OP *step2 = NULL;
                            OP *s2;
                            int bf2 = 1;
                            int ii;

                            if (body_null2 && body_null2->op_type == OP_NULL &&
                                (body_null2->op_flags & OPf_KIDS))
                                logic2 = cUNOPx(body_null2)->op_first;

                            if (logic2 && logic2->op_type == OP_AND) {
                                cond2 = cLOGOPx(logic2)->op_first;
                                bseq2 = OpSIBLING(cond2);
                            }

                            if (bseq2 && (bseq2->op_flags & OPf_KIDS)) {
                                OP *prev2 = NULL;
                                for (s2 = cUNOPx(bseq2)->op_first;
                                     s2; s2 = OpSIBLING(s2)) {
                                    if (s2->op_type == OP_UNSTACK) break;
                                    prev2 = s2;
                                }
                                if (prev2 && prev2->op_type != OP_NEXTSTATE &&
                                    prev2->op_type != OP_DBSTATE &&
                                    prev2->op_type != OP_SCOPE &&
                                    prev2->op_type != OP_LEAVE)
                                    step2 = prev2;
                            }

                            ddc_emit_keyword(aTHX_ ctx, "for", 3);
                            sv_catpvn(ctx->out, " (", 2);
                            ctx->prec = LOO_PREC_LOWEST;
                            ddc_deparse_op(aTHX_ stmt, ctx);
                            sv_catpvn(ctx->out, "; ", 2);
                            if (cond2) ddc_deparse_op(aTHX_ cond2, ctx);
                            sv_catpvn(ctx->out, "; ", 2);
                            if (step2) ddc_deparse_op(aTHX_ step2, ctx);
                            sv_catpvn(ctx->out, ") {\n", 4);

                            ctx->indent++;
                            if (bseq2 && (bseq2->op_flags & OPf_KIDS)) {
                                for (s2 = cUNOPx(bseq2)->op_first;
                                     s2; s2 = OpSIBLING(s2))
                                {
                                    U16 st = s2->op_type;
                                    if (st == OP_UNSTACK) continue;
                                    if (s2 == step2) continue;
                                    if (st == OP_PUSHMARK || st == OP_ENTER)
                                        continue;
                                    if (ddc_is_nextstate(s2)) {
                                        if (ddc_next_sibling_is_nextstate(s2))
                                            continue;
                                        if (!bf2) sv_catpvn(ctx->out, "\n", 1);
                                        bf2 = 0;
                                        ddc_deparse_indent(aTHX_ ctx);
                                        continue;
                                    }
                                    ctx->prec = LOO_PREC_LOWEST;
                                    ddc_deparse_op(aTHX_ s2, ctx);
                                    if (st != OP_LINESEQ && st != OP_SCOPE &&
                                        st != OP_LEAVE && st != OP_LEAVELOOP)
                                        sv_catpvn(ctx->out, ";", 1);
                                }
                            }
                            ctx->indent--;

                            sv_catpvn(ctx->out, "\n", 1);
                            for (ii = 0; ii < ctx->indent; ii++)
                                sv_catpvn(ctx->out, "  ", 2);
                            sv_catpvn(ctx->out, "}", 1);

                            stmt = skip_to;
                            continue;
                        }
                    }

                    if (bfirst) {
                        ddc_deparse_indent(aTHX_ ctx);
                        bfirst = 0;
                    }
                    ctx->prec = LOO_PREC_LOWEST;
                    ddc_deparse_op(aTHX_ stmt, ctx);
                    if (stype != OP_LINESEQ && stype != OP_SCOPE &&
                        stype != OP_LEAVE && stype != OP_LEAVELOOP) {
                        /* Check for null wrapping scope */
                        int skip_semi = 0;
                        if (stype == OP_NULL &&
                            (stmt->op_flags & OPf_KIDS)) {
                            OP *inn = cUNOPx(stmt)->op_first;
                            if (inn && !OpSIBLING(inn)) {
                                U16 it = inn->op_type;
                                if (it == OP_LEAVE || it == OP_SCOPE
                                    || it == OP_LINESEQ)
                                    skip_semi = 1;
                            }
                        }
                        if (!skip_semi)
                            sv_catpvn(ctx->out, ";", 1);
                    }
                }
            } else {
                /* Single body op (e.g. scope) */
                ctx->indent++;
                ddc_deparse_stmts(aTHX_ body_seq, ctx);
                ctx->indent--;
            }
            ctx->indent--;
        }

        sv_catpvn(ctx->out, "\n", 1);
        for (i = 0; i < ctx->indent; i++)
            sv_catpvn(ctx->out, "  ", 2);
        sv_catpvn(ctx->out, "}", 1);
        break;
    }

    case OP_ENTERLOOP:
    case OP_ENTERITER:
    case OP_UNSTACK:
    case OP_ITER:
        /* These are handled by OP_LEAVELOOP above */
        break;

    /* ── Anonymous constructors ──────────────────────────────── */
    case OP_ANONLIST: {
        OP *kid;
        int first = 1;
        sv_catpvn(ctx->out, "[", 1);
        if (o->op_flags & OPf_KIDS) {
            for (kid = cUNOPo->op_first; kid; kid = OpSIBLING(kid)) {
                if (kid->op_type == OP_PUSHMARK) continue;
#if PERL_VERSION >= 18
                if (kid->op_type == OP_PADRANGE) continue;
#endif
                if (!first) sv_catpvn(ctx->out, ", ", 2);
                ddc_deparse_op(aTHX_ kid, ctx);
                first = 0;
            }
        }
        sv_catpvn(ctx->out, "]", 1);
        break;
    }
    case OP_ANONHASH: {
        OP *kid;
        int pair_count = 0;
        int is_key = 1;
        sv_catpvn(ctx->out, "{", 1);
        if (o->op_flags & OPf_KIDS) {
            for (kid = cUNOPo->op_first; kid; kid = OpSIBLING(kid)) {
                if (kid->op_type == OP_PUSHMARK) continue;
#if PERL_VERSION >= 18
                if (kid->op_type == OP_PADRANGE) continue;
#endif
                if (is_key && pair_count > 0)
                    sv_catpvn(ctx->out, ", ", 2);
                ddc_deparse_op(aTHX_ kid, ctx);
                if (is_key) {
                    sv_catpvn(ctx->out, " => ", 4);
                    pair_count++;
                }
                is_key = !is_key;
            }
        }
        sv_catpvn(ctx->out, "}", 1);
        break;
    }

    /* ── List ─────────────────────────────────────────────────── */
    case OP_LIST: {
        OP *kid;
        int first = 1;
        if (!(o->op_flags & OPf_KIDS)) break;
        for (kid = cUNOPo->op_first; kid; kid = OpSIBLING(kid)) {
            if (kid->op_type == OP_PUSHMARK) continue;
            if (!first) sv_catpvn(ctx->out, ", ", 2);
            ddc_deparse_op(aTHX_ kid, ctx);
            first = 0;
#if PERL_VERSION >= 18
            if (kid->op_type == OP_PADRANGE) {
                int skip = (int)(kid->op_private & OPpPADRANGE_COUNTMASK);
                while (skip-- > 0 && OpSIBLING(kid)) kid = OpSIBLING(kid);
            }
#endif
        }
        break;
    }

    /* ── Reference constructors ───────────────────────────────── */
    case OP_SREFGEN:
    case OP_REFGEN: {
        /* \expr or sub { ... } ref — recurse into child */
        if (o->op_flags & OPf_KIDS) {
            OP *kid = cUNOPo->op_first;
            /* Unwrap ex-list if present */
            if (kid && kid->op_type == OP_NULL && (kid->op_flags & OPf_KIDS))
                kid = cUNOPx(kid)->op_first;
            /* On older perls (< 5.18), refgen wraps an ex-list whose
               children are pushmark + anoncode.  Skip past pushmark
               and any other non-anoncode siblings to find anoncode. */
            {
                OP *scan = kid;
                while (scan) {
                    if (scan->op_type == OP_ANONCODE) {
                        kid = scan;
                        break;
                    }
                    scan = OpSIBLING(scan);
                }
            }
            if (kid && kid->op_type == OP_ANONCODE) {
                ddc_deparse_op(aTHX_ kid, ctx);
            } else {
                sv_catpvn(ctx->out, "\\", 1);
                if (kid) ddc_deparse_op(aTHX_ kid, ctx);
            }
        }
        break;
    }
    case OP_ANONCODE: {
        /* Anonymous sub: deparse the CV body.
           The CV may live in the parent CV's pad (indexed by op_targ)
           or in op_sv.  Modern Perl stores it in the pad on both
           ithreads and non-ithreads builds, so try the pad first. */
        CV *acv = NULL;
        /* Try pad lookup via op_targ (like B::Deparse) */
        if (o->op_targ > 0 && ctx->cv) {
            PADLIST *pl = CvPADLIST(ctx->cv);
            if (pl) {
                PAD *pad = PadlistARRAY(pl)[1];
                if (pad && (IV)o->op_targ <= AvFILLp(pad)) {
                    SV *sv = AvARRAY(pad)[(PADOFFSET)o->op_targ];
                    if (sv && SvTYPE(sv) == SVt_PVCV)
                        acv = (CV *)sv;
                }
            }
        }
        /* Fallback to op_sv (prototype CV) */
        if (!acv && cSVOPx_sv(o)) {
            SV *sv = cSVOPx_sv(o);
            if (SvTYPE(sv) == SVt_PVCV)
                acv = (CV *)sv;
        }
        if (acv && SvTYPE((SV*)acv) == SVt_PVCV && CvROOT(acv)) {
            int i;
            OP *root = CvROOT(acv);
            PADLIST *acv_pl = CvPADLIST(acv);
            DDCDeparse sub_ctx;
            Zero(&sub_ctx, 1, DDCDeparse);
            sub_ctx.style  = ctx->style;
            sub_ctx.out    = ctx->out;
            sub_ctx.indent = ctx->indent + 1;
            sub_ctx.prec   = LOO_PREC_LOWEST;
            sub_ctx.cv     = acv;
            if (acv_pl)
                sub_ctx.padnames = PadlistNAMES(acv_pl);
            ddc_emit_keyword(aTHX_ ctx, "sub", 3);
            sv_catpvn(ctx->out, " {\n", 3);
            ddc_deparse_stmts(aTHX_ root, &sub_ctx);
            sv_catpvn(ctx->out, "\n", 1);
            for (i = 0; i < ctx->indent; i++)
                sv_catpvn(ctx->out, "  ", 2);
            sv_catpvn(ctx->out, "}", 1);
        } else {
            sv_catpvs(ctx->out, "sub { ... }");
        }
        break;
    }

    /* ── print/say/warn/die ───────────────────────────────────── */
    case OP_PRINT: case OP_SAY: case OP_WARN: case OP_DIE: {
        const char *fn;
        OP *kid;
        int first = 1;
        switch (type) {
            case OP_PRINT: fn = "print"; break;
            case OP_SAY:   fn = "say";   break;
            case OP_WARN:  fn = "warn";  break;
            case OP_DIE:   fn = "die";   break;
            default: fn = "???";
        }
        ddc_emit_keyword(aTHX_ ctx, fn, strlen(fn));
        if (o->op_flags & OPf_KIDS) {
            sv_catpvn(ctx->out, " ", 1);
            for (kid = cUNOPo->op_first; kid; kid = OpSIBLING(kid)) {
                if (kid->op_type == OP_PUSHMARK) continue;
                if (!first) sv_catpvn(ctx->out, ", ", 2);
                ddc_deparse_op(aTHX_ kid, ctx);
                first = 0;
#if PERL_VERSION >= 18
                if (kid->op_type == OP_PADRANGE) {
                    int skip = (int)(kid->op_private & OPpPADRANGE_COUNTMASK);
                    while (skip-- > 0 && OpSIBLING(kid)) kid = OpSIBLING(kid);
                }
#endif
            }
        }
        break;
    }

    /* ── Builtins that take a single arg ──────────────────────── */
    case OP_DEFINED: case OP_REF: case OP_LENGTH:
    case OP_CHR: case OP_ORD: case OP_HEX: case OP_OCT:
    case OP_ABS: case OP_INT: case OP_SQRT:
    case OP_UC: case OP_LC: case OP_UCFIRST: case OP_LCFIRST:
    case OP_CHOMP: case OP_CHOP: case OP_CHDIR:
    case OP_EXISTS: case OP_DELETE: {
        const char *fn = PL_op_name[type];
        ddc_emit_keyword(aTHX_ ctx, fn, strlen(fn));
        if (o->op_flags & OPf_KIDS) {
            sv_catpvn(ctx->out, "(", 1);
            ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
            sv_catpvn(ctx->out, ")", 1);
        }
        break;
    }

    /* ── Regex match/qr ───────────────────────────────────────── */
    case OP_MATCH: {
        OP *kid = NULL;
        PMOP *pm = (PMOP *)o;

        if (o->op_flags & OPf_KIDS)
            kid = cUNOPo->op_first;

        /* Preserve bind target in expressions like $_[0] =~ m/foo/. */
        if (kid) {
            ddc_deparse_op(aTHX_ kid, ctx);
            sv_catpvn(ctx->out, " =~ ", 4);
        }

        if (PM_GETRE(pm)) {
            REGEXP *re = PM_GETRE(pm);
            STRLEN plen;
            const char *pat = RX_PRECOMP(re);
            plen = RX_PRELEN(re);
            sv_catpvn(ctx->out, "m/", 2);
            if (pat && plen) sv_catpvn(ctx->out, pat, plen);
            sv_catpvn(ctx->out, "/", 1);
        } else {
            sv_catpvn(ctx->out, "m//", 3);
        }
        break;
    }
    case OP_QR: {
        PMOP *pm = (PMOP *)o;
        if (PM_GETRE(pm)) {
            REGEXP *re = PM_GETRE(pm);
            STRLEN plen;
            const char *pat = RX_PRECOMP(re);
            plen = RX_PRELEN(re);
            sv_catpvn(ctx->out, "qr/", 3);
            if (pat && plen) sv_catpvn(ctx->out, pat, plen);
            sv_catpvn(ctx->out, "/", 1);
        } else {
            sv_catpvn(ctx->out, "qr//", 4);
        }
        break;
    }

    /* ── @_, @array, %hash deref ──────────────────────────────── */
    case OP_RV2AV:
        if (o->op_flags & OPf_KIDS) {
            OP *kid = cUNOPo->op_first;
            if (kid && kid->op_type == OP_GV) {
                SV *name = ddc_gv_from_op_cv(aTHX_ kid, ctx->cv);
                const char *pv = SvPV_nolen(name);
                if (strEQ(pv, "_")) {
                    ddc_emit_variable(aTHX_ ctx, "@_", 2);
                } else {
                    sv_catpvn(ctx->out, "@", 1);
                    ddc_emit_variable(aTHX_ ctx, pv, strlen(pv));
                }
                SvREFCNT_dec(name);
                break;
            }
        }
        sv_catpvn(ctx->out, "@", 1);
        if (o->op_flags & OPf_KIDS)
            ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
        break;

    case OP_RV2HV:
        sv_catpvn(ctx->out, "%", 1);
        if (o->op_flags & OPf_KIDS)
            ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
        break;

    case OP_RV2SV:
        sv_catpvn(ctx->out, "$", 1);
        if (o->op_flags & OPf_KIDS)
            ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
        break;

    /* ── Increment/decrement ──────────────────────────────────── */
    case OP_PREINC:
        ddc_emit_operator(aTHX_ ctx, "++", 2);
        if (cUNOPo->op_first) ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
        break;
    case OP_PREDEC:
        ddc_emit_operator(aTHX_ ctx, "--", 2);
        if (cUNOPo->op_first) ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
        break;
    case OP_POSTINC:
        if (cUNOPo->op_first) ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
        ddc_emit_operator(aTHX_ ctx, "++", 2);
        break;
    case OP_POSTDEC:
        if (cUNOPo->op_first) ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
        ddc_emit_operator(aTHX_ ctx, "--", 2);
        break;

    /* ── OP_MULTICONCAT (Perl 5.28+) ─────────────────────────── */
#if PERL_VERSION >= 28
    case OP_MULTICONCAT: {
        UNOP_AUX_item *aux = cUNOP_AUXo->op_aux;
        SSize_t nargs = aux[PERL_MULTICONCAT_IX_NARGS].ssize;
        const char *plain_pv;
        SSize_t *lens;
        OP *kids[64];
        int nkids = 0;
        SSize_t seg;
        int is_stacked = (o->op_flags & OPf_STACKED) ? 1 : 0;
        int is_append = (o->op_private & OPpMULTICONCAT_APPEND) ? 1 : 0;
        int is_targmy = (o->op_private & OPpTARGET_MY) ? 1 : 0;
        int out_parts = 0;

        plain_pv = aux[PERL_MULTICONCAT_IX_PLAIN_PV].pv;
        lens = &aux[PERL_MULTICONCAT_IX_LENGTHS].ssize;

        /* Collect arg kids — skip childless null placeholders */
        if (o->op_flags & OPf_KIDS) {
            OP *k;
            for (k = cUNOPo->op_first; k; k = OpSIBLING(k)) {
                /* Skip null ops with no children (const placeholders) */
                if (k->op_type == OP_NULL &&
                    !(k->op_flags & OPf_KIDS))
                    continue;
                if (nkids < 64) kids[nkids++] = k;
            }
        }

        /* Handle .= (append) */
        {
            int kidx = 0;

            /* If TARGMY + APPEND, target is in op_targ (padname) */
            if (is_targmy && is_append) {
                const char *name = ddc_padname_for_targ(aTHX_ ctx, o->op_targ);
                if (name)
                    ddc_emit_variable(aTHX_ ctx, name, strlen(name));
                else
                    sv_catpvf(ctx->out, "$pad_%d", (int)o->op_targ);
                sv_catpvn(ctx->out, " ", 1);
                ddc_emit_operator(aTHX_ ctx, ".=", 2);
                sv_catpvn(ctx->out, " ", 1);
            }
            /* If OPf_STACKED + APPEND, target is first kid */
            else if (is_stacked && is_append && kidx < nkids) {
                ddc_deparse_op(aTHX_ kids[kidx++], ctx);
                sv_catpvn(ctx->out, " ", 1);
                ddc_emit_operator(aTHX_ ctx, ".=", 2);
                sv_catpvn(ctx->out, " ", 1);
            }

            for (seg = 0; seg <= nargs; seg++) {
                SSize_t slen = lens[seg];

                /* Constant segment */
                if (slen > 0 && plain_pv) {
                    if (out_parts > 0) {
                        sv_catpvn(ctx->out, " ", 1);
                        ddc_emit_operator(aTHX_ ctx, ".", 1);
                        sv_catpvn(ctx->out, " ", 1);
                    }
                    sv_catpvn(ctx->out, "'", 1);
                    ddc_emit_dep_string(aTHX_ ctx, plain_pv, slen);
                    sv_catpvn(ctx->out, "'", 1);
                    out_parts++;
                }
                if (slen >= 0 && plain_pv)
                    plain_pv += slen;

                /* Variable segment (arg) */
                if (seg < nargs && kidx < nkids) {
                    if (out_parts > 0) {
                        sv_catpvn(ctx->out, " ", 1);
                        ddc_emit_operator(aTHX_ ctx, ".", 1);
                        sv_catpvn(ctx->out, " ", 1);
                    }
                    ddc_deparse_op(aTHX_ kids[kidx++], ctx);
                    out_parts++;
                }
            }
        }
        break;
    }
#endif /* PERL_VERSION >= 28 */

    /* ── Regex substitution s/// ──────────────────────────────── */
    case OP_SUBST: {
        PMOP *pm = (PMOP *)o;
        OP *kid = NULL;
        OP *repl_kid = NULL;
        REGEXP *re;

        if (o->op_flags & OPf_KIDS)
            kid = cUNOPo->op_first;

        /* Emit LHS binding if present */
        if (kid && (o->op_flags & OPf_STACKED)) {
            ddc_deparse_op(aTHX_ kid, ctx);
            sv_catpvn(ctx->out, " =~ ", 4);
            repl_kid = OpSIBLING(kid);
        }

        sv_catpvn(ctx->out, "s/", 2);
        re = PM_GETRE(pm);
        if (re) {
            STRLEN plen = RX_PRELEN(re);
            const char *pat = RX_PRECOMP(re);
            if (pat && plen)
                sv_catpvn(ctx->out, pat, plen);
        }
        sv_catpvn(ctx->out, "/", 1);

        /* Replacement: second kid when stacked, else first kid */
        if (!repl_kid && kid && !(o->op_flags & OPf_STACKED))
            repl_kid = kid;
        if (repl_kid && repl_kid->op_type == OP_CONST) {
            SV *sv = ddc_const_sv(aTHX_ repl_kid, ctx->cv);
            if (sv && SvPOK(sv)) {
                STRLEN rlen;
                const char *rpv = SvPV(sv, rlen);
                sv_catpvn(ctx->out, rpv, rlen);
            }
        } else if (repl_kid) {
            ddc_deparse_op(aTHX_ repl_kid, ctx);
        }

        sv_catpvn(ctx->out, "/", 1);
        /* Flags */
        if (pm->op_pmflags & PMf_GLOBAL)
            sv_catpvn(ctx->out, "g", 1);
        break;
    }

    /* ── Scalar chomp/chop ────────────────────────────────────── */
    case OP_SCHOMP:
        ddc_emit_keyword(aTHX_ ctx, "chomp", 5);
        if (o->op_flags & OPf_KIDS) {
            sv_catpvn(ctx->out, "(", 1);
            ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
            sv_catpvn(ctx->out, ")", 1);
        }
        break;
    case OP_SCHOP:
        ddc_emit_keyword(aTHX_ ctx, "chop", 4);
        if (o->op_flags & OPf_KIDS) {
            sv_catpvn(ctx->out, "(", 1);
            ddc_deparse_op(aTHX_ cUNOPo->op_first, ctx);
            sv_catpvn(ctx->out, ")", 1);
        }
        break;

    /* ── wantarray ────────────────────────────────────────────── */
    case OP_WANTARRAY:
        ddc_emit_keyword(aTHX_ ctx, "wantarray", 9);
        sv_catpvn(ctx->out, "()", 2);
        break;

    /* ── List builtins ────────────────────────────────────────── */
    case OP_PUSH: case OP_POP: case OP_SHIFT: case OP_UNSHIFT:
    case OP_SPLICE: case OP_SORT: case OP_REVERSE:
    case OP_KEYS: case OP_VALUES: case OP_EACH:
    case OP_JOIN: case OP_SPRINTF:
    case OP_SUBSTR: case OP_INDEX: case OP_RINDEX: {
        const char *fn = PL_op_name[type];
        OP *kid;
        int first = 1;
        ddc_emit_keyword(aTHX_ ctx, fn, strlen(fn));
        if (o->op_flags & OPf_KIDS) {
            sv_catpvn(ctx->out, "(", 1);
            for (kid = cUNOPo->op_first; kid; kid = OpSIBLING(kid)) {
                if (kid->op_type == OP_PUSHMARK) continue;
                if (kid->op_type == OP_NULL &&
                    !(kid->op_flags & OPf_KIDS)) continue;
                if (!first) sv_catpvn(ctx->out, ", ", 2);
                ddc_deparse_op(aTHX_ kid, ctx);
                first = 0;
#if PERL_VERSION >= 18
                if (kid->op_type == OP_PADRANGE) {
                    int skip = (int)(kid->op_private & OPpPADRANGE_COUNTMASK);
                    while (skip-- > 0 && OpSIBLING(kid)) kid = OpSIBLING(kid);
                }
#endif
            }
            sv_catpvn(ctx->out, ")", 1);
        }
        break;
    }

    /* ── split ────────────────────────────────────────────────── */
    case OP_SPLIT: {
        OP *kid;
        OP *args[16];
        int nargs = 0;
        int ai;
        int first = 1;
        REGEXP *re = NULL;

        /* Before 5.26, split is a LISTOP with a pushre PMOP child
           holding the regex.  From 5.26+, split itself is a PMOP. */
#if PERL_VERSION >= 26
        re = PM_GETRE((PMOP *)o);
#else
        if (o->op_flags & OPf_KIDS) {
            OP *k = cUNOPo->op_first;
            /* Skip pushmark */
            if (k && k->op_type == OP_PUSHMARK)
                k = OpSIBLING(k);
            if (k && k->op_type == OP_PUSHRE)
                re = PM_GETRE((PMOP *)k);
        }
#endif

        ddc_emit_keyword(aTHX_ ctx, "split", 5);
        sv_catpvn(ctx->out, "(", 1);

        /* Emit the regex first */
        if (re) {
            STRLEN plen = RX_PRELEN(re);
            const char *pat = RX_PRECOMP(re);
            sv_catpvn(ctx->out, "/", 1);
            if (pat && plen)
                sv_catpvn(ctx->out, pat, plen);
            sv_catpvn(ctx->out, "/", 1);
            first = 0;
        }

        /* Emit remaining args (string to split, optional limit) */
        if (o->op_flags & OPf_KIDS) {
            for (kid = cUNOPo->op_first; kid; kid = OpSIBLING(kid)) {
                if (kid->op_type == OP_PUSHMARK) continue;
#if PERL_VERSION < 26
                if (kid->op_type == OP_PUSHRE) continue;
#endif
                if (kid->op_type == OP_NULL &&
                    !(kid->op_flags & OPf_KIDS)) continue;
                if (nargs < 16)
                    args[nargs++] = kid;
            }
        }

        /* Omit implicit split limit 0 */
        if (nargs >= 2 && args[nargs - 1]->op_type == OP_CONST) {
            SV *sv = ddc_const_sv(aTHX_ args[nargs - 1], ctx->cv);
            if (sv && SvOK(sv) && SvIOK(sv) && SvIV(sv) == 0)
                nargs--;
        }

        for (ai = 0; ai < nargs; ai++) {
            if (!first) sv_catpvn(ctx->out, ", ", 2);
            ddc_deparse_op(aTHX_ args[ai], ctx);
            first = 0;
        }
        sv_catpvn(ctx->out, ")", 1);
        break;
    }

    /* ── grep/map with block ──────────────────────────────────── */
    case OP_GREPWHILE: case OP_MAPWHILE: {
        const char *fn = (type == OP_GREPWHILE) ? "grep" : "map";
        OP *grepstart_op;
        OP *block_op = NULL;
        OP *list_op = NULL;

        ddc_emit_keyword(aTHX_ ctx, fn, strlen(fn));
        sv_catpvn(ctx->out, " ", 1);

        /* grepwhile/mapwhile's first child is grepstart/mapstart
           grepstart's children are: pushmark, block, list */
        if (o->op_flags & OPf_KIDS) {
            grepstart_op = cLOGOPo->op_first;
            if (grepstart_op && (grepstart_op->op_flags & OPf_KIDS)) {
                OP *gs_kid = cUNOPx(grepstart_op)->op_first;
                /* Skip pushmark */
                if (gs_kid && gs_kid->op_type == OP_PUSHMARK)
                    gs_kid = OpSIBLING(gs_kid);
                
                /* First non-pushmark child is the block (may be wrapped in null ops) */
                if (gs_kid) {
                    block_op = gs_kid;
                    gs_kid = OpSIBLING(gs_kid);
                }
                /* Second non-pushmark child is the list */
                if (gs_kid) {
                    list_op = gs_kid;
                }
            }
        }

        /* Emit block: unwrap any null/scope/lineseq wrappers to get the expression */
        sv_catpvn(ctx->out, "{ ", 2);
        if (block_op) {
            OP *expr_op = block_op;
            /* Unwrap null wrappers */
            while (expr_op && expr_op->op_type == OP_NULL &&
                   (expr_op->op_flags & OPf_KIDS) && !OpSIBLING(cUNOPx(expr_op)->op_first))
                expr_op = cUNOPx(expr_op)->op_first;
            /* Unwrap scope */
            if (expr_op && expr_op->op_type == OP_SCOPE &&
                (expr_op->op_flags & OPf_KIDS)) {
                OP *scope_kid = cUNOPx(expr_op)->op_first;
                /* Skip ex-nextstate */
                if (scope_kid && (scope_kid->op_type == OP_NULL ||
                                  scope_kid->op_type == OP_NEXTSTATE))
                    scope_kid = OpSIBLING(scope_kid);
                if (scope_kid && !OpSIBLING(scope_kid))
                    expr_op = scope_kid;
            }
            ddc_deparse_op(aTHX_ expr_op, ctx);
        }
        sv_catpvn(ctx->out, " }", 2);

        /* Emit list */
        if (list_op) {
            sv_catpvn(ctx->out, " ", 1);
            ddc_deparse_op(aTHX_ list_op, ctx);
        }
        break;
    }

    /* ── eval { BLOCK } ───────────────────────────────────────── */
    case OP_LEAVETRY: {
        int i;
        ddc_emit_keyword(aTHX_ ctx, "eval", 4);
        sv_catpvn(ctx->out, " {\n", 3);
        ctx->indent++;
        ddc_deparse_stmts(aTHX_ o, ctx);
        ctx->indent--;
        sv_catpvn(ctx->out, "\n", 1);
        for (i = 0; i < ctx->indent; i++)
            sv_catpvn(ctx->out, "  ", 2);
        sv_catpvn(ctx->out, "}", 1);
        ctx->last_was_block = 0;
        break;
    }
    case OP_ENTERTRY:
        /* Handled by OP_LEAVETRY */
        break;

    /* ── next/last/redo ───────────────────────────────────────── */
    case OP_NEXT:
        ddc_emit_keyword(aTHX_ ctx, "next", 4);
        break;
    case OP_LAST:
        ddc_emit_keyword(aTHX_ ctx, "last", 4);
        break;
    case OP_REDO:
        ddc_emit_keyword(aTHX_ ctx, "redo", 4);
        break;

    /* ── Skip internal ops ────────────────────────────────────── */
    case OP_PUSHMARK:
    case OP_ENTER:
    case OP_NEXTSTATE:
    case OP_DBSTATE:
        break;

    /* ── Fallback ─────────────────────────────────────────────── */
    default:
        if (o->op_flags & OPf_KIDS) {
            OP *kid;
            for (kid = cUNOPo->op_first; kid; kid = OpSIBLING(kid))
                ddc_deparse_op(aTHX_ kid, ctx);
        }
        break;
    }
}

/* ══════════════════════════════════════════════════════════════ */
/* ── Entry point: deparse a CV ────────────────────────────────── */
/* ══════════════════════════════════════════════════════════════ */

static SV *
ddc_deparse_cv(pTHX_ CV *cv, DDCStyle *style, int depth)
{
    OP *root;
    DDCDeparse ctx;
    PADLIST *padlist;
    int i;

    if (!cv || !CvROOT(cv))
        return NULL;

    root = CvROOT(cv);

    Zero(&ctx, 1, DDCDeparse);
    ctx.style  = style;
    ctx.out    = newSVpvs("");
    ctx.indent = depth + 1;
    ctx.prec   = LOO_PREC_LOWEST;
    ctx.cv     = cv;

    padlist = CvPADLIST(cv);
    if (padlist)
        ctx.padnames = PadlistNAMES(padlist);

    ddc_emit_keyword(aTHX_ &ctx, "sub", 3);
    sv_catpvn(ctx.out, " {\n", 3);

    ddc_deparse_stmts(aTHX_ root, &ctx);

    sv_catpvn(ctx.out, "\n", 1);
    {
        int width = (style && style->indent_width > 0)
                    ? style->indent_width : 2;
        char ch   = (style && style->indent_char)
                    ? style->indent_char : ' ';
        for (i = 0; i < depth; i++) {
            int j;
            for (j = 0; j < width; j++)
                sv_catpvn(ctx.out, &ch, 1);
        }
    }
    sv_catpvn(ctx.out, "}", 1);

    return ctx.out;
}

#endif /* LOO_DEPARSE_H */
