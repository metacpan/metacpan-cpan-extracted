#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "callchecker0.h"
#include "XSUB.h"

static OP *pp_numify(pTHX)
{
    dSP;
    SV *scalar_to_numify;
    int num_type;
    const char *pv;
    STRLEN len;
    UV valuep;

    scalar_to_numify = newSVsv(POPs);

    if (SvUOK(scalar_to_numify)) {
        sv_setuv(scalar_to_numify, SvIV(scalar_to_numify));
    } else if (SvIOK(scalar_to_numify)) {
        sv_setiv(scalar_to_numify, SvUV(scalar_to_numify));
    } else if (SvNOK(scalar_to_numify)) {
        sv_setnv(scalar_to_numify, SvNV(scalar_to_numify));
    } else {
        pv = SvPV(scalar_to_numify, len);
        num_type = grok_number(pv, len, &valuep);

        if (!num_type || num_type & IS_NUMBER_NOT_INT) {
            sv_setnv(scalar_to_numify, SvNV(scalar_to_numify));
        } else {
            if (!(num_type & IS_NUMBER_IN_UV)) {
                sv_setnv(scalar_to_numify, SvNV(scalar_to_numify));
            } else if (num_type & IS_NUMBER_NEG) {
                sv_setiv(scalar_to_numify, SvIV(scalar_to_numify));
            } else {
                sv_setuv(scalar_to_numify, valuep);
            }
        }
    }

    if(GIMME_V != G_VOID) PUSHs(scalar_to_numify);
    RETURN;
}

#define gen_numify_op(argop) \
        THX_gen_numify_op(aTHX_ argop)
static OP *THX_gen_numify_op(pTHX_ OP *argop)
{
    OP *my_op;
    NewOpSz(0, my_op, sizeof(UNOP));
    my_op->op_type = OP_CUSTOM;
    my_op->op_ppaddr = pp_numify;
    cUNOPx(my_op)->op_flags = OPf_KIDS;
    cUNOPx(my_op)->op_first = argop;
    return my_op;
}

static OP *myck_entersub_json_number(pTHX_ OP *entersubop,
    GV *namegv, SV *protosv)
{
    OP *pushop, *argop;
    entersubop = ck_entersub_args_proto(entersubop, namegv, protosv);
    pushop = cUNOPx(entersubop)->op_first;
    if(!pushop->op_sibling) pushop = cUNOPx(pushop)->op_first;
    argop = pushop->op_sibling;
    if(!argop) return entersubop;
    pushop->op_sibling = argop->op_sibling;
    argop->op_sibling = NULL;
    op_free(entersubop);
    return gen_numify_op(argop);
}

static OP *myck_entersub_json_string(pTHX_ OP *entersubop,
    GV *namegv, SV *protosv)
{
    OP *pushop, *argop;
    entersubop = ck_entersub_args_proto(entersubop, namegv, protosv);
    pushop = cUNOPx(entersubop)->op_first;
    if(!pushop->op_sibling) pushop = cUNOPx(pushop)->op_first;
    argop = pushop->op_sibling;
    if(!argop) return entersubop;
    pushop->op_sibling = argop->op_sibling;
    argop->op_sibling = NULL;
    op_free(entersubop);

    return newLISTOP(OP_STRINGIFY, 0, newOP(OP_PUSHMARK, 0), argop);
}

MODULE = JSON::XS::Sugar PACKAGE = JSON::XS::Sugar

PROTOTYPES: DISABLE

BOOT:
{
    XOP *xop;

    CV *json_number_cv = get_cv("JSON::XS::Sugar::json_number", 0);
    cv_set_call_checker(json_number_cv, myck_entersub_json_number,
        (SV*)json_number_cv);

    Newxz(xop, 1, XOP);
    XopENTRY_set(xop, xop_name, "json_number");
    XopENTRY_set(xop, xop_desc, "json_number");
    XopENTRY_set(xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_numify, xop);

    CV *json_string_cv = get_cv("JSON::XS::Sugar::json_string", 0);
    cv_set_call_checker(json_string_cv, myck_entersub_json_string,
        (SV*)json_string_cv);
}

void
json_number(...)
PROTOTYPE: $
CODE:
    PERL_UNUSED_VAR(items);
    croak("json_number called as a function");

void
json_string(...)
PROTOTYPE: $
CODE:
    PERL_UNUSED_VAR(items);
    croak("json_string called as a function");