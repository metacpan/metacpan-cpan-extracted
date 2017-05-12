#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

#include "mro_compat.h"

#include "magic_ext.h"

#define PACKAGE "Method::Cumulative"

#define MC_BASE_FIRST(mg)           MG_private(mg)
#define MC_BASE_FIRST_on(mg) (void)(MG_private(mg) = TRUE)

#define MC_AvEXTEND(av, max) STMT_START {                   \
		if(AvMAX(av) < (max)) av_extend(av, (max)); \
	} STMT_END

enum {
	M_NAME,
	M_METHODS,
	M_GEN
};

static MGVTBL mc_vtbl;

static HV*
mc_get_stash(pTHX_ SV* const invocant){
	if(SvROK(invocant) && SvOBJECT(SvRV(invocant))){
		return SvSTASH(SvRV(invocant));
	}
	else{
		return gv_stashsv(invocant, FALSE);
	}
}

static AV*
mc_get_methods(pTHX_ CV* const cv, SV* const invocant){
	HV* const stash = mc_get_stash(aTHX_ invocant);
	MAGIC* const mg = mgx_get((SV*)cv, &mc_vtbl);
	SV* gensv;
	AV* methods;
	SV* namesv;

	if(!MG_sv(mg)){
		AV* const meta   = newAV();
		GV* const namegv = CvGV(cv);

		gensv   = newSVuv(0U);
		methods = newAV();
		namesv  = newSVpvn_share(GvNAME(namegv), GvNAMELEN(namegv), 0U);

		av_store(meta, M_GEN,     gensv);
		av_store(meta, M_METHODS, (SV*)methods);
		av_store(meta, M_NAME,    namesv);

		MG_sv_set(mg, (SV*)meta);
	}
	else{
		AV* const meta = (AV*)MG_sv(mg);
		assert(SvTYPE(meta) == SVt_PVAV);

		gensv   =      AvARRAY(meta)[M_GEN];
		methods = (AV*)AvARRAY(meta)[M_METHODS];
		namesv  =      AvARRAY(meta)[M_NAME];
	}

	if(SvUVX(gensv) != mro_get_gen(stash)){
		AV* const isa = mro_get_linear_isa(stash);
		SV** svp;
		SV** end;

		assert(SvTYPE(methods) == SVt_PVAV);

		av_clear(methods);
		MC_AvEXTEND(methods, AvFILLp(isa));

		if(MC_BASE_FIRST(mg)){
			svp = AvARRAY(isa) + AvFILLp(isa);
			end = AvARRAY(isa) -1;
		}
		else{
			svp = AvARRAY(isa);
			end = AvARRAY(isa) + AvFILLp(isa) + 1;
		}

		while(svp != end){
			HV* const st  = gv_stashsv(*svp, TRUE);
			HE* const he  = hv_fetch_ent(st, namesv, FALSE, 0U);
			if(he){
				GV* const gv = (GV*)HeVAL(he);
				if(!isGV(gv)) gv_init(gv, st, SvPVX(namesv), SvCUR(namesv), GV_ADDMULTI);

				if(GvCVu(gv)){
					MAGIC* const  mc = MGX_FIND((SV*)GvCV(gv), &mc_vtbl);
					SV* const entity = mc ? MG_obj(mc) : (SV*)GvCV(gv);

					av_store(methods, AvFILLp(methods)+1, entity);
					SvREFCNT_inc_simple_void_NN(entity);
				}
			}

			if(MC_BASE_FIRST(mg)){
				svp--;
			}
			else{
				svp++;
			}
		}

		sv_setuv(gensv, mro_get_gen(stash));
	}

	return methods;
}

static void
mc_invoke(pTHX_ SV* const entity, I32 const gimme, bool* const return_ok, I32 const argc, SV** const argv){
	dSP;
	I32 n;

	assert(MGX_FIND(entity, &mc_vtbl) == NULL);

	PUSHMARK(SP);

	EXTEND(SP, argc+1);
	Copy(argv, SP+1, (size_t)argc, SV*);
	SP += argc;

	PUTBACK;
	n = call_sv(entity, gimme);
	SPAGAIN;

	switch(gimme){
	default: /* G_VOID */
		SP -= n;
		break;
	case G_SCALAR:
		assert(n == 1);
		if(*return_ok || !SvOK(TOPs)){
			SP -= n;
		}
		else{
			*return_ok = TRUE;
		}
		break;
	case G_ARRAY:
		if(*return_ok || (n == 0)){
			SP -= n;
		}
		else{
			*return_ok = TRUE;
		}
	}
	PUTBACK;
}

XS(Method__Cumulative_dispatcher);
XS(Method__Cumulative_dispatcher){
	dVAR; dXSARGS;
	dXSTARG;
	SV** argv;

	if(items == 0){
		Perl_croak(aTHX_ "Method %s requires an invocant", GvNAME(CvGV(cv)));
	}

	/* setup argv */
	SvUPGRADE(TARG, SVt_PVAV);
	MC_AvEXTEND((AV*)TARG, items-1);
	argv = AvARRAY((AV*)TARG);

	MARK++;
	Copy(MARK, argv, (size_t)items, SV*);

	SP -= items;
	PUTBACK;

	{
		AV* const methods  = mc_get_methods(aTHX_ cv, *MARK);
		SV**       svp     = AvARRAY(methods);
		SV** const end     = svp + AvFILLp(methods) + 1;
		I32 const gimme    = GIMME_V;
		bool return_ok     = FALSE;

		while(svp != end){
			mc_invoke(aTHX_ *svp, gimme, &return_ok, items, argv);
			svp++;
		}

	}

	return;
}


static void
mc_check_consistancy(pTHX_ HV* const stash, MAGIC* const mg, GV* const gv){
	AV* const isa = mro_get_linear_isa(stash);
	I32 const len = AvFILLp(isa)+1;
	I32 i;

	for(i = 0; i < len; i++){
		HV*  const st  = gv_stashsv(AvARRAY(isa)[i], TRUE);
		SV** const svp = hv_fetch(st, GvNAME(gv), GvNAMELEN(gv), FALSE);
		GV* meth;

		if(svp && (meth = (GV*)*svp) && isGV(meth) && GvCVu(meth)){
			MAGIC* const mc = MGX_FIND((SV*)GvCV(meth), &mc_vtbl);

			if(mc && MC_BASE_FIRST(mg) != MC_BASE_FIRST(mc)){
				Perl_warner(aTHX_ packWARN(WARN_SYNTAX),
					"Conflicting definitions for cumulative method %s::%s",
					HvNAME(GvSTASH(gv)), GvNAME(gv)
				);
			}
		}
	}
}

MODULE = Method::Cumulative	PACKAGE = Method::Cumulative

PROTOTYPES: DISABLE

void
CUMULATIVE(SV* klass, SV* symref, CV* code, attr_name, SV* attr_data)
ATTRS: ATTR_SUB
PREINIT:
	GV* gv;
	CV* xsub;
	MAGIC* mg;
CODE:
	if(!(SvROK(symref) && isGV(SvRV(symref)))){
		Perl_croak(aTHX_ "Can't make anonymous subroutine cumulative");
	}
	
	gv = (GV*)SvRV(symref);
	/* redefine */
	SvREFCNT_dec(GvCV(gv));
	GvCV(gv) = NULL;
	xsub = newXS(
		Perl_form(aTHX_ "%s::%s", HvNAME(GvSTASH(gv)), GvNAME(gv)),
		Method__Cumulative_dispatcher,
		__FILE__
	);
	CvMETHOD_on(xsub);

	mg = mgx_attach((SV*)xsub, &mc_vtbl, (SV*)code);
	SvREFCNT_inc_simple_void_NN(code);

	if(SvOK(attr_data)){
		STRLEN len;
		const char* const pv = SvPV_const(attr_data, len);

		if(len > 0){
			if(strnEQ(pv, "BASE FIRST", len)){
				MC_BASE_FIRST_on(mg);
			}
			else{
				Perl_croak(aTHX_ "Unrecognized attribute option \"%s\"", pv);
			}
		}
	}

	if(ckWARN(WARN_SYNTAX)){
		mc_check_consistancy(aTHX_ mc_get_stash(aTHX_ klass), mg, gv);
	}

