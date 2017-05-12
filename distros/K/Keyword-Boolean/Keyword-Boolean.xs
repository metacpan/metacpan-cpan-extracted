#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef USE_PPPORT
#include "ppport.h"
#endif

SV* hintkey_sv;
static Perl_keyword_plugin_t next_keyword_plugin;

#define keyword_active(hintkey) THX_keyword_active(aTHX_ hintkey)
static int
THX_keyword_active(pTHX_ SV* const hintkey)
{
    if(GvHV(PL_hintgv) && PL_hints & HINT_LOCALIZE_HH){
        HE* const he = hv_fetch_ent(GvHV(PL_hintgv),
            hintkey, FALSE, 0U);

        return he && SvTRUE(HeVAL(he));
    }

    return FALSE;
}

#define keyword_enable(hintkey) THX_keyword_enable(aTHX_ hintkey)
static void
THX_keyword_enable(pTHX_ SV* const hintkey)
{
    HE* const he = hv_fetch_ent(GvHVn(PL_hintgv), hintkey, TRUE, 0U);
    sv_setsv_mg(HeVAL(he), &PL_sv_yes);

    PL_hints |= HINT_LOCALIZE_HH;
}

#define keyword_disable(hintkey) THX_keyword_disable(aTHX_ hintkey)
static void
THX_keyword_disable(pTHX_ SV* hintkey)
{
    if(!GvHV(PL_hintgv)) {
        return;
    }
    (void)hv_delete_ent(GvHV(PL_hintgv), hintkey, G_DISCARD, 0U);

    PL_hints |= HINT_LOCALIZE_HH;
}

#define keyword_eq(kp, kl, s) ((kl) == (sizeof(s)-1) && strnEQ((kp), s, kl))

static int
my_keyword_plugin(pTHX_
    char* const keyword_ptr, STRLEN const keyword_len, OP** const op_ptr)
{
    if(keyword_active(hintkey_sv)){
        //warn("[%*s]", (int)keyword_len, keyword_ptr);
        if(keyword_eq(keyword_ptr, keyword_len, "true")){
            *op_ptr = newSVOP(OP_CONST, 0, &PL_sv_yes);
            return KEYWORD_PLUGIN_EXPR;
        }
        else if(keyword_eq(keyword_ptr, keyword_len, "false")){
            *op_ptr = newSVOP(OP_CONST, 0, &PL_sv_no);
            return KEYWORD_PLUGIN_EXPR;
        }
    }

    return next_keyword_plugin(aTHX_
            keyword_ptr, keyword_len, op_ptr);
}

MODULE = Keyword::Boolean    PACKAGE = Keyword::Boolean

BOOT:
    hintkey_sv = newSVpvs_share("Keyword::Boolean");
    next_keyword_plugin = PL_keyword_plugin;
    PL_keyword_plugin   = my_keyword_plugin;

void
import(classname, ...)
CODE:
    keyword_enable(hintkey_sv);

void
unimport(classname, ...)
CODE:
    keyword_disable(hintkey_sv);
