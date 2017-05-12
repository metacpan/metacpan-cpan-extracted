#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <SWI-Prolog.h>

#include "context.h"
#include "plconfig.h"
#include "argv.h"
#include "swi2perl.h"
#include "perl2swi.h"
#include "opaque.h"
#include "vars.h"
#include "query.h"
#include "callperl.h"
#include "engines.h"
#include "Low.h"


void savestate_Low(pTHX_ pMY_CXT) {
    save_item(c_depth);
    sv_inc(c_depth);
}


MODULE = Language::Prolog::Yaswi::Low   PACKAGE = Language::Prolog::Yaswi::Low   PREFIX = yaswi_

BOOT:
{
    dTHX;
    init_cxt(aTHX);
    boot_callperl();
}

PROTOTYPES: ENABLE

void
yaswi_CLONE(klass)
    SV *klass
CODE:
    init_cxt(aTHX);


void
yaswi_END()
PREINIT:
    MY_dMY_CXT;
CODE:
    /* warn ("calling END code (thread=%i)", PL_thread_self()); */
    release_prolog(aTHX_ aMY_CXT);
    release_cxt(aTHX_ aMY_CXT);


SV *
yaswi_PL_EXE()
CODE:
    RETVAL=newSVpv(PL_exe, 0);
OUTPUT:
    RETVAL


void
yaswi_start()
PREINIT:
    MY_dMY_CXT;
CODE:
    if (PL_is_initialised(NULL, NULL)) {
	croak ("SWI-Prolog engine already initialised");
    }
    check_prolog(aTHX_ aMY_CXT);


void
yaswi_cleanup()
PREINIT:
    MY_dMY_CXT;
CODE:
    test_no_query(aTHX_ aMY_CXT);
    if (SvIV(c_depth) > 1) {
	croak ("swi_cleanup called from call back");
    }
    release_prolog(aTHX_ aMY_CXT);


int
yaswi_toplevel()
PREINIT:
    MY_dMY_CXT;
CODE:
    check_prolog(aTHX_ aMY_CXT);
    RETVAL=PL_toplevel();
OUTPUT:
    RETVAL


SV *
yaswi_swi2perl(term)
    SV *term;
PREINIT:
    MY_dMY_CXT;
CODE:
    check_prolog(aTHX_ aMY_CXT);
    if (!SvIOK(term)) {
	croak ("'%s' is not a valid SWI-Prolog term", SvPV_nolen(term));
    }
    RETVAL=swi2perl(aTHX_ SvIV(term),
		    get_cells(aTHX_ aMY_CXT));
OUTPUT:
    RETVAL


void
yaswi_openquery(query_obj, module)
    SV *query_obj;
    SV *module;
PREINIT:
    MY_dMY_CXT;
    term_t q, arg0;
    module_t m;
    predicate_t predicate;
    AV *refs, *cells;
PPCODE:
    check_prolog(aTHX_ aMY_CXT);
    test_no_query(aTHX_ aMY_CXT);
    push_frame(aTHX_ aMY_CXT);
    q=PL_new_term_ref();
    if (pl_unify_perl_sv(aTHX_ q, 
			 query_obj,
			 refs=(AV *)sv_2mortal((SV *)newAV()),
			 cells=(AV *)sv_2mortal((SV *)newAV()))) {
	functor_t functor;
	if (PL_get_functor(q, &functor)) {
	    int arity, i;
	    arity=PL_functor_arity(functor);
	    arg0=PL_new_term_refs(arity);
	    for (i=0; i<arity; i++) {
		PL_unify_arg(i+1, q, arg0+i);
	    }
	    perl2swi_module(aTHX_ module, &m);
	    predicate=PL_pred(functor, m);
	    sv_setiv(c_qid, PL_open_query(0,
					  PL_Q_NODEBUG|PL_Q_CATCH_EXCEPTION,
					  predicate, arg0));

	    sv_setiv(c_query, q);
	    set_vars(aTHX_ aMY_CXT_ refs, cells);
	    XPUSHs(sv_2mortal(newRV_inc((SV *)refs)));
	}
	else {
	    pop_frame(aTHX_ aMY_CXT);
	    croak("unable to convert perl data to prolog query (%s)", SvPV_nolen(query_obj));
	}
    }
    else {
	pop_frame(aTHX_ aMY_CXT);
	croak("unable to convert perl data to prolog (%s)", SvPV_nolen(query_obj));
    }

void
yaswi_cutquery()
PREINIT:
    MY_dMY_CXT;
CODE:
    check_prolog(aTHX_ aMY_CXT);
    test_query(aTHX_ aMY_CXT);
    close_query(aTHX_ aMY_CXT);

int
yaswi_nextsolution()
PREINIT:
    MY_dMY_CXT;
CODE:
    check_prolog(aTHX_ aMY_CXT);
    test_query(aTHX_ aMY_CXT); 
    cut_anonymous_vars(aTHX_ aMY_CXT);
    if(PL_next_solution(SvIV(c_qid))) {
	RETVAL=1;
    }
    else {
	term_t e;
	RETVAL=0;
	if (e=PL_exception(SvIV(c_qid))) {
	    /* warn ("exception cached"); */
	    SV *errsv = get_sv("@", TRUE);
	    sv_setsv( errsv,
		      sv_2mortal(swi2perl(aTHX_
					  e,
					  get_cells(aTHX_ aMY_CXT))));
	    close_query(aTHX_ aMY_CXT);
	    croak(Nullch);
	}
	else {
	    close_query(aTHX_ aMY_CXT);
	}
    }
OUTPUT:
    RETVAL
    
void
yaswi_testquery()
PREINIT:
    MY_dMY_CXT;
CODE:
    check_prolog(aTHX_ aMY_CXT);
    test_query(aTHX_ aMY_CXT);


IV
yaswi_ref2int(rv)
    SV *rv;
CODE:
    if (!SvROK(rv)) {
	croak ("value passed to ref2int is not a reference");
    }
    RETVAL = PTR2IV(SvRV(rv));
OUTPUT:
    RETVAL


