#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "unwind_debug.h"

#define MODULE_NAME "Devel::Unwind"

#ifndef op_convert_list
PERL_CALLCONV  OP* Perl_convert(pTHX_ I32 optype, I32 flags, OP* o);
#define op_convert_list(a,b,c)  Perl_convert(aTHX_ a,b,c)
#endif

#ifndef pad_add_name_pvn
PERL_CALLCONV PADOFFSET Perl_pad_add_name(pTHX_ const char *namepv,
                                          STRLEN namelen,U32 flags,
                                          HV *typestash, HV *ourstash);
#define pad_add_name_pvs(a,b,c,d) Perl_pad_add_name(aTHX_ STR_WITH_LEN(a),b,c,d)
#define padadd_NO_DUP_CHECK 0x04
#endif

static XOP label_xop;
static XOP unwind_xop;
static XOP mydie_xop;

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);
static int find_mark(pTHX_ const PERL_SI *, const char*);

static OP* create_eval(pTHX_ OP *block);

static SV *
my_with_queued_errors(pTHX_ SV *ex)
{
    if (PL_errors && SvCUR(PL_errors) && !SvROK(ex)) {
	sv_catsv(PL_errors, ex);
	ex = sv_mortalcopy(PL_errors);
	SvCUR_set(PL_errors, 0);
    }
    return ex;
}

static int
consume_space(pTHX)
{
    char *start = PL_parser->bufptr;
    lex_read_space(0);
    return start!=PL_parser->bufptr; /* Consumed space? */
}

static OP* label_pp(pTHX) { return NORMAL; }
static OP* mydie_pp(pTHX) { Perl_die_unwind(aTHX_ ERRSV); }

static OP* unwind_pp(pTHX)
{
    dVAR; dSP; dMARK;
    SV *exsv;
    STRLEN len;
    const char *label;

    int olddepth = 0;
    CV *diehook_cv = NULL;

    if (PL_diehook) {
        /* See [Note: Prevent infinite recursion in die hook] */
        HV *stash;
        GV *gv;
        SV * const oldhook = PL_diehook;
        ENTER;
        SAVESPTR(PL_diehook);
        PL_diehook = NULL;
        diehook_cv = sv_2cv(oldhook, &stash, &gv, 0);
        LEAVE;
        olddepth = CvDEPTH(diehook_cv);
    }

    label = SvPVX(POPs);
    if (SP - MARK != 1) {
	exsv = newSVpvs_flags("",SVs_TEMP);
	do_join(exsv, &PL_sv_no, MARK, SP);
	SP = MARK + 1;
    } else {
        exsv = sv_mortalcopy(POPs);
    }

    if (SvROK(exsv) || (SvPV_const(exsv, len), len)) {
	/* well-formed exception supplied */
    }
    else {
	SV * const errsv = ERRSV;
	SvGETMAGIC(errsv);
	if (SvROK(errsv)) {
	    exsv = errsv;
	    if (sv_isobject(exsv)) {
		HV * const stash = SvSTASH(SvRV(exsv));
		GV * const gv = gv_fetchmethod(stash, "PROPAGATE");
		if (gv) {
		    SV * const file = sv_2mortal(newSVpv(CopFILE(PL_curcop),0));
		    SV * const line = sv_2mortal(newSVuv(CopLINE(PL_curcop)));
		    EXTEND(SP, 3);
		    PUSHMARK(SP);
		    PUSHs(exsv);
		    PUSHs(file);
		    PUSHs(line);
		    PUTBACK;
		    call_sv(MUTABLE_SV(GvCV(gv)),
			    G_SCALAR|G_EVAL|G_KEEPERR);
		    exsv = sv_mortalcopy(*PL_stack_sp--);
		}
	    }
	}
	else if (SvPOK(errsv) && SvCUR(errsv)) {
	    exsv = sv_mortalcopy(errsv);
	    sv_catpvs(exsv, "\t...propagated");
	}
	else {
	    exsv = newSVpvs_flags("Died", SVs_TEMP);
	}
    }

    {
        const PERL_SI *si;
        I32  label_cxix;

        for (si = PL_curstackinfo; si; si = si->si_prev) {
            label_cxix = find_mark(aTHX_ si, label);
            if (label_cxix >= 0) {
                break;
            }
        }
        if (label_cxix < 0) {
            Perl_write_to_stderr(aTHX_
                                 my_with_queued_errors(aTHX_
                                                       mess("'unwind %s' exiting: %s",
                                                            label,
                                                            SvPV_nolen(exsv))));
            my_failure_exit();
        }

        POPSTACK_TO(si->si_stack);
        dounwind(label_cxix);
        {
            JMPENV *eval_jmpenv = si->si_cxstack[label_cxix].blk_eval.cur_top_env;
            while (PL_top_env != eval_jmpenv) {
                dJMPENV;
                cur_env = *PL_top_env;
                PL_top_env = &cur_env; /* Hackishly silence assertion */
                JMPENV_POP;
            }
        }
    }

    if (PL_diehook) {
        /* Note: Prevent infinite recursion in die hook
           --------------------------------------------
           If we're running inside the die hook then the previous POPSUB
           restored the CvDEPTH to zero. We restore the old CvDEPTH
           to prevent infinitie recursion in the die hook.

           If we're not running inside the die hook then
           CvDEPTH(diehook_cv) equals olddepth;
         */
        CvDEPTH(diehook_cv) = olddepth;
    }

    die_sv(exsv);
    assert(0); /* NOTREACHED */
    return NULL; /* SILENCE GCC */
}

static int
find_mark(pTHX_ const PERL_SI *stackinfo, const char *label)
{
    I32 i;
    DEBUG_printf("find label '%s' on stack '%s'\n",
                 label, si_names[stackinfo->si_type+1]);
    for (i=stackinfo->si_cxix; i >= 0; i--) {
        PERL_CONTEXT *cx = &(stackinfo->si_cxstack[i]);
        OP  *retop = cx->blk_eval.retop;
        if (CxTYPE(cx) == CXt_EVAL && retop && retop->op_ppaddr == label_pp) {
            assert(cPVOPx(retop)->op_pv);
            char *mark_label = cPVOPx(retop)->op_pv;
            if (!strcmp(label,mark_label)) {
                DEBUG_printf("\tLABEL '%s' FOUND at '%d'\n", label, i);
                return i;
            }
        }
    }
    DEBUG_printf("\tLABEL '%s' NOT FOUND\n", label);
    return -1;
}

static OP*
disable_scalar_context_optimization(pTHX_ OP *mark_expr) {
/*
  The mark expression is of the form

    eval BLOCK, PVOP(label_pp, LABEL)

  in scalar context it has the value of PVOP(label_pp, LABEL) but
  we're interested in the return value of the eval. So I jump through
  hoops and wrap mark_expr in

    eval {
      my @x = mark_expr;
      local $SIG{__DIE__};
      die $@ if $@;
      {
         # Disables warnings about useless constants
         # in void context
         no warnings;
         wantarray ? @x : $x[-1];
      }
    }

  This feels dirty but it's all I've got :/
*/
    PADOFFSET padoff;
    OP *a1,*a2,*a3;
    OP *assign_to_array;
    OP *die_if_error;
    OP *wantarray;
    OP *block;
    OP *std_warning_cop;
    OP *o;

    padoff = pad_add_name_pvs("@__stack_unwind_internal",
                              /* Do I have to prevent name collisions
                                 Is it guaranteed that the user can't
                                 by mistake use the array name
                                 @___stack_unwind_internal?
                               */
                              padadd_NO_DUP_CHECK,
                              0,0);

    a1 = newOP(OP_PADAV, OPf_MOD  | (OPpLVAL_INTRO<<8));
    a2 = newOP(OP_PADAV, 0);
    a3 = newOP(OP_PADAV, OPf_REF);
    a1->op_targ = a2->op_targ = a3->op_targ = padoff;

    assign_to_array =  newSTATEOP(0, NULL,
                                  newASSIGNOP(OPf_STACKED, a1, 0, mark_expr));

    die_if_error =
        newLOGOP(OP_AND, 0,
                 newUNOP(OP_RV2SV, 0,
                         newGVOP(OP_GV, 0, PL_errgv)),
                 (o = newOP(OP_CUSTOM, 0),
                  o->op_ppaddr = mydie_pp, /* mydie_pp doesn't call the die hook */
                  o));

    wantarray =  newCONDOP(0,
                           newOP(OP_WANTARRAY, 0),
                           a2,
                           newBINOP(OP_AELEM, 0,
                                    a3,
                                    newSVOP(OP_CONST, 0,
                                            newSViv(-1))));

    std_warning_cop = newSTATEOP(0, NULL, 0);
    cCOPx(std_warning_cop)->cop_warnings = pWARN_NONE;

    block = op_append_elem(OP_LINESEQ, assign_to_array, newSTATEOP(0, NULL, 0));
    block = op_append_elem(OP_LINESEQ, block, die_if_error);
    block = op_append_elem(OP_LINESEQ, block, std_warning_cop);
    block = op_append_elem(OP_LINESEQ, block, wantarray);

    return create_eval(aTHX_ block);
}

static OP*
create_eval(pTHX_ OP *block) {
    OP    *o;
    LOGOP *enter;

    /*
      Shamelessly copied from Perl_ck_eval
     */

    NewOp(1101, enter, 1, LOGOP);
    enter->op_type = OP_ENTERTRY;
    enter->op_ppaddr = PL_ppaddr[OP_ENTERTRY];
    enter->op_private = 0;

    o = op_prepend_elem(OP_LINESEQ, (OP*)enter, (OP*)block);
    o->op_type = OP_LEAVETRY;
    o->op_ppaddr = PL_ppaddr[OP_LEAVETRY];
    enter->op_other = o;

    return o;
}

static OP *_parse_block(pTHX)
{
    OP *o = parse_block(0);
    if (!o) {
        o = newOP(OP_STUB, 0);
    }
    /*
     * Do I need to set any flags?
     */
    return o;
}

static SV *_parse_label(pTHX) {
    SV *label;
    char *start;
    char *end;;

    lex_read_space(0);
    start = end = PL_parser->bufptr;
    if (!isIDFIRST(*start)) {
        croak(MODULE_NAME ": Invalid label at %s. Got '%c'.\n",
              CopFILE(PL_curcop),
              *start
            );
    }
    while (isALNUM(*++end));
    lex_read_to(end);

    label = newSVpv(start, end-start);
    DEBUG_printf("Valid label: %s\n", SvPV_nolen(label));

    return label;
}

static int
mark_keyword_plugin(pTHX_
                  char *keyword_ptr,
                  STRLEN keyword_len,
                  OP **op_ptr)
{
    if (keyword_len == 4 && strnEQ(keyword_ptr, "mark", 4))  {
        OP *eval_block;
        OP *label_op;
        char *label;
        /*
          Transform
             mark LABEL: BLOCK
          to
            eval BLOCK, PVOP(label_pp, LABEL)
          think of it as
            LABEL: eval BLOCK
          and we label the eval by making sure a labeled PVOP
          is the retop of the eval block.
         */
        {
            SV *l = _parse_label(aTHX);
            label = savesharedsvpv(l);
            SvREFCNT_dec(l);
        }

        eval_block = create_eval(aTHX_
                                 _parse_block(aTHX));

        label_op = newPVOP(OP_CUSTOM, 0, label);
        label_op->op_ppaddr = label_pp;

        *op_ptr =
            disable_scalar_context_optimization(aTHX_
                op_append_elem(OP_LIST, eval_block, label_op));


        return KEYWORD_PLUGIN_EXPR;
    }
    else if (keyword_len == 6 && strnEQ(keyword_ptr, "unwind", 6)) {
        /*
          unwind LABEL [EXPRESSION];
         */
        SV *label= NULL;
        OP *expr = NULL;
        int space;

        label = _parse_label(aTHX);
        space = consume_space(aTHX);
        if (*PL_parser->bufptr != ',') {
            expr  = parse_listexpr(PARSE_OPTIONAL);
            if (!space && expr) {
                PL_parser->error_count++;
                croak(MODULE_NAME
                      ": Syntax error near '%s' when parsing label.",
                      SvPVX(label));
            }
            expr  = expr ? expr : newOP(OP_STUB,0);
        }
        expr  = op_contextualize(expr, G_ARRAY);

        *op_ptr =  op_convert_list(OP_CUSTOM, 0,
                                   op_append_elem(OP_LIST,
                                                  expr,
                                                  newSVOP(OP_CONST, 0, label)));
        (*op_ptr)->op_ppaddr = unwind_pp;

        return KEYWORD_PLUGIN_EXPR;
    }
    else {
        return next_keyword_plugin(aTHX_ keyword_ptr, keyword_len, op_ptr);
    }
}

MODULE = Devel::Unwind PACKAGE = Devel::Unwind

PROTOTYPES: DISABLE

BOOT:
    XopENTRY_set(&label_xop, xop_name,  "label_xop");
    XopENTRY_set(&label_xop, xop_desc,  "label the mark");
    XopENTRY_set(&label_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ label_pp, &label_xop);

    XopENTRY_set(&unwind_xop, xop_name,  "unwind");
    XopENTRY_set(&unwind_xop, xop_desc,  "unwind the stack to the mark");
    XopENTRY_set(&unwind_xop, xop_class, OA_PVOP_OR_SVOP);
    Perl_custom_op_register(aTHX_ unwind_pp, &unwind_xop);

    XopENTRY_set(&mydie_xop, xop_name,  "mydie");
    XopENTRY_set(&mydie_xop, xop_desc,  "mydie, dies without calling the SIGDIE handler");
    XopENTRY_set(&mydie_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ mydie_pp, &mydie_xop);

    next_keyword_plugin =  PL_keyword_plugin;
    PL_keyword_plugin   = mark_keyword_plugin;
