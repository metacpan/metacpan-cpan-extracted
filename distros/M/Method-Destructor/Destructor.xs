#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"
#define NEED_mro_get_linear_isa
#include "mro_compat.h"
#include "mgx.h"

#ifndef GvSVn
#define GvSVn(gv) GvSV(gv)
#endif

#define DEMOLISH "DEMOLISH"

#define in_global_destruction() (PL_dirty)

MGVTBL md_meta_vtbl;

enum md_flags{
	MDf_NONE       = 0x00,
	MDf_SKIP_DIRTY = 0x01
};

static void
md_call_demolishall(pTHX_ SV* const self, AV* const demolishall){
	SV**       svp = AvARRAY(demolishall);
	SV** const end = svp + AvFILLp(demolishall) + 1;

	while(svp != end){
		GV* const demolishgv = (GV*)*svp;
		SV* const sv         = GvSV(demolishgv);
		IV  const flags      = (sv && SvIOK(sv)) ? SvIVX(sv) : MDf_NONE;

		if(!( (flags & MDf_SKIP_DIRTY) && in_global_destruction() )){
			dSP;

			PUSHMARK(SP);
			XPUSHs(self);
			PUTBACK;

			/*
			   NOTE: changes PL_stack_sp directly, instead of using G_DISCARD.
			*/
			PL_stack_sp -= call_sv((SV*)GvCV(demolishgv), G_VOID);
		}

		svp++;
	}
}

XS(XS_Method__Destructor_DESTROY);

MODULE = Method::Destructor	PACKAGE = Method::Destructor

PROTOTYPES: DISABLE

void
import(SV* klass, ...)
PREINIT:
	int i;
CODE:
	for(i = 1; i < items; i++){
		SV* const option = ST(i);
		if(strEQ(SvPV_nolen_const(option), "-optional")){
			GV* const gv = (GV*)*hv_fetchs(PL_curstash, DEMOLISH, TRUE);
			SV* flags;

			if(!isGV(gv)){
				gv_init(gv, PL_curstash, DEMOLISH, sizeof(DEMOLISH)-1, GV_ADDMULTI);
			}
			flags = GvSVn(gv);

			/* $flags |= MDf_SKIP_DIRTY */
			sv_setiv(flags, (SvIOK(flags) ? SvIVX(flags) : MDf_NONE) | MDf_SKIP_DIRTY);
		}
		else{
			Perl_croak(aTHX_ "Invalid option '%"SVf"' for %"SVf, option, klass);
		}
	}
	newXS("DESTROY", XS_Method__Destructor_DESTROY, __FILE__);

void
DESTROY(SV* self)
PREINIT:
	HV* stash;
	MAGIC* meta_mg;
	AV* demolishall;
	U16 generation;
CODE:
	if(!( SvROK(self) && (stash = SvSTASH(SvRV(self))) )){
		Perl_croak(aTHX_ "Invalid call of DESTROY");
	}

	meta_mg = MgFind((SV*)stash, &md_meta_vtbl);

	if(!meta_mg){
		demolishall = newAV();
		generation  = 0;
		meta_mg     = sv_magicext((SV*)stash, (SV*)demolishall, PERL_MAGIC_ext, &md_meta_vtbl, NULL, 0);
		SvREFCNT_dec(demolishall); /* refcnt++ in sv_magicext() */
	}
	else{
		demolishall = (AV*)meta_mg->mg_obj;
		generation  = meta_mg->mg_private;
	}

	if(generation != (U16)mro_get_gen(stash)){
		AV*  const isa = mro_get_linear_isa(stash);
		SV**       svp = AvARRAY(isa);
		SV** const end = svp + AvFILLp(isa) + 1;

		if(AvFILLp(demolishall) > -1){
			av_clear(demolishall);
		}

		while(svp != end){
			HV*  const st  = gv_stashsv(*svp, TRUE);
			GV** const gvp = (GV**)hv_fetchs(st, DEMOLISH, FALSE);

			if(gvp && isGV(*gvp) && GvCVu(*gvp)){
				av_push(demolishall, (SV*)*gvp);
				SvREFCNT_inc_simple_void_NN(*gvp);
			}

			svp++;
		}

		meta_mg->mg_private = (U16)mro_get_gen(stash);
	}

	if(AvFILLp(demolishall) > -1){
		md_call_demolishall(aTHX_ self, demolishall);
	}
