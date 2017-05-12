#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <SWI-Prolog.h>

#include "context.h"

#include "argv.h"
#include "engines.h"

void check_prolog(pTHX_ pMY_CXT) {
    if (!c_prolog_ok) {
	if(!PL_is_initialised(NULL, NULL)) {
	    args2argv();
	    if(!PL_initialise(PL_argc, PL_argv)) {
		die ("unable to start prolog engine");
	    }
	    push_frame(aTHX_ aMY_CXT);
	    c_prolog_init=1;
	}
#ifdef MULTIPLICITY
	if(PL_thread_self()==-1) {
	    if(PL_thread_attach_engine(NULL)==-1) {
		die ("unable to create prolog thread engine");
	    }
	    push_frame(aTHX_ aMY_CXT);
	    c_prolog_init=1;
	}
#endif
	c_prolog_ok=1;
    }
}

void release_prolog(pTHX_ pMY_CXT) {
    if (c_prolog_ok && c_prolog_init) {
#ifdef MULTIPLICITY
	/* warn ("destroying Prolog engine"); */
	PL_thread_destroy_engine();
#else
	warn ("Prolog cleanup");
	PL_cleanup(0);
#endif
	c_prolog_init=0;
	c_prolog_ok=0;
    }
}


#ifdef MULTIPLICITY

static char *pargs[]={ "", "-e", "require Language::Prolog::Yaswi::Low", };

EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);

EXTERN_C void xs_init(pTHX)
{
    char *file = __FILE__;
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}

void clear_perl(void *nothing) {
    dTHX;
    /* warn ("destroying perl engine %x", my_perl); */
    perl_destruct(my_perl);
    perl_free(my_perl);
    PERL_SET_CONTEXT(NULL);
}

void *my_Perl_get_context(void) {
    PerlInterpreter *my_perl=Perl_get_context();
    if (!my_perl) {
	my_perl=perl_alloc();
	PERL_SET_CONTEXT(my_perl);
	perl_construct(my_perl);
	perl_parse(my_perl, xs_init, 3, pargs, NULL);
	PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
	perl_run(my_perl);
	PL_thread_at_exit(clear_perl, NULL, 0);
	/* warn ("new perl interpreter created %x (thread=%i)",
	      my_perl,
	      PL_thread_self()); */
    }
    return my_perl;
}

#endif
