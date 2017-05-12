#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <SWI-Prolog.h>

#include "Low.h"
#include "callback.h"
#include "hook.h"
#include "opaque.h"
#include "perl2swi.h"
#include "context.h"

/* prototypes */
static int pl_unify_perl_ifunctor(pTHX_ term_t t, SV *o, AV *refs, AV *cells);
static int pl_unify_perl_ilist(pTHX_ term_t t, SV *o, AV *refs, AV *cells);
static int pl_unify_perl_iulist(pTHX_ term_t t, SV *o, AV *refs, AV *cells);
static int pl_unify_perl_list(pTHX_ term_t t, SV *o, AV *refs, AV *cells);
static int pl_unify_perl_functor(pTHX_ term_t t, SV *o, AV *refs, AV *cells);
static int pl_unify_perl_var(pTHX_ term_t t, SV *sv, AV *refs, AV *cells);
static int pl_unify_perl_any_ref(pTHX_ term_t t, SV *ref, AV *refs, AV *cells);
static int pl_unify_perl_object(pTHX_ term_t t, SV *sv, AV *refs, AV *cells);
static int pl_unify_perl_rv(pTHX_ term_t t, SV *rv, AV *refs, AV *cells);


static SV *my_fetch (pTHX_ AV *av, int i) {
    SV **sv_p=av_fetch(av, i, 0);
    return (sv_p ? *sv_p : &PL_sv_undef);
}

static int
pl_unify_perl_ifunctor(pTHX_ term_t t, SV *o, AV *refs, AV *cells) {
    AV *array=(AV *)o;
    int i;
    int arity;

    if (SvTYPE(o)!=SVt_PVAV) {
	warn ("implementation mismatch, " TYPEINTPKG "::functor object is not an array ref");
	return FALSE;
    }

    arity=av_len(array);
    if (arity>0) {
	atom_t name_a;
	if ( ! perl2swi_new_atom(aTHX_ my_fetch(aTHX_ array, 0), &name_a) )
	    return FALSE;
	if ( PL_unify_functor(t, PL_new_functor(name_a, arity)) ) {
	    PL_unregister_atom(name_a);
	    for(i=1; i<=arity; i++) {
		term_t arg = PL_new_term_ref();
		if ( !PL_unify_arg(i, t, arg) ||
		     !pl_unify_perl_sv(aTHX_ arg, my_fetch(aTHX_ array, i),
				       refs, cells) )
		    return FALSE;
	    }
	    return TRUE;
	}
	PL_unregister_atom(name_a);
	return FALSE;
    }
    else {
	return pl_unify_perl_sv(aTHX_ t, my_fetch(aTHX_ array, 0), refs, cells);
    }
}

int
pl_unify_perl_av(pTHX_ term_t t, AV *array, int u, AV *refs, AV *cells) {
    term_t l = PL_copy_term_ref(t);
    term_t a = PL_new_term_ref();
    int i;
    int len=av_len(array);
    if (u) {
	len--;
	if (len<0) {
	    warn ("implementation mismatch, " TYPEINTPKG "::ulist object is an array with less than one element\n");
	    return FALSE;
	}
    }
    for(i=0; i<=len; i++) {
	if ( !PL_unify_list(l, a, l) ||
	     !pl_unify_perl_sv(aTHX_ a, my_fetch(aTHX_ array, i),
			       refs, cells) )
	    return FALSE;
    }

    if (u)
	return pl_unify_perl_sv(aTHX_ l, my_fetch(aTHX_ array, i),
				refs, cells);

    return PL_unify_nil(l);
}

static int
pl_unify_perl_ilist(pTHX_ term_t t, SV *o, AV *refs, AV *cells) {
    if (SvTYPE(o)!=SVt_PVAV) {
	warn ("implementation mismatch, " TYPEINTPKG "::list object is not an array ref");
	return FALSE;
    }
    return pl_unify_perl_av(aTHX_ t, (AV *)o, 0, refs, cells);
}

static int
pl_unify_perl_iulist(pTHX_ term_t t, SV *o, AV *refs, AV *cells) {
    if (SvTYPE(o)!=SVt_PVAV) {
	warn ("implementation mismatch, " TYPEINTPKG "::ulist object is not an array ref");
	return FALSE;
    }
    return pl_unify_perl_av(aTHX_ t, (AV *)o, 1, refs, cells);
}

static int
pl_unify_perl_list(pTHX_ term_t t, SV *o, AV *refs, AV *cells) {
    dSP;
    int i;
    int len;
    term_t l = PL_copy_term_ref(t);
    term_t a = PL_new_term_ref();

    len=call_method__int(aTHX_ o, "length");
    for (i=0; i<=len; i++) {
	SV *larg;
	ENTER;
	SAVETMPS;
	larg=call_method_int__sv(aTHX_ o, "larg", i);
	FREETMPS;
	LEAVE;
	if ( !PL_unify_list(l, a, l) ||
	     !pl_unify_perl_sv(aTHX_ a, larg,
			       refs, cells) )
	    return FALSE;
    }
    return pl_unify_perl_sv(aTHX_ l, call_method__sv(aTHX_ o, "tail"),
			    refs, cells );
}

static int
pl_unify_perl_functor(pTHX_ term_t t, SV *o, AV *refs, AV *cells) {
    dSP;
    int arity;
    SV *name;

    name = call_method__sv(aTHX_ o, "functor");
    arity=call_method__int(aTHX_ o, "arity");
    if (arity>0) {
	atom_t name_a;
	if ( ! perl2swi_new_atom(aTHX_ call_method__sv(aTHX_ o, "functor"), &name_a) )
	    return FALSE;

	if ( PL_unify_functor(t, PL_new_functor(name_a, arity)) ) {
	    int i;
	    PL_unregister_atom(name_a);
	    for(i=1; i<=arity; i++) {
		term_t arg;
		SV *farg;
		ENTER;
		SAVETMPS;
		farg=call_method_int__sv(aTHX_ o, "farg", i-1);
		FREETMPS;
		LEAVE;
		arg=PL_new_term_ref();
		if ( !PL_unify_arg(i, t, arg) ||
		     !pl_unify_perl_sv(aTHX_ arg, farg,
				       refs, cells) )
		    return FALSE;
	    }
	    return TRUE;
	}
	PL_unregister_atom(name_a);
	return FALSE;
    }
    return pl_unify_perl_sv(aTHX_ t, name, refs, cells);
}

static int
pl_unify_perl_var(pTHX_ term_t t, SV *sv, AV *refs, AV *cells) {
    return TRUE;
}

static int
pl_unify_perl_any_ref(pTHX_ term_t t, SV *ref, AV *refs, AV *cells) {
    MY_dMY_CXT;
    return pl_unify_perl_sv(aTHX_ t,
			    call_method_sv__sv(aTHX_ c_converter,
					       "perl_ref2prolog", ref),
			    refs, cells);
}

static int
pl_unify_perl_object(pTHX_ term_t t, SV *sv, AV *refs, AV *cells) {

    if (sv_isa(sv,TYPEINTPKG "::list"))
	return pl_unify_perl_ilist(aTHX_ t, SvRV(sv), refs, cells);
    
    if (sv_isa(sv, TYPEINTPKG "::functor"))
	return pl_unify_perl_ifunctor(aTHX_ t,  SvRV(sv), refs, cells);
    
    if (sv_isa(sv, TYPEINTPKG "::nil"))
	return PL_unify_nil(t);
    
    if (sv_isa(sv, TYPEINTPKG "::opaque"))
	return pl_unify_perl_iopaque(aTHX_ t, sv, refs, cells);
    
    if (sv_isa(sv, TYPEINTPKG "::ulist"))
	return pl_unify_perl_iulist(aTHX_ t, SvRV(sv), refs, cells);
    
    if (sv_derived_from(sv, TYPEPKG "::Term")) {
	
	if (sv_derived_from(sv,TYPEPKG "::Variable"))
	    return pl_unify_perl_var(aTHX_ t, SvRV(sv), refs, cells);
	
	if (sv_derived_from(sv,TYPEPKG "::List"))
	    return pl_unify_perl_list(aTHX_ t, SvRV(sv), refs, cells);
	
	if (sv_derived_from(sv, TYPEPKG "::Functor"))
	    return pl_unify_perl_functor(aTHX_ t,  SvRV(sv), refs, cells);
	
	if (sv_derived_from(sv, TYPEPKG "::Nil"))
	    return PL_unify_nil(t);
	
	if (sv_derived_from(sv, TYPEPKG "::Opaque"))
	    return pl_unify_perl_opaque(aTHX_ t, sv, refs, cells);
	
	die ("unable to convert " TYPEPKG "::Term object '%s' to Prolog term",
	     SvPV_nolen(sv));
	return FALSE;
    }
    return pl_unify_perl_any_ref(aTHX_ t, sv, refs, cells);
}

int
lookup_ref(pTHX_ term_t *t, SV *sv, AV *refs, AV *cells) {
    int i;
    int len=av_len(refs);
    /* warn ("lookup_ref(%_, %_, %_)\n", sv, refs, cells); */
    if(sv_isobject(sv) && sv_derived_from(sv, TYPEPKG "::Variable")) {
	/* variables are the same if they have the same name, even if
	 * they are at different addresses */
	dSP;
	SV *name;
	ENTER;
	SAVETMPS;
	name=call_method__sv(aTHX_ sv, "name");
	for (i=0; i<=len; i++) {
	    SV *ref=my_fetch(aTHX_ refs, i);
	    if ( sv_isobject(ref) &&
		 sv_derived_from(ref, TYPEPKG "::Variable") &&
		 !sv_cmp(name, call_method__sv(aTHX_ ref, "name"))) {
		break;
	    }
	}
	FREETMPS;
	LEAVE;
    }
    else {
	SV *new_ref=SvRV(sv);
	for (i=0; i<=len; i++) {
	    SV **ref_p=av_fetch(refs, i, 0);
	    if(!ref_p) {
		warn ("internal error, unable to fetch reference pointer from references cache");
		return FALSE;
	    }
	    if (new_ref==SvRV(*ref_p))
		break;
	}
    }
    if (i<=len) {
	SV **cell_p=av_fetch(cells, i, 0);
	if(!cell_p || !SvOK(*cell_p)) {
	    warn ("internal error, unable to fetch cell pointer from references cache");
	    return FALSE;
	}
	*t=SvIV(*cell_p);
	return TRUE;
    }
    return FALSE;
}

static int
pl_unify_perl_rv(pTHX_ term_t t, SV *rv, AV *refs, AV *cells) {
    term_t old;
    if (lookup_ref(aTHX_ &old, rv, refs, cells)) {
	return PL_unify(t, old);
    }

    SvREFCNT_inc(rv);
    av_push(refs, rv);
    av_push(cells, newSViv(PL_copy_term_ref(t)));
    if(sv_isobject(rv)) {
	return pl_unify_perl_object(aTHX_ t, rv, refs, cells);
    }
    else {
	SV *val=SvRV(rv);
	if(SvTYPE(val)==SVt_PVAV)
	    return pl_unify_perl_av(aTHX_ t, (AV *)val, 0, refs, cells);
	return pl_unify_perl_any_ref(aTHX_ t, rv, refs, cells);
    }
}

int
pl_unify_perl_sv(pTHX_ term_t t, SV *sv, AV *refs, AV *cells) {
    if (!SvOK(sv))
	return PL_unify_nil(t);
    if (SvROK(sv))
	return pl_unify_perl_rv(aTHX_ t, sv, refs, cells);
    SvGETMAGIC(sv);
    if (SvIOK(sv))
	return PL_unify_integer(t, SvIV(sv));
    if (SvNOK(sv))
	return PL_unify_float(t, SvNV(sv));

    {
	STRLEN len;
	char *name;
	name = SvPV(sv, len);

#ifdef REP_UTF8
	if (SvUTF8(sv))
	    return PL_unify_chars(t, PL_ATOM|REP_UTF8, len, name);
#endif
	return PL_unify_atom_nchars(t, len, name);
    }

}

int
perl2swi_module(pTHX_ SV *sv, module_t *m) {
    /* warn ("converting %_ to module\n", sv); */
    if(SvOK(sv)) {
	STRLEN len;
	char *str = SvPV(sv, len);
#ifdef REP_UTF8
	if (SvUTF8(sv)) {
	    term_t t = PL_new_term_ref();
	    if (!(PL_unify_chars(t, PL_ATOM|REP_UTF8, len, str) &&
		  PL_get_module(t, m)))
		return FALSE;
	}
	else
#endif
	{
	    atom_t name=PL_new_atom_nchars(len, str);
	    *m = PL_new_module(name);
	    PL_unregister_atom(name);
	}
    }
    else {
	*m=0;
    }
    return TRUE;
}

int
perl2swi_new_atom(pTHX_ SV *sv, atom_t *a) {
    STRLEN len;
    char *str;
    str = SvPV(sv, len);
#ifdef REP_UTF8
    if (SvUTF8(sv)) {
	term_t t = PL_new_term_ref();
	if (!(PL_unify_chars(t, PL_ATOM|REP_UTF8, len, str) &&
	      PL_get_atom(t, a)))
	    return FALSE;
	PL_register_atom(*a);
    }
    else
#endif
    {
	*a = PL_new_atom_nchars(len, str);
    }
    return TRUE;
}
