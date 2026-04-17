#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "listquote_callparser0.h"
#include "XSUB.h"

#ifndef op_append_elem
# define op_append_elem(t, f, l) THX_op_append_elem(aTHX_ t, f, l)
static OP *THX_op_append_elem(pTHX_ I32 type, OP *first, OP *last)
{
	if(!first) return last;
	if(!last) return first;
	if(first->op_type != (unsigned)type ||
			(type == OP_LIST && (first->op_flags & OPf_PARENS)))
		return newLISTOP(type, 0, first, last);
	if(first->op_flags & OPf_KIDS) {
		cLISTOPx(first)->op_last->op_sibling = last;
	} else {
		first->op_flags |= OPf_KIDS;
		cLISTOPx(first)->op_first = last;
	}
	cLISTOPx(first)->op_last = last;
	return first;
}
#endif /* !op_append_elem */

static OP *THX_parse_args_listquote(pTHX_ GV *namegv, SV *psobj, U32 *flags_p)
{
	I32 qc;
	OP *argsop;
	PERL_UNUSED_ARG(namegv);
	argsop = newLISTOP(OP_LIST, 0,
			newSVOP(OP_CONST, 0, SvREFCNT_inc(psobj)),
			NULL);
	lex_read_space(0);
	qc = lex_read_unichar(0);
	if(qc == -1) croak("unexpected EOF");
	while(1) {
		I32 c = lex_read_unichar(0);
		char cc;
		SV *csv;
		if(c == -1) croak("unexpected EOF");
		if(c == qc) break;
		if(c > 0xff) croak("can't handle non-Latin-1 character");
		cc = (char)c;
		csv = newSVpvn(&cc, 1);
		argsop = op_append_elem(OP_LIST,
				argsop, newSVOP(OP_CONST, 0, csv));
	}
	if(qc == '!') *flags_p |= CALLPARSER_STATEMENT;
	return argsop;
}

MODULE = t::listquote PACKAGE = t::listquote

PROTOTYPES: DISABLE

void
cv_set_call_parser_listquote(CV *cv, SV *psobj)
PROTOTYPE: $$
CODE:
	cv_set_call_parser(cv, THX_parse_args_listquote, psobj);
