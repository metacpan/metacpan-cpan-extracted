#define  PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <SWI-Prolog.h>

#include "Low.h"
#include "opaque.h"
#include "callback.h"
#include "hook.h"

PL_agc_hook_t old_agc_hook=NULL;
int hook_set=0;


static int my_agc_hook(atom_t a) {
    if(!strcmp(OPAQUE_FUNCTOR, PL_atom_chars(a))) {
        const char *oname;
        size_t olen;
	dTHX;
	dSP;
	ENTER;
	SAVETMPS;
        oname = PL_atom_nchars(a, &olen);
	call_sub_sv__sv(aTHX_
			PKG "::unregister_opaque",
			sv_2mortal(newSVpv(oname, olen)));
	FREETMPS;
	LEAVE;
    }
    
    if (old_agc_hook) {
	return (*old_agc_hook)(a);
    }
    return TRUE;
}

void set_my_agc_hook(void) {
    hook_set=1;
    old_agc_hook=PL_agc_hook(my_agc_hook);
}

