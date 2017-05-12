#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define MY_CXT_KEY "perl5db::_guts" XS_VERSION

typedef struct {
    SV *ldebug;
    AV *stack;
    GV *stack_depth;
    SV *deep;
    HV *fq_function_names;
} my_cxt_t;

START_MY_CXT

#define dblog(string)                   \
    STMT_START {                        \
        if (SvIV(MY_CXT.ldebug)) {      \
            const char *arg = (string); \
            PUTBACK;                    \
            do_dblog(aTHX_ arg);        \
            SPAGAIN;                    \
        }                               \
    } STMT_END

static void do_dblog(pTHX_ const char *string) {
    dSP;

    EXTEND(SP, 1);

    PUSHMARK(SP);
    PUSHs(sv_2mortal(newSVpv(string, 0)));
    PUTBACK;

    call_pv("DB::dblog", G_VOID | G_DISCARD | G_NODEBUG);
}

#if PERL_VERSION >= 22
static void PL_DBsingle_iv_set(pTHX_ IV x) {
    PL_DBsingle_iv = x;
}
#else
#define PL_DBsingle_iv SvIV(PL_DBsingle)

static void PL_DBsingle_iv_set(pTHX_ IV x) {
    SvIV_set(PL_DBsingle, x);
    SvIOK_only(PL_DBsingle);
}
#endif

static void reinit_my_cxt(pTHX_ pMY_CXT) {
    MY_CXT.ldebug = get_sv("DB::ldebug", 0);
    MY_CXT.stack_depth = gv_fetchpv("DB::stack_depth", 0, 0);

    call_pv("DB::setup_lexicals", G_VOID | G_DISCARD | G_NODEBUG);
}

static void try_breaking(pTHX_ pMY_CXT_ SV *sub, const char *type) {
    dSP;

    HE *entry = hv_fetch_ent(MY_CXT.fq_function_names, sub, 0, 0);
    if (!entry)
        return;

    EXTEND(SP, 3);

    PUSHMARK(SP);
    PUSHs(HeVAL(entry));
    PUSHs(sub);
    PUSHs(sv_2mortal(newSVpv(type, 0)));
    PUTBACK;

    call_pv("DB::tryBreaking", G_VOID | G_DISCARD | G_NODEBUG);
}

static bool before_call(pTHX_ pMY_CXT_ int current_depth) {
    bool in_debugger = FALSE;

    /* local $stach_depth = $stack_depth + 1 */
    SAVEGENERICSV(GvSVn(MY_CXT.stack_depth));
    GvSVn((MY_CXT.stack_depth)) = newSViv(current_depth);

    /* $#stack = $stack_depth */
    av_fill(MY_CXT.stack, current_depth);

    /* $stack[-1] = $single */
    IV single = PL_DBsingle_iv;
    {
        SV **top = av_fetch(MY_CXT.stack, current_depth, 1);

        sv_setiv(*top, single);
    }
    /* $single &= 1 */
    single = single & 1;

    /* $single |= 4 if $#stack == $deep */
    if (current_depth == SvIV(MY_CXT.deep))
        single = single | 4;
    PL_DBsingle_iv_set(aTHX_ single);

    {
        HV *stash = CopSTASH(PL_curcop);
        STRLEN len = HvNAMELEN_get(stash);
        const char *name = HvNAME(stash);

        if (len > 4 && strncmp(name, "DB::", 4) == 0)
            in_debugger = TRUE;
    }

    /* check function call breakpoint */
    if (!in_debugger)
        try_breaking(aTHX_ aMY_CXT_ GvSV(PL_DBsub), "call");

    return in_debugger;
}

static void after_call(pTHX_ pMY_CXT_ bool in_debugger, int current_depth) {
    /* $single |= $stack[$stack_depth] */
    {
        SV **top = av_fetch(MY_CXT.stack, current_depth, 0);

        PL_DBsingle_iv_set(aTHX_ PL_DBsingle_iv | SvIV(*top));
    }

    /* check function return breakpoint */
    if (!in_debugger)
        try_breaking(aTHX_ aMY_CXT_ GvSV(PL_DBsub), "return");
}

MODULE=dbgp_helper::perl5db PACKAGE=DB::XS

void
sub_xs(...)
  PREINIT:
    dMY_CXT;
  /* needs a separate CV so we can set the LVALUE flag */
  ALIAS:
    lsub_xs = 1
  INIT:
    SV *sub = GvSV(PL_DBsub);
    IV current_depth = SvIV(GvSVn(MY_CXT.stack_depth)) + 1;
    I32 context = GIMME_V;
    /*
       If the original sub was called with the &foo syntax,
       add G_NOARGS to the call_sv() call, so @_ is not copied,
       and the callee can modify it.

       DB::sub (Perl) does this for all calls, because it's written in
       Perl, so @_ is always there, but when DB::XS::sub is called,
       @_ is not set up, because the sub is an XS.
     */
    I32 noargs = (PL_op->op_flags & OPf_STACKED) ? 0 : G_NOARGS;
    bool in_debugger;
    int retcount;
  PPCODE:
    /*
        We're passing through our arguments unmodified, so we can
        re-push them in place, or just restore the MARK declared by
        the implicit dXSARGS, and get the non-adjusted stack pointer
        from the interpreter global.
     */
    PUSHMARK(MARK);
    /* not needed right now, added just in case */
    SPAGAIN;

    in_debugger = before_call(aTHX_ aMY_CXT_ current_depth);
    retcount = call_sv(sub, context | noargs | G_NODEBUG);
    after_call(aTHX_ aMY_CXT_ in_debugger, current_depth);

    /*
       The global stack pointer is already at the right place, so we
       refresh our local copy so the implict PUTBACK at the end is a
       no-op. We could also do XSRETURN(retcount)
     */
    SPAGAIN;

void
setup_lexicals(SV *ldebug, SV *stack, SV *deep, SV *fq_function_names)
  PREINIT:
    dMY_CXT;
  CODE:
    MY_CXT.ldebug = SvRV(ldebug);
    MY_CXT.stack = (AV *) SvRV(stack);
    MY_CXT.deep = SvRV(deep);
    MY_CXT.fq_function_names = (HV *) SvRV(fq_function_names);

void
CLONE(...)
  CODE:
    MY_CXT_CLONE;
    reinit_my_cxt(aTHX_ aMY_CXT);

BOOT:
    MY_CXT_INIT;
    reinit_my_cxt(aTHX_ aMY_CXT);

    CvLVALUE_on(get_cv("DB::XS::lsub_xs", 0));
