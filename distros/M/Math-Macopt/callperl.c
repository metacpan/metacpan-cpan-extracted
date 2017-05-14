#include "callperl.h"

// PerlInterpreter *my_perl;

AV* interactPerl(SV* callback, AV* args)
{		
	int i;
	
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(sp);
	
	/* push args here */
	if (args != NULL) {
		for(i=0; i<=av_len(args); i++) {
			SV** argRef = av_fetch(args, i, 0);
			if (argRef != NULL) {	
				XPUSHs(*argRef);
//				XPUSHs(sv_mortalcopy(*argRef));
			}
		}
	}
	PUTBACK;
	
	// Call the perl method
	int outputNum = 0;
	outputNum = call_sv((SV*) callback, G_ARRAY);
//	outputNum = call_pv(sub, G_ARRAY);
	SPAGAIN;

	/* get returns here */
	AV* returns = newAV();
	av_clear(returns);
	av_fill(returns, outputNum);

	for (i=outputNum-1; i>=0; i--) {
		av_store(returns, i, newSVsv(POPs));
	}
	
	PUTBACK;
	FREETMPS;
	LEAVE;	
	
	return returns;
}

