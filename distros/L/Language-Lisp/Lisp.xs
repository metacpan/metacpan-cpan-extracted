#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdarg.h>

#if defined(WIN32)
#      define EXP __declspec(dllexport)
#else
#      define EXP
#endif

/* Global Data */

#define MY_CXT_KEY "Language::Lisp::_guts" XS_VERSION

typedef struct {
    /* Put Global Data in here */
    int dummy;		/* you can access this elsewhere as MY_CXT.dummy */
} my_cxt_t;

START_MY_CXT

EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);

typedef SV* (*lispfunc) (char *s);
lispfunc f_lisp_eval = 0;

EXP void lisp_init(lispfunc ff)
{
    f_lisp_eval = ff;
}

EXP int ttst () {
    /* simple checker function to be sure lisp dynaload actually work */
    return 42;
}

void
create_lisp_on_sv(SV *rsv, char *pkg_name, char *lisp_name)
{
    char classname[200];
    SV *sv = SvRV(rsv);
    HV *phv;
    sv_setpv(sv,lisp_name);
    if (strchr(pkg_name,':')!=0)
	strcpy(classname,pkg_name); // if full name given, use it
    else
	sprintf(classname, "Language::Lisp::%s::",pkg_name); // otherwise ...
    phv = get_hv(classname,TRUE);
    sv_bless(rsv,phv);
}

EXP SV*
create_lisp_sv(char *pkg_name, char *lisp_name)
{
    SV *sv = newSVpv(lisp_name,strlen(lisp_name));
    SV *rsv = newRV_noinc(sv); // after this sv will have refcnt 1 (fortunately)
    create_lisp_on_sv(rsv, pkg_name, lisp_name);
    if (!f_lisp_eval) {croak("can't work w/o f_lisp_eval ");}
    return rsv;
}

EXP SV* eval_wrapper(SV *code)
{
    dTHX; /* fetch context */
    dSP;
    I32 count, i;
    SV *sv;
    SV *rc = &PL_sv_undef;

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    PUTBACK;
    count = perl_eval_sv(code, G_EVAL|G_ARRAY);
	fprintf(stderr,"count=%d;\n",count);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
	/* signal error... */
	fprintf(stderr,"err in eval!\n");
	POPs; /* pop the undef off the stack */
    }
    else {
	AV *av = newAV();
	av_extend(av,count);
	for (i = 0; i < count; i++) {
	    sv = POPs; /* pop value off the stack */
	    SvREFCNT_inc(sv);  /*this makes leakage???*/
	    av_store(av, count-i-1, sv);
	}
	//rc = sv_bless(newRV_noinc((SV *) av), gv_stashpv("Language::Lisp::List", 1));
	rc = av;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
    return rc;
}

EXP SV* call_wrapper_varg(SV *fun, SV *args, ...)
{
    va_list ap;
    dTHX; /* fetch context */
    dSP;
    I32 count, i=0;
    SV *sv;
    SV *rc = &PL_sv_undef;

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    va_start(ap, args);
    while (args != 0) {
	PUSHs(args);
        args = va_arg(ap, SV *);
    }
    va_end(ap);

    PUTBACK;
    count = perl_call_sv(fun, G_EVAL|G_ARRAY);
	fprintf(stderr,"(call)count=%d;\n",count);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
	/* signal error... */
	fprintf(stderr,"(call)err in eval!\n");
	POPs; /* pop the undef off the stack */
    }
    else {
	AV *av = newAV();
	//av_extend(av,count);
	for (i = 0; i < count; i++) {
	    sv = POPs; /* pop value off the stack */
	    SvREFCNT_inc(sv);  /*this makes leakage???*/
	    av_store(av, count-i-1, sv);
	}
	//rc = sv_bless(newRV_noinc((SV *) av), gv_stashpv("Language::Lisp::List", 1));
	rc = av;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
    return rc;
}
EXP SV* call_wrapper(SV *fun, AV *args)
{
    dTHX; /* fetch context */
    dSP;
    I32 count, i=0;
    SV *sv, **ssv;
    SV *rc = &PL_sv_undef;

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    count = av_len(args);
    for (i=0; i< count; i++) {
	ssv = av_fetch(args,i,0);
	PUSHs(*ssv);
    }
    PUTBACK;
    count = perl_call_sv(fun, G_EVAL|G_ARRAY);
	fprintf(stderr,"(call)count=%d;\n",count);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
	/* signal error... */
	fprintf(stderr,"(call)err in eval!\n");
	POPs; /* pop the undef off the stack */
    }
    else {
	AV *av = newAV();
	//av_extend(av,count);
	for (i = 0; i < count; i++) {
	    sv = POPs; /* pop value off the stack */
	    SvREFCNT_inc(sv);  /*this makes leakage???*/
	    av_store(av, count-i-1, sv);
	}
	//rc = sv_bless(newRV_noinc((SV *) av), gv_stashpv("Language::Lisp::List", 1));
	rc = av;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
    return rc;
}

XS(language_lisp_eval)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Language::Lisp::eval(sv)");
    {
	SV *sv = ST(0);
	SV *RETVAL, *res;
        char *str = SvPV_nolen(sv);
	if (!f_lisp_eval) {
	    Perl_croak(aTHX_ "please init lisp callback first!\n");
	}
	else {
            res = (*f_lisp_eval)(str);
	    /*
	    printf("res(lisp) = %08X; svpv=%s;\n",res,SvPV_nolen(res));
            RETVAL = newSVsv(res);
	    ST(0) = RETVAL;
	    */
	    ST(0) = res;
            sv_2mortal(ST(0));
        }
    }
    XSRETURN(1);
}

XS(language_lisp_symbol)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Language::Lisp::create_symbol(sv)");
    {
	SV *sv = ST(0);
	SV *RETVAL, *res;
        char *str = SvPV_nolen(sv);
	if (!f_lisp_eval) {
	    Perl_croak(aTHX_ "please init lisp callback first!\n");
	}
	else {
            res = create_lisp_sv("Symbol",str);
	    /*
	    printf("res(lisp) = %08X; svpv=%s;\n",res,SvPV_nolen(res));
            RETVAL = newSVsv(res);
	    ST(0) = RETVAL;
	    */
	    ST(0) = res;
            sv_2mortal(ST(0));
        }
    }
    XSRETURN(1);
}

EXP void
xs_init()
{
       char *file = __FILE__;
       /* DynaLoader is a special case */
       newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);

       /* also declare lisp<->connector function(s) */
       newXS("Language::Lisp::eval", language_lisp_eval, file);
       newXS("Language::Lisp::create_symbol", language_lisp_symbol, file);
}



MODULE = Language::Lisp		PACKAGE = Language::Lisp		


BOOT:
{
    MY_CXT_INIT;
    /* If any of the fields in the my_cxt_t struct need
       to be initialised, do it here.
     */
    /* where is dynaloader - in shared library of entire perl? */
    /*newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, __FILE__);*/
}

