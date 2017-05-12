#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

#ifndef SvRXOK
#define SvRXOK(sv) (SvROK(sv) && SvMAGICAL(SvRV(sv)) && mg_find(SvRV(sv), PERL_MAGIC_qr))
#endif

#ifndef gv_stashpvs
#define gv_stashpvs(s, create) Perl_gv_stashpvn(aTHX_ STR_WITH_LEN(s), create)
#endif

#ifndef CopLABEL
#define CopLABEL(cop) ((cop)->cop_label)
#endif

#define PACKAGE "Devel::Optrace"

#define MY_CXT_KEY PACKAGE "::_guts" XS_VERSION
typedef struct{
    SV* debugsv;

    HV* debsv_seen;
    SV* buff;

    SV* linebuf;

    runops_proc_t orig_runops;
    peep_t        orig_peepp;

    U32* count_data;
    struct tms start_tms;
} my_cxt_t;
START_MY_CXT

#define dMY_DEBUG dMY_CXT; register unsigned int const debug = (unsigned int)SvUV(MY_CXT.debugsv)

#define DOf_TRACE   0x001
#define DOf_STACK   0x002
#define DOf_RUNOPS  0x004
#define DOf_DEFAULT (DOf_TRACE | DOf_STACK | DOf_RUNOPS)

#define DOf_COUNT   0x020 /* simple opcode counter */

#define DOf_NOOPT   0x100

#define DO_TRACE   (debug & DOf_TRACE)
#define DO_STACK   (debug & DOf_STACK)
#define DO_RUNOPS  (debug & DOf_RUNOPS)
#define DO_NOOPT   (debug & DOf_NOOPT)
#define DO_COUNT   (debug & DOf_COUNT)

#define PV_LIMIT (50)

#define debflush() STMT_START { \
        if(SvCUR(MY_CXT.linebuf) > 0){ \
            GV* const stderrgv = PL_stderrgv;\
            PerlIO* const log  = isGV(stderrgv) && GvIOp(stderrgv) ? IoOFP(GvIOp(stderrgv)) : NULL; \
            PerlIO_write(log, SvPVX(MY_CXT.linebuf), SvCUR(MY_CXT.linebuf)); \
            SvCUR_set(MY_CXT.linebuf, 0); \
        } \
    } STMT_END

#define debs(s)         do_debpvn(aTHX_ aMY_CXT_ STR_WITH_LEN(s))
#define debpvn(pv, len) do_debpvn(aTHX_ aMY_CXT_ pv, len)
static void
do_debpvn(pTHX_ pMY_CXT_ const char* pv, STRLEN const len){
    dVAR;
    sv_catpvn(MY_CXT.linebuf, pv, len);
}

#define debpv(pv) do_debpv(aTHX_ aMY_CXT_ pv)
static void
do_debpv(pTHX_ pMY_CXT_ const char* const pv){
    dVAR;
    sv_catpvn(MY_CXT.linebuf, pv, strlen(pv));
}


#define debf do_debf_nocontext
static void
do_debf_nocontext(const char* const fmt, ...){
    dTHX;
    dMY_CXT;
    va_list args;

    va_start(args, fmt);
    sv_vcatpvf(MY_CXT.linebuf, fmt, &args);
    va_end(args);
}

#define debname(pv, len) do_debname(aTHX_ aMY_CXT_ pv, len)
static void
do_debname(pTHX_ pMY_CXT_ const char* const pv, STRLEN const len){
    dVAR;
    STRLEN i;

    for(i = 0; i < len; i++){
        if(isCNTRL(pv[i])){
            char ctrl[2];
            ctrl[0] = '^';
            ctrl[1] = toCTRL(pv[i]);

            debpvn(ctrl, 2);
        }
        else{
            debpvn(pv+i, 1);
        }
    }
}

#define debgv(gv, prefix) do_debgv(aTHX_ aMY_CXT_ gv, prefix)
static void
do_debgv(pTHX_ pMY_CXT_ GV* const gv, const char* const prefix){
    dVAR;
    gv_efullname4(MY_CXT.buff, gv, prefix, FALSE);
    debname(SvPVX(MY_CXT.buff), SvCUR(MY_CXT.buff));
}

static const char*
do_magic_name(const char mgtype){
    /* stolen from dump.c */
    static const struct { const char type; const char* const name; } magic_names[] = {
        { PERL_MAGIC_sv,             "sv" },
        { PERL_MAGIC_arylen,         "arylen" },
        { PERL_MAGIC_glob,           "glob" },
#ifdef PERL_MAGIC_rhash
        { PERL_MAGIC_rhash,          "rhash" },
#endif
        { PERL_MAGIC_pos,            "pos" },
#ifdef PERL_MAGIC_symtab
        { PERL_MAGIC_symtab,         "symtab" },
#endif
        { PERL_MAGIC_backref,        "backref" },
#ifdef PERL_MAGIC_arylen_p
        { PERL_MAGIC_arylen_p,       "arylen_p" },
#endif
#ifdef PERL_MAGIC_arylen
        { PERL_MAGIC_arylen,         "arylen" },
#endif
        { PERL_MAGIC_overload,       "overload" },
        { PERL_MAGIC_bm,             "bm" },
        { PERL_MAGIC_regdata,        "regdata" },
        { PERL_MAGIC_env,            "env" },
#ifdef PERL_MAGIC_hints
        { PERL_MAGIC_hints,          "hints" },
#endif
        { PERL_MAGIC_isa,            "isa" },
        { PERL_MAGIC_dbfile,         "dbfile" },
        { PERL_MAGIC_shared,         "shared" },
        { PERL_MAGIC_tied,           "tied" },
        { PERL_MAGIC_sig,            "sig" },
        { PERL_MAGIC_uvar,           "uvar" },
        { PERL_MAGIC_overload_elem,  "overload_elem" },
        { PERL_MAGIC_overload_table, "overload_table" },
        { PERL_MAGIC_regdatum,       "regdatum" },
        { PERL_MAGIC_envelem,        "envelem" },
        { PERL_MAGIC_fm,             "fm" },
        { PERL_MAGIC_regex_global,   "regex_global" },
#ifdef PERL_MAGIC_hintselem
        { PERL_MAGIC_hintselem,      "hintselem" },
#endif
        { PERL_MAGIC_isaelem,        "isaelem" },
        { PERL_MAGIC_nkeys,          "nkeys" },
        { PERL_MAGIC_dbline,         "dbline" },
        { PERL_MAGIC_shared_scalar,  "shared_scalar" },
        { PERL_MAGIC_collxfrm,       "collxfrm" },
        { PERL_MAGIC_tiedelem,       "tiedelem" },
        { PERL_MAGIC_tiedscalar,     "tiedscalar" },
        { PERL_MAGIC_qr,             "qr" },
        { PERL_MAGIC_sigelem,        "sigelem" },
        { PERL_MAGIC_taint,          "taint" },
        { PERL_MAGIC_uvar_elem,      "uvar_elem" },
        { PERL_MAGIC_vec,            "vec" },
        { PERL_MAGIC_vstring,        "vstring" },
        { PERL_MAGIC_utf8,           "utf8" },
        { PERL_MAGIC_substr,         "substr" },
        { PERL_MAGIC_defelem,        "defelem" },
        { PERL_MAGIC_ext,            "ext" },
        /* this null string terminates the list */
        { 0,                         NULL },
    };

    I32 i;
    for(i = 0; magic_names[i].name; i++){
        if(mgtype == magic_names[i].type){
            return magic_names[i].name;
        }
    }
    return form("unknown(%c)", mgtype);
}

#define debsv_peek(sv) do_debsv_peek(aTHX_ aMY_CXT_ seen, sv)
static void
do_debsv_peek(pTHX_ pMY_CXT_ HV* const seen, SV* sv){
    dVAR;
    SV* const buff = MY_CXT.buff;
    HE* he;

    retry:
    if(!sv){
        debs("NULL");
        return;
    }
    if(SvTYPE(sv) > SVt_PVIO){
        debf("0x%p", sv); /* non-sv pointer (e.g. OP* for pp_pushre()) */
        return;
    }

    sv_setuv(buff, PTR2UV(sv));
    he = hv_fetch_ent(seen, buff, TRUE, 0U);
    if(SvOK(HeVAL(he))){
        debs("...");
        return;
    }
    sv_setiv(HeVAL(he), TRUE);

    if(SvROK(sv)){
        SV* const rv = SvRV(sv);
        if(SvOBJECT(rv)){
            if(SvRXOK(sv)){
                STRLEN len;
                const char* const pv = SvPV_const(sv, len);
                debs("qr/");
                debpvn(pv, len);
                debs("/");
            }
            else{
                debf("%s=%s(0x%p)", sv_reftype(rv, TRUE), sv_reftype(rv, FALSE), rv);
            }
            goto finish;
        }
        else{
            debs("\\");
            sv = rv;
            goto retry;
        }
    }

    if(SvREADONLY(sv)){
        if(sv == &PL_sv_undef){
            debs("UNDEF");
            return;
        }
        else if(sv == &PL_sv_yes){
            debs("YES");
            return;
        }
        else if(sv == &PL_sv_no){
            debs("NO");
            return;
        }
        else if(sv == &PL_sv_placeholder){
            debs("PLACEHOLDER");
            return;
        }
    }

    switch(SvTYPE(sv)){
    case SVt_PVAV:{
        debs("@");
        if(sv == (SV*)GvAV(PL_defgv)){
            debs("_");
        }
        else{
            debf("(%d/%d 0x%p)", AvFILLp((AV*)sv)+1, AvMAX((AV*)sv)+1, sv);
        }
#if 0
        I32 const len = AvFILLp((AV*)sv) + 1;
        I32 i;
        debs("@(");
        for(i = 0; i < len; i++){
            debsv_peek(AvARRAY((AV*)sv)[i]);

            if((i+1) < len){
                debs(",");
            }
        }
        debs(")");
#endif
        break;
    }
    case SVt_PVHV:{
        debs("%");

        if(SvMAGICAL(sv)){
            if(mg_find(sv, PERL_MAGIC_env)){
                debs("ENV");
                goto finish;
            }
            else if(mg_find(sv, PERL_MAGIC_sig)){
                debs("SIG");
                goto finish;
            }
        }

        if(HvNAME((HV*)sv)){ /* stash */
            debpv(HvNAME((HV*)sv));
            debs("::");
        }
        else if(sv == (SV*)GvHV(PL_hintgv)){
            debs("^H");
        }
        else if(sv == (SV*)GvHV(PL_incgv)){
            debs("INC");
        }
        else{
            debf("(%d/%d 0x%p)", (int)HvFILL((HV*)sv), (int)HvMAX((HV*)sv) + 1, sv);
        }
        break;
    }
    case SVt_PVCV:
    case SVt_PVFM:{
        if(CvGV((CV*)sv)){
            debgv(CvGV((CV*)sv), "&");
        }
        else{
            debs("&(unknown)");
        }
        break;
    }
    case SVt_PVGV:{
        debgv((GV*)sv, "*");
        break;
    }
    case SVt_PVIO:{
        const PerlIO* const fp = IoIFP((IO*)sv);
        debf("IO(%c 0x%p)", IoTYPE((IO*)sv), fp);
        break;
    }

    /* scalar */
    case SVt_NULL:{
        debs("undef");
        break;
    }
    default:
        if(SvPOKp(sv)){
            pv_display(buff, SvPVX(sv), SvCUR(sv), SvCUR(sv), PV_LIMIT);
            debpvn(SvPVX(buff), SvCUR(buff));
        }
        else if(SvIOKp(sv)){
            if(SvIsUV(sv)){
                debf("%"UVuf, SvUVX(sv));
            }
            else{
                debf("%"IVdf, SvIVX(sv));
            }
        }
        else if(SvNOKp(sv)){
            debf("%"NVgf, SvNVX(sv));
        }
        else{
            debs("undef");
        }

        if(SvTYPE(sv) == SVt_PVLV){
            debs(" LV(");
            switch(LvTYPE(sv)){
            case 'k':
                debs("keys");
                break;
            case '.':
                debs("pos");
                break;
            case 'x':
                debs("substr");
                break;
            case 'v':
                debs("vec");
                break;
            case '/':
                debs("re"); /* split/pushre */
                break;
            case 'y':
                debs("elem"); /* aelem/helem/iter */
                break;
            case 't':
                debs("tie");
                break;
            case 'T':
                debs("tiedelem");
                break;
            default:
                debf("%c", LvTYPE(sv));
            }
            debs(")");
        }
    } /* switch(SvTYPE(sv)) */

    finish:
    if(SvMAGICAL(sv)){
        MAGIC* mg;

        for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
            debs(" MG(");
            debpv(do_magic_name(mg->mg_type));

            switch(mg->mg_type){
            case PERL_MAGIC_sv:
                debs(" ");
                debgv((GV*)mg->mg_obj, "$");
                break;
            case PERL_MAGIC_isa:
                debs(" ");
                debgv((GV*)mg->mg_obj, "@");
                break;

            case PERL_MAGIC_isaelem:
                break;
            default:
                if(mg->mg_obj && sv != mg->mg_obj){
                    debs(" ");
                    debsv_peek(mg->mg_obj);
                }
            }
            debs(")");
        }
    }
}

#define debsv(sv) do_debsv(aTHX_ aMY_CXT_ sv)
static void
do_debsv(pTHX_ pMY_CXT_ SV* const sv){
    dVAR;
    HV* const seen = MY_CXT.debsv_seen;
    debsv_peek(sv);
    hv_clear(seen);
}

static void
do_debindent(pTHX_ pMY_CXT){
    dVAR;
    PERL_SI* si;
    for(si = PL_curstackinfo; si; si = si->si_prev){
        int i;
        for(i = si->si_cxix; i >= 0; i--){
            debs(" ");
        }
    }
}

static void
do_stack(pTHX_ pMY_CXT){
    dVAR;
    SV** svp = PL_stack_base + 1;
    SV** end = PL_stack_sp + 1;

    do_debindent(aTHX_ aMY_CXT);

    debs("(");
    while(svp != end){
        debsv(*svp);
        svp++;
        if(svp != end){
            debs(",");
        }
    }
    debs(")\n");
}

/* stolen from Perl_do_runcv() in pp_ctl.c */
static CV*
do_find_runcv(pTHX){
    PERL_SI *si;

    for (si = PL_curstackinfo; si; si = si->si_prev) {
        I32 ix;
        for (ix = si->si_cxix; ix >= 0; ix--) {
            PERL_CONTEXT* const cx = &(si->si_cxstack[ix]);
            if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
                return cx->blk_sub.cv;
            }
            else if (CxTYPE(cx) == CXt_EVAL && !CxTRYBLOCK(cx)){
                return PL_compcv;
            }
        }
    }
    return PL_main_cv;
}


#define debpadname(po) do_debpadname(aTHX_ aMY_CXT_ (po))
static void
do_debpadname(pTHX_ pMY_CXT_ PADOFFSET const targ){
    dVAR;
    CV* const cv = do_find_runcv(aTHX);
    AV* const padlist       = CvPADLIST(cv);
    AV* const comppad_names = (AV*)AvARRAY(padlist)[0];
    SV* name;

    assert(SvTYPE(comppad_names) == SVt_PVAV);
    if (AvMAX(comppad_names) < (I32)targ) {
        debs("?");
        return;
    }
    name = AvARRAY(comppad_names)[targ];


    if (SvPOKp(name)) {
#if PERL_BCDVERSION >= 0x5010000
        debpvn(SvPVX(name), SvCUR(name));
#else
        debpv(SvPVX(name));
#endif
    }
    else {
        debs("?");
    }
}


#define CopFILE_short(cop) do_shortname(aTHX_ CopFILE(cop))
static const char*
do_shortname(pTHX_ const char* path){
    if(path[0] == '/'){
        const char* file = path;
        while(*path){
            if(*path == '/'){
                file = ++path;
            }
            else{
                path++;
            }
        }
        return Perl_form(aTHX_ "/.../%s", file);
    }
    else{
        return path;
    }
}

#define Private(flag, name) STMT_START{ if(private & (flag)){ debs(name); } } STMT_END

static void
do_optrace(pTHX_ pMY_CXT){
    dVAR;
    const OP* const o = PL_op;
    int const flags   = o->op_flags;
    int const private = o->op_private;

    do_debindent(aTHX_ aMY_CXT);

    debpv(OP_NAME((OP*)o)); /* OP_NAME may require OP*, not const OP* */

    switch(o->op_type){
    case OP_NEXTSTATE:
    case OP_DBSTATE:
        debf("(%s%s %s:%d)",
            CopLABEL(cCOPo) ? CopLABEL(cCOPo) : "",
            CopSTASHPV(cCOPo),
            CopFILE_short(cCOPo), (int)CopLINE(cCOPo));
        break;

    case OP_CONST:
        debs("(");
        debsv(cSVOPo_sv);
        debs(")");

#ifdef OPpCONST_NOVER
        Private(OPpCONST_NOVER,        " NOVER");
#endif
        Private(OPpCONST_SHORTCIRCUIT, " SHORTCIRCUIT");
        Private(OPpCONST_STRICT,       " STRICT");
        Private(OPpCONST_ENTERED,      " ENTERED");
#ifdef OPpCONST_ARYBASE
        Private(OPpCONST_ARYBASE,      " ARYBASE");
#endif
        Private(OPpCONST_BARE,         " BARE");
        Private(OPpCONST_WARNING,      " WARNING");

        break;

    case OP_GV:
        debs("(");
        debgv(cGVOPo_gv, "*");
        debs(")");
        Private(OPpEARLY_CV, " EARLY_CV");
        goto intro_common;

    case OP_GVSV:
        debs("(");
        debgv(cGVOPo_gv, "$");
        debs(")");
        Private(OPpOUR_INTRO,  " OUR_INTRO");
        goto intro_common;

    case OP_RV2GV:
#ifdef OPpDONT_INIT_GV
        Private(OPpDONT_INIT_GV, " DONT_INIT_GV");
#endif
        goto intro_common;

    case OP_RV2SV:
    case OP_RV2AV:
    case OP_RV2HV:
        Private(OPpOUR_INTRO,  " OUR_INTRO");
        goto intro_common;

    case OP_AELEM:
    case OP_HELEM:
        Private(OPpLVAL_DEFER,  " LVAL_DEFER");
        goto intro_common;

    case OP_PADSV:
    case OP_PADAV:
    case OP_PADHV:
        debs("(");
        debpadname(o->op_targ);
        debs(")");

#ifdef OPpPAD_STATE
        Private(OPpPAD_STATE,  " STATE");
#endif

        intro_common:
        Private(OPpLVAL_INTRO, " LVAL_INTRO");
        Private(OPpDEREF,      " DEREF");
        Private(OPpMAYBE_LVSUB," MAYBE_LVSUB");

        break;

    case OP_AELEMFAST:
        debs("(");
        if(flags & OPf_SPECIAL){
            debpadname(o->op_targ);
        }
        else{
            debgv(cGVOPo_gv, "@");
        }
        debf("[%d])", private);
        break;

    case OP_ENTERITER:
        if(o->op_targ){ /* foreach my $var(...) */
            debs("(");
            debpadname(o->op_targ);
            debs(")");
        }

#ifdef OPpITER_DEF
        Private(OPpITER_DEF,      " DEF");
#endif
        Private(OPpLVAL_INTRO,    " LVAL_INTRO");
        Private(OPpOUR_INTRO,     " OUR_INTRO");
        Private(OPpITER_REVERSED, " REVERSED");
        break;

    case OP_ENTERSUB:
    {
        Private(OPpENTERSUB_DB,      " DB");
        Private(OPpENTERSUB_HASTARG, " HASTARG");
#ifdef OPpENTERSUB_NOMOD
        Private(OPpENTERSUB_NOMOD,   " NOMOD");
#endif
    }

        /* fall through */
    case OP_RV2CV:
        Private(OPpENTERSUB_AMPER,   " AMPER");
        Private(OPpENTERSUB_NOPAREN, " NOPAREN");
        Private(OPpENTERSUB_INARGS,  " INARGS");

        if(o->op_type == OP_RV2CV){
#ifdef OPpMAY_RETURN_CONSTANT
            Private(OPpMAY_RETURN_CONSTANT,   " MAY_RETURN_CONSTANT");
#endif
        }
        break;

    case OP_SASSIGN:
        Private(OPpASSIGN_BACKWARDS, " BACKWARDS");
#ifdef OPpASSIGN_CV_TO_GV
        Private(OPpASSIGN_CV_TO_GV,  " CV_TO_GV");
#endif
        break;

    case OP_AASSIGN:
        Private(OPpASSIGN_COMMON, " COMMON");
        break;

    case OP_METHOD_NAMED:
        debs("(");
        assert(SvPOKp(cSVOPo_sv));
        debpvn(SvPVX(cSVOPo_sv), SvCUR(cSVOPo_sv));
        debs(")");
        break;

    case OP_TRANS:
        Private(OPpTARGET_MY,        " TARGET_MY");
        Private(OPpTRANS_TO_UTF,     " TO_UTF");
        Private(OPpTRANS_IDENTICAL,  " IDENTICAL");
        Private(OPpTRANS_SQUASH,     " SQUASH");
        Private(OPpTRANS_COMPLEMENT, " COMPLEMENT");
        Private(OPpTRANS_GROWS,      " GROWS");
        Private(OPpTRANS_DELETE,     " DELETE");
        break;

    case OP_MATCH:
    case OP_SUBST:
    case OP_SUBSTCONT:
        Private(OPpTARGET_MY,        " TARGET_MY");
        Private(OPpRUNTIME, " RUNTIME");
        break;

    case OP_LEAVESUB:
    case OP_LEAVESUBLV:
    case OP_LEAVEEVAL:
    case OP_LEAVE:
    case OP_SCOPE:
    case OP_LEAVEWRITE:
        Private(OPpREFCOUNTED, " REFCOUNTED");
        break;

    case OP_REPEAT:
        Private(OPpREPEAT_DOLIST, " DOLIST");
        break;

    case OP_FLIP:
    case OP_FLOP:
        Private(OPpFLIP_LINENUM, " LINENUM");
        break;

    case OP_LIST:
        Private(OPpLIST_GUESSED, " GUESSED");
        break;

    case OP_DELETE:
        Private(OPpSLICE, " SLICE");
        break;

    case OP_EXISTS:
        Private(OPpEXISTS_SUB, " SUB");
        break;

    case OP_SORT:
        Private(OPpSORT_NUMERIC, " NUMERIC");
        Private(OPpSORT_INTEGER, " INTEGER");
        Private(OPpSORT_REVERSE, " REVERSE");
        Private(OPpSORT_INPLACE, " INPLACE");
        Private(OPpSORT_DESCEND, " DESCEND");
#ifdef OPpSORT_QSORT
        Private(OPpSORT_QSORT,   " QSORT");
#endif
#ifdef OPpSORT_STABLE
        Private(OPpSORT_STABLE,  " STABLE");
#endif
        break;

    case OP_OPEN:
    case OP_BACKTICK:
    Private(OPpOPEN_IN_RAW,   " IN_RAW");
    Private(OPpOPEN_IN_CRLF,  " IN_CRLF");
    Private(OPpOPEN_OUT_RAW,  " OUT_RAW");
    Private(OPpOPEN_OUT_CRLF, " OUT_CRLF");
    break;

    case OP_GREPSTART:
    case OP_GREPWHILE:
    case OP_MAPSTART:
    case OP_MAPWHILE:
#ifdef OPpGREP_LEX
        Private(OPpGREP_LEX, " LEX");
#endif
        break;

    case OP_ENTEREVAL:
#ifdef OPpEVAL_HAS_HH
        Private(OPpEVAL_HAS_HH, " HAS_HH");
#endif
        break;

    default:
        NOOP;
    }

    /* flags */
    switch(flags & OPf_WANT){
    case OPf_WANT_VOID:
        debs(" VOID");
        break;
    case OPf_WANT_SCALAR:
        debs(" SCALAR");
        break;
    case OPf_WANT_LIST:
        debs(" LIST");
        break;
    }

    if(flags & OPf_KIDS){
        debs(" KIDS");
    }
    if(flags & OPf_PARENS){
        debs(" PARENS");
    }
    if(flags & OPf_REF){
        debs(" REF");
    }
    if(flags & OPf_MOD){
        debs(" MOD");
    }
    if(flags & OPf_STACKED){
        debs(" STACKED");
    }
    if(flags & OPf_SPECIAL){
        debs(" SPECIAL");
    }

    debs("\n");
}

static void
do_debcount(pTHX_ pMY_CXT_ const OP* const o){
    dVAR;
    if(!MY_CXT.count_data){
        Newxz(MY_CXT.count_data, MAXO, U32);

        PerlProc_times(&(MY_CXT.start_tms));
    }
    MY_CXT.count_data[o->op_type]++;
}

static void
do_debcount_dump(pTHX_ pMY_CXT){
    struct tms end_tms;
    int i;

    if(!MY_CXT.count_data){
        return;
    }

    PerlProc_times(&end_tms);

    /* dump count_data */
    debf(">> name                times    (user=%.03"NVff" system=%.03"NVff")\n",
        (NV)(end_tms.tms_utime - MY_CXT.start_tms.tms_utime) / (NV)PL_clocktick,
        (NV)(end_tms.tms_stime - MY_CXT.start_tms.tms_stime) / (NV)PL_clocktick
    );
    for(i = 0; i < MAXO; i++){
        if(MY_CXT.count_data[i] > 0){
            debf(">> %-18s %8u\n",
                PL_op_name[i],
                (unsigned)MY_CXT.count_data[i]
            );
            debflush();
        }
    }
}

static void
do_debstackinfo(pTHX_ pMY_CXT){
    PERL_SI* const si = PL_curstackinfo;

    switch(si->si_type){
    default:
        debs(" UNKNOWN");
        break;
    case PERLSI_UNDEF:
        debs(" UNDEF");
        break;
    case PERLSI_MAIN:
        debs(" MAIN");
        break;
    case PERLSI_MAGIC:
        debs(" MAGIC");
        break;
    case PERLSI_SORT:
        debs(" SORT");
        break;
    case PERLSI_SIGNAL:
        debs(" SIGNAL");
        break;
    case PERLSI_OVERLOAD:
        debs(" OVERLOAD");
        break;
    case PERLSI_DESTROY:
        debs(" DESTROY");
        break;
    case PERLSI_WARNHOOK:
        debs(" WARNHOOK");
        break;
    case PERLSI_DIEHOOK:
        debs(" DIEHOOK");
        break;
    case PERLSI_REQUIRE:
        debs(" REQUIRE");
        break;
    }
}

static int
d_optrace_runops(pTHX){
    dVAR;
    dMY_DEBUG;

    if(DO_RUNOPS){
        do_debindent(aTHX_ aMY_CXT);
        debs("Entering RUNOPS");
        do_debstackinfo(aTHX_ aMY_CXT);
        debf(" (%s:%d)\n", CopFILE_short(PL_curcop), (int)CopLINE(PL_curcop));
    }

    do{
        PERL_ASYNC_CHECK();

        if(DO_STACK){
            do_stack(aTHX_ aMY_CXT);
        }
        if(DO_TRACE){
            do_optrace(aTHX_ aMY_CXT);
        }
        if(DO_COUNT){
            do_debcount(aTHX_ aMY_CXT_ PL_op);
        }

        debflush();
    }
    while((PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX)));

    if(DO_STACK){
        do_stack(aTHX_ aMY_CXT);
    }

    if(DO_RUNOPS){
        do_debindent(aTHX_ aMY_CXT);
        debs("Leaving RUNOPS");
        do_debstackinfo(aTHX_ aMY_CXT);
        debf(" (%s:%d)\n", CopFILE_short(PL_curcop), (int)CopLINE(PL_curcop));
    }

    debflush();

    TAINT_NOT;
    return 0;
}

static void
d_optrace_peep(pTHX_ OP* const o){
    dMY_DEBUG;

    if(!DO_NOOPT){
        MY_CXT.orig_peepp(aTHX_ o);
    }
}

static void
do_init(pTHX_ pMY_CXT){
    dVAR;

#if 0
    PL_dbargs   = NULL; /* @DB::args */
    PL_DBgv     = NULL; /* *DB::DB */
    PL_DBline   = NULL; /* *DB::line */
    PL_DBsub    = NULL; /* *DB::sub */
    PL_DBsingle = NULL; /* $DB::single */
    PL_DBtrace  = NULL; /* $DB::trace */
    PL_DBsignal = NULL; /* $DB::signal */
#endif

    MY_CXT.debugsv    = get_sv(PACKAGE "::DB", GV_ADD);
    MY_CXT.buff       = newSV(PV_LIMIT);
    MY_CXT.linebuf    = newSV(PV_LIMIT);
    MY_CXT.debsv_seen = newHV();

    sv_setpvs(MY_CXT.linebuf, "");


    if(PL_perldb){
        PL_perldb   = (PERLDBf_NAMEEVAL | PERLDBf_NAMEANON); /* $^P */
    }
}

MODULE = Devel::Optrace PACKAGE = Devel::Optrace

BOOT:
{
    HV* const stash = gv_stashpvs(PACKAGE, TRUE);
    MY_CXT_INIT;

    do_init(aTHX_ aMY_CXT);
    if(!SvOK(MY_CXT.debugsv)){
        sv_setiv(MY_CXT.debugsv, 0x00);
    }

    MY_CXT.orig_runops = PL_runops;
    MY_CXT.orig_peepp  = PL_peepp;

    newCONSTSUB(stash, "DOf_TRACE",   newSViv(DOf_TRACE));
    newCONSTSUB(stash, "DOf_STACK",   newSViv(DOf_STACK));
    newCONSTSUB(stash, "DOf_RUNOPS",  newSViv(DOf_RUNOPS));
    newCONSTSUB(stash, "DOf_NOOPT",   newSViv(DOf_NOOPT));
    newCONSTSUB(stash, "DOf_COUNT",   newSViv(DOf_COUNT));

    newCONSTSUB(stash, "DOf_DEFAULT", newSViv(DOf_DEFAULT));

    PL_runops = d_optrace_runops;
    PL_peepp  = d_optrace_peep;
}

PROTOTYPES: DISABLE

#ifdef USE_ITHREADS

void
CLONE(...)
CODE:
{
    MY_CXT_CLONE;
    do_init(aTHX_ aMY_CXT);
    PERL_UNUSED_VAR(items);
}

#endif

void
END(...)
CODE:
{
    dMY_CXT;
    do_debcount_dump(aTHX_ aMY_CXT);
    PERL_UNUSED_VAR(items);
}


void
p(...)
CODE:
{
    dMY_CXT;
    while(MARK != SP){
        debsv(*(++MARK));
        debs("\n");
        debflush();
    }
    PERL_UNUSED_VAR(items);
}

