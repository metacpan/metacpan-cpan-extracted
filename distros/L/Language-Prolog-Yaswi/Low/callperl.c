#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <SWI-Prolog.h>

#include "context.h"

#include "engines.h"
#include "perl2swi.h"
#include "swi2perl.h"
#include "query.h"
#include "vars.h"
#include "Low.h"
#include "callperl.h"


static foreign_t swi2perl_sub(term_t name,
			      term_t args,
			      term_t result );

static foreign_t swi2perl_eval(term_t code,
			       term_t result);

static foreign_t swi2perl_method(term_t object,
				 term_t method,
				 term_t args,
				 term_t result);

static PL_extension callperl[] = {
    { "perl5_call",   3, swi2perl_sub,    0 },
    { "perl5_eval",   2, swi2perl_eval,   0 },
    { "perl5_method", 4, swi2perl_method, 0 },
    { NULL, 0, NULL, 0 }, };

void boot_callperl(void) {
    static int registered=0;
    if(!registered) {
	registered=1;
	PL_register_extensions(callperl);
    }
}

static void
savestate(pTHX_ pMY_CXT) {
    savestate_Low(aTHX_ aMY_CXT);
    savestate_query(aTHX_ aMY_CXT);
    savestate_vars(aTHX_ aMY_CXT);
}

static int
test_open_query(pTHX_ pMY_CXT) {
    if (is_query(aTHX_ aMY_CXT)) {
	close_query(aTHX_ aMY_CXT);
	return TRUE;
    }
    return FALSE;
}

static int
check_error_and_pop_results(pTHX_ pMY_CXT_ term_t t, int n) {
    dSP;
    AV *refs=(AV*)sv_2mortal((SV *)newAV());
    AV *cells=(AV*)sv_2mortal((SV *)newAV());

    if (n && SvTRUE(ERRSV)) {
	term_t e, pe;
	test_open_query(aTHX_ aMY_CXT);
	e=PL_new_term_ref();
	pe=PL_new_term_ref();

	pl_unify_perl_sv(aTHX_ pe, ERRSV, refs, cells);
	PL_unify_term(e,
		      PL_FUNCTOR_CHARS, "perl_exception", 1,
		      PL_TERM, pe);
	PL_raise_exception(e);
	return FALSE;
    }
    else if (test_open_query(aTHX_ aMY_CXT)) {
	term_t e=PL_new_term_ref();
	PL_unify_term(e,
		      PL_FUNCTOR_CHARS, "perl_exception", 1,
		      PL_CHARS, "open_query");
	PL_raise_exception(e);
	return FALSE;
    }
    else {
	AV *ret=(AV*)sv_2mortal((SV*)newAV());
	av_extend(ret, n-1);
	while(--n>=0) {
	    SV *sv=POPs;
	    SvREFCNT_inc(sv);
	    av_store(ret, n, sv);
	}
	return pl_unify_perl_av(aTHX_ t, ret, 0, refs, cells);
    }
}

static int
push_args(pTHX_ term_t obj, int obj_ok, term_t args) {
    dSP;
    term_t head, list;
    AV *cells=(AV *)sv_2mortal((SV *) newAV());
    if (obj_ok) {
	XPUSHs(sv_2mortal(swi2perl(aTHX_ obj,cells)));
    }
    head=PL_new_term_ref();
    list=PL_copy_term_ref(args);
    while (!PL_get_nil(list)) {
	if (PL_get_list(list, head, list)) {
	    XPUSHs(sv_2mortal(swi2perl(aTHX_ head, cells)));
	}
	else {
	    term_t e=PL_new_term_ref();
	    PL_unify_term(e,
			  PL_FUNCTOR_CHARS, "type_error", 2,
			  PL_CHARS, "list",
			  PL_TERM, args);
	    PL_raise_exception(e);
	    return FALSE;
	}
    }
    PUTBACK;
    return TRUE;
}

static foreign_t swi2perl_sub(term_t name,
			      term_t args,
			      term_t result ) {
    MY_dTHX;
    MY_dMY_CXT;
    dSP;

    SV *svname = swi2perl_atom_sv_ex(aTHX_ name);
    if (svname) {
	int n;
	int ret=FALSE;

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	savestate(aTHX_ aMY_CXT);
	sv_2mortal(svname);
	if (push_args(aTHX_ 0, 0, args)) {
	    n = call_sv(svname, G_ARRAY | G_EVAL);
	    ret=check_error_and_pop_results(aTHX_ aMY_CXT_ result, n);
	}

	SPAGAIN;
	FREETMPS;
	LEAVE;

	return ret;
    }
    return FALSE;
}

static foreign_t swi2perl_eval(term_t code,
			       term_t result) {
    MY_dTHX;
    MY_dMY_CXT;
    dSP;
    
    SV *svcode = swi2perl_atom_sv_ex(aTHX_ code);
    if (svcode) {
	int n;
	int ret=FALSE;

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	savestate(aTHX_ aMY_CXT);
	sv_2mortal(svcode);
	n=eval_sv(svcode, G_ARRAY | G_EVAL);
	ret=check_error_and_pop_results(aTHX_ aMY_CXT_ result, n);
	SPAGAIN;
	FREETMPS;
	LEAVE;
	return ret;
    }
    return FALSE;
}

static foreign_t swi2perl_method(term_t object,
				 term_t method,
				 term_t args,
				 term_t result) {
    MY_dTHX;
    MY_dMY_CXT;
    dSP;
    SV *svmethod = swi2perl_atom_sv_ex(aTHX_ method);
    if (svmethod) {
	int n;
	int ret=FALSE;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	savestate(aTHX_ aMY_CXT);
	sv_2mortal(svmethod);
	if (push_args(aTHX_ object, 1, args)) {
	    n=call_method(SvPV_nolen(svmethod), G_ARRAY|G_EVAL);
	    ret=check_error_and_pop_results(aTHX_ aMY_CXT_ result, n);
	}
	SPAGAIN;
	FREETMPS;
	LEAVE;
	return ret;
    }
    return FALSE;
}

