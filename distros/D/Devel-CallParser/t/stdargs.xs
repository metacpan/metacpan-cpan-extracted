#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "stdargs_callparser1.h"
#include "XSUB.h"

static OP *THX_pa_parenthesised(pTHX_ GV *namegv, SV *psobj, U32 *flags_p)
{
	PERL_UNUSED_ARG(namegv);
	PERL_UNUSED_ARG(psobj);
	return parse_args_parenthesised(flags_p);
}

static OP *THX_pa_nullary(pTHX_ GV *namegv, SV *psobj, U32 *flags_p)
{
	PERL_UNUSED_ARG(namegv);
	PERL_UNUSED_ARG(psobj);
	return parse_args_nullary(flags_p);
}

static OP *THX_pa_unary(pTHX_ GV *namegv, SV *psobj, U32 *flags_p)
{
	PERL_UNUSED_ARG(namegv);
	PERL_UNUSED_ARG(psobj);
	return parse_args_unary(flags_p);
}

static OP *THX_pa_list(pTHX_ GV *namegv, SV *psobj, U32 *flags_p)
{
	PERL_UNUSED_ARG(namegv);
	PERL_UNUSED_ARG(psobj);
	return parse_args_list(flags_p);
}

static OP *THX_pa_block_list(pTHX_ GV *namegv, SV *psobj, U32 *flags_p)
{
	PERL_UNUSED_ARG(namegv);
	PERL_UNUSED_ARG(psobj);
	return parse_args_block_list(flags_p);
}

MODULE = t::stdargs PACKAGE = t::stdargs

PROTOTYPES: DISABLE

void
cv_set_call_parser_parenthesised(CV *cv)
PROTOTYPE: $
CODE:
	cv_set_call_parser(cv, THX_pa_parenthesised, &PL_sv_undef);

void
cv_set_call_parser_nullary(CV *cv)
PROTOTYPE: $
CODE:
	cv_set_call_parser(cv, THX_pa_nullary, &PL_sv_undef);

void
cv_set_call_parser_unary(CV *cv)
PROTOTYPE: $
CODE:
	cv_set_call_parser(cv, THX_pa_unary, &PL_sv_undef);

void
cv_set_call_parser_list(CV *cv)
PROTOTYPE: $
CODE:
	cv_set_call_parser(cv, THX_pa_list, &PL_sv_undef);

void
cv_set_call_parser_block_list(CV *cv)
PROTOTYPE: $
CODE:
	cv_set_call_parser(cv, THX_pa_block_list, &PL_sv_undef);
