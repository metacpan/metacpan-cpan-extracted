#include <cinterf.h>

#define TYPEPKG "Language::Prolog::Types"
#define TYPEINTPKG TYPEPKG "::Internal"

#define PKG "Language::XSB::Base"
static SV *converter;

/* prototypes */
static SV *term2sv(prolog_term t);
static void perl2p_sv(SV *sv, prolog_term t, AV *refs, AV *cells);

/* some functions to easily call simple methods on Perl refs: */
static SV *call_method__sv(SV *object, char *method) {
  dSP;
  SV *result;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(object);
  PUTBACK;
  call_method(method, G_SCALAR);
  SPAGAIN;
  result=POPs;
  SvREFCNT_inc(result);
  PUTBACK;
  FREETMPS;
  LEAVE;
  return sv_2mortal(result);
}

static int call_method__int(SV *object, char *method) {
  dSP;
  int result;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(object);
  PUTBACK;
  call_method(method, G_SCALAR);
  SPAGAIN;
  result=POPi;
  PUTBACK;
  FREETMPS;
  LEAVE;
  return result;
}

static SV *call_method_int__sv(SV *object, char *method, int i) {
  dSP;
  SV *result;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(object);
  XPUSHs(sv_2mortal(newSViv(i)));
  PUTBACK;
  call_method(method, G_SCALAR);
  SPAGAIN;
  result=POPs;
  SvREFCNT_inc(result);
  PUTBACK;
  FREETMPS;
  LEAVE;
  return sv_2mortal(result);
}

static SV *call_method_sv__sv(SV *object, char *method, SV *arg) {
  dSP;
  SV *result;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(object);
  XPUSHs(arg);
  PUTBACK;
  call_method(method, G_SCALAR);
  SPAGAIN;
  result=POPs;
  SvREFCNT_inc(result);
  PUTBACK;
  FREETMPS;
  LEAVE;
  return sv_2mortal(result);
}

static int regtype(int index) {
    prolog_term t=reg_term(index);
    if (is_int(t)) return 2;
    if (is_string(t)) return 3;
    if (is_float(t)) return 4;
    if (is_list(t)) return 5;
    if (is_nil(t)) return 6;
    if (is_functor(t)) return 7;
    if (is_var(t)) return 1;
    return 0;
}

static SV *term2sv(prolog_term t) {
    /* fprintf(stderr, "term \%u: ", t); */
    /* printterm(stderr, t, 100); */
    /* fprintf(stderr, "\n"); */
    if (is_int(t))
	return newSViv(p2c_int(t));
    if (is_string(t))
	return newSVpv(p2c_string(t),0);
    if (is_float(t))
	return newSVnv(p2c_float(t));
    if (is_nil(t)) {
      AV *array=newAV();
      SV *ref=newRV_noinc((SV *)array);
      sv_bless(ref, gv_stashpv(TYPEINTPKG "::nil",1));
      return ref;
    }
    if (is_list(t)) {
	AV *array=newAV();
	SV *ref=newRV_noinc((SV *)array);
	while(is_list(t)) {
	    av_push(array, term2sv(p2p_car(t)));
	    t=p2p_cdr(t);
	}
	if(is_nil(t)) {
	    sv_bless(ref, gv_stashpv(TYPEINTPKG "::list",1));
	}
	else {
	    av_push(array, term2sv(t));
	    sv_bless(ref, gv_stashpv(TYPEINTPKG "::ulist",1));
	}
	return ref;
    }
    if (is_functor(t)) {
	int arity=p2c_arity(t);
	int i;
	AV *functor=newAV();
	SV *ref=newRV_noinc((SV*)functor);
	sv_bless(ref, gv_stashpv(TYPEINTPKG "::functor",1));
	av_extend(functor,arity+1);
	av_store(functor,0,newSVpv(p2c_functor(t),0));
	for(i=1; i<=arity; i++)
	    av_store(functor,i,term2sv(p2p_arg(t,i)));
	return ref;
    }
    if (is_var(t)) {
	SV *var=newSVuv(t);
	SV *ref=newRV_noinc(var);
	/* SV *ref=newRV_noinc(term2sv(p2p_deref(t))); */
	sv_bless(ref, gv_stashpv(TYPEINTPKG "::variable",1));
	return ref;
    }
    if(1) {
	SV *var=newSVuv(t);
	SV *ref=newRV_noinc(var);
	warn ("unknow type for XSB term \%u", t);
	sv_bless(ref, gv_stashpv(TYPEINTPKG "::unknow",1));
	return ref;
    }
    
    die("unknow/unsupported term type");
    return NULL;
}

static int remap_result(int result, char *sub_name) {
    if (result==0) return 1;
    if (result==1) return 0;
    die ("\%s failed with error \%d", sub_name, result);
}

static SV *my_fetch (AV *av, int i) {
    SV **sv_p=av_fetch(av, i, 0);
    return (sv_p ? *sv_p : &PL_sv_undef);
}

static void perl2p_ifunctor(SV *o, prolog_term t, AV *refs, AV *cells) {
    if(SvTYPE(o)==SVt_PVAV) {
	AV *array=(AV *)o;
	int arity=av_len(array);
	int i;
	/* fprintf(stderr, "creating functor arity %d\n", arity); */
	if(!c2p_functor(SvPV_nolen(my_fetch(array,0)), arity, t))
	    die("unable to convert functor to XSB");
	for(i=1;i<=arity;i++)
	    perl2p_sv(my_fetch(array, i), p2p_arg(t,i), refs, cells);
    }
    else 
	die ("implementation mismatch, " TYPEINTPKG "::functor object is not an array ref");
}

static void perl2p_array(AV *array, int u,
				prolog_term list, AV *refs, AV *cells) {
    int i;
    int len=av_len(array);
    if(u) {
	if (len<0)
	    die ("implementation mismatch, " TYPEINTPKG "::ulist object is an array with less than one element\n");
	--len;
    }
    for(i=0; i<=len; i++, list=p2p_cdr(list)) {
	if(!c2p_list(list))
	    die ("internal error, unable to create XSB list\n");
	perl2p_sv(my_fetch(array, i), p2p_car(list), refs, cells);
    }
    if(u) {
	/* warn ("setting tail, index: %d, tail: %s, term: %x type: %d",
	      i, SvPV_nolen(my_fetch(array, i)), list, regtype(list)); */
	perl2p_sv(my_fetch(array, i), list, refs, cells);
    }
    else
	if(!c2p_nil(list))
	    die ("internal error, unable to create XSB list tail\n");
}

static void perl2p_nil(prolog_term t, AV *refs, AV *cells) {
    if(!c2p_nil(t))
	die ("internal error, unable to create XSB nil\n");
}

static void perl2p_ilist(SV *o, prolog_term t, AV *refs, AV *cells) {
    if(SvTYPE(o)==SVt_PVAV)
	perl2p_array((AV *)o, 0, t, refs, cells);
    else
	die ("implementation mismatch, " TYPEINTPKG "::list object is not an array ref");
}

static void perl2p_iulist(SV *o, prolog_term t, AV *refs, AV *cells) {
    if(SvTYPE(o)==SVt_PVAV)
	perl2p_array((AV *)o, 1, t, refs, cells);
    else
	die ("implementation mismatch, " TYPEINTPKG "::ulist object is not an array ref");
}

static void perl2p_list(SV *o, prolog_term list, AV *refs, AV *cells) {
    dSP;
    int i;
    int len;
    SV *el;
    ENTER;
    SAVETMPS;
    len=call_method__int(o, "length");
    for (i=0; i<len; i++, list=p2p_cdr(list)) {
	if(!c2p_list(list))
	    die ("internal error, unable to create XSB list\n");
	ENTER;
	SAVETMPS;
	perl2p_sv( call_method_int__sv(o, "larg", i),
		   p2p_car(list), refs, cells );
	FREETMPS;
	LEAVE;
    }

    perl2p_sv( call_method__sv(o, "tail"),
	       list, refs, cells );
    FREETMPS;
    LEAVE;
}

static void perl2p_functor(SV *o, prolog_term functor, AV *refs, AV *cells) {
    dSP;
    int i;
    SV *name;
    int arity;
    ENTER;
    SAVETMPS;
    name=call_method__sv(o, "functor");
    arity=call_method__int(o, "arity");
    if(!c2p_functor(SvPV_nolen(name), arity, functor))
	die("internal error, unable to create XSB %s/%d functor",
	    SvPV_nolen(name), arity);
    /* SvREFCNT_dec(name); */
    for(i=0; i<arity; i++) {
	ENTER;
	SAVETMPS;
	perl2p_sv(call_method_int__sv(o, "farg", i),
		  p2p_arg(functor, i), refs, cells);
	FREETMPS;
	LEAVE;
    }
    FREETMPS;
    LEAVE;
}


static void perl2p_any_ref(SV *ref, prolog_term t, AV *refs, AV *cells) {
    /* warn ("Converting Perl ref -> XSB term\n"); */
    perl2p_sv( call_method_sv__sv(converter, "perl_ref2prolog", ref),
	       t, refs, cells);
}

static void perl2p_object(SV *sv, prolog_term t, AV *refs, AV *cells) {
    if (sv_derived_from(sv, TYPEPKG "::Term")) {	    
	if (sv_isa(sv,TYPEINTPKG "::list")) {
	    perl2p_ilist(SvRV(sv), t, refs, cells);
	}
	else if(sv_isa(sv, TYPEINTPKG "::ulist")) {
	    perl2p_iulist(SvRV(sv), t, refs, cells);
	}
	else if (sv_isa(sv, TYPEINTPKG "::functor")) {
	    perl2p_ifunctor(SvRV(sv), t, refs, cells);
	}
	else if (sv_isa(sv, TYPEINTPKG "::nil")) {
	    perl2p_nil(t, refs, cells);
	}
	else if (sv_derived_from(sv, TYPEPKG "::UList")) {
	    perl2p_list(sv, t, refs, cells);
	}
	else if (sv_derived_from(sv, TYPEPKG "::List")) {
	    perl2p_list(sv, t, refs, cells);
	}
	else if (sv_derived_from(sv, TYPEPKG "::Functor")) {
	    perl2p_functor(sv, t, refs, cells);
	}
	else if (sv_derived_from(sv, TYPEPKG "::Nil")) {
	    perl2p_nil(t, refs, cells);
	}
	else {
	    warn ("unable to convert "TYPEPKG"::Term object '%s' to XSB term",
		  SvPV_nolen(sv));
	    perl2p_any_ref(sv, t, refs, cells);
	}
    }
    else
	perl2p_any_ref(sv, t, refs, cells);
}

int lookup_ref(SV *sv, prolog_term t, AV *refs, AV *cells) {
    int i;
    int len=av_len(refs);
    if(sv_isobject(sv) && sv_derived_from(sv, TYPEPKG "::Variable")) {
	/* variables are the same if they have the same name, even if
	 * they have different references */
	dSP;
	SV *name;
	ENTER;
	SAVETMPS;
	name=call_method__sv(sv, "name");
	for (i=0; i<=len; i++) {
	    SV *ref=my_fetch(refs, i);
	    if ( sv_isobject(ref) &&
		 sv_derived_from(ref, TYPEPKG "::Variable") &&
		 !sv_cmp(name, call_method__sv(ref, "name"))) {
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
	    if(!ref_p)
		die ("internal error, unable to fetch reference pointer from references cache");
	    if (new_ref==SvRV(*ref_p))
		break;
	}
    }
    if (i<=len) {
	SV **cell_p=av_fetch(cells, i, 0);
	if(!cell_p || *cell_p==&PL_sv_undef) {
	    warn ("cycled reference passed to XSB as nil\n");
	    perl2p_nil(t, refs, cells);
	    return 1;
	}
	if(!p2p_unify(t, SvIV(*cell_p)))
	    die ("internal error, unable to unify multiple instances of Perl object '%s'",
		 SvPV_nolen(sv));
	return 1;
    }
    return 0;
}

static void perl2p_rv(SV *sv, prolog_term t, AV *refs, AV *cells) {
    if (!lookup_ref(sv, t, refs, cells)) {
	/* store object reference in cache */
	SV *cell;
	int cell_index;
	SvREFCNT_inc(sv);
	av_push(refs, sv);
	cell_index=av_len(refs);
	if(sv_isobject(sv)) {
	    /* if it is a variable we have to do nothing */
	    if(!sv_derived_from(sv, TYPEPKG "::Variable"))
		perl2p_object(sv, t, refs, cells);
	}
	else {
	    SV *val=SvRV(sv);
	    if(SvTYPE(val)==SVt_PVAV)
		perl2p_array((AV *)val, 0, t, refs, cells);
	    else
		perl2p_any_ref(sv, t, refs, cells);
	}
	/* store term in cache */
	cell=newSViv(t);
	SvREADONLY_on(cell);
	if(!av_store(cells, cell_index, cell)) {
	    die("unable to store cell in cell cache\n");
	}
    }
}

static void perl2p_sv(SV *sv, prolog_term t, AV *refs, AV *cells) {
    if (!is_var(t))
	die ("unable to convert perl value to XSB, term is not a free variable");

    if (!SvOK(sv)) {
	if(!c2p_nil(t))
	    die ("unable to convert undef to XSB nil term");
    }
    else if (SvIOK(sv)) {
	if (!c2p_int(SvIV(sv),t))
	    die ("unable to convert integer to XSB term");
    }
    else if (SvNOK(sv)) {
	if(!c2p_float(SvNV(sv),t))
	    die ("unable to convert float to XSB term");
    }
    else if (SvPOK(sv)) {
	if (!c2p_string(SvPV_nolen(sv),t))
	    die ("unable to convert string to XSB term");
    }
    else if (SvROK(sv)) {
	perl2p_rv(sv, t, refs, cells);

    }
    else {
	warn ("unable to convert unknow type '%s' to XSB term", SvPV_nolen(sv));
	perl2p_any_ref(sv, t, refs, cells);
    }
}

static SV *setreg(int index, SV *pt) {
    dSP;
    AV *refs, *cells;
    SV *ref;
    prolog_term t;
    t=reg_term(index);
    if(!is_var(t))
	die ("unable to set register %d, it isn't a free variable\n", index);
    ENTER;
    SAVETMPS;
    perl2p_sv( pt, t,
	       refs=(AV *)sv_2mortal((SV *)newAV()),
	       (AV *)sv_2mortal((SV *)newAV()));
    ref=newRV_inc((SV *)refs);
    FREETMPS;
    LEAVE;
    sv_bless(ref, gv_stashpv(TYPEINTPKG "::list",1));
    return ref;

}

static void *setreg_int(int index, int value) {
    prolog_term t=reg_term(index);
    if(!is_var(t))
	die ("unable to set register %d, it isn't a free variable\n", index);
    if(!c2p_int(value, t)) {
	die ("conversion from int to XSB term failed\n");
    }
}

SV *getreg_int(int index) {
    prolog_term t=reg_term(index);
    if(!is_int(t))
	return &PL_sv_undef;
    return newSViv(p2c_int(t));
}
