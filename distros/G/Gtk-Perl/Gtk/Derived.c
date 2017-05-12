#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* The contents of this file are directly derived from universal.c in
   Perl 5.005, and are specifically under Perl's copyright. */

#if defined(LAZY_LOAD) || defined(NEED_DERIVED)

#include "ppport.h"

/*
 * Contributed by Graham Barr  <Graham.Barr@tiuk.ti.com>
 * The main guts of traverse_isa was actually copied from gv_fetchmeth
 */

static SV *
isa_lookup(HV *stash, char *name, int len, int level)
{
    AV* av;
    GV* gv;
    GV** gvp;
    HV* hv = Nullhv;

    if (!stash)
	return &PL_sv_undef;

    if(strEQ(HvNAME(stash), name))
	return &PL_sv_yes;

    if (level > 100)
	croak("Recursive inheritance detected in package '%s'", HvNAME(stash));

    gvp = (GV**)hv_fetch(stash, "::ISA::CACHE::", 14, FALSE);

    if (gvp && (gv = *gvp) != (GV*)&PL_sv_undef && (hv = GvHV(gv))) {
	SV* sv;
	SV** svp = (SV**)hv_fetch(hv, name, len, FALSE);
	if (svp && (sv = *svp) != (SV*)&PL_sv_undef)
	    return sv;
    }

    gvp = (GV**)hv_fetch(stash,"ISA",3,FALSE);
    
    if (gvp && (gv = *gvp) != (GV*)&PL_sv_undef && (av = GvAV(gv))) {
	if(!hv) {
	    gvp = (GV**)hv_fetch(stash, "::ISA::CACHE::", 14, TRUE);

	    gv = *gvp;

	    if (SvTYPE(gv) != SVt_PVGV)
		gv_init(gv, stash, "::ISA::CACHE::", 14, TRUE);

	    hv = GvHVn(gv);
	}
	if(hv) {
	    SV** svp = AvARRAY(av);
	    /* NOTE: No support for tied ISA */
	    I32 items = av_len(av) + 1;
	    while (items--) {
		SV* sv = *svp++;
		HV* basestash = gv_stashsv(sv, FALSE);
		if (!basestash) {
		    /*dTHR;
		    if (ckWARN(WARN_MISC))
			warner(WARN_SYNTAX,
		             "Can't locate package %s for @%s::ISA",
			    SvPVX(sv), HvNAME(stash));*/
			warn("Can't locate package %s for @%s::ISA",
			    SvPVX(sv), HvNAME(stash));
			    
		    continue;
		}
		if(&PL_sv_yes == isa_lookup(basestash, name, len, level + 1)) {
		    (void)hv_store(hv,name,len,&PL_sv_yes,0);
		    return &PL_sv_yes;
		}
	    }
	    (void)hv_store(hv,name,len,&PL_sv_no,0);
	}
    }

#ifdef LAZY_LOAD
    gvp = (GV**)hv_fetch(stash,"_ISA",4,FALSE);
    
    if (gvp && (gv = *gvp) != (GV*)&PL_sv_undef && (av = GvAV(gv))) {
	if(!hv) {
	    gvp = (GV**)hv_fetch(stash, "::ISA::CACHE::", 14, TRUE);

	    gv = *gvp;

	    if (SvTYPE(gv) != SVt_PVGV)
		gv_init(gv, stash, "::ISA::CACHE::", 14, TRUE);

	    hv = GvHVn(gv);
	}
	if(hv) {
	    SV** svp = AvARRAY(av);
	    /* NOTE: No support for tied _ISA */
	    I32 items = av_len(av) + 1;
	    while (items--) {
		SV* sv = *svp++;
		HV* basestash = gv_stashsv(sv, FALSE);
		if (!basestash) {
		    /*dTHR;
		    if (ckWARN(WARN_MISC))
			warner(WARN_SYNTAX,
		             "Can't locate package %s for @%s::_ISA",
			    SvPVX(sv), HvNAME(stash));*/
			warn("Can't locate package %s for @%s::_ISA",
			    SvPVX(sv), HvNAME(stash));
		    continue;
		}
		if(&PL_sv_yes == isa_lookup(basestash, name, len, level + 1)) {
		    (void)hv_store(hv,name,len,&PL_sv_yes,0);
		    return &PL_sv_yes;
		}
	    }
	    (void)hv_store(hv,name,len,&PL_sv_no,0);
	}
    }
#endif

    return boolSV(strEQ(name, "UNIVERSAL"));
}

bool
PerlGtk_sv_derived_from(SV *sv, char *name)
{
    SV *rv;
    char *type;
    HV *stash;
  
    stash = Nullhv;
    type = Nullch;
 
    if (SvGMAGICAL(sv))
        mg_get(sv) ;

    if (SvROK(sv)) {
        sv = SvRV(sv);
        type = sv_reftype(sv,0);
        if(SvOBJECT(sv))
            stash = SvSTASH(sv);
    }
    else {
        stash = gv_stashsv(sv, FALSE);
    }
 
    return (type && strEQ(type,name)) ||
            (stash && isa_lookup(stash, name, strlen(name), 0) == &PL_sv_yes)
        ? TRUE
        : FALSE ;
 
}

#endif
