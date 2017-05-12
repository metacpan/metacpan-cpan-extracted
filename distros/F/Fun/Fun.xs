#include "EXTERN.h"
#include "perl.h"
#include "callparser1.h"
#include "XSUB.h"

/* stolen (with modifications) from Scope::Escape::Sugar */

#define SVt_PADNAME SVt_PVMG

#ifndef COP_SEQ_RANGE_LOW_set
# define COP_SEQ_RANGE_LOW_set(sv,val) \
	do { ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xlow = val; } while(0)
# define COP_SEQ_RANGE_HIGH_set(sv,val) \
	do { ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xhigh = val; } while(0)
#endif /* !COP_SEQ_RANGE_LOW_set */

/*
 * pad handling
 *
 * The public API for the pad system is lacking any way to add items to
 * the pad.  This is a minimal implementation of the necessary facilities.
 * It doesn't warn about shadowing.
 */

#define pad_add_my_pvn(namepv, namelen, type) \
		THX_pad_add_my_pvn(aTHX_ namepv, namelen, type)
static PADOFFSET THX_pad_add_my_pvn(pTHX_
	char const *namepv, STRLEN namelen, svtype type)
{
	PADOFFSET offset;
	SV *namesv, *myvar;
	myvar = *av_fetch(PL_comppad, AvFILLp(PL_comppad) + 1, 1);
	offset = AvFILLp(PL_comppad);
	SvPADMY_on(myvar);
        SvUPGRADE(myvar, type);
	PL_curpad = AvARRAY(PL_comppad);
	namesv = newSV_type(SVt_PADNAME);
	sv_setpvn(namesv, namepv, namelen);
	COP_SEQ_RANGE_LOW_set(namesv, PL_cop_seqmax);
	COP_SEQ_RANGE_HIGH_set(namesv, PERL_PADSEQ_INTRO);
	PL_cop_seqmax++;
	av_store(PL_comppad_name, offset, namesv);
	return offset;
}

#define pad_add_my_sv(namesv, type) THX_pad_add_my_sv(aTHX_ namesv, type)
static PADOFFSET THX_pad_add_my_sv(pTHX_ SV *namesv, svtype type)
{
	char const *pv;
	STRLEN len;
	pv = SvPV(namesv, len);
	return pad_add_my_pvn(pv, len, type);
}

#define pad_add_my_scalar_sv(namesv) THX_pad_add_my_sv(aTHX_ namesv, SVt_NULL)
#define pad_add_my_array_sv(namesv)  THX_pad_add_my_sv(aTHX_ namesv, SVt_PVAV)
#define pad_add_my_hash_sv(namesv)   THX_pad_add_my_sv(aTHX_ namesv, SVt_PVHV)
#define pad_add_my_scalar_pvn(namepv, namelen) \
    THX_pad_add_my_pvn(aTHX_ namepv, namelen, SVt_NULL)
#define pad_add_my_array_pvn(namepv, namelen) \
    THX_pad_add_my_pvn(aTHX_ namepv, namelen, SVt_PVAV)
#define pad_add_my_hash_pvn(namepv, namelen) \
    THX_pad_add_my_pvn(aTHX_ namepv, namelen, SVt_PVHV)

/*
 * parser pieces
 *
 * These functions reimplement fairly low-level parts of the Perl syntax,
 * using the character-level public lexer API.
 */

#define DEMAND_IMMEDIATE 0x00000001
#define DEMAND_NOCONSUME 0x00000002
#define demand_unichar(c, f) THX_demand_unichar(aTHX_ c, f)
static void THX_demand_unichar(pTHX_ I32 c, U32 flags)
{
	if(!(flags & DEMAND_IMMEDIATE)) lex_read_space(0);
	if(lex_peek_unichar(0) != c) croak("syntax error");
	if(!(flags & DEMAND_NOCONSUME)) lex_read_unichar(0);
}

#define parse_idword(prefix) THX_parse_idword(aTHX_ prefix)
static SV *THX_parse_idword(pTHX_ char const *prefix)
{
	STRLEN prefixlen, idlen;
	SV *sv;
	char *start, *s, c;
	s = start = PL_parser->bufptr;
	c = *s;
	if(!isIDFIRST(c)) croak("syntax error");
	do {
		c = *++s;
	} while(isALNUM(c));
	lex_read_to(s);
	prefixlen = strlen(prefix);
	idlen = s-start;
	sv = sv_2mortal(newSV(prefixlen + idlen));
	Copy(prefix, SvPVX(sv), prefixlen, char);
	Copy(start, SvPVX(sv)+prefixlen, idlen, char);
	SvPVX(sv)[prefixlen + idlen] = 0;
	SvCUR_set(sv, prefixlen + idlen);
	SvPOK_on(sv);
	return sv;
}

#define parse_varname(sigil) THX_parse_varname(aTHX_ sigil)
static SV *THX_parse_varname(pTHX_ const char *sigil)
{
	demand_unichar(sigil[0], DEMAND_IMMEDIATE);
	lex_read_space(0);
	return parse_idword(sigil);
}

#define parse_scalar_varname() THX_parse_varname(aTHX_ "$")
#define parse_array_varname()  THX_parse_varname(aTHX_ "@")
#define parse_hash_varname()   THX_parse_varname(aTHX_ "%")

/* end stolen from Scope::Escape::Sugar */

#define parse_parameter_default(i, padoffset) THX_parse_parameter_default(aTHX_ i, padoffset)
static OP *THX_parse_parameter_default(pTHX_ IV i, PADOFFSET padoffset)
{
    SV *name;
    OP *default_expr, *check_args, *get_var, *assign_default;
    char sigil;

    lex_read_space(0);

    default_expr = parse_arithexpr(0);

    check_args = newBINOP(OP_LE, 0, newUNOP(OP_RV2AV, 0, newGVOP(OP_GV, 0, gv_fetchpv("_", 0, SVt_PVAV))), newSVOP(OP_CONST, 0, newSViv(i)));

    name = newSVsv(*av_fetch(PL_comppad_name, padoffset, 0));
    sigil = SvPVX(name)[0];
    if (sigil == '$') {
        get_var = newOP(OP_PADSV, 0);
    }
    else if (sigil == '@') {
        get_var = newOP(OP_PADAV, 0);
    }
    else if (sigil == '%') {
        get_var = newOP(OP_PADHV, 0);
    }
    else {
        croak("weird pad entry %"SVf, name);
    }
    get_var->op_targ = padoffset;
    assign_default = newASSIGNOP(OPf_STACKED, get_var, 0, default_expr);

    return newLOGOP(OP_AND, 0, check_args, assign_default);
}

#define parse_function_prototype() THX_parse_function_prototype(aTHX)
static OP *THX_parse_function_prototype(pTHX)
{
    OP *myvars, *defaults, *get_args, *arg_assign;
    IV i = 0;
    SV *seen_slurpy = NULL;

    demand_unichar('(', DEMAND_IMMEDIATE);

    lex_read_space(0);
    if (lex_peek_unichar(0) == ')') {
        lex_read_unichar(0);
        return NULL;
    }

    myvars = newLISTOP(OP_LIST, 0, NULL, NULL);
    defaults = newLISTOP(OP_LINESEQ, 0, NULL, NULL);

    for (;;) {
        OP *pad_op;
        char next;
        I32 type;
        SV *name;

        lex_read_space(0);
        next = lex_peek_unichar(0);
        if (next == '$') {
            name = parse_scalar_varname();
            if (seen_slurpy) {
                croak("Can't declare parameter %"SVf" after slurpy parameter %"SVf, name, seen_slurpy);
            }
            pad_op = newOP(OP_PADSV, 0);
            pad_op->op_targ = pad_add_my_scalar_sv(name);
        }
        else if (next == '@') {
            name = parse_array_varname();
            if (seen_slurpy) {
                croak("Can't declare parameter %"SVf" after slurpy parameter %"SVf, name, seen_slurpy);
            }
            pad_op = newOP(OP_PADAV, 0);
            pad_op->op_targ = pad_add_my_array_sv(name);
            seen_slurpy = name;
        }
        else if (next == '%') {
            name = parse_hash_varname();
            if (seen_slurpy) {
                croak("Can't declare parameter %"SVf" after slurpy parameter %"SVf, name, seen_slurpy);
            }
            pad_op = newOP(OP_PADHV, 0);
            pad_op->op_targ = pad_add_my_hash_sv(name);
            seen_slurpy = name;
        }
        else {
            croak("syntax error");
        }

        op_append_elem(OP_LIST, myvars, pad_op);

        lex_read_space(0);
        next = lex_peek_unichar(0);

        if (next == '=') {
            OP *set_default;

            lex_read_unichar(0);
            set_default = parse_parameter_default(i, pad_op->op_targ);
            op_append_elem(OP_LINESEQ,
                           defaults,
                           newSTATEOP(0, NULL, set_default));

            lex_read_space(0);
            next = lex_peek_unichar(0);
        }

        i++;

        if (next == ',') {
            lex_read_unichar(0);
        }
        else if (next == ')') {
            lex_read_unichar(0);
            break;
        }
        else {
            croak("syntax error");
        }
    }

    myvars = Perl_localize(aTHX_ myvars, 1);
    myvars = Perl_sawparens(aTHX_ myvars);

    get_args = newUNOP(OP_RV2AV, 0, newGVOP(OP_GV, 0, gv_fetchpv("_", 0, SVt_PVAV)));
    arg_assign = newASSIGNOP(OPf_STACKED, myvars, 0, get_args);

    return op_prepend_elem(OP_LINESEQ,
                           newSTATEOP(0, NULL, arg_assign),
                           defaults);
}

static OP *parse_fun(pTHX_ GV *namegv, SV *psobj, U32 *flagsp)
{
    I32 floor;
    SV *function_name = NULL;
    CV *code;
    OP *arg_assign = NULL, *block, *name;


    lex_read_space(0);
    if (isIDFIRST(*(PL_parser->bufptr)) || *(PL_parser->bufptr) == ':') {
        floor = start_subparse(0, 0);
        function_name = sv_2mortal(newSVpvs(""));
        while (isIDFIRST(*(PL_parser->bufptr)) || *(PL_parser->bufptr) == ':') {
            if (lex_peek_unichar(0) == ':') {
                demand_unichar(':', DEMAND_IMMEDIATE);
                demand_unichar(':', DEMAND_IMMEDIATE);
                sv_catpvs(function_name, "::");
            }
            else {
                sv_catsv(function_name, parse_idword(""));
            }
        }
    }
    else {
        floor = start_subparse(0, CVf_ANON);
    }

    lex_read_space(0);
    if (lex_peek_unichar(0) == '(') {
        arg_assign = parse_function_prototype();
    }

    demand_unichar('{', DEMAND_NOCONSUME);

    block = parse_block(0);

    if (arg_assign) {
        block = op_prepend_elem(OP_LINESEQ,
	                        newSTATEOP(0, NULL, arg_assign),
	                        block);
    }

    if (function_name) {
        SV *code;

        *flagsp |= CALLPARSER_STATEMENT;
        SvREFCNT_inc(function_name);
        name = newSVOP(OP_CONST, 0, function_name);
        code = newRV_inc((SV*)newATTRSUB(floor, name, NULL, NULL, block));

        return newOP(OP_NULL, 0);
    }
    else {
        OP *code;

        code = newANONSUB(floor, NULL, block);

        return newLISTOP(OP_LIST, 0, code, NULL);
    }
}

static OP *check_fun(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    OP *kids, *args;

    kids = cUNOPx(entersubop)->op_first;
    args = cLISTOPx(kids)->op_first->op_sibling;
    if (args->op_type == OP_NULL) {
        op_free(entersubop);
        return newOP(OP_NULL, 0);
    }
    else {
        return entersubop;
    }
}

MODULE = Fun  PACKAGE = Fun

PROTOTYPES: DISABLE

BOOT:
{
    cv_set_call_parser(get_cv("Fun::fun", 0), parse_fun, &PL_sv_undef);
    cv_set_call_checker(get_cv("Fun::fun", 0), check_fun, &PL_sv_undef);
}
