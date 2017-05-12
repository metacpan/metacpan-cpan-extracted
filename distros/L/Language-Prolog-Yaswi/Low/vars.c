#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <SWI-Prolog.h>

#include "context.h"

#include "Low.h"
#include "swi2perl.h"
#include "callback.h"
#include "vars.h"


AV *get_cells(pTHX_ pMY_CXT) {
    AV *av;
    if (av=GvAV(c_cells)) return av;
    return GvAV(c_cells)=newAV();
}

AV *get_vars(pTHX_ pMY_CXT) {
    AV *av;
    if (av=GvAV(c_vars)) return av;
    return GvAV(c_vars)=newAV();
}

HV *get_cache(pTHX_ pMY_CXT) {
    HV *hv;
    if (hv=GvHV(c_cache)) return hv;
    return GvHV(c_cache)=newHV();
}
void savestate_vars(pTHX_ pMY_CXT) {
    save_ary(c_vars);
    save_ary(c_cells);
    save_hash(c_cache);
}

void clear_vars(pTHX_ pMY_CXT) {
    av_clear(get_vars(aTHX_ aMY_CXT));
    av_clear(get_cells(aTHX_ aMY_CXT));
    hv_clear(get_cache(aTHX_ aMY_CXT));
}

void cut_anonymous_vars(pTHX_ pMY_CXT) {
    av_fill(get_cells(aTHX_ aMY_CXT),
	    av_len(get_vars(aTHX_ aMY_CXT)));
}

void set_vars(pTHX_ pMY_CXT_ AV *nrefs, AV *ncells) {
    AV *vars=get_vars(aTHX_ aMY_CXT);
    AV *cells=get_cells(aTHX_ aMY_CXT);
    HV *cache=get_cache(aTHX_ aMY_CXT);
    int i, len;
    if (av_len(vars)>=0 || av_len(cells)>=0) {
	warn ("vars/cells stack is not empty");
	av_clear(vars);
	av_clear(cells);
    }
    
    len=av_len(nrefs)+1;
    for (i=0; i<len; i++) {
	SV **var=av_fetch(nrefs, i, 0);
	if (!var) {
	    die ("corrupted refs/cells stack, ref %i is NULL", i);
	}
	if (sv_derived_from(*var, TYPEPKG "::Variable")) {
	    SV *name=call_method__sv(aTHX_ *var, "name");
	    char *cname;
	    size_t vlen;
	    cname=SvPV(name, vlen);
	    if (strNE("_", cname)) {
		SV **cell=av_fetch(ncells, i, 0);
		if (!cell) {
		    die ("corrupted refs/cells stack, cell %i is NULL", i);
		}
		SvREFCNT_inc(*cell);
		av_push(cells, *cell);
		SvREFCNT_inc(*cell);
		hv_store(cache, cname, vlen, *cell, 0);
		SvREFCNT_inc(*var);
		av_push(vars, *var);
	    }
	}
    }
}
